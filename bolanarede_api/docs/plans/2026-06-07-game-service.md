# Game Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-07-matchmaking-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `game-service` (porta 4008) — serviço que gerencia partidas competitivas criadas pelo matchmaking. Consome `matchmaking.match-accepted` para criar o registro da partida, permite que um participante submeta o placar final, e publica `game.match-completed` (consumido por gamification e ranking) e `game.result-disputed`.

**Architecture:** NestJS 11 com módulo único `game`, PostgreSQL dedicado. Sem Redis — sem estado em memória. A partida é criada automaticamente ao receber `MATCH_ACCEPTED`. Um dos dois jogadores submete o placar final; o outro pode disputar. A coluna `match_id` tem UNIQUE constraint para idempotência no consumer.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger, uuid

---

## Setup de Branch

**Branch:** `feature/game-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/game-service
```

---

## File Map

```
services/game/
├── .env.example                                                      ← Task 1
├── drizzle.config.ts                                                 ← Task 2
├── nest-cli.json                                                      ← Task 3
├── package.json                                                       ← Task 4
├── tsconfig.json                                                      ← Task 5
├── tsconfig.build.json                                                ← Task 5
└── src/
    ├── main.ts                                                        ← Task 16
    ├── app.module.ts                                                  ← Task 16
    └── modules/
        └── game/
            ├── game.module.ts                                         ← Task 15
            ├── domain/
            │   ├── models/
            │   │   └── competitive-game.entity.ts                     ← Task 6
            │   └── repositories/
            │       └── game-repository.interface.ts                   ← Task 8
            ├── application/
            │   ├── dto/
            │   │   ├── submit-result.dto.ts                           ← Task 10
            │   │   └── game.dto.ts                                    ← Task 10
            │   └── services/
            │       ├── game.service.spec.ts                           ← Task 12
            │       ├── game.service.ts                                ← Task 12
            │       ├── game-messaging.service.ts                      ← Task 11
            │       └── matchmaking-events.consumer.ts                 ← Task 13
            └── infra/
                ├── controllers/
                │   └── games.controller.ts                            ← Task 14
                └── database/
                    ├── schemas/
                    │   └── competitive-game.schema.ts                 ← Task 7
                    └── repositories/
                        └── drizzle-game.repository.ts                 ← Task 9

drizzle/                                                               ← Task 17
scripts/migrate.js                                                     ← Task 18
Dockerfile                                                             ← Task 18
docker-entrypoint.sh                                                   ← Task 18
docker-compose.yml (raiz)                                              ← Task 19
docs/plans/_status.md                                                  ← Task 20
```

---

## Regras de Negócio

### Fluxo da Partida

```
matchmaking-service → publish MATCH_ACCEPTED { matchId, userAId, userBId, sport }
                          ↓
game-service consumes → cria CompetitiveGame (status: scheduled)
                          ↓
Qualquer participante → POST /games/:id/result { playerAGoals, playerBGoals, playerAAssists, playerBAssists }
                          → Game status: completed
                          → winnerId = userAId se A > B, userBId se B > A, null se empate
                          → publish game.match-completed (fire-and-forget)
                          ↓
O OUTRO participante → POST /games/:id/dispute
                          → Game status: disputed
                          → publish game.result-disputed (fire-and-forget)
```

### Status do jogo

| Status | Descrição |
|--------|-----------|
| `scheduled` | Criado ao receber MATCH_ACCEPTED. Aguarda placar. |
| `completed` | Placar submetido. MATCH_COMPLETED publicado. |
| `disputed` | Resultado contestado. RESULT_DISPUTED publicado. |

### Regras de validação

- Apenas participantes (userAId ou userBId) podem submeter resultado ou disputar
- Resultado só pode ser submetido se `status === 'scheduled'`
- Disputa só pode ser feita se `status === 'completed'`
- Quem submeteu o resultado NÃO pode disputar (seria o outro jogador)
- Consumer idempotente: `match_id` tem UNIQUE constraint — segunda entrega do evento é ignorada (onConflictDoNothing)

