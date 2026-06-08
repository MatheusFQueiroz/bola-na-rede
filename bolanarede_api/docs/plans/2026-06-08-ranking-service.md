# Ranking Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-07-game-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `ranking-service` (porta 4009) — serviço que mantém o ranking competitivo dos jogadores por esporte. Consome `game.match-completed` para atualizar wins/losses/draws/goals/assists/points e expõe endpoints de leaderboard e ranking individual. Publica `ranking.recalculated` após cada atualização.

**Architecture:** NestJS 11 com módulo único `ranking`, PostgreSQL dedicado. Sem Redis. Duas tabelas: `player_rankings` (ranking per player per sport, com UNIQUE em `(player_user_id, sport)` e upsert atômico) e `ranking_processed_games` (idempotência — UNIQUE em `game_id`). Pontuação: vitória=3, empate=1, derrota=0.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## Setup de Branch

**Branch:** `feature/ranking-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/ranking-service
```

---

## File Map

```
services/ranking/
├── .env.example                                                         ← Task 1
├── drizzle.config.ts                                                    ← Task 2
├── nest-cli.json                                                        ← Task 3
├── package.json                                                         ← Task 4
├── tsconfig.json                                                        ← Task 5
├── tsconfig.build.json                                                  ← Task 5
└── src/
    ├── main.ts                                                          ← Task 16
    ├── app.module.ts                                                    ← Task 16
    └── modules/
        └── ranking/
            ├── ranking.module.ts                                        ← Task 15
            ├── domain/
            │   ├── models/
            │   │   ├── player-ranking.entity.ts                        ← Task 6
            │   │   └── processed-game.entity.ts                        ← Task 6
            │   └── repositories/
            │       └── ranking-repository.interface.ts                 ← Task 8
            ├── application/
            │   ├── dto/
            │   │   ├── ranking.dto.ts                                  ← Task 10
            │   │   └── leaderboard-entry.dto.ts                        ← Task 10
            │   └── services/
            │       ├── ranking.service.spec.ts                         ← Task 12
            │       ├── ranking.service.ts                              ← Task 12
            │       ├── ranking-messaging.service.ts                    ← Task 11
            │       └── game-events.consumer.ts                         ← Task 13
            └── infra/
                ├── controllers/
                │   └── rankings.controller.ts                          ← Task 14
                └── database/
                    ├── schemas/
                    │   ├── player-ranking.schema.ts                    ← Task 7
                    │   └── ranking-processed-game.schema.ts            ← Task 7
                    └── repositories/
                        └── drizzle-ranking.repository.ts               ← Task 9

drizzle/                                                                 ← Task 17
scripts/migrate.js                                                       ← Task 18
Dockerfile                                                               ← Task 18
docker-entrypoint.sh                                                     ← Task 18
docker-compose.yml (raiz)                                                ← Task 19
docs/plans/_status.md                                                    ← Task 20
```

---

## Regras de Negócio

### Sistema de Pontuação

| Resultado | Pontos |
|-----------|--------|
| Vitória   | 3      |
| Empate    | 1      |
| Derrota   | 0      |

### Payload `game.match-completed` (consumido)

```typescript
{
  gameId: string,         // game.externalId
  matchId: string,
  sport: string,
  winnerId: string | null,  // null = empate
  players: [
    { playerUserId: string, goals: number, assists: number, won: boolean },
    { playerUserId: string, goals: number, assists: number, won: boolean },
  ],
}
```

### Payload `ranking.recalculated` (publicado)

```typescript
{
  playerUserId: string,
  sport: string,
  points: number,
  wins: number,
  losses: number,
  draws: number,
  gamesPlayed: number,
}
```

### Endpoints

