# Identity Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-05-26-shared-module.md` deve estar 100% concluído antes de começar este plano.

**Goal:** Criar o `identity-service` (porta 4001) com autenticação JWT, gerenciamento de perfil e device tokens.

**Architecture:** NestJS 11 com 3 módulos de domínio: `users` (perfil, crud), `auth` (login/registro/JWT), `device-tokens` (FCM). Drizzle ORM, PostgreSQL. SharedModule (@Global) provê DrizzleService, guards, messaging.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, pg, bcrypt, @nestjs/jwt, @nestjs/swagger, @golevelup/nestjs-rabbitmq, class-validator

---

## File Map

```
services/identity/
├── .env.example                                                    ← Task 1
├── drizzle.config.ts                                               ← Task 2
├── nest-cli.json                                                   ← Task 3
├── package.json                                                    ← Task 4
├── tsconfig.json                                                   ← Task 5
├── tsconfig.build.json                                             ← Task 6
└── src/
    ├── main.ts                                                     ← Task 7
    ├── app.module.ts                                               ← Task 8
    └── modules/
        └── identity/
            ├── identity.module.ts                                  ← Task 9
            ├── users/
            │   ├── domain/
            │   │   ├── models/
            │   │   │   ├── user.entity.ts                          ← Task 10
            │   │   │   └── player-profile.entity.ts               ← Task 11
            │   │   └── repositories/
            │   │       └── user-repository.interface.ts            ← Task 12
            │   ├── infra/
            │   │   ├── database/schemas/
            │   │   │   ├── user.schema.ts                          ← Task 13
            │   │   │   ├── credential.schema.ts                    ← Task 14
            │   │   │   └── player-profile.schema.ts                ← Task 15
            │   │   ├── repositories/
            │   │   │   └── drizzle-user.repository.ts              ← Task 16
            │   │   └── controllers/
            │   │       └── users.controller.ts                     ← Task 21
            │   ├── application/
            │   │   ├── dto/
            │   │   │   ├── create-user.dto.ts                      ← Task 17
            │   │   │   ├── update-profile.dto.ts                   ← Task 18
            │   │   │   └── user.dto.ts                             ← Task 19
            │   │   └── services/
            │   │       ├── user.service.ts                         ← Task 20
            │   │       └── user-messaging.service.ts               ← Task 22
            │   └── users.module.ts                                 ← Task 23
            ├── auth/
            │   ├── application/
            │   │   ├── dto/
            │   │   │   ├── login.dto.ts                            ← Task 24
            │   │   │   └── register.dto.ts                         ← Task 25
            │   │   └── services/
            │   │       └── auth.service.spec.ts                    ← Task 26
            │   │       └── auth.service.ts                         ← Task 27
            │   ├── infra/controllers/
            │   │   └── auth.controller.ts                          ← Task 28
            │   └── auth.module.ts                                  ← Task 29
            └── device-tokens/
                ├── domain/
                │   ├── models/
                │   │   └── device-token.entity.ts                  ← Task 30
                │   └── repositories/
                │       └── device-token-repository.interface.ts    ← Task 31
                ├── infra/
                │   ├── database/schemas/
                │   │   └── device-token.schema.ts                  ← Task 32
                │   └── repositories/
                │       └── drizzle-device-token.repository.ts      ← Task 33
                ├── application/services/
                │   └── device-token.service.ts                     ← Task 34
                └── device-tokens.module.ts                         ← Task 35
```

Tasks 36–37: migration + smoke test.

---

### Task 1: .env.example

**File:** `services/identity/.env.example`

- [ ] Criar `services/identity/.env.example`:

```env
PORT=4001
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_identity
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

- [ ] Commit: `git add services/identity/.env.example && git commit -m "chore(identity): add .env.example"`

---

### Task 2: drizzle.config.ts

**File:** `services/identity/drizzle.config.ts`

- [ ] Criar `services/identity/drizzle.config.ts`:

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

- [ ] Commit: `git add services/identity/drizzle.config.ts && git commit -m "chore(identity): add drizzle.config.ts"`

---

### Task 3: nest-cli.json

**File:** `services/identity/nest-cli.json`

- [ ] Criar `services/identity/nest-cli.json`:

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

- [ ] Commit: `git add services/identity/nest-cli.json && git commit -m "chore(identity): add nest-cli.json"`

---

### Task 4: package.json

**File:** `services/identity/package.json`

- [ ] Criar `services/identity/package.json`:

```json
{
  "name": "@bolanarede/identity",
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
    "bcrypt": "^5.1.1",
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
    "@types/bcrypt": "^5.0.2",
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
      "^@shared/(.*)$": "<rootDir>/../../shared/src/$1"
    },
    "testEnvironment": "node"
  }
}
```

- [ ] Instalar dependências:

```bash
cd services/identity && npm install
```

Esperado: `node_modules/` criado sem erros.

- [ ] Commit: `git add services/identity/package.json services/identity/package-lock.json && git commit -m "chore(identity): add package.json and install deps"`

---

### Task 5: tsconfig.json

**File:** `services/identity/tsconfig.json`

- [ ] Criar `services/identity/tsconfig.json`:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "drizzle"]
}
```

