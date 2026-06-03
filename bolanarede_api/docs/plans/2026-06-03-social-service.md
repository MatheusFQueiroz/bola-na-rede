# Social Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-06-02-open-game-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `social-service` (porta 4005) — serviço de avaliações entre jogadores após partidas, com cálculo de score/reputação agregado por jogador.

**Architecture:** NestJS 11 com um único módulo `social` e banco PostgreSQL dedicado. Sem Redis. Jogadores submetem avaliações (score 1-5 + comentário opcional) após partidas; o serviço recalcula o score agregado do avaliado a cada nova review e publica 2 eventos (`PLAYER_REVIEWED`, `PLAYER_SCORE_UPDATED`). Consome `identity.profile-updated` para manter snapshots de `displayName` atualizados em reviews e scores.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## Setup de Branch

**Branch:** `feature/social-service` — checkout no clone principal (sem worktree em pasta separada).

```bash
git checkout develop && git pull
git checkout -b feature/social-service
```

---

## File Map

```
services/social/
├── .env.example                                                          ← Task 1
├── drizzle.config.ts                                                     ← Task 2
├── nest-cli.json                                                         ← Task 3
├── package.json                                                          ← Task 4
├── tsconfig.json                                                         ← Task 5
├── tsconfig.build.json                                                   ← Task 5
└── src/
    ├── main.ts                                                           ← Task 19
    ├── app.module.ts                                                     ← Task 19
    └── modules/
        └── social/
            ├── social.module.ts                                          ← Task 18
            ├── domain/
            │   ├── models/
            │   │   ├── player-review.entity.ts                           ← Task 6
            │   │   └── player-score.entity.ts                            ← Task 6
            │   └── repositories/
            │       ├── review-repository.interface.ts                    ← Task 8
            │       └── score-repository.interface.ts                     ← Task 8
            ├── application/
            │   ├── dto/
            │   │   ├── create-review.dto.ts                              ← Task 11
            │   │   ├── list-reviews.dto.ts                               ← Task 11
            │   │   ├── review.dto.ts                                     ← Task 12
            │   │   └── player-score.dto.ts                               ← Task 12
            │   └── services/
            │       ├── review.service.spec.ts                            ← Task 14
            │       ├── review.service.ts                                 ← Task 14
            │       ├── social-messaging.service.ts                       ← Task 13
            │       └── identity-events.consumer.ts                       ← Task 15
            └── infra/
                ├── controllers/
                │   ├── reviews.controller.ts                             ← Task 16
                │   └── scores.controller.ts                              ← Task 17
                └── database/
                    ├── schemas/
                    │   ├── player-review.schema.ts                       ← Task 7
                    │   └── player-score.schema.ts                        ← Task 7
                    └── repositories/
                        ├── drizzle-review.repository.ts                  ← Task 9
                        └── drizzle-score.repository.ts                   ← Task 10

drizzle/                                                                  ← Task 20
scripts/migrate.js                                                        ← Task 21
Dockerfile                                                                ← Task 21
docker-entrypoint.sh                                                      ← Task 21
docker-compose.yml (raiz)                                                 ← Task 22
docs/plans/_status.md                                                     ← Task 23
```

---

## Contexto de Desenvolvimento

Branch: `feature/social-service` no clone principal (`/c/bola-na-rede/bolanarede_api/`).
Todos os comandos devem ser executados de dentro de `services/social/` salvo indicação contrária.

### Regras inegociáveis (reforço)
- Drizzle ORM (NUNCA TypeORM)
- Biome (NUNCA ESLint/Prettier)
- BIGSERIAL PK interno + UUID `external_id` exposto pela API
- Timestamps: sempre `timestamptz` (`withTimezone: true`)
- Fire-and-forget: chamadas de `messaging.publish*` APÓS commit no DB, dentro de `try/catch`
- Caminhos relativos em `infra/database/repositories/` para `domain/`: precisam de `../../../` (3 níveis) para chegar em `social/domain/`
- Idempotência em consumers RabbitMQ (try/catch sem rethrow)

---

### Task 1: `.env.example`

**Files:**
- Create: `services/social/.env.example`

- [ ] **Step 1: Criar `.env.example`**

```
PORT=4005
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_social
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/social/.env.example
git commit -m "chore(social): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/social/drizzle.config.ts`

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
git add services/social/drizzle.config.ts
git commit -m "chore(social): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/social/nest-cli.json`

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
git add services/social/nest-cli.json
git commit -m "chore(social): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/social/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "@bolanarede/social",
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
cd services/social && npm install --legacy-peer-deps
```

Expected: `node_modules/` criado. Se houver peer dep warning para `@golevelup/nestjs-rabbitmq`, é esperado — `--legacy-peer-deps` resolve.

- [ ] **Step 3: Commit**

```bash
git add services/social/package.json services/social/package-lock.json
git commit -m "chore(social): add package.json and install dependencies"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/social/tsconfig.json`
- Create: `services/social/tsconfig.build.json`

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
git add services/social/tsconfig.json services/social/tsconfig.build.json
git commit -m "chore(social): add tsconfig files"
```

---

### Task 6: Domain entities

**Files:**
- Create: `services/social/src/modules/social/domain/models/player-review.entity.ts`
- Create: `services/social/src/modules/social/domain/models/player-score.entity.ts`

- [ ] **Step 1: Criar player-review.entity.ts**

