# Gamification Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-03-social-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `gamification-service` (porta 4006) — serviço de XP, níveis e conquistas (badges) dos jogadores, acionado por eventos de partidas concluídas e estatísticas registradas.

**Architecture:** NestJS 11 com um único módulo `gamification` e banco PostgreSQL dedicado. Sem Redis. Jogadores acumulam XP a cada partida (participação + gols + assistências); o XP determina o nível automaticamente. Badges são concedidos por marcos (primeira partida, primeiro gol, nível 5, nível 10). Publica `gamification.badge-awarded` ao conceder badge. Consome `identity.user-registered`, `identity.profile-updated`, `open-game.stats-recorded` e `game.match-completed`.

**Importante:** O evento `open-game.stats-recorded` hoje só carrega `{ gameId }`. Este plano inclui (Task 15) a modificação do open-game service para enriquecer o payload com estatísticas por jogador.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## Setup de Branch

**Branch:** `feature/gamification-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/gamification-service
```

---

## File Map

```
services/gamification/
├── .env.example                                                              ← Task 1
├── drizzle.config.ts                                                         ← Task 2
├── nest-cli.json                                                             ← Task 3
├── package.json                                                              ← Task 4
├── tsconfig.json                                                             ← Task 5
├── tsconfig.build.json                                                       ← Task 5
└── src/
    ├── main.ts                                                               ← Task 19
    ├── app.module.ts                                                         ← Task 19
    └── modules/
        └── gamification/
            ├── gamification.module.ts                                        ← Task 18
            ├── domain/
            │   ├── models/
            │   │   ├── player-profile.entity.ts                              ← Task 6
            │   │   ├── xp-ledger.entity.ts                                   ← Task 6
            │   │   └── player-badge.entity.ts                                ← Task 6
            │   └── repositories/
            │       ├── profile-repository.interface.ts                       ← Task 8
            │       ├── xp-ledger-repository.interface.ts                     ← Task 8
            │       └── badge-repository.interface.ts                         ← Task 8
            ├── application/
            │   ├── dto/
            │   │   ├── profile.dto.ts                                        ← Task 11
            │   │   └── leaderboard-entry.dto.ts                              ← Task 11
            │   └── services/
            │       ├── xp.service.spec.ts                                    ← Task 13
            │       ├── xp.service.ts                                         ← Task 13
            │       ├── gamification-messaging.service.ts                     ← Task 12
            │       ├── identity-events.consumer.ts                           ← Task 14
            │       ├── open-game-events.consumer.ts                          ← Task 15
            │       └── game-events.consumer.ts                               ← Task 16
            └── infra/
                ├── controllers/
                │   └── gamification.controller.ts                            ← Task 17
                └── database/
                    ├── schemas/
                    │   ├── player-profile.schema.ts                          ← Task 7
                    │   ├── xp-ledger.schema.ts                               ← Task 7
                    │   └── player-badge.schema.ts                            ← Task 7
                    └── repositories/
                        ├── drizzle-profile.repository.ts                     ← Task 9
                        └── drizzle-xp-badge.repository.ts                   ← Task 10

drizzle/                                                                      ← Task 20
scripts/migrate.js                                                            ← Task 21
Dockerfile                                                                    ← Task 21
docker-entrypoint.sh                                                          ← Task 21
docker-compose.yml (raiz)                                                     ← Task 22
docs/plans/_status.md                                                         ← Task 23

services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts  ← Task 15 (modify)
services/open-game/src/modules/open-game/stats/application/services/stats.service.ts               ← Task 15 (modify)
```

---

## Regras de Negócio

### XP por evento

| Evento | Motivo | XP |
|--------|--------|----|
| `open-game.stats-recorded` | participação | +10 |
| `open-game.stats-recorded` | por gol marcado | +5 cada |
| `open-game.stats-recorded` | por assistência | +3 cada |
| `game.match-completed` | participação (stub) | +20 |

### Fórmula de nível

```
level = Math.floor(totalXp / 100) + 1
```
Exemplos: 0 XP → nível 1; 100 XP → nível 2; 400 XP → nível 5; 900 XP → nível 10.

### Badges disponíveis

| Código | Descrição | Critério |
|--------|-----------|----------|
| `first-game` | Primeira partida | Primeira entrada no XP ledger |
| `goal-scorer` | Artilheiro estreante | Primeira entrada de gol no XP ledger |
| `level-5` | Nível 5 | totalXp atingiu 400 (level ≥ 5) |
| `level-10` | Nível 10 | totalXp atingiu 900 (level ≥ 10) |

### Idempotência no XP ledger

A tabela `xp_ledger` tem constraint UNIQUE `(player_user_id, source_id, reason)`. Se o mesmo evento for reprocessado, o INSERT usa `onConflictDoNothing` e retorna `null` — nenhum XP duplicado.

---

## Contexto de Desenvolvimento

Branch: `feature/gamification-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/gamification/` salvo indicação contrária.

### Regras inegociáveis (reforço)
- Drizzle ORM (NUNCA TypeORM)
- Biome (NUNCA ESLint/Prettier)
- BIGSERIAL PK interno; nenhuma entidade gamification é exposta por UUID (sem external_id necessário)
- Timestamps: sempre `timestamptz` (`withTimezone: true`)
- Fire-and-forget: chamadas de `messaging.publish*` APÓS commit no DB, dentro de `try/catch`
- Caminhos relativos em `infra/database/repositories/` para `domain/`: precisam de `../../../` (3 níveis) para chegar em `gamification/domain/`
- Idempotência em consumers RabbitMQ (try/catch sem rethrow)
- Sem Redis neste serviço

---

### Task 1: `.env.example`

**Files:**
- Create: `services/gamification/.env.example`

- [ ] **Step 1: Criar `.env.example`**

