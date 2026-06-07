# Matchmaking Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-03-gamification-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `matchmaking-service` (porta 4007) — serviço de pareamento de jogadores para partidas competitivas. Jogadores solicitam um match por esporte; o serviço encontra um oponente disponível na fila Redis, propõe o match a ambos, e aguarda aceitação. Publica `MATCH_REQUESTED`, `MATCH_ACCEPTED` e `MATCH_EXPIRED`.

**Architecture:** NestJS 11 com um único módulo `matchmaking`, banco PostgreSQL dedicado e Redis compartilhado (já em execução). A fila de espera vive no Redis (ZSET por esporte). O PostgreSQL persiste o histórico de requests e matches. Sem cron job — expiração tratada lazily (verificação na leitura).

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, Redis (ioredis), @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## Setup de Branch

**Branch:** `feature/matchmaking-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/matchmaking-service
```

---

## File Map

```
services/matchmaking/
├── .env.example                                                                  ← Task 1
├── drizzle.config.ts                                                             ← Task 2
├── nest-cli.json                                                                 ← Task 3
├── package.json                                                                  ← Task 4
├── tsconfig.json                                                                 ← Task 5
├── tsconfig.build.json                                                           ← Task 5
└── src/
    ├── main.ts                                                                   ← Task 20
    ├── app.module.ts                                                             ← Task 20
    └── modules/
        └── matchmaking/
            ├── matchmaking.module.ts                                             ← Task 19
            ├── domain/
            │   ├── models/
            │   │   ├── match-request.entity.ts                                   ← Task 6
            │   │   └── pending-match.entity.ts                                   ← Task 6
            │   └── repositories/
            │       ├── match-request-repository.interface.ts                     ← Task 8
            │       └── pending-match-repository.interface.ts                     ← Task 8
            ├── application/
            │   ├── dto/
            │   │   ├── create-match-request.dto.ts                               ← Task 11
            │   │   ├── match-request.dto.ts                                      ← Task 11
            │   │   └── pending-match.dto.ts                                      ← Task 11
            │   └── services/
            │       ├── matchmaking.service.spec.ts                               ← Task 15
            │       ├── matchmaking.service.ts                                    ← Task 15
            │       ├── matchmaking-messaging.service.ts                          ← Task 14
            │       ├── matchmaking-queue.service.ts                              ← Task 13
            │       └── identity-events.consumer.ts                               ← Task 16
            └── infra/
                ├── controllers/
                │   ├── match-requests.controller.ts                              ← Task 17
                │   └── matches.controller.ts                                     ← Task 18
                ├── cache/
                │   └── redis.service.ts                                          ← Task 12
                └── database/
                    ├── schemas/
                    │   ├── match-request.schema.ts                               ← Task 7
                    │   └── pending-match.schema.ts                               ← Task 7
                    └── repositories/
                        ├── drizzle-match-request.repository.ts                   ← Task 9
                        └── drizzle-pending-match.repository.ts                   ← Task 10

drizzle/                                                                          ← Task 21
scripts/migrate.js                                                                ← Task 22
Dockerfile                                                                        ← Task 22
docker-entrypoint.sh                                                              ← Task 22
docker-compose.yml (raiz)                                                         ← Task 23
docs/plans/_status.md                                                             ← Task 24
```

---

## Regras de Negócio

### Fluxo de Matchmaking

```
Player A → POST /match-requests {sport}
           → MatchRequest criado (status: pending)
           → Redis ZADD matchmaking:queue:{sport} {timestamp} {requestExternalId}
           → Busca oponente na fila (mesmo esporte, userId diferente, não expirado)
              ├─ Oponente encontrado:
              │    → ZREM da fila (remove oponente)
              │    → PendingMatch criado (status: proposed)
              │    → Ambos MatchRequests → status: matched
              │    → publish MATCH_REQUESTED (fire-and-forget)
              └─ Não encontrado:
                   → ZADD própria request na fila
                   → Retorna MatchRequestDto com status: pending

Player A → POST /matches/:id/accept
Player B → POST /matches/:id/accept
           → Quando ambos aceitaram:
                → PendingMatch → status: accepted
                → publish MATCH_ACCEPTED (fire-and-forget)

Timeout (verificado lazily na leitura):
           → MatchRequest status: expired (se expiresAt < now)
           → PendingMatch status: expired (se expiresAt < now)
           → publish MATCH_EXPIRED (fire-and-forget)
```

### TTLs

| Entidade | TTL |
|----------|-----|
| MatchRequest | 5 minutos (expiresAt = requestedAt + 5min) |
| PendingMatch | 2 minutos (expiresAt = proposedAt + 2min) |

### Regras de validação no service

- Um jogador só pode ter **um** MatchRequest com status `pending` ou `matched` por vez
- Um jogador não pode ser oponente de si mesmo
- Cancelar request remove-a da fila Redis (`ZREM`)
- Aceitar um match já `accepted`, `declined` ou `expired` → `ConflictException`

### Redis key structure

| Chave | Tipo | Descrição |
|-------|------|-----------|
| `matchmaking:queue:{sport}` | ZSET | Fila de espera por esporte. Score = timestamp ms. Value = requestExternalId |

### XP/Level não geram efeito aqui
O matchmaking apenas pareou os jogadores. Quem concede XP é o gamification-service, quando consumir `game.match-completed` após o jogo encerrar.

---

## Contexto de Desenvolvimento

Branch: `feature/matchmaking-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/matchmaking/` salvo indicação contrária.

### Regras inegociáveis (reforço)
- Drizzle ORM (NUNCA TypeORM)
- Biome (NUNCA ESLint/Prettier)
- BIGSERIAL PK interno + UUID `external_id` exposto pela API
- Timestamps: sempre `timestamptz` (`withTimezone: true`)
- Fire-and-forget: chamadas de `messaging.publish*` APÓS commit no DB, dentro de `try/catch`
- Caminhos relativos em `infra/database/repositories/` para `domain/`: precisam de `../../../` (3 níveis)
- Caminhos relativos em `infra/cache/` para `application/services/`: precisam de `../../application/services/`
- Idempotência em consumers RabbitMQ (try/catch sem rethrow)
- Redis: `ioredis` com `RedisService` local (mesma estrutura do open-game service)
- ioredis `set` com NX+PX: ordem correta é `set(key, val, 'PX', ms, 'NX')`

---

### Task 1: `.env.example`

**Files:**
- Create: `services/matchmaking/.env.example`

- [ ] **Step 1: Criar `.env.example`**