```typescript
export type ReviewScore = 1 | 2 | 3 | 4 | 5;
export type GameType = 'open-game' | 'game';

export class PlayerReview {
  id!: string;                    // UUID (external_id)
  gameId!: string;                // UUID do jogo (referência externa)
  gameType!: GameType;
  reviewerUserId!: string;        // UUID do avaliador
  reviewerDisplayName!: string;   // snapshot
  revieweeUserId!: string;        // UUID do avaliado
  revieweeDisplayName!: string;   // snapshot
  score!: ReviewScore;            // 1 a 5
  comment?: string;
  createdAt!: Date;
}
```

- [ ] **Step 2: Criar player-score.entity.ts**

```typescript
export class PlayerScore {
  playerUserId!: string;    // UUID do jogador
  displayName!: string;     // snapshot
  totalReviews!: number;
  averageScore!: number;    // média das reviews (0.00 a 5.00)
  updatedAt!: Date;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/social/src/modules/social/domain/models/
git commit -m "feat(social): add domain entities (PlayerReview, PlayerScore)"
```

---

### Task 7: Drizzle schemas

**Files:**
- Create: `services/social/src/modules/social/infra/database/schemas/player-review.schema.ts`
- Create: `services/social/src/modules/social/infra/database/schemas/player-score.schema.ts`

- [ ] **Step 1: Criar player-review.schema.ts**

```typescript
import {
  pgTable,
  bigserial,
  uuid,
  text,
  smallint,
  timestamp,
  unique,
} from 'drizzle-orm/pg-core';

export const playerReviews = pgTable(
  'player_reviews',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    externalId: uuid('external_id').defaultRandom().notNull().unique(),
    gameId: text('game_id').notNull(),
    gameType: text('game_type').notNull(),
    reviewerUserId: text('reviewer_user_id').notNull(),
    reviewerDisplayName: text('reviewer_display_name').notNull(),
    revieweeUserId: text('reviewee_user_id').notNull(),
    revieweeDisplayName: text('reviewee_display_name').notNull(),
    score: smallint('score').notNull(),
    comment: text('comment'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    unique('uq_review_reviewer_game').on(t.reviewerUserId, t.gameId),
  ],
);

export type PlayerReviewRow = typeof playerReviews.$inferSelect;
export type NewPlayerReviewRow = typeof playerReviews.$inferInsert;
```

- [ ] **Step 2: Criar player-score.schema.ts**

```typescript
import {
  pgTable,
  bigserial,
  text,
  integer,
  numeric,
  timestamp,
} from 'drizzle-orm/pg-core';

export const playerScores = pgTable('player_scores', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  playerUserId: text('player_user_id').notNull().unique(),
  displayName: text('display_name').notNull(),
  totalReviews: integer('total_reviews').notNull().default(0),
  averageScore: numeric('average_score', { precision: 3, scale: 2 }).notNull().default('0.00'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PlayerScoreRow = typeof playerScores.$inferSelect;
export type NewPlayerScoreRow = typeof playerScores.$inferInsert;
```

- [ ] **Step 3: Commit**

```bash
git add services/social/src/modules/social/infra/database/schemas/
git commit -m "feat(social): add Drizzle schemas (player_reviews, player_scores)"
```

---

### Task 8: Repository interfaces

**Files:**
- Create: `services/social/src/modules/social/domain/repositories/review-repository.interface.ts`
- Create: `services/social/src/modules/social/domain/repositories/score-repository.interface.ts`

- [ ] **Step 1: Criar review-repository.interface.ts**

```typescript
import type { PlayerReview } from '../models/player-review.entity';

export const REVIEW_REPOSITORY = 'REVIEW_REPOSITORY';

export interface CreateReviewData {
  gameId: string;
  gameType: string;
  reviewerUserId: string;
  reviewerDisplayName: string;
  revieweeUserId: string;
  revieweeDisplayName: string;
  score: number;
  comment?: string;
}

export interface ListReviewsFilter {
  revieweeUserId?: string;
  reviewerUserId?: string;
  gameId?: string;
}

export interface ReviewRepositoryInterface {
  create(data: CreateReviewData): Promise<PlayerReview>;
  findById(externalId: string): Promise<PlayerReview | null>;
  findAll(filter: ListReviewsFilter): Promise<PlayerReview[]>;
  existsForGame(reviewerUserId: string, gameId: string): Promise<boolean>;
  updateDisplayNames(userId: string, displayName: string): Promise<void>;
}
```

- [ ] **Step 2: Criar score-repository.interface.ts**

```typescript
import type { PlayerScore } from '../models/player-score.entity';

export const SCORE_REPOSITORY = 'SCORE_REPOSITORY';

export interface ScoreRepositoryInterface {
  findByPlayer(playerUserId: string): Promise<PlayerScore | null>;
  recalculate(playerUserId: string, displayName: string): Promise<PlayerScore>;
  updateDisplayName(playerUserId: string, displayName: string): Promise<void>;
}
```

**Notas sobre `recalculate`:** a implementação `DrizzleScoreRepository.recalculate()` faz um `SELECT COUNT(*), AVG(score)` na tabela `player_reviews` e depois um `INSERT ... ON CONFLICT DO UPDATE` em `player_scores`. Portanto o `DrizzleScoreRepository` precisa importar o schema `playerReviews` além de `playerScores`.

- [ ] **Step 3: Commit**

```bash
git add services/social/src/modules/social/domain/repositories/
git commit -m "feat(social): add repository interfaces (REVIEW_REPOSITORY, SCORE_REPOSITORY)"
```