```
PORT=4006
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_gamification
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/gamification/.env.example
git commit -m "chore(gamification): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/gamification/drizzle.config.ts`

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
git add services/gamification/drizzle.config.ts
git commit -m "chore(gamification): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/gamification/nest-cli.json`

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
git add services/gamification/nest-cli.json
git commit -m "chore(gamification): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/gamification/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/gamification",
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
    "pg": "^8.13.0",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
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
cd services/gamification
npm install --legacy-peer-deps
```

Expected: `node_modules/` criado sem erros fatais.

- [ ] **Step 3: Commit**

```bash
git add services/gamification/package.json services/gamification/package-lock.json
git commit -m "chore(gamification): add package.json"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/gamification/tsconfig.json`
- Create: `services/gamification/tsconfig.build.json`

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
      "pg": ["./node_modules/@types/pg"],
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
git add services/gamification/tsconfig.json services/gamification/tsconfig.build.json
git commit -m "chore(gamification): add tsconfig files"
```

---

### Task 6: Domain entities

**Files:**
- Create: `services/gamification/src/modules/gamification/domain/models/player-profile.entity.ts`
- Create: `services/gamification/src/modules/gamification/domain/models/xp-ledger.entity.ts`
- Create: `services/gamification/src/modules/gamification/domain/models/player-badge.entity.ts`

- [ ] **Step 1: Criar player-profile.entity.ts**

```typescript
export class PlayerProfile {
  playerUserId!: string;
  displayName!: string;
  totalXp!: number;
  level!: number;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Criar xp-ledger.entity.ts**

```typescript
export type XpSourceType = 'open-game' | 'game';
export type XpReason = 'participation' | 'goal' | 'assist' | 'win';

export class XpLedgerEntry {
  id!: number;
  playerUserId!: string;
  sourceType!: XpSourceType;
  sourceId!: string;
  xpEarned!: number;
  reason!: XpReason;
  createdAt!: Date;
}
```

- [ ] **Step 3: Criar player-badge.entity.ts**

```typescript
export type BadgeCode = 'first-game' | 'goal-scorer' | 'level-5' | 'level-10';

export class PlayerBadge {
  playerUserId!: string;
  badgeCode!: BadgeCode;
  earnedAt!: Date;
}
```

- [ ] **Step 4: Commit**

```bash
git add services/gamification/src/modules/gamification/domain/models/
git commit -m "feat(gamification): add domain entities"
```

---

### Task 7: Database schemas

**Files:**
- Create: `services/gamification/src/modules/gamification/infra/database/schemas/player-profile.schema.ts`
- Create: `services/gamification/src/modules/gamification/infra/database/schemas/xp-ledger.schema.ts`
- Create: `services/gamification/src/modules/gamification/infra/database/schemas/player-badge.schema.ts`

- [ ] **Step 1: Criar player-profile.schema.ts**

```typescript
import { pgTable, bigserial, text, integer, smallint, timestamp } from 'drizzle-orm/pg-core';

export const playerProfiles = pgTable('player_profiles', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  playerUserId: text('player_user_id').notNull().unique(),
  displayName: text('display_name').notNull().default(''),
  totalXp: integer('total_xp').notNull().default(0),
  level: smallint('level').notNull().default(1),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PlayerProfileRow = typeof playerProfiles.$inferSelect;
```

- [ ] **Step 2: Criar xp-ledger.schema.ts**

```typescript
import { pgTable, bigserial, text, smallint, timestamp, unique } from 'drizzle-orm/pg-core';

export const xpLedger = pgTable(
  'xp_ledger',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    sourceType: text('source_type').notNull(),
    sourceId: text('source_id').notNull(),
    xpEarned: smallint('xp_earned').notNull(),
    reason: text('reason').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_xp_ledger_player_source_reason').on(t.playerUserId, t.sourceId, t.reason)],
);

export type XpLedgerRow = typeof xpLedger.$inferSelect;
```

- [ ] **Step 3: Criar player-badge.schema.ts**

```typescript
import { pgTable, bigserial, text, timestamp, unique } from 'drizzle-orm/pg-core';

export const playerBadges = pgTable(
  'player_badges',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    badgeCode: text('badge_code').notNull(),
    earnedAt: timestamp('earned_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_player_badge').on(t.playerUserId, t.badgeCode)],
);

export type PlayerBadgeRow = typeof playerBadges.$inferSelect;
```

- [ ] **Step 4: Commit**

```bash
git add services/gamification/src/modules/gamification/infra/database/schemas/
git commit -m "feat(gamification): add Drizzle schemas"
```

---

### Task 8: Repository interfaces

**Files:**
- Create: `services/gamification/src/modules/gamification/domain/repositories/profile-repository.interface.ts`
- Create: `services/gamification/src/modules/gamification/domain/repositories/xp-ledger-repository.interface.ts`
- Create: `services/gamification/src/modules/gamification/domain/repositories/badge-repository.interface.ts`

- [ ] **Step 1: Criar profile-repository.interface.ts**

```typescript
import type { PlayerProfile } from '../models/player-profile.entity';

export const PROFILE_REPOSITORY = 'PROFILE_REPOSITORY';

export interface ProfileRepositoryInterface {
  /** Cria perfil com 0 XP se não existir; retorna o perfil existente caso já exista. */
  upsertProfile(playerUserId: string, displayName: string): Promise<PlayerProfile>;
  findByPlayer(playerUserId: string): Promise<PlayerProfile | null>;
  /** Incrementa totalXp e recalcula level; retorna o perfil atualizado. */
  addXp(playerUserId: string, xpToAdd: number): Promise<PlayerProfile>;
  updateDisplayName(playerUserId: string, displayName: string): Promise<void>;
  findTopByXp(limit: number): Promise<PlayerProfile[]>;
}
```

- [ ] **Step 2: Criar xp-ledger-repository.interface.ts**

```typescript
import type { XpLedgerEntry, XpSourceType, XpReason } from '../models/xp-ledger.entity';

export const XP_LEDGER_REPOSITORY = 'XP_LEDGER_REPOSITORY';