```
PORT=4007
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_matchmaking
RABBITMQ_URL=amqp://admin:admin@localhost:5672
REDIS_URL=redis://localhost:6379
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/.env.example
git commit -m "chore(matchmaking): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/matchmaking/drizzle.config.ts`

- [ ] **Step 1: Criar drizzle.config.ts**

```typescript
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/**/schemas/*.schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env['DATABASE_URL']!,
  },
} satisfies Config;
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/drizzle.config.ts
git commit -m "chore(matchmaking): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/matchmaking/nest-cli.json`

- [ ] **Step 1: Criar nest-cli.json**

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true,
    "tsConfigPath": "tsconfig.build.json"
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/nest-cli.json
git commit -m "chore(matchmaking): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/matchmaking/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/matchmaking",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start:dev": "nest start --watch",
    "build": "nest build",
    "start:prod": "node dist/main",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "@golevelup/nestjs-rabbitmq": "^4.1.0",
    "@nestjs/common": "^11.0.0",
    "@nestjs/config": "^3.2.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/jwt": "^10.2.0",
    "@nestjs/platform-express": "^11.0.0",
    "@nestjs/swagger": "^8.0.0",
    "class-transformer": "^0.5.1",
    "class-validator": "^0.14.1",
    "drizzle-orm": "^0.36.0",
    "ioredis": "^5.3.0",
    "pg": "^8.13.0",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.0",
    "@nestjs/cli": "^11.0.0",
    "@nestjs/schematics": "^11.0.0",
    "@nestjs/testing": "^11.0.0",
    "@types/express": "^5.0.0",
    "@types/jest": "^29.5.0",
    "@types/node": "^22.0.0",
    "@types/pg": "^8.11.0",
    "@types/uuid": "^9.0.0",
    "drizzle-kit": "^0.28.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.2.0",
    "tsconfig-paths": "^4.2.0",
    "typescript": "^5.7.0"
  },
  "jest": {
    "moduleFileExtensions": ["js", "json", "ts"],
    "rootDir": "src",
    "testRegex": ".*\\.spec\\.ts$",
    "transform": { "^.+\\.(t|j)s$": "ts-jest" },
    "moduleNameMapper": {
      "^@shared/(.*)$": "<rootDir>/../../../shared/src/$1"
    },
    "modulePaths": ["<rootDir>/../node_modules"],
    "testEnvironment": "node"
  }
}
```

- [ ] **Step 2: Instalar dependências**

```bash
cd services/matchmaking && npm install --legacy-peer-deps
```

- [ ] **Step 3: Commit**

```bash
git add services/matchmaking/package.json services/matchmaking/package-lock.json
git commit -m "chore(matchmaking): add package.json"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/matchmaking/tsconfig.json`
- Create: `services/matchmaking/tsconfig.build.json`

- [ ] **Step 1: Criar tsconfig.json**

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "baseUrl": "./",
    "paths": {
      "@shared/*": ["../../shared/src/*"],
      "@nestjs/*": ["./node_modules/@nestjs/*"],
      "@golevelup/*": ["./node_modules/@golevelup/*"],
      "class-validator": ["./node_modules/class-validator"],
      "class-transformer": ["./node_modules/class-transformer"],
      "rxjs": ["./node_modules/rxjs"],
      "rxjs/*": ["./node_modules/rxjs/*"],
      "drizzle-orm": ["./node_modules/drizzle-orm"],
      "drizzle-orm/*": ["./node_modules/drizzle-orm/*"],
      "ioredis": ["./node_modules/ioredis"],
      "ioredis/*": ["./node_modules/ioredis/*"],
      "pg": ["./node_modules/@types/pg"],
      "uuid": ["./node_modules/uuid"],
      "reflect-metadata": ["./node_modules/reflect-metadata"],
      "@types/*": ["./node_modules/@types/*"]
    },
    "incremental": true,
    "isolatedModules": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "drizzle"]
}
```

- [ ] **Step 2: Criar tsconfig.build.json**

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "dist", "drizzle", "**/*.spec.ts"]
}
```

- [ ] **Step 3: Commit**

```bash
git add services/matchmaking/tsconfig.json services/matchmaking/tsconfig.build.json
git commit -m "chore(matchmaking): add tsconfig files"
```

---

### Task 6: Domain entities

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/domain/models/match-request.entity.ts`
- Create: `services/matchmaking/src/modules/matchmaking/domain/models/pending-match.entity.ts`

- [ ] **Step 1: Criar match-request.entity.ts**

```typescript
export type MatchRequestStatus = 'pending' | 'matched' | 'cancelled' | 'expired';
export type SportType = 'futsal' | 'society' | 'campo';

export class MatchRequest {
  id!: number;
  externalId!: string;
  requesterUserId!: string;
  displayName!: string;
  sport!: SportType;
  status!: MatchRequestStatus;
  requestedAt!: Date;
  expiresAt!: Date;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Criar pending-match.entity.ts**

```typescript
export type PendingMatchStatus = 'proposed' | 'accepted' | 'expired';