---

### Task 9: `DrizzleReviewRepository`

**Files:**
- Create: `services/social/src/modules/social/infra/database/repositories/drizzle-review.repository.ts`

- [ ] **Step 1: Criar drizzle-review.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { and, desc, eq } from 'drizzle-orm';
import type { SQL } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateReviewData,
  ListReviewsFilter,
  ReviewRepositoryInterface,
} from '../../../domain/repositories/review-repository.interface';
import type { PlayerReview, GameType, ReviewScore } from '../../../domain/models/player-review.entity';
import { playerReviews, type PlayerReviewRow } from '../schemas/player-review.schema';

@Injectable()
export class DrizzleReviewRepository implements ReviewRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateReviewData): Promise<PlayerReview> {
    const [row] = await this.drizzle.db
      .insert(playerReviews)
      .values({
        gameId: data.gameId,
        gameType: data.gameType,
        reviewerUserId: data.reviewerUserId,
        reviewerDisplayName: data.reviewerDisplayName,
        revieweeUserId: data.revieweeUserId,
        revieweeDisplayName: data.revieweeDisplayName,
        score: data.score,
        comment: data.comment,
      })
      .returning();
    return this.toReview(row);
  }

  async findById(externalId: string): Promise<PlayerReview | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerReviews)
      .where(eq(playerReviews.externalId, externalId))
      .limit(1);
    return row ? this.toReview(row) : null;
  }

  async findAll(filter: ListReviewsFilter): Promise<PlayerReview[]> {
    const conditions: SQL[] = [];
    if (filter.revieweeUserId) {
      conditions.push(eq(playerReviews.revieweeUserId, filter.revieweeUserId));
    }
    if (filter.reviewerUserId) {
      conditions.push(eq(playerReviews.reviewerUserId, filter.reviewerUserId));
    }
    if (filter.gameId) {
      conditions.push(eq(playerReviews.gameId, filter.gameId));
    }

    const rows = await this.drizzle.db
      .select()
      .from(playerReviews)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(playerReviews.createdAt));

    return rows.map((row) => this.toReview(row));
  }

  async existsForGame(reviewerUserId: string, gameId: string): Promise<boolean> {
    const [row] = await this.drizzle.db
      .select({ id: playerReviews.id })
      .from(playerReviews)
      .where(
        and(
          eq(playerReviews.reviewerUserId, reviewerUserId),
          eq(playerReviews.gameId, gameId),
        ),
      )
      .limit(1);
    return Boolean(row);
  }

  async updateDisplayNames(userId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerReviews)
      .set({ reviewerDisplayName: displayName })
      .where(eq(playerReviews.reviewerUserId, userId));
    await this.drizzle.db
      .update(playerReviews)
      .set({ revieweeDisplayName: displayName })
      .where(eq(playerReviews.revieweeUserId, userId));
  }

  private toReview(row: PlayerReviewRow): PlayerReview {
    return {
      id: row.externalId,
      gameId: row.gameId,
      gameType: row.gameType as GameType,
      reviewerUserId: row.reviewerUserId,
      reviewerDisplayName: row.reviewerDisplayName,
      revieweeUserId: row.revieweeUserId,
      revieweeDisplayName: row.revieweeDisplayName,
      score: row.score as ReviewScore,
      comment: row.comment ?? undefined,
      createdAt: row.createdAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/infra/database/repositories/drizzle-review.repository.ts
git commit -m "feat(social): add DrizzleReviewRepository"
```

---

### Task 10: `DrizzleScoreRepository`

**Files:**
- Create: `services/social/src/modules/social/infra/database/repositories/drizzle-score.repository.ts`

- [ ] **Step 1: Criar drizzle-score.repository.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { avg, count, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  ScoreRepositoryInterface,
} from '../../../domain/repositories/score-repository.interface';
import type { PlayerScore } from '../../../domain/models/player-score.entity';
import { playerScores, type PlayerScoreRow } from '../schemas/player-score.schema';
import { playerReviews } from '../schemas/player-review.schema';

@Injectable()
export class DrizzleScoreRepository implements ScoreRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async findByPlayer(playerUserId: string): Promise<PlayerScore | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerScores)
      .where(eq(playerScores.playerUserId, playerUserId))
      .limit(1);
    return row ? this.toScore(row) : null;
  }

  async recalculate(playerUserId: string, displayName: string): Promise<PlayerScore> {
    const [agg] = await this.drizzle.db
      .select({
        total: count(playerReviews.id),
        average: avg(playerReviews.score),
      })
      .from(playerReviews)
      .where(eq(playerReviews.revieweeUserId, playerUserId));

    const totalReviews = agg?.total ?? 0;
    const averageScore = agg?.average ? Number(agg.average).toFixed(2) : '0.00';

    const [row] = await this.drizzle.db
      .insert(playerScores)
      .values({ playerUserId, displayName, totalReviews, averageScore })
      .onConflictDoUpdate({
        target: playerScores.playerUserId,
        set: {
          totalReviews,
          averageScore: sql`excluded.average_score`,
          displayName,
          updatedAt: sql`now()`,
        },
      })
      .returning();

    return this.toScore(row);
  }

  async updateDisplayName(playerUserId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerScores)
      .set({ displayName })
      .where(eq(playerScores.playerUserId, playerUserId));
  }

  private toScore(row: PlayerScoreRow): PlayerScore {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      totalReviews: row.totalReviews,
      averageScore: parseFloat(row.averageScore),
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/infra/database/repositories/drizzle-score.repository.ts
git commit -m "feat(social): add DrizzleScoreRepository"
```

---

### Task 11: Input DTOs

**Files:**
- Create: `services/social/src/modules/social/application/dto/create-review.dto.ts`
- Create: `services/social/src/modules/social/application/dto/list-reviews.dto.ts`

- [ ] **Step 1: Criar create-review.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateReviewDto {
  @IsUUID()
  @ApiProperty({ description: 'UUID do jogo (open-game ou game)' })
  gameId!: string;

  @IsIn(['open-game', 'game'])
  @ApiProperty({ enum: ['open-game', 'game'], description: 'Tipo do jogo' })
  gameType!: string;

  @IsUUID()
  @ApiProperty({ description: 'UUID do jogador avaliado' })
  revieweeUserId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  @ApiProperty({ minimum: 1, maximum: 5, description: 'Nota de 1 a 5' })
  score!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  @ApiPropertyOptional({ maxLength: 500 })
  comment?: string;
}
```

- [ ] **Step 2: Criar list-reviews.dto.ts**

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUUID } from 'class-validator';

export class ListReviewsDto {
  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do jogador avaliado' })
  revieweeUserId?: string;

  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do avaliador' })
  reviewerUserId?: string;

  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do jogo' })
  gameId?: string;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/social/src/modules/social/application/dto/create-review.dto.ts \
        services/social/src/modules/social/application/dto/list-reviews.dto.ts
git commit -m "feat(social): add input DTOs (CreateReviewDto, ListReviewsDto)"
```

---

### Task 12: Output DTOs

**Files:**
- Create: `services/social/src/modules/social/application/dto/review.dto.ts`
- Create: `services/social/src/modules/social/application/dto/player-score.dto.ts`

- [ ] **Step 1: Criar review.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { PlayerReview } from '../../domain/models/player-review.entity';

export class ReviewDto {
  @ApiProperty() id!: string;
  @ApiProperty() gameId!: string;
  @ApiProperty() gameType!: string;
  @ApiProperty() reviewerUserId!: string;
  @ApiProperty() reviewerDisplayName!: string;
  @ApiProperty() revieweeUserId!: string;
  @ApiProperty() revieweeDisplayName!: string;
  @ApiProperty() score!: number;
  @ApiPropertyOptional() comment?: string;
  @ApiProperty() createdAt!: Date;

  static fromReview(review: PlayerReview): ReviewDto {
    const dto = new ReviewDto();
    dto.id = review.id;
    dto.gameId = review.gameId;
    dto.gameType = review.gameType;
    dto.reviewerUserId = review.reviewerUserId;
    dto.reviewerDisplayName = review.reviewerDisplayName;
    dto.revieweeUserId = review.revieweeUserId;
    dto.revieweeDisplayName = review.revieweeDisplayName;
    dto.score = review.score;
    dto.comment = review.comment;
    dto.createdAt = review.createdAt;
    return dto;
  }
}
```

- [ ] **Step 2: Criar player-score.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { PlayerScore } from '../../domain/models/player-score.entity';

export class PlayerScoreDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalReviews!: number;
  @ApiProperty() averageScore!: number;
  @ApiProperty() updatedAt!: Date;

  static fromScore(score: PlayerScore): PlayerScoreDto {
    const dto = new PlayerScoreDto();
    dto.playerUserId = score.playerUserId;
    dto.displayName = score.displayName;
    dto.totalReviews = score.totalReviews;
    dto.averageScore = score.averageScore;
    dto.updatedAt = score.updatedAt;
    return dto;
  }

  static empty(playerUserId: string): PlayerScoreDto {
    const dto = new PlayerScoreDto();
    dto.playerUserId = playerUserId;
    dto.displayName = '';
    dto.totalReviews = 0;
    dto.averageScore = 0;
    dto.updatedAt = new Date(0);
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/social/src/modules/social/application/dto/review.dto.ts \
        services/social/src/modules/social/application/dto/player-score.dto.ts
git commit -m "feat(social): add output DTOs (ReviewDto, PlayerScoreDto)"
```

---

### Task 13: `SocialMessagingService`

**Files:**
- Create: `services/social/src/modules/social/application/services/social-messaging.service.ts`

- [ ] **Step 1: Criar social-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { SocialEvents } from '@shared/contracts/events/social-events.enum';
import type { PlayerReview } from '../../domain/models/player-review.entity';
import type { PlayerScore } from '../../domain/models/player-score.entity';

@Injectable()
export class SocialMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishPlayerReviewed(review: PlayerReview): Promise<void> {
    await this.messaging.publish(SocialEvents.PLAYER_REVIEWED, {
      reviewId: review.id,
      gameId: review.gameId,
      gameType: review.gameType,
      reviewerUserId: review.reviewerUserId,
      revieweeUserId: review.revieweeUserId,
      score: review.score,
    });
  }

  async publishScoreUpdated(score: PlayerScore): Promise<void> {
    await this.messaging.publish(SocialEvents.PLAYER_SCORE_UPDATED, {
      playerUserId: score.playerUserId,
      averageScore: score.averageScore,
      totalReviews: score.totalReviews,
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/application/services/social-messaging.service.ts
git commit -m "feat(social): add SocialMessagingService"
```

---

### Task 14: `ReviewService` (TDD)

**Files:**
- Create: `services/social/src/modules/social/application/services/review.service.spec.ts`
- Create: `services/social/src/modules/social/application/services/review.service.ts`

- [ ] **Step 1: Escrever os testes antes da implementação**

Crie `review.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { ReviewService } from './review.service';
import { REVIEW_REPOSITORY } from '../../domain/repositories/review-repository.interface';
import { SCORE_REPOSITORY } from '../../domain/repositories/score-repository.interface';
import { SocialMessagingService } from './social-messaging.service';
import type { PlayerReview } from '../../domain/models/player-review.entity';
import type { PlayerScore } from '../../domain/models/player-score.entity';
import type { CreateReviewDto } from '../dto/create-review.dto';

const mockReview: PlayerReview = {
  id: 'review-uuid-1',
  gameId: 'game-uuid-1',
  gameType: 'open-game',
  reviewerUserId: 'user-a',
  reviewerDisplayName: 'Player A',
  revieweeUserId: 'user-b',
  revieweeDisplayName: 'Player B',
  score: 4,
  createdAt: new Date('2026-01-01'),
};

const mockScore: PlayerScore = {
  playerUserId: 'user-b',
  displayName: 'Player B',
  totalReviews: 1,
  averageScore: 4.0,
  updatedAt: new Date('2026-01-01'),
};

describe('ReviewService', () => {
  let service: ReviewService;
  let mockReviewRepo: jest.Mocked<any>;
  let mockScoreRepo: jest.Mocked<any>;
  let mockMessaging: jest.Mocked<any>;

  beforeEach(async () => {
    mockReviewRepo = {
      create: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      existsForGame: jest.fn(),
      updateDisplayNames: jest.fn(),
    };

    mockScoreRepo = {
      findByPlayer: jest.fn(),
      recalculate: jest.fn(),
      updateDisplayName: jest.fn(),
    };

    mockMessaging = {
      publishPlayerReviewed: jest.fn().mockResolvedValue(undefined),
      publishScoreUpdated: jest.fn().mockResolvedValue(undefined),
    };

    const module = await Test.createTestingModule({
      providers: [
        ReviewService,
        { provide: REVIEW_REPOSITORY, useValue: mockReviewRepo },
        { provide: SCORE_REPOSITORY, useValue: mockScoreRepo },
        { provide: SocialMessagingService, useValue: mockMessaging },
      ],
    }).compile();

    service = module.get(ReviewService);
  });

  describe('createReview', () => {
    const dto: CreateReviewDto = {
      gameId: 'game-uuid-1',
      gameType: 'open-game',
      revieweeUserId: 'user-b',
      score: 4,
    };

    it('cria review, recalcula score e publica eventos', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(false);
      mockScoreRepo.findByPlayer.mockResolvedValue(mockScore);
      mockReviewRepo.create.mockResolvedValue(mockReview);
      mockScoreRepo.recalculate.mockResolvedValue(mockScore);

      const result = await service.createReview('user-a', 'Player A', dto);

      expect(mockReviewRepo.existsForGame).toHaveBeenCalledWith('user-a', 'game-uuid-1');
      expect(mockReviewRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUserId: 'user-a',
          reviewerDisplayName: 'Player A',
          revieweeUserId: 'user-b',
          score: 4,
          gameId: 'game-uuid-1',
          gameType: 'open-game',
        }),
      );
      expect(mockScoreRepo.recalculate).toHaveBeenCalledWith('user-b', expect.any(String));
      expect(mockMessaging.publishPlayerReviewed).toHaveBeenCalledWith(mockReview);
      expect(mockMessaging.publishScoreUpdated).toHaveBeenCalledWith(mockScore);
      expect(result.id).toBe('review-uuid-1');
    });

    it('lança BadRequestException quando reviewer === reviewee', async () => {
      await expect(
        service.createReview('user-b', 'Player B', { ...dto, revieweeUserId: 'user-b' }),
      ).rejects.toThrow(BadRequestException);

      expect(mockReviewRepo.existsForGame).not.toHaveBeenCalled();
    });

    it('lança ConflictException quando reviewer já avaliou neste jogo', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(true);

      await expect(service.createReview('user-a', 'Player A', dto)).rejects.toThrow(
        ConflictException,
      );

      expect(mockReviewRepo.create).not.toHaveBeenCalled();
    });

    it('não propaga erro de messaging (fire-and-forget)', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(false);
      mockScoreRepo.findByPlayer.mockResolvedValue(null);
      mockReviewRepo.create.mockResolvedValue(mockReview);
      mockScoreRepo.recalculate.mockResolvedValue(mockScore);
      mockMessaging.publishPlayerReviewed.mockRejectedValue(new Error('AMQP down'));

      await expect(service.createReview('user-a', 'Player A', dto)).resolves.toBeDefined();
    });
  });

  describe('listReviews', () => {
    it('retorna lista de ReviewDtos', async () => {
      mockReviewRepo.findAll.mockResolvedValue([mockReview]);

      const result = await service.listReviews({ revieweeUserId: 'user-b' });

      expect(mockReviewRepo.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ revieweeUserId: 'user-b' }),
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('review-uuid-1');
    });
  });

  describe('getPlayerScore', () => {
    it('retorna PlayerScoreDto quando score existe', async () => {
      mockScoreRepo.findByPlayer.mockResolvedValue(mockScore);

      const result = await service.getPlayerScore('user-b');

      expect(result.playerUserId).toBe('user-b');
      expect(result.totalReviews).toBe(1);
      expect(result.averageScore).toBe(4.0);
    });

    it('retorna score vazio quando jogador não tem reviews', async () => {
      mockScoreRepo.findByPlayer.mockResolvedValue(null);

      const result = await service.getPlayerScore('user-c');

      expect(result.playerUserId).toBe('user-c');
      expect(result.totalReviews).toBe(0);
      expect(result.averageScore).toBe(0);
    });
  });
});
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