export interface RecordXpData {
  playerUserId: string;
  sourceType: XpSourceType;
  sourceId: string;
  xpEarned: number;
  reason: XpReason;
}

export interface XpLedgerRepositoryInterface {
  /** Insere entrada de XP. Retorna null se a entrada já existir (idempotente). */
  recordXp(data: RecordXpData): Promise<XpLedgerEntry | null>;
  /** Retorna true se o jogador possui ao menos uma entrada com reason='goal'. */
  hasGoal(playerUserId: string): Promise<boolean>;
}
```

- [ ] **Step 3: Criar badge-repository.interface.ts**

```typescript
import type { PlayerBadge, BadgeCode } from '../models/player-badge.entity';

export const BADGE_REPOSITORY = 'BADGE_REPOSITORY';

export interface BadgeRepositoryInterface {
  /** Concede badge ao jogador. Retorna null se já possuía o badge (idempotente). */
  awardBadge(playerUserId: string, badgeCode: BadgeCode): Promise<PlayerBadge | null>;
  findEarnedBadges(playerUserId: string): Promise<PlayerBadge[]>;
}
```

- [ ] **Step 4: Commit**

```bash
git add services/gamification/src/modules/gamification/domain/repositories/
git commit -m "feat(gamification): add repository interfaces"
```

---

### Task 9: `DrizzleProfileRepository`

**Files:**
- Create: `services/gamification/src/modules/gamification/infra/database/repositories/drizzle-profile.repository.ts`

- [ ] **Step 1: Criar drizzle-profile.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { eq, desc, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { ProfileRepositoryInterface } from '../../../domain/repositories/profile-repository.interface';
import type { PlayerProfile } from '../../../domain/models/player-profile.entity';
import { playerProfiles, type PlayerProfileRow } from '../schemas/player-profile.schema';

@Injectable()
export class DrizzleProfileRepository implements ProfileRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsertProfile(playerUserId: string, displayName: string): Promise<PlayerProfile> {
    const [row] = await this.drizzle.db
      .insert(playerProfiles)
      .values({ playerUserId, displayName, totalXp: 0, level: 1 })
      .onConflictDoUpdate({
        target: playerProfiles.playerUserId,
        set: { updatedAt: new Date() },
      })
      .returning();
    return this.toProfile(row);
  }

  async findByPlayer(playerUserId: string): Promise<PlayerProfile | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerProfiles)
      .where(eq(playerProfiles.playerUserId, playerUserId))
      .limit(1);
    return row ? this.toProfile(row) : null;
  }

  async addXp(playerUserId: string, xpToAdd: number): Promise<PlayerProfile> {
    const newTotalXp = sql<number>`${playerProfiles.totalXp} + ${xpToAdd}`;
    const newLevel = sql<number>`floor((${playerProfiles.totalXp} + ${xpToAdd}) / 100) + 1`;

    const [row] = await this.drizzle.db
      .update(playerProfiles)
      .set({
        totalXp: newTotalXp,
        level: newLevel,
        updatedAt: new Date(),
      })
      .where(eq(playerProfiles.playerUserId, playerUserId))
      .returning();

    if (!row) throw new Error(`PlayerProfile "${playerUserId}" not found`);
    return this.toProfile(row);
  }

  async updateDisplayName(playerUserId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerProfiles)
      .set({ displayName, updatedAt: new Date() })
      .where(eq(playerProfiles.playerUserId, playerUserId));
  }

  async findTopByXp(limit: number): Promise<PlayerProfile[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerProfiles)
      .orderBy(desc(playerProfiles.totalXp))
      .limit(limit);
    return rows.map((r) => this.toProfile(r));
  }

  private toProfile(row: PlayerProfileRow): PlayerProfile {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      totalXp: row.totalXp,
      level: row.level,
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/infra/database/repositories/drizzle-profile.repository.ts
git commit -m "feat(gamification): add DrizzleProfileRepository"
```

---

### Task 10: `DrizzleXpBadgeRepository`

**Files:**
- Create: `services/gamification/src/modules/gamification/infra/database/repositories/drizzle-xp-badge.repository.ts`

- [ ] **Step 1: Criar drizzle-xp-badge.repository.ts**

Implementa tanto `XpLedgerRepositoryInterface` quanto `BadgeRepositoryInterface` em uma única classe (ambas precisam de acesso ao banco, são leves, e evitam proliferação desnecessária de arquivos).

```typescript
import { Injectable } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { XpLedgerRepositoryInterface, RecordXpData } from '../../../domain/repositories/xp-ledger-repository.interface';
import type { BadgeRepositoryInterface } from '../../../domain/repositories/badge-repository.interface';
import type { XpLedgerEntry } from '../../../domain/models/xp-ledger.entity';
import type { PlayerBadge, BadgeCode } from '../../../domain/models/player-badge.entity';
import { xpLedger, type XpLedgerRow } from '../schemas/xp-ledger.schema';
import { playerBadges, type PlayerBadgeRow } from '../schemas/player-badge.schema';

@Injectable()
export class DrizzleXpBadgeRepository
  implements XpLedgerRepositoryInterface, BadgeRepositoryInterface
{
  constructor(private readonly drizzle: DrizzleService) {}

  async recordXp(data: RecordXpData): Promise<XpLedgerEntry | null> {
    const [row] = await this.drizzle.db
      .insert(xpLedger)
      .values({
        playerUserId: data.playerUserId,
        sourceType: data.sourceType,
        sourceId: data.sourceId,
        xpEarned: data.xpEarned,
        reason: data.reason,
      })
      .onConflictDoNothing()
      .returning();

    return row ? this.toEntry(row) : null;
  }

  async hasGoal(playerUserId: string): Promise<boolean> {
    const [row] = await this.drizzle.db
      .select({ id: xpLedger.id })
      .from(xpLedger)
      .where(
        and(
          eq(xpLedger.playerUserId, playerUserId),
          eq(xpLedger.reason, 'goal'),
        ),
      )
      .limit(1);
    return !!row;
  }

  async awardBadge(playerUserId: string, badgeCode: BadgeCode): Promise<PlayerBadge | null> {
    const [row] = await this.drizzle.db
      .insert(playerBadges)
      .values({ playerUserId, badgeCode })
      .onConflictDoNothing()
      .returning();
    return row ? this.toBadge(row) : null;
  }

  async findEarnedBadges(playerUserId: string): Promise<PlayerBadge[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerBadges)
      .where(eq(playerBadges.playerUserId, playerUserId));
    return rows.map((r) => this.toBadge(r));
  }

  private toEntry(row: XpLedgerRow): XpLedgerEntry {
    return {
      id: row.id,
      playerUserId: row.playerUserId,
      sourceType: row.sourceType as XpLedgerEntry['sourceType'],
      sourceId: row.sourceId,
      xpEarned: row.xpEarned,
      reason: row.reason as XpLedgerEntry['reason'],
      createdAt: row.createdAt,
    };
  }

  private toBadge(row: PlayerBadgeRow): PlayerBadge {
    return {
      playerUserId: row.playerUserId,
      badgeCode: row.badgeCode as BadgeCode,
      earnedAt: row.earnedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/infra/database/repositories/drizzle-xp-badge.repository.ts
git commit -m "feat(gamification): add DrizzleXpBadgeRepository"
```