export class PendingMatch {
  id!: number;
  externalId!: string;
  requestAExternalId!: string;
  requestBExternalId!: string;
  userAId!: string;
  userBId!: string;
  sport!: string;
  status!: PendingMatchStatus;
  acceptedByA!: boolean;
  acceptedByB!: boolean;
  proposedAt!: Date;
  expiresAt!: Date;
  updatedAt!: Date;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/domain/models/
git commit -m "feat(matchmaking): add domain entities"
```

---

### Task 7: Database schemas

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/database/schemas/match-request.schema.ts`
- Create: `services/matchmaking/src/modules/matchmaking/infra/database/schemas/pending-match.schema.ts`

- [ ] **Step 1: Criar match-request.schema.ts**

```typescript
import { pgTable, bigserial, text, timestamp } from 'drizzle-orm/pg-core';

export const matchRequests = pgTable('match_requests', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  requesterUserId: text('requester_user_id').notNull(),
  displayName: text('display_name').notNull().default(''),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('pending'),
  requestedAt: timestamp('requested_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type MatchRequestRow = typeof matchRequests.$inferSelect;
```

- [ ] **Step 2: Criar pending-match.schema.ts**

```typescript
import { pgTable, bigserial, text, boolean, timestamp } from 'drizzle-orm/pg-core';

export const pendingMatches = pgTable('pending_matches', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  requestAExternalId: text('request_a_external_id').notNull(),
  requestBExternalId: text('request_b_external_id').notNull(),
  userAId: text('user_a_id').notNull(),
  userBId: text('user_b_id').notNull(),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('proposed'),
  acceptedByA: boolean('accepted_by_a').notNull().default(false),
  acceptedByB: boolean('accepted_by_b').notNull().default(false),
  proposedAt: timestamp('proposed_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PendingMatchRow = typeof pendingMatches.$inferSelect;
```

- [ ] **Step 3: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/database/schemas/
git commit -m "feat(matchmaking): add Drizzle schemas"
```

---

### Task 8: Repository interfaces

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/domain/repositories/match-request-repository.interface.ts`
- Create: `services/matchmaking/src/modules/matchmaking/domain/repositories/pending-match-repository.interface.ts`

- [ ] **Step 1: Criar match-request-repository.interface.ts**

```typescript
import type { MatchRequest, MatchRequestStatus, SportType } from '../models/match-request.entity';

export const MATCH_REQUEST_REPOSITORY = 'MATCH_REQUEST_REPOSITORY';

export interface CreateMatchRequestData {
  externalId: string;
  requesterUserId: string;
  displayName: string;
  sport: SportType;
  expiresAt: Date;
}

export interface MatchRequestRepositoryInterface {
  create(data: CreateMatchRequestData): Promise<MatchRequest>;
  findByExternalId(externalId: string): Promise<MatchRequest | null>;
  /** Retorna a request pending/matched mais recente do usuário, se existir. */
  findActivByUserId(userId: string): Promise<MatchRequest | null>;
  updateStatus(externalId: string, status: MatchRequestStatus): Promise<void>;
  updateDisplayName(userId: string, displayName: string): Promise<void>;
}
```

- [ ] **Step 2: Criar pending-match-repository.interface.ts**

```typescript
import type { PendingMatch, PendingMatchStatus } from '../models/pending-match.entity';
import type { SportType } from '../models/match-request.entity';

export const PENDING_MATCH_REPOSITORY = 'PENDING_MATCH_REPOSITORY';

export interface CreatePendingMatchData {
  externalId: string;
  requestAExternalId: string;
  requestBExternalId: string;
  userAId: string;
  userBId: string;
  sport: SportType;
  expiresAt: Date;
}

export interface PendingMatchRepositoryInterface {
  create(data: CreatePendingMatchData): Promise<PendingMatch>;
  findByExternalId(externalId: string): Promise<PendingMatch | null>;
  /** Marca aceitação do jogador A ou B. Retorna o match atualizado. */
  accept(externalId: string, role: 'A' | 'B'): Promise<PendingMatch>;
  updateStatus(externalId: string, status: PendingMatchStatus): Promise<void>;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/domain/repositories/
git commit -m "feat(matchmaking): add repository interfaces"
```

---

### Task 9: `DrizzleMatchRequestRepository`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/database/repositories/drizzle-match-request.repository.ts`

- [ ] **Step 1: Criar drizzle-match-request.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { eq, or } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  MatchRequestRepositoryInterface,
  CreateMatchRequestData,
} from '../../../domain/repositories/match-request-repository.interface';
import type { MatchRequest, MatchRequestStatus } from '../../../domain/models/match-request.entity';
import { matchRequests, type MatchRequestRow } from '../schemas/match-request.schema';

@Injectable()
export class DrizzleMatchRequestRepository implements MatchRequestRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateMatchRequestData): Promise<MatchRequest> {
    const [row] = await this.drizzle.db
      .insert(matchRequests)
      .values({
        externalId: data.externalId,
        requesterUserId: data.requesterUserId,
        displayName: data.displayName,
        sport: data.sport,
        expiresAt: data.expiresAt,
        status: 'pending',
      })
      .returning();
    return this.toEntity(row);
  }

  async findByExternalId(externalId: string): Promise<MatchRequest | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(matchRequests)
      .where(eq(matchRequests.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async findActivByUserId(userId: string): Promise<MatchRequest | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(matchRequests)
      .where(
        eq(matchRequests.requesterUserId, userId),
        // status pending OR matched
      )
      .limit(1);

    if (!row) return null;
    // Check if active status
    if (row.status === 'pending' || row.status === 'matched') {
      return this.toEntity(row);
    }
    return null;
  }

  async updateStatus(externalId: string, status: MatchRequestStatus): Promise<void> {
    await this.drizzle.db
      .update(matchRequests)
      .set({ status, updatedAt: new Date() })
      .where(eq(matchRequests.externalId, externalId));
  }

  async updateDisplayName(userId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(matchRequests)
      .set({ displayName, updatedAt: new Date() })
      .where(eq(matchRequests.requesterUserId, userId));
  }

  private toEntity(row: MatchRequestRow): MatchRequest {
    return {
      id: row.id,
      externalId: row.externalId,
      requesterUserId: row.requesterUserId,
      displayName: row.displayName,
      sport: row.sport as MatchRequest['sport'],
      status: row.status as MatchRequest['status'],
      requestedAt: row.requestedAt,
      expiresAt: row.expiresAt,
      updatedAt: row.updatedAt,
    };
  }
}
```

**Atenção:** O método `findActivByUserId` usa `.where(eq(matchRequests.requesterUserId, userId))` e verifica status no código. Para uma query com múltiplos status, usar `inArray` do drizzle-orm:

```typescript
import { eq, inArray } from 'drizzle-orm';

async findActivByUserId(userId: string): Promise<MatchRequest | null> {
  const [row] = await this.drizzle.db
    .select()
    .from(matchRequests)
    .where(
      eq(matchRequests.requesterUserId, userId),
    )
    .orderBy(desc(matchRequests.requestedAt))
    .limit(1);

  if (!row) return null;
  if (row.status === 'pending' || row.status === 'matched') return this.toEntity(row);
  return null;
}
```

Importe `desc` de `drizzle-orm`.

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/database/repositories/drizzle-match-request.repository.ts
git commit -m "feat(matchmaking): add DrizzleMatchRequestRepository"
```

---

### Task 10: `DrizzlePendingMatchRepository`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/database/repositories/drizzle-pending-match.repository.ts`

- [ ] **Step 1: Criar drizzle-pending-match.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  PendingMatchRepositoryInterface,
  CreatePendingMatchData,
} from '../../../domain/repositories/pending-match-repository.interface';
import type { PendingMatch, PendingMatchStatus } from '../../../domain/models/pending-match.entity';
import { pendingMatches, type PendingMatchRow } from '../schemas/pending-match.schema';