```bash
cd services/social && npx jest --no-coverage 2>&1 | tail -10
```

Expected: `FAIL` — `ReviewService` não existe ainda.

- [ ] **Step 3: Implementar review.service.ts**

```typescript
import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
} from '@nestjs/common';
import {
  REVIEW_REPOSITORY,
  ReviewRepositoryInterface,
} from '../../domain/repositories/review-repository.interface';
import {
  SCORE_REPOSITORY,
  ScoreRepositoryInterface,
} from '../../domain/repositories/score-repository.interface';
import { SocialMessagingService } from './social-messaging.service';
import { CreateReviewDto } from '../dto/create-review.dto';
import { ListReviewsDto } from '../dto/list-reviews.dto';
import { ReviewDto } from '../dto/review.dto';
import { PlayerScoreDto } from '../dto/player-score.dto';

@Injectable()
export class ReviewService {
  constructor(
    @Inject(REVIEW_REPOSITORY)
    private readonly reviewRepo: ReviewRepositoryInterface,
    @Inject(SCORE_REPOSITORY)
    private readonly scoreRepo: ScoreRepositoryInterface,
    private readonly messaging: SocialMessagingService,
  ) {}

  async createReview(
    reviewerUserId: string,
    reviewerDisplayName: string,
    dto: CreateReviewDto,
  ): Promise<ReviewDto> {
    if (reviewerUserId === dto.revieweeUserId) {
      throw new BadRequestException('Cannot review yourself');
    }

    const alreadyReviewed = await this.reviewRepo.existsForGame(reviewerUserId, dto.gameId);
    if (alreadyReviewed) {
      throw new ConflictException('Already reviewed a player in this game');
    }

    const existingScore = await this.scoreRepo.findByPlayer(dto.revieweeUserId);
    const revieweeDisplayName = existingScore?.displayName ?? '';

    const review = await this.reviewRepo.create({
      gameId: dto.gameId,
      gameType: dto.gameType,
      reviewerUserId,
      reviewerDisplayName,
      revieweeUserId: dto.revieweeUserId,
      revieweeDisplayName,
      score: dto.score,
      comment: dto.comment,
    });

    const score = await this.scoreRepo.recalculate(dto.revieweeUserId, revieweeDisplayName);

    try {
      await this.messaging.publishPlayerReviewed(review);
      await this.messaging.publishScoreUpdated(score);
    } catch {
      // fire-and-forget — advisory
    }

    return ReviewDto.fromReview(review);
  }

  async listReviews(query: ListReviewsDto): Promise<ReviewDto[]> {
    const reviews = await this.reviewRepo.findAll({
      revieweeUserId: query.revieweeUserId,
      reviewerUserId: query.reviewerUserId,
      gameId: query.gameId,
    });
    return reviews.map((r) => ReviewDto.fromReview(r));
  }

  async getPlayerScore(playerUserId: string): Promise<PlayerScoreDto> {
    const score = await this.scoreRepo.findByPlayer(playerUserId);
    return score ? PlayerScoreDto.fromScore(score) : PlayerScoreDto.empty(playerUserId);
  }
}
```

