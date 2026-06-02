# Team Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-05-26-shared-module.md` e `docs/plans/2026-05-26-identity-service.md` devem estar 100% concluídos.

**Goal:** Criar o `team-service` (porta 4002) com criação/gestão de equipes, membership com snapshots de jogadores via RabbitMQ, e captaincy transfer.

**Architecture:** NestJS 11 com um módulo de domínio (`teams`) que expõe CRUD de equipes e membership. O serviço publica eventos via `bolanarededb` exchange e consome `identity.profile-updated` para manter snapshots de `displayName`/`position` em `team_members` — zero HTTP cross-service. Captain-only operations são validadas na camada de serviço via `ForbiddenException`.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## File Map

```
services/team/
├── .env.example                                                    ← Task 1
├── drizzle.config.ts                                               ← Task 2
├── nest-cli.json                                                   ← Task 3
├── package.json                                                    ← Task 4
├── tsconfig.json                                                   ← Task 5
├── tsconfig.build.json                                             ← Task 5
├── Dockerfile                                                      ← Task 27
├── docker-entrypoint.sh                                            ← Task 27
├── scripts/
│   └── migrate.js                                                  ← Task 27
└── src/
    ├── main.ts                                                     ← Task 6
    ├── app.module.ts                                               ← Task 7
    └── modules/
        └── team/
            ├── team.module.ts                                      ← Task 26
            └── teams/
                ├── domain/
                │   ├── models/
                │   │   ├── team.entity.ts                          ← Task 8
                │   │   └── team-member.entity.ts                   ← Task 9
                │   └── repositories/
                │       └── team-repository.interface.ts            ← Task 10
                ├── infra/
                │   ├── database/schemas/
                │   │   ├── team.schema.ts                          ← Task 11
                │   │   └── team-member.schema.ts                   ← Task 12
                │   ├── repositories/
                │   │   └── drizzle-team.repository.ts              ← Task 13
                │   └── controllers/
                │       └── teams.controller.ts                     ← Task 23
                ├── application/
                │   ├── dto/
                │   │   ├── create-team.dto.ts                      ← Task 14
                │   │   ├── update-team.dto.ts                      ← Task 15
                │   │   ├── transfer-captaincy.dto.ts               ← Task 16
                │   │   ├── team.dto.ts                             ← Task 17
                │   │   └── team-member.dto.ts                      ← Task 18
                │   └── services/
                │       ├── team.service.spec.ts                    ← Task 19
                │       ├── team.service.ts                         ← Task 20
                │       ├── team-messaging.service.ts               ← Task 21
                │       └── identity-events.consumer.ts             ← Task 22
                └── teams.module.ts                                 ← Task 24 (+ team.module.ts Task 25)
```

Tasks 27–29: Docker, docker-compose update, migration + verification.

---

### Task 1: .env.example

**File:** `services/team/.env.example`

- [ ] Criar `services/team/.env.example`:

```env
PORT=4002
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_team
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

- [ ] Commit: `git add services/team/.env.example && git commit -m "chore(team): add .env.example"`

---

### Task 2: drizzle.config.ts

**File:** `services/team/drizzle.config.ts`

- [ ] Criar `services/team/drizzle.config.ts`:

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

- [ ] Commit: `git add services/team/drizzle.config.ts && git commit -m "chore(team): add drizzle.config.ts"`

---

### Task 3: nest-cli.json

**File:** `services/team/nest-cli.json`

- [ ] Criar `services/team/nest-cli.json`:

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

- [ ] Commit: `git add services/team/nest-cli.json && git commit -m "chore(team): add nest-cli.json"`

---

### Task 4: package.json

**File:** `services/team/package.json`

- [ ] Criar `services/team/package.json`:

```json
{
  "name": "@bolanarede/team",
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
    "@golevelup/nestjs-rabbitmq": "^4.0.0",
    "@nestjs/common": "^11.0.0",
    "@nestjs/config": "^3.0.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/jwt": "^10.0.0",
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
    "testEnvironment": "node"
  }
}
```

- [ ] Instalar dependências:

```bash
cd services/team && npm install --legacy-peer-deps
```

Esperado: `node_modules/` criado sem erros.

- [ ] Commit: `git add services/team/package.json services/team/package-lock.json && git commit -m "chore(team): add package.json and install deps"`

---

### Task 5: tsconfig.json + tsconfig.build.json

**File:** `services/team/tsconfig.json`

- [ ] Criar `services/team/tsconfig.json`:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "baseUrl": "./",
    "paths": {
      "@shared/*": ["../../shared/src/*"]
    },
    "incremental": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "drizzle"]
}
```

**File:** `services/team/tsconfig.build.json`