| Method | Path | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/rankings?sport=futsal&limit=10` | Público | Leaderboard top N por sport (order: points DESC, wins DESC) |
| GET | `/rankings/:userId?sport=futsal` | Público | Ranking individual do jogador |

### Regras de validação

- `sport` é obrigatório na query string (ambos os endpoints)
- `limit` default = 10, máximo = 100
- Ranking individual retorna 404 se jogador não tiver partidas no sport
- Consumer idempotente: `ranking_processed_games.game_id` tem UNIQUE constraint — re-entrega do evento é ignorada
- Upsert atômico: `INSERT ... ON CONFLICT (player_user_id, sport) DO UPDATE SET games_played + 1, wins + N, ...`

---

## Contexto de Desenvolvimento

Branch: `feature/ranking-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/ranking/` salvo indicação contrária.

### Regras inegociáveis (reforço)
- Drizzle ORM (NUNCA TypeORM)
- Biome (NUNCA ESLint/Prettier)
- BIGSERIAL PK interno + UUID `external_id` exposto pela API (neste serviço, playerUserId já é UUID externo)
- Timestamps: sempre `timestamptz` (`withTimezone: true`)
- Fire-and-forget: chamadas de `messaging.publish*` APÓS commit no DB, dentro de `try/catch`
- Caminhos relativos em `infra/database/repositories/` para `domain/`: precisam de `../../../` (3 níveis)
- Idempotência em consumers RabbitMQ (processedGames table + try/catch sem rethrow)
- Sem Redis neste serviço (apenas PostgreSQL + RabbitMQ)

---

### Task 1: `.env.example`

**Files:**
- Create: `services/ranking/.env.example`

- [ ] **Step 1: Criar `.env.example`**

```
PORT=4009
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_ranking
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

Salve como `.env.example` e copie para `.env` local:
```bash
cp services/ranking/.env.example services/ranking/.env
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/.env.example
git commit -m "chore(ranking): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/ranking/drizzle.config.ts`

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
git add services/ranking/drizzle.config.ts
git commit -m "chore(ranking): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/ranking/nest-cli.json`

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
git add services/ranking/nest-cli.json
git commit -m "chore(ranking): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/ranking/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/ranking",
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
cd services/ranking && npm install --legacy-peer-deps
```

- [ ] **Step 3: Commit**

```bash
git add services/ranking/package.json services/ranking/package-lock.json
git commit -m "chore(ranking): add package.json"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/ranking/tsconfig.json`
- Create: `services/ranking/tsconfig.build.json`

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
git add services/ranking/tsconfig.json services/ranking/tsconfig.build.json
git commit -m "chore(ranking): add tsconfig files"
```

---

### Task 6: Domain entities

**Files:**
- Create: `services/ranking/src/modules/ranking/domain/models/player-ranking.entity.ts`
- Create: `services/ranking/src/modules/ranking/domain/models/processed-game.entity.ts`

- [ ] **Step 1: Criar player-ranking.entity.ts**

```typescript
export class PlayerRanking {
  id!: number;
  playerUserId!: string;
  sport!: string;
  gamesPlayed!: number;
  wins!: number;
  losses!: number;
  draws!: number;
  goals!: number;
  assists!: number;
  /** wins×3 + draws×1 */
  points!: number;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Criar processed-game.entity.ts**

```typescript
export class ProcessedGame {
  id!: number;
  gameId!: string;
  processedAt!: Date;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/ranking/src/modules/ranking/domain/models/
git commit -m "feat(ranking): add PlayerRanking and ProcessedGame domain entities"
```

---

### Task 7: Drizzle schemas

**Files:**
- Create: `services/ranking/src/modules/ranking/infra/database/schemas/player-ranking.schema.ts`
- Create: `services/ranking/src/modules/ranking/infra/database/schemas/ranking-processed-game.schema.ts`

- [ ] **Step 1: Criar player-ranking.schema.ts**

```typescript
import { pgTable, bigserial, text, integer, timestamp, unique } from 'drizzle-orm/pg-core';

export const playerRankings = pgTable(
  'player_rankings',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    sport: text('sport').notNull(),
    gamesPlayed: integer('games_played').notNull().default(0),
    wins: integer('wins').notNull().default(0),
    losses: integer('losses').notNull().default(0),
    draws: integer('draws').notNull().default(0),
    goals: integer('goals').notNull().default(0),
    assists: integer('assists').notNull().default(0),
    /** wins×3 + draws×1 */
    points: integer('points').notNull().default(0),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    unique('player_rankings_player_sport_unique').on(table.playerUserId, table.sport),
  ],
);