- [ ] **Step 4: Rodar os testes e confirmar que passam**

```bash
cd services/social && npx jest --no-coverage 2>&1 | tail -10
```

Expected: `Tests: 6 passed, 6 total`

- [ ] **Step 5: Commit**

```bash
git add services/social/src/modules/social/application/services/review.service.spec.ts \
        services/social/src/modules/social/application/services/review.service.ts
git commit -m "feat(social): add ReviewService with 6 tests passing"
```

---

### Task 15: `IdentityEventsConsumer`

**Files:**
- Create: `services/social/src/modules/social/application/services/identity-events.consumer.ts`

- [ ] **Step 1: Criar identity-events.consumer.ts**

```typescript
import { Inject, Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  REVIEW_REPOSITORY,
  ReviewRepositoryInterface,
} from '../../domain/repositories/review-repository.interface';
import {
  SCORE_REPOSITORY,
  ScoreRepositoryInterface,
} from '../../domain/repositories/score-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(REVIEW_REPOSITORY)
    private readonly reviewRepo: ReviewRepositoryInterface,
    @Inject(SCORE_REPOSITORY)
    private readonly scoreRepo: ScoreRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'social-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.reviewRepo.updateDisplayNames(payload.userId, payload.displayName);
      await this.scoreRepo.updateDisplayName(payload.userId, payload.displayName);
      this.logger.debug(`Updated display names for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update display names for user ${payload.userId}: ${message}`,
      );
      // Don't rethrow — idempotent; snapshot corrected on next profile update
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/application/services/identity-events.consumer.ts
git commit -m "feat(social): add IdentityEventsConsumer for display name snapshot updates"
```