- [ ] Criar `services/team/tsconfig.build.json`:

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
```

- [ ] Commit: `git add services/team/tsconfig.json services/team/tsconfig.build.json && git commit -m "chore(team): add tsconfig files"`

---

### Task 6: main.ts

**File:** `services/team/src/main.ts`

- [ ] Criar `services/team/src/main.ts`:

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

- [ ] Commit: `git add services/team/src/main.ts && git commit -m "feat(team): add main.ts"`

---

### Task 7: app.module.ts

**File:** `services/team/src/app.module.ts`

- [ ] Criar `services/team/src/app.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TeamModule } from './modules/team/team.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TeamModule,
  ],
})
export class AppModule {}
```

- [ ] Commit: `git add services/team/src/app.module.ts && git commit -m "feat(team): add AppModule"`

---

### Task 8: team.entity.ts

**File:** `services/team/src/modules/team/teams/domain/models/team.entity.ts`

- [ ] Criar `services/team/src/modules/team/teams/domain/models/team.entity.ts`:

```typescript
export class Team {
  id!: string;           // external_id UUID
  name!: string;
  description!: string | null;
  captainUserId!: string;   // identity UUID (cross-service, stored as text)
  minPlayers!: number;
  maxPlayers!: number;
  isActive!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/domain/models/team.entity.ts && git commit -m "feat(team): add Team entity"`

---

### Task 9: team-member.entity.ts

**File:** `services/team/src/modules/team/teams/domain/models/team-member.entity.ts`

- [ ] Criar `services/team/src/modules/team/teams/domain/models/team-member.entity.ts`:

```typescript
export class TeamMember {
  playerUserId!: string;     // identity UUID (cross-service, stored as text)
  displayName!: string;      // snapshot from identity.profile-updated events
  position!: string | null;  // snapshot from identity.profile-updated events
  role!: 'captain' | 'member';
  joinedAt!: Date;
  leftAt!: Date | null;      // null = active member
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/domain/models/team-member.entity.ts && git commit -m "feat(team): add TeamMember entity"`

---

### Task 10: team-repository.interface.ts

**File:** `services/team/src/modules/team/teams/domain/repositories/team-repository.interface.ts`

- [ ] Criar `services/team/src/modules/team/teams/domain/repositories/team-repository.interface.ts`:

```typescript
import type { Team } from '../models/team.entity';
import type { TeamMember } from '../models/team-member.entity';

export const TEAM_REPOSITORY = 'TEAM_REPOSITORY';

export interface CreateTeamData {
  name: string;
  description?: string;
  captainUserId: string;
  captainDisplayName: string;
  minPlayers: number;
  maxPlayers: number;
}

export interface TeamWithCount extends Team {
  memberCount: number;
}

export interface TeamRepositoryInterface {
  create(data: CreateTeamData): Promise<Team>;
  findById(externalId: string): Promise<Team | null>;
  findByIdWithMemberCount(externalId: string): Promise<TeamWithCount | null>;
  update(externalId: string, data: Partial<Pick<Team, 'name' | 'description'>>): Promise<Team>;
  deactivate(externalId: string): Promise<void>;
  addMember(teamExternalId: string, playerUserId: string, displayName: string, position: string | null): Promise<TeamMember>;
  removeMember(teamExternalId: string, playerUserId: string): Promise<void>;
  findMember(teamExternalId: string, playerUserId: string): Promise<TeamMember | null>;
  findMembers(teamExternalId: string): Promise<TeamMember[]>;
  countActiveMembers(teamExternalId: string): Promise<number>;
  setCaptain(teamExternalId: string, newCaptainUserId: string): Promise<void>;
  updateMemberSnapshot(playerUserId: string, displayName: string, position: string | null): Promise<void>;
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/domain/repositories/team-repository.interface.ts && git commit -m "feat(team): add TeamRepositoryInterface"`

---

### Task 11: team.schema.ts

**File:** `services/team/src/modules/team/teams/infra/database/schemas/team.schema.ts`

- [ ] Criar `services/team/src/modules/team/teams/infra/database/schemas/team.schema.ts`:

```typescript
import {
  pgTable,
  bigserial,
  uuid,
  text,
  smallint,
  boolean,
  timestamp,
} from 'drizzle-orm/pg-core';

export const teams = pgTable('teams', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  name: text('name').notNull(),
  description: text('description'),
  captainUserId: text('captain_user_id').notNull(),  // identity UUID, no FK (cross-service)
  minPlayers: smallint('min_players').notNull().default(5),
  maxPlayers: smallint('max_players').notNull().default(11),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type TeamRow = typeof teams.$inferSelect;
export type NewTeamRow = typeof teams.$inferInsert;
```

- [ ] Commit: `git add services/team/src/modules/team/teams/infra/database/schemas/team.schema.ts && git commit -m "feat(team): add teams Drizzle schema"`

---

### Task 12: team-member.schema.ts

**File:** `services/team/src/modules/team/teams/infra/database/schemas/team-member.schema.ts`

- [ ] Criar `services/team/src/modules/team/teams/infra/database/schemas/team-member.schema.ts`:

```typescript
import {
  pgTable,
  bigserial,
  bigint,
  text,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { teams } from './team.schema';

export const teamMembers = pgTable(
  'team_members',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    teamId: bigint('team_id', { mode: 'number' })
      .notNull()
      .references(() => teams.id, { onDelete: 'cascade' }),
    playerUserId: text('player_user_id').notNull(),  // identity UUID, no FK constraint
    displayName: text('display_name').notNull(),
    position: text('position'),
    role: text('role').notNull().default('member'),  // 'captain' | 'member'
    joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
    leftAt: timestamp('left_at', { withTimezone: true }),  // null = active member
  },
  (table) => [
    index('idx_team_members_team_id').on(table.teamId),
    index('idx_team_members_player_user_id').on(table.playerUserId),
  ],
);

export type TeamMemberRow = typeof teamMembers.$inferSelect;
export type NewTeamMemberRow = typeof teamMembers.$inferInsert;
```

- [ ] Commit: `git add services/team/src/modules/team/teams/infra/database/schemas/team-member.schema.ts && git commit -m "feat(team): add team_members Drizzle schema"`

---

### Task 13: drizzle-team.repository.ts

**File:** `services/team/src/modules/team/teams/infra/repositories/drizzle-team.repository.ts`

- [ ] Criar `services/team/src/modules/team/teams/infra/repositories/drizzle-team.repository.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { and, eq, isNull, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateTeamData,
  TeamRepositoryInterface,
  TeamWithCount,
} from '../../domain/repositories/team-repository.interface';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';
import { teams, type TeamRow } from '../database/schemas/team.schema';
import { teamMembers, type TeamMemberRow } from '../database/schemas/team-member.schema';

@Injectable()
export class DrizzleTeamRepository implements TeamRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateTeamData): Promise<Team> {
    return this.drizzle.db.transaction(async (tx) => {
      const [teamRow] = await tx
        .insert(teams)
        .values({
          name: data.name,
          description: data.description ?? null,
          captainUserId: data.captainUserId,
          minPlayers: data.minPlayers,
          maxPlayers: data.maxPlayers,
        })
        .returning();

      await tx.insert(teamMembers).values({
        teamId: teamRow.id,
        playerUserId: data.captainUserId,
        displayName: data.captainDisplayName,
        position: null,
        role: 'captain',
      });

      return this.toTeam(teamRow);
    });
  }