- [ ] Commit: `git add services/identity/tsconfig.json && git commit -m "chore(identity): add tsconfig.json extending base"`

---

### Task 6: tsconfig.build.json

**File:** `services/identity/tsconfig.build.json`

- [ ] Criar `services/identity/tsconfig.build.json`:

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
```

- [ ] Commit: `git add services/identity/tsconfig.build.json && git commit -m "chore(identity): add tsconfig.build.json"`

---

### Task 7: main.ts

**File:** `services/identity/src/main.ts`

- [ ] Criar `services/identity/src/main.ts`:

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

- [ ] Commit: `git add services/identity/src/main.ts && git commit -m "feat(identity): add main.ts bootstrap"`

---

### Task 8: app.module.ts

**File:** `services/identity/src/app.module.ts`

- [ ] Criar `services/identity/src/app.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { IdentityModule } from './modules/identity/identity.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    IdentityModule,
  ],
})
export class AppModule {}
```

- [ ] Commit: `git add services/identity/src/app.module.ts && git commit -m "feat(identity): add AppModule"`

---

### Task 9: identity.module.ts

**File:** `services/identity/src/modules/identity/identity.module.ts`

- [ ] Criar `services/identity/src/modules/identity/identity.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { DeviceTokensModule } from './device-tokens/device-tokens.module';