---

### Task 16: `ReviewsController`

**Files:**
- Create: `services/social/src/modules/social/infra/controllers/reviews.controller.ts`

- [ ] **Step 1: Criar reviews.controller.ts**

```typescript
import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { ReviewService } from '../../application/services/review.service';
import { CreateReviewDto } from '../../application/dto/create-review.dto';
import { ListReviewsDto } from '../../application/dto/list-reviews.dto';
import { ReviewDto } from '../../application/dto/review.dto';

@ApiTags('reviews')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly service: ReviewService) {}

  @Post()
  @Permissions('social:write')
  @HateoasItem(ReviewDto)
  @ApiOperation({ summary: 'Submeter avaliação de jogador após partida' })
  create(
    @Body() dto: CreateReviewDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReviewDto> {
    return this.service.createReview(user.id, user.name, dto);
  }

  @Get()
  @Public()
  @HateoasList(ReviewDto)
  @ApiOperation({ summary: 'Listar avaliações (filtrável por reviewee, reviewer ou jogo)' })
  list(@Query() query: ListReviewsDto): Promise<ReviewDto[]> {
    return this.service.listReviews(query);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/infra/controllers/reviews.controller.ts
git commit -m "feat(social): add ReviewsController (2 endpoints)"
```

---

### Task 17: `ScoresController`

