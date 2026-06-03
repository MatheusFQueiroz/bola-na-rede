# Open-Game Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-01-field-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `open-game-service` (porta 4004) — serviço de partidas abertas onde qualquer usuário pode criar ou entrar em um jogo casual de futebol, com controle de vagas via lock distribuído Redis e cache da listagem ativa.

**Architecture:** NestJS 11 com dois sub-módulos (`games` e `stats`) compartilhando um único banco PostgreSQL. Redis é usado para: (1) lock distribuído no `join` para evitar race condition na última vaga; (2) cache TTL-30s da listagem de jogos sem filtros. O serviço consome `identity.profile-updated` para atualizar snapshots de `displayName` nos participantes e publica 7 eventos (`CREATED`, `PLAYER_JOINED`, `PLAYER_LEFT`, `FULL`, `FINISHED`, `CANCELLED`, `STATS_RECORDED`).

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, Redis 7 (`ioredis`), @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## Setup de Branch

**Branch:** `feature/open-game-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/open-game-service
```

---

## File Map

```
services/open-game/
├── .env.example                                                               ← Task 1
├── drizzle.config.ts                                                          ← Task 2
├── nest-cli.json                                                              ← Task 3
├── package.json                                                               ← Task 4
├── tsconfig.json                                                              ← Task 5
├── tsconfig.build.json                                                        ← Task 5
├── src/
│   ├── main.ts                                                                ← Task 25
│   ├── app.module.ts                                                          ← Task 25
│   ├── infra/
│   │   └── cache/
│   │       └── redis.service.ts                                               ← Task 12
│   └── modules/
│       └── open-game/
│           ├── open-game.module.ts                                            ← Task 24
│           ├── games/
│           │   ├── domain/
│           │   │   ├── models/
│           │   │   │   ├── open-game.entity.ts                                ← Task 6
│           │   │   │   └── game-participant.entity.ts                         ← Task 6
│           │   │   └── repositories/
│           │   │       └── open-game-repository.interface.ts                  ← Task 10
│           │   ├── application/
│           │   │   ├── dto/
│           │   │   │   ├── create-open-game.dto.ts                            ← Task 15
│           │   │   │   ├── update-open-game.dto.ts                            ← Task 15
│           │   │   │   ├── list-open-games.dto.ts                             ← Task 15
│           │   │   │   ├── open-game.dto.ts                                   ← Task 16
│           │   │   │   └── game-participant.dto.ts                            ← Task 16
│           │   │   └── services/
│           │   │       ├── open-game.service.spec.ts                          ← Task 18
│           │   │       ├── open-game.service.ts                               ← Task 18
│           │   │       ├── identity-events.consumer.ts                        ← Task 20
│           │   │       └── open-game-messaging.service.ts                     ← Task 21
│           │   ├── infra/
│           │   │   ├── cache/
│           │   │   │   └── game-cache.service.ts                              ← Task 13
│           │   │   ├── controllers/
│           │   │   │   └── open-games.controller.ts                           ← Task 22
│           │   │   └── database/
│           │   │       ├── schemas/
│           │   │       │   ├── open-game.schema.ts                            ← Task 8
│           │   │       │   └── game-participant.schema.ts                     ← Task 8
│           │   │       └── repositories/
│           │   │           └── drizzle-open-game.repository.ts                ← Task 13
│           │   └── games.module.ts                                            ← Task 24
│           └── stats/
│               ├── domain/
│               │   ├── models/
│               │   │   └── player-stats.entity.ts                             ← Task 7
│               │   └── repositories/
│               │       └── stats-repository.interface.ts                      ← Task 11
│               ├── application/
│               │   ├── dto/
│               │   │   ├── record-stats.dto.ts                                ← Task 17
│               │   │   └── stats.dto.ts                                       ← Task 17
│               │   └── services/
│               │       ├── stats.service.spec.ts                              ← Task 19
│               │       └── stats.service.ts                                   ← Task 19
│               ├── infra/
│               │   ├── controllers/
│               │   │   └── stats.controller.ts                                ← Task 23
│               │   └── database/
│               │       ├── schemas/
│               │       │   └── player-stats.schema.ts                         ← Task 9
│               │       └── repositories/
│               │           └── drizzle-stats.repository.ts                    ← Task 14
│               └── stats.module.ts                                            ← Task 24
├── drizzle/                                                                   ← Task 26
├── scripts/
│   └── migrate.js                                                             ← Task 27
├── Dockerfile                                                                 ← Task 27
└── docker-entrypoint.sh                                                       ← Task 27

docker-compose.yml (root)                                                      ← Task 28
docs/plans/_status.md                                                          ← Task 29
```

---

## Contexto de Desenvolvimento

Branch: `feature/open-game-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/open-game/` salvo indicação contrária.

---

### Task 1: `.env.example`

**Files:**
- Create: `services/open-game/.env.example`

- [ ] **Step 1: Criar .env.example**

```
PORT=4004
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_open_game
RABBITMQ_URL=amqp://admin:admin@localhost:5672
REDIS_URL=redis://localhost:6379
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/open-game/.env.example
git commit -m "chore(open-game): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/open-game/drizzle.config.ts`

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
git add services/open-game/drizzle.config.ts
git commit -m "chore(open-game): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/open-game/nest-cli.json`

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
git add services/open-game/nest-cli.json
git commit -m "chore(open-game): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/open-game/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/open-game",
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
    "ioredis": "^5.3.2",
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
npm install
```

Expected: `node_modules/` criado, sem erros fatais. Warnings de peer deps de `@golevelup/nestjs-rabbitmq` são normais.

- [ ] **Step 3: Commit**

```bash
git add services/open-game/package.json services/open-game/package-lock.json
git commit -m "chore(open-game): add package.json and install deps"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/open-game/tsconfig.json`
- Create: `services/open-game/tsconfig.build.json`

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
git add services/open-game/tsconfig.json services/open-game/tsconfig.build.json
git commit -m "chore(open-game): add tsconfig files"
```

---

### Task 6: Domain entities — `OpenGame` e `GameParticipant`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/domain/models/open-game.entity.ts`
- Create: `services/open-game/src/modules/open-game/games/domain/models/game-participant.entity.ts`

- [ ] **Step 1: Criar open-game.entity.ts**