---

### Task 11: DTOs

**Files:**
- Create: `services/gamification/src/modules/gamification/application/dto/profile.dto.ts`
- Create: `services/gamification/src/modules/gamification/application/dto/leaderboard-entry.dto.ts`

- [ ] **Step 1: Criar profile.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

export class BadgeDto {
  @ApiProperty() badgeCode!: string;
  @ApiProperty() earnedAt!: Date;

  static fromBadge(b: PlayerBadge): BadgeDto {
    const dto = new BadgeDto();
    dto.badgeCode = b.badgeCode;
    dto.earnedAt = b.earnedAt;
    return dto;
  }
}

export class ProfileDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalXp!: number;
  @ApiProperty() level!: number;
  @ApiProperty({ type: [BadgeDto] }) badges!: BadgeDto[];
  @ApiProperty() updatedAt!: Date;

  static from(profile: PlayerProfile, badges: PlayerBadge[]): ProfileDto {
    const dto = new ProfileDto();
    dto.playerUserId = profile.playerUserId;
    dto.displayName = profile.displayName;
    dto.totalXp = profile.totalXp;
    dto.level = profile.level;
    dto.badges = badges.map((b) => BadgeDto.fromBadge(b));
    dto.updatedAt = profile.updatedAt;
    return dto;
  }

  static empty(playerUserId: string): ProfileDto {
    const dto = new ProfileDto();
    dto.playerUserId = playerUserId;
    dto.displayName = '';
    dto.totalXp = 0;
    dto.level = 1;
    dto.badges = [];
    dto.updatedAt = new Date(0);
    return dto;
  }
}
```

- [ ] **Step 2: Criar leaderboard-entry.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

export class LeaderboardEntryDto {
  @ApiProperty() rank!: number;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalXp!: number;
  @ApiProperty() level!: number;

  static from(profile: PlayerProfile, rank: number): LeaderboardEntryDto {
    const dto = new LeaderboardEntryDto();
    dto.rank = rank;
    dto.playerUserId = profile.playerUserId;
    dto.displayName = profile.displayName;
    dto.totalXp = profile.totalXp;
    dto.level = profile.level;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/gamification/src/modules/gamification/application/dto/
git commit -m "feat(gamification): add DTOs"
```

---

### Task 12: `GamificationMessagingService`

**Files:**
- Create: `services/gamification/src/modules/gamification/application/services/gamification-messaging.service.ts`

- [ ] **Step 1: Criar gamification-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { GamificationEvents } from '@shared/contracts/events/gamification-events.enum';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