### Payload de game.match-completed

```typescript
{
  gameId: string,       // game.externalId
  matchId: string,      // original matchId do matchmaking
  sport: string,
  players: [
    { playerUserId: string, goals: number, assists: number, won: boolean },
    { playerUserId: string, goals: number, assists: number, won: boolean },
  ],
}
```

### Payload de game.result-disputed

```typescript
{
  gameId: string,
  matchId: string,
  sport: string,
  disputedByUserId: string,
}
```

---

## Contexto de Desenvolvimento

Branch: `feature/game-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/game/` salvo indicação contrária.

### Regras inegociáveis (reforço)
- Drizzle ORM (NUNCA TypeORM)
- Biome (NUNCA ESLint/Prettier)
- BIGSERIAL PK interno + UUID `external_id` exposto pela API
- Timestamps: sempre `timestamptz` (`withTimezone: true`)
- Fire-and-forget: chamadas de `messaging.publish*` APÓS commit no DB, dentro de `try/catch`
- Caminhos relativos em `infra/database/repositories/` para `domain/`: precisam de `../../../` (3 níveis)
- Idempotência em consumers RabbitMQ (onConflictDoNothing + try/catch sem rethrow)
- Sem Redis neste serviço (apenas PostgreSQL + RabbitMQ)

---

### Task 1: `.env.example`

**Files:**
- Create: `services/game/.env.example`

- [ ] **Step 1: Criar `.env.example`**

```
PORT=4008
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_game
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/game/.env.example
git commit -m "chore(game): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/game/drizzle.config.ts`

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
git add services/game/drizzle.config.ts
git commit -m "chore(game): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/game/nest-cli.json`

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
git add services/game/nest-cli.json
git commit -m "chore(game): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/game/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/game",
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
cd services/game && npm install --legacy-peer-deps
```

- [ ] **Step 3: Commit**

```bash
git add services/game/package.json services/game/package-lock.json
git commit -m "chore(game): add package.json"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/game/tsconfig.json`
- Create: `services/game/tsconfig.build.json`

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
git add services/game/tsconfig.json services/game/tsconfig.build.json
git commit -m "chore(game): add tsconfig files"
```

---

### Task 6: Domain entity

**Files:**
- Create: `services/game/src/modules/game/domain/models/competitive-game.entity.ts`

- [ ] **Step 1: Criar competitive-game.entity.ts**

```typescript
export type GameStatus = 'scheduled' | 'completed' | 'disputed';

export class CompetitiveGame {
  id!: number;
  externalId!: string;
  matchId!: string;
  userAId!: string;
  userBId!: string;
  sport!: string;
  status!: GameStatus;
  playerAGoals!: number;
  playerBGoals!: number;
  playerAAssists!: number;
  playerBAssists!: number;
  /** null = empate */
  winnerId!: string | null;
  /** userId de quem submeteu o placar */
  submittedByUserId!: string | null;
  createdAt!: Date;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/domain/models/competitive-game.entity.ts
git commit -m "feat(game): add CompetitiveGame domain entity"
```

---

### Task 7: Drizzle schema

**Files:**
- Create: `services/game/src/modules/game/infra/database/schemas/competitive-game.schema.ts`

- [ ] **Step 1: Criar competitive-game.schema.ts**

```typescript
import { pgTable, bigserial, text, integer, timestamp } from 'drizzle-orm/pg-core';

export const competitiveGames = pgTable('competitive_games', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  /** UNIQUE garante idempotência: MATCH_ACCEPTED re-entregue não cria duplicata */
  matchId: text('match_id').notNull().unique(),
  userAId: text('user_a_id').notNull(),
  userBId: text('user_b_id').notNull(),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('scheduled'),
  playerAGoals: integer('player_a_goals').notNull().default(0),
  playerBGoals: integer('player_b_goals').notNull().default(0),
  playerAAssists: integer('player_a_assists').notNull().default(0),
  playerBAssists: integer('player_b_assists').notNull().default(0),
  winnerId: text('winner_id'),
  submittedByUserId: text('submitted_by_user_id'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type CompetitiveGameRow = typeof competitiveGames.$inferSelect;
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/infra/database/schemas/competitive-game.schema.ts
git commit -m "feat(game): add Drizzle schema for competitive_games"
```