@Injectable()
export class DrizzlePendingMatchRepository implements PendingMatchRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreatePendingMatchData): Promise<PendingMatch> {
    const [row] = await this.drizzle.db
      .insert(pendingMatches)
      .values({
        externalId: data.externalId,
        requestAExternalId: data.requestAExternalId,
        requestBExternalId: data.requestBExternalId,
        userAId: data.userAId,
        userBId: data.userBId,
        sport: data.sport,
        expiresAt: data.expiresAt,
        status: 'proposed',
        acceptedByA: false,
        acceptedByB: false,
      })
      .returning();
    return this.toEntity(row);
  }

  async findByExternalId(externalId: string): Promise<PendingMatch | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(pendingMatches)
      .where(eq(pendingMatches.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async accept(externalId: string, role: 'A' | 'B'): Promise<PendingMatch> {
    const field = role === 'A' ? pendingMatches.acceptedByA : pendingMatches.acceptedByB;
    const [row] = await this.drizzle.db
      .update(pendingMatches)
      .set({ [role === 'A' ? 'acceptedByA' : 'acceptedByB']: true, updatedAt: new Date() })
      .where(eq(pendingMatches.externalId, externalId))
      .returning();
    return this.toEntity(row);
  }

  async updateStatus(externalId: string, status: PendingMatchStatus): Promise<void> {
    await this.drizzle.db
      .update(pendingMatches)
      .set({ status, updatedAt: new Date() })
      .where(eq(pendingMatches.externalId, externalId));
  }

  private toEntity(row: PendingMatchRow): PendingMatch {
    return {
      id: row.id,
      externalId: row.externalId,
      requestAExternalId: row.requestAExternalId,
      requestBExternalId: row.requestBExternalId,
      userAId: row.userAId,
      userBId: row.userBId,
      sport: row.sport,
      status: row.status as PendingMatch['status'],
      acceptedByA: row.acceptedByA,
      acceptedByB: row.acceptedByB,
      proposedAt: row.proposedAt,
      expiresAt: row.expiresAt,
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/database/repositories/drizzle-pending-match.repository.ts
git commit -m "feat(matchmaking): add DrizzlePendingMatchRepository"
```

---

### Task 11: DTOs

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/application/dto/create-match-request.dto.ts`
- Create: `services/matchmaking/src/modules/matchmaking/application/dto/match-request.dto.ts`
- Create: `services/matchmaking/src/modules/matchmaking/application/dto/pending-match.dto.ts`

- [ ] **Step 1: Criar create-match-request.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import type { SportType } from '../../domain/models/match-request.entity';

export class CreateMatchRequestDto {
  @ApiProperty({ enum: ['futsal', 'society', 'campo'] })
  @IsIn(['futsal', 'society', 'campo'])
  sport!: SportType;
}
```

- [ ] **Step 2: Criar match-request.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { MatchRequest } from '../../domain/models/match-request.entity';

export class MatchRequestDto {
  @ApiProperty() id!: string;
  @ApiProperty() requesterUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() requestedAt!: Date;
  @ApiProperty() expiresAt!: Date;

  static from(r: MatchRequest): MatchRequestDto {
    const dto = new MatchRequestDto();
    dto.id = r.externalId;
    dto.requesterUserId = r.requesterUserId;
    dto.displayName = r.displayName;
    dto.sport = r.sport;
    dto.status = r.status;
    dto.requestedAt = r.requestedAt;
    dto.expiresAt = r.expiresAt;
    return dto;
  }
}
```

- [ ] **Step 3: Criar pending-match.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

export class PendingMatchDto {
  @ApiProperty() id!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() acceptedByA!: boolean;
  @ApiProperty() acceptedByB!: boolean;
  @ApiProperty() proposedAt!: Date;
  @ApiProperty() expiresAt!: Date;

  static from(m: PendingMatch): PendingMatchDto {
    const dto = new PendingMatchDto();
    dto.id = m.externalId;
    dto.sport = m.sport;
    dto.status = m.status;
    dto.acceptedByA = m.acceptedByA;
    dto.acceptedByB = m.acceptedByB;
    dto.proposedAt = m.proposedAt;
    dto.expiresAt = m.expiresAt;
    return dto;
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/application/dto/
git commit -m "feat(matchmaking): add DTOs"
```

---

### Task 12: `RedisService`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/cache/redis.service.ts`

Idêntico ao `services/open-game/src/infra/cache/redis.service.ts`. Copie e adapte o Logger.

- [ ] **Step 1: Criar redis.service.ts**

```typescript
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  readonly client: Redis;

  constructor(config: ConfigService) {
    this.client = new Redis(config.get('REDIS_URL')!);
    this.client.on('error', (err) => {
      this.logger.error(`Redis error: ${err.message}`);
    });
  }

  onModuleDestroy(): void {
    this.client.disconnect();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/cache/redis.service.ts
git commit -m "feat(matchmaking): add RedisService"
```

---

### Task 13: `MatchmakingQueueService`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/application/services/matchmaking-queue.service.ts`

Este serviço encapsula as operações Redis da fila de matchmaking.

- [ ] **Step 1: Criar matchmaking-queue.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { RedisService } from '../../infra/cache/redis.service';
import type { MatchRequest, SportType } from '../../domain/models/match-request.entity';

const REQUEST_TTL_MS = 5 * 60 * 1000; // 5 minutes

@Injectable()
export class MatchmakingQueueService {
  constructor(private readonly redis: RedisService) {}

  private queueKey(sport: SportType): string {
    return `matchmaking:queue:${sport}`;
  }

  /** Adiciona request à fila. Score = timestamp ms (FIFO por mais antigo). */
  async enqueue(request: MatchRequest): Promise<void> {
    await this.redis.client.zadd(
      this.queueKey(request.sport),
      request.requestedAt.getTime(),
      request.externalId,
    );
  }

  /** Remove request da fila (cancelamento ou match encontrado). */
  async dequeue(sport: SportType, externalId: string): Promise<void> {
    await this.redis.client.zrem(this.queueKey(sport), externalId);
  }

  /**
   * Busca o candidato mais antigo na fila (excluindo `excludeUserId`).
   * Retorna o externalId do candidato ou null se nenhum encontrado.
   * Remove entradas expiradas da fila durante a busca.
   */
  async findCandidate(
    sport: SportType,
    excludeUserId: string,
    excludeExternalId: string,
  ): Promise<string | null> {
    const now = Date.now();
    const validSince = now - REQUEST_TTL_MS;

    // Remove requests expirados (score < validSince)
    await this.redis.client.zremrangebyscore(this.queueKey(sport), '-inf', validSince - 1);

    // Busca até 20 candidatos válidos (ordenados por tempo de entrada)
    const candidates = await this.redis.client.zrangebyscore(
      this.queueKey(sport),
      validSince,
      '+inf',
      'LIMIT',
      0,
      20,
    );

    // Retorna o primeiro que não é a própria request e não é o mesmo userId
    // (o caller deve filtrar por userId usando o repositório)
    for (const candidateId of candidates) {
      if (candidateId !== excludeExternalId) {
        return candidateId;
      }
    }

    return null;
  }
}
```

**Nota:** A verificação de `userId` (para garantir que não é a mesma pessoa) é feita no `MatchmakingService` após recuperar o request do banco com `findByExternalId`.

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/application/services/matchmaking-queue.service.ts
git commit -m "feat(matchmaking): add MatchmakingQueueService"
```

---

### Task 14: `MatchmakingMessagingService`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/application/services/matchmaking-messaging.service.ts`

- [ ] **Step 1: Criar matchmaking-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

@Injectable()
export class MatchmakingMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishMatchRequested(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_REQUESTED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
      expiresAt: match.expiresAt,
    });
  }

  async publishMatchAccepted(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_ACCEPTED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
    });
  }

  async publishMatchExpired(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_EXPIRED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/application/services/matchmaking-messaging.service.ts
git commit -m "feat(matchmaking): add MatchmakingMessagingService"
```

---

### Task 15: `MatchmakingService` (TDD)

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/application/services/matchmaking.service.spec.ts`
- Create: `services/matchmaking/src/modules/matchmaking/application/services/matchmaking.service.ts`

- [ ] **Step 1: Escrever spec primeiro**

```typescript
// matchmaking.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { MatchmakingService } from './matchmaking.service';
import { MATCH_REQUEST_REPOSITORY } from '../../domain/repositories/match-request-repository.interface';
import { PENDING_MATCH_REPOSITORY } from '../../domain/repositories/pending-match-repository.interface';
import { MatchmakingQueueService } from './matchmaking-queue.service';
import { MatchmakingMessagingService } from './matchmaking-messaging.service';
import type { MatchRequest } from '../../domain/models/match-request.entity';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

const makeRequest = (overrides: Partial<MatchRequest> = {}): MatchRequest => ({
  id: 1,
  externalId: 'req-1',
  requesterUserId: 'user-1',
  displayName: 'Alice',
  sport: 'futsal',
  status: 'pending',
  requestedAt: new Date(),
  expiresAt: new Date(Date.now() + 5 * 60 * 1000),
  updatedAt: new Date(),
  ...overrides,
});

const makeMatch = (overrides: Partial<PendingMatch> = {}): PendingMatch => ({
  id: 1,
  externalId: 'match-1',
  requestAExternalId: 'req-1',
  requestBExternalId: 'req-2',
  userAId: 'user-1',
  userBId: 'user-2',
  sport: 'futsal',
  status: 'proposed',
  acceptedByA: false,
  acceptedByB: false,
  proposedAt: new Date(),
  expiresAt: new Date(Date.now() + 2 * 60 * 1000),
  updatedAt: new Date(),
  ...overrides,
});

describe('MatchmakingService', () => {
  let service: MatchmakingService;
  let requestRepo: jest.Mocked<any>;
  let matchRepo: jest.Mocked<any>;
  let queueService: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    requestRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      findActivByUserId: jest.fn(),
      updateStatus: jest.fn(),
      updateDisplayName: jest.fn(),
    };
    matchRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      accept: jest.fn(),
      updateStatus: jest.fn(),
    };
    queueService = {
      enqueue: jest.fn(),
      dequeue: jest.fn(),
      findCandidate: jest.fn(),
    };
    messaging = {
      publishMatchRequested: jest.fn(),
      publishMatchAccepted: jest.fn(),
      publishMatchExpired: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchmakingService,
        { provide: MATCH_REQUEST_REPOSITORY, useValue: requestRepo },
        { provide: PENDING_MATCH_REPOSITORY, useValue: matchRepo },
        { provide: MatchmakingQueueService, useValue: queueService },
        { provide: MatchmakingMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<MatchmakingService>(MatchmakingService);
  });

  describe('createRequest', () => {
    it('creates pending request and enqueues when no opponent found', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(null);
      requestRepo.create.mockResolvedValue(makeRequest());
      queueService.findCandidate.mockResolvedValue(null);
      queueService.enqueue.mockResolvedValue(undefined);

      const result = await service.createRequest('user-1', 'Alice', 'futsal');

      expect(requestRepo.create).toHaveBeenCalled();
      expect(queueService.findCandidate).toHaveBeenCalled();
      expect(queueService.enqueue).toHaveBeenCalled();
      expect(result.status).toBe('pending');
    });

    it('throws ConflictException when user already has active request', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(makeRequest({ status: 'pending' }));

      await expect(service.createRequest('user-1', 'Alice', 'futsal')).rejects.toThrow(
        ConflictException,
      );
    });

    it('creates match and publishes MATCH_REQUESTED when opponent found in queue', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(null);
      const ownRequest = makeRequest({ externalId: 'req-1', requesterUserId: 'user-1' });
      requestRepo.create.mockResolvedValue(ownRequest);
      queueService.findCandidate.mockResolvedValue('req-2');
      const opponentRequest = makeRequest({
        externalId: 'req-2',
        requesterUserId: 'user-2',
        displayName: 'Bob',
      });
      requestRepo.findByExternalId.mockResolvedValue(opponentRequest);
      const pendingMatch = makeMatch();
      matchRepo.create.mockResolvedValue(pendingMatch);
      requestRepo.updateStatus.mockResolvedValue(undefined);
      queueService.dequeue.mockResolvedValue(undefined);
      messaging.publishMatchRequested.mockResolvedValue(undefined);

      const result = await service.createRequest('user-1', 'Alice', 'futsal');

      expect(matchRepo.create).toHaveBeenCalled();
      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-1', 'matched');
      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-2', 'matched');
      expect(messaging.publishMatchRequested).toHaveBeenCalled();
      expect(result.status).toBe('matched');
    });
  });

  describe('cancelRequest', () => {
    it('cancels own request and removes from queue', async () => {
      requestRepo.findByExternalId.mockResolvedValue(makeRequest({ requesterUserId: 'user-1' }));
      requestRepo.updateStatus.mockResolvedValue(undefined);
      queueService.dequeue.mockResolvedValue(undefined);

      await service.cancelRequest('user-1', 'req-1');

      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-1', 'cancelled');
      expect(queueService.dequeue).toHaveBeenCalled();
    });

    it('throws ForbiddenException when cancelling someone else request', async () => {
      requestRepo.findByExternalId.mockResolvedValue(makeRequest({ requesterUserId: 'user-2' }));

      await expect(service.cancelRequest('user-1', 'req-1')).rejects.toThrow(ForbiddenException);
    });
  });

  describe('acceptMatch', () => {
    it('marks partial acceptance (only one player accepted)', async () => {
      const proposed = makeMatch({ status: 'proposed', acceptedByA: false, acceptedByB: false });
      matchRepo.findByExternalId.mockResolvedValue(proposed);
      const afterAccept = makeMatch({ acceptedByA: true, acceptedByB: false });
      matchRepo.accept.mockResolvedValue(afterAccept);

      const result = await service.acceptMatch('user-1', 'match-1');

      expect(matchRepo.accept).toHaveBeenCalledWith('match-1', 'A');
      expect(matchRepo.updateStatus).not.toHaveBeenCalledWith('match-1', 'accepted');
      expect(messaging.publishMatchAccepted).not.toHaveBeenCalled();
      expect(result.status).toBe('proposed');
    });

    it('marks accepted and publishes MATCH_ACCEPTED when both players accept', async () => {
      const proposed = makeMatch({ status: 'proposed', acceptedByA: true, acceptedByB: false });
      matchRepo.findByExternalId.mockResolvedValue(proposed);
      const fullyAccepted = makeMatch({ status: 'accepted', acceptedByA: true, acceptedByB: true });
      matchRepo.accept.mockResolvedValue(fullyAccepted);
      matchRepo.updateStatus.mockResolvedValue(undefined);
      messaging.publishMatchAccepted.mockResolvedValue(undefined);

      const result = await service.acceptMatch('user-2', 'match-1');

      expect(matchRepo.accept).toHaveBeenCalledWith('match-1', 'B');
      expect(matchRepo.updateStatus).toHaveBeenCalledWith('match-1', 'accepted');
      expect(messaging.publishMatchAccepted).toHaveBeenCalled();
      expect(result.status).toBe('accepted');
    });

    it('throws NotFoundException when match does not exist', async () => {
      matchRepo.findByExternalId.mockResolvedValue(null);

      await expect(service.acceptMatch('user-1', 'non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
```

- [ ] **Step 2: Rodar tests para confirmar FAIL**

```bash
cd services/matchmaking && npm test -- --testPathPattern="matchmaking.service.spec"
```

Expected: FAIL com "Cannot find module './matchmaking.service'".

- [ ] **Step 3: Implementar matchmaking.service.ts**

```typescript
import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import {
  MATCH_REQUEST_REPOSITORY,
  MatchRequestRepositoryInterface,
} from '../../domain/repositories/match-request-repository.interface';
import {
  PENDING_MATCH_REPOSITORY,
  PendingMatchRepositoryInterface,
} from '../../domain/repositories/pending-match-repository.interface';
import { MatchmakingQueueService } from './matchmaking-queue.service';
import { MatchmakingMessagingService } from './matchmaking-messaging.service';
import type { MatchRequest, SportType } from '../../domain/models/match-request.entity';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

const REQUEST_TTL_MS = 5 * 60 * 1000;  // 5 min
const MATCH_TTL_MS = 2 * 60 * 1000;    // 2 min

@Injectable()
export class MatchmakingService {
  private readonly logger = new Logger(MatchmakingService.name);

  constructor(
    @Inject(MATCH_REQUEST_REPOSITORY)
    private readonly requestRepo: MatchRequestRepositoryInterface,
    @Inject(PENDING_MATCH_REPOSITORY)
    private readonly matchRepo: PendingMatchRepositoryInterface,
    private readonly queueService: MatchmakingQueueService,
    private readonly messaging: MatchmakingMessagingService,
  ) {}

  async createRequest(
    userId: string,
    displayName: string,
    sport: SportType,
  ): Promise<MatchRequest> {
    // Validar que não há request ativa
    const existing = await this.requestRepo.findActivByUserId(userId);
    if (existing) {
      throw new ConflictException('Player already has an active match request');
    }

    const now = new Date();
    const request = await this.requestRepo.create({
      externalId: uuidv4(),
      requesterUserId: userId,
      displayName,
      sport,
      expiresAt: new Date(now.getTime() + REQUEST_TTL_MS),
    });

    // Buscar oponente na fila
    const candidateId = await this.queueService.findCandidate(sport, userId, request.externalId);

    if (candidateId) {
      const opponent = await this.requestRepo.findByExternalId(candidateId);
      // Verificar se candidato é outro usuário e ainda está pendente
      if (opponent && opponent.requesterUserId !== userId && opponent.status === 'pending') {
        return this.proposeMatch(request, opponent);
      }
    }

    // Nenhum oponente → colocar na fila
    await this.queueService.enqueue(request);
    return request;
  }

  async cancelRequest(userId: string, requestExternalId: string): Promise<void> {
    const request = await this.requestRepo.findByExternalId(requestExternalId);
    if (!request) throw new NotFoundException('Match request not found');
    if (request.requesterUserId !== userId) {
      throw new ForbiddenException('Cannot cancel another player\'s request');
    }

    await this.requestRepo.updateStatus(requestExternalId, 'cancelled');
    await this.queueService.dequeue(request.sport, requestExternalId);
  }

  async getRequest(userId: string, requestExternalId: string): Promise<MatchRequest> {
    const request = await this.requestRepo.findByExternalId(requestExternalId);
    if (!request) throw new NotFoundException('Match request not found');
    if (request.requesterUserId !== userId) {
      throw new ForbiddenException('Cannot view another player\'s request');
    }

    // Verificação lazy de expiração
    if (request.status === 'pending' && request.expiresAt < new Date()) {
      await this.requestRepo.updateStatus(requestExternalId, 'expired');
      await this.queueService.dequeue(request.sport, requestExternalId);
      return { ...request, status: 'expired' };
    }

    return request;
  }

  async acceptMatch(userId: string, matchExternalId: string): Promise<PendingMatch> {
    const match = await this.matchRepo.findByExternalId(matchExternalId);
    if (!match) throw new NotFoundException('Pending match not found');

    if (match.status !== 'proposed') {
      throw new ConflictException(`Match is already ${match.status}`);
    }

    // Verificar expiração lazy
    if (match.expiresAt < new Date()) {
      await this.matchRepo.updateStatus(matchExternalId, 'expired');
      try {
        await this.messaging.publishMatchExpired({ ...match, status: 'expired' });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(`Failed to publish match-expired for ${matchExternalId}: ${message}`);
      }
      throw new ConflictException('Match has expired');
    }

    // Determinar role do usuário
    let role: 'A' | 'B';
    if (match.userAId === userId) role = 'A';
    else if (match.userBId === userId) role = 'B';
    else throw new ForbiddenException('You are not part of this match');

    const updated = await this.matchRepo.accept(matchExternalId, role);

    if (updated.acceptedByA && updated.acceptedByB) {
      await this.matchRepo.updateStatus(matchExternalId, 'accepted');
      const accepted = { ...updated, status: 'accepted' as const };
      try {
        await this.messaging.publishMatchAccepted(accepted);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(`Failed to publish match-accepted for ${matchExternalId}: ${message}`);
      }
      return accepted;
    }

    return updated;
  }

  private async proposeMatch(requestA: MatchRequest, requestB: MatchRequest): Promise<MatchRequest> {
    const now = new Date();
    const match = await this.matchRepo.create({
      externalId: uuidv4(),
      requestAExternalId: requestA.externalId,
      requestBExternalId: requestB.externalId,
      userAId: requestA.requesterUserId,
      userBId: requestB.requesterUserId,
      sport: requestA.sport,
      expiresAt: new Date(now.getTime() + MATCH_TTL_MS),
    });

    await this.requestRepo.updateStatus(requestA.externalId, 'matched');
    await this.requestRepo.updateStatus(requestB.externalId, 'matched');
    await this.queueService.dequeue(requestB.sport, requestB.externalId);

    try {
      await this.messaging.publishMatchRequested(match);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish match-requested for ${match.externalId}: ${message}`);
    }

    return { ...requestA, status: 'matched' };
  }
}
```

- [ ] **Step 4: Rodar tests para confirmar PASS**

```bash
cd services/matchmaking && npm test -- --testPathPattern="matchmaking.service.spec"
```

Expected: 7/7 tests passando.

- [ ] **Step 5: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/application/services/matchmaking.service.spec.ts
git add services/matchmaking/src/modules/matchmaking/application/services/matchmaking.service.ts
git commit -m "feat(matchmaking): add MatchmakingService with TDD (7/7 tests)"
```