@Injectable()
export class GamificationMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishBadgeAwarded(badge: PlayerBadge): Promise<void> {
    await this.messaging.publish(GamificationEvents.BADGE_AWARDED, {
      playerUserId: badge.playerUserId,
      badgeCode: badge.badgeCode,
      earnedAt: badge.earnedAt,
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/application/services/gamification-messaging.service.ts
git commit -m "feat(gamification): add GamificationMessagingService"
```

---

### Task 13: `XpService` (TDD)

**Files:**
- Create: `services/gamification/src/modules/gamification/application/services/xp.service.spec.ts`
- Create: `services/gamification/src/modules/gamification/application/services/xp.service.ts`

- [ ] **Step 1: Escrever os testes primeiro**

```typescript
// xp.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { XpService } from './xp.service';
import { PROFILE_REPOSITORY } from '../../domain/repositories/profile-repository.interface';
import { XP_LEDGER_REPOSITORY } from '../../domain/repositories/xp-ledger-repository.interface';
import { BADGE_REPOSITORY } from '../../domain/repositories/badge-repository.interface';
import { GamificationMessagingService } from './gamification-messaging.service';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

const mockProfile = (overrides: Partial<PlayerProfile> = {}): PlayerProfile => ({
  playerUserId: 'user-1',
  displayName: 'Alice',
  totalXp: 0,
  level: 1,
  updatedAt: new Date(),
  ...overrides,
});

const mockBadge = (badgeCode: string): PlayerBadge => ({
  playerUserId: 'user-1',
  badgeCode: badgeCode as PlayerBadge['badgeCode'],
  earnedAt: new Date(),
});

describe('XpService', () => {
  let service: XpService;
  let profileRepo: { upsertProfile: jest.Mock; findByPlayer: jest.Mock; addXp: jest.Mock; updateDisplayName: jest.Mock; findTopByXp: jest.Mock };
  let xpLedgerRepo: { recordXp: jest.Mock; hasGoal: jest.Mock };
  let badgeRepo: { awardBadge: jest.Mock; findEarnedBadges: jest.Mock };
  let messaging: { publishBadgeAwarded: jest.Mock };

  beforeEach(async () => {
    profileRepo = {
      upsertProfile: jest.fn(),
      findByPlayer: jest.fn(),
      addXp: jest.fn(),
      updateDisplayName: jest.fn(),
      findTopByXp: jest.fn(),
    };
    xpLedgerRepo = {
      recordXp: jest.fn(),
      hasGoal: jest.fn(),
    };
    badgeRepo = {
      awardBadge: jest.fn(),
      findEarnedBadges: jest.fn(),
    };
    messaging = { publishBadgeAwarded: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        XpService,
        { provide: PROFILE_REPOSITORY, useValue: profileRepo },
        { provide: XP_LEDGER_REPOSITORY, useValue: xpLedgerRepo },
        { provide: BADGE_REPOSITORY, useValue: badgeRepo },
        { provide: GamificationMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<XpService>(XpService);
  });

  describe('processOpenGameStats', () => {
    it('grants participation XP and first-game badge on first game', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      // participation: new entry (not null = granted)
      xpLedgerRepo.recordXp.mockImplementation(async (data) => {
        if (data.reason === 'participation') return { ...data, id: 1, createdAt: new Date() };
        return null;
      });
      badgeRepo.awardBadge.mockImplementation(async (_, code) =>
        code === 'first-game' ? mockBadge('first-game') : null,
      );
      const afterXp = mockProfile({ totalXp: 10, level: 1 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(profileRepo.upsertProfile).toHaveBeenCalledWith('user-1', 'Alice');
      expect(xpLedgerRepo.recordXp).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-1', reason: 'participation', xpEarned: 10 }),
      );
      expect(profileRepo.addXp).toHaveBeenCalledWith('user-1', 10);
      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'first-game');
      expect(messaging.publishBadgeAwarded).toHaveBeenCalled();
    });

    it('skips XP grant when participation already recorded (idempotent)', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      // null = already exists
      xpLedgerRepo.recordXp.mockResolvedValue(null);
      badgeRepo.awardBadge.mockResolvedValue(null);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(profileRepo.addXp).not.toHaveBeenCalled();
    });

    it('grants goal XP and goal-scorer badge on first goal', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      xpLedgerRepo.recordXp.mockImplementation(async (data) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(true); // now has goal after insert
      badgeRepo.awardBadge.mockImplementation(async (_, code) =>
        mockBadge(code),
      );
      profileRepo.addXp.mockResolvedValue(mockProfile({ totalXp: 15, level: 1 }));
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 1, assists: 0 }],
      });

      // participation (10) + goal (5)
      const xpCalls = xpLedgerRepo.recordXp.mock.calls.map((c: any[]) => c[0]);
      expect(xpCalls).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ reason: 'participation', xpEarned: 10 }),
          expect.objectContaining({ reason: 'goal', xpEarned: 5 }),
        ]),
      );
      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'goal-scorer');
    });

    it('awards level-5 badge when totalXp crosses 400', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile({ totalXp: 390 }));
      xpLedgerRepo.recordXp.mockImplementation(async (data) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(false);
      const afterXp = mockProfile({ totalXp: 400, level: 5 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      badgeRepo.awardBadge.mockImplementation(async (_, code) =>
        code === 'level-5' ? mockBadge('level-5') : null,
      );
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-2',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'level-5');
      expect(messaging.publishBadgeAwarded).toHaveBeenCalledWith(
        expect.objectContaining({ badgeCode: 'level-5' }),
      );
    });

    it('awards level-10 badge when totalXp crosses 900', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile({ totalXp: 890 }));
      xpLedgerRepo.recordXp.mockImplementation(async (data) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(false);
      const afterXp = mockProfile({ totalXp: 900, level: 10 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      badgeRepo.awardBadge.mockImplementation(async (_, code) =>
        code === 'level-10' ? mockBadge('level-10') : null,
      );
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-3',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'level-10');
    });
  });

  describe('getProfile', () => {
    it('returns profile with badges for existing player', async () => {
      profileRepo.findByPlayer.mockResolvedValue(mockProfile({ totalXp: 50 }));
      badgeRepo.findEarnedBadges.mockResolvedValue([mockBadge('first-game')]);

      const result = await service.getProfile('user-1');

      expect(result.profile.totalXp).toBe(50);
      expect(result.badges).toHaveLength(1);
      expect(result.badges[0].badgeCode).toBe('first-game');
    });

    it('returns null profile for unknown player', async () => {
      profileRepo.findByPlayer.mockResolvedValue(null);
      badgeRepo.findEarnedBadges.mockResolvedValue([]);

      const result = await service.getProfile('unknown');

      expect(result.profile).toBeNull();
    });
  });
});
```

- [ ] **Step 2: Rodar os testes para confirmar FAIL**

```bash
cd services/gamification
npm test -- --testPathPattern="xp.service.spec"
```

Expected: FAIL com "Cannot find module './xp.service'".

- [ ] **Step 3: Implementar xp.service.ts**

```typescript
import { Inject, Injectable } from '@nestjs/common';
import {
  PROFILE_REPOSITORY,
  ProfileRepositoryInterface,
} from '../../domain/repositories/profile-repository.interface';
import {
  XP_LEDGER_REPOSITORY,
  XpLedgerRepositoryInterface,
} from '../../domain/repositories/xp-ledger-repository.interface';
import {
  BADGE_REPOSITORY,
  BadgeRepositoryInterface,
} from '../../domain/repositories/badge-repository.interface';
import { GamificationMessagingService } from './gamification-messaging.service';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge, BadgeCode } from '../../domain/models/player-badge.entity';

export interface OpenGameStatsPayload {
  gameId: string;
  players: Array<{
    playerUserId: string;
    displayName: string;
    goals: number;
    assists: number;
  }>;
}

