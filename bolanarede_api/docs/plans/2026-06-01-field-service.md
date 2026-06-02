# Field Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Pré-requisito:** `docs/plans/2026-05-27-team-service.md` deve estar 100% concluído e mergeado em `develop`.

**Goal:** Criar o `field-service` (porta 4003) com registro de campos, gestão de quadras, controle de disponibilidade, reservas manuais e planos recorrentes semanais — com busca geoespacial via PostGIS.

**Architecture:** NestJS 11 com três sub-módulos de domínio (`fields`, `reservations`, `plans`) compartilhando um único banco PostgreSQL + PostGIS. O serviço publica 4 eventos (`REGISTERED`, `RESERVATION_CONFIRMED`, `RESERVATION_CANCELLED`, `PLAN_SLOT_RELEASED`) e **não consome eventos de outros serviços**. A coluna `location geometry(POINT,4326)` é adicionada manualmente na migration (fora do schema Drizzle) e consultada via templates `sql` para busca por raio.

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, PostgreSQL 17 + PostGIS 3.5, @golevelup/nestjs-rabbitmq, class-validator, @nestjs/swagger

---

## File Map

```
services/field/
├── .env.example                                                        ← Task 1
├── drizzle.config.ts                                                   ← Task 2
├── nest-cli.json                                                       ← Task 3
├── package.json                                                        ← Task 4
├── tsconfig.json                                                       ← Task 5
├── tsconfig.build.json                                                 ← Task 5
├── src/
│   ├── main.ts                                                         ← Task 30
│   ├── app.module.ts                                                   ← Task 30
│   └── modules/
│       └── field/
│           ├── field.module.ts                                         ← Task 29
│           ├── fields/
│           │   ├── domain/
│           │   │   ├── models/
│           │   │   │   ├── field.entity.ts                             ← Task 6
│           │   │   │   ├── field-court.entity.ts                       ← Task 6
│           │   │   │   └── availability-slot.entity.ts                 ← Task 6
│           │   │   └── repositories/
│           │   │       └── field-repository.interface.ts               ← Task 13
│           │   ├── application/
│           │   │   ├── dto/
│           │   │   │   ├── create-field.dto.ts                         ← Task 19
│           │   │   │   ├── create-court.dto.ts                         ← Task 19
│           │   │   │   ├── set-availability.dto.ts                     ← Task 19
│           │   │   │   ├── search-fields.dto.ts                        ← Task 19
│           │   │   │   ├── field.dto.ts                                ← Task 19
│           │   │   │   ├── field-court.dto.ts                          ← Task 19
│           │   │   │   └── field-availability.dto.ts                   ← Task 20
│           │   │   └── services/
│           │   │       ├── field.service.spec.ts                       ← Task 22
│           │   │       ├── field.service.ts                            ← Task 22
│           │   │       └── availability.service.spec.ts                ← Task 23
│           │   │       └── availability.service.ts                     ← Task 23
│           │   ├── infra/
│           │   │   ├── controllers/
│           │   │   │   └── fields.controller.ts                        ← Task 27
│           │   │   └── database/
│           │   │       ├── schemas/
│           │   │       │   ├── field.schema.ts                         ← Task 9
│           │   │       │   ├── field-court.schema.ts                   ← Task 9
│           │   │       │   └── availability-slot.schema.ts             ← Task 10
│           │   │       └── repositories/
│           │   │           └── drizzle-field.repository.ts             ← Task 16
│           │   └── fields.module.ts                                    ← Task 29
│           ├── reservations/
│           │   ├── domain/
│           │   │   ├── models/
│           │   │   │   └── reservation.entity.ts                       ← Task 7
│           │   │   └── repositories/
│           │   │       └── reservation-repository.interface.ts         ← Task 14
│           │   ├── application/
│           │   │   ├── dto/
│           │   │   │   ├── create-reservation.dto.ts                   ← Task 20
│           │   │   │   └── reservation.dto.ts                          ← Task 20
│           │   │   └── services/
│           │   │       ├── reservation.service.spec.ts                 ← Task 24
│           │   │       └── reservation.service.ts                      ← Task 24
│           │   ├── infra/
│           │   │   ├── controllers/
│           │   │   │   └── reservations.controller.ts                  ← Task 28
│           │   │   └── database/
│           │   │       ├── schemas/
│           │   │       │   └── reservation.schema.ts                   ← Task 11
│           │   │       └── repositories/
│           │   │           └── drizzle-reservation.repository.ts       ← Task 17
│           │   └── reservations.module.ts                              ← Task 29
│           └── plans/
│               ├── domain/
│               │   ├── models/
│               │   │   ├── recurring-plan.entity.ts                    ← Task 8
│               │   │   └── recurring-plan-slot.entity.ts               ← Task 8
│               │   └── repositories/
│               │       └── recurring-plan-repository.interface.ts      ← Task 15
│               ├── application/
│               │   ├── dto/
│               │   │   ├── create-recurring-plan.dto.ts                ← Task 21
│               │   │   └── recurring-plan.dto.ts                       ← Task 21
│               │   └── services/
│               │       ├── recurring-plan.service.spec.ts              ← Task 25
│               │       └── recurring-plan.service.ts                   ← Task 25
│               ├── infra/
│               │   ├── controllers/
│               │   │   └── plans.controller.ts                         ← Task 28
│               │   └── database/
│               │       ├── schemas/
│               │       │   ├── recurring-plan.schema.ts                ← Task 12
│               │       │   └── recurring-plan-slot.schema.ts           ← Task 12
│               │       └── repositories/
│               │           └── drizzle-recurring-plan.repository.ts    ← Task 18
│               └── plans.module.ts                                     ← Task 29
├── field-messaging.service.ts  (em fields/application/services/)       ← Task 26
├── drizzle/                                                            ← Task 31
├── scripts/
│   └── migrate.js                                                      ← Task 32
├── Dockerfile                                                          ← Task 32
└── docker-entrypoint.sh                                               ← Task 32

docker-compose.yml (root)                                              ← Task 33
docs/plans/_status.md                                                  ← Task 34
```

---

## Contexto de Desenvolvimento

O worktree fica em `../worktrees/feature-field-service/bolanarede_api/`.
Todos os comandos abaixo devem ser executados de dentro de `services/field/` salvo indicação contrária.

---

### Task 1: `.env.example`

**Files:**
- Create: `services/field/.env.example`

- [ ] **Step 1: Criar .env.example**

```
PORT=4003
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_field
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

Salve como `.env.example` e copie para `.env` local.

- [ ] **Step 2: Commit**

```bash
git add services/field/.env.example
git commit -m "chore(field): add .env.example"
```

---

### Task 2: `drizzle.config.ts`

**Files:**
- Create: `services/field/drizzle.config.ts`

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
git add services/field/drizzle.config.ts
git commit -m "chore(field): add drizzle.config.ts"
```

---

### Task 3: `nest-cli.json`