  async findById(externalId: string): Promise<Team | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(teams)
      .where(eq(teams.externalId, externalId))
      .limit(1);
    return row ? this.toTeam(row) : null;
  }

  async findByIdWithMemberCount(externalId: string): Promise<TeamWithCount | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(teams)
      .where(eq(teams.externalId, externalId))
      .limit(1);

    if (!row) return null;

    const count = await this.countActiveMembers(externalId);
    return { ...this.toTeam(row), memberCount: count };
  }

  async update(externalId: string, data: Partial<Pick<Team, 'name' | 'description'>>): Promise<Team> {
    const updateData: Partial<typeof teams.$inferInsert> = { updatedAt: new Date() };
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;

    const [row] = await this.drizzle.db
      .update(teams)
      .set(updateData)
      .where(eq(teams.externalId, externalId))
      .returning();

    if (!row) throw new Error(`Team "${externalId}" not found`);
    return this.toTeam(row);
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(teams)
      .set({ isActive: false, updatedAt: new Date() })
      .where(eq(teams.externalId, externalId));
  }

  async addMember(
    teamExternalId: string,
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<TeamMember> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

    const [row] = await this.drizzle.db
      .insert(teamMembers)
      .values({ teamId: teamRow.id, playerUserId, displayName, position, role: 'member' })
      .returning();

    if (!row) throw new Error(`Failed to add member to team "${teamExternalId}"`);
    return this.toMember(row);
  }

  async removeMember(teamExternalId: string, playerUserId: string): Promise<void> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

    await this.drizzle.db
      .update(teamMembers)
      .set({ leftAt: new Date() })
      .where(
        and(
          eq(teamMembers.teamId, teamRow.id),
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      );
  }

  async findMember(teamExternalId: string, playerUserId: string): Promise<TeamMember | null> {
    const [row] = await this.drizzle.db
      .select({ tm: teamMembers })
      .from(teamMembers)
      .innerJoin(teams, eq(teams.id, teamMembers.teamId))
      .where(
        and(
          eq(teams.externalId, teamExternalId),
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      )
      .limit(1);

    return row ? this.toMember(row.tm) : null;
  }

  async findMembers(teamExternalId: string): Promise<TeamMember[]> {
    const rows = await this.drizzle.db
      .select({ tm: teamMembers })
      .from(teamMembers)
      .innerJoin(teams, eq(teams.id, teamMembers.teamId))
      .where(
        and(
          eq(teams.externalId, teamExternalId),
          isNull(teamMembers.leftAt),
        ),
      );

    return rows.map((r) => this.toMember(r.tm));
  }

  async countActiveMembers(teamExternalId: string): Promise<number> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) return 0;

    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(teamMembers)
      .where(
        and(
          eq(teamMembers.teamId, teamRow.id),
          isNull(teamMembers.leftAt),
        ),
      );