@Injectable()
export class XpService {
  constructor(
    @Inject(PROFILE_REPOSITORY)
    private readonly profileRepo: ProfileRepositoryInterface,
    @Inject(XP_LEDGER_REPOSITORY)
    private readonly xpLedgerRepo: XpLedgerRepositoryInterface,
    @Inject(BADGE_REPOSITORY)
    private readonly badgeRepo: BadgeRepositoryInterface,
    private readonly messaging: GamificationMessagingService,
  ) {}

  async processOpenGameStats(payload: OpenGameStatsPayload): Promise<void> {
    for (const player of payload.players) {
      await this.grantXpForPlayer(player.playerUserId, player.displayName, payload.gameId, player.goals, player.assists);
    }
  }

  async handleUserRegistered(playerUserId: string, displayName: string): Promise<void> {
    await this.profileRepo.upsertProfile(playerUserId, displayName);
  }

  async handleProfileUpdated(playerUserId: string, displayName: string): Promise<void> {
    await this.profileRepo.updateDisplayName(playerUserId, displayName);
  }

  async getProfile(playerUserId: string): Promise<{ profile: PlayerProfile | null; badges: PlayerBadge[] }> {
    const [profile, badges] = await Promise.all([
      this.profileRepo.findByPlayer(playerUserId),
      this.badgeRepo.findEarnedBadges(playerUserId),
    ]);
    return { profile, badges };
  }

  async getLeaderboard(): Promise<PlayerProfile[]> {
    return this.profileRepo.findTopByXp(10);
  }