@Module({
  imports: [UsersModule, AuthModule, DeviceTokensModule],
})
export class IdentityModule {}
```

- [ ] Verificar compilação parcial:

```bash
cd services/identity && npx tsc --noEmit 2>&1 | head -20
```

Esperado: erros apenas de "cannot find module" (arquivos ainda não existem) — sem erros de sintaxe nos arquivos já criados.

- [ ] Commit: `git add services/identity/src/modules/identity/identity.module.ts && git commit -m "feat(identity): add IdentityModule"`

---

### Task 10: user.entity.ts

**File:** `services/identity/src/modules/identity/users/domain/models/user.entity.ts`

- [ ] Criar `services/identity/src/modules/identity/users/domain/models/user.entity.ts`:

```typescript
export class User {
  id: string;       // maps to users.external_id (UUID)
  email: string | null;
  phone: string | null;
  status: 'ACTIVE' | 'ANONYMIZED';
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/domain/models/user.entity.ts && git commit -m "feat(identity): add User entity"`

---

### Task 11: player-profile.entity.ts

**File:** `services/identity/src/modules/identity/users/domain/models/player-profile.entity.ts`

- [ ] Criar `services/identity/src/modules/identity/users/domain/models/player-profile.entity.ts`:

```typescript
export class PlayerProfile {
  id: string;       // maps to users.external_id (player identity)
  displayName: string;
  photoUrl: string | null;
  bio: string | null;
  city: string | null;
  position: 'goalkeeper' | 'defender' | 'midfielder' | 'forward' | null;
  skillLevel: number | null;
  isPublic: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/domain/models/player-profile.entity.ts && git commit -m "feat(identity): add PlayerProfile entity"`

---

### Task 12: user-repository.interface.ts

**File:** `services/identity/src/modules/identity/users/domain/repositories/user-repository.interface.ts`

- [ ] Criar `services/identity/src/modules/identity/users/domain/repositories/user-repository.interface.ts`:

```typescript
import type { User } from '../models/user.entity';
import type { PlayerProfile } from '../models/player-profile.entity';

export const USER_REPOSITORY = 'USER_REPOSITORY';

export interface CreateUserData {
  email: string;
  passwordHash: string;
  displayName: string;
}

export interface UserWithCredential extends User {
  passwordHash: string | null;
}

export interface UserRepositoryInterface {
  findById(externalId: string): Promise<User | null>;
  findByEmail(email: string): Promise<UserWithCredential | null>;
  create(data: CreateUserData): Promise<User>;
  findProfileById(userId: string): Promise<PlayerProfile | null>;
  updateProfile(userId: string, data: Partial<PlayerProfile>): Promise<PlayerProfile>;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/domain/repositories/user-repository.interface.ts && git commit -m "feat(identity): add UserRepositoryInterface"`

---

### Task 13: user.schema.ts

**File:** `services/identity/src/modules/identity/users/infra/database/schemas/user.schema.ts`

- [ ] Criar `services/identity/src/modules/identity/users/infra/database/schemas/user.schema.ts`:

```typescript
import {
  pgTable,
  bigserial,
  uuid,
  text,
  timestamp,
} from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  email: text('email').unique(),
  phone: text('phone').unique(),
  status: text('status').notNull().default('ACTIVE'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
});

export type UserRow = typeof users.$inferSelect;
export type NewUserRow = typeof users.$inferInsert;
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/infra/database/schemas/user.schema.ts && git commit -m "feat(identity): add users Drizzle schema"`

---

### Task 14: credential.schema.ts

**File:** `services/identity/src/modules/identity/users/infra/database/schemas/credential.schema.ts`

- [ ] Criar `services/identity/src/modules/identity/users/infra/database/schemas/credential.schema.ts`:

```typescript
import { pgTable, bigserial, bigint, text, timestamp } from 'drizzle-orm/pg-core';
import { users } from './user.schema';

export const credentials = pgTable('credentials', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  userId: bigint('user_id', { mode: 'number' })
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  provider: text('provider').notNull().default('email'),
  passwordHash: text('password_hash'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type CredentialRow = typeof credentials.$inferSelect;
export type NewCredentialRow = typeof credentials.$inferInsert;
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/infra/database/schemas/credential.schema.ts && git commit -m "feat(identity): add credentials Drizzle schema"`

---

### Task 15: player-profile.schema.ts

**File:** `services/identity/src/modules/identity/users/infra/database/schemas/player-profile.schema.ts`

- [ ] Criar `services/identity/src/modules/identity/users/infra/database/schemas/player-profile.schema.ts`:

```typescript
import {
  pgTable,
  bigserial,
  bigint,
  text,
  smallint,
  boolean,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { users } from './user.schema';

export const playerProfiles = pgTable(
  'player_profiles',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    userId: bigint('user_id', { mode: 'number' })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    displayName: text('display_name').notNull(),
    photoUrl: text('photo_url'),
    bio: text('bio'),
    city: text('city'),
    position: text('position'),
    skillLevel: smallint('skill_level'),
    isPublic: boolean('is_public').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [uniqueIndex('uq_player_profiles_user_id').on(table.userId)],
);

export type PlayerProfileRow = typeof playerProfiles.$inferSelect;
export type NewPlayerProfileRow = typeof playerProfiles.$inferInsert;
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/infra/database/schemas/player-profile.schema.ts && git commit -m "feat(identity): add player_profiles Drizzle schema"`

---

### Task 16: drizzle-user.repository.ts

**File:** `services/identity/src/modules/identity/users/infra/repositories/drizzle-user.repository.ts`

- [ ] Criar `services/identity/src/modules/identity/users/infra/repositories/drizzle-user.repository.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { and, eq, isNull } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateUserData,
  UserRepositoryInterface,
  UserWithCredential,
} from '../../domain/repositories/user-repository.interface';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import { users, type UserRow } from '../database/schemas/user.schema';
import { credentials } from '../database/schemas/credential.schema';
import { playerProfiles, type PlayerProfileRow } from '../database/schemas/player-profile.schema';

@Injectable()
export class DrizzleUserRepository implements UserRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async findById(externalId: string): Promise<User | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(users)
      .where(and(eq(users.externalId, externalId), isNull(users.deletedAt)))
      .limit(1);
    return row ? this.toUser(row) : null;
  }

  async findByEmail(email: string): Promise<UserWithCredential | null> {
    const [row] = await this.drizzle.db
      .select({ user: users, credential: credentials })
      .from(users)
      .leftJoin(credentials, eq(credentials.userId, users.id))
      .where(and(eq(users.email, email), isNull(users.deletedAt)))
      .limit(1);

    if (!row) return null;
    return { ...this.toUser(row.user), passwordHash: row.credential?.passwordHash ?? null };
  }

  async create(data: CreateUserData): Promise<User> {
    return this.drizzle.db.transaction(async (tx) => {
      const [userRow] = await tx
        .insert(users)
        .values({ email: data.email })
        .returning();

      await tx.insert(credentials).values({
        userId: userRow.id,
        provider: 'email',
        passwordHash: data.passwordHash,
      });

      await tx.insert(playerProfiles).values({
        userId: userRow.id,
        displayName: data.displayName,
      });

      return this.toUser(userRow);
    });
  }

  async findProfileById(userId: string): Promise<PlayerProfile | null> {
    const [row] = await this.drizzle.db
      .select({ profile: playerProfiles, externalId: users.externalId })
      .from(playerProfiles)
      .innerJoin(users, eq(users.id, playerProfiles.userId))
      .where(eq(users.externalId, userId))
      .limit(1);

    return row ? this.toProfile(row.profile, row.externalId) : null;
  }

  async updateProfile(userId: string, data: Partial<PlayerProfile>): Promise<PlayerProfile> {
    const [userRow] = await this.drizzle.db
      .select({ id: users.id, externalId: users.externalId })
      .from(users)
      .where(eq(users.externalId, userId))
      .limit(1);

    const updateData: Partial<typeof playerProfiles.$inferInsert> = { updatedAt: new Date() };
    if (data.displayName !== undefined) updateData.displayName = data.displayName;
    if (data.photoUrl !== undefined) updateData.photoUrl = data.photoUrl;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.city !== undefined) updateData.city = data.city;
    if (data.position !== undefined) updateData.position = data.position;
    if (data.skillLevel !== undefined) updateData.skillLevel = data.skillLevel;
    if (data.isPublic !== undefined) updateData.isPublic = data.isPublic;

    const [row] = await this.drizzle.db
      .update(playerProfiles)
      .set(updateData)
      .where(eq(playerProfiles.userId, userRow.id))
      .returning();

    return this.toProfile(row, userRow.externalId);
  }

  private toUser(row: UserRow): User {
    return {
      id: row.externalId,
      email: row.email,
      phone: row.phone,
      status: row.status as 'ACTIVE' | 'ANONYMIZED',
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt ?? null,
    };
  }