    return result?.count ?? 0;
  }

  async setCaptain(teamExternalId: string, newCaptainUserId: string): Promise<void> {
    await this.drizzle.db.transaction(async (tx) => {
      const [teamRow] = await tx
        .select({ id: teams.id, captainUserId: teams.captainUserId })
        .from(teams)
        .where(eq(teams.externalId, teamExternalId))
        .limit(1);

      if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

      await tx
        .update(teams)
        .set({ captainUserId: newCaptainUserId, updatedAt: new Date() })
        .where(eq(teams.externalId, teamExternalId));

      await tx
        .update(teamMembers)
        .set({ role: 'member' })
        .where(
          and(
            eq(teamMembers.teamId, teamRow.id),
            eq(teamMembers.playerUserId, teamRow.captainUserId),
            isNull(teamMembers.leftAt),
          ),
        );

      await tx
        .update(teamMembers)
        .set({ role: 'captain' })
        .where(
          and(
            eq(teamMembers.teamId, teamRow.id),
            eq(teamMembers.playerUserId, newCaptainUserId),
            isNull(teamMembers.leftAt),
          ),
        );
    });
  }

  async updateMemberSnapshot(
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<void> {
    await this.drizzle.db
      .update(teamMembers)
      .set({ displayName, position })
      .where(
        and(
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      );
  }

  private toTeam(row: TeamRow): Team {
    return {
      id: row.externalId,
      name: row.name,
      description: row.description ?? null,
      captainUserId: row.captainUserId,
      minPlayers: row.minPlayers,
      maxPlayers: row.maxPlayers,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toMember(row: TeamMemberRow): TeamMember {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      position: row.position ?? null,
      role: row.role as 'captain' | 'member',
      joinedAt: row.joinedAt,
      leftAt: row.leftAt ?? null,
    };
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/infra/repositories/drizzle-team.repository.ts && git commit -m "feat(team): add DrizzleTeamRepository"`

---

### Task 14: create-team.dto.ts

**File:** `services/team/src/modules/team/teams/application/dto/create-team.dto.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/dto/create-team.dto.ts`:

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateTeamDto {
  @ApiProperty({ description: 'Nome da equipe', example: 'Los Cracks' })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name!: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe', example: 'Time de pelada do bairro' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  description?: string;

  @ApiPropertyOptional({ description: 'Mínimo de jogadores para partida', default: 5 })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(11)
  minPlayers?: number;

  @ApiPropertyOptional({ description: 'Máximo de jogadores no elenco', default: 11 })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(22)
  maxPlayers?: number;
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/dto/create-team.dto.ts && git commit -m "feat(team): add CreateTeamDto"`

---

### Task 15: update-team.dto.ts

**File:** `services/team/src/modules/team/teams/application/dto/update-team.dto.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/dto/update-team.dto.ts`:

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateTeamDto {
  @ApiPropertyOptional({ description: 'Nome da equipe', example: 'Los Cracks FC' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name?: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  description?: string;
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/dto/update-team.dto.ts && git commit -m "feat(team): add UpdateTeamDto"`

---

### Task 16: transfer-captaincy.dto.ts

**File:** `services/team/src/modules/team/teams/application/dto/transfer-captaincy.dto.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/dto/transfer-captaincy.dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class TransferCaptaincyDto {
  @ApiProperty({
    description: 'UUID do novo capitão (deve ser membro ativo da equipe)',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  newCaptainId!: string;
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/dto/transfer-captaincy.dto.ts && git commit -m "feat(team): add TransferCaptaincyDto"`

---

### Task 17: team.dto.ts

**File:** `services/team/src/modules/team/teams/application/dto/team.dto.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/dto/team.dto.ts`:

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Team } from '../../domain/models/team.entity';

export class TeamDto {
  @ApiProperty({ description: 'ID público da equipe (UUID)' })
  id!: string;

  @ApiProperty({ description: 'Nome da equipe' })
  name!: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe' })
  description!: string | null;

  @ApiProperty({ description: 'UUID do capitão (identity)' })
  captainUserId!: string;

  @ApiProperty({ description: 'Mínimo de jogadores para partida' })
  minPlayers!: number;

  @ApiProperty({ description: 'Máximo de jogadores no elenco' })
  maxPlayers!: number;

  @ApiProperty({ description: 'Número de membros ativos' })
  memberCount!: number;

  @ApiProperty({ description: 'Equipe ativa?' })
  isActive!: boolean;

  @ApiProperty({ description: 'Data de criação' })
  createdAt!: Date;

  static fromTeamAndCount(team: Team, count: number): TeamDto {
    const dto = new TeamDto();
    dto.id = team.id;
    dto.name = team.name;
    dto.description = team.description;
    dto.captainUserId = team.captainUserId;
    dto.minPlayers = team.minPlayers;
    dto.maxPlayers = team.maxPlayers;
    dto.memberCount = count;
    dto.isActive = team.isActive;
    dto.createdAt = team.createdAt;
    return dto;
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/dto/team.dto.ts && git commit -m "feat(team): add TeamDto"`

---

### Task 18: team-member.dto.ts

**File:** `services/team/src/modules/team/teams/application/dto/team-member.dto.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/dto/team-member.dto.ts`:

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { TeamMember } from '../../domain/models/team-member.entity';

export class TeamMemberDto {
  @ApiProperty({ description: 'UUID do jogador (identity)' })
  playerUserId!: string;

  @ApiProperty({ description: 'Nome de exibição (snapshot)' })
  displayName!: string;

  @ApiPropertyOptional({ description: 'Posição preferida (snapshot)' })
  position!: string | null;

  @ApiProperty({ enum: ['captain', 'member'], description: 'Papel na equipe' })
  role!: 'captain' | 'member';

  @ApiProperty({ description: 'Data de entrada na equipe' })
  joinedAt!: Date;

  static fromMember(member: TeamMember): TeamMemberDto {
    const dto = new TeamMemberDto();
    dto.playerUserId = member.playerUserId;
    dto.displayName = member.displayName;
    dto.position = member.position;
    dto.role = member.role;
    dto.joinedAt = member.joinedAt;
    return dto;
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/dto/team-member.dto.ts && git commit -m "feat(team): add TeamMemberDto"`

---

### Task 19: team.service.spec.ts (TDD — red phase)

**File:** `services/team/src/modules/team/teams/application/services/team.service.spec.ts`

- [ ] Criar o arquivo de testes:

```typescript
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TeamService } from './team.service';
import { TEAM_REPOSITORY } from '../../domain/repositories/team-repository.interface';
import { TeamMessagingService } from './team-messaging.service';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';

const mockTeamRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByIdWithMemberCount: jest.fn(),
  update: jest.fn(),
  deactivate: jest.fn(),
  addMember: jest.fn(),
  removeMember: jest.fn(),
  findMember: jest.fn(),
  findMembers: jest.fn(),
  countActiveMembers: jest.fn(),
  setCaptain: jest.fn(),
  updateMemberSnapshot: jest.fn(),
};

const mockMessaging = {
  publishTeamCreated: jest.fn(),
  publishPlayerJoined: jest.fn(),
  publishPlayerLeft: jest.fn(),
  publishTeamBecameInvalid: jest.fn(),
  publishCaptaincyTransferred: jest.fn(),
};

const mockTeam: Team = {
  id: 'team-uuid-1',
  name: 'Los Cracks',
  description: 'Time de pelada',
  captainUserId: 'player-captain',
  minPlayers: 5,
  maxPlayers: 11,
  isActive: true,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

const mockMember: TeamMember = {
  playerUserId: 'player-member',
  displayName: 'João Silva',
  position: null,
  role: 'member',
  joinedAt: new Date('2026-01-01'),
  leftAt: null,
};

describe('TeamService', () => {
  let service: TeamService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module = await Test.createTestingModule({
      providers: [
        TeamService,
        { provide: TEAM_REPOSITORY, useValue: mockTeamRepo },
        { provide: TeamMessagingService, useValue: mockMessaging },
      ],
    }).compile();

    service = module.get(TeamService);
  });

  describe('create', () => {
    it('creates a team and publishes team.created event', async () => {
      mockTeamRepo.create.mockResolvedValue(mockTeam);

      const result = await service.create('player-captain', 'El Capitán', {
        name: 'Los Cracks',
        minPlayers: 5,
        maxPlayers: 11,
      });

      expect(result.id).toBe('team-uuid-1');
      expect(result.memberCount).toBe(1);
      expect(mockTeamRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Los Cracks',
          captainUserId: 'player-captain',
          captainDisplayName: 'El Capitán',
          minPlayers: 5,
          maxPlayers: 11,
        }),
      );
      expect(mockMessaging.publishTeamCreated).toHaveBeenCalledWith(mockTeam, 1);
    });

    it('applies default minPlayers=5 and maxPlayers=11 when not provided', async () => {
      mockTeamRepo.create.mockResolvedValue(mockTeam);
      await service.create('player-captain', 'El Capitán', { name: 'Sem config' });
      expect(mockTeamRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ minPlayers: 5, maxPlayers: 11 }),
      );
    });
  });

  describe('getTeam', () => {
    it('returns TeamDto when team exists', async () => {
      mockTeamRepo.findByIdWithMemberCount.mockResolvedValue({ ...mockTeam, memberCount: 3 });
      const result = await service.getTeam('team-uuid-1');
      expect(result.memberCount).toBe(3);
    });

    it('throws NotFoundException when team does not exist', async () => {
      mockTeamRepo.findByIdWithMemberCount.mockResolvedValue(null);
      await expect(service.getTeam('non-existent')).rejects.toThrow(NotFoundException);
    });
  });

  describe('join', () => {
    it('adds member to team and publishes player-joined event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      mockTeamRepo.countActiveMembers.mockResolvedValue(4);
      mockTeamRepo.addMember.mockResolvedValue(mockMember);

      const result = await service.join('player-member', 'João Silva', 'team-uuid-1');

      expect(result.playerUserId).toBe('player-member');
      expect(mockMessaging.publishPlayerJoined).toHaveBeenCalledWith(mockTeam, mockMember);
    });

    it('throws NotFoundException when team does not exist', async () => {
      mockTeamRepo.findById.mockResolvedValue(null);
      await expect(service.join('player-member', 'João', 'no-team')).rejects.toThrow(NotFoundException);
    });

    it('throws NotFoundException when team is inactive', async () => {
      mockTeamRepo.findById.mockResolvedValue({ ...mockTeam, isActive: false });
      await expect(service.join('player-member', 'João', 'team-uuid-1')).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when player is already a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      await expect(service.join('player-member', 'João', 'team-uuid-1')).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException when team is full', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      mockTeamRepo.countActiveMembers.mockResolvedValue(11); // maxPlayers = 11
      await expect(service.join('player-new', 'Novo', 'team-uuid-1')).rejects.toThrow(ConflictException);
    });
  });

  describe('leave', () => {
    it('removes member and publishes player-left event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(6);

      await service.leave('player-member', 'team-uuid-1');

      expect(mockTeamRepo.removeMember).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishPlayerLeft).toHaveBeenCalledWith(mockTeam, 'player-member');
      expect(mockMessaging.publishTeamBecameInvalid).not.toHaveBeenCalled();
    });

    it('publishes team.became-invalid when count drops below minPlayers', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(4); // below minPlayers=5

      await service.leave('player-member', 'team-uuid-1');

      expect(mockMessaging.publishTeamBecameInvalid).toHaveBeenCalledWith(mockTeam);
    });

    it('throws ForbiddenException when captain tries to leave without transferring', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(service.leave('player-captain', 'team-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('throws NotFoundException when player is not a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      await expect(service.leave('player-member', 'team-uuid-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('removeMember', () => {
    it('captain can remove a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(6);

      await service.removeMember('player-captain', 'team-uuid-1', 'player-member');

      expect(mockTeamRepo.removeMember).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishPlayerLeft).toHaveBeenCalledWith(mockTeam, 'player-member');
    });

    it('throws ForbiddenException when non-captain tries to remove', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.removeMember('player-other', 'team-uuid-1', 'player-member'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws ForbiddenException when captain tries to remove themselves', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.removeMember('player-captain', 'team-uuid-1', 'player-captain'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('transferCaptaincy', () => {
    it('transfers captaincy to an active member', async () => {
      const updatedTeam = { ...mockTeam, captainUserId: 'player-member' };
      mockTeamRepo.findById
        .mockResolvedValueOnce(mockTeam)
        .mockResolvedValueOnce(updatedTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(5);

      const result = await service.transferCaptaincy('player-captain', 'team-uuid-1', {
        newCaptainId: 'player-member',
      });

      expect(mockTeamRepo.setCaptain).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishCaptaincyTransferred).toHaveBeenCalledWith(
        updatedTeam,
        'player-captain',
        'player-member',
      );
      expect(result.captainUserId).toBe('player-member');
    });

    it('throws ForbiddenException when non-captain tries to transfer', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.transferCaptaincy('player-other', 'team-uuid-1', { newCaptainId: 'player-member' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws NotFoundException when new captain is not a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      await expect(
        service.transferCaptaincy('player-captain', 'team-uuid-1', { newCaptainId: 'stranger' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deactivate', () => {
    it('deactivates team and publishes team.became-invalid event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await service.deactivate('player-captain', 'team-uuid-1');
      expect(mockTeamRepo.deactivate).toHaveBeenCalledWith('team-uuid-1');
      expect(mockMessaging.publishTeamBecameInvalid).toHaveBeenCalledWith(mockTeam);
    });

    it('throws ForbiddenException when non-captain tries to deactivate', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(service.deactivate('player-other', 'team-uuid-1')).rejects.toThrow(ForbiddenException);
    });
  });
});
```

- [ ] Rodar o teste para confirmar que falha (TeamService não existe):

```bash
cd services/team && npx jest src/modules/team/teams/application/services/team.service.spec.ts --no-coverage 2>&1 | tail -5
```

Esperado: `FAIL` — "Cannot find module './team.service'"

---

### Task 20: team.service.ts (TDD — green phase)

**File:** `services/team/src/modules/team/teams/application/services/team.service.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/services/team.service.ts`:

```typescript
import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  TEAM_REPOSITORY,
  TeamRepositoryInterface,
} from '../../domain/repositories/team-repository.interface';
import { TeamMessagingService } from './team-messaging.service';
import { CreateTeamDto } from '../dto/create-team.dto';
import { UpdateTeamDto } from '../dto/update-team.dto';
import { TransferCaptaincyDto } from '../dto/transfer-captaincy.dto';
import { TeamDto } from '../dto/team.dto';
import { TeamMemberDto } from '../dto/team-member.dto';

@Injectable()
export class TeamService {
  constructor(
    @Inject(TEAM_REPOSITORY)
    private readonly teamRepository: TeamRepositoryInterface,
    private readonly messaging: TeamMessagingService,
  ) {}

  async create(userId: string, userName: string, dto: CreateTeamDto): Promise<TeamDto> {
    const team = await this.teamRepository.create({
      name: dto.name,
      description: dto.description,
      captainUserId: userId,
      captainDisplayName: userName,
      minPlayers: dto.minPlayers ?? 5,
      maxPlayers: dto.maxPlayers ?? 11,
    });

    await this.messaging.publishTeamCreated(team, 1);
    return TeamDto.fromTeamAndCount(team, 1);
  }

  async getTeam(teamId: string): Promise<TeamDto> {
    const result = await this.teamRepository.findByIdWithMemberCount(teamId);
    if (!result) throw new NotFoundException(`Team ${teamId} not found`);
    return TeamDto.fromTeamAndCount(result, result.memberCount);
  }

  async update(userId: string, teamId: string, dto: UpdateTeamDto): Promise<TeamDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can update the team');
    }

    const updated = await this.teamRepository.update(teamId, {
      name: dto.name,
      description: dto.description,
    });
    const count = await this.teamRepository.countActiveMembers(teamId);
    return TeamDto.fromTeamAndCount(updated, count);
  }

  async deactivate(userId: string, teamId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can deactivate the team');
    }

    await this.teamRepository.deactivate(teamId);

    try {
      await this.messaging.publishTeamBecameInvalid(team);
    } catch (error) {
      // Advisory event — don't fail the deactivation
    }
  }

  async join(userId: string, userName: string, teamId: string): Promise<TeamMemberDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team || !team.isActive) throw new NotFoundException(`Team ${teamId} not found`);

    const existing = await this.teamRepository.findMember(teamId, userId);
    if (existing) throw new ConflictException('Already a member of this team');

    const count = await this.teamRepository.countActiveMembers(teamId);
    if (count >= team.maxPlayers) throw new ConflictException('Team is full');

    const member = await this.teamRepository.addMember(teamId, userId, userName, null);

    try {
      await this.messaging.publishPlayerJoined(team, member);
    } catch (error) {
      // Advisory event
    }

    return TeamMemberDto.fromMember(member);
  }

  async leave(userId: string, teamId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);

    if (team.captainUserId === userId) {
      throw new ForbiddenException('Captain must transfer captaincy before leaving');
    }

    const member = await this.teamRepository.findMember(teamId, userId);
    if (!member) throw new NotFoundException('Not a member of this team');

    await this.teamRepository.removeMember(teamId, userId);

    const count = await this.teamRepository.countActiveMembers(teamId);

    try {
      await this.messaging.publishPlayerLeft(team, userId);
      if (count < team.minPlayers) {
        await this.messaging.publishTeamBecameInvalid(team);
      }
    } catch (error) {
      // Advisory events
    }
  }

  async removeMember(captainId: string, teamId: string, playerId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== captainId) {
      throw new ForbiddenException('Only the captain can remove members');
    }
    if (playerId === captainId) {
      throw new ForbiddenException('Captain cannot remove themselves; use leave instead');
    }

    const member = await this.teamRepository.findMember(teamId, playerId);
    if (!member) throw new NotFoundException('Player is not a member of this team');

    await this.teamRepository.removeMember(teamId, playerId);

    const count = await this.teamRepository.countActiveMembers(teamId);

    try {
      await this.messaging.publishPlayerLeft(team, playerId);
      if (count < team.minPlayers) {
        await this.messaging.publishTeamBecameInvalid(team);
      }
    } catch (error) {
      // Advisory events
    }
  }

  async transferCaptaincy(
    userId: string,
    teamId: string,
    dto: TransferCaptaincyDto,
  ): Promise<TeamDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can transfer captaincy');
    }

    const newCaptain = await this.teamRepository.findMember(teamId, dto.newCaptainId);
    if (!newCaptain) throw new NotFoundException('New captain is not a member of this team');

    await this.teamRepository.setCaptain(teamId, dto.newCaptainId);

    const [updatedTeam, count] = await Promise.all([
      this.teamRepository.findById(teamId),
      this.teamRepository.countActiveMembers(teamId),
    ]);

    try {
      await this.messaging.publishCaptaincyTransferred(updatedTeam!, userId, dto.newCaptainId);
    } catch (error) {
      // Advisory event
    }

    return TeamDto.fromTeamAndCount(updatedTeam!, count);
  }

  async getMembers(teamId: string): Promise<TeamMemberDto[]> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    const members = await this.teamRepository.findMembers(teamId);
    return members.map(TeamMemberDto.fromMember);
  }
}
```

- [ ] Rodar os testes para confirmar que passam:

```bash
cd services/team && npx jest src/modules/team/teams/application/services/team.service.spec.ts --no-coverage 2>&1 | tail -10
```

Esperado: `PASS` — todos os testes passando.

- [ ] Commit ambos os arquivos:

```bash
cd services/team && git add src/modules/team/teams/application/services/ && git commit -m "feat(team): add TeamService with TDD (create/join/leave/transfer-captaincy)"
```

---

### Task 21: team-messaging.service.ts

**File:** `services/team/src/modules/team/teams/application/services/team-messaging.service.ts`

- [ ] Criar `services/team/src/modules/team/teams/application/services/team-messaging.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { TeamEvents } from '@shared/contracts/events/team-events.enum';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';