---

### Task 16: `IdentityEventsConsumer`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/application/services/identity-events.consumer.ts`

- [ ] **Step 1: Criar identity-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { Inject } from '@nestjs/common';
import {
  MATCH_REQUEST_REPOSITORY,
  MatchRequestRepositoryInterface,
} from '../../domain/repositories/match-request-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(MATCH_REQUEST_REPOSITORY)
    private readonly requestRepo: MatchRequestRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'matchmaking-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.requestRepo.updateDisplayName(payload.userId, payload.displayName);
      this.logger.debug(`Updated displayName for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to update displayName for ${payload.userId}: ${message}`);
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/application/services/identity-events.consumer.ts
git commit -m "feat(matchmaking): add IdentityEventsConsumer"
```

---

### Task 17: `MatchRequestsController`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/controllers/match-requests.controller.ts`

- [ ] **Step 1: Criar match-requests.controller.ts**

```typescript
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Request,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { MatchmakingService } from '../../application/services/matchmaking.service';
import { CreateMatchRequestDto } from '../../application/dto/create-match-request.dto';
import { MatchRequestDto } from '../../application/dto/match-request.dto';

@ApiTags('Match Requests')
@UseGuards(JwtAuthGuard)
@Controller('match-requests')
export class MatchRequestsController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new matchmaking request' })
  async createRequest(
    @Request() req: any,
    @Body() dto: CreateMatchRequestDto,
  ): Promise<MatchRequestDto> {
    const userId: string = req.user.sub;
    const displayName: string = req.user.displayName ?? '';
    const request = await this.matchmakingService.createRequest(userId, displayName, dto.sport);
    return MatchRequestDto.from(request);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get match request status' })
  async getRequest(@Request() req: any, @Param('id') id: string): Promise<MatchRequestDto> {
    const userId: string = req.user.sub;
    const request = await this.matchmakingService.getRequest(userId, id);
    return MatchRequestDto.from(request);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Cancel a match request' })
  async cancelRequest(@Request() req: any, @Param('id') id: string): Promise<void> {
    const userId: string = req.user.sub;
    await this.matchmakingService.cancelRequest(userId, id);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/controllers/match-requests.controller.ts
git commit -m "feat(matchmaking): add MatchRequestsController"
```