  private async grantXpForPlayer(
    playerUserId: string,
    displayName: string,
    gameId: string,
    goals: number,
    assists: number,
  ): Promise<void> {
    await this.profileRepo.upsertProfile(playerUserId, displayName);

    let totalXpToAdd = 0;
    let isFirstGame = false;
    let earnedGoal = false;

    // Participation XP
    const participationEntry = await this.xpLedgerRepo.recordXp({
      playerUserId,
      sourceType: 'open-game',
      sourceId: gameId,
      xpEarned: 10,
      reason: 'participation',
    });
    if (participationEntry) {
      totalXpToAdd += 10;
      isFirstGame = true;
    } else {
      // already processed — skip to avoid double XP
      return;
    }

    // Goal XP
    if (goals > 0) {
      const goalEntry = await this.xpLedgerRepo.recordXp({
        playerUserId,
        sourceType: 'open-game',
        sourceId: gameId,
        xpEarned: goals * 5,
        reason: 'goal',
      });
      if (goalEntry) {
        totalXpToAdd += goals * 5;
        earnedGoal = true;
      }
    }

    // Assist XP
    if (assists > 0) {
      const assistEntry = await this.xpLedgerRepo.recordXp({
        playerUserId,
        sourceType: 'open-game',
        sourceId: gameId,
        xpEarned: assists * 3,
        reason: 'assist',
      });
      if (assistEntry) {
        totalXpToAdd += assists * 3;
      }
    }

    if (totalXpToAdd === 0) return;

    const updatedProfile = await this.profileRepo.addXp(playerUserId, totalXpToAdd);

    // Check and award badges (fire-and-forget per badge)
    const badgesToCheck: BadgeCode[] = [];

    if (isFirstGame) {
      badgesToCheck.push('first-game');
    }

    if (earnedGoal) {
      const hasGoalNow = await this.xpLedgerRepo.hasGoal(playerUserId);
      if (hasGoalNow) {
        badgesToCheck.push('goal-scorer');
      }
    }

    if (updatedProfile.level >= 5) {
      badgesToCheck.push('level-5');
    }

    if (updatedProfile.level >= 10) {
      badgesToCheck.push('level-10');
    }

    try {
      for (const badgeCode of badgesToCheck) {
        const badge = await this.badgeRepo.awardBadge(playerUserId, badgeCode);
        if (badge) {
          await this.messaging.publishBadgeAwarded(badge);
        }
      }
    } catch {
      // fire-and-forget
    }
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar PASS**

```bash
cd services/gamification
npm test -- --testPathPattern="xp.service.spec"
```

Expected: PASS — 6 testes passando.

- [ ] **Step 5: Commit**

```bash
git add services/gamification/src/modules/gamification/application/services/xp.service.spec.ts
git add services/gamification/src/modules/gamification/application/services/xp.service.ts
git commit -m "feat(gamification): add XpService with TDD (6/6 tests)"
```

---

### Task 14: `IdentityEventsConsumer`

**Files:**
- Create: `services/gamification/src/modules/gamification/application/services/identity-events.consumer.ts`

- [ ] **Step 1: Criar identity-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { XpService } from './xp.service';

interface UserRegisteredPayload {
  userId: string;
  displayName: string;
}

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(private readonly xpService: XpService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.USER_REGISTERED,
    queue: 'gamification-service.identity.user-registered',
    queueOptions: { durable: true },
  })
  async handleUserRegistered(payload: UserRegisteredPayload): Promise<void> {
    try {
      await this.xpService.handleUserRegistered(payload.userId, payload.displayName);
      this.logger.debug(`Created profile for new user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to create profile for user ${payload.userId}: ${message}`);
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'gamification-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.xpService.handleProfileUpdated(payload.userId, payload.displayName);
      this.logger.debug(`Updated displayName for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to update displayName for user ${payload.userId}: ${message}`);
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/application/services/identity-events.consumer.ts
git commit -m "feat(gamification): add IdentityEventsConsumer"
```

---

### Task 15: `OpenGameEventsConsumer` + enriquecer `open-game.stats-recorded`

Esta task tem duas partes: (A) enriquecer o payload do evento no open-game service; (B) criar o consumer no gamification service.

**Files:**
- Modify: `services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts`
- Modify: `services/open-game/src/modules/open-game/stats/application/services/stats.service.ts`
- Create: `services/gamification/src/modules/gamification/application/services/open-game-events.consumer.ts`

- [ ] **Step 1: Modificar `open-game-messaging.service.ts` para incluir players no payload**

Arquivo atual: `services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts`

Localizar o método `publishStatsRecorded` e substituir:

```typescript
// ANTES:
async publishStatsRecorded(game: OpenGame): Promise<void> {
  await this.messaging.publish(OpenGameEvents.STATS_RECORDED, {
    gameId: game.id,
  });
}

// DEPOIS:
async publishStatsRecorded(
  game: OpenGame,
  players: Array<{ playerUserId: string; goals: number; assists: number }>,
): Promise<void> {
  await this.messaging.publish(OpenGameEvents.STATS_RECORDED, {
    gameId: game.id,
    sport: game.sport,
    players,
  });
}
```

- [ ] **Step 2: Modificar `stats.service.ts` para passar player stats ao publicar**

Arquivo: `services/open-game/src/modules/open-game/stats/application/services/stats.service.ts`

Localizar o bloco `try { await this.messaging.publishStatsRecorded(game); }` e substituir:

```typescript
// ANTES:
try {
  await this.messaging.publishStatsRecorded(game);
} catch {
  // advisory
}

// DEPOIS:
try {
  await this.messaging.publishStatsRecorded(
    game,
    stats.map((s) => ({
      playerUserId: s.playerUserId,
      goals: s.goals,
      assists: s.assists,
    })),
  );
} catch {
  // advisory
}
```

- [ ] **Step 3: Criar open-game-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';
import { XpService, type OpenGameStatsPayload } from './xp.service';

interface StatsRecordedPayload {
  gameId: string;
  sport: string;
  players: Array<{
    playerUserId: string;
    displayName?: string;
    goals: number;
    assists: number;
  }>;
}

@Injectable()
export class OpenGameEventsConsumer {
  private readonly logger = new Logger(OpenGameEventsConsumer.name);

  constructor(private readonly xpService: XpService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: OpenGameEvents.STATS_RECORDED,
    queue: 'gamification-service.open-game.stats-recorded',
    queueOptions: { durable: true },
  })
  async handleStatsRecorded(payload: StatsRecordedPayload): Promise<void> {
    try {
      const xpPayload: OpenGameStatsPayload = {
        gameId: payload.gameId,
        players: (payload.players ?? []).map((p) => ({
          playerUserId: p.playerUserId,
          displayName: p.displayName ?? '',
          goals: p.goals,
          assists: p.assists,
        })),
      };
      await this.xpService.processOpenGameStats(xpPayload);
      this.logger.debug(`Processed stats for game ${payload.gameId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to process stats for game ${payload.gameId}: ${message}`);
    }
  }
}
```

- [ ] **Step 4: Verificar que o build do open-game ainda compila**

```bash
cd services/open-game
npm run build
```

Expected: compilação sem erros.

- [ ] **Step 5: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts
git add services/open-game/src/modules/open-game/stats/application/services/stats.service.ts
git add services/gamification/src/modules/gamification/application/services/open-game-events.consumer.ts
git commit -m "feat(gamification): add OpenGameEventsConsumer + enrich stats-recorded payload"
```

---

### Task 16: `GameEventsConsumer` (stub)

**Files:**
- Create: `services/gamification/src/modules/gamification/application/services/game-events.consumer.ts`

O game service ainda não foi implementado. Este consumer registra a queue e loga o evento para processamento futuro.

- [ ] **Step 1: Criar game-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';

interface MatchCompletedPayload {
  gameId: string;
  [key: string]: unknown;
}

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'gamification-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    // Stub: game service não implementado ainda.
    // Quando implementado, processar XP de partida competitiva.
    this.logger.debug(`[stub] Received match-completed for game ${payload.gameId}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/application/services/game-events.consumer.ts
git commit -m "feat(gamification): add GameEventsConsumer stub"
```

---

### Task 17: `GamificationController`

**Files:**
- Create: `services/gamification/src/modules/gamification/infra/controllers/gamification.controller.ts`

- [ ] **Step 1: Criar gamification.controller.ts**

```typescript
import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { XpService } from '../../application/services/xp.service';
import { ProfileDto } from '../../application/dto/profile.dto';
import { LeaderboardEntryDto } from '../../application/dto/leaderboard-entry.dto';

@ApiTags('Gamification')
@Controller()
export class GamificationController {
  constructor(private readonly xpService: XpService) {}

  @Get('profiles/:userId')
  @ApiOperation({ summary: 'Get player profile (XP, level, badges)' })
  async getProfile(@Param('userId') userId: string): Promise<ProfileDto> {
    const { profile, badges } = await this.xpService.getProfile(userId);
    if (!profile) throw new NotFoundException(`Profile for player "${userId}" not found`);
    return ProfileDto.from(profile, badges);
  }

  @Get('leaderboard')
  @ApiOperation({ summary: 'Top 10 players by XP' })
  async getLeaderboard(): Promise<LeaderboardEntryDto[]> {
    const profiles = await this.xpService.getLeaderboard();
    return profiles.map((p, i) => LeaderboardEntryDto.from(p, i + 1));
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/infra/controllers/gamification.controller.ts
git commit -m "feat(gamification): add GamificationController"
```

---

### Task 18: `GamificationModule`

**Files:**
- Create: `services/gamification/src/modules/gamification/gamification.module.ts`

- [ ] **Step 1: Criar gamification.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { PROFILE_REPOSITORY } from './domain/repositories/profile-repository.interface';
import { XP_LEDGER_REPOSITORY } from './domain/repositories/xp-ledger-repository.interface';
import { BADGE_REPOSITORY } from './domain/repositories/badge-repository.interface';
import { DrizzleProfileRepository } from './infra/database/repositories/drizzle-profile.repository';
import { DrizzleXpBadgeRepository } from './infra/database/repositories/drizzle-xp-badge.repository';
import { XpService } from './application/services/xp.service';
import { GamificationMessagingService } from './application/services/gamification-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { OpenGameEventsConsumer } from './application/services/open-game-events.consumer';
import { GameEventsConsumer } from './application/services/game-events.consumer';
import { GamificationController } from './infra/controllers/gamification.controller';

@Module({
  imports: [SharedModule],
  controllers: [GamificationController],
  providers: [
    { provide: PROFILE_REPOSITORY, useClass: DrizzleProfileRepository },
    { provide: XP_LEDGER_REPOSITORY, useClass: DrizzleXpBadgeRepository },
    { provide: BADGE_REPOSITORY, useClass: DrizzleXpBadgeRepository },
    XpService,
    GamificationMessagingService,
    IdentityEventsConsumer,
    OpenGameEventsConsumer,
    GameEventsConsumer,
  ],
})
export class GamificationModule {}
```

**Atenção:** `DrizzleXpBadgeRepository` é registrado para DOIS tokens (`XP_LEDGER_REPOSITORY` e `BADGE_REPOSITORY`) pois implementa ambas as interfaces. O NestJS criará uma instância por token — aceitável para este serviço leve.

- [ ] **Step 2: Commit**

```bash
git add services/gamification/src/modules/gamification/gamification.module.ts
git commit -m "feat(gamification): add GamificationModule"
```

---

### Task 19: `AppModule` + `main.ts`

**Files:**
- Create: `services/gamification/src/app.module.ts`
- Create: `services/gamification/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GamificationModule } from './modules/gamification/gamification.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    GamificationModule,
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

- [ ] **Step 3: Rodar build para verificar tipos**

```bash
cd services/gamification
npm run build
```

Expected: compilação sem erros. Corrigir quaisquer erros de import (lembrar: `infra/database/repositories/` → `../../../domain/` = 3 níveis).

- [ ] **Step 4: Commit**

```bash
git add services/gamification/src/app.module.ts services/gamification/src/main.ts
git commit -m "feat(gamification): add AppModule and main.ts"
```

---

### Task 20: Migration SQL

**Files:**
- Create: `services/gamification/drizzle/0000_initial_gamification.sql`
- Create: `services/gamification/drizzle/meta/_journal.json`

- [ ] **Step 1: Gerar migration via Drizzle Kit**

```bash
cd services/gamification
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_gamification npm run db:generate
```

Expected: cria `drizzle/0000_initial_gamification.sql` e `drizzle/meta/_journal.json`.

Se não for possível conectar ao banco (ambiente local sem DB), criar manualmente:

`drizzle/0000_initial_gamification.sql`:
```sql
CREATE TABLE "player_profiles" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "display_name" text DEFAULT '' NOT NULL,
  "total_xp" integer DEFAULT 0 NOT NULL,
  "level" smallint DEFAULT 1 NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "player_profiles_player_user_id_unique" UNIQUE("player_user_id")
);

CREATE TABLE "xp_ledger" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "source_type" text NOT NULL,
  "source_id" text NOT NULL,
  "xp_earned" smallint NOT NULL,
  "reason" text NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_xp_ledger_player_source_reason" UNIQUE("player_user_id","source_id","reason")
);

CREATE TABLE "player_badges" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "badge_code" text NOT NULL,
  "earned_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_player_badge" UNIQUE("player_user_id","badge_code")
);
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
      "when": 1748908800000,
      "tag": "0000_initial_gamification",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add services/gamification/drizzle/
git commit -m "feat(gamification): add initial Drizzle migration"
```

---

### Task 21: `Dockerfile` + `scripts/migrate.js` + `docker-entrypoint.sh`

**Files:**
- Create: `services/gamification/Dockerfile`
- Create: `services/gamification/scripts/migrate.js`
- Create: `services/gamification/docker-entrypoint.sh`

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
node /app/services/gamification/scripts/migrate.js

echo "Starting gamification service..."
exec node /app/services/gamification/dist/services/gamification/src/main
```

- [ ] **Step 3: Criar Dockerfile**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/gamification/ ./services/gamification/

WORKDIR /app/services/gamification
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/gamification

COPY --from=builder /app/services/gamification/dist ./dist
COPY --from=builder /app/services/gamification/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/gamification/drizzle ./drizzle
COPY --from=builder /app/services/gamification/scripts ./scripts
COPY --from=builder /app/services/gamification/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4006

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 4: Commit**

```bash
git add services/gamification/Dockerfile services/gamification/scripts/migrate.js services/gamification/docker-entrypoint.sh
git commit -m "feat(gamification): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 22: `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Adicionar postgres-gamification e gamification ao docker-compose.yml**

Adicionar logo após o serviço `postgres-social` (e antes de `volumes:`):

```yaml
  postgres-gamification:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_gamification
    ports:
      - "5437:5432"
    volumes:
      - postgres_gamification_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  gamification:
    build:
      context: .
      dockerfile: services/gamification/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4006
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-gamification:5432/bolanarededb_gamification
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4006:4006"
    depends_on:
      postgres-gamification:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

Adicionar o volume no bloco `volumes:`:

```yaml
  postgres_gamification_data:
```

- [ ] **Step 2: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(gamification): add postgres-gamification and gamification service to docker-compose"
```

---

### Task 23: `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar _status.md**

Localizar a linha do gamification service e marcá-la como DONE:

```
| gamification    | ⏳ TODO  | 0/?   | —                            |
```

Substituir por:

```
| gamification    | ✅ DONE  | 23/23 | feature/gamification-service |
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs(gamification): update _status.md — gamification service DONE (23/23)"
```

---

## Checklist de conclusão

- [ ] `npm test` em `services/gamification/` — todos os testes passando
- [ ] `npm run build` em `services/gamification/` — sem erros de compilação
- [ ] `npm run build` em `services/open-game/` — sem erros (após modificações na Task 15)
- [ ] Todos os 23 tasks commitados na branch `feature/gamification-service`