@Injectable()
export class TeamMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishTeamCreated(team: Team, memberCount: number): Promise<void> {
    await this.messaging.publish(TeamEvents.CREATED, {
      teamId: team.id,
      name: team.name,
      captainUserId: team.captainUserId,
      memberCount,
      createdAt: team.createdAt,
    });
  }

  async publishPlayerJoined(team: Team, member: TeamMember): Promise<void> {
    await this.messaging.publish(TeamEvents.PLAYER_JOINED, {
      teamId: team.id,
      playerUserId: member.playerUserId,
      displayName: member.displayName,
    });
  }

  async publishPlayerLeft(team: Team, playerUserId: string): Promise<void> {
    await this.messaging.publish(TeamEvents.PLAYER_LEFT, {
      teamId: team.id,
      playerUserId,
    });
  }

  async publishTeamBecameInvalid(team: Team): Promise<void> {
    await this.messaging.publish(TeamEvents.BECAME_INVALID, {
      teamId: team.id,
    });
  }

  async publishCaptaincyTransferred(
    team: Team,
    previousCaptainId: string,
    newCaptainId: string,
  ): Promise<void> {
    await this.messaging.publish(TeamEvents.CAPTAINCY_TRANSFERRED, {
      teamId: team.id,
      previousCaptainId,
      newCaptainId,
    });
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/services/team-messaging.service.ts && git commit -m "feat(team): add TeamMessagingService"`

---

### Task 22: identity-events.consumer.ts

**File:** `services/team/src/modules/team/teams/application/services/identity-events.consumer.ts`

Consome `identity.profile-updated` via RabbitMQ para manter snapshots de `displayName` e `position` em `team_members`.

- [ ] Criar `services/team/src/modules/team/teams/application/services/identity-events.consumer.ts`:

```typescript
import { Inject, Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  TEAM_REPOSITORY,
  TeamRepositoryInterface,
} from '../../domain/repositories/team-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(TEAM_REPOSITORY)
    private readonly teamRepository: TeamRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'team-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.teamRepository.updateMemberSnapshot(
        payload.userId,
        payload.displayName,
        payload.position,
      );
      this.logger.debug(`Updated member snapshot for player ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update member snapshot for player ${payload.userId}: ${message}`,
      );
      // Don't rethrow — message is acknowledged; snapshot will be corrected on next profile update
    }
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/application/services/identity-events.consumer.ts && git commit -m "feat(team): add IdentityEventsConsumer for profile snapshot updates"`

---

### Task 23: teams.controller.ts

**File:** `services/team/src/modules/team/teams/infra/controllers/teams.controller.ts`

- [ ] Criar `services/team/src/modules/team/teams/infra/controllers/teams.controller.ts`:

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
  Put,
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
import { TeamService } from '../../application/services/team.service';
import { CreateTeamDto } from '../../application/dto/create-team.dto';
import { UpdateTeamDto } from '../../application/dto/update-team.dto';
import { TransferCaptaincyDto } from '../../application/dto/transfer-captaincy.dto';
import { TeamDto } from '../../application/dto/team.dto';
import { TeamMemberDto } from '../../application/dto/team-member.dto';

@ApiTags('teams')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('teams')
export class TeamsController {
  constructor(private readonly teamService: TeamService) {}

  @Post()
  @Permissions('teams:write')
  @HateoasItem(TeamDto)
  @ApiOperation({ summary: 'Criar equipe' })
  create(
    @Body() dto: CreateTeamDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.create(user.id, user.name, dto);
  }

  @Get(':id')
  @Public()
  @HateoasItem(TeamDto)
  @ApiOperation({ summary: 'Obter detalhes da equipe' })
  getTeam(@Param('id') id: string): Promise<TeamDto> {
    return this.teamService.getTeam(id);
  }

  @Put(':id')
  @Permissions('teams:write')
  @HateoasItem(TeamDto)
  @ApiOperation({ summary: 'Atualizar equipe (somente capitão)' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateTeamDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.update(user.id, id, dto);
  }

  @Delete(':id')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Desativar equipe (somente capitão)' })
  deactivate(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.deactivate(user.id, id);
  }

  @Post(':id/members')
  @Permissions('teams:write')
  @HateoasItem(TeamMemberDto)
  @ApiOperation({ summary: 'Entrar na equipe' })
  join(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamMemberDto> {
    return this.teamService.join(user.id, user.name, id);
  }

  @Delete(':id/members/me')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Sair da equipe' })
  leave(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.leave(user.id, id);
  }

  @Delete(':id/members/:playerId')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remover membro da equipe (somente capitão)' })
  removeMember(
    @Param('id') id: string,
    @Param('playerId') playerId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.removeMember(user.id, id, playerId);
  }

  @Put(':id/captain')
  @Permissions('teams:write')
  @HateoasItem(TeamDto)
  @ApiOperation({ summary: 'Transferir capitania' })
  transferCaptaincy(
    @Param('id') id: string,
    @Body() dto: TransferCaptaincyDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.transferCaptaincy(user.id, id, dto);
  }

  @Get(':id/members')
  @Public()
  @HateoasList(TeamMemberDto)
  @ApiOperation({ summary: 'Listar membros da equipe' })
  getMembers(@Param('id') id: string): Promise<TeamMemberDto[]> {
    return this.teamService.getMembers(id);
  }
}
```