  private toProfile(row: PlayerProfileRow, externalId: string): PlayerProfile {
    return {
      id: externalId,
      displayName: row.displayName,
      photoUrl: row.photoUrl ?? null,
      bio: row.bio ?? null,
      city: row.city ?? null,
      position: row.position as PlayerProfile['position'],
      skillLevel: row.skillLevel ?? null,
      isPublic: row.isPublic,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/infra/repositories/drizzle-user.repository.ts && git commit -m "feat(identity): add DrizzleUserRepository"`

---

### Task 17: create-user.dto.ts

**File:** `services/identity/src/modules/identity/users/application/dto/create-user.dto.ts`

- [ ] Criar `services/identity/src/modules/identity/users/application/dto/create-user.dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @ApiProperty({ description: 'Email do usuário', example: 'jogador@email.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Senha (mínimo 6 caracteres)', example: 'senha123' })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ description: 'Nome de exibição', example: 'João Silva' })
  @IsString()
  @MinLength(2)
  displayName: string;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/application/dto/create-user.dto.ts && git commit -m "feat(identity): add CreateUserDto"`

---

### Task 18: update-profile.dto.ts

**File:** `services/identity/src/modules/identity/users/application/dto/update-profile.dto.ts`

- [ ] Criar `services/identity/src/modules/identity/users/application/dto/update-profile.dto.ts`:

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  Min,
} from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ description: 'Nome de exibição', example: 'João Silva' })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional({ description: 'URL da foto de perfil' })
  @IsOptional()
  @IsUrl()
  photoUrl?: string;

  @ApiPropertyOptional({ description: 'Apresentação do jogador' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ description: 'Cidade', example: 'Curitiba' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({
    description: 'Posição em campo',
    enum: ['goalkeeper', 'defender', 'midfielder', 'forward'],
  })
  @IsOptional()
  @IsIn(['goalkeeper', 'defender', 'midfielder', 'forward'])
  position?: string;

  @ApiPropertyOptional({ description: 'Nível de habilidade (1–5)', minimum: 1, maximum: 5 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  skillLevel?: number;

  @ApiPropertyOptional({ description: 'Perfil visível publicamente?' })
  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/application/dto/update-profile.dto.ts && git commit -m "feat(identity): add UpdateProfileDto"`

---

### Task 19: user.dto.ts

**File:** `services/identity/src/modules/identity/users/application/dto/user.dto.ts`

- [ ] Criar `services/identity/src/modules/identity/users/application/dto/user.dto.ts`:

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

export class UserDto {
  @ApiProperty({ description: 'ID público do usuário (UUID)' })
  id: string;

  @ApiPropertyOptional({ description: 'Email' })
  email: string | null;

  @ApiPropertyOptional({ description: 'Nome de exibição' })
  displayName?: string;

  @ApiPropertyOptional({ description: 'URL da foto' })
  photoUrl?: string | null;

  @ApiPropertyOptional({ description: 'Bio' })
  bio?: string | null;

  @ApiPropertyOptional({ description: 'Cidade' })
  city?: string | null;

  @ApiPropertyOptional({ description: 'Posição' })
  position?: string | null;

  @ApiPropertyOptional({ description: 'Nível de habilidade (1–5)' })
  skillLevel?: number | null;

  @ApiPropertyOptional({ description: 'Perfil público?' })
  isPublic?: boolean;

  @ApiProperty({ description: 'Data de criação da conta' })
  createdAt: Date;

  static fromUserAndProfile(user: User, profile: PlayerProfile | null): UserDto {
    const dto = new UserDto();
    dto.id = user.id;
    dto.email = user.email;
    dto.createdAt = user.createdAt;

    if (profile) {
      dto.displayName = profile.displayName;
      dto.photoUrl = profile.photoUrl;
      dto.bio = profile.bio;
      dto.city = profile.city;
      dto.position = profile.position;
      dto.skillLevel = profile.skillLevel;
      dto.isPublic = profile.isPublic;
    }

    return dto;
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/application/dto/user.dto.ts && git commit -m "feat(identity): add UserDto"`

---

### Task 20: user.service.ts

**File:** `services/identity/src/modules/identity/users/application/services/user.service.ts`

- [ ] Criar `services/identity/src/modules/identity/users/application/services/user.service.ts`:

```typescript
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  USER_REPOSITORY,
  UserRepositoryInterface,
} from '../../domain/repositories/user-repository.interface';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { UserDto } from '../dto/user.dto';

@Injectable()
export class UserService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepositoryInterface,
  ) {}

  async getProfile(userId: string): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.findProfileById(userId);
    return UserDto.fromUserAndProfile(user, profile);
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
    messagingService: { publishProfileUpdated: (user: unknown, profile: unknown) => Promise<void> },
  ): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.updateProfile(userId, {
      displayName: dto.displayName,
      photoUrl: dto.photoUrl,
      bio: dto.bio,
      city: dto.city,
      position: dto.position as PlayerProfilePosition,
      skillLevel: dto.skillLevel,
      isPublic: dto.isPublic,
    });

    await messagingService.publishProfileUpdated(user, profile);
    return UserDto.fromUserAndProfile(user, profile);
  }

  async getPublicProfile(userId: string): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.findProfileById(userId);
    if (!profile?.isPublic) throw new NotFoundException(`User ${userId} not found`);

    return UserDto.fromUserAndProfile(user, profile);
  }
}