**Files:**
- Create: `services/field/nest-cli.json`

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
git add services/field/nest-cli.json
git commit -m "chore(field): add nest-cli.json"
```

---

### Task 4: `package.json`

**Files:**
- Create: `services/field/package.json`

- [ ] **Step 1: Criar package.json**

```json
{
  "name": "field-service",
  "version": "0.1.0",
  "private": true,
  "license": "UNLICENSED",
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
    "transform": {
      "^.+\\.(t|j)s$": "ts-jest"
    },
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
cd services/field && npm install
```

Expected: Resolves packages, cria `node_modules/` e `package-lock.json`.

- [ ] **Step 3: Commit**

```bash
git add services/field/package.json services/field/package-lock.json
git commit -m "chore(field): add package.json and install dependencies"
```

---

### Task 5: `tsconfig.json` + `tsconfig.build.json`

**Files:**
- Create: `services/field/tsconfig.json`
- Create: `services/field/tsconfig.build.json`

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
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/tsconfig.json services/field/tsconfig.build.json
git commit -m "chore(field): add tsconfig files"
```

---

### Task 6: Domain Entities — Field, FieldCourt, AvailabilitySlot

**Files:**
- Create: `services/field/src/modules/field/fields/domain/models/field.entity.ts`
- Create: `services/field/src/modules/field/fields/domain/models/field-court.entity.ts`
- Create: `services/field/src/modules/field/fields/domain/models/availability-slot.entity.ts`

- [ ] **Step 1: Criar field.entity.ts**

```typescript
export class Field {
  id!: string;           // UUID (external_id)
  name!: string;
  description!: string | null;
  city!: string;
  address!: string;
  lat!: number;
  lng!: number;
  ownerUserId!: string;  // UUID do dono (text, sem FK)
  isActive!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
```

- [ ] **Step 2: Criar field-court.entity.ts**

```typescript
export type CourtType = 'society' | 'futsal' | 'grass' | 'synthetic';

export class FieldCourt {
  id!: string;           // UUID (external_id)
  fieldId!: string;      // UUID do field pai
  name!: string;
  type!: CourtType;
  maxPlayers!: number;
  isActive!: boolean;
}
```

- [ ] **Step 3: Criar availability-slot.entity.ts**

```typescript
// dayOfWeek: 0=Domingo, 1=Segunda, ..., 6=Sábado
// startTime / endTime: string no formato "HH:MM" (e.g. "08:00", "09:00")
export class AvailabilitySlot {
  id!: bigint;
  courtId!: bigint;
  dayOfWeek!: number;
  startTime!: string;
  endTime!: string;
  isAvailable!: boolean;
}
```

- [ ] **Step 4: Commit**

```bash
git add services/field/src/modules/field/fields/domain/
git commit -m "feat(field): add Field, FieldCourt, AvailabilitySlot domain entities"
```

---

### Task 7: Domain Entity — Reservation

**Files:**
- Create: `services/field/src/modules/field/reservations/domain/models/reservation.entity.ts`

- [ ] **Step 1: Criar reservation.entity.ts**

```typescript
export type ReservationChannel = 'app' | 'manual' | 'phone';
export type ReservationStatus = 'confirmed' | 'cancelled';

export class Reservation {
  id!: string;             // UUID (external_id)
  courtId!: string;        // UUID da quadra
  fieldId!: string;        // UUID do campo (desnormalizado para queries)
  playerUserId!: string | null;  // null para reservas manual/phone
  channel!: ReservationChannel;
  startsAt!: Date;
  endsAt!: Date;
  status!: ReservationStatus;
  notes!: string | null;
  createdAt!: Date;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/reservations/domain/
git commit -m "feat(field): add Reservation domain entity"
```

---

### Task 8: Domain Entities — RecurringPlan + RecurringPlanSlot

**Files:**
- Create: `services/field/src/modules/field/plans/domain/models/recurring-plan.entity.ts`
- Create: `services/field/src/modules/field/plans/domain/models/recurring-plan-slot.entity.ts`

- [ ] **Step 1: Criar recurring-plan.entity.ts**

```typescript
// Um plano fixa um horário semanal em uma quadra.
// dayOfWeek: 0=Dom, 1=Seg, ..., 6=Sáb
// startTime / endTime: "HH:MM"
// planEndsAt null = plano indefinido
export class RecurringPlan {
  id!: string;              // UUID (external_id)
  courtId!: string;         // UUID da quadra
  fieldId!: string;         // UUID do campo (desnormalizado)
  playerUserId!: string | null;
  dayOfWeek!: number;
  startTime!: string;
  endTime!: string;
  planStartsAt!: Date;
  planEndsAt!: Date | null;
  isActive!: boolean;
  createdAt!: Date;
}
```

- [ ] **Step 2: Criar recurring-plan-slot.entity.ts**

```typescript
export type SlotStatus = 'active' | 'released' | 'cancelled';

// Representa uma instância semanal de um RecurringPlan.
// released = dono liberou o horário para reserva avulsa
export class RecurringPlanSlot {
  id!: string;              // UUID (external_id)
  planId!: string;          // UUID do plano pai
  fieldId!: string;         // UUID do campo (para o evento publicado)
  slotDate!: Date;          // Data específica da semana
  status!: SlotStatus;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/plans/domain/
git commit -m "feat(field): add RecurringPlan and RecurringPlanSlot domain entities"
```

---

### Task 9: Drizzle Schemas — fields + field_courts

**Files:**
- Create: `services/field/src/modules/field/fields/infra/database/schemas/field.schema.ts`
- Create: `services/field/src/modules/field/fields/infra/database/schemas/field-court.schema.ts`

- [ ] **Step 1: Criar field.schema.ts**

```typescript
import { pgTable, bigserial, uuid, text, boolean, doublePrecision, timestamp } from 'drizzle-orm/pg-core';

export const fields = pgTable('fields', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  name: text('name').notNull(),
  description: text('description'),
  city: text('city').notNull(),
  address: text('address').notNull(),
  lat: doublePrecision('lat').notNull(),
  lng: doublePrecision('lng').notNull(),
  // Coluna `location geometry(POINT,4326)` adicionada manualmente na migration — não declarada aqui
  ownerUserId: text('owner_user_id').notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type FieldRow = typeof fields.$inferSelect;
export type NewFieldRow = typeof fields.$inferInsert;
```

- [ ] **Step 2: Criar field-court.schema.ts**

```typescript
import { pgTable, bigserial, uuid, bigint, text, smallint, boolean } from 'drizzle-orm/pg-core';
import { fields } from './field.schema';

export const fieldCourts = pgTable('field_courts', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  fieldId: bigint('field_id', { mode: 'bigint' }).notNull().references(() => fields.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  type: text('type').notNull(),  // 'society' | 'futsal' | 'grass' | 'synthetic'
  maxPlayers: smallint('max_players').default(10).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
});

export type FieldCourtRow = typeof fieldCourts.$inferSelect;
export type NewFieldCourtRow = typeof fieldCourts.$inferInsert;
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/fields/infra/database/schemas/
git commit -m "feat(field): add Drizzle schemas for fields and field_courts"
```

---

### Task 10: Drizzle Schema — availability_slots

**Files:**
- Create: `services/field/src/modules/field/fields/infra/database/schemas/availability-slot.schema.ts`

- [ ] **Step 1: Criar availability-slot.schema.ts**

```typescript
import { pgTable, bigserial, bigint, smallint, text, boolean, index } from 'drizzle-orm/pg-core';
import { fieldCourts } from './field-court.schema';

export const availabilitySlots = pgTable('availability_slots', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  courtId: bigint('court_id', { mode: 'bigint' }).notNull().references(() => fieldCourts.id, { onDelete: 'cascade' }),
  dayOfWeek: smallint('day_of_week').notNull(),  // 0=Dom ... 6=Sáb
  startTime: text('start_time').notNull(),        // "HH:MM"
  endTime: text('end_time').notNull(),            // "HH:MM"
  isAvailable: boolean('is_available').default(true).notNull(),
}, (t) => ({
  idxCourtDay: index('idx_availability_slots_court_day').on(t.courtId, t.dayOfWeek),
}));

export type AvailabilitySlotRow = typeof availabilitySlots.$inferSelect;
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/fields/infra/database/schemas/availability-slot.schema.ts
git commit -m "feat(field): add Drizzle schema for availability_slots"
```

---

### Task 11: Drizzle Schema — reservations

**Files:**
- Create: `services/field/src/modules/field/reservations/infra/database/schemas/reservation.schema.ts`

- [ ] **Step 1: Criar reservation.schema.ts**

```typescript
import { pgTable, bigserial, uuid, bigint, text, timestamp, index } from 'drizzle-orm/pg-core';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

export const reservations = pgTable('reservations', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  courtId: bigint('court_id', { mode: 'bigint' }).notNull().references(() => fieldCourts.id, { onDelete: 'cascade' }),
  fieldId: bigint('field_id', { mode: 'bigint' }).notNull().references(() => fields.id, { onDelete: 'cascade' }),
  playerUserId: text('player_user_id'),            // null para manual/phone
  channel: text('channel').notNull(),              // 'app' | 'manual' | 'phone'
  startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
  endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
  status: text('status').default('confirmed').notNull(), // 'confirmed' | 'cancelled'
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => ({
  idxCourtStatus: index('idx_reservations_court_status').on(t.courtId, t.status),
  idxFieldId: index('idx_reservations_field_id').on(t.fieldId),
}));

export type ReservationRow = typeof reservations.$inferSelect;
export type NewReservationRow = typeof reservations.$inferInsert;
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/reservations/infra/database/schemas/
git commit -m "feat(field): add Drizzle schema for reservations"
```

---

### Task 12: Drizzle Schemas — recurring_plans + recurring_plan_slots

**Files:**
- Create: `services/field/src/modules/field/plans/infra/database/schemas/recurring-plan.schema.ts`
- Create: `services/field/src/modules/field/plans/infra/database/schemas/recurring-plan-slot.schema.ts`

- [ ] **Step 1: Criar recurring-plan.schema.ts**

```typescript
import { pgTable, bigserial, uuid, bigint, text, smallint, boolean, timestamp, index } from 'drizzle-orm/pg-core';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

export const recurringPlans = pgTable('recurring_plans', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  courtId: bigint('court_id', { mode: 'bigint' }).notNull().references(() => fieldCourts.id, { onDelete: 'cascade' }),
  fieldId: bigint('field_id', { mode: 'bigint' }).notNull().references(() => fields.id, { onDelete: 'cascade' }),
  playerUserId: text('player_user_id'),
  dayOfWeek: smallint('day_of_week').notNull(),
  startTime: text('start_time').notNull(),
  endTime: text('end_time').notNull(),
  planStartsAt: timestamp('plan_starts_at', { withTimezone: true }).notNull(),
  planEndsAt: timestamp('plan_ends_at', { withTimezone: true }),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => ({
  idxCourtActive: index('idx_recurring_plans_court_active').on(t.courtId, t.isActive),
}));

export type RecurringPlanRow = typeof recurringPlans.$inferSelect;
export type NewRecurringPlanRow = typeof recurringPlans.$inferInsert;
```

- [ ] **Step 2: Criar recurring-plan-slot.schema.ts**

```typescript
import { pgTable, bigserial, uuid, bigint, text, timestamp, index } from 'drizzle-orm/pg-core';
import { recurringPlans } from './recurring-plan.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

export const recurringPlanSlots = pgTable('recurring_plan_slots', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  planId: bigint('plan_id', { mode: 'bigint' }).notNull().references(() => recurringPlans.id, { onDelete: 'cascade' }),
  fieldId: bigint('field_id', { mode: 'bigint' }).notNull().references(() => fields.id, { onDelete: 'cascade' }),
  slotDate: timestamp('slot_date', { withTimezone: true }).notNull(),
  status: text('status').default('active').notNull(), // 'active' | 'released' | 'cancelled'
}, (t) => ({
  idxPlanDate: index('idx_recurring_plan_slots_plan_date').on(t.planId, t.slotDate),
  idxFieldDate: index('idx_recurring_plan_slots_field_date').on(t.fieldId, t.slotDate),
}));

export type RecurringPlanSlotRow = typeof recurringPlanSlots.$inferSelect;
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/plans/infra/database/schemas/
git commit -m "feat(field): add Drizzle schemas for recurring_plans and recurring_plan_slots"
```

---

### Task 13: Repository Interface — Field

**Files:**
- Create: `services/field/src/modules/field/fields/domain/repositories/field-repository.interface.ts`

- [ ] **Step 1: Criar field-repository.interface.ts**

```typescript
import type { Field } from '../models/field.entity';
import type { FieldCourt } from '../models/field-court.entity';
import type { AvailabilitySlot } from '../models/availability-slot.entity';

export const FIELD_REPOSITORY = Symbol('FIELD_REPOSITORY');

export interface CreateFieldData {
  name: string;
  description?: string;
  city: string;
  address: string;
  lat: number;
  lng: number;
  ownerUserId: string;
}

export interface CreateCourtData {
  fieldExternalId: string;
  name: string;
  type: string;
  maxPlayers: number;
}

export interface AvailabilitySlotData {
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  isAvailable: boolean;
}

export interface SearchFieldsParams {
  city?: string;
  lat?: number;
  lng?: number;
  radiusKm?: number;
}

export interface FieldRepositoryInterface {
  create(data: CreateFieldData): Promise<Field>;
  findById(externalId: string): Promise<Field | null>;
  findNearby(params: SearchFieldsParams): Promise<Field[]>;
  addCourt(data: CreateCourtData): Promise<FieldCourt>;
  findCourt(courtExternalId: string): Promise<FieldCourt | null>;
  findCourts(fieldExternalId: string): Promise<FieldCourt[]>;
  setAvailabilitySlots(courtExternalId: string, slots: AvailabilitySlotData[]): Promise<void>;
  getAvailabilitySlots(courtExternalId: string): Promise<AvailabilitySlot[]>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/fields/domain/repositories/
git commit -m "feat(field): add FieldRepositoryInterface"
```

---

### Task 14: Repository Interface — Reservation

**Files:**
- Create: `services/field/src/modules/field/reservations/domain/repositories/reservation-repository.interface.ts`

- [ ] **Step 1: Criar reservation-repository.interface.ts**

```typescript
import type { Reservation, ReservationChannel } from '../models/reservation.entity';

export const RESERVATION_REPOSITORY = Symbol('RESERVATION_REPOSITORY');

export interface CreateReservationData {
  courtExternalId: string;
  fieldExternalId: string;
  playerUserId?: string;
  channel: ReservationChannel;
  startsAt: Date;
  endsAt: Date;
  notes?: string;
}

export interface ReservationRepositoryInterface {
  create(data: CreateReservationData): Promise<Reservation>;
  findById(externalId: string): Promise<Reservation | null>;
  findByField(fieldExternalId: string, page: number, limit: number): Promise<Reservation[]>;
  findOverlapping(courtExternalId: string, startsAt: Date, endsAt: Date): Promise<Reservation[]>;
  cancel(externalId: string): Promise<Reservation>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/reservations/domain/repositories/
git commit -m "feat(field): add ReservationRepositoryInterface"
```

---

### Task 15: Repository Interface — RecurringPlan

**Files:**
- Create: `services/field/src/modules/field/plans/domain/repositories/recurring-plan-repository.interface.ts`

- [ ] **Step 1: Criar recurring-plan-repository.interface.ts**

```typescript
import type { RecurringPlan } from '../models/recurring-plan.entity';
import type { RecurringPlanSlot } from '../models/recurring-plan-slot.entity';

export const RECURRING_PLAN_REPOSITORY = Symbol('RECURRING_PLAN_REPOSITORY');

export interface CreateRecurringPlanData {
  courtExternalId: string;
  fieldExternalId: string;
  playerUserId?: string;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  planStartsAt: Date;
  planEndsAt?: Date;
}

export interface RecurringPlanRepositoryInterface {
  create(data: CreateRecurringPlanData): Promise<RecurringPlan>;
  findById(externalId: string): Promise<RecurringPlan | null>;
  findByField(fieldExternalId: string): Promise<RecurringPlan[]>;
  deactivate(externalId: string): Promise<void>;
  createSlot(planExternalId: string, slotDate: Date): Promise<RecurringPlanSlot>;
  findSlot(slotExternalId: string): Promise<RecurringPlanSlot | null>;
  releaseSlot(slotExternalId: string): Promise<RecurringPlanSlot>;
  findActiveSlotsByField(fieldExternalId: string, date: Date): Promise<RecurringPlanSlot[]>;
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/plans/domain/repositories/
git commit -m "feat(field): add RecurringPlanRepositoryInterface"
```

---

### Task 16: Drizzle Repository — Field

**Files:**
- Create: `services/field/src/modules/field/fields/infra/database/repositories/drizzle-field.repository.ts`

- [ ] **Step 1: Criar drizzle-field.repository.ts**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateFieldData,
  CreateCourtData,
  AvailabilitySlotData,
  SearchFieldsParams,
  FieldRepositoryInterface,
} from '../../domain/repositories/field-repository.interface';
import type { Field } from '../../domain/models/field.entity';
import type { FieldCourt, CourtType } from '../../domain/models/field-court.entity';
import type { AvailabilitySlot } from '../../domain/models/availability-slot.entity';
import { fields, type FieldRow } from '../schemas/field.schema';
import { fieldCourts, type FieldCourtRow } from '../schemas/field-court.schema';
import { availabilitySlots, type AvailabilitySlotRow } from '../schemas/availability-slot.schema';

@Injectable()
export class DrizzleFieldRepository implements FieldRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateFieldData): Promise<Field> {
    const [row] = await this.drizzle.db
      .insert(fields)
      .values({
        name: data.name,
        description: data.description ?? null,
        city: data.city,
        address: data.address,
        lat: data.lat,
        lng: data.lng,
        ownerUserId: data.ownerUserId,
      })
      .returning();