- [ ] Commit: `git add services/team/src/modules/team/teams/infra/controllers/teams.controller.ts && git commit -m "feat(team): add TeamsController"`

---

### Task 24: teams.module.ts + task 25: team.module.ts

**File:** `services/team/src/modules/team/teams/teams.module.ts`

- [ ] Criar `services/team/src/modules/team/teams/teams.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { TeamService } from './application/services/team.service';
import { TeamMessagingService } from './application/services/team-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { TeamsController } from './infra/controllers/teams.controller';
import { DrizzleTeamRepository } from './infra/repositories/drizzle-team.repository';
import { TEAM_REPOSITORY } from './domain/repositories/team-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [TeamsController],
  providers: [
    TeamService,
    TeamMessagingService,
    IdentityEventsConsumer,
    { provide: TEAM_REPOSITORY, useClass: DrizzleTeamRepository },
  ],
  exports: [TeamService],
})
export class TeamsModule {}
```

**File:** `services/team/src/modules/team/team.module.ts`

- [ ] Criar `services/team/src/modules/team/team.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { TeamsModule } from './teams/teams.module';

@Module({
  imports: [TeamsModule],
})
export class TeamModule {}
```

- [ ] Commit: `git add services/team/src/modules/team/ && git commit -m "feat(team): add TeamsModule and TeamModule"`