type PlayerProfilePosition = 'goalkeeper' | 'defender' | 'midfielder' | 'forward' | null;
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/application/services/user.service.ts && git commit -m "feat(identity): add UserService"`

---

### Task 21: users.controller.ts

**File:** `services/identity/src/modules/identity/users/infra/controllers/users.controller.ts`

- [ ] Criar `services/identity/src/modules/identity/users/infra/controllers/users.controller.ts`:

```typescript
import { Body, Controller, Get, Param, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { UserService } from '../../application/services/user.service';
import { UserMessagingService } from '../../application/services/user-messaging.service';
import { UpdateProfileDto } from '../../application/dto/update-profile.dto';
import { UserDto } from '../../application/dto/user.dto';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly userService: UserService,
    private readonly messagingService: UserMessagingService,
  ) {}

  @Get('me')
  @Permissions('players:read')
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Obter perfil do usuário autenticado' })
  getMe(@CurrentUser() user: AuthenticatedUser): Promise<UserDto> {
    return this.userService.getProfile(user.id);
  }

  @Put('me/profile')
  @Permissions('players:write')
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Atualizar perfil do usuário autenticado' })
  updateProfile(
    @Body() dto: UpdateProfileDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<UserDto> {
    return this.userService.updateProfile(user.id, dto, this.messagingService);
  }

  @Get(':id/profile')
  @Public()
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Obter perfil público de um usuário' })
  getPublicProfile(@Param('id') id: string): Promise<UserDto> {
    return this.userService.getPublicProfile(id);
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/infra/controllers/users.controller.ts && git commit -m "feat(identity): add UsersController"`

---

### Task 22: user-messaging.service.ts

**File:** `services/identity/src/modules/identity/users/application/services/user-messaging.service.ts`

- [ ] Criar `services/identity/src/modules/identity/users/application/services/user-messaging.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

@Injectable()
export class UserMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishUserRegistered(user: User): Promise<void> {
    await this.messaging.publish(IdentityEvents.USER_REGISTERED, {
      userId: user.id,
      email: user.email,
      createdAt: user.createdAt,
    });
  }

  async publishProfileUpdated(user: User, profile: PlayerProfile): Promise<void> {
    await this.messaging.publish(IdentityEvents.PROFILE_UPDATED, {
      userId: user.id,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
      city: profile.city,
      position: profile.position,
    });
  }

  async publishDeviceTokenUpdated(
    userId: string,
    token: string,
    platform: string,
  ): Promise<void> {
    await this.messaging.publish(IdentityEvents.DEVICE_TOKEN_UPDATED, {
      userId,
      token,
      platform,
    });
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/application/services/user-messaging.service.ts && git commit -m "feat(identity): add UserMessagingService"`

---

### Task 23: users.module.ts

**File:** `services/identity/src/modules/identity/users/users.module.ts`

- [ ] Criar `services/identity/src/modules/identity/users/users.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UserService } from './application/services/user.service';
import { UserMessagingService } from './application/services/user-messaging.service';
import { UsersController } from './infra/controllers/users.controller';
import { DrizzleUserRepository } from './infra/repositories/drizzle-user.repository';
import { USER_REPOSITORY } from './domain/repositories/user-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [UsersController],
  providers: [
    UserService,
    UserMessagingService,
    { provide: USER_REPOSITORY, useClass: DrizzleUserRepository },
  ],
  exports: [UserService, UserMessagingService],
})
export class UsersModule {}
```

- [ ] Commit: `git add services/identity/src/modules/identity/users/users.module.ts && git commit -m "feat(identity): add UsersModule"`

---

### Task 24: login.dto.ts

**File:** `services/identity/src/modules/identity/auth/application/dto/login.dto.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/application/dto/login.dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ description: 'Email do usuário', example: 'jogador@email.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Senha', example: 'senha123' })
  @IsString()
  @MinLength(6)
  password: string;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/auth/application/dto/login.dto.ts && git commit -m "feat(identity): add LoginDto"`

---

### Task 25: register.dto.ts

**File:** `services/identity/src/modules/identity/auth/application/dto/register.dto.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/application/dto/register.dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ description: 'Email do usuário', example: 'jogador@email.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Senha (mínimo 6 caracteres)', example: 'senha123' })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ description: 'Nome de exibição', example: 'João Silva' })
  @IsString()
  @MinLength(2)
  displayName: string;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/auth/application/dto/register.dto.ts && git commit -m "feat(identity): add RegisterDto"`

---

### Task 26: auth.service.spec.ts

**File:** `services/identity/src/modules/identity/auth/application/services/auth.service.spec.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/application/services/auth.service.spec.ts`:

```typescript
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { USER_REPOSITORY } from '../../../users/domain/repositories/user-repository.interface';

jest.mock('bcrypt');
const bcryptMock = bcrypt as jest.Mocked<typeof bcrypt>;