export type PlayerRankingRow = typeof playerRankings.$inferSelect;
```

- [ ] **Step 2: Criar ranking-processed-game.schema.ts**

```typescript
import { pgTable, bigserial, text, timestamp } from 'drizzle-orm/pg-core';

export const rankingProcessedGames = pgTable('ranking_processed_games', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  gameId: text('game_id').notNull().unique(),
  processedAt: timestamp('processed_at', { withTimezone: true }).defaultNow().notNull(),
});
```

- [ ] **Step 3: Commit**

```bash
git add services/ranking/src/modules/ranking/infra/database/schemas/
git commit -m "feat(ranking): add Drizzle schemas for player_rankings and ranking_processed_games"
```

---

### Task 8: Repository interface

**Files:**
- Create: `services/ranking/src/modules/ranking/domain/repositories/ranking-repository.interface.ts`

- [ ] **Step 1: Criar ranking-repository.interface.ts**

```typescript
import type { PlayerRanking } from '../models/player-ranking.entity';

export const RANKING_REPOSITORY = 'RANKING_REPOSITORY';

export interface UpsertRankingData {
  playerUserId: string;
  sport: string;
  goals: number;
  assists: number;
  isWin: boolean;
  isDraw: boolean;
}

export interface RankingRepositoryInterface {
  /**
   * Tenta inserir o gameId na tabela de controle.
   * Retorna true se inserido (novo), false se já existia (já processado).
   */
  insertProcessedGameIfNew(gameId: string): Promise<boolean>;
  /**
   * Upsert atômico: cria o ranking se não existir, ou incrementa
   * games_played/wins/losses/draws/goals/assists/points se já existir.
   */
  upsertRanking(data: UpsertRankingData): Promise<PlayerRanking>;
  findByPlayerAndSport(playerUserId: string, sport: string): Promise<PlayerRanking | null>;
  /** Retorna os top `limit` jogadores do sport, ordenados por points DESC, wins DESC. */
  getLeaderboard(sport: string, limit: number): Promise<PlayerRanking[]>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/src/modules/ranking/domain/repositories/ranking-repository.interface.ts
git commit -m "feat(ranking): add RankingRepositoryInterface"
```

---

### Task 9: `DrizzleRankingRepository`

**Files:**
- Create: `services/ranking/src/modules/ranking/infra/database/repositories/drizzle-ranking.repository.ts`

- [ ] **Step 1: Criar drizzle-ranking.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { and, desc, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  RankingRepositoryInterface,
  UpsertRankingData,
} from '../../../domain/repositories/ranking-repository.interface';
import type { PlayerRanking } from '../../../domain/models/player-ranking.entity';
import { playerRankings, type PlayerRankingRow } from '../schemas/player-ranking.schema';
import { rankingProcessedGames } from '../schemas/ranking-processed-game.schema';

@Injectable()
export class DrizzleRankingRepository implements RankingRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async insertProcessedGameIfNew(gameId: string): Promise<boolean> {
    const result = await this.drizzle.db
      .insert(rankingProcessedGames)
      .values({ gameId })
      .onConflictDoNothing()
      .returning();
    return result.length > 0;
  }

  async upsertRanking(data: UpsertRankingData): Promise<PlayerRanking> {
    const wins = data.isWin ? 1 : 0;
    const losses = !data.isWin && !data.isDraw ? 1 : 0;
    const draws = data.isDraw ? 1 : 0;
    const points = data.isWin ? 3 : data.isDraw ? 1 : 0;

    const [row] = await this.drizzle.db
      .insert(playerRankings)
      .values({
        playerUserId: data.playerUserId,
        sport: data.sport,
        gamesPlayed: 1,
        wins,
        losses,
        draws,
        goals: data.goals,
        assists: data.assists,
        points,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [playerRankings.playerUserId, playerRankings.sport],
        set: {
          gamesPlayed: sql`${playerRankings.gamesPlayed} + 1`,
          wins: sql`${playerRankings.wins} + ${wins}`,
          losses: sql`${playerRankings.losses} + ${losses}`,
          draws: sql`${playerRankings.draws} + ${draws}`,
          goals: sql`${playerRankings.goals} + ${data.goals}`,
          assists: sql`${playerRankings.assists} + ${data.assists}`,
          points: sql`${playerRankings.points} + ${points}`,
          updatedAt: new Date(),
        },
      })
      .returning();
    return this.toEntity(row);
  }

  async findByPlayerAndSport(playerUserId: string, sport: string): Promise<PlayerRanking | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerRankings)
      .where(and(eq(playerRankings.playerUserId, playerUserId), eq(playerRankings.sport, sport)))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async getLeaderboard(sport: string, limit: number): Promise<PlayerRanking[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerRankings)
      .where(eq(playerRankings.sport, sport))
      .orderBy(desc(playerRankings.points), desc(playerRankings.wins))
      .limit(limit);
    return rows.map((r) => this.toEntity(r));
  }

  private toEntity(row: PlayerRankingRow): PlayerRanking {
    return {
      id: row.id,
      playerUserId: row.playerUserId,
      sport: row.sport,
      gamesPlayed: row.gamesPlayed,
      wins: row.wins,
      losses: row.losses,
      draws: row.draws,
      goals: row.goals,
      assists: row.assists,
      points: row.points,
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/src/modules/ranking/infra/database/repositories/drizzle-ranking.repository.ts
git commit -m "feat(ranking): add DrizzleRankingRepository"
```

---

### Task 10: DTOs

**Files:**
- Create: `services/ranking/src/modules/ranking/application/dto/ranking.dto.ts`
- Create: `services/ranking/src/modules/ranking/application/dto/leaderboard-entry.dto.ts`

- [ ] **Step 1: Criar ranking.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

export class RankingDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() gamesPlayed!: number;
  @ApiProperty() wins!: number;
  @ApiProperty() losses!: number;
  @ApiProperty() draws!: number;
  @ApiProperty() goals!: number;
  @ApiProperty() assists!: number;
  @ApiProperty() points!: number;