---

### Task 26: Verificar compilação TypeScript

- [ ] Compilar o serviço:

```bash
cd services/team && npm run build 2>&1 | tail -20
```

Esperado: `Successfully compiled` — sem erros TypeScript.

- [ ] Rodar todos os testes:

```bash
cd services/team && npx jest --no-coverage 2>&1 | tail -10
```

Esperado: todos os testes passando.

---

### Task 27: Dockerfile + docker-entrypoint.sh + scripts/migrate.js

**File:** `services/team/Dockerfile`

- [ ] Criar `services/team/Dockerfile`:

```dockerfile
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/team/ ./services/team/

WORKDIR /app/services/team
RUN npm ci
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/team

COPY --from=builder /app/services/team/dist ./dist
COPY --from=builder /app/services/team/package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/services/team/drizzle ./drizzle
COPY services/team/scripts ./scripts
COPY services/team/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4002

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

**File:** `services/team/docker-entrypoint.sh`

- [ ] Criar `services/team/docker-entrypoint.sh`:

```sh
#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/team/scripts/migrate.js

echo "Starting team service..."
exec node /app/services/team/dist/services/team/src/main
```

**File:** `services/team/scripts/migrate.js`

- [ ] Criar `services/team/scripts/migrate.js`:

```js
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

- [ ] Commit:

```bash
git add services/team/Dockerfile services/team/docker-entrypoint.sh services/team/scripts/ && git commit -m "chore(team): add Dockerfile and migration entrypoint"
```

---

### Task 28: Atualizar docker-compose.yml

- [ ] Editar `docker-compose.yml` na raiz do repositório. Adicionar após o serviço `identity`:

```yaml
  postgres-team:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_team
    ports:
      - "5433:5432"
    volumes:
      - postgres_team_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d bolanarededb_team"]
      interval: 5s
      timeout: 5s
      retries: 10

  team:
    build:
      context: .
      dockerfile: services/team/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4002
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-team:5432/bolanarededb_team
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4002:4002"
    depends_on:
      postgres-team:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

Também adicionar `postgres_team_data:` na seção `volumes:` do arquivo.

A seção `volumes:` final deve ficar:

```yaml
volumes:
  postgres_identity_data:
  postgres_team_data:
```

- [ ] Commit: `git add docker-compose.yml && git commit -m "chore(docker): add postgres-team and team service to docker-compose"`

---

### Task 29: Gerar migration + verificação final

- [ ] Copiar `.env.example` para `.env`:

```bash
cd services/team && cp .env.example .env
```

- [ ] Gerar migration:

```bash
cd services/team && npm run db:generate
```

Esperado: pasta `drizzle/` criada com arquivo `0000_*.sql` contendo `CREATE TABLE teams` e `CREATE TABLE team_members`.

- [ ] Verificar o conteúdo do SQL gerado:

```bash
head -30 services/team/drizzle/*.sql
```

Esperado: DDL com as tabelas `teams` e `team_members`, índices corretos, FK de `team_members.team_id → teams.id` com `ON DELETE CASCADE`.

- [ ] Commit:

```bash
git add services/team/drizzle/ && git commit -m "chore(team): generate initial Drizzle migrations"
```

- [ ] Atualizar `docs/plans/_status.md`:

```markdown
| team         | ✅ DONE  | 29/29      | —                            |
```

Também adicionar na seção `## Planos`:
```markdown
- `docs/plans/2026-05-27-team-service.md` — 29 tasks
```

- [ ] Commit final:

```bash
git add docs/plans/_status.md docs/plans/2026-05-27-team-service.md && git commit -m "docs(plans): add team-service plan and update status"
```

---

## Verificação Final

**Checklist de conclusão do team-service:**
- [ ] `npm run build` passa sem erros TypeScript
- [ ] `npx jest --no-coverage` — todos os testes passando
- [ ] `npm run db:generate` — migration SQL gerado com `teams` + `team_members`
- [ ] docker-compose.yml atualizado com `postgres-team` + `team` service
- [ ] `POST /v1/teams` cria equipe (com `teams:write` permission + JWT)
- [ ] `GET /v1/teams/:id` retorna equipe (público)
- [ ] `GET /v1/teams/:id/members` retorna membros (público)
- [ ] Nenhum `console.log`, nenhum `any` implícito