const mockUserRepo = {
  findByEmail: jest.fn(),
  create: jest.fn(),
  findById: jest.fn(),
  findProfileById: jest.fn(),
  updateProfile: jest.fn(),
};

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: USER_REPOSITORY, useValue: mockUserRepo },
        {
          provide: JwtService,
          useValue: { signAsync: jest.fn().mockResolvedValue('mock-access-token') },
        },
        {
          provide: ConfigService,
          useValue: { getOrThrow: jest.fn().mockReturnValue('test-jwt-secret') },
        },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  describe('register', () => {
    it('throws ConflictException when email already in use', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'existing-uuid',
        email: 'test@test.com',
        passwordHash: 'hash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });

      await expect(
        service.register({ email: 'test@test.com', password: '123456', displayName: 'Test' }),
      ).rejects.toThrow(ConflictException);

      expect(mockUserRepo.create).not.toHaveBeenCalled();
    });

    it('creates user and returns accessToken on success', async () => {
      mockUserRepo.findByEmail.mockResolvedValue(null);
      mockUserRepo.create.mockResolvedValue({
        id: 'new-uuid',
        email: 'new@test.com',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      (bcryptMock.hash as jest.Mock).mockResolvedValue('hashed-password');

      const result = await service.register({
        email: 'new@test.com',
        password: 'senha123',
        displayName: 'Novo Jogador',
      });

      expect(result.accessToken).toBe('mock-access-token');
      expect(mockUserRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'new@test.com', displayName: 'Novo Jogador' }),
      );
    });
  });

  describe('login', () => {
    it('throws UnauthorizedException when user not found', async () => {
      mockUserRepo.findByEmail.mockResolvedValue(null);

      await expect(
        service.login({ email: 'notfound@test.com', password: '123456' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when password is wrong', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'uuid-1',
        email: 'test@test.com',
        passwordHash: '$2b$10$wronghash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      (bcryptMock.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.login({ email: 'test@test.com', password: 'wrongpassword' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('returns accessToken when credentials are valid', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'uuid-1',
        email: 'test@test.com',
        passwordHash: '$2b$10$validhash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      mockUserRepo.findProfileById.mockResolvedValue({
        id: 'uuid-1',
        displayName: 'Test User',
        photoUrl: null,
        bio: null,
        city: null,
        position: null,
        skillLevel: null,
        isPublic: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      (bcryptMock.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.login({ email: 'test@test.com', password: 'correta123' });
      expect(result.accessToken).toBe('mock-access-token');
    });
  });
});
```

- [ ] Rodar o teste para confirmar que falha (AuthService não existe ainda):

```bash
cd services/identity && npx jest src/modules/identity/auth/application/services/auth.service.spec.ts --no-coverage 2>&1 | tail -5
```

Esperado: `FAIL` — "Cannot find module './auth.service'"

---

### Task 27: auth.service.ts

**File:** `services/identity/src/modules/identity/auth/application/services/auth.service.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/application/services/auth.service.ts`:

```typescript
import { ConflictException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import {
  USER_REPOSITORY,
  UserRepositoryInterface,
} from '../../../users/domain/repositories/user-repository.interface';
import type { LoginDto } from '../dto/login.dto';
import type { RegisterDto } from '../dto/register.dto';

const DEFAULT_PERMISSIONS = [
  'players:read',
  'players:write',
  'open-games:read',
  'open-games:write',
  'teams:read',
  'teams:write',
  'reviews:read',
  'reviews:write',
  'seasons:read',
  'seasons:write',
  'matches:read',
  'matches:write',
  'rankings:read',
  'notifications:write',
];

@Injectable()
export class AuthService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepositoryInterface,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<{ accessToken: string }> {
    const existing = await this.userRepository.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already in use');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.userRepository.create({
      email: dto.email,
      passwordHash,
      displayName: dto.displayName,
    });

    const payload: AuthenticatedUser = {
      id: user.id,
      name: dto.displayName,
      email: dto.email,
      permissions: DEFAULT_PERMISSIONS,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_SECRET'),
      expiresIn: '7d',
    });

    return { accessToken };
  }

  async login(dto: LoginDto): Promise<{ accessToken: string }> {
    const user = await this.userRepository.findByEmail(dto.email);
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials');

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) throw new UnauthorizedException('Invalid credentials');

    const profile = await this.userRepository.findProfileById(user.id);

    const payload: AuthenticatedUser = {
      id: user.id,
      name: profile?.displayName ?? user.email ?? user.id,
      email: user.email ?? '',
      permissions: DEFAULT_PERMISSIONS,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_SECRET'),
      expiresIn: '7d',
    });

    return { accessToken };
  }

  async refresh(token: string): Promise<{ accessToken: string }> {
    let payload: AuthenticatedUser;
    try {
      payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
        ignoreExpiration: true,
      });
    } catch {
      throw new UnauthorizedException('Invalid token');
    }

    const newToken = await this.jwtService.signAsync(
      { id: payload.id, name: payload.name, email: payload.email, permissions: payload.permissions },
      { secret: this.config.getOrThrow<string>('JWT_SECRET'), expiresIn: '7d' },
    );

    return { accessToken: newToken };
  }
}
```

- [ ] Rodar o teste para confirmar que passa:

```bash
cd services/identity && npx jest src/modules/identity/auth/application/services/auth.service.spec.ts --no-coverage 2>&1 | tail -10
```

Esperado: `PASS` — 4 testes passando.

- [ ] Commit:

```bash
cd services/identity && git add src/modules/identity/auth/ && git commit -m "feat(identity): add AuthService with TDD (register/login/refresh)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 28: auth.controller.ts