**Files:**
- Create: `services/social/src/modules/social/infra/controllers/scores.controller.ts`

- [ ] **Step 1: Criar scores.controller.ts**

```typescript
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem } from '@shared/infra/hateoas';
import { ReviewService } from '../../application/services/review.service';
import { PlayerScoreDto } from '../../application/dto/player-score.dto';

@ApiTags('scores')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('scores')
export class ScoresController {
  constructor(private readonly service: ReviewService) {}

  @Get('players/:userId')
  @Public()
  @HateoasItem(PlayerScoreDto)
  @ApiOperation({ summary: 'Obter score/reputação de um jogador' })
  getPlayerScore(@Param('userId') userId: string): Promise<PlayerScoreDto> {
    return this.service.getPlayerScore(userId);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/infra/controllers/scores.controller.ts
git commit -m "feat(social): add ScoresController (1 endpoint)"
```

---

### Task 18: NestJS modules

**Files:**
- Create: `services/social/src/modules/social/social.module.ts`

- [ ] **Step 1: Criar social.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { REVIEW_REPOSITORY } from './domain/repositories/review-repository.interface';
import { SCORE_REPOSITORY } from './domain/repositories/score-repository.interface';
import { DrizzleReviewRepository } from './infra/database/repositories/drizzle-review.repository';
import { DrizzleScoreRepository } from './infra/database/repositories/drizzle-score.repository';
import { ReviewService } from './application/services/review.service';
import { SocialMessagingService } from './application/services/social-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { ReviewsController } from './infra/controllers/reviews.controller';
import { ScoresController } from './infra/controllers/scores.controller';

@Module({
  imports: [SharedModule],
  controllers: [ReviewsController, ScoresController],
  providers: [
    { provide: REVIEW_REPOSITORY, useClass: DrizzleReviewRepository },
    { provide: SCORE_REPOSITORY, useClass: DrizzleScoreRepository },
    ReviewService,
    SocialMessagingService,
    IdentityEventsConsumer,
  ],
})
export class SocialModule {}
```

- [ ] **Step 2: Commit**

```bash
git add services/social/src/modules/social/social.module.ts
git commit -m "feat(social): add SocialModule"
```

---

### Task 19: `main.ts` + `app.module.ts`

**Files:**
- Create: `services/social/src/app.module.ts`
- Create: `services/social/src/main.ts`

- [ ] **Step 1: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SocialModule } from './modules/social/social.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SocialModule,
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
cd services/social && npm run build 2>&1 | tail -20
```

Expected: saída sem linhas de `error TS`. Se houver erros de caminho relativo (ex: `Cannot find module '../../domain/...'`), corrija os paths — de dentro de `infra/database/repositories/` são necessários `../../../domain/...` (3 níveis acima).

- [ ] **Step 4: Executar todos os testes**

```bash
cd services/social && npx jest --no-coverage 2>&1 | tail -10
```

Expected: `Tests: 6 passed, 6 total`

- [ ] **Step 5: Commit**

```bash
git add services/social/src/app.module.ts services/social/src/main.ts
git commit -m "feat(social): add app.module and main bootstrap"
```

---

### Task 20: Drizzle migration

**Files:**
- Create: `services/social/drizzle/0000_initial_social.sql`
- Create: `services/social/drizzle/meta/_journal.json`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p services/social/drizzle/meta
```

- [ ] **Step 2: Criar `drizzle/0000_initial_social.sql`**

```sql
CREATE TABLE IF NOT EXISTS "player_reviews" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" uuid DEFAULT gen_random_uuid() NOT NULL UNIQUE,
  "game_id" text NOT NULL,
  "game_type" text NOT NULL,
  "reviewer_user_id" text NOT NULL,
  "reviewer_display_name" text NOT NULL,
  "reviewee_user_id" text NOT NULL,
  "reviewee_display_name" text NOT NULL,
  "score" smallint NOT NULL,
  "comment" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_review_reviewer_game" UNIQUE ("reviewer_user_id", "game_id")
);

CREATE TABLE IF NOT EXISTS "player_scores" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL UNIQUE,
  "display_name" text NOT NULL,
  "total_reviews" integer DEFAULT 0 NOT NULL,
  "average_score" numeric(3, 2) DEFAULT '0.00' NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_player_reviews_reviewee" ON "player_reviews" ("reviewee_user_id");