  static from(r: PlayerRanking): RankingDto {
    const dto = new RankingDto();
    dto.playerUserId = r.playerUserId;
    dto.sport = r.sport;
    dto.gamesPlayed = r.gamesPlayed;
    dto.wins = r.wins;
    dto.losses = r.losses;
    dto.draws = r.draws;
    dto.goals = r.goals;
    dto.assists = r.assists;
    dto.points = r.points;
    return dto;
  }
}
```

- [ ] **Step 2: Criar leaderboard-entry.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

export class LeaderboardEntryDto {
  @ApiProperty() position!: number;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() gamesPlayed!: number;
  @ApiProperty() wins!: number;
  @ApiProperty() losses!: number;
  @ApiProperty() draws!: number;
  @ApiProperty() goals!: number;
  @ApiProperty() assists!: number;
  @ApiProperty() points!: number;

  static from(r: PlayerRanking, position: number): LeaderboardEntryDto {
    const dto = new LeaderboardEntryDto();
    dto.position = position;
    dto.playerUserId = r.playerUserId;
    dto.sport = r.sport;
    dto.gamesPlayed = r.gamesPlayed;
    dto.wins = r.wins;
    dto.losses = r.losses;
    dto.draws = r.draws;
    dto.goals = r.goals;
    dto.assists = r.assists;
    dto.points = r.points;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/ranking/src/modules/ranking/application/dto/
git commit -m "feat(ranking): add DTOs"
```

---