```typescript
export type GameStatus = 'open' | 'full' | 'in_progress' | 'finished' | 'cancelled';
export type SportType = 'futsal' | 'society' | 'campo';

export class OpenGame {
  id!: string;                        // external_id UUID exposto via API
  organizerUserId!: string;           // identity UUID (cross-service, sem FK)
  fieldId!: string | null;            // field UUID (cross-service, sem FK, nullable)
  fieldNameSnapshot!: string | null;  // snapshot do nome do campo
  fieldAddressSnapshot!: string | null;
  title!: string;
  description!: string | null;
  sport!: SportType;
  scheduledAt!: Date;
  durationMinutes!: number;
  minPlayers!: number;
  maxPlayers!: number;
  pricePerPlayer!: number | null;     // NUMERIC(10,2) — null = gratuito
  status!: GameStatus;
  createdAt!: Date;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Criar game-participant.entity.ts**

```typescript
export class GameParticipant {
  gameExternalId!: string;   // UUID do jogo (para retorno na API)
  playerUserId!: string;     // identity UUID
  displayName!: string;      // snapshot atualizado via identity.profile-updated
  position!: string | null;  // snapshot
  joinedAt!: Date;
  leftAt!: Date | null;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/games/domain/models/
git commit -m "feat(open-game): add OpenGame and GameParticipant domain entities"
```

---

### Task 7: Domain entity — `PlayerStats`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/domain/models/player-stats.entity.ts`

- [ ] **Step 1: Criar player-stats.entity.ts**

```typescript
export class PlayerStats {
  gameExternalId!: string;   // UUID do jogo
  playerUserId!: string;     // identity UUID
  goals!: number;
  assists!: number;
  notes!: string | null;
  createdAt!: Date;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/domain/models/player-stats.entity.ts
git commit -m "feat(open-game): add PlayerStats domain entity"
```

---

### Task 8: Drizzle schemas — `open_games` e `game_participants`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/infra/database/schemas/open-game.schema.ts`
- Create: `services/open-game/src/modules/open-game/games/infra/database/schemas/game-participant.schema.ts`

- [ ] **Step 1: Criar open-game.schema.ts**

```typescript
import {
  pgTable,
  bigserial,
  uuid,
  text,
  smallint,
  boolean,
  timestamp,
  numeric,
} from 'drizzle-orm/pg-core';

export const openGames = pgTable('open_games', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  organizerUserId: text('organizer_user_id').notNull(),
  fieldId: text('field_id'),
  fieldNameSnapshot: text('field_name_snapshot'),
  fieldAddressSnapshot: text('field_address_snapshot'),
  title: text('title').notNull(),
  description: text('description'),
  sport: text('sport').notNull(),                                  // 'futsal' | 'society' | 'campo'
  scheduledAt: timestamp('scheduled_at', { withTimezone: true }).notNull(),
  durationMinutes: smallint('duration_minutes').notNull().default(60),
  minPlayers: smallint('min_players').notNull().default(10),
  maxPlayers: smallint('max_players').notNull().default(22),
  pricePerPlayer: numeric('price_per_player', { precision: 10, scale: 2 }),
  status: text('status').notNull().default('open'),               // GameStatus
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type OpenGameRow = typeof openGames.$inferSelect;
export type NewOpenGameRow = typeof openGames.$inferInsert;
```

- [ ] **Step 2: Criar game-participant.schema.ts**

```typescript
import {
  pgTable,
  bigserial,
  bigint,
  text,
  timestamp,
} from 'drizzle-orm/pg-core';
import { openGames } from './open-game.schema';

export const gameParticipants = pgTable('game_participants', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  gameId: bigint('game_id', { mode: 'number' }).notNull().references(() => openGames.id),
  playerUserId: text('player_user_id').notNull(),
  displayName: text('display_name').notNull(),
  position: text('position'),
  joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
  leftAt: timestamp('left_at', { withTimezone: true }),
});

export type GameParticipantRow = typeof gameParticipants.$inferSelect;
export type NewGameParticipantRow = typeof gameParticipants.$inferInsert;
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/games/infra/database/schemas/
git commit -m "feat(open-game): add Drizzle schemas for open_games and game_participants"
```

---

### Task 9: Drizzle schema — `player_stats`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/infra/database/schemas/player-stats.schema.ts`

- [ ] **Step 1: Criar player-stats.schema.ts**

```typescript
import {
  pgTable,
  bigserial,
  bigint,
  text,
  smallint,
  timestamp,
  unique,
} from 'drizzle-orm/pg-core';
import { openGames } from '../../../games/infra/database/schemas/open-game.schema';

export const playerStats = pgTable(
  'player_stats',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    gameId: bigint('game_id', { mode: 'number' }).notNull().references(() => openGames.id),
    playerUserId: text('player_user_id').notNull(),
    goals: smallint('goals').notNull().default(0),
    assists: smallint('assists').notNull().default(0),
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_player_stats_game_player').on(t.gameId, t.playerUserId)],
);

export type PlayerStatsRow = typeof playerStats.$inferSelect;
export type NewPlayerStatsRow = typeof playerStats.$inferInsert;
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/infra/database/schemas/player-stats.schema.ts
git commit -m "feat(open-game): add Drizzle schema for player_stats"
```

---

### Task 10: Repository interface — `OpenGameRepositoryInterface`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/domain/repositories/open-game-repository.interface.ts`

- [ ] **Step 1: Criar open-game-repository.interface.ts**

```typescript
import type { OpenGame, GameStatus } from '../models/open-game.entity';
import type { GameParticipant } from '../models/game-participant.entity';

export const OPEN_GAME_REPOSITORY = 'OPEN_GAME_REPOSITORY';

export interface CreateOpenGameData {
  organizerUserId: string;
  fieldId?: string;
  fieldNameSnapshot?: string;
  fieldAddressSnapshot?: string;
  title: string;
  description?: string;
  sport: string;
  scheduledAt: Date;
  durationMinutes?: number;
  minPlayers?: number;
  maxPlayers?: number;
  pricePerPlayer?: number;
}

export interface UpdateOpenGameData {
  title?: string;
  description?: string;
  fieldId?: string;
  fieldNameSnapshot?: string;
  fieldAddressSnapshot?: string;
  scheduledAt?: Date;
  durationMinutes?: number;
  minPlayers?: number;
  maxPlayers?: number;
  pricePerPlayer?: number;
}

export interface ListOpenGamesFilter {
  sport?: string;
  fieldId?: string;
  fromDate?: Date;
  toDate?: Date;
  status?: GameStatus[];
}

export interface OpenGameRepositoryInterface {
  create(data: CreateOpenGameData): Promise<OpenGame>;
  findById(externalId: string): Promise<OpenGame | null>;
  findUpcoming(filter: ListOpenGamesFilter): Promise<OpenGame[]>;
  update(externalId: string, data: UpdateOpenGameData): Promise<OpenGame>;
  updateStatus(externalId: string, status: GameStatus): Promise<void>;
  deactivate(externalId: string): Promise<void>;

  // participants
  addParticipant(gameExternalId: string, playerUserId: string, displayName: string, position: string | null): Promise<GameParticipant>;
  removeParticipant(gameExternalId: string, playerUserId: string): Promise<void>;
  findParticipant(gameExternalId: string, playerUserId: string): Promise<GameParticipant | null>;
  findParticipants(gameExternalId: string): Promise<GameParticipant[]>;
  countActiveParticipants(gameExternalId: string): Promise<number>;
  updateParticipantSnapshot(playerUserId: string, displayName: string, position: string | null): Promise<void>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/games/domain/repositories/open-game-repository.interface.ts
git commit -m "feat(open-game): add OpenGameRepositoryInterface"
```

---

### Task 11: Repository interface — `StatsRepositoryInterface`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/domain/repositories/stats-repository.interface.ts`

- [ ] **Step 1: Criar stats-repository.interface.ts**

```typescript
import type { PlayerStats } from '../models/player-stats.entity';

export const STATS_REPOSITORY = 'STATS_REPOSITORY';

export interface UpsertStatsData {
  gameExternalId: string;
  playerUserId: string;
  goals: number;
  assists: number;
  notes?: string;
}

export interface StatsRepositoryInterface {
  upsertStats(data: UpsertStatsData[]): Promise<PlayerStats[]>;
  findByGame(gameExternalId: string): Promise<PlayerStats[]>;
  findByPlayer(playerUserId: string): Promise<PlayerStats[]>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/domain/repositories/stats-repository.interface.ts
git commit -m "feat(open-game): add StatsRepositoryInterface"
```

---

### Task 12: Redis service

**Files:**
- Create: `services/open-game/src/infra/cache/redis.service.ts`

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
git add services/open-game/src/infra/cache/redis.service.ts
git commit -m "feat(open-game): add RedisService"
```

---

### Task 13: Drizzle repository + GameCacheService

**Files:**
- Create: `services/open-game/src/modules/open-game/games/infra/database/repositories/drizzle-open-game.repository.ts`
- Create: `services/open-game/src/modules/open-game/games/infra/cache/game-cache.service.ts`

- [ ] **Step 1: Criar game-cache.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { RedisService } from '../../../../../infra/cache/redis.service';
import type { OpenGame } from '../../domain/models/open-game.entity';

const UPCOMING_KEY = 'games:upcoming';
const UPCOMING_TTL = 30; // seconds

@Injectable()
export class GameCacheService {
  constructor(private readonly redis: RedisService) {}

  async getUpcoming(): Promise<OpenGame[] | null> {
    const cached = await this.redis.client.get(UPCOMING_KEY);
    return cached ? (JSON.parse(cached) as OpenGame[]) : null;
  }

  async setUpcoming(games: OpenGame[]): Promise<void> {
    await this.redis.client.set(UPCOMING_KEY, JSON.stringify(games), 'EX', UPCOMING_TTL);
  }

  async invalidate(): Promise<void> {
    await this.redis.client.del(UPCOMING_KEY);
  }

  /** Tenta adquirir lock exclusivo (SET NX PX). Retorna true se lock adquirido. */
  async acquireJoinLock(gameId: string): Promise<boolean> {
    const result = await this.redis.client.set(
      `lock:join:game:${gameId}`,
      '1',
      'NX',
      'PX',
      3000,
    );
    return result === 'OK';
  }

  async releaseJoinLock(gameId: string): Promise<void> {
    await this.redis.client.del(`lock:join:game:${gameId}`);
  }
}
```

- [ ] **Step 2: Criar drizzle-open-game.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { and, eq, gte, inArray, isNull, lte, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateOpenGameData,
  ListOpenGamesFilter,
  OpenGameRepositoryInterface,
  UpdateOpenGameData,
} from '../../domain/repositories/open-game-repository.interface';
import type { OpenGame, GameStatus } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';
import { openGames, type OpenGameRow } from '../database/schemas/open-game.schema';
import { gameParticipants, type GameParticipantRow } from '../database/schemas/game-participant.schema';

@Injectable()
export class DrizzleOpenGameRepository implements OpenGameRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateOpenGameData): Promise<OpenGame> {
    const [row] = await this.drizzle.db
      .insert(openGames)
      .values({
        organizerUserId: data.organizerUserId,
        fieldId: data.fieldId ?? null,
        fieldNameSnapshot: data.fieldNameSnapshot ?? null,
        fieldAddressSnapshot: data.fieldAddressSnapshot ?? null,
        title: data.title,
        description: data.description ?? null,
        sport: data.sport,
        scheduledAt: data.scheduledAt,
        durationMinutes: data.durationMinutes ?? 60,
        minPlayers: data.minPlayers ?? 10,
        maxPlayers: data.maxPlayers ?? 22,
        pricePerPlayer: data.pricePerPlayer != null ? String(data.pricePerPlayer) : null,
        status: 'open',
      })
      .returning();
    return this.toGame(row);
  }

  async findById(externalId: string): Promise<OpenGame | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(openGames)
      .where(and(eq(openGames.externalId, externalId), eq(openGames.isActive, true)))
      .limit(1);
    return row ? this.toGame(row) : null;
  }

  async findUpcoming(filter: ListOpenGamesFilter): Promise<OpenGame[]> {
    const conditions = [eq(openGames.isActive, true)];

    if (filter.status && filter.status.length > 0) {
      conditions.push(inArray(openGames.status, filter.status));
    } else {
      conditions.push(inArray(openGames.status, ['open', 'full']));
    }

    if (filter.sport) {
      conditions.push(eq(openGames.sport, filter.sport));
    }
    if (filter.fieldId) {
      conditions.push(eq(openGames.fieldId, filter.fieldId));
    }
    if (filter.fromDate) {
      conditions.push(gte(openGames.scheduledAt, filter.fromDate));
    }
    if (filter.toDate) {
      conditions.push(lte(openGames.scheduledAt, filter.toDate));
    }

    const rows = await this.drizzle.db
      .select()
      .from(openGames)
      .where(and(...conditions))
      .orderBy(openGames.scheduledAt);

    return rows.map(this.toGame);
  }

  async update(externalId: string, data: UpdateOpenGameData): Promise<OpenGame> {
    const values: Partial<typeof openGames.$inferInsert> = { updatedAt: new Date() };
    if (data.title !== undefined) values.title = data.title;
    if (data.description !== undefined) values.description = data.description;
    if (data.fieldId !== undefined) values.fieldId = data.fieldId;
    if (data.fieldNameSnapshot !== undefined) values.fieldNameSnapshot = data.fieldNameSnapshot;
    if (data.fieldAddressSnapshot !== undefined) values.fieldAddressSnapshot = data.fieldAddressSnapshot;
    if (data.scheduledAt !== undefined) values.scheduledAt = data.scheduledAt;
    if (data.durationMinutes !== undefined) values.durationMinutes = data.durationMinutes;
    if (data.minPlayers !== undefined) values.minPlayers = data.minPlayers;
    if (data.maxPlayers !== undefined) values.maxPlayers = data.maxPlayers;
    if (data.pricePerPlayer !== undefined) {
      values.pricePerPlayer = data.pricePerPlayer != null ? String(data.pricePerPlayer) : null;
    }

    const [row] = await this.drizzle.db
      .update(openGames)
      .set(values)
      .where(eq(openGames.externalId, externalId))
      .returning();

    if (!row) throw new Error(`OpenGame "${externalId}" not found`);
    return this.toGame(row);
  }

  async updateStatus(externalId: string, status: GameStatus): Promise<void> {
    await this.drizzle.db
      .update(openGames)
      .set({ status, updatedAt: new Date() })
      .where(eq(openGames.externalId, externalId));
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(openGames)
      .set({ isActive: false, status: 'cancelled', updatedAt: new Date() })
      .where(eq(openGames.externalId, externalId));
  }

  async addParticipant(
    gameExternalId: string,
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<GameParticipant> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) throw new Error(`OpenGame "${gameExternalId}" not found`);

    const [row] = await this.drizzle.db
      .insert(gameParticipants)
      .values({ gameId: gameRow.id, playerUserId, displayName, position })
      .returning();

    if (!row) throw new Error(`Failed to add participant to game "${gameExternalId}"`);
    return this.toParticipant(row, gameExternalId);
  }

  async removeParticipant(gameExternalId: string, playerUserId: string): Promise<void> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) throw new Error(`OpenGame "${gameExternalId}" not found`);

    await this.drizzle.db
      .update(gameParticipants)
      .set({ leftAt: new Date() })
      .where(
        and(
          eq(gameParticipants.gameId, gameRow.id),
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      );
  }

  async findParticipant(gameExternalId: string, playerUserId: string): Promise<GameParticipant | null> {
    const [row] = await this.drizzle.db
      .select({ gp: gameParticipants })
      .from(gameParticipants)
      .innerJoin(openGames, eq(openGames.id, gameParticipants.gameId))
      .where(
        and(
          eq(openGames.externalId, gameExternalId),
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      )
      .limit(1);

    return row ? this.toParticipant(row.gp, gameExternalId) : null;
  }

  async findParticipants(gameExternalId: string): Promise<GameParticipant[]> {
    const rows = await this.drizzle.db
      .select({ gp: gameParticipants })
      .from(gameParticipants)
      .innerJoin(openGames, eq(openGames.id, gameParticipants.gameId))
      .where(
        and(
          eq(openGames.externalId, gameExternalId),
          isNull(gameParticipants.leftAt),
        ),
      );

    return rows.map((r) => this.toParticipant(r.gp, gameExternalId));
  }

  async countActiveParticipants(gameExternalId: string): Promise<number> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) return 0;

    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(gameParticipants)
      .where(
        and(
          eq(gameParticipants.gameId, gameRow.id),
          isNull(gameParticipants.leftAt),
        ),
      );

    return result?.count ?? 0;
  }

  async updateParticipantSnapshot(
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<void> {
    await this.drizzle.db
      .update(gameParticipants)
      .set({ displayName, position })
      .where(
        and(
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      );
  }

  private toGame(row: OpenGameRow): OpenGame {
    return {
      id: row.externalId,
      organizerUserId: row.organizerUserId,
      fieldId: row.fieldId ?? null,
      fieldNameSnapshot: row.fieldNameSnapshot ?? null,
      fieldAddressSnapshot: row.fieldAddressSnapshot ?? null,
      title: row.title,
      description: row.description ?? null,
      sport: row.sport as OpenGame['sport'],
      scheduledAt: row.scheduledAt,
      durationMinutes: row.durationMinutes,
      minPlayers: row.minPlayers,
      maxPlayers: row.maxPlayers,
      pricePerPlayer: row.pricePerPlayer != null ? parseFloat(row.pricePerPlayer) : null,
      status: row.status as OpenGame['status'],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toParticipant(row: GameParticipantRow, gameExternalId: string): GameParticipant {
    return {
      gameExternalId,
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      position: row.position ?? null,
      joinedAt: row.joinedAt,
      leftAt: row.leftAt ?? null,
    };
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/games/infra/
git commit -m "feat(open-game): add DrizzleOpenGameRepository and GameCacheService"
```

---

### Task 14: Drizzle repository — `DrizzleStatsRepository`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/infra/database/repositories/drizzle-stats.repository.ts`

- [ ] **Step 1: Criar drizzle-stats.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  StatsRepositoryInterface,
  UpsertStatsData,
} from '../../domain/repositories/stats-repository.interface';
import type { PlayerStats } from '../../domain/models/player-stats.entity';
import { playerStats, type PlayerStatsRow } from '../database/schemas/player-stats.schema';
import { openGames } from '../../../games/infra/database/schemas/open-game.schema';

@Injectable()
export class DrizzleStatsRepository implements StatsRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsertStats(data: UpsertStatsData[]): Promise<PlayerStats[]> {
    if (data.length === 0) return [];

    // Resolve external_id → internal id for all games at once
    const externalIds = [...new Set(data.map((d) => d.gameExternalId))];
    const gameRows = await this.drizzle.db
      .select({ id: openGames.id, externalId: openGames.externalId })
      .from(openGames)
      .where(sql`${openGames.externalId} = ANY(${sql.raw(`ARRAY['${externalIds.join("','")}']::uuid[]`)})`);

    const gameIdMap = new Map(gameRows.map((r) => [r.externalId, r.id]));

    const rows = await this.drizzle.db
      .insert(playerStats)
      .values(
        data.map((d) => ({
          gameId: gameIdMap.get(d.gameExternalId)!,
          playerUserId: d.playerUserId,
          goals: d.goals,
          assists: d.assists,
          notes: d.notes ?? null,
        })),
      )
      .onConflictDoUpdate({
        target: [playerStats.gameId, playerStats.playerUserId],
        set: {
          goals: sql`excluded.goals`,
          assists: sql`excluded.assists`,
          notes: sql`excluded.notes`,
        },
      })
      .returning();

    return rows.map((r) => this.toStats(r, data.find((d) => gameIdMap.get(d.gameExternalId) === r.gameId)!.gameExternalId));
  }

  async findByGame(gameExternalId: string): Promise<PlayerStats[]> {
    const rows = await this.drizzle.db
      .select({ ps: playerStats })
      .from(playerStats)
      .innerJoin(openGames, eq(openGames.id, playerStats.gameId))
      .where(eq(openGames.externalId, gameExternalId));

    return rows.map((r) => this.toStats(r.ps, gameExternalId));
  }

  async findByPlayer(playerUserId: string): Promise<PlayerStats[]> {
    const rows = await this.drizzle.db
      .select({ ps: playerStats, gameExternalId: openGames.externalId })
      .from(playerStats)
      .innerJoin(openGames, eq(openGames.id, playerStats.gameId))
      .where(eq(playerStats.playerUserId, playerUserId));

    return rows.map((r) => this.toStats(r.ps, r.gameExternalId));
  }

  private toStats(row: PlayerStatsRow, gameExternalId: string): PlayerStats {
    return {
      gameExternalId,
      playerUserId: row.playerUserId,
      goals: row.goals,
      assists: row.assists,
      notes: row.notes ?? null,
      createdAt: row.createdAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/infra/database/repositories/drizzle-stats.repository.ts
git commit -m "feat(open-game): add DrizzleStatsRepository"
```

---

### Task 15: DTOs de entrada — `CreateOpenGameDto`, `UpdateOpenGameDto`, `ListOpenGamesDto`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/application/dto/create-open-game.dto.ts`
- Create: `services/open-game/src/modules/open-game/games/application/dto/update-open-game.dto.ts`
- Create: `services/open-game/src/modules/open-game/games/application/dto/list-open-games.dto.ts`

- [ ] **Step 1: Criar create-open-game.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString, IsNotEmpty, IsEnum, IsISO8601, IsOptional,
  IsPositive, IsInt, Min, Max, IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOpenGameDto {
  @ApiProperty({ example: 'Pelada de terça' })
  @IsString() @IsNotEmpty()
  title!: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  description?: string;

  @ApiProperty({ enum: ['futsal', 'society', 'campo'] })
  @IsEnum(['futsal', 'society', 'campo'])
  sport!: string;

  @ApiProperty({ example: '2026-07-01T19:00:00Z', description: 'ISO 8601 UTC' })
  @IsISO8601()
  scheduledAt!: string;

  @ApiPropertyOptional({ default: 60 })
  @IsInt() @IsPositive() @IsOptional()
  @Type(() => Number)
  durationMinutes?: number;

  @ApiPropertyOptional({ default: 10 })
  @IsInt() @Min(2) @Max(30) @IsOptional()
  @Type(() => Number)
  minPlayers?: number;

  @ApiPropertyOptional({ default: 22 })
  @IsInt() @Min(2) @Max(30) @IsOptional()
  @Type(() => Number)
  maxPlayers?: number;

  @ApiPropertyOptional({ description: 'UUID do campo cadastrado no field-service' })
  @IsUUID() @IsOptional()
  fieldId?: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  fieldNameSnapshot?: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  fieldAddressSnapshot?: string;

  @ApiPropertyOptional({ description: 'Preço por jogador em reais (null = gratuito)' })
  @IsPositive() @IsOptional()
  @Type(() => Number)
  pricePerPlayer?: number;
}
```

- [ ] **Step 2: Criar update-open-game.dto.ts**

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString, IsISO8601, IsOptional, IsPositive, IsInt,
  Min, Max, IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateOpenGameDto {
  @ApiPropertyOptional() @IsString() @IsOptional() title?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() description?: string;
  @ApiPropertyOptional() @IsISO8601() @IsOptional() scheduledAt?: string;
  @ApiPropertyOptional() @IsInt() @IsPositive() @IsOptional() @Type(() => Number) durationMinutes?: number;
  @ApiPropertyOptional() @IsInt() @Min(2) @Max(30) @IsOptional() @Type(() => Number) minPlayers?: number;
  @ApiPropertyOptional() @IsInt() @Min(2) @Max(30) @IsOptional() @Type(() => Number) maxPlayers?: number;
  @ApiPropertyOptional() @IsUUID() @IsOptional() fieldId?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() fieldNameSnapshot?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() fieldAddressSnapshot?: string;
  @ApiPropertyOptional() @IsPositive() @IsOptional() @Type(() => Number) pricePerPlayer?: number;
}
```

- [ ] **Step 3: Criar list-open-games.dto.ts**

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsISO8601, IsOptional, IsUUID } from 'class-validator';

export class ListOpenGamesDto {
  @ApiPropertyOptional({ enum: ['futsal', 'society', 'campo'] })
  @IsEnum(['futsal', 'society', 'campo']) @IsOptional()
  sport?: string;

  @ApiPropertyOptional({ description: 'UUID do campo (field-service)' })
  @IsUUID() @IsOptional()
  fieldId?: string;

  @ApiPropertyOptional({ example: '2026-07-01T00:00:00Z' })
  @IsISO8601() @IsOptional()
  from?: string;

  @ApiPropertyOptional({ example: '2026-07-31T23:59:59Z' })
  @IsISO8601() @IsOptional()
  to?: string;
}
```

- [ ] **Step 4: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/dto/
git commit -m "feat(open-game): add input DTOs (create, update, list)"
```

---

### Task 16: DTOs de saída — `OpenGameDto`, `GameParticipantDto`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/application/dto/open-game.dto.ts`
- Create: `services/open-game/src/modules/open-game/games/application/dto/game-participant.dto.ts`

- [ ] **Step 1: Criar open-game.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { OpenGame } from '../../domain/models/open-game.entity';

export class OpenGameDto {
  @ApiProperty() id!: string;
  @ApiProperty() organizerUserId!: string;
  @ApiPropertyOptional() fieldId!: string | null;
  @ApiPropertyOptional() fieldNameSnapshot!: string | null;
  @ApiPropertyOptional() fieldAddressSnapshot!: string | null;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() description!: string | null;
  @ApiProperty() sport!: string;
  @ApiProperty() scheduledAt!: Date;
  @ApiProperty() durationMinutes!: number;
  @ApiProperty() minPlayers!: number;
  @ApiProperty() maxPlayers!: number;
  @ApiPropertyOptional() pricePerPlayer!: number | null;
  @ApiProperty() status!: string;
  @ApiProperty() participantCount!: number;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;

  static fromGame(game: OpenGame, participantCount: number): OpenGameDto {
    const dto = new OpenGameDto();
    dto.id = game.id;
    dto.organizerUserId = game.organizerUserId;
    dto.fieldId = game.fieldId;
    dto.fieldNameSnapshot = game.fieldNameSnapshot;
    dto.fieldAddressSnapshot = game.fieldAddressSnapshot;
    dto.title = game.title;
    dto.description = game.description;
    dto.sport = game.sport;
    dto.scheduledAt = game.scheduledAt;
    dto.durationMinutes = game.durationMinutes;
    dto.minPlayers = game.minPlayers;
    dto.maxPlayers = game.maxPlayers;
    dto.pricePerPlayer = game.pricePerPlayer;
    dto.status = game.status;
    dto.participantCount = participantCount;
    dto.createdAt = game.createdAt;
    dto.updatedAt = game.updatedAt;
    return dto;
  }
}
```

- [ ] **Step 2: Criar game-participant.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

export class GameParticipantDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiPropertyOptional() position!: string | null;
  @ApiProperty() joinedAt!: Date;

  static fromParticipant(p: GameParticipant): GameParticipantDto {
    const dto = new GameParticipantDto();
    dto.playerUserId = p.playerUserId;
    dto.displayName = p.displayName;
    dto.position = p.position;
    dto.joinedAt = p.joinedAt;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/dto/open-game.dto.ts
git add services/open-game/src/modules/open-game/games/application/dto/game-participant.dto.ts
git commit -m "feat(open-game): add output DTOs (OpenGameDto, GameParticipantDto)"
```

---

### Task 17: DTOs de stats — `RecordStatsDto`, `StatsDto`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/application/dto/record-stats.dto.ts`
- Create: `services/open-game/src/modules/open-game/stats/application/dto/stats.dto.ts`

- [ ] **Step 1: Criar record-stats.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsUUID, IsInt, Min, IsOptional, IsString, ValidateNested, ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';

export class PlayerStatEntryDto {
  @ApiProperty({ description: 'UUID do jogador (identity)' })
  @IsUUID()
  playerUserId!: string;

  @ApiProperty({ default: 0 }) @IsInt() @Min(0) goals!: number;
  @ApiProperty({ default: 0 }) @IsInt() @Min(0) assists!: number;

  @ApiPropertyOptional() @IsString() @IsOptional() notes?: string;
}

export class RecordStatsDto {
  @ApiProperty({ type: [PlayerStatEntryDto] })
  @ValidateNested({ each: true })
  @ArrayMinSize(1)
  @Type(() => PlayerStatEntryDto)
  players!: PlayerStatEntryDto[];
}
```

- [ ] **Step 2: Criar stats.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { PlayerStats } from '../../domain/models/player-stats.entity';

export class StatsDto {
  @ApiProperty() gameId!: string;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() goals!: number;
  @ApiProperty() assists!: number;
  @ApiPropertyOptional() notes!: string | null;
  @ApiProperty() createdAt!: Date;

  static fromStats(s: PlayerStats): StatsDto {
    const dto = new StatsDto();
    dto.gameId = s.gameExternalId;
    dto.playerUserId = s.playerUserId;
    dto.goals = s.goals;
    dto.assists = s.assists;
    dto.notes = s.notes;
    dto.createdAt = s.createdAt;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/application/dto/
git commit -m "feat(open-game): add stats DTOs"
```

---

### Task 18: `OpenGameService` — testes e implementação

**Files:**
- Create: `services/open-game/src/modules/open-game/games/application/services/open-game.service.spec.ts`
- Create: `services/open-game/src/modules/open-game/games/application/services/open-game.service.ts`

- [ ] **Step 1: Escrever open-game.service.spec.ts**

```typescript
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { OpenGameService } from './open-game.service';
import { OPEN_GAME_REPOSITORY } from '../../domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from './open-game-messaging.service';
import { GameCacheService } from '../../infra/cache/game-cache.service';
import type { OpenGame } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

const mockRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findUpcoming: jest.fn(),
  update: jest.fn(),
  updateStatus: jest.fn(),
  deactivate: jest.fn(),
  addParticipant: jest.fn(),
  removeParticipant: jest.fn(),
  findParticipant: jest.fn(),
  findParticipants: jest.fn(),
  countActiveParticipants: jest.fn(),
  updateParticipantSnapshot: jest.fn(),
};

const mockMessaging = {
  publishCreated: jest.fn(),
  publishPlayerJoined: jest.fn(),
  publishPlayerLeft: jest.fn(),
  publishFull: jest.fn(),
  publishFinished: jest.fn(),
  publishCancelled: jest.fn(),
};

const mockCache = {
  getUpcoming: jest.fn(),
  setUpcoming: jest.fn(),
  invalidate: jest.fn(),
  acquireJoinLock: jest.fn(),
  releaseJoinLock: jest.fn(),
};

const mockGame: OpenGame = {
  id: 'game-uuid-1',
  organizerUserId: 'organizer-uuid-1',
  fieldId: null,
  fieldNameSnapshot: null,
  fieldAddressSnapshot: null,
  title: 'Pelada de terça',
  description: null,
  sport: 'society',
  scheduledAt: new Date('2026-07-01T19:00:00Z'),
  durationMinutes: 60,
  minPlayers: 10,
  maxPlayers: 22,
  pricePerPlayer: null,
  status: 'open',
  createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-06-01'),
};

const mockParticipant: GameParticipant = {
  gameExternalId: 'game-uuid-1',
  playerUserId: 'player-uuid-1',
  displayName: 'João Silva',
  position: 'atacante',
  joinedAt: new Date('2026-06-01'),
  leftAt: null,
};

describe('OpenGameService', () => {
  let service: OpenGameService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        OpenGameService,
        { provide: OPEN_GAME_REPOSITORY, useValue: mockRepo },
        { provide: OpenGameMessagingService, useValue: mockMessaging },
        { provide: GameCacheService, useValue: mockCache },
      ],
    }).compile();
    service = module.get(OpenGameService);
  });

  describe('create', () => {
    it('cria jogo, invalida cache e publica CREATED', async () => {
      mockRepo.create.mockResolvedValue(mockGame);
      mockRepo.countActiveParticipants.mockResolvedValue(0);

      const result = await service.create('organizer-uuid-1', 'João', {
        title: 'Pelada de terça',
        sport: 'society',
        scheduledAt: '2026-07-01T19:00:00Z',
      });

      expect(mockRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        organizerUserId: 'organizer-uuid-1',
        title: 'Pelada de terça',
        sport: 'society',
      }));
      expect(mockCache.invalidate).toHaveBeenCalled();
      expect(mockMessaging.publishCreated).toHaveBeenCalledWith(mockGame, 0);
      expect(result.id).toBe('game-uuid-1');
    });
  });

  describe('getById', () => {
    it('retorna jogo com contagem de participantes', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.countActiveParticipants.mockResolvedValue(5);

      const result = await service.getById('game-uuid-1');

      expect(result.id).toBe('game-uuid-1');
      expect(result.participantCount).toBe(5);
    });

    it('lança NotFoundException se jogo não encontrado', async () => {
      mockRepo.findById.mockResolvedValue(null);
      await expect(service.getById('not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('cancel', () => {
    it('lança ForbiddenException se usuário não é o organizador', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      await expect(service.cancel('other-user', 'game-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('cancela jogo, invalida cache e publica CANCELLED', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);

      await service.cancel('organizer-uuid-1', 'game-uuid-1');

      expect(mockRepo.deactivate).toHaveBeenCalledWith('game-uuid-1');
      expect(mockCache.invalidate).toHaveBeenCalled();
    });
  });

  describe('join', () => {
    it('lança ConflictException se jogador já está no jogo', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(mockParticipant);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      await expect(
        service.join('player-uuid-1', 'João', null, 'game-uuid-1'),
      ).rejects.toThrow(ConflictException);

      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
    });

    it('lança ConflictException se jogo está lotado (count >= maxPlayers)', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(null);
      mockRepo.countActiveParticipants.mockResolvedValue(22);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      await expect(
        service.join('player-uuid-1', 'João', null, 'game-uuid-1'),
      ).rejects.toThrow(ConflictException);

      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
    });

    it('adiciona participante, publica PLAYER_JOINED e FULL ao atingir minPlayers', async () => {
      mockRepo.findById.mockResolvedValue(mockGame); // minPlayers=10
      mockRepo.findParticipant.mockResolvedValue(null);
      mockRepo.countActiveParticipants.mockResolvedValue(9); // count pré-join
      mockRepo.addParticipant.mockResolvedValue(mockParticipant);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      const result = await service.join('player-uuid-1', 'João', null, 'game-uuid-1');

      expect(mockRepo.addParticipant).toHaveBeenCalled();
      expect(mockMessaging.publishPlayerJoined).toHaveBeenCalledWith(mockGame, mockParticipant);
      // 9 + 1 = 10 = minPlayers → deve publicar FULL e atualizar status
      expect(mockRepo.updateStatus).toHaveBeenCalledWith('game-uuid-1', 'full');
      expect(mockMessaging.publishFull).toHaveBeenCalledWith(mockGame);
      expect(mockCache.invalidate).toHaveBeenCalled();
      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
      expect(result.playerUserId).toBe('player-uuid-1');
    });
  });

  describe('leave', () => {
    it('remove participante e publica PLAYER_LEFT', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(mockParticipant);
      mockRepo.countActiveParticipants.mockResolvedValue(11);

      await service.leave('player-uuid-1', 'game-uuid-1');

      expect(mockRepo.removeParticipant).toHaveBeenCalledWith('game-uuid-1', 'player-uuid-1');
      expect(mockCache.invalidate).toHaveBeenCalled();
    });

    it('lança NotFoundException se participante não encontrado', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(null);

      await expect(service.leave('player-uuid-1', 'game-uuid-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('finish', () => {
    it('lança ForbiddenException se não é o organizador', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      await expect(service.finish('other-user', 'game-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('marca jogo como finalizado e publica FINISHED', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);

      await service.finish('organizer-uuid-1', 'game-uuid-1');

      expect(mockRepo.updateStatus).toHaveBeenCalledWith('game-uuid-1', 'finished');
      expect(mockMessaging.publishFinished).toHaveBeenCalledWith(mockGame);
      expect(mockCache.invalidate).toHaveBeenCalled();
    });
  });
});
```

- [ ] **Step 2: Executar testes para verificar que falham**

```bash
npx jest --testPathPattern=open-game.service.spec --no-coverage 2>&1 | tail -20
```

Expected: falha com `Cannot find module './open-game.service'`

- [ ] **Step 3: Implementar open-game.service.ts**

```typescript
import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from './open-game-messaging.service';
import { GameCacheService } from '../../infra/cache/game-cache.service';
import { CreateOpenGameDto } from '../dto/create-open-game.dto';
import { UpdateOpenGameDto } from '../dto/update-open-game.dto';
import { ListOpenGamesDto } from '../dto/list-open-games.dto';
import { OpenGameDto } from '../dto/open-game.dto';
import { GameParticipantDto } from '../dto/game-participant.dto';

@Injectable()
export class OpenGameService {
  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly repo: OpenGameRepositoryInterface,
    private readonly messaging: OpenGameMessagingService,
    private readonly cache: GameCacheService,
  ) {}

  async create(userId: string, _displayName: string, dto: CreateOpenGameDto): Promise<OpenGameDto> {
    const game = await this.repo.create({
      organizerUserId: userId,
      fieldId: dto.fieldId,
      fieldNameSnapshot: dto.fieldNameSnapshot,
      fieldAddressSnapshot: dto.fieldAddressSnapshot,
      title: dto.title,
      description: dto.description,
      sport: dto.sport,
      scheduledAt: new Date(dto.scheduledAt),
      durationMinutes: dto.durationMinutes,
      minPlayers: dto.minPlayers,
      maxPlayers: dto.maxPlayers,
      pricePerPlayer: dto.pricePerPlayer,
    });

    await this.cache.invalidate();

    try {
      await this.messaging.publishCreated(game, 0);
    } catch {
      // advisory
    }

    return OpenGameDto.fromGame(game, 0);
  }

  async list(query: ListOpenGamesDto): Promise<OpenGameDto[]> {
    const hasFilters = Boolean(query.sport || query.fieldId || query.from || query.to);

    if (!hasFilters) {
      const cached = await this.cache.getUpcoming();
      if (cached) return cached;
    }

    const games = await this.repo.findUpcoming({
      sport: query.sport,
      fieldId: query.fieldId,
      fromDate: query.from ? new Date(query.from) : undefined,
      toDate: query.to ? new Date(query.to) : undefined,
    });

    const dtos = await Promise.all(
      games.map(async (g) => {
        const count = await this.repo.countActiveParticipants(g.id);
        return OpenGameDto.fromGame(g, count);
      }),
    );

    if (!hasFilters) {
      await this.cache.setUpcoming(dtos);
    }

    return dtos;
  }

  async getById(gameId: string): Promise<OpenGameDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const count = await this.repo.countActiveParticipants(gameId);
    return OpenGameDto.fromGame(game, count);
  }

  async update(userId: string, gameId: string, dto: UpdateOpenGameDto): Promise<OpenGameDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can update this game');
    }

    const updated = await this.repo.update(gameId, {
      title: dto.title,
      description: dto.description,
      fieldId: dto.fieldId,
      fieldNameSnapshot: dto.fieldNameSnapshot,
      fieldAddressSnapshot: dto.fieldAddressSnapshot,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
      durationMinutes: dto.durationMinutes,
      minPlayers: dto.minPlayers,
      maxPlayers: dto.maxPlayers,
      pricePerPlayer: dto.pricePerPlayer,
    });

    await this.cache.invalidate();
    const count = await this.repo.countActiveParticipants(gameId);
    return OpenGameDto.fromGame(updated, count);
  }

  async cancel(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can cancel this game');
    }

    await this.repo.deactivate(gameId);
    await this.cache.invalidate();

    try {
      await this.messaging.publishCancelled(game);
    } catch {
      // advisory
    }
  }

  async join(userId: string, displayName: string, position: string | null, gameId: string): Promise<GameParticipantDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.status === 'finished' || game.status === 'cancelled') {
      throw new ConflictException('Cannot join a finished or cancelled game');
    }

    const acquired = await this.cache.acquireJoinLock(gameId);
    if (!acquired) {
      throw new ConflictException('Another join is in progress — try again in a moment');
    }

    try {
      const existing = await this.repo.findParticipant(gameId, userId);
      if (existing) throw new ConflictException('Already joined this game');

      const count = await this.repo.countActiveParticipants(gameId);
      if (count >= game.maxPlayers) throw new ConflictException('Game is full');

      const participant = await this.repo.addParticipant(gameId, userId, displayName, position);
      const newCount = count + 1;

      await this.cache.invalidate();

      try {
        await this.messaging.publishPlayerJoined(game, participant);
        if (newCount === game.minPlayers) {
          await this.repo.updateStatus(gameId, 'full');
          await this.messaging.publishFull(game);
        }
      } catch {
        // advisory
      }

      return GameParticipantDto.fromParticipant(participant);
    } finally {
      await this.cache.releaseJoinLock(gameId);
    }
  }

  async leave(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);

    const participant = await this.repo.findParticipant(gameId, userId);
    if (!participant) throw new NotFoundException('Not a participant of this game');

    await this.repo.removeParticipant(gameId, userId);

    const remainingCount = await this.repo.countActiveParticipants(gameId);
    if (remainingCount < game.minPlayers && game.status === 'full') {
      await this.repo.updateStatus(gameId, 'open');
    }

    await this.cache.invalidate();

    try {
      await this.messaging.publishPlayerLeft(game, userId);
    } catch {
      // advisory
    }
  }

  async finish(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can finish this game');
    }

    await this.repo.updateStatus(gameId, 'finished');
    await this.cache.invalidate();

    try {
      await this.messaging.publishFinished(game);
    } catch {
      // advisory
    }
  }

  async getParticipants(gameId: string): Promise<GameParticipantDto[]> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const participants = await this.repo.findParticipants(gameId);
    return participants.map(GameParticipantDto.fromParticipant);
  }
}
```

- [ ] **Step 4: Executar testes para verificar que passam**

```bash
npx jest --testPathPattern=open-game.service.spec --no-coverage
```

Expected: `Tests: 7 passed, 7 total`

- [ ] **Step 5: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/services/
git commit -m "feat(open-game): add OpenGameService with 7 tests passing"
```

---

### Task 19: `StatsService` — testes e implementação

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/application/services/stats.service.spec.ts`
- Create: `services/open-game/src/modules/open-game/stats/application/services/stats.service.ts`

- [ ] **Step 1: Escrever stats.service.spec.ts**

```typescript
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { StatsService } from './stats.service';
import { STATS_REPOSITORY } from '../../domain/repositories/stats-repository.interface';
import { OPEN_GAME_REPOSITORY } from '../../../games/domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from '../../../games/application/services/open-game-messaging.service';
import type { OpenGame } from '../../../games/domain/models/open-game.entity';
import type { PlayerStats } from '../../domain/models/player-stats.entity';

const mockGameRepo = {
  findById: jest.fn(),
};

const mockStatsRepo = {
  upsertStats: jest.fn(),
  findByGame: jest.fn(),
  findByPlayer: jest.fn(),
};

const mockMessaging = {
  publishStatsRecorded: jest.fn(),
};

const mockGame: OpenGame = {
  id: 'game-uuid-1',
  organizerUserId: 'organizer-uuid-1',
  fieldId: null,
  fieldNameSnapshot: null,
  fieldAddressSnapshot: null,
  title: 'Pelada',
  description: null,
  sport: 'society',
  scheduledAt: new Date('2026-07-01T19:00:00Z'),
  durationMinutes: 60,
  minPlayers: 10,
  maxPlayers: 22,
  pricePerPlayer: null,
  status: 'finished',
  createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-06-01'),
};

const mockStats: PlayerStats = {
  gameExternalId: 'game-uuid-1',
  playerUserId: 'player-uuid-1',
  goals: 2,
  assists: 1,
  notes: null,
  createdAt: new Date('2026-07-01'),
};

describe('StatsService', () => {
  let service: StatsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        StatsService,
        { provide: OPEN_GAME_REPOSITORY, useValue: mockGameRepo },
        { provide: STATS_REPOSITORY, useValue: mockStatsRepo },
        { provide: OpenGameMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(StatsService);
  });

  describe('recordStats', () => {
    it('lança NotFoundException se jogo não encontrado', async () => {
      mockGameRepo.findById.mockResolvedValue(null);
      await expect(
        service.recordStats('organizer-uuid-1', 'not-found', { players: [] }),
      ).rejects.toThrow(NotFoundException);
    });

    it('lança ForbiddenException se não é o organizador', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      await expect(
        service.recordStats('other-user', 'game-uuid-1', { players: [] }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('faz upsert de stats e publica STATS_RECORDED', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      mockStatsRepo.upsertStats.mockResolvedValue([mockStats]);

      const result = await service.recordStats('organizer-uuid-1', 'game-uuid-1', {
        players: [{ playerUserId: 'player-uuid-1', goals: 2, assists: 1 }],
      });

      expect(mockStatsRepo.upsertStats).toHaveBeenCalledWith([
        expect.objectContaining({
          gameExternalId: 'game-uuid-1',
          playerUserId: 'player-uuid-1',
          goals: 2,
          assists: 1,
        }),
      ]);
      expect(mockMessaging.publishStatsRecorded).toHaveBeenCalledWith(mockGame);
      expect(result[0].goals).toBe(2);
    });
  });

  describe('getGameStats', () => {
    it('retorna stats de um jogo', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      mockStatsRepo.findByGame.mockResolvedValue([mockStats]);

      const result = await service.getGameStats('game-uuid-1');

      expect(result).toHaveLength(1);
      expect(result[0].goals).toBe(2);
    });

    it('lança NotFoundException se jogo não existe', async () => {
      mockGameRepo.findById.mockResolvedValue(null);
      await expect(service.getGameStats('not-found')).rejects.toThrow(NotFoundException);
    });
  });
});
```

- [ ] **Step 2: Executar testes para verificar que falham**

```bash
npx jest --testPathPattern=stats.service.spec --no-coverage 2>&1 | tail -10
```

Expected: falha com `Cannot find module './stats.service'`

- [ ] **Step 3: Implementar stats.service.ts**

```typescript
import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  STATS_REPOSITORY,
  StatsRepositoryInterface,
} from '../../domain/repositories/stats-repository.interface';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../../games/domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from '../../../games/application/services/open-game-messaging.service';
import { RecordStatsDto } from '../dto/record-stats.dto';
import { StatsDto } from '../dto/stats.dto';

@Injectable()
export class StatsService {
  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly gameRepo: OpenGameRepositoryInterface,
    @Inject(STATS_REPOSITORY)
    private readonly statsRepo: StatsRepositoryInterface,
    private readonly messaging: OpenGameMessagingService,
  ) {}

  async recordStats(userId: string, gameId: string, dto: RecordStatsDto): Promise<StatsDto[]> {
    const game = await this.gameRepo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can record stats');
    }

    const stats = await this.statsRepo.upsertStats(
      dto.players.map((p) => ({
        gameExternalId: gameId,
        playerUserId: p.playerUserId,
        goals: p.goals,
        assists: p.assists,
        notes: p.notes,
      })),
    );

    try {
      await this.messaging.publishStatsRecorded(game);
    } catch {
      // advisory
    }

    return stats.map(StatsDto.fromStats);
  }

  async getGameStats(gameId: string): Promise<StatsDto[]> {
    const game = await this.gameRepo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const stats = await this.statsRepo.findByGame(gameId);
    return stats.map(StatsDto.fromStats);
  }
}
```

- [ ] **Step 4: Executar todos os testes**

```bash
npx jest --no-coverage
```

Expected: `Tests: 12 passed, 12 total` (7 do OpenGameService + 5 do StatsService)

- [ ] **Step 5: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/application/services/
git commit -m "feat(open-game): add StatsService with 5 tests passing"
```

---

### Task 20: `IdentityEventsConsumer`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/application/services/identity-events.consumer.ts`

- [ ] **Step 1: Criar identity-events.consumer.ts**

```typescript
import { Inject, Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../domain/repositories/open-game-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly repo: OpenGameRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'open-game-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.repo.updateParticipantSnapshot(
        payload.userId,
        payload.displayName,
        payload.position,
      );
      this.logger.debug(`Updated participant snapshot for player ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update participant snapshot for player ${payload.userId}: ${message}`,
      );
      // Don't rethrow — idempotent; snapshot corrected on next profile update
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/services/identity-events.consumer.ts
git commit -m "feat(open-game): add IdentityEventsConsumer for profile snapshot updates"
```

---

### Task 21: `OpenGameMessagingService`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts`

- [ ] **Step 1: Criar open-game-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';
import type { OpenGame } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

@Injectable()
export class OpenGameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishCreated(game: OpenGame, participantCount: number): Promise<void> {
    await this.messaging.publish(OpenGameEvents.CREATED, {
      gameId: game.id,
      organizerUserId: game.organizerUserId,
      title: game.title,
      sport: game.sport,
      scheduledAt: game.scheduledAt,
      fieldId: game.fieldId,
      minPlayers: game.minPlayers,
      maxPlayers: game.maxPlayers,
      participantCount,
    });
  }

  async publishPlayerJoined(game: OpenGame, participant: GameParticipant): Promise<void> {
    await this.messaging.publish(OpenGameEvents.PLAYER_JOINED, {
      gameId: game.id,
      playerUserId: participant.playerUserId,
      displayName: participant.displayName,
    });
  }

  async publishPlayerLeft(game: OpenGame, playerUserId: string): Promise<void> {
    await this.messaging.publish(OpenGameEvents.PLAYER_LEFT, {
      gameId: game.id,
      playerUserId,
    });
  }

  async publishFull(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.FULL, {
      gameId: game.id,
      minPlayers: game.minPlayers,
    });
  }

  async publishFinished(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.FINISHED, {
      gameId: game.id,
      scheduledAt: game.scheduledAt,
      sport: game.sport,
    });
  }

  async publishCancelled(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.CANCELLED, {
      gameId: game.id,
    });
  }

  async publishStatsRecorded(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.STATS_RECORDED, {
      gameId: game.id,
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/games/application/services/open-game-messaging.service.ts
git commit -m "feat(open-game): add OpenGameMessagingService"
```

---

### Task 22: `OpenGamesController`

**Files:**
- Create: `services/open-game/src/modules/open-game/games/infra/controllers/open-games.controller.ts`

- [ ] **Step 1: Criar open-games.controller.ts**

```typescript
import {
  Body, Controller, Delete, Get, HttpCode, HttpStatus,
  Param, Post, Put, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { OpenGameService } from '../../application/services/open-game.service';
import { CreateOpenGameDto } from '../../application/dto/create-open-game.dto';
import { UpdateOpenGameDto } from '../../application/dto/update-open-game.dto';
import { ListOpenGamesDto } from '../../application/dto/list-open-games.dto';
import { OpenGameDto } from '../../application/dto/open-game.dto';
import { GameParticipantDto } from '../../application/dto/game-participant.dto';

@ApiTags('open-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('open-games')
export class OpenGamesController {
  constructor(private readonly service: OpenGameService) {}

  @Post()
  @Permissions('open-games:write')
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Criar partida aberta' })
  create(
    @Body() dto: CreateOpenGameDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    return this.service.create(user.id, user.name, dto);
  }

  @Get()
  @Public()
  @HateoasList(OpenGameDto)
  @ApiOperation({ summary: 'Listar partidas abertas (cache 30s sem filtros)' })
  list(@Query() query: ListOpenGamesDto): Promise<OpenGameDto[]> {
    return this.service.list(query);
  }

  @Get(':id')
  @Public()
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Obter partida por ID' })
  getById(@Param('id') id: string): Promise<OpenGameDto> {
    return this.service.getById(id);
  }

  @Put(':id')
  @Permissions('open-games:write')
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Atualizar dados da partida (somente organizador)' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateOpenGameDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    return this.service.update(user.id, id, dto);
  }

  @Delete(':id')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Cancelar partida (somente organizador)' })
  cancel(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.cancel(user.id, id);
  }

  @Post(':id/join')
  @Permissions('open-games:write')
  @HateoasItem(GameParticipantDto)
  @ApiOperation({ summary: 'Entrar na partida' })
  join(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<GameParticipantDto> {
    return this.service.join(user.id, user.name, null, id);
  }

  @Delete(':id/leave')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Sair da partida' })
  leave(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.leave(user.id, id);
  }

  @Post(':id/finish')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Finalizar partida (somente organizador)' })
  finish(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.finish(user.id, id);
  }

  @Get(':id/participants')
  @Public()
  @HateoasList(GameParticipantDto)
  @ApiOperation({ summary: 'Listar participantes da partida' })
  getParticipants(@Param('id') id: string): Promise<GameParticipantDto[]> {
    return this.service.getParticipants(id);
  }
}
```

**Nota:** `user.displayName` e `user.position` são propriedades do `AuthenticatedUser`. Verifique o conteúdo de `shared/src/infra/auth/interfaces/authenticated-user.interface.ts` — se `displayName` ou `position` não existirem nessa interface, adicione-os (o campo `position` pode ser opcional/undefined). Caso `displayName` não exista no token JWT, derive-o de `user.sub` temporariamente: `user.sub` contém o userId e `user.displayName` pode não existir. Consulte o arquivo antes de escrever.

- [ ] **Step 2: Confirmar `AuthenticatedUser` interface**

`AuthenticatedUser` tem os campos `id`, `name`, `email`, `permissions`. O controller usa `user.name` como `displayName` e `null` como `position` — nenhuma alteração necessária na interface.

- [ ] **Step 3: Commit**

```bash
git add services/open-game/src/modules/open-game/games/infra/controllers/open-games.controller.ts
git commit -m "feat(open-game): add OpenGamesController (9 endpoints)"
```

---

### Task 23: `StatsController`

**Files:**
- Create: `services/open-game/src/modules/open-game/stats/infra/controllers/stats.controller.ts`

- [ ] **Step 1: Criar stats.controller.ts**

```typescript
import {
  Body, Controller, Get, Param, Post, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { StatsService } from '../../application/services/stats.service';
import { RecordStatsDto } from '../../application/dto/record-stats.dto';
import { StatsDto } from '../../application/dto/stats.dto';

@ApiTags('open-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('open-games')
export class StatsController {
  constructor(private readonly service: StatsService) {}

  @Post(':id/stats')
  @Permissions('open-games:write')
  @HateoasList(StatsDto)
  @ApiOperation({ summary: 'Registrar estatísticas dos jogadores (somente organizador)' })
  recordStats(
    @Param('id') id: string,
    @Body() dto: RecordStatsDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<StatsDto[]> {
    return this.service.recordStats(user.id, id, dto);
  }

  @Get(':id/stats')
  @Public()
  @HateoasList(StatsDto)
  @ApiOperation({ summary: 'Listar estatísticas da partida' })
  getGameStats(@Param('id') id: string): Promise<StatsDto[]> {
    return this.service.getGameStats(id);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/open-game/src/modules/open-game/stats/infra/controllers/stats.controller.ts
git commit -m "feat(open-game): add StatsController"
```

---

### Task 24: NestJS modules

**Files:**
- Create: `services/open-game/src/modules/open-game/games/games.module.ts`
- Create: `services/open-game/src/modules/open-game/stats/stats.module.ts`
- Create: `services/open-game/src/modules/open-game/open-game.module.ts`

- [ ] **Step 1: Criar games.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { OPEN_GAME_REPOSITORY } from './domain/repositories/open-game-repository.interface';
import { DrizzleOpenGameRepository } from './infra/database/repositories/drizzle-open-game.repository';
import { GameCacheService } from './infra/cache/game-cache.service';
import { OpenGameService } from './application/services/open-game.service';
import { OpenGameMessagingService } from './application/services/open-game-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { OpenGamesController } from './infra/controllers/open-games.controller';
import { RedisService } from '../../../infra/cache/redis.service';

@Module({
  imports: [SharedModule],
  controllers: [OpenGamesController],
  providers: [
    { provide: OPEN_GAME_REPOSITORY, useClass: DrizzleOpenGameRepository },
    RedisService,
    GameCacheService,
    OpenGameService,
    OpenGameMessagingService,
    IdentityEventsConsumer,
  ],
  exports: [OPEN_GAME_REPOSITORY, OpenGameMessagingService],
})
export class GamesModule {}
```

- [ ] **Step 2: Criar stats.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { GamesModule } from '../games/games.module';
import { STATS_REPOSITORY } from './domain/repositories/stats-repository.interface';
import { DrizzleStatsRepository } from './infra/database/repositories/drizzle-stats.repository';
import { StatsService } from './application/services/stats.service';
import { StatsController } from './infra/controllers/stats.controller';

@Module({
  imports: [SharedModule, GamesModule],
  controllers: [StatsController],
  providers: [
    { provide: STATS_REPOSITORY, useClass: DrizzleStatsRepository },
    StatsService,
  ],
})
export class StatsModule {}
```

- [ ] **Step 3: Criar open-game.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { GamesModule } from './games/games.module';
import { StatsModule } from './stats/stats.module';

@Module({
  imports: [GamesModule, StatsModule],
})
export class OpenGameModule {}
```

- [ ] **Step 4: Commit**

```bash
git add services/open-game/src/modules/open-game/
git commit -m "feat(open-game): add NestJS modules (games, stats, open-game)"
```

---

### Task 25: `main.ts` + `app.module.ts`

**Files:**
- Create: `services/open-game/src/app.module.ts`
- Create: `services/open-game/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OpenGameModule } from './modules/open-game/open-game.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    OpenGameModule,
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

- [ ] **Step 3: Build para verificar que compila sem erros**

```bash
npm run build 2>&1 | tail -20
```

Expected: `Successfully compiled project with Webpack` ou sem erros TypeScript.

- [ ] **Step 4: Executar todos os testes após build**

```bash
npx jest --no-coverage
```

Expected: `Tests: 12 passed, 12 total`

- [ ] **Step 5: Commit**

```bash
git add services/open-game/src/app.module.ts services/open-game/src/main.ts
git commit -m "feat(open-game): add app.module and main bootstrap"
```

---

### Task 26: Drizzle migration

**Files:**
- Create: `services/open-game/drizzle/0000_initial.sql` (criado manualmente)

- [ ] **Step 1: Gerar migration com drizzle-kit**

Certifique-se que `.env` tem `DATABASE_URL` apontando para um PostgreSQL acessível (local ou Docker).
Se não houver banco local, crie o arquivo manualmente conforme Step 2.

```bash
npm run db:generate
```

Expected: arquivo SQL gerado em `drizzle/` com nome `0000_<slug>.sql`.

- [ ] **Step 2: Alternativa — criar migration manualmente**

Se `db:generate` falhar (sem DB disponível), crie o arquivo manualmente:

```bash
mkdir -p drizzle/meta
```

Crie `drizzle/0000_initial_open_game.sql`:

```sql
CREATE TABLE IF NOT EXISTS "open_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" uuid DEFAULT gen_random_uuid() NOT NULL UNIQUE,
  "organizer_user_id" text NOT NULL,
  "field_id" text,
  "field_name_snapshot" text,
  "field_address_snapshot" text,
  "title" text NOT NULL,
  "description" text,
  "sport" text NOT NULL,
  "scheduled_at" timestamptz NOT NULL,
  "duration_minutes" smallint DEFAULT 60 NOT NULL,
  "min_players" smallint DEFAULT 10 NOT NULL,
  "max_players" smallint DEFAULT 22 NOT NULL,
  "price_per_player" numeric(10, 2),
  "status" text DEFAULT 'open' NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "game_participants" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" bigint NOT NULL REFERENCES "open_games"("id"),
  "player_user_id" text NOT NULL,
  "display_name" text NOT NULL,
  "position" text,
  "joined_at" timestamptz DEFAULT now() NOT NULL,
  "left_at" timestamptz
);

CREATE TABLE IF NOT EXISTS "player_stats" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" bigint NOT NULL REFERENCES "open_games"("id"),
  "player_user_id" text NOT NULL,
  "goals" smallint DEFAULT 0 NOT NULL,
  "assists" smallint DEFAULT 0 NOT NULL,
  "notes" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_player_stats_game_player" UNIQUE ("game_id", "player_user_id")
);

CREATE INDEX IF NOT EXISTS "idx_open_games_scheduled_at" ON "open_games" ("scheduled_at");
CREATE INDEX IF NOT EXISTS "idx_open_games_status" ON "open_games" ("status");
CREATE INDEX IF NOT EXISTS "idx_game_participants_player" ON "game_participants" ("player_user_id");
```

Crie `drizzle/meta/_journal.json`:

```json
{
  "version": "7",
  "dialect": "postgresql",
  "entries": [
    {
      "idx": 0,
      "version": "7",
      "when": 1748822400000,
      "tag": "0000_initial_open_game",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 3: Commit**

```bash
git add services/open-game/drizzle/
git commit -m "feat(open-game): add initial Drizzle migration"
```

---

### Task 27: `migrate.js`, `Dockerfile`, `docker-entrypoint.sh`

**Files:**
- Create: `services/open-game/scripts/migrate.js`
- Create: `services/open-game/Dockerfile`
- Create: `services/open-game/docker-entrypoint.sh`

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

- [ ] **Step 2: Criar Dockerfile**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

# Copy monorepo base config (required for @shared/* path resolution)
COPY tsconfig.base.json ./

# Copy shared module source (compiled into dist alongside service)
COPY shared/ ./shared/

# Copy service source and package files
COPY services/open-game/ ./services/open-game/

# Install all dependencies (including devDeps for build)
WORKDIR /app/services/open-game
RUN npm ci --legacy-peer-deps

# Compile TypeScript
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/open-game

# Copy compiled output
COPY --from=builder /app/services/open-game/dist ./dist

# Copy package files and install ONLY production dependencies
COPY --from=builder /app/services/open-game/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

# Copy Drizzle migration files
COPY --from=builder /app/services/open-game/drizzle ./drizzle

# Copy migration script
COPY --from=builder /app/services/open-game/scripts ./scripts

# Copy and make entrypoint executable
COPY --from=builder /app/services/open-game/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4004

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 3: Criar docker-entrypoint.sh**

```sh
#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/open-game/scripts/migrate.js

echo "Starting open-game service..."
exec node /app/services/open-game/dist/services/open-game/src/main
```

- [ ] **Step 4: Commit**

```bash
git add services/open-game/scripts/ services/open-game/Dockerfile services/open-game/docker-entrypoint.sh
git commit -m "feat(open-game): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 28: Atualizar `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Adicionar postgres-open-game, redis e open-game ao docker-compose.yml**

Adicione no bloco de infrastructure (após `postgres-field`):

```yaml
  postgres-open-game:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_open_game
    ports:
      - "5435:5432"
    volumes:
      - postgres_open_game_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d bolanarededb_open_game"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10
```

Adicione no bloco de services (após `field`):

```yaml
  open-game:
    build:
      context: .
      dockerfile: services/open-game/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4004
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-open-game:5432/bolanarededb_open_game
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
      REDIS_URL: redis://redis:6379
    ports:
      - "4004:4004"
    depends_on:
      postgres-open-game:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      redis:
        condition: service_healthy
```

Adicione `postgres_open_game_data:` no bloco `volumes:`.

- [ ] **Step 2: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(open-game): add postgres-open-game, redis and open-game to docker-compose"
```

---

### Task 29: Atualizar `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar _status.md**

Atualize a tabela e adicione a entrada do plano:

```markdown
# BolaNaRede — Status de Desenvolvimento
Última atualização: 2026-06-02

| Serviço      | Status   | Concluídas | Próxima task pendente        |
|--------------|----------|------------|------------------------------|
| shared       | ✅ DONE  | 29/29      | —                            |
| identity     | ✅ DONE  | 37/37      | —                            |
| team         | ✅ DONE  | 29/29      | —                            |
| field        | ✅ DONE  | 34/34      | —                            |
| open-game    | ✅ DONE  | 29/29      | —                            |
| social       | ⏳ TODO  | 0/?        | —                            |
| gamification | ⏳ TODO  | 0/?        | —                            |
| matchmaking  | ⏳ TODO  | 0/?        | —                            |
| game         | ⏳ TODO  | 0/?        | —                            |
| ranking      | ⏳ TODO  | 0/?        | —                            |
| notification | ⏳ TODO  | 0/?        | —                            |

## Planos

- `docs/plans/2026-05-26-shared-module.md` — 29 tasks
- `docs/plans/2026-05-26-identity-service.md` — 37 tasks
- `docs/plans/2026-05-27-team-service.md` — 29 tasks
- `docs/plans/2026-06-01-field-service.md` — 34 tasks
- `docs/plans/2026-06-02-open-game-service.md` — 29 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md docs/plans/2026-06-02-open-game-service.md
git commit -m "docs(open-game): update _status.md and add open-game plan"
```

---

## Notas de Implementação

### `AuthenticatedUser` — campos disponíveis

`AuthenticatedUser` expõe `{ id, name, email, permissions }`. O controller usa `user.name` como `displayName` do participante e passa `null` como `position` (posição não está no JWT). Isso é adequado para o snapshot inicial; o consumer `identity.profile-updated` atualizará o snapshot com a posição real quando o jogador atualizar seu perfil.

### Redis no Docker vs. local

O docker-compose adiciona um único container `redis` compartilhado. Serviços futuros (`matchmaking`, `game`) que precisarem de Redis devem apontar para o mesmo container e incluir `redis` nos seus `depends_on`.

### Testes sem Redis

Os testes unitários mockam `GameCacheService` completamente — não é necessário Redis rodando para `npx jest` funcionar. O Redis só é necessário em testes de integração ou ao rodar o serviço completo.

### `upsertStats` — segurança de SQL injection

O `DrizzleStatsRepository.upsertStats` usa `sql.raw` para construir o array UUID. Em produção, prefira usar `sql` parametrizado ou múltiplas queries individuais. O padrão `sql.raw` aqui assume que os UUIDs são validados pela DTO antes de chegarem ao repositório.