---

### Task 18: `MatchesController`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/infra/controllers/matches.controller.ts`

- [ ] **Step 1: Criar matches.controller.ts**

```typescript
import { Controller, HttpCode, HttpStatus, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { MatchmakingService } from '../../application/services/matchmaking.service';
import { PendingMatchDto } from '../../application/dto/pending-match.dto';

@ApiTags('Matches')
@UseGuards(JwtAuthGuard)
@Controller('matches')
export class MatchesController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Post(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept a proposed match' })
  async acceptMatch(@Request() req: any, @Param('id') id: string): Promise<PendingMatchDto> {
    const userId: string = req.user.sub;
    const match = await this.matchmakingService.acceptMatch(userId, id);
    return PendingMatchDto.from(match);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/infra/controllers/matches.controller.ts
git commit -m "feat(matchmaking): add MatchesController"
```

---

### Task 19: `MatchmakingModule`

**Files:**
- Create: `services/matchmaking/src/modules/matchmaking/matchmaking.module.ts`

- [ ] **Step 1: Criar matchmaking.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { MATCH_REQUEST_REPOSITORY } from './domain/repositories/match-request-repository.interface';
import { PENDING_MATCH_REPOSITORY } from './domain/repositories/pending-match-repository.interface';
import { DrizzleMatchRequestRepository } from './infra/database/repositories/drizzle-match-request.repository';
import { DrizzlePendingMatchRepository } from './infra/database/repositories/drizzle-pending-match.repository';
import { RedisService } from './infra/cache/redis.service';
import { MatchmakingQueueService } from './application/services/matchmaking-queue.service';
import { MatchmakingMessagingService } from './application/services/matchmaking-messaging.service';
import { MatchmakingService } from './application/services/matchmaking.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { MatchRequestsController } from './infra/controllers/match-requests.controller';
import { MatchesController } from './infra/controllers/matches.controller';