### Task 11: `RankingMessagingService`

**Files:**
- Create: `services/ranking/src/modules/ranking/application/services/ranking-messaging.service.ts`

- [ ] **Step 1: Verificar que `RankingEvents.RECALCULATED` existe**

```bash
cat /c/bola-na-rede/bolanarede_api/shared/src/contracts/events/ranking-events.enum.ts
```

Expected: `RECALCULATED = 'ranking.recalculated'`

- [ ] **Step 2: Criar ranking-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { RankingEvents } from '@shared/contracts/events/ranking-events.enum';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

@Injectable()
export class RankingMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishRankingRecalculated(ranking: PlayerRanking): Promise<void> {
    await this.messaging.publish(RankingEvents.RECALCULATED, {
      playerUserId: ranking.playerUserId,
      sport: ranking.sport,
      points: ranking.points,
      wins: ranking.wins,
      losses: ranking.losses,
      draws: ranking.draws,
      gamesPlayed: ranking.gamesPlayed,
    });
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/ranking/src/modules/ranking/application/services/ranking-messaging.service.ts
git commit -m "feat(ranking): add RankingMessagingService"
```

---

### Task 12: `RankingService` (TDD — 6 testes)

**Files:**
- Create: `services/ranking/src/modules/ranking/application/services/ranking.service.spec.ts`
- Create: `services/ranking/src/modules/ranking/application/services/ranking.service.ts`

- [ ] **Step 1: Escrever spec primeiro**

```typescript
// ranking.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { RankingService } from './ranking.service';
import { RANKING_REPOSITORY } from '../../domain/repositories/ranking-repository.interface';
import { RankingMessagingService } from './ranking-messaging.service';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

const makeRanking = (overrides: Partial<PlayerRanking> = {}): PlayerRanking => ({
  id: 1,
  playerUserId: 'user-a',
  sport: 'futsal',
  gamesPlayed: 1,
  wins: 1,
  losses: 0,
  draws: 0,
  goals: 2,
  assists: 1,
  points: 3,
  updatedAt: new Date(),
  ...overrides,
});

const matchPayload = {
  gameId: 'game-1',
  matchId: 'match-1',
  sport: 'futsal',
  winnerId: 'user-a' as string | null,
  players: [
    { playerUserId: 'user-a', goals: 2, assists: 1, won: true },
    { playerUserId: 'user-b', goals: 0, assists: 0, won: false },
  ],
};

describe('RankingService', () => {
  let service: RankingService;
  let rankingRepo: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    rankingRepo = {
      insertProcessedGameIfNew: jest.fn(),
      upsertRanking: jest.fn(),
      findByPlayerAndSport: jest.fn(),
      getLeaderboard: jest.fn(),
    };
    messaging = {
      publishRankingRecalculated: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RankingService,
        { provide: RANKING_REPOSITORY, useValue: rankingRepo },
        { provide: RankingMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<RankingService>(RankingService);
  });

  describe('processMatchCompleted', () => {
    it('skips processing if game already processed (idempotent)', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(false);

      await service.processMatchCompleted(matchPayload);

      expect(rankingRepo.upsertRanking).not.toHaveBeenCalled();
      expect(messaging.publishRankingRecalculated).not.toHaveBeenCalled();
    });

    it('awards 3 points to winner and 0 to loser', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      await service.processMatchCompleted(matchPayload);

      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-a', isWin: true, isDraw: false }),
      );
      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-b', isWin: false, isDraw: false }),
      );
    });