    // Atualiza a coluna geometry (adicionada manualmente na migration)
    await this.drizzle.db.execute(sql`
      UPDATE fields
      SET location = ST_SetSRID(ST_MakePoint(${data.lng}, ${data.lat}), 4326)
      WHERE id = ${row.id}
    `);

    return this.toField(row);
  }

  async findById(externalId: string): Promise<Field | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(fields)
      .where(eq(fields.externalId, externalId))
      .limit(1);
    return row ? this.toField(row) : null;
  }

  async findNearby(params: SearchFieldsParams): Promise<Field[]> {
    const { city, lat, lng, radiusKm } = params;
    const hasGeo = lat != null && lng != null && radiusKm != null;

    const rows = await this.drizzle.db
      .select()
      .from(fields)
      .where(
        and(
          eq(fields.isActive, true),
          city ? eq(fields.city, city) : undefined,
          hasGeo
            ? sql`ST_DWithin(
                location::geography,
                ST_SetSRID(ST_MakePoint(${lng!}, ${lat!}), 4326)::geography,
                ${radiusKm! * 1000}
              )`
            : undefined,
        ),
      )
      .orderBy(
        hasGeo
          ? sql`ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(${lng!}, ${lat!}), 4326)::geography)`
          : fields.createdAt,
      )
      .limit(50);

    return rows.map(this.toField);
  }

  async addCourt(data: CreateCourtData): Promise<FieldCourt> {
    const [fieldRow] = await this.drizzle.db
      .select()
      .from(fields)
      .where(eq(fields.externalId, data.fieldExternalId))
      .limit(1);

    if (!fieldRow) {
      throw new NotFoundException(`Field ${data.fieldExternalId} not found`);
    }

    const [row] = await this.drizzle.db
      .insert(fieldCourts)
      .values({
        fieldId: fieldRow.id,
        name: data.name,
        type: data.type,
        maxPlayers: data.maxPlayers,
      })
      .returning();

    return this.toCourt(row, fieldRow.externalId);
  }

  async findCourt(courtExternalId: string): Promise<FieldCourt | null> {
    const [row] = await this.drizzle.db
      .select({ court: fieldCourts, fieldExternalId: fields.externalId })
      .from(fieldCourts)
      .innerJoin(fields, eq(fieldCourts.fieldId, fields.id))
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);
    return row ? this.toCourt(row.court, row.fieldExternalId) : null;
  }

  async findCourts(fieldExternalId: string): Promise<FieldCourt[]> {
    const rows = await this.drizzle.db
      .select({ court: fieldCourts, fieldExternalId: fields.externalId })
      .from(fieldCourts)
      .innerJoin(fields, eq(fieldCourts.fieldId, fields.id))
      .where(and(eq(fields.externalId, fieldExternalId), eq(fieldCourts.isActive, true)));
    return rows.map((r) => this.toCourt(r.court, r.fieldExternalId));
  }

  async setAvailabilitySlots(courtExternalId: string, slots: AvailabilitySlotData[]): Promise<void> {
    const [court] = await this.drizzle.db
      .select()
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);

    if (!court) throw new NotFoundException(`Court ${courtExternalId} not found`);

    await this.drizzle.db.transaction(async (tx) => {
      await tx.delete(availabilitySlots).where(eq(availabilitySlots.courtId, court.id));
      if (slots.length > 0) {
        await tx.insert(availabilitySlots).values(
          slots.map((s) => ({
            courtId: court.id,
            dayOfWeek: s.dayOfWeek,
            startTime: s.startTime,
            endTime: s.endTime,
            isAvailable: s.isAvailable,
          })),
        );
      }
    });
  }

  async getAvailabilitySlots(courtExternalId: string): Promise<AvailabilitySlot[]> {
    const [court] = await this.drizzle.db
      .select()
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);

    if (!court) return [];

    const rows = await this.drizzle.db
      .select()
      .from(availabilitySlots)
      .where(eq(availabilitySlots.courtId, court.id));
    return rows.map(this.toSlot);
  }

  private toField(row: FieldRow): Field {
    return {
      id: row.externalId,
      name: row.name,
      description: row.description,
      city: row.city,
      address: row.address,
      lat: row.lat,
      lng: row.lng,
      ownerUserId: row.ownerUserId,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toCourt(row: FieldCourtRow, fieldExternalId: string): FieldCourt {
    return {
      id: row.externalId,
      fieldId: fieldExternalId,
      name: row.name,
      type: row.type as CourtType,
      maxPlayers: row.maxPlayers,
      isActive: row.isActive,
    };
  }

  private toSlot(row: AvailabilitySlotRow): AvailabilitySlot {
    return {
      id: row.id,
      courtId: row.courtId,
      dayOfWeek: row.dayOfWeek,
      startTime: row.startTime,
      endTime: row.endTime,
      isAvailable: row.isAvailable,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/fields/infra/database/repositories/
git commit -m "feat(field): add DrizzleFieldRepository"
```

---

### Task 17: Drizzle Repository — Reservation

**Files:**
- Create: `services/field/src/modules/field/reservations/infra/database/repositories/drizzle-reservation.repository.ts`

- [ ] **Step 1: Criar drizzle-reservation.repository.ts**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, gte, lte, ne, or } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateReservationData,
  ReservationRepositoryInterface,
} from '../../domain/repositories/reservation-repository.interface';
import type { Reservation, ReservationChannel, ReservationStatus } from '../../domain/models/reservation.entity';
import { reservations, type ReservationRow } from '../schemas/reservation.schema';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

@Injectable()
export class DrizzleReservationRepository implements ReservationRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateReservationData): Promise<Reservation> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id, fieldId: fieldCourts.fieldId })
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, data.courtExternalId))
      .limit(1);
    if (!court) throw new NotFoundException(`Court ${data.courtExternalId} not found`);

    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, data.fieldExternalId))
      .limit(1);
    if (!field) throw new NotFoundException(`Field ${data.fieldExternalId} not found`);

    const [row] = await this.drizzle.db
      .insert(reservations)
      .values({
        courtId: court.id,
        fieldId: field.id,
        playerUserId: data.playerUserId ?? null,
        channel: data.channel,
        startsAt: data.startsAt,
        endsAt: data.endsAt,
        notes: data.notes ?? null,
        status: 'confirmed',
      })
      .returning();

    return this.toReservation(row, data.courtExternalId, data.fieldExternalId);
  }

  async findById(externalId: string): Promise<Reservation | null> {
    const [row] = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(eq(reservations.externalId, externalId))
      .limit(1);
    return row ? this.toReservation(row.res, row.courtExtId, row.fieldExtId) : null;
  }

  async findByField(fieldExternalId: string, page: number, limit: number): Promise<Reservation[]> {
    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, fieldExternalId))
      .limit(1);
    if (!field) return [];

    const rows = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(and(eq(reservations.fieldId, field.id), eq(reservations.status, 'confirmed')))
      .orderBy(reservations.startsAt)
      .limit(limit)
      .offset((page - 1) * limit);

    return rows.map((r) => this.toReservation(r.res, r.courtExtId, r.fieldExtId));
  }

  async findOverlapping(courtExternalId: string, startsAt: Date, endsAt: Date): Promise<Reservation[]> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id })
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);
    if (!court) return [];

    // Overlapping: existing.startsAt < endsAt AND existing.endsAt > startsAt
    const rows = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(
        and(
          eq(reservations.courtId, court.id),
          eq(reservations.status, 'confirmed'),
          lte(reservations.startsAt, endsAt),
          gte(reservations.endsAt, startsAt),
        ),
      );

    return rows.map((r) => this.toReservation(r.res, r.courtExtId, r.fieldExtId));
  }

  async cancel(externalId: string): Promise<Reservation> {
    const existing = await this.findById(externalId);
    if (!existing) throw new NotFoundException(`Reservation ${externalId} not found`);

    await this.drizzle.db
      .update(reservations)
      .set({ status: 'cancelled' })
      .where(eq(reservations.externalId, externalId));

    return { ...existing, status: 'cancelled' };
  }

  private toReservation(row: ReservationRow, courtExternalId: string, fieldExternalId: string): Reservation {
    return {
      id: row.externalId,
      courtId: courtExternalId,
      fieldId: fieldExternalId,
      playerUserId: row.playerUserId,
      channel: row.channel as ReservationChannel,
      startsAt: row.startsAt,
      endsAt: row.endsAt,
      status: row.status as ReservationStatus,
      notes: row.notes,
      createdAt: row.createdAt,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/reservations/infra/database/repositories/
git commit -m "feat(field): add DrizzleReservationRepository"
```

---

### Task 18: Drizzle Repository — RecurringPlan

**Files:**
- Create: `services/field/src/modules/field/plans/infra/database/repositories/drizzle-recurring-plan.repository.ts`

- [ ] **Step 1: Criar drizzle-recurring-plan.repository.ts**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateRecurringPlanData,
  RecurringPlanRepositoryInterface,
} from '../../domain/repositories/recurring-plan-repository.interface';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';
import type { RecurringPlanSlot, SlotStatus } from '../../domain/models/recurring-plan-slot.entity';
import { recurringPlans, type RecurringPlanRow } from '../schemas/recurring-plan.schema';
import { recurringPlanSlots, type RecurringPlanSlotRow } from '../schemas/recurring-plan-slot.schema';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

@Injectable()
export class DrizzleRecurringPlanRepository implements RecurringPlanRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateRecurringPlanData): Promise<RecurringPlan> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id })
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, data.courtExternalId))
      .limit(1);
    if (!court) throw new NotFoundException(`Court ${data.courtExternalId} not found`);

    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, data.fieldExternalId))
      .limit(1);
    if (!field) throw new NotFoundException(`Field ${data.fieldExternalId} not found`);

    const [row] = await this.drizzle.db
      .insert(recurringPlans)
      .values({
        courtId: court.id,
        fieldId: field.id,
        playerUserId: data.playerUserId ?? null,
        dayOfWeek: data.dayOfWeek,
        startTime: data.startTime,
        endTime: data.endTime,
        planStartsAt: data.planStartsAt,
        planEndsAt: data.planEndsAt ?? null,
      })
      .returning();

    return this.toPlan(row, data.courtExternalId, data.fieldExternalId);
  }

  async findById(externalId: string): Promise<RecurringPlan | null> {
    const [row] = await this.drizzle.db
      .select({
        plan: recurringPlans,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlans)
      .innerJoin(fieldCourts, eq(recurringPlans.courtId, fieldCourts.id))
      .innerJoin(fields, eq(recurringPlans.fieldId, fields.id))
      .where(eq(recurringPlans.externalId, externalId))
      .limit(1);
    return row ? this.toPlan(row.plan, row.courtExtId, row.fieldExtId) : null;
  }

  async findByField(fieldExternalId: string): Promise<RecurringPlan[]> {
    const rows = await this.drizzle.db
      .select({
        plan: recurringPlans,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlans)
      .innerJoin(fieldCourts, eq(recurringPlans.courtId, fieldCourts.id))
      .innerJoin(fields, eq(recurringPlans.fieldId, fields.id))
      .where(and(eq(fields.externalId, fieldExternalId), eq(recurringPlans.isActive, true)));
    return rows.map((r) => this.toPlan(r.plan, r.courtExtId, r.fieldExtId));
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(recurringPlans)
      .set({ isActive: false })
      .where(eq(recurringPlans.externalId, externalId));
  }

  async createSlot(planExternalId: string, slotDate: Date): Promise<RecurringPlanSlot> {
    const [plan] = await this.drizzle.db
      .select({ id: recurringPlans.id, fieldId: recurringPlans.fieldId })
      .from(recurringPlans)
      .where(eq(recurringPlans.externalId, planExternalId))
      .limit(1);
    if (!plan) throw new NotFoundException(`Plan ${planExternalId} not found`);

    const [row] = await this.drizzle.db
      .insert(recurringPlanSlots)
      .values({ planId: plan.id, fieldId: plan.fieldId, slotDate, status: 'active' })
      .returning();

    const [fieldRow] = await this.drizzle.db
      .select({ externalId: fields.externalId })
      .from(fields)
      .where(eq(fields.id, plan.fieldId))
      .limit(1);

    return this.toSlot(row, planExternalId, fieldRow?.externalId ?? '');
  }

  async findSlot(slotExternalId: string): Promise<RecurringPlanSlot | null> {
    const [row] = await this.drizzle.db
      .select({
        slot: recurringPlanSlots,
        planExtId: recurringPlans.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlanSlots)
      .innerJoin(recurringPlans, eq(recurringPlanSlots.planId, recurringPlans.id))
      .innerJoin(fields, eq(recurringPlanSlots.fieldId, fields.id))
      .where(eq(recurringPlanSlots.externalId, slotExternalId))
      .limit(1);
    return row ? this.toSlot(row.slot, row.planExtId, row.fieldExtId) : null;
  }

  async releaseSlot(slotExternalId: string): Promise<RecurringPlanSlot> {
    const existing = await this.findSlot(slotExternalId);
    if (!existing) throw new NotFoundException(`Slot ${slotExternalId} not found`);

    await this.drizzle.db
      .update(recurringPlanSlots)
      .set({ status: 'released' })
      .where(eq(recurringPlanSlots.externalId, slotExternalId));

    return { ...existing, status: 'released' };
  }

  async findActiveSlotsByField(fieldExternalId: string, date: Date): Promise<RecurringPlanSlot[]> {
    const dayStart = new Date(date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, fieldExternalId))
      .limit(1);
    if (!field) return [];

    const rows = await this.drizzle.db
      .select({
        slot: recurringPlanSlots,
        planExtId: recurringPlans.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlanSlots)
      .innerJoin(recurringPlans, eq(recurringPlanSlots.planId, recurringPlans.id))
      .innerJoin(fields, eq(recurringPlanSlots.fieldId, fields.id))
      .where(
        and(
          eq(recurringPlanSlots.fieldId, field.id),
          eq(recurringPlanSlots.status, 'active'),
        ),
      );

    return rows.map((r) => this.toSlot(r.slot, r.planExtId, r.fieldExtId));
  }

  private toPlan(row: RecurringPlanRow, courtExternalId: string, fieldExternalId: string): RecurringPlan {
    return {
      id: row.externalId,
      courtId: courtExternalId,
      fieldId: fieldExternalId,
      playerUserId: row.playerUserId,
      dayOfWeek: row.dayOfWeek,
      startTime: row.startTime,
      endTime: row.endTime,
      planStartsAt: row.planStartsAt,
      planEndsAt: row.planEndsAt,
      isActive: row.isActive,
      createdAt: row.createdAt,
    };
  }

  private toSlot(row: RecurringPlanSlotRow, planExternalId: string, fieldExternalId: string): RecurringPlanSlot {
    return {
      id: row.externalId,
      planId: planExternalId,
      fieldId: fieldExternalId,
      slotDate: row.slotDate,
      status: row.status as SlotStatus,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add services/field/src/modules/field/plans/infra/database/repositories/
git commit -m "feat(field): add DrizzleRecurringPlanRepository"
```

---

### Task 19: DTOs — Field, FieldCourt, SearchFields

**Files:**
- Create: `services/field/src/modules/field/fields/application/dto/create-field.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/create-court.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/set-availability.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/search-fields.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/field.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/field-court.dto.ts`

- [ ] **Step 1: Criar create-field.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateFieldDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiPropertyOptional() @IsString() @IsOptional() description?: string;
  @ApiProperty() @IsString() @IsNotEmpty() city!: string;
  @ApiProperty() @IsString() @IsNotEmpty() address!: string;
  @ApiProperty({ description: 'Latitude (-90 a 90)' })
  @IsNumber() @Min(-90) @Max(90) lat!: number;
  @ApiProperty({ description: 'Longitude (-180 a 180)' })
  @IsNumber() @Min(-180) @Max(180) lng!: number;
}
```

- [ ] **Step 2: Criar create-court.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsIn, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateCourtDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty({ enum: ['society', 'futsal', 'grass', 'synthetic'] })
  @IsIn(['society', 'futsal', 'grass', 'synthetic']) type!: string;
  @ApiPropertyOptional({ default: 10 })
  @IsNumber() @IsOptional() @Min(2) @Max(22) maxPlayers?: number;
}
```

- [ ] **Step 3: Criar set-availability.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsString, Max, Min, ValidateNested } from 'class-validator';

export class AvailabilitySlotDto {
  @ApiProperty({ description: '0=Dom, 1=Seg, ..., 6=Sáb' })
  @IsInt() @Min(0) @Max(6) dayOfWeek!: number;
  @ApiProperty({ example: '08:00' }) @IsString() startTime!: string;
  @ApiProperty({ example: '09:00' }) @IsString() endTime!: string;
  @ApiProperty() @IsBoolean() isAvailable!: boolean;
}

export class SetAvailabilityDto {
  @ApiProperty({ type: [AvailabilitySlotDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AvailabilitySlotDto)
  slots!: AvailabilitySlotDto[];
}
```

- [ ] **Step 4: Criar search-fields.dto.ts**

```typescript
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumber, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class SearchFieldsDto {
  @ApiPropertyOptional() @IsOptional() @IsString() city?: string;
  @ApiPropertyOptional() @IsOptional() @Type(() => Number) @IsNumber() @Min(-90) @Max(90) lat?: number;
  @ApiPropertyOptional() @IsOptional() @Type(() => Number) @IsNumber() @Min(-180) @Max(180) lng?: number;
  @ApiPropertyOptional({ description: 'Raio em km', default: 10 })
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0.1) @Max(100) radius?: number;
}
```

- [ ] **Step 5: Criar field.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Field } from '../../domain/models/field.entity';

export class FieldDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiPropertyOptional() description!: string | null;
  @ApiProperty() city!: string;
  @ApiProperty() address!: string;
  @ApiProperty() lat!: number;
  @ApiProperty() lng!: number;
  @ApiProperty() ownerUserId!: string;
  @ApiProperty() isActive!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(field: Field): FieldDto {
    const dto = new FieldDto();
    dto.id = field.id;
    dto.name = field.name;
    dto.description = field.description;
    dto.city = field.city;
    dto.address = field.address;
    dto.lat = field.lat;
    dto.lng = field.lng;
    dto.ownerUserId = field.ownerUserId;
    dto.isActive = field.isActive;
    dto.createdAt = field.createdAt;
    return dto;
  }
}
```

- [ ] **Step 6: Criar field-court.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import type { FieldCourt } from '../../domain/models/field-court.entity';

export class FieldCourtDto {
  @ApiProperty() id!: string;
  @ApiProperty() fieldId!: string;
  @ApiProperty() name!: string;
  @ApiProperty() type!: string;
  @ApiProperty() maxPlayers!: number;
  @ApiProperty() isActive!: boolean;

  static from(court: FieldCourt): FieldCourtDto {
    const dto = new FieldCourtDto();
    dto.id = court.id;
    dto.fieldId = court.fieldId;
    dto.name = court.name;
    dto.type = court.type;
    dto.maxPlayers = court.maxPlayers;
    dto.isActive = court.isActive;
    return dto;
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add services/field/src/modules/field/fields/application/dto/
git commit -m "feat(field): add Field, FieldCourt and SearchFields DTOs"
```

---

### Task 20: DTOs — Reservation + FieldAvailability

**Files:**
- Create: `services/field/src/modules/field/reservations/application/dto/create-reservation.dto.ts`
- Create: `services/field/src/modules/field/reservations/application/dto/reservation.dto.ts`
- Create: `services/field/src/modules/field/fields/application/dto/field-availability.dto.ts`

- [ ] **Step 1: Criar create-reservation.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateReservationDto {
  @ApiProperty({ description: 'UUID da quadra' })
  @IsUUID() courtId!: string;

  @ApiProperty({ enum: ['app', 'manual', 'phone'] })
  @IsIn(['app', 'manual', 'phone']) channel!: string;

  @ApiProperty({ example: '2026-06-15T08:00:00-03:00' })
  @IsDateString() startsAt!: string;

  @ApiProperty({ example: '2026-06-15T09:00:00-03:00' })
  @IsDateString() endsAt!: string;

  @ApiPropertyOptional() @IsOptional() @IsString() notes?: string;
}
```

- [ ] **Step 2: Criar reservation.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Reservation } from '../../domain/models/reservation.entity';

export class ReservationDto {
  @ApiProperty() id!: string;
  @ApiProperty() courtId!: string;
  @ApiProperty() fieldId!: string;
  @ApiPropertyOptional() playerUserId!: string | null;
  @ApiProperty() channel!: string;
  @ApiProperty() startsAt!: Date;
  @ApiProperty() endsAt!: Date;
  @ApiProperty() status!: string;
  @ApiPropertyOptional() notes!: string | null;
  @ApiProperty() createdAt!: Date;

  static from(r: Reservation): ReservationDto {
    const dto = new ReservationDto();
    dto.id = r.id;
    dto.courtId = r.courtId;
    dto.fieldId = r.fieldId;
    dto.playerUserId = r.playerUserId;
    dto.channel = r.channel;
    dto.startsAt = r.startsAt;
    dto.endsAt = r.endsAt;
    dto.status = r.status;
    dto.notes = r.notes;
    dto.createdAt = r.createdAt;
    return dto;
  }
}
```

- [ ] **Step 3: Criar field-availability.dto.ts**

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class TimeSlotDto {
  @ApiProperty({ example: '08:00' }) startTime!: string;
  @ApiProperty({ example: '09:00' }) endTime!: string;
  @ApiProperty() isAvailable!: boolean;
}

export class CourtAvailabilityDto {
  @ApiProperty() courtId!: string;
  @ApiProperty() courtName!: string;
  @ApiProperty({ type: [TimeSlotDto] }) slots!: TimeSlotDto[];
}

export class FieldAvailabilityDto {
  @ApiProperty() fieldId!: string;
  @ApiProperty() date!: string;
  @ApiProperty({ type: [CourtAvailabilityDto] }) courts!: CourtAvailabilityDto[];
}
```

- [ ] **Step 4: Commit**

```bash
git add services/field/src/modules/field/reservations/application/dto/ services/field/src/modules/field/fields/application/dto/field-availability.dto.ts
git commit -m "feat(field): add Reservation and FieldAvailability DTOs"
```

---

### Task 21: DTOs — RecurringPlan

**Files:**
- Create: `services/field/src/modules/field/plans/application/dto/create-recurring-plan.dto.ts`
- Create: `services/field/src/modules/field/plans/application/dto/recurring-plan.dto.ts`

- [ ] **Step 1: Criar create-recurring-plan.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateRecurringPlanDto {
  @ApiProperty({ description: 'UUID da quadra' }) @IsString() courtId!: string;
  @ApiProperty({ description: '0=Dom, 1=Seg, ..., 6=Sáb' })
  @IsInt() @Min(0) @Max(6) dayOfWeek!: number;
  @ApiProperty({ example: '08:00' }) @IsString() startTime!: string;
  @ApiProperty({ example: '09:00' }) @IsString() endTime!: string;
  @ApiProperty({ example: '2026-06-01T00:00:00Z' }) @IsDateString() planStartsAt!: string;
  @ApiPropertyOptional() @IsOptional() @IsDateString() planEndsAt?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() playerUserId?: string;
}
```

- [ ] **Step 2: Criar recurring-plan.dto.ts**

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';

export class RecurringPlanDto {
  @ApiProperty() id!: string;
  @ApiProperty() courtId!: string;
  @ApiProperty() fieldId!: string;
  @ApiPropertyOptional() playerUserId!: string | null;
  @ApiProperty() dayOfWeek!: number;
  @ApiProperty() startTime!: string;
  @ApiProperty() endTime!: string;
  @ApiProperty() planStartsAt!: Date;
  @ApiPropertyOptional() planEndsAt!: Date | null;
  @ApiProperty() isActive!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(plan: RecurringPlan): RecurringPlanDto {
    const dto = new RecurringPlanDto();
    dto.id = plan.id;
    dto.courtId = plan.courtId;
    dto.fieldId = plan.fieldId;
    dto.playerUserId = plan.playerUserId;
    dto.dayOfWeek = plan.dayOfWeek;
    dto.startTime = plan.startTime;
    dto.endTime = plan.endTime;
    dto.planStartsAt = plan.planStartsAt;
    dto.planEndsAt = plan.planEndsAt;
    dto.isActive = plan.isActive;
    dto.createdAt = plan.createdAt;
    return dto;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/plans/application/dto/
git commit -m "feat(field): add RecurringPlan DTOs"
```

---

### Task 22: TDD — FieldService (register, getById, searchNearby, addCourt)

**Files:**
- Create: `services/field/src/modules/field/fields/application/services/field.service.spec.ts`
- Create: `services/field/src/modules/field/fields/application/services/field.service.ts`

- [ ] **Step 1: Escrever o teste que vai falhar**

Crie `field.service.spec.ts`:

```typescript
import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { FieldService } from './field.service';
import { FIELD_REPOSITORY } from '../../domain/repositories/field-repository.interface';
import { FieldMessagingService } from './field-messaging.service';
import type { Field } from '../../domain/models/field.entity';
import type { FieldCourt } from '../../domain/models/field-court.entity';

const mockFieldRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findNearby: jest.fn(),
  addCourt: jest.fn(),
  findCourt: jest.fn(),
  findCourts: jest.fn(),
  setAvailabilitySlots: jest.fn(),
  getAvailabilitySlots: jest.fn(),
};

const mockMessaging = {
  publishFieldRegistered: jest.fn(),
};

const mockField: Field = {
  id: 'field-uuid-1',
  name: 'Arena São Paulo',
  description: 'Quadras society',
  city: 'São Paulo',
  address: 'Rua Teste, 123',
  lat: -23.5505,
  lng: -46.6333,
  ownerUserId: 'owner-uuid-1',
  isActive: true,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

const mockCourt: FieldCourt = {
  id: 'court-uuid-1',
  fieldId: 'field-uuid-1',
  name: 'Quadra A',
  type: 'society',
  maxPlayers: 10,
  isActive: true,
};

describe('FieldService', () => {
  let service: FieldService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        FieldService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(FieldService);
  });

  describe('register', () => {
    it('creates a field and publishes field.registered event', async () => {
      mockFieldRepo.create.mockResolvedValue(mockField);

      const result = await service.register('owner-uuid-1', {
        name: 'Arena São Paulo',
        city: 'São Paulo',
        address: 'Rua Teste, 123',
        lat: -23.5505,
        lng: -46.6333,
      });

      expect(mockFieldRepo.create).toHaveBeenCalledWith({
        name: 'Arena São Paulo',
        city: 'São Paulo',
        address: 'Rua Teste, 123',
        lat: -23.5505,
        lng: -46.6333,
        ownerUserId: 'owner-uuid-1',
        description: undefined,
      });
      expect(mockMessaging.publishFieldRegistered).toHaveBeenCalledWith(mockField);
      expect(result.id).toBe('field-uuid-1');
      expect(result.name).toBe('Arena São Paulo');
    });
  });

  describe('getById', () => {
    it('returns field when found', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      const result = await service.getById('field-uuid-1');
      expect(result.id).toBe('field-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(service.getById('not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('searchNearby', () => {
    it('returns list of fields from repository', async () => {
      mockFieldRepo.findNearby.mockResolvedValue([mockField]);
      const results = await service.searchNearby({ city: 'São Paulo' });
      expect(mockFieldRepo.findNearby).toHaveBeenCalledWith({ city: 'São Paulo' });
      expect(results).toHaveLength(1);
      expect(results[0].id).toBe('field-uuid-1');
    });
  });

  describe('addCourt', () => {
    it('adds court to existing field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.addCourt.mockResolvedValue(mockCourt);

      const result = await service.addCourt('owner-uuid-1', 'field-uuid-1', {
        name: 'Quadra A',
        type: 'society',
        maxPlayers: 10,
      });

      expect(mockFieldRepo.addCourt).toHaveBeenCalledWith({
        fieldExternalId: 'field-uuid-1',
        name: 'Quadra A',
        type: 'society',
        maxPlayers: 10,
      });
      expect(result.name).toBe('Quadra A');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.addCourt('owner-uuid-1', 'not-found', { name: 'Q', type: 'futsal', maxPlayers: 10 }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ForbiddenException when user is not field owner', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      const { ForbiddenException } = await import('@nestjs/common');
      await expect(
        service.addCourt('another-user', 'field-uuid-1', { name: 'Q', type: 'futsal', maxPlayers: 10 }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
cd services/field && npm test -- --testPathPattern="field.service.spec"
```

Expected: FAIL — `Cannot find module './field.service'`

- [ ] **Step 3: Implementar field.service.ts**

```typescript
import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface, type SearchFieldsParams } from '../../domain/repositories/field-repository.interface';
import { FieldMessagingService } from './field-messaging.service';
import { CreateFieldDto } from '../dto/create-field.dto';
import { CreateCourtDto } from '../dto/create-court.dto';
import { FieldDto } from '../dto/field.dto';
import { FieldCourtDto } from '../dto/field-court.dto';

@Injectable()
export class FieldService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async register(ownerUserId: string, dto: CreateFieldDto): Promise<FieldDto> {
    const field = await this.fieldRepo.create({
      name: dto.name,
      description: dto.description,
      city: dto.city,
      address: dto.address,
      lat: dto.lat,
      lng: dto.lng,
      ownerUserId,
    });

    try {
      await this.messaging.publishFieldRegistered(field);
    } catch {
      // advisory — não bloqueia resposta
    }

    return FieldDto.from(field);
  }

  async getById(externalId: string): Promise<FieldDto> {
    const field = await this.fieldRepo.findById(externalId);
    if (!field) throw new NotFoundException(`Field ${externalId} not found`);
    return FieldDto.from(field);
  }

  async searchNearby(params: SearchFieldsParams): Promise<FieldDto[]> {
    const results = await this.fieldRepo.findNearby(params);
    return results.map(FieldDto.from);
  }

  async addCourt(ownerUserId: string, fieldExternalId: string, dto: CreateCourtDto): Promise<FieldCourtDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can add courts');

    const court = await this.fieldRepo.addCourt({
      fieldExternalId,
      name: dto.name,
      type: dto.type,
      maxPlayers: dto.maxPlayers ?? 10,
    });

    return FieldCourtDto.from(court);
  }

  async getCourts(fieldExternalId: string): Promise<FieldCourtDto[]> {
    const courts = await this.fieldRepo.findCourts(fieldExternalId);
    return courts.map(FieldCourtDto.from);
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

```bash
npm test -- --testPathPattern="field.service.spec"
```

Expected: PASS — 6 tests passing

- [ ] **Step 5: Commit**

```bash
git add services/field/src/modules/field/fields/application/services/
git commit -m "feat(field): implement FieldService with TDD (6 tests passing)"
```

---

### Task 23: TDD — AvailabilityService

**Files:**
- Create: `services/field/src/modules/field/fields/application/services/availability.service.spec.ts`
- Create: `services/field/src/modules/field/fields/application/services/availability.service.ts`

- [ ] **Step 1: Escrever o teste que vai falhar**

Crie `availability.service.spec.ts`:

```typescript
import { Test } from '@nestjs/testing';
import { AvailabilityService } from './availability.service';
import { FIELD_REPOSITORY } from '../../domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY } from '../../../reservations/domain/repositories/reservation-repository.interface';
import { RECURRING_PLAN_REPOSITORY } from '../../../plans/domain/repositories/recurring-plan-repository.interface';
import type { AvailabilitySlot } from '../../domain/models/availability-slot.entity';
import type { Reservation } from '../../../reservations/domain/models/reservation.entity';

const mockFieldRepo = {
  findById: jest.fn(),
  findCourts: jest.fn(),
  getAvailabilitySlots: jest.fn(),
};
const mockReservationRepo = { findOverlapping: jest.fn() };
const mockPlanRepo = { findActiveSlotsByField: jest.fn() };

const mockAvailabilitySlots: AvailabilitySlot[] = [
  { id: 1n, courtId: 1n, dayOfWeek: 0, startTime: '08:00', endTime: '09:00', isAvailable: true },
  { id: 2n, courtId: 1n, dayOfWeek: 0, startTime: '09:00', endTime: '10:00', isAvailable: true },
];

describe('AvailabilityService', () => {
  let service: AvailabilityService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AvailabilityService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RESERVATION_REPOSITORY, useValue: mockReservationRepo },
        { provide: RECURRING_PLAN_REPOSITORY, useValue: mockPlanRepo },
      ],
    }).compile();
    service = module.get(AvailabilityService);
  });

  describe('getAvailability', () => {
    it('returns all slots as available when no reservations exist', async () => {
      mockFieldRepo.findById.mockResolvedValue({ id: 'f-1', isActive: true });
      mockFieldRepo.findCourts.mockResolvedValue([
        { id: 'c-1', name: 'Quadra A', type: 'society' },
      ]);
      mockFieldRepo.getAvailabilitySlots.mockResolvedValue(mockAvailabilitySlots);
      mockReservationRepo.findOverlapping.mockResolvedValue([]);
      mockPlanRepo.findActiveSlotsByField.mockResolvedValue([]);

      // Sunday, 2026-06-07 (dayOfWeek=0)
      const result = await service.getAvailability('f-1', '2026-06-07');

      expect(result.courts).toHaveLength(1);
      expect(result.courts[0].slots).toHaveLength(2);
      expect(result.courts[0].slots[0].isAvailable).toBe(true);
      expect(result.courts[0].slots[1].isAvailable).toBe(true);
    });

    it('marks slots as unavailable when confirmed reservation overlaps', async () => {
      mockFieldRepo.findById.mockResolvedValue({ id: 'f-1', isActive: true });
      mockFieldRepo.findCourts.mockResolvedValue([
        { id: 'c-1', name: 'Quadra A', type: 'society' },
      ]);
      mockFieldRepo.getAvailabilitySlots.mockResolvedValue(mockAvailabilitySlots);

      const reservation: Partial<Reservation> = {
        startsAt: new Date('2026-06-07T08:00:00-03:00'),
        endsAt: new Date('2026-06-07T09:00:00-03:00'),
        status: 'confirmed',
      };
      mockReservationRepo.findOverlapping.mockResolvedValue([reservation]);
      mockPlanRepo.findActiveSlotsByField.mockResolvedValue([]);

      const result = await service.getAvailability('f-1', '2026-06-07');

      // First slot (08:00-09:00) is taken, second (09:00-10:00) is free
      const slots = result.courts[0].slots;
      expect(slots[0].isAvailable).toBe(false);
      expect(slots[1].isAvailable).toBe(true);
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      const { NotFoundException } = await import('@nestjs/common');
      await expect(service.getAvailability('not-found', '2026-06-07')).rejects.toThrow(NotFoundException);
    });
  });
});
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
npm test -- --testPathPattern="availability.service.spec"
```

Expected: FAIL — `Cannot find module './availability.service'`

- [ ] **Step 3: Implementar availability.service.ts**

```typescript
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY, type ReservationRepositoryInterface } from '../../../reservations/domain/repositories/reservation-repository.interface';
import { RECURRING_PLAN_REPOSITORY, type RecurringPlanRepositoryInterface } from '../../../plans/domain/repositories/recurring-plan-repository.interface';
import { FieldAvailabilityDto, CourtAvailabilityDto, TimeSlotDto } from '../dto/field-availability.dto';

@Injectable()
export class AvailabilityService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RESERVATION_REPOSITORY) private readonly reservationRepo: ReservationRepositoryInterface,
    @Inject(RECURRING_PLAN_REPOSITORY) private readonly planRepo: RecurringPlanRepositoryInterface,
  ) {}

  async getAvailability(fieldExternalId: string, dateStr: string): Promise<FieldAvailabilityDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);

    const date = new Date(dateStr);
    const dayOfWeek = date.getDay(); // 0=Sun, 6=Sat
    const dayStart = new Date(`${dateStr}T00:00:00Z`);
    const dayEnd = new Date(`${dateStr}T23:59:59Z`);

    const courts = await this.fieldRepo.findCourts(fieldExternalId);
    const activeSlotsByField = await this.planRepo.findActiveSlotsByField(fieldExternalId, date);

    const courtAvailabilities: CourtAvailabilityDto[] = [];

    for (const court of courts) {
      const slots = await this.fieldRepo.getAvailabilitySlots(court.id);
      const daySlots = slots.filter((s) => s.dayOfWeek === dayOfWeek && s.isAvailable);

      const slotDtos: TimeSlotDto[] = [];
      for (const slot of daySlots) {
        const slotStart = new Date(`${dateStr}T${slot.startTime}:00`);
        const slotEnd = new Date(`${dateStr}T${slot.endTime}:00`);

        const overlapping = await this.reservationRepo.findOverlapping(
          court.id,
          slotStart,
          slotEnd,
        );

        const isBlockedByPlan = activeSlotsByField.some((planSlot) => {
          const ps = new Date(planSlot.slotDate);
          return ps >= slotStart && ps < slotEnd;
        });

        const timeSlot = new TimeSlotDto();
        timeSlot.startTime = slot.startTime;
        timeSlot.endTime = slot.endTime;
        timeSlot.isAvailable = overlapping.length === 0 && !isBlockedByPlan;
        slotDtos.push(timeSlot);
      }

      const courtDto = new CourtAvailabilityDto();
      courtDto.courtId = court.id;
      courtDto.courtName = court.name;
      courtDto.slots = slotDtos;
      courtAvailabilities.push(courtDto);
    }

    const result = new FieldAvailabilityDto();
    result.fieldId = fieldExternalId;
    result.date = dateStr;
    result.courts = courtAvailabilities;
    return result;
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

```bash
npm test -- --testPathPattern="availability.service.spec"
```

Expected: PASS — 3 tests passing

- [ ] **Step 5: Commit**

```bash
git add services/field/src/modules/field/fields/application/services/availability.service.spec.ts services/field/src/modules/field/fields/application/services/availability.service.ts
git commit -m "feat(field): implement AvailabilityService with TDD (3 tests passing)"
```

---

### Task 24: TDD — ReservationService

**Files:**
- Create: `services/field/src/modules/field/reservations/application/services/reservation.service.spec.ts`
- Create: `services/field/src/modules/field/reservations/application/services/reservation.service.ts`

- [ ] **Step 1: Escrever o teste que vai falhar**

Crie `reservation.service.spec.ts`:

```typescript
import { ConflictException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ReservationService } from './reservation.service';
import { FIELD_REPOSITORY } from '../../../fields/domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY } from '../../domain/repositories/reservation-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import type { Reservation } from '../../domain/models/reservation.entity';
import type { Field } from '../../../fields/domain/models/field.entity';

const mockFieldRepo = { findById: jest.fn(), findCourt: jest.fn() };
const mockReservationRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByField: jest.fn(),
  findOverlapping: jest.fn(),
  cancel: jest.fn(),
};
const mockMessaging = {
  publishReservationConfirmed: jest.fn(),
  publishReservationCancelled: jest.fn(),
};

const mockField: Field = {
  id: 'field-uuid-1', name: 'Arena', description: null, city: 'SP',
  address: 'Rua X', lat: -23.5, lng: -46.6,
  ownerUserId: 'owner-uuid-1', isActive: true,
  createdAt: new Date(), updatedAt: new Date(),
};

const mockReservation: Reservation = {
  id: 'res-uuid-1', courtId: 'court-uuid-1', fieldId: 'field-uuid-1',
  playerUserId: null, channel: 'manual', notes: null,
  startsAt: new Date('2026-06-15T08:00:00Z'),
  endsAt: new Date('2026-06-15T09:00:00Z'),
  status: 'confirmed', createdAt: new Date(),
};

describe('ReservationService', () => {
  let service: ReservationService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        ReservationService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RESERVATION_REPOSITORY, useValue: mockReservationRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(ReservationService);
  });

  describe('createManual', () => {
    it('creates a reservation and publishes reservation.confirmed event', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.findCourt.mockResolvedValue({ id: 'court-uuid-1', fieldId: 'field-uuid-1' });
      mockReservationRepo.findOverlapping.mockResolvedValue([]);
      mockReservationRepo.create.mockResolvedValue(mockReservation);

      const result = await service.createManual('owner-uuid-1', 'field-uuid-1', {
        courtId: 'court-uuid-1',
        channel: 'manual',
        startsAt: '2026-06-15T08:00:00Z',
        endsAt: '2026-06-15T09:00:00Z',
      });

      expect(mockReservationRepo.create).toHaveBeenCalled();
      expect(mockMessaging.publishReservationConfirmed).toHaveBeenCalledWith(mockReservation);
      expect(result.id).toBe('res-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.createManual('owner-uuid-1', 'not-found', {
          courtId: 'c', channel: 'manual',
          startsAt: '2026-06-15T08:00:00Z', endsAt: '2026-06-15T09:00:00Z',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when time slot is already reserved', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.findCourt.mockResolvedValue({ id: 'court-uuid-1', fieldId: 'field-uuid-1' });
      mockReservationRepo.findOverlapping.mockResolvedValue([mockReservation]);

      await expect(
        service.createManual('owner-uuid-1', 'field-uuid-1', {
          courtId: 'court-uuid-1', channel: 'manual',
          startsAt: '2026-06-15T08:00:00Z', endsAt: '2026-06-15T09:00:00Z',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('cancel', () => {
    it('cancels reservation and publishes reservation.cancelled event', async () => {
      const cancelled = { ...mockReservation, status: 'cancelled' as const };
      mockReservationRepo.findById.mockResolvedValue(mockReservation);
      mockReservationRepo.cancel.mockResolvedValue(cancelled);
      mockFieldRepo.findById.mockResolvedValue(mockField);

      const result = await service.cancel('owner-uuid-1', 'field-uuid-1', 'res-uuid-1');

      expect(mockReservationRepo.cancel).toHaveBeenCalledWith('res-uuid-1');
      expect(mockMessaging.publishReservationCancelled).toHaveBeenCalledWith(cancelled);
      expect(result.status).toBe('cancelled');
    });

    it('throws NotFoundException when reservation not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockReservationRepo.findById.mockResolvedValue(null);
      await expect(service.cancel('owner-uuid-1', 'field-uuid-1', 'not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('list', () => {
    it('returns reservations for field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockReservationRepo.findByField.mockResolvedValue([mockReservation]);

      const result = await service.list('field-uuid-1', 1, 10);

      expect(mockReservationRepo.findByField).toHaveBeenCalledWith('field-uuid-1', 1, 10);
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('res-uuid-1');
    });
  });
});
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
npm test -- --testPathPattern="reservation.service.spec"
```

Expected: FAIL — `Cannot find module './reservation.service'`

- [ ] **Step 3: Implementar reservation.service.ts**

```typescript
import { ConflictException, ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../../fields/domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY, type ReservationRepositoryInterface } from '../../domain/repositories/reservation-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import { CreateReservationDto } from '../dto/create-reservation.dto';
import { ReservationDto } from '../dto/reservation.dto';

@Injectable()
export class ReservationService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RESERVATION_REPOSITORY) private readonly reservationRepo: ReservationRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async createManual(ownerUserId: string, fieldExternalId: string, dto: CreateReservationDto): Promise<ReservationDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can create reservations');

    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);

    const overlapping = await this.reservationRepo.findOverlapping(dto.courtId, startsAt, endsAt);
    if (overlapping.length > 0) {
      throw new ConflictException('Time slot is already reserved');
    }

    const reservation = await this.reservationRepo.create({
      courtExternalId: dto.courtId,
      fieldExternalId,
      channel: dto.channel as any,
      startsAt,
      endsAt,
      notes: dto.notes,
    });

    try {
      await this.messaging.publishReservationConfirmed(reservation);
    } catch {
      // advisory
    }

    return ReservationDto.from(reservation);
  }

  async cancel(ownerUserId: string, fieldExternalId: string, reservationExternalId: string): Promise<ReservationDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can cancel reservations');

    const existing = await this.reservationRepo.findById(reservationExternalId);
    if (!existing) throw new NotFoundException(`Reservation ${reservationExternalId} not found`);

    const cancelled = await this.reservationRepo.cancel(reservationExternalId);

    try {
      await this.messaging.publishReservationCancelled(cancelled);
    } catch {
      // advisory
    }

    return ReservationDto.from(cancelled);
  }

  async list(fieldExternalId: string, page: number, limit: number): Promise<ReservationDto[]> {
    const reservations = await this.reservationRepo.findByField(fieldExternalId, page, limit);
    return reservations.map(ReservationDto.from);
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

```bash
npm test -- --testPathPattern="reservation.service.spec"
```

Expected: PASS — 5 tests passing

- [ ] **Step 5: Commit**

```bash
git add services/field/src/modules/field/reservations/application/services/
git commit -m "feat(field): implement ReservationService with TDD (5 tests passing)"
```

---

### Task 25: TDD — RecurringPlanService

**Files:**
- Create: `services/field/src/modules/field/plans/application/services/recurring-plan.service.spec.ts`
- Create: `services/field/src/modules/field/plans/application/services/recurring-plan.service.ts`

- [ ] **Step 1: Escrever o teste que vai falhar**

Crie `recurring-plan.service.spec.ts`:

```typescript
import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { RecurringPlanService } from './recurring-plan.service';
import { FIELD_REPOSITORY } from '../../../fields/domain/repositories/field-repository.interface';
import { RECURRING_PLAN_REPOSITORY } from '../../domain/repositories/recurring-plan-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import type { Field } from '../../../fields/domain/models/field.entity';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';
import type { RecurringPlanSlot } from '../../domain/models/recurring-plan-slot.entity';

const mockFieldRepo = { findById: jest.fn() };
const mockPlanRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByField: jest.fn(),
  deactivate: jest.fn(),
  createSlot: jest.fn(),
  findSlot: jest.fn(),
  releaseSlot: jest.fn(),
  findActiveSlotsByField: jest.fn(),
};
const mockMessaging = { publishPlanSlotReleased: jest.fn() };

const mockField: Field = {
  id: 'field-uuid-1', name: 'Arena', description: null, city: 'SP',
  address: 'Rua X', lat: -23.5, lng: -46.6,
  ownerUserId: 'owner-uuid-1', isActive: true,
  createdAt: new Date(), updatedAt: new Date(),
};

const mockPlan: RecurringPlan = {
  id: 'plan-uuid-1', courtId: 'court-uuid-1', fieldId: 'field-uuid-1',
  playerUserId: 'player-uuid-1', dayOfWeek: 1, startTime: '08:00', endTime: '09:00',
  planStartsAt: new Date('2026-06-01'), planEndsAt: null, isActive: true,
  createdAt: new Date(),
};

const mockSlot: RecurringPlanSlot = {
  id: 'slot-uuid-1', planId: 'plan-uuid-1', fieldId: 'field-uuid-1',
  slotDate: new Date('2026-06-08'), status: 'active',
};

describe('RecurringPlanService', () => {
  let service: RecurringPlanService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        RecurringPlanService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RECURRING_PLAN_REPOSITORY, useValue: mockPlanRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(RecurringPlanService);
  });

  describe('create', () => {
    it('creates recurring plan for existing field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockPlanRepo.create.mockResolvedValue(mockPlan);

      const result = await service.create('owner-uuid-1', 'field-uuid-1', {
        courtId: 'court-uuid-1',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:00',
        planStartsAt: '2026-06-01T00:00:00Z',
        playerUserId: 'player-uuid-1',
      });

      expect(mockPlanRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        courtExternalId: 'court-uuid-1',
        fieldExternalId: 'field-uuid-1',
        dayOfWeek: 1,
        startTime: '08:00',
      }));
      expect(result.id).toBe('plan-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.create('owner-uuid-1', 'not-found', {
          courtId: 'c', dayOfWeek: 1, startTime: '08:00',
          endTime: '09:00', planStartsAt: '2026-06-01T00:00:00Z',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('releaseSlot', () => {
    it('releases a slot and publishes plan.slot-released event', async () => {
      const released = { ...mockSlot, status: 'released' as const };
      mockPlanRepo.findSlot.mockResolvedValue(mockSlot);
      mockPlanRepo.releaseSlot.mockResolvedValue(released);

      const result = await service.releaseSlot('owner-uuid-1', 'field-uuid-1', 'slot-uuid-1');

      expect(mockPlanRepo.releaseSlot).toHaveBeenCalledWith('slot-uuid-1');
      expect(mockMessaging.publishPlanSlotReleased).toHaveBeenCalledWith(released);
      expect(result.status).toBe('released');
    });

    it('throws NotFoundException when slot not found', async () => {
      mockPlanRepo.findSlot.mockResolvedValue(null);
      await expect(service.releaseSlot('owner-uuid-1', 'field-uuid-1', 'not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getByField', () => {
    it('returns active plans for field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockPlanRepo.findByField.mockResolvedValue([mockPlan]);

      const result = await service.getByField('field-uuid-1');

      expect(mockPlanRepo.findByField).toHaveBeenCalledWith('field-uuid-1');
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('plan-uuid-1');
    });
  });
});
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
npm test -- --testPathPattern="recurring-plan.service.spec"
```

Expected: FAIL — `Cannot find module './recurring-plan.service'`

- [ ] **Step 3: Implementar recurring-plan.service.ts**

```typescript
import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../../fields/domain/repositories/field-repository.interface';
import { RECURRING_PLAN_REPOSITORY, type RecurringPlanRepositoryInterface } from '../../domain/repositories/recurring-plan-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import { CreateRecurringPlanDto } from '../dto/create-recurring-plan.dto';
import { RecurringPlanDto } from '../dto/recurring-plan.dto';

@Injectable()
export class RecurringPlanService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RECURRING_PLAN_REPOSITORY) private readonly planRepo: RecurringPlanRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async create(ownerUserId: string, fieldExternalId: string, dto: CreateRecurringPlanDto): Promise<RecurringPlanDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can create plans');

    const plan = await this.planRepo.create({
      courtExternalId: dto.courtId,
      fieldExternalId,
      playerUserId: dto.playerUserId,
      dayOfWeek: dto.dayOfWeek,
      startTime: dto.startTime,
      endTime: dto.endTime,
      planStartsAt: new Date(dto.planStartsAt),
      planEndsAt: dto.planEndsAt ? new Date(dto.planEndsAt) : undefined,
    });

    return RecurringPlanDto.from(plan);
  }

  async releaseSlot(ownerUserId: string, fieldExternalId: string, slotExternalId: string): Promise<{ id: string; status: string }> {
    const slot = await this.planRepo.findSlot(slotExternalId);
    if (!slot) throw new NotFoundException(`Slot ${slotExternalId} not found`);
    if (slot.fieldId !== fieldExternalId) throw new ForbiddenException('Slot does not belong to this field');

    const released = await this.planRepo.releaseSlot(slotExternalId);

    try {
      await this.messaging.publishPlanSlotReleased(released);
    } catch {
      // advisory
    }

    return { id: released.id, status: released.status };
  }

  async getByField(fieldExternalId: string): Promise<RecurringPlanDto[]> {
    const plans = await this.planRepo.findByField(fieldExternalId);
    return plans.map(RecurringPlanDto.from);
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

```bash
npm test -- --testPathPattern="recurring-plan.service.spec"
```

Expected: PASS — 5 tests passing

- [ ] **Step 5: Rodar toda a suite de testes**

```bash
npm test
```

Expected: PASS — 19 tests passing (6 + 3 + 5 + 5)

- [ ] **Step 6: Commit**

```bash
git add services/field/src/modules/field/plans/application/services/
git commit -m "feat(field): implement RecurringPlanService with TDD (5 tests passing, 19 total)"
```

---

### Task 26: FieldMessagingService

**Files:**
- Create: `services/field/src/modules/field/fields/application/services/field-messaging.service.ts`

- [ ] **Step 1: Criar field-messaging.service.ts**

```typescript
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { FieldEvents } from '@shared/contracts/events/field.events';
import type { Field } from '../../domain/models/field.entity';
import type { Reservation } from '../../../reservations/domain/models/reservation.entity';
import type { RecurringPlanSlot } from '../../../plans/domain/models/recurring-plan-slot.entity';

@Injectable()
export class FieldMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishFieldRegistered(field: Field): Promise<void> {
    await this.messaging.publish(FieldEvents.REGISTERED, {
      fieldId: field.id,
      name: field.name,
      city: field.city,
      location: { lat: field.lat, lng: field.lng },
    });
  }

  async publishReservationConfirmed(reservation: Reservation): Promise<void> {
    await this.messaging.publish(FieldEvents.RESERVATION_CONFIRMED, {
      reservationId: reservation.id,
      fieldId: reservation.fieldId,
      courtId: reservation.courtId,
      startsAt: reservation.startsAt.toISOString(),
      endsAt: reservation.endsAt.toISOString(),
      channel: reservation.channel,
    });
  }

  async publishReservationCancelled(reservation: Reservation): Promise<void> {
    await this.messaging.publish(FieldEvents.RESERVATION_CANCELLED, {
      reservationId: reservation.id,
      fieldId: reservation.fieldId,
    });
  }

  async publishPlanSlotReleased(slot: RecurringPlanSlot): Promise<void> {
    await this.messaging.publish(FieldEvents.PLAN_SLOT_RELEASED, {
      planId: slot.planId,
      slotId: slot.id,
      slotDate: slot.slotDate.toISOString(),
      fieldId: slot.fieldId,
    });
  }
}
```

- [ ] **Step 2: Verificar que o evento existe em @shared**

O arquivo `shared/src/contracts/events/field.events.ts` já deve existir com os 4 valores. Confirme:

```bash
cat ../../shared/src/contracts/events/field.events.ts
```

Expected output:
```
export enum FieldEvents {
  REGISTERED = 'field.registered',
  RESERVATION_CONFIRMED = 'field.reservation-confirmed',
  RESERVATION_CANCELLED = 'field.reservation-cancelled',
  PLAN_SLOT_RELEASED = 'field.plan-slot-released',
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/fields/application/services/field-messaging.service.ts
git commit -m "feat(field): add FieldMessagingService (4 events)"
```

---

### Task 27: FieldsController

**Files:**
- Create: `services/field/src/modules/field/fields/infra/controllers/fields.controller.ts`

- [ ] **Step 1: Criar fields.controller.ts**

```typescript
import {
  Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Put, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { FieldService } from '../../application/services/field.service';
import { AvailabilityService } from '../../application/services/availability.service';
import { CreateFieldDto } from '../../application/dto/create-field.dto';
import { CreateCourtDto } from '../../application/dto/create-court.dto';
import { SetAvailabilityDto } from '../../application/dto/set-availability.dto';
import { SearchFieldsDto } from '../../application/dto/search-fields.dto';
import { FieldDto } from '../../application/dto/field.dto';
import { FieldCourtDto } from '../../application/dto/field-court.dto';
import { FieldAvailabilityDto } from '../../application/dto/field-availability.dto';
import { FIELD_REPOSITORY } from '../../domain/repositories/field-repository.interface';
import { Inject } from '@nestjs/common';
import type { FieldRepositoryInterface } from '../../domain/repositories/field-repository.interface';

@ApiTags('fields')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields')
export class FieldsController {
  constructor(
    private readonly fieldService: FieldService,
    private readonly availabilityService: AvailabilityService,
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
  ) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem(FieldDto)
  @ApiOperation({ summary: 'Registrar campo' })
  register(
    @Body() dto: CreateFieldDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<FieldDto> {
    return this.fieldService.register(user.id, dto);
  }

  @Get()
  @Public()
  @HateoasList(FieldDto)
  @ApiOperation({ summary: 'Buscar campos por cidade ou geolocalização' })
  search(@Query() query: SearchFieldsDto): Promise<FieldDto[]> {
    return this.fieldService.searchNearby({
      city: query.city,
      lat: query.lat,
      lng: query.lng,
      radiusKm: query.radius,
    });
  }

  @Get(':id')
  @Public()
  @HateoasItem(FieldDto)
  @ApiOperation({ summary: 'Obter campo por ID' })
  getById(@Param('id') id: string): Promise<FieldDto> {
    return this.fieldService.getById(id);
  }

  @Get(':id/availability')
  @Public()
  @HateoasItem(FieldAvailabilityDto)
  @ApiOperation({ summary: 'Verificar disponibilidade do campo na data' })
  @ApiQuery({ name: 'date', description: 'Data no formato YYYY-MM-DD', example: '2026-06-15' })
  getAvailability(
    @Param('id') id: string,
    @Query('date') date: string,
  ): Promise<FieldAvailabilityDto> {
    return this.availabilityService.getAvailability(id, date);
  }

  @Post(':id/courts')
  @Permissions('fields:write')
  @HateoasItem(FieldCourtDto)
  @ApiOperation({ summary: 'Adicionar quadra ao campo' })
  addCourt(
    @Param('id') id: string,
    @Body() dto: CreateCourtDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<FieldCourtDto> {
    return this.fieldService.addCourt(user.id, id, dto);
  }

  @Get(':id/courts')
  @Public()
  @HateoasList(FieldCourtDto)
  @ApiOperation({ summary: 'Listar quadras do campo' })
  getCourts(@Param('id') id: string): Promise<FieldCourtDto[]> {
    return this.fieldService.getCourts(id);
  }

  @Put(':id/courts/:courtId/availability')
  @Permissions('fields:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Definir disponibilidade semanal da quadra' })
  setAvailability(
    @Param('id') id: string,
    @Param('courtId') courtId: string,
    @Body() dto: SetAvailabilityDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    // Valida que o usuário é dono do campo antes de delegar
    return this.fieldService.setAvailability(user.id, id, courtId, dto.slots);
  }
}
```

- [ ] **Step 2: Adicionar `setAvailability` ao FieldService**

Abra `field.service.ts` e adicione:

```typescript
import { SetAvailabilityDto } from '../dto/set-availability.dto';
import type { AvailabilitySlotData } from '../../domain/repositories/field-repository.interface';

// ... no final da classe FieldService:
async setAvailability(
  ownerUserId: string,
  fieldExternalId: string,
  courtExternalId: string,
  slots: Array<{ dayOfWeek: number; startTime: string; endTime: string; isAvailable: boolean }>,
): Promise<void> {
  const field = await this.fieldRepo.findById(fieldExternalId);
  if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
  if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can set availability');

  await this.fieldRepo.setAvailabilitySlots(courtExternalId, slots);
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/fields/infra/controllers/ services/field/src/modules/field/fields/application/services/field.service.ts
git commit -m "feat(field): add FieldsController with 7 endpoints"
```

---

### Task 28: ReservationsController + PlansController

**Files:**
- Create: `services/field/src/modules/field/reservations/infra/controllers/reservations.controller.ts`
- Create: `services/field/src/modules/field/plans/infra/controllers/plans.controller.ts`

- [ ] **Step 1: Criar reservations.controller.ts**

```typescript
import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { ReservationService } from '../../application/services/reservation.service';
import { CreateReservationDto } from '../../application/dto/create-reservation.dto';
import { ReservationDto } from '../../application/dto/reservation.dto';

@ApiTags('reservations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields/:fieldId/reservations')
export class ReservationsController {
  constructor(private readonly reservationService: ReservationService) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem(ReservationDto)
  @ApiOperation({ summary: 'Criar reserva manual/por telefone' })
  create(
    @Param('fieldId') fieldId: string,
    @Body() dto: CreateReservationDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReservationDto> {
    return this.reservationService.createManual(user.id, fieldId, dto);
  }

  @Get()
  @Permissions('fields:write')
  @HateoasList(ReservationDto)
  @ApiOperation({ summary: 'Listar reservas do campo' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  list(
    @Param('fieldId') fieldId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ): Promise<ReservationDto[]> {
    return this.reservationService.list(fieldId, Number(page), Number(limit));
  }

  @Delete(':reservationId')
  @Permissions('fields:write')
  @HateoasItem(ReservationDto)
  @ApiOperation({ summary: 'Cancelar reserva' })
  cancel(
    @Param('fieldId') fieldId: string,
    @Param('reservationId') reservationId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReservationDto> {
    return this.reservationService.cancel(user.id, fieldId, reservationId);
  }
}
```

- [ ] **Step 2: Criar plans.controller.ts**

```typescript
import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { RecurringPlanService } from '../../application/services/recurring-plan.service';
import { CreateRecurringPlanDto } from '../../application/dto/create-recurring-plan.dto';
import { RecurringPlanDto } from '../../application/dto/recurring-plan.dto';

@ApiTags('plans')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields/:fieldId/plans')
export class PlansController {
  constructor(private readonly planService: RecurringPlanService) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem(RecurringPlanDto)
  @ApiOperation({ summary: 'Criar plano recorrente para uma quadra' })
  create(
    @Param('fieldId') fieldId: string,
    @Body() dto: CreateRecurringPlanDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<RecurringPlanDto> {
    return this.planService.create(user.id, fieldId, dto);
  }

  @Get()
  @Public()
  @HateoasList(RecurringPlanDto)
  @ApiOperation({ summary: 'Listar planos recorrentes do campo' })
  list(@Param('fieldId') fieldId: string): Promise<RecurringPlanDto[]> {
    return this.planService.getByField(fieldId);
  }

  @Delete('slots/:slotId/release')
  @Permissions('fields:write')
  @ApiOperation({ summary: 'Liberar slot de plano recorrente para reserva avulsa' })
  releaseSlot(
    @Param('fieldId') fieldId: string,
    @Param('slotId') slotId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ id: string; status: string }> {
    return this.planService.releaseSlot(user.id, fieldId, slotId);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/field/src/modules/field/reservations/infra/controllers/ services/field/src/modules/field/plans/infra/controllers/
git commit -m "feat(field): add ReservationsController and PlansController"
```

---

### Task 29: Módulos NestJS

**Files:**
- Create: `services/field/src/modules/field/fields/fields.module.ts`
- Create: `services/field/src/modules/field/reservations/reservations.module.ts`
- Create: `services/field/src/modules/field/plans/plans.module.ts`
- Create: `services/field/src/modules/field/field.module.ts`

- [ ] **Step 1: Criar fields.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { FieldService } from './application/services/field.service';
import { AvailabilityService } from './application/services/availability.service';
import { FieldMessagingService } from './application/services/field-messaging.service';
import { DrizzleFieldRepository } from './infra/database/repositories/drizzle-field.repository';
import { FieldsController } from './infra/controllers/fields.controller';
import { FIELD_REPOSITORY } from './domain/repositories/field-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [FieldsController],
  providers: [
    FieldService,
    AvailabilityService,
    FieldMessagingService,
    { provide: FIELD_REPOSITORY, useClass: DrizzleFieldRepository },
  ],
  exports: [FIELD_REPOSITORY, FieldMessagingService],
})
export class FieldsModule {}
```

- [ ] **Step 2: Criar reservations.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { ReservationService } from './application/services/reservation.service';
import { DrizzleReservationRepository } from './infra/database/repositories/drizzle-reservation.repository';
import { ReservationsController } from './infra/controllers/reservations.controller';
import { RESERVATION_REPOSITORY } from './domain/repositories/reservation-repository.interface';
import { FieldsModule } from '../fields/fields.module';

@Module({
  imports: [SharedModule, FieldsModule],
  controllers: [ReservationsController],
  providers: [
    ReservationService,
    { provide: RESERVATION_REPOSITORY, useClass: DrizzleReservationRepository },
  ],
  exports: [RESERVATION_REPOSITORY],
})
export class ReservationsModule {}
```

- [ ] **Step 3: Criar plans.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { RecurringPlanService } from './application/services/recurring-plan.service';
import { DrizzleRecurringPlanRepository } from './infra/database/repositories/drizzle-recurring-plan.repository';
import { PlansController } from './infra/controllers/plans.controller';
import { RECURRING_PLAN_REPOSITORY } from './domain/repositories/recurring-plan-repository.interface';
import { FieldsModule } from '../fields/fields.module';

@Module({
  imports: [SharedModule, FieldsModule],
  controllers: [PlansController],
  providers: [
    RecurringPlanService,
    { provide: RECURRING_PLAN_REPOSITORY, useClass: DrizzleRecurringPlanRepository },
  ],
  exports: [RECURRING_PLAN_REPOSITORY],
})
export class PlansModule {}
```

- [ ] **Step 4: Criar field.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { FieldsModule } from './fields/fields.module';
import { ReservationsModule } from './reservations/reservations.module';
import { PlansModule } from './plans/plans.module';

@Module({
  imports: [FieldsModule, ReservationsModule, PlansModule],
})
export class FieldModule {}
```

- [ ] **Step 5: Commit**

```bash
git add services/field/src/modules/field/
git commit -m "feat(field): wire NestJS modules (fields, reservations, plans, field)"
```

---

### Task 30: `main.ts` + `app.module.ts`

**Files:**
- Create: `services/field/src/main.ts`
- Create: `services/field/src/app.module.ts`

- [ ] **Step 1: Criar main.ts**

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

- [ ] **Step 2: Criar app.module.ts**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FieldModule } from './modules/field/field.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    FieldModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 3: Rodar o build para validar compilação TypeScript**

```bash
npm run build
```

Expected: Nenhum erro de TypeScript. Diretório `dist/` criado.

- [ ] **Step 4: Commit**

```bash
git add services/field/src/main.ts services/field/src/app.module.ts services/field/dist/
git commit -m "feat(field): add main.ts and app.module.ts, build passing"
```

---

### Task 31: Geração da Migration

**Files:**
- Create: `services/field/drizzle/` (gerado pelo drizzle-kit)

- [ ] **Step 1: Garantir que o banco PostgreSQL + PostGIS esteja rodando**

```bash
# Na raiz do repositório
docker compose up postgres-field -d
```

Aguarde o healthcheck passar:

```bash
docker compose ps postgres-field
```

Expected: `Status: healthy`

- [ ] **Step 2: Gerar a migration com drizzle-kit**

```bash
cd services/field && DATABASE_URL="postgres://postgres:postgres@localhost:5434/bolanarededb_field" npm run db:generate
```

Expected: Arquivo criado em `drizzle/XXXX_<name>.sql` com CREATE TABLE para `fields`, `field_courts`, `availability_slots`, `reservations`, `recurring_plans`, `recurring_plan_slots`.

- [ ] **Step 3: Editar a migration para adicionar PostGIS**

Abra o arquivo `drizzle/XXXX_<name>.sql` e adicione **no início**, antes do primeiro `CREATE TABLE`:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
--> statement-breakpoint
```

E logo após a criação da tabela `fields` (após o `);`), adicione:

```sql
--> statement-breakpoint
ALTER TABLE "fields" ADD COLUMN IF NOT EXISTS "location" geometry(POINT,4326);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_fields_location" ON "fields" USING GIST ("location");
```

- [ ] **Step 4: Verificar o arquivo final da migration**

O início do arquivo deve ser:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "fields" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  ...
);
--> statement-breakpoint
ALTER TABLE "fields" ADD COLUMN IF NOT EXISTS "location" geometry(POINT,4326);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_fields_location" ON "fields" USING GIST ("location");
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "field_courts" (
  ...
```

- [ ] **Step 5: Rodar a migration para validar**

```bash
DATABASE_URL="postgres://postgres:postgres@localhost:5434/bolanarededb_field" node -e "
const { drizzle } = require('drizzle-orm/node-postgres');
const { migrate } = require('drizzle-orm/node-postgres/migrator');
const { Pool } = require('pg');
const path = require('path');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const db = drizzle(pool);
migrate(db, { migrationsFolder: path.join(__dirname, 'drizzle') })
  .then(() => { console.log('Migration OK'); pool.end(); })
  .catch((e) => { console.error(e); process.exit(1); });
"
```

Expected: `Migration OK`

- [ ] **Step 6: Commit**

```bash
git add services/field/drizzle/
git commit -m "feat(field): generate and patch Drizzle migration with PostGIS extension"
```

---

### Task 32: `scripts/migrate.js` + Dockerfile + docker-entrypoint.sh

**Files:**
- Create: `services/field/scripts/migrate.js`
- Create: `services/field/Dockerfile`
- Create: `services/field/docker-entrypoint.sh`

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

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/field/ ./services/field/

WORKDIR /app/services/field
RUN npm ci
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/field

COPY --from=builder /app/services/field/dist ./dist
COPY --from=builder /app/services/field/package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/services/field/drizzle ./drizzle
COPY services/field/scripts ./scripts
COPY services/field/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4003

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
```

- [ ] **Step 3: Criar docker-entrypoint.sh**

```sh
#!/bin/sh
set -e

echo "Running migrations..."
node /app/services/field/scripts/migrate.js

echo "Starting field service..."
exec node /app/services/field/dist/services/field/src/main
```

- [ ] **Step 4: Commit**

```bash
git add services/field/scripts/ services/field/Dockerfile services/field/docker-entrypoint.sh
git commit -m "feat(field): add migrate.js, Dockerfile and docker-entrypoint.sh"
```

---

### Task 33: `docker-compose.yml` — adicionar postgres-field + field service

**Files:**
- Modify: `docker-compose.yml` (na raiz do repositório)

- [ ] **Step 1: Adicionar postgres-field e field service**

Adicione ao `docker-compose.yml` (após o bloco `postgres-team`):

```yaml
  postgres-field:
    image: postgis/postgis:17-3.5
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bolanarededb_field
    ports:
      - "5434:5432"
    volumes:
      - postgres_field_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d bolanarededb_field"]
      interval: 5s
      timeout: 5s
      retries: 10
```

E no bloco `services:` (após o bloco `team`):

```yaml
  field:
    build:
      context: .
      dockerfile: services/field/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4003
      JWT_SECRET: bolanarededb-secret
      DATABASE_URL: postgres://postgres:postgres@postgres-field:5432/bolanarededb_field
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
    ports:
      - "4003:4003"
    depends_on:
      postgres-field:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
```

E no bloco `volumes:` (no final), adicione:

```yaml
  postgres_field_data:
```

- [ ] **Step 2: Validar o docker-compose.yml**

```bash
cd ../.. && docker compose config --quiet
```

Expected: Sem erros de sintaxe YAML.

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "chore(infra): add postgres-field (PostGIS) and field service to docker-compose"
```

---

### Task 34: Atualizar `_status.md`

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Atualizar a tabela de status**

Atualize a linha do `field` de:

```
| field        | ⏳ TODO  | 0/?        | —                            |
```

Para:

```
| field        | ✅ DONE  | 34/34      | —                            |
```

E adicione na seção `## Planos`:

```
- `docs/plans/2026-06-01-field-service.md` — 34 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs: mark field service as complete (34/34 tasks)"
```

---

## Self-Review

### Spec Coverage

| Requisito | Task |
|-----------|------|
| POST /v1/fields | Task 27 (FieldsController.register) |
| GET /v1/fields?city=&lat=&lng=&radius= | Task 27 (FieldsController.search) |
| GET /v1/fields/:id | Task 27 (FieldsController.getById) |
| GET /v1/fields/:id/availability?date= | Task 27 (FieldsController.getAvailability) |
| POST /v1/fields/:id/reservations | Task 28 (ReservationsController.create) |
| GET /v1/fields/:id/reservations | Task 28 (ReservationsController.list) |
| FieldEvents.REGISTERED | Task 26 |
| FieldEvents.RESERVATION_CONFIRMED | Task 26 |
| FieldEvents.RESERVATION_CANCELLED | Task 26 |
| FieldEvents.PLAN_SLOT_RELEASED | Task 26 |
| PostGIS location search | Tasks 16, 31 |
| FieldCourt management | Tasks 6, 13, 16, 19, 27 |
| AvailabilitySlot | Tasks 6, 10, 13, 16, 23 |
| RecurringPlan | Tasks 8, 12, 15, 18, 25, 28 |
| RecurringPlanSlot release | Tasks 8, 12, 15, 18, 25, 28 |
| Migration com PostGIS | Task 31 |
| Docker + docker-compose | Tasks 32, 33 |

### Type Consistency Check

- `FieldRepositoryInterface.findNearby(params: SearchFieldsParams)` → retorna `Field[]` → `FieldService.searchNearby()` → retorna `FieldDto[]` ✓
- `ReservationRepository.findOverlapping(courtExternalId, startsAt, endsAt)` — aceita string courtExternalId (UUID) ✓
- `AvailabilityService` usa `FIELD_REPOSITORY`, `RESERVATION_REPOSITORY`, `RECURRING_PLAN_REPOSITORY` — todos exportados pelos módulos correspondentes ✓
- `FieldsModule` exporta `FIELD_REPOSITORY` e `FieldMessagingService` — necessário para `ReservationsModule` e `PlansModule` ✓
- `RecurringPlanDto.from(plan)` usa os campos do `RecurringPlan` entity — consistente com Tasks 8 e 21 ✓

### Notas para o Developer

1. **PostGIS**: A imagem `postgis/postgis:17-3.5` pode não ter variante alpine estável — use a padrão (sem `-alpine`).
2. **Migration manual**: O drizzle-kit não sabe de colunas PostGIS, então a edição manual do arquivo `.sql` na Task 31 é obrigatória.
3. **`AvailabilityService` injeta 3 repositórios** — certifique-se que o `FieldsModule` exporta `FIELD_REPOSITORY` e que `ReservationsModule` e `PlansModule` exportam seus respectivos tokens para uso cruzado.
4. **Testes**: Os mocks de bigint nos testes de AvailabilitySlot usam `1n` (BigInt literal) — TypeScript deve aceitar isso com `isolatedModules: true`.