CREATE INDEX IF NOT EXISTS "idx_player_reviews_reviewer" ON "player_reviews" ("reviewer_user_id");
CREATE INDEX IF NOT EXISTS "idx_player_reviews_game" ON "player_reviews" ("game_id");
```

- [ ] **Step 3: Criar `drizzle/meta/_journal.json`**

```json
{
  "version": "7",
  "dialect": "postgresql",
  "entries": [
    {
      "idx": 0,
      "version": "7",
      "when": 1748908800000,
      "tag": "0000_initial_social",
      "breakpoints": true
    }
  ]
}
```

- [ ] **Step 4: Commit**

```bash
git add services/social/drizzle/
git commit -m "feat(social): add initial Drizzle migration"
```

---

### Task 21: `migrate.js`, `Dockerfile`, `docker-entrypoint.sh`

**Files:**
- Create: `services/social/scripts/migrate.js`
- Create: `services/social/Dockerfile`
- Create: `services/social/docker-entrypoint.sh`

- [ ] **Step 1: Criar `scripts/migrate.js`**

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

- [ ] **Step 2: Criar `Dockerfile`**

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/social/ ./services/social/

WORKDIR /app/services/social
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/social

COPY --from=builder /app/services/social/dist ./dist
COPY --from=builder /app/services/social/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/social/drizzle ./drizzle
COPY --from=builder /app/services/social/scripts ./scripts
COPY --from=builder /app/services/social/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4005

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 3: Criar `docker-entrypoint.sh`**

```sh
#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/social/scripts/migrate.js

echo "Starting social service..."
exec node /app/services/social/dist/services/social/src/main
```

- [ ] **Step 4: Commit**

```bash
git add services/social/scripts/ services/social/Dockerfile services/social/docker-entrypoint.sh
git commit -m "feat(social): add Dockerfile, entrypoint and migrate.js"
```

---

### Task 22: Atualizar `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml` (raiz do monorepo)

- [ ] **Step 1: Ler o arquivo atual**

```bash
cat docker-compose.yml
```

- [ ] **Step 2: Adicionar `postgres-social` no bloco de infraestrutura (após `postgres-open-game`)**

```yaml
  postgres-social:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_social
    ports:
      - "5436:5432"
    volumes:
      - postgres_social_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d bolanarededb_social"]
      interval: 5s
      timeout: 5s
      retries: 10
```

- [ ] **Step 3: Adicionar `social` no bloco de application services (após `open-game`)**

```yaml
  social:
    build:
      context: .
      dockerfile: services/social/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4005
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-social:5432/bolanarededb_social
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4005:4005"
    depends_on:
      postgres-social:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

- [ ] **Step 4: Adicionar `postgres_social_data:` no bloco `volumes:`**

```yaml
  postgres_social_data:
```

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(social): add postgres-social and social service to docker-compose"
```

---

### Task 23: Atualizar `docs/plans/_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar a tabela e adicionar entrada do plano**

```markdown
# BolaNaRede — Status de Desenvolvimento
Última atualização: 2026-06-03

| Serviço      | Status   | Concluídas | Próxima task pendente        |
|--------------|----------|------------|------------------------------|
| shared       | ✅ DONE  | 29/29      | —                            |
| identity     | ✅ DONE  | 37/37      | —                            |
| team         | ✅ DONE  | 29/29      | —                            |
| field        | ✅ DONE  | 34/34      | —                            |
| open-game    | ✅ DONE  | 29/29      | —                            |
| social       | ✅ DONE  | 23/23      | —                            |
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
- `docs/plans/2026-06-03-social-service.md` — 23 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md docs/plans/2026-06-03-social-service.md
git commit -m "docs(social): update _status.md and add social service plan"
```

---

## Notas de Implementação

### Caminhos relativos — armadilha recorrente

A estrutura é mais rasa que open-game (sem sub-módulos), mas os repositórios Drizzle ficam em `infra/database/repositories/` e os domínios em `domain/`. A distância entre eles:

```
social/
├── domain/repositories/       ← destino
└── infra/database/repositories/ ← origem
```

De `infra/database/repositories/` até `domain/`:
- `..` = `infra/database/`
- `../..` = `infra/`
- `../../..` = `social/`
- `../../../domain/` = `social/domain/` ✓

**Usar sempre `../../../domain/...` (3 níveis), não `../../domain/...`.**

### `recalculate` — sem locks necessários

O `DrizzleScoreRepository.recalculate()` usa `INSERT ... ON CONFLICT DO UPDATE` (upsert idempotente). Não há race condition grave aqui pois o `ReviewService` chama `recalculate` apenas uma vez por requisição. Se dois reviews chegarem simultaneamente, o segundo upsert sobrescreverá com o valor correto pois o `AVG()` agrega todas as reviews existentes.

### `revieweeDisplayName` no momento da criação

Quando uma review é criada, o display name do avaliado vem do snapshot `PlayerScore.displayName` (se existir) ou fica vazio. O consumer `identity.profile-updated` atualiza o snapshot retroativamente. Isso é aceitável — o nome correto aparece após o próximo evento de perfil.

### Constraint `uq_review_reviewer_game`

Um avaliador pode avaliar **apenas um jogador** por jogo (`(reviewer_user_id, game_id)` unique). Isso é intencional: limita spam e garante que a review seja feita no contexto correto da partida.