    it('awards 1 point to both players on draw', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      const drawPayload = {
        ...matchPayload,
        winnerId: null,
        players: [
          { playerUserId: 'user-a', goals: 1, assists: 0, won: false },
          { playerUserId: 'user-b', goals: 1, assists: 0, won: false },
        ],
      };

      await service.processMatchCompleted(drawPayload);

      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-a', isWin: false, isDraw: true }),
      );
      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-b', isWin: false, isDraw: true }),
      );
    });

    it('publishes ranking-recalculated for each player after upsert', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      await service.processMatchCompleted(matchPayload);

      expect(messaging.publishRankingRecalculated).toHaveBeenCalledTimes(2);
    });

    it('does not throw if messaging publish fails', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockRejectedValue(new Error('RabbitMQ down'));

      await expect(service.processMatchCompleted(matchPayload)).resolves.not.toThrow();
    });
  });

  describe('getLeaderboard', () => {
    it('returns leaderboard entries with 1-based positions', async () => {
      rankingRepo.getLeaderboard.mockResolvedValue([
        makeRanking({ playerUserId: 'user-a', points: 9 }),
        makeRanking({ playerUserId: 'user-b', points: 3 }),
      ]);

      const result = await service.getLeaderboard('futsal', 10);

      expect(result[0].position).toBe(1);
      expect(result[0].playerUserId).toBe('user-a');
      expect(result[1].position).toBe(2);
      expect(result[1].playerUserId).toBe('user-b');
    });
  });
});
```

- [ ] **Step 2: Rodar testes para confirmar FAIL**

```bash
cd services/ranking && npm test -- --testPathPattern="ranking.service.spec" 2>&1 | tail -10
```

Expected: FAIL com `Cannot find module './ranking.service'`.

- [ ] **Step 3: Implementar ranking.service.ts**

```typescript
import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  RANKING_REPOSITORY,
  RankingRepositoryInterface,
} from '../../domain/repositories/ranking-repository.interface';
import { RankingMessagingService } from './ranking-messaging.service';
import { RankingDto } from '../dto/ranking.dto';
import { LeaderboardEntryDto } from '../dto/leaderboard-entry.dto';

interface MatchCompletedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{
    playerUserId: string;
    goals: number;
    assists: number;
    won: boolean;
  }>;
}

@Injectable()
export class RankingService {
  private readonly logger = new Logger(RankingService.name);

  constructor(
    @Inject(RANKING_REPOSITORY)
    private readonly rankingRepo: RankingRepositoryInterface,
    private readonly messaging: RankingMessagingService,
  ) {}

  async processMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    const isNew = await this.rankingRepo.insertProcessedGameIfNew(payload.gameId);
    if (!isNew) {
      this.logger.debug(`Game ${payload.gameId} already processed by ranking, skipping`);
      return;
    }

    for (const player of payload.players) {
      const isWin = payload.winnerId === player.playerUserId;
      const isDraw = payload.winnerId === null;

      const ranking = await this.rankingRepo.upsertRanking({
        playerUserId: player.playerUserId,
        sport: payload.sport,
        goals: player.goals,
        assists: player.assists,
        isWin,
        isDraw,
      });

      try {
        await this.messaging.publishRankingRecalculated(ranking);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(
          `Failed to publish ranking-recalculated for ${player.playerUserId}: ${message}`,
        );
      }
    }
  }

  async getLeaderboard(sport: string, limit: number): Promise<LeaderboardEntryDto[]> {
    const rankings = await this.rankingRepo.getLeaderboard(sport, limit);
    return rankings.map((r, i) => LeaderboardEntryDto.from(r, i + 1));
  }

  async getPlayerRanking(userId: string, sport: string): Promise<RankingDto> {
    const ranking = await this.rankingRepo.findByPlayerAndSport(userId, sport);
    if (!ranking) {
      throw new NotFoundException(`No ranking found for player ${userId} in sport ${sport}`);
    }
    return RankingDto.from(ranking);
  }
}
```

- [ ] **Step 4: Rodar testes para confirmar PASS**

```bash
cd services/ranking && npm test -- --testPathPattern="ranking.service.spec" 2>&1 | tail -15
```

Expected: 6/6 tests passando.

- [ ] **Step 5: Commit**

```bash
git add services/ranking/src/modules/ranking/application/services/ranking.service.spec.ts
git add services/ranking/src/modules/ranking/application/services/ranking.service.ts
git commit -m "feat(ranking): add RankingService with TDD (6/6 tests)"
```

---

### Task 13: `GameEventsConsumer`

**Files:**
- Create: `services/ranking/src/modules/ranking/application/services/game-events.consumer.ts`

- [ ] **Step 1: Criar game-events.consumer.ts**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import { RankingService } from './ranking.service';

interface MatchCompletedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{
    playerUserId: string;
    goals: number;
    assists: number;
    won: boolean;
  }>;
}

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  constructor(private readonly rankingService: RankingService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'ranking-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    try {
      await this.rankingService.processMatchCompleted(payload);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to process match-completed for game ${payload.gameId}: ${message}`,
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/src/modules/ranking/application/services/game-events.consumer.ts
git commit -m "feat(ranking): add GameEventsConsumer"
```

---

### Task 14: `RankingsController`

**Files:**
- Create: `services/ranking/src/modules/ranking/infra/controllers/rankings.controller.ts`

- [ ] **Step 1: Criar rankings.controller.ts**

```typescript
import {
  Controller,
  Get,
  NotFoundException,
  Param,
  Query,
} from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { RankingService } from '../../application/services/ranking.service';
import { RankingDto } from '../../application/dto/ranking.dto';
import { LeaderboardEntryDto } from '../../application/dto/leaderboard-entry.dto';