---

### Task 8: Repository interface

**Files:**
- Create: `services/game/src/modules/game/domain/repositories/game-repository.interface.ts`

- [ ] **Step 1: Criar game-repository.interface.ts**

```typescript
import type { CompetitiveGame, GameStatus } from '../models/competitive-game.entity';

export const GAME_REPOSITORY = 'GAME_REPOSITORY';

export interface CreateGameData {
  externalId: string;
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

export interface SubmitResultData {
  playerAGoals: number;
  playerBGoals: number;
  playerAAssists: number;
  playerBAssists: number;
  winnerId: string | null;
  submittedByUserId: string;
}

export interface GameRepositoryInterface {
  /** Idempotente: ignora duplicata via onConflictDoNothing. Retorna null se já existia. */
  create(data: CreateGameData): Promise<CompetitiveGame | null>;
  findByExternalId(externalId: string): Promise<CompetitiveGame | null>;
  /** Atualiza status para 'completed' e grava o placar. */
  submitResult(externalId: string, data: SubmitResultData): Promise<CompetitiveGame>;
  /** Atualiza status para 'disputed'. */
  dispute(externalId: string): Promise<CompetitiveGame>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/domain/repositories/game-repository.interface.ts
git commit -m "feat(game): add GameRepositoryInterface"
```

---

### Task 9: `DrizzleGameRepository`

**Files:**
- Create: `services/game/src/modules/game/infra/database/repositories/drizzle-game.repository.ts`

- [ ] **Step 1: Criar drizzle-game.repository.ts**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  GameRepositoryInterface,
  CreateGameData,
  SubmitResultData,
} from '../../../domain/repositories/game-repository.interface';
import type { CompetitiveGame } from '../../../domain/models/competitive-game.entity';
import { competitiveGames, type CompetitiveGameRow } from '../schemas/competitive-game.schema';