**File:** `services/identity/src/modules/identity/auth/infra/controllers/auth.controller.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/infra/controllers/auth.controller.ts`:

```typescript
import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from '@shared/infra/decorators/public.decorator';
import { AuthService } from '../../application/services/auth.service';
import { LoginDto } from '../../application/dto/login.dto';
import { RegisterDto } from '../../application/dto/register.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Public()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Registrar novo usuário' })
  register(@Body() dto: RegisterDto): Promise<{ accessToken: string }> {
    return this.authService.register(dto);
  }

  @Post('login')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Autenticar usuário' })
  login(@Body() dto: LoginDto): Promise<{ accessToken: string }> {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Renovar token de acesso' })
  refresh(@Body() body: { token: string }): Promise<{ accessToken: string }> {
    return this.authService.refresh(body.token);
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/auth/infra/controllers/auth.controller.ts && git commit -m "feat(identity): add AuthController"`

---

### Task 29: auth.module.ts

**File:** `services/identity/src/modules/identity/auth/auth.module.ts`

- [ ] Criar `services/identity/src/modules/identity/auth/auth.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UsersModule } from '../users/users.module';
import { AuthService } from './application/services/auth.service';
import { AuthController } from './infra/controllers/auth.controller';

@Module({
  imports: [SharedModule, UsersModule],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
```

- [ ] Commit: `git add services/identity/src/modules/identity/auth/auth.module.ts && git commit -m "feat(identity): add AuthModule"`

---

### Task 30: device-token.entity.ts

**File:** `services/identity/src/modules/identity/device-tokens/domain/models/device-token.entity.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/domain/models/device-token.entity.ts`:

```typescript
export class DeviceToken {
  userId: string;  // users.external_id
  token: string;
  platform: 'ios' | 'android';
  isActive: boolean;
  updatedAt: Date;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/device-tokens/domain/models/device-token.entity.ts && git commit -m "feat(identity): add DeviceToken entity"`

---

### Task 31: device-token-repository.interface.ts

**File:** `services/identity/src/modules/identity/device-tokens/domain/repositories/device-token-repository.interface.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/domain/repositories/device-token-repository.interface.ts`:

```typescript
import type { DeviceToken } from '../models/device-token.entity';

export const DEVICE_TOKEN_REPOSITORY = 'DEVICE_TOKEN_REPOSITORY';

export interface DeviceTokenRepositoryInterface {
  upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<DeviceToken>;
  findByUserId(userId: string): Promise<DeviceToken[]>;
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/device-tokens/domain/repositories/device-token-repository.interface.ts && git commit -m "feat(identity): add DeviceTokenRepositoryInterface"`

---

### Task 32: device-token.schema.ts

**File:** `services/identity/src/modules/identity/device-tokens/infra/database/schemas/device-token.schema.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/infra/database/schemas/device-token.schema.ts`:

```typescript
import {
  pgTable,
  bigserial,
  bigint,
  text,
  boolean,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { users } from '../../../users/infra/database/schemas/user.schema';

export const deviceTokens = pgTable(
  'device_tokens',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    userId: bigint('user_id', { mode: 'number' })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    token: text('token').notNull(),
    platform: text('platform').notNull(),
    isActive: boolean('is_active').notNull().default(true),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('uq_device_tokens_user_platform').on(table.userId, table.platform),
  ],
);

export type DeviceTokenRow = typeof deviceTokens.$inferSelect;
```

- [ ] Commit: `git add services/identity/src/modules/identity/device-tokens/infra/database/schemas/device-token.schema.ts && git commit -m "feat(identity): add device_tokens Drizzle schema"`

---

### Task 33: drizzle-device-token.repository.ts

**File:** `services/identity/src/modules/identity/device-tokens/infra/repositories/drizzle-device-token.repository.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/infra/repositories/drizzle-device-token.repository.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { DeviceTokenRepositoryInterface } from '../../domain/repositories/device-token-repository.interface';
import type { DeviceToken } from '../../domain/models/device-token.entity';
import { deviceTokens } from '../database/schemas/device-token.schema';
import { users } from '../../../users/infra/database/schemas/user.schema';

@Injectable()
export class DrizzleDeviceTokenRepository implements DeviceTokenRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<DeviceToken> {
    const [userRow] = await this.drizzle.db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.externalId, userId))
      .limit(1);

    const [row] = await this.drizzle.db
      .insert(deviceTokens)
      .values({ userId: userRow.id, token, platform, isActive: true, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: [deviceTokens.userId, deviceTokens.platform],
        set: { token, isActive: true, updatedAt: new Date() },
      })
      .returning();

    return { userId, token: row.token, platform: row.platform as 'ios' | 'android', isActive: row.isActive, updatedAt: row.updatedAt };
  }

  async findByUserId(userId: string): Promise<DeviceToken[]> {
    const rows = await this.drizzle.db
      .select({ dt: deviceTokens })
      .from(deviceTokens)
      .innerJoin(users, eq(users.id, deviceTokens.userId))
      .where(and(eq(users.externalId, userId), eq(deviceTokens.isActive, true)));

    return rows.map((r) => ({
      userId,
      token: r.dt.token,
      platform: r.dt.platform as 'ios' | 'android',
      isActive: r.dt.isActive,
      updatedAt: r.dt.updatedAt,
    }));
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/device-tokens/infra/repositories/drizzle-device-token.repository.ts && git commit -m "feat(identity): add DrizzleDeviceTokenRepository"`