@ApiTags('Rankings')
@Controller('rankings')
export class RankingsController {
  constructor(private readonly rankingService: RankingService) {}

  @Get()
  @ApiOperation({ summary: 'Get leaderboard for a sport (top N players by points)' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 10, max 100)' })
  async getLeaderboard(
    @Query('sport') sport: string,
    @Query('limit') limit?: string,
  ): Promise<LeaderboardEntryDto[]> {
    if (!sport) throw new NotFoundException('sport query parameter is required');
    const parsedLimit = Math.min(parseInt(limit ?? '10', 10) || 10, 100);
    return this.rankingService.getLeaderboard(sport, parsedLimit);
  }

  @Get(':userId')
  @ApiOperation({ summary: 'Get ranking for a specific player in a sport' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  async getPlayerRanking(
    @Param('userId') userId: string,
    @Query('sport') sport: string,
  ): Promise<RankingDto> {
    if (!sport) throw new NotFoundException('sport query parameter is required');
    return this.rankingService.getPlayerRanking(userId, sport);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/src/modules/ranking/infra/controllers/rankings.controller.ts
git commit -m "feat(ranking): add RankingsController"
```

---

### Task 15: `RankingModule`

**Files:**
- Create: `services/ranking/src/modules/ranking/ranking.module.ts`

- [ ] **Step 1: Criar ranking.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { RANKING_REPOSITORY } from './domain/repositories/ranking-repository.interface';
import { DrizzleRankingRepository } from './infra/database/repositories/drizzle-ranking.repository';
import { RankingMessagingService } from './application/services/ranking-messaging.service';
import { RankingService } from './application/services/ranking.service';
import { GameEventsConsumer } from './application/services/game-events.consumer';
import { RankingsController } from './infra/controllers/rankings.controller';

@Module({
  imports: [SharedModule],
  controllers: [RankingsController],
  providers: [
    { provide: RANKING_REPOSITORY, useClass: DrizzleRankingRepository },
    RankingMessagingService,
    RankingService,
    GameEventsConsumer,
  ],
})
export class RankingModule {}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/src/modules/ranking/ranking.module.ts
git commit -m "feat(ranking): add RankingModule"
```

---

### Task 16: `AppModule` + `main.ts` + build

**Files:**
- Create: `services/ranking/src/app.module.ts`
- Create: `services/ranking/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { RankingModule } from './modules/ranking/ranking.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    RankingModule,
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
cd services/ranking && npm run build 2>&1 | tail -20
```

Expected: 0 erros. Se houver erros de import, verificar caminhos relativos (`../../../` de `infra/database/repositories/` para `domain/`).

- [ ] **Step 4: Commit**

```bash
git add services/ranking/src/app.module.ts services/ranking/src/main.ts
git commit -m "feat(ranking): add AppModule and main.ts"
```

---

### Task 17: Migration SQL

**Files:**
- Create: `services/ranking/drizzle/0000_initial_ranking.sql`
- Create: `services/ranking/drizzle/meta/_journal.json`

- [ ] **Step 1: Criar SQL de migration**

`drizzle/0000_initial_ranking.sql`:
```sql
CREATE TABLE "player_rankings" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "sport" text NOT NULL,
  "games_played" integer DEFAULT 0 NOT NULL,
  "wins" integer DEFAULT 0 NOT NULL,
  "losses" integer DEFAULT 0 NOT NULL,
  "draws" integer DEFAULT 0 NOT NULL,
  "goals" integer DEFAULT 0 NOT NULL,
  "assists" integer DEFAULT 0 NOT NULL,
  "points" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "player_rankings_player_sport_unique" UNIQUE("player_user_id", "sport")
);

CREATE TABLE "ranking_processed_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" text NOT NULL,
  "processed_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "ranking_processed_games_game_id_unique" UNIQUE("game_id")
);

CREATE INDEX "idx_player_rankings_sport_points" ON "player_rankings" ("sport", "points" DESC);
CREATE INDEX "idx_player_rankings_player_user_id" ON "player_rankings" ("player_user_id");
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
      "when": 1749427200000,
      "tag": "0000_initial_ranking",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add services/ranking/drizzle/
git commit -m "feat(ranking): add initial Drizzle migration"
```

---

### Task 18: `Dockerfile` + `scripts/migrate.js` + `docker-entrypoint.sh`

**Files:**
- Create: `services/ranking/scripts/migrate.js`
- Create: `services/ranking/docker-entrypoint.sh`
- Create: `services/ranking/Dockerfile`

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
node /app/services/ranking/scripts/migrate.js

echo "Starting ranking service..."
exec node /app/services/ranking/dist/services/ranking/src/main
```

- [ ] **Step 3: Criar Dockerfile**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/ranking/ ./services/ranking/

WORKDIR /app/services/ranking
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/ranking

COPY --from=builder /app/services/ranking/dist ./dist
COPY --from=builder /app/services/ranking/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/ranking/drizzle ./drizzle
COPY --from=builder /app/services/ranking/scripts ./scripts
COPY --from=builder /app/services/ranking/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4009

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 4: Commit**

```bash
git add services/ranking/Dockerfile services/ranking/scripts/migrate.js services/ranking/docker-entrypoint.sh
git commit -m "feat(ranking): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 19: `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Adicionar postgres-ranking e ranking ao docker-compose.yml**

Ler o arquivo atual e adicionar após o bloco `game:` e antes de `volumes:`:

```yaml
  postgres-ranking:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_ranking
    ports:
      - "5440:5432"
    volumes:
      - postgres_ranking_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d bolanarededb_ranking"]
      interval: 5s
      timeout: 5s
      retries: 5

  ranking:
    build:
      context: .
      dockerfile: services/ranking/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4009
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-ranking:5432/bolanarededb_ranking
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4009:4009"
    depends_on:
      postgres-ranking:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

Adicionar no bloco `volumes:`:

```yaml
  postgres_ranking_data:
```

- [ ] **Step 2: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(ranking): add postgres-ranking and ranking service to docker-compose"
```

---

### Task 20: `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar _status.md**

Localizar a linha do ranking (deve estar como `⏳ TODO` ou similar) e substituir por:

```
| ranking      | ✅ DONE     | 20/20      | —                            |
```

Atualizar timestamp: `Última atualização: 2026-06-08 (ranking service DONE)`

Adicionar ao bloco de planos:
```
- `docs/plans/2026-06-08-ranking-service.md` — 20 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs(ranking): update _status.md — ranking service DONE (20/20)"
```