@Injectable()
export class DrizzleGameRepository implements GameRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateGameData): Promise<CompetitiveGame | null> {
    const result = await this.drizzle.db
      .insert(competitiveGames)
      .values({
        externalId: data.externalId,
        matchId: data.matchId,
        userAId: data.userAId,
        userBId: data.userBId,
        sport: data.sport,
        status: 'scheduled',
        playerAGoals: 0,
        playerBGoals: 0,
        playerAAssists: 0,
        playerBAssists: 0,
        winnerId: null,
        submittedByUserId: null,
      })
      .onConflictDoNothing()
      .returning();
    return result[0] ? this.toEntity(result[0]) : null;
  }

  async findByExternalId(externalId: string): Promise<CompetitiveGame | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(competitiveGames)
      .where(eq(competitiveGames.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async submitResult(externalId: string, data: SubmitResultData): Promise<CompetitiveGame> {
    const [row] = await this.drizzle.db
      .update(competitiveGames)
      .set({
        status: 'completed',
        playerAGoals: data.playerAGoals,
        playerBGoals: data.playerBGoals,
        playerAAssists: data.playerAAssists,
        playerBAssists: data.playerBAssists,
        winnerId: data.winnerId,
        submittedByUserId: data.submittedByUserId,
        updatedAt: new Date(),
      })
      .where(eq(competitiveGames.externalId, externalId))
      .returning();
    if (!row) throw new NotFoundException(`Game ${externalId} not found`);
    return this.toEntity(row);
  }

  async dispute(externalId: string): Promise<CompetitiveGame> {
    const [row] = await this.drizzle.db
      .update(competitiveGames)
      .set({ status: 'disputed', updatedAt: new Date() })
      .where(eq(competitiveGames.externalId, externalId))
      .returning();
    if (!row) throw new NotFoundException(`Game ${externalId} not found`);
    return this.toEntity(row);
  }

  private toEntity(row: CompetitiveGameRow): CompetitiveGame {
    return {
      id: row.id,
      externalId: row.externalId,
      matchId: row.matchId,
      userAId: row.userAId,
      userBId: row.userBId,
      sport: row.sport,
      status: row.status as CompetitiveGame['status'],
      playerAGoals: row.playerAGoals,
      playerBGoals: row.playerBGoals,
      playerAAssists: row.playerAAssists,
      playerBAssists: row.playerBAssists,
      winnerId: row.winnerId,
      submittedByUserId: row.submittedByUserId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/infra/database/repositories/drizzle-game.repository.ts
git commit -m "feat(game): add DrizzleGameRepository"
```

---

### Task 10: DTOs

**Files:**
- Create: `services/game/src/modules/game/application/dto/submit-result.dto.ts`
- Create: `services/game/src/modules/game/application/dto/game.dto.ts`

- [ ] **Step 1: Criar submit-result.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class SubmitResultDto {
  @ApiProperty({ description: 'Goals scored by player A', minimum: 0 })
  @IsInt()
  @Min(0)
  playerAGoals!: number;

  @ApiProperty({ description: 'Goals scored by player B', minimum: 0 })
  @IsInt()
  @Min(0)
  playerBGoals!: number;

  @ApiProperty({ description: 'Assists by player A', minimum: 0 })
  @IsInt()
  @Min(0)
  playerAAssists!: number;

  @ApiProperty({ description: 'Assists by player B', minimum: 0 })
  @IsInt()
  @Min(0)
  playerBAssists!: number;
}
```

- [ ] **Step 2: Criar game.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

export class GameDto {
  @ApiProperty() id!: string;
  @ApiProperty() matchId!: string;
  @ApiProperty() userAId!: string;
  @ApiProperty() userBId!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() playerAGoals!: number;
  @ApiProperty() playerBGoals!: number;
  @ApiProperty() playerAAssists!: number;
  @ApiProperty() playerBAssists!: number;
  @ApiProperty({ nullable: true }) winnerId!: string | null;
  @ApiProperty({ nullable: true }) submittedByUserId!: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;

  static from(g: CompetitiveGame): GameDto {
    const dto = new GameDto();
    dto.id = g.externalId;
    dto.matchId = g.matchId;
    dto.userAId = g.userAId;
    dto.userBId = g.userBId;
    dto.sport = g.sport;
    dto.status = g.status;
    dto.playerAGoals = g.playerAGoals;
    dto.playerBGoals = g.playerBGoals;
    dto.playerAAssists = g.playerAAssists;
    dto.playerBAssists = g.playerBAssists;
    dto.winnerId = g.winnerId;
    dto.submittedByUserId = g.submittedByUserId;
    dto.createdAt = g.createdAt;
    dto.updatedAt = g.updatedAt;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/game/src/modules/game/application/dto/
git commit -m "feat(game): add DTOs"
```

---

### Task 11: `GameMessagingService`

**Files:**
- Create: `services/game/src/modules/game/application/services/game-messaging.service.ts`

- [ ] **Step 1: Criar game-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

@Injectable()
export class GameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishMatchCompleted(game: CompetitiveGame): Promise<void> {
    const players = [
      {
        playerUserId: game.userAId,
        goals: game.playerAGoals,
        assists: game.playerAAssists,
        won: game.winnerId === game.userAId,
      },
      {
        playerUserId: game.userBId,
        goals: game.playerBGoals,
        assists: game.playerBAssists,
        won: game.winnerId === game.userBId,
      },
    ];

    await this.messaging.publish(GameEvents.MATCH_COMPLETED, {
      gameId: game.externalId,
      matchId: game.matchId,
      sport: game.sport,
      players,
    });
  }

  async publishResultDisputed(game: CompetitiveGame, disputedByUserId: string): Promise<void> {
    await this.messaging.publish(GameEvents.RESULT_DISPUTED, {
      gameId: game.externalId,
      matchId: game.matchId,
      sport: game.sport,
      disputedByUserId,
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/application/services/game-messaging.service.ts
git commit -m "feat(game): add GameMessagingService"
```

---

### Task 12: `GameService` (TDD — 7 testes)

**Files:**
- Create: `services/game/src/modules/game/application/services/game.service.spec.ts`
- Create: `services/game/src/modules/game/application/services/game.service.ts`

- [ ] **Step 1: Escrever spec primeiro**

```typescript
// game.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { GameService } from './game.service';
import { GAME_REPOSITORY } from '../../domain/repositories/game-repository.interface';
import { GameMessagingService } from './game-messaging.service';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

const makeGame = (overrides: Partial<CompetitiveGame> = {}): CompetitiveGame => ({
  id: 1,
  externalId: 'game-1',
  matchId: 'match-1',
  userAId: 'user-a',
  userBId: 'user-b',
  sport: 'futsal',
  status: 'scheduled',
  playerAGoals: 0,
  playerBGoals: 0,
  playerAAssists: 0,
  playerBAssists: 0,
  winnerId: null,
  submittedByUserId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  ...overrides,
});

describe('GameService', () => {
  let service: GameService;
  let gameRepo: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    gameRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      submitResult: jest.fn(),
      dispute: jest.fn(),
    };
    messaging = {
      publishMatchCompleted: jest.fn(),
      publishResultDisputed: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameService,
        { provide: GAME_REPOSITORY, useValue: gameRepo },
        { provide: GameMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<GameService>(GameService);
  });

  describe('submitResult', () => {
    const dto = { playerAGoals: 3, playerBGoals: 1, playerAAssists: 1, playerBAssists: 0 };

    it('completes game with winner A when A has more goals', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b' }));
      const completed = makeGame({ status: 'completed', playerAGoals: 3, playerBGoals: 1, winnerId: 'user-a', submittedByUserId: 'user-a' });
      gameRepo.submitResult.mockResolvedValue(completed);
      messaging.publishMatchCompleted.mockResolvedValue(undefined);

      const result = await service.submitResult('user-a', 'game-1', dto);

      expect(gameRepo.submitResult).toHaveBeenCalledWith('game-1', expect.objectContaining({ winnerId: 'user-a' }));
      expect(messaging.publishMatchCompleted).toHaveBeenCalled();
      expect(result.status).toBe('completed');
      expect(result.winnerId).toBe('user-a');
    });

    it('completes game with null winner on draw', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b' }));
      const drawn = makeGame({ status: 'completed', playerAGoals: 2, playerBGoals: 2, winnerId: null, submittedByUserId: 'user-a' });
      gameRepo.submitResult.mockResolvedValue(drawn);
      messaging.publishMatchCompleted.mockResolvedValue(undefined);

      await service.submitResult('user-a', 'game-1', { playerAGoals: 2, playerBGoals: 2, playerAAssists: 0, playerBAssists: 0 });

      expect(gameRepo.submitResult).toHaveBeenCalledWith('game-1', expect.objectContaining({ winnerId: null }));
    });

    it('throws ForbiddenException if user is not a participant', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ userAId: 'user-a', userBId: 'user-b' }));

      await expect(service.submitResult('user-x', 'game-1', dto)).rejects.toThrow(ForbiddenException);
    });

    it('throws ConflictException if game is not scheduled', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'completed' }));

      await expect(service.submitResult('user-a', 'game-1', dto)).rejects.toThrow(ConflictException);
    });
  });

  describe('disputeResult', () => {
    it('transitions to disputed and publishes event', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'completed', userAId: 'user-a', userBId: 'user-b', submittedByUserId: 'user-a' }),
      );
      const disputed = makeGame({ status: 'disputed' });
      gameRepo.dispute.mockResolvedValue(disputed);
      messaging.publishResultDisputed.mockResolvedValue(undefined);

      const result = await service.disputeResult('user-b', 'game-1');

      expect(gameRepo.dispute).toHaveBeenCalledWith('game-1');
      expect(messaging.publishResultDisputed).toHaveBeenCalledWith(disputed, 'user-b');
      expect(result.status).toBe('disputed');
    });

    it('throws ForbiddenException if submitter tries to dispute own submission', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'completed', userAId: 'user-a', userBId: 'user-b', submittedByUserId: 'user-a' }),
      );

      await expect(service.disputeResult('user-a', 'game-1')).rejects.toThrow(ForbiddenException);
    });

    it('throws ConflictException if game is not completed', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b', submittedByUserId: null }),
      );

      await expect(service.disputeResult('user-b', 'game-1')).rejects.toThrow(ConflictException);
    });
  });
});
```

- [ ] **Step 2: Rodar testes para confirmar FAIL**

```bash
cd services/game && npm test -- --testPathPattern="game.service.spec"
```

Expected: FAIL com `Cannot find module './game.service'`.

- [ ] **Step 3: Implementar game.service.ts**

```typescript
import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  GAME_REPOSITORY,
  GameRepositoryInterface,
} from '../../domain/repositories/game-repository.interface';
import { GameMessagingService } from './game-messaging.service';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';
import type { SubmitResultDto } from '../dto/submit-result.dto';

@Injectable()
export class GameService {
  private readonly logger = new Logger(GameService.name);

  constructor(
    @Inject(GAME_REPOSITORY)
    private readonly gameRepo: GameRepositoryInterface,
    private readonly messaging: GameMessagingService,
  ) {}

  async submitResult(
    userId: string,
    gameExternalId: string,
    dto: SubmitResultDto,
  ): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');

    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }

    if (game.status !== 'scheduled') {
      throw new ConflictException(`Game is already ${game.status}`);
    }

    const winnerId =
      dto.playerAGoals > dto.playerBGoals
        ? game.userAId
        : dto.playerBGoals > dto.playerAGoals
          ? game.userBId
          : null;

    const updated = await this.gameRepo.submitResult(gameExternalId, {
      playerAGoals: dto.playerAGoals,
      playerBGoals: dto.playerBGoals,
      playerAAssists: dto.playerAAssists,
      playerBAssists: dto.playerBAssists,
      winnerId,
      submittedByUserId: userId,
    });

    try {
      await this.messaging.publishMatchCompleted(updated);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish match-completed for ${gameExternalId}: ${message}`);
    }

    return updated;
  }

  async disputeResult(userId: string, gameExternalId: string): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');

    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }

    if (game.status !== 'completed') {
      throw new ConflictException(`Cannot dispute a game with status ${game.status}`);
    }

    if (game.submittedByUserId === userId) {
      throw new ForbiddenException('Cannot dispute your own submission');
    }

    const updated = await this.gameRepo.dispute(gameExternalId);

    try {
      await this.messaging.publishResultDisputed(updated, userId);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish result-disputed for ${gameExternalId}: ${message}`);
    }

    return updated;
  }

  async getGame(userId: string, gameExternalId: string): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');
    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }
    return game;
  }
}
```

- [ ] **Step 4: Rodar testes para confirmar PASS**

```bash
cd services/game && npm test -- --testPathPattern="game.service.spec"
```

Expected: 7/7 tests passando.

- [ ] **Step 5: Commit**

```bash
git add services/game/src/modules/game/application/services/game.service.spec.ts
git add services/game/src/modules/game/application/services/game.service.ts
git commit -m "feat(game): add GameService with TDD (7/7 tests)"
```

---

### Task 13: `MatchmakingEventsConsumer`

**Files:**
- Create: `services/game/src/modules/game/application/services/matchmaking-events.consumer.ts`

- [ ] **Step 1: Criar matchmaking-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { Inject } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import {
  GAME_REPOSITORY,
  GameRepositoryInterface,
} from '../../domain/repositories/game-repository.interface';

interface MatchAcceptedPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

@Injectable()
export class MatchmakingEventsConsumer {
  private readonly logger = new Logger(MatchmakingEventsConsumer.name);

  constructor(
    @Inject(GAME_REPOSITORY)
    private readonly gameRepo: GameRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_ACCEPTED,
    queue: 'game-service.matchmaking.match-accepted',
    queueOptions: { durable: true },
  })
  async handleMatchAccepted(payload: MatchAcceptedPayload): Promise<void> {
    try {
      const game = await this.gameRepo.create({
        externalId: uuidv4(),
        matchId: payload.matchId,
        userAId: payload.userAId,
        userBId: payload.userBId,
        sport: payload.sport,
      });

      if (!game) {
        // onConflictDoNothing: partida para este matchId já existe (re-entrega idempotente)
        this.logger.debug(`Game for match ${payload.matchId} already exists, skipping`);
        return;
      }

      this.logger.log(`Game ${game.externalId} created for match ${payload.matchId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to create game for match ${payload.matchId}: ${message}`);
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/application/services/matchmaking-events.consumer.ts
git commit -m "feat(game): add MatchmakingEventsConsumer"
```

---

### Task 14: `GamesController`

**Files:**
- Create: `services/game/src/modules/game/infra/controllers/games.controller.ts`

- [ ] **Step 1: Criar games.controller.ts**

```typescript
import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { GameService } from '../../application/services/game.service';
import { SubmitResultDto } from '../../application/dto/submit-result.dto';
import { GameDto } from '../../application/dto/game.dto';

@ApiTags('Games')
@UseGuards(JwtAuthGuard)
@Controller('games')
export class GamesController {
  constructor(private readonly gameService: GameService) {}

  @Get(':id')
  @ApiOperation({ summary: 'Get competitive game info' })
  async getGame(@Request() req: any, @Param('id') id: string): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.getGame(userId, id);
    return GameDto.from(game);
  }

  @Post(':id/result')
  @ApiOperation({ summary: 'Submit final result for a competitive game' })
  async submitResult(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: SubmitResultDto,
  ): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.submitResult(userId, id, dto);
    return GameDto.from(game);
  }

  @Post(':id/dispute')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Dispute the result of a completed game' })
  async disputeResult(@Request() req: any, @Param('id') id: string): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.disputeResult(userId, id);
    return GameDto.from(game);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/infra/controllers/games.controller.ts
git commit -m "feat(game): add GamesController"
```

---

### Task 15: `GameModule`

**Files:**
- Create: `services/game/src/modules/game/game.module.ts`

- [ ] **Step 1: Criar game.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { GAME_REPOSITORY } from './domain/repositories/game-repository.interface';
import { DrizzleGameRepository } from './infra/database/repositories/drizzle-game.repository';
import { GameMessagingService } from './application/services/game-messaging.service';
import { GameService } from './application/services/game.service';
import { MatchmakingEventsConsumer } from './application/services/matchmaking-events.consumer';
import { GamesController } from './infra/controllers/games.controller';

@Module({
  imports: [SharedModule],
  controllers: [GamesController],
  providers: [
    { provide: GAME_REPOSITORY, useClass: DrizzleGameRepository },
    GameMessagingService,
    GameService,
    MatchmakingEventsConsumer,
  ],
})
export class GameModule {}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/src/modules/game/game.module.ts
git commit -m "feat(game): add GameModule"
```

---

### Task 16: `AppModule` + `main.ts` + build

**Files:**
- Create: `services/game/src/app.module.ts`
- Create: `services/game/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GameModule } from './modules/game/game.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    GameModule,
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
cd services/game && npm run build
```

Expected: 0 erros. Se houver erros de import, verificar caminhos relativos (3 níveis de `../` de `infra/database/repositories/` para `domain/`).

- [ ] **Step 4: Commit**

```bash
git add services/game/src/app.module.ts services/game/src/main.ts
git commit -m "feat(game): add AppModule and main.ts"
```

---

### Task 17: Migration SQL

**Files:**
- Create: `services/game/drizzle/0000_initial_game.sql`
- Create: `services/game/drizzle/meta/_journal.json`

- [ ] **Step 1: Criar SQL de migration**

`drizzle/0000_initial_game.sql`:
```sql
CREATE TABLE "competitive_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "match_id" text NOT NULL,
  "user_a_id" text NOT NULL,
  "user_b_id" text NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'scheduled' NOT NULL,
  "player_a_goals" integer DEFAULT 0 NOT NULL,
  "player_b_goals" integer DEFAULT 0 NOT NULL,
  "player_a_assists" integer DEFAULT 0 NOT NULL,
  "player_b_assists" integer DEFAULT 0 NOT NULL,
  "winner_id" text,
  "submitted_by_user_id" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "competitive_games_external_id_unique" UNIQUE("external_id"),
  CONSTRAINT "competitive_games_match_id_unique" UNIQUE("match_id")
);

CREATE INDEX "idx_competitive_games_user_a" ON "competitive_games" ("user_a_id");
CREATE INDEX "idx_competitive_games_user_b" ON "competitive_games" ("user_b_id");
CREATE INDEX "idx_competitive_games_status" ON "competitive_games" ("status");
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
      "when": 1749340800000,
      "tag": "0000_initial_game",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add services/game/drizzle/
git commit -m "feat(game): add initial Drizzle migration"
```

---

### Task 18: `Dockerfile` + `scripts/migrate.js` + `docker-entrypoint.sh`

**Files:**
- Create: `services/game/scripts/migrate.js`
- Create: `services/game/docker-entrypoint.sh`
- Create: `services/game/Dockerfile`

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
node /app/services/game/scripts/migrate.js

echo "Starting game service..."
exec node /app/services/game/dist/services/game/src/main
```

- [ ] **Step 3: Criar Dockerfile**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/game/ ./services/game/

WORKDIR /app/services/game
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/game

COPY --from=builder /app/services/game/dist ./dist
COPY --from=builder /app/services/game/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/game/drizzle ./drizzle
COPY --from=builder /app/services/game/scripts ./scripts
COPY --from=builder /app/services/game/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4008

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 4: Commit**

```bash
git add services/game/Dockerfile services/game/scripts/migrate.js services/game/docker-entrypoint.sh
git commit -m "feat(game): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 19: `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Adicionar postgres-game e game ao docker-compose.yml**

Ler o arquivo `docker-compose.yml` atual. Adicionar após o bloco `matchmaking:` e antes do bloco `volumes:`:

```yaml
  postgres-game:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_game
    ports:
      - "5439:5432"
    volumes:
      - postgres_game_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  game:
    build:
      context: .
      dockerfile: services/game/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4008
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-game:5432/bolanarededb_game
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4008:4008"
    depends_on:
      postgres-game:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

Adicionar no bloco `volumes:`:

```yaml
  postgres_game_data:
```

- [ ] **Step 2: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(game): add postgres-game and game service to docker-compose"
```

---

### Task 20: `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar _status.md**

Localizar:
```
| game         | ⏳ TODO  | 0/?        | —                            |
```

Substituir por:
```
| game         | ✅ DONE     | 20/20      | —                            |
```

Atualizar timestamp: `Última atualização: 2026-06-07 (game service DONE)`

Adicionar ao bloco de planos:
```
- `docs/plans/2026-06-07-game-service.md` — 20 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs(game): update _status.md — game service DONE (20/20)"
```