---

### Task 34: device-token.service.ts

**File:** `services/identity/src/modules/identity/device-tokens/application/services/device-token.service.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/application/services/device-token.service.ts`:

```typescript
import { Inject, Injectable } from '@nestjs/common';
import {
  DEVICE_TOKEN_REPOSITORY,
  DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import { UserMessagingService } from '../../../users/application/services/user-messaging.service';

@Injectable()
export class DeviceTokenService {
  constructor(
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly deviceTokenRepository: DeviceTokenRepositoryInterface,
    private readonly userMessaging: UserMessagingService,
  ) {}

  async upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<void> {
    await this.deviceTokenRepository.upsert(userId, token, platform);
    await this.userMessaging.publishDeviceTokenUpdated(userId, token, platform);
  }
}
```

- [ ] Commit: `git add services/identity/src/modules/identity/device-tokens/application/services/device-token.service.ts && git commit -m "feat(identity): add DeviceTokenService"`

---

### Task 35: device-tokens.module.ts

**File:** `services/identity/src/modules/identity/device-tokens/device-tokens.module.ts`

- [ ] Criar `services/identity/src/modules/identity/device-tokens/device-tokens.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UsersModule } from '../users/users.module';
import { DeviceTokenService } from './application/services/device-token.service';
import { DrizzleDeviceTokenRepository } from './infra/repositories/drizzle-device-token.repository';
import { DEVICE_TOKEN_REPOSITORY } from './domain/repositories/device-token-repository.interface';

@Module({
  imports: [SharedModule, UsersModule],
  providers: [
    DeviceTokenService,
    { provide: DEVICE_TOKEN_REPOSITORY, useClass: DrizzleDeviceTokenRepository },
  ],
  exports: [DeviceTokenService],
})
export class DeviceTokensModule {}
```

- [ ] Verificar build completo do serviço:

```bash
cd services/identity && npm run build 2>&1 | tail -20
```

Esperado: `Successfully compiled` — sem erros TypeScript.

- [ ] Rodar todos os testes:

```bash
cd services/identity && npx jest --no-coverage 2>&1 | tail -10
```

Esperado: `PASS` — todos os testes passando.

- [ ] Commit:

```bash
cd services/identity && git add src/modules/identity/device-tokens/ && git commit -m "feat(identity): add DeviceTokensModule — completes identity service implementation"
```

---

### Task 36: Gerar migration Drizzle

**Pré-requisito:** Banco `bolanarededb_identity` criado e `DATABASE_URL` configurado no `.env`.

- [ ] Copiar `.env.example` para `.env` e preencher `DATABASE_URL`:

```bash
cd services/identity && cp .env.example .env
# Editar DATABASE_URL se necessário
```

- [ ] Gerar migration:

```bash
cd services/identity && npm run db:generate
```

Esperado: Pasta `drizzle/` criada com arquivo `0000_*.sql` contendo `CREATE TABLE users`, `CREATE TABLE credentials`, `CREATE TABLE player_profiles`, `CREATE TABLE device_tokens`.

- [ ] Commit:

```bash
cd services/identity && git add drizzle/ && git commit -m "chore(identity): generate initial Drizzle migrations"
```

---

### Task 37: Aplicar migration e smoke test

- [ ] Aplicar migrations:

```bash
cd services/identity && npm run db:migrate
```

Esperado: `All migrations applied` — 4 tabelas criadas no banco.

- [ ] Subir o serviço em modo dev:

```bash
cd services/identity && npm run start:dev
```

- [ ] Verificar health via Swagger (abrir no browser ou curl):

```bash
curl http://localhost:4001/docs-json | head -5
```

Esperado: JSON do Swagger com `"title":"BolaNaRede API"`.

- [ ] Testar registro via API:

```bash
curl -s -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"senha123","displayName":"Teste"}' \
  | jq '.accessToken' 2>/dev/null || echo "Reponse received (jq not available)"
```

Esperado: `accessToken` no response.

- [ ] Commit final:

```bash
git add services/identity/.env.example && git commit -m "feat(identity): identity service fully functional — auth, users, device-tokens"
```

---

## Verificação Final

**Checklist de conclusão do identity-service:**
- [ ] `npm run build` passa sem erros
- [ ] `npx jest --no-coverage` — todos os testes passando
- [ ] `npm run db:migrate` — 4 tabelas criadas no banco
- [ ] `POST /v1/auth/register` retorna `accessToken`
- [ ] `POST /v1/auth/login` retorna `accessToken`
- [ ] `GET /v1/users/me` com bearer token retorna perfil do usuário
- [ ] Nenhum `console.log`, nenhum `any` implícito
- [ ] Atualizar `docs/plans/_status.md`: `identity | ✅ DONE | 37/37`