@Module({
  imports: [SharedModule],
  controllers: [MatchRequestsController, MatchesController],
  providers: [
    { provide: MATCH_REQUEST_REPOSITORY, useClass: DrizzleMatchRequestRepository },
    { provide: PENDING_MATCH_REPOSITORY, useClass: DrizzlePendingMatchRepository },
    RedisService,
    MatchmakingQueueService,
    MatchmakingMessagingService,
    MatchmakingService,
    IdentityEventsConsumer,
  ],
})
export class MatchmakingModule {}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/src/modules/matchmaking/matchmaking.module.ts
git commit -m "feat(matchmaking): add MatchmakingModule"
```

---

### Task 20: `AppModule` + `main.ts`

**Files:**
- Create: `services/matchmaking/src/app.module.ts`
- Create: `services/matchmaking/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MatchmakingModule } from './modules/matchmaking/matchmaking.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MatchmakingModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 2: Criar main.ts**

```typescript
import { NestFactory } from '@nestjs/core';
import { bootstrapHttpApp } from '@shared/infra/http/bootstrap-http-app';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await bootstrapHttpApp(app);
}

bootstrap();
```

- [ ] **Step 3: Rodar build**

```bash
cd services/matchmaking && npm run build
```

Expected: 0 erros. Se houver erros de import, corrigir caminhos relativos (3 níveis de `../` de `infra/database/repositories/` para `domain/`).

- [ ] **Step 4: Commit**

```bash
git add services/matchmaking/src/app.module.ts services/matchmaking/src/main.ts
git commit -m "feat(matchmaking): add AppModule and main.ts"
```

---

### Task 21: Migration SQL

**Files:**
- Create: `services/matchmaking/drizzle/0000_initial_matchmaking.sql`
- Create: `services/matchmaking/drizzle/meta/_journal.json`

- [ ] **Step 1: Criar SQL de migration**

`drizzle/0000_initial_matchmaking.sql`:
```sql
CREATE TABLE "match_requests" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "requester_user_id" text NOT NULL,
  "display_name" text DEFAULT '' NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'pending' NOT NULL,
  "requested_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "match_requests_external_id_unique" UNIQUE("external_id")
);

CREATE TABLE "pending_matches" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "request_a_external_id" text NOT NULL,
  "request_b_external_id" text NOT NULL,
  "user_a_id" text NOT NULL,
  "user_b_id" text NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'proposed' NOT NULL,
  "accepted_by_a" boolean DEFAULT false NOT NULL,
  "accepted_by_b" boolean DEFAULT false NOT NULL,
  "proposed_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "pending_matches_external_id_unique" UNIQUE("external_id")
);

CREATE INDEX "idx_match_requests_user_status" ON "match_requests" ("requester_user_id", "status");
CREATE INDEX "idx_match_requests_sport_status" ON "match_requests" ("sport", "status");
```

`drizzle/meta/_journal.json`:
```json
{
  "version": "7",
  "dialect": "postgresql",
  "entries": [
    {
      "idx": 0,
      "version": "7",
      "when": 1749254400000,
      "tag": "0000_initial_matchmaking",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add services/matchmaking/drizzle/
git commit -m "feat(matchmaking): add initial Drizzle migration"
```

---

### Task 22: `Dockerfile` + `scripts/migrate.js` + `docker-entrypoint.sh`

Mesma estrutura dos outros serviços, substituindo `matchmaking` por `matchmaking` e porta `4007`.

**Files:**
- Create: `services/matchmaking/scripts/migrate.js`
- Create: `services/matchmaking/docker-entrypoint.sh`
- Create: `services/matchmaking/Dockerfile`

- [ ] **Step 1: Criar scripts/migrate.js**

```javascript
'use strict';

const { drizzle } = require('drizzle-orm/node-postgres');
const { migrate } = require('drizzle-orm/node-postgres/migrator');
const { Pool } = require('pg');
const path = require('path');

async function runMigrations() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.error('DATABASE_URL is not set');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: url });
  const db = drizzle(pool);

  console.log('Running database migrations...');
  await migrate(db, { migrationsFolder: path.join(__dirname, '../drizzle') });
  await pool.end();
  console.log('Migrations complete.');
}

runMigrations().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
```

- [ ] **Step 2: Criar docker-entrypoint.sh**

```sh
#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/matchmaking/scripts/migrate.js

echo "Starting matchmaking service..."
exec node /app/services/matchmaking/dist/services/matchmaking/src/main
```

- [ ] **Step 3: Criar Dockerfile**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/matchmaking/ ./services/matchmaking/

WORKDIR /app/services/matchmaking
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/matchmaking

COPY --from=builder /app/services/matchmaking/dist ./dist
COPY --from=builder /app/services/matchmaking/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/matchmaking/drizzle ./drizzle
COPY --from=builder /app/services/matchmaking/scripts ./scripts
COPY --from=builder /app/services/matchmaking/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4007

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 4: Commit**

```bash
git add services/matchmaking/Dockerfile services/matchmaking/scripts/migrate.js services/matchmaking/docker-entrypoint.sh
git commit -m "feat(matchmaking): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 23: `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Adicionar postgres-matchmaking e matchmaking ao docker-compose.yml**

Adicionar após o bloco `postgres-gamification:` e antes do bloco `volumes:`:

```yaml
  postgres-matchmaking:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_matchmaking
    ports:
      - "5438:5432"
    volumes:
      - postgres_matchmaking_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  matchmaking:
    build:
      context: .
      dockerfile: services/matchmaking/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4007
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-matchmaking:5432/bolanarededb_matchmaking
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
      REDIS_URL: redis://redis:6379
    ports:
      - "4007:4007"
    depends_on:
      postgres-matchmaking:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      redis:
        condition: service_healthy
```

Adicionar no bloco `volumes:`:

```yaml
  postgres_matchmaking_data:
```

- [ ] **Step 2: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(matchmaking): add postgres-matchmaking and matchmaking service to docker-compose"
```

---

### Task 24: `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar _status.md**

Localizar:
```
| matchmaking  | ⏳ TODO  | 0/?        | —                            |
```

Substituir por:
```
| matchmaking  | ✅ DONE  | 24/24      | —                            |
```

Adicionar ao bloco de planos:
```
- `docs/plans/2026-06-07-matchmaking-service.md` — 24 tasks
```

Atualizar timestamp: `Última atualização: 2026-06-07 (matchmaking DONE)`

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs(matchmaking): update _status.md — matchmaking service DONE (24/24)"
```

---

## Checklist de conclusão

- [ ] `npm test` em `services/matchmaking/` — todos os 7 testes passando
- [ ] `npm run build` em `services/matchmaking/` — sem erros de compilação
- [ ] Todos os 24 tasks commitados na branch `feature/matchmaking-service`
