# Drizzle ORM — Padrões do Projeto

O projeto usa **Drizzle ORM**, não TypeORM. Nunca usar decorators TypeORM (`@Entity`, `@Column`, `@PrimaryGeneratedColumn` etc.).

## drizzle.config.ts (igual em todo serviço)

```typescript
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/**/schemas/*.schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
} satisfies Config;
```

## Definição de Schema

```typescript
// infra/database/schemas/open-game.schema.ts
import {
  pgTable,
  uuid,
  text,
  timestamp,
  integer,
  boolean,
  jsonb,
  smallint,
} from 'drizzle-orm/pg-core';

export const openGames = pgTable('open_games', {
  id: uuid('id').defaultRandom().primaryKey(),
  organizerId: text('organizer_id').notNull(),
  organizerSnapshot: jsonb('organizer_snapshot').notNull().default({}),
  fieldId: text('field_id'),
  fieldSnapshot: jsonb('field_snapshot').notNull().default({}),
  title: text('title').notNull(),
  type: text('type').notNull().default('OPEN'),
  status: text('status').notNull().default('OPEN'),
  scheduledAt: timestamp('scheduled_at', { withTimezone: true }).notNull(),
  durationMin: smallint('duration_min').notNull().default(60),
  maxPlayers: smallint('max_players').notNull(),
  minPlayers: smallint('min_players'),
  confirmedCount: smallint('confirmed_count').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// Sempre exportar os tipos inferidos
export type OpenGame = typeof openGames.$inferSelect;
export type NewOpenGame = typeof openGames.$inferInsert;
```

## Tipos Drizzle Disponíveis

```typescript
// Tipos mais usados no projeto
uuid('col'); // UUID com defaultRandom()
text('col'); // TEXT (nunca VARCHAR)
integer('col'); // INT4
smallint('col'); // INT2
boolean('col'); // BOOLEAN
numeric('col', { precision: 8, scale: 2 }); // NUMERIC(8,2) para dinheiro
jsonb('col'); // JSONB para snapshots
timestamp('col', { withTimezone: true }); // TIMESTAMPTZ
date('col') // DATE
  // Modificadores
  .primaryKey()
  .notNull()
  .default(value)
  .defaultNow()
  .defaultRandom() // para UUID
  .unique()
  .references(() => outroSchema.col); // FK (só dentro do mesmo serviço)
```

## DrizzleService (do shared)

```typescript
// shared/src/infra/database/drizzle.service.ts
// Já está implementado no shared. Injetar via construtor.
import { DrizzleService } from '@shared/infra/database/drizzle.service';
```

## Implementação do Repository

```typescript
// infra/repositories/drizzle-open-game.repository.ts
import { Injectable } from '@nestjs/common';
import { eq, and, desc, isNull } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import { OpenGameRepositoryInterface } from '../../domain/repositories/open-game-repository.interface';
import { OpenGame } from '../../domain/models/open-game.entity';
import { openGames } from '../database/schemas/open-game.schema';

@Injectable()
export class DrizzleOpenGameRepository implements OpenGameRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async findById(id: string): Promise<OpenGame | null> {
    const [result] = await this.drizzle.db
      .select()
      .from(openGames)
      .where(eq(openGames.id, id))
      .limit(1);

    return result ?? null;
  }

  async findAll(): Promise<OpenGame[]> {
    return this.drizzle.db
      .select()
      .from(openGames)
      .where(eq(openGames.status, 'OPEN'))
      .orderBy(desc(openGames.scheduledAt));
  }

  async create(data: Partial<OpenGame>): Promise<OpenGame> {
    const [result] = await this.drizzle.db
      .insert(openGames)
      .values(data as any)
      .returning();

    return result;
  }

  async update(id: string, data: Partial<OpenGame>): Promise<OpenGame> {
    const [result] = await this.drizzle.db
      .update(openGames)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(openGames.id, id))
      .returning();

    return result;
  }

  async delete(id: string): Promise<void> {
    await this.drizzle.db.delete(openGames).where(eq(openGames.id, id));
  }
}
```

## Queries Comuns

```typescript
// Filtro simples
.where(eq(table.field, value))

// Múltiplos filtros
.where(and(
  eq(table.status, 'OPEN'),
  eq(table.city, city),
))

// Soft delete (deletedAt IS NULL)
.where(isNull(table.deletedAt))

// Ordenação
.orderBy(desc(table.createdAt))
.orderBy(asc(table.scheduledAt))

// Paginação
.limit(20)
.offset(page * 20)

// Incremento atômico
.update(table)
.set({ count: sql`${table.count} + 1` })

// Upsert (usado em projeções locais)
.insert(table)
.values(data)
.onConflictDoUpdate({
  target: table.playerId,
  set: { displayName: data.displayName, updatedAt: new Date() },
})
```

## Migrations

```bash
# Gerar migration após alterar schema
npm run db:generate

# Aplicar migrations
npm run db:migrate
```

### package.json de cada serviço

```json
{
  "scripts": {
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "start:dev": "nest start --watch",
    "build": "nest build"
  }
}
```

## Schema de Projeção Local (cross-service)

Quando um serviço precisa de dados de outro, cria um schema local atualizado via eventos:

```typescript
// open-game/infra/database/schemas/player-summary.schema.ts
// Projeção local de dados do identity-service
import {
  pgTable,
  text,
  numeric,
  integer,
  timestamp,
} from 'drizzle-orm/pg-core';

export const playerSummaries = pgTable('player_summaries', {
  playerId: text('player_id').primaryKey(), // = users.external_id
  displayName: text('display_name').notNull(),
  photoUrl: text('photo_url'),
  city: text('city'),
  position: text('position'),
  overallScore: numeric('overall_score', { precision: 3, scale: 1 })
    .notNull()
    .default('0.0'),
  reviewCount: integer('review_count').notNull().default(0),
  syncedAt: timestamp('synced_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});
```

## Padrões de Coluna por Tipo de Dado

| Dado                       | Tipo Drizzle                          | Motivo                             |
| -------------------------- | ------------------------------------- | ---------------------------------- |
| ID primário                | `uuid().defaultRandom().primaryKey()` | UUID padrão                        |
| ID externo (cross-service) | `text()`                              | UUID de outro serviço, sem FK real |
| Texto qualquer             | `text()`                              | Nunca `varchar(n)`                 |
| Enum de status             | `text()` com `.default('OPEN')`       | Flexível, validado na app          |
| Dinheiro                   | `numeric({ precision: 8, scale: 2 })` | Nunca float                        |
| JSON/Snapshot              | `jsonb()`                             | Flexível para snapshots            |
| Data + hora                | `timestamp({ withTimezone: true })`   | Sempre com timezone                |
| Data apenas                | `date()`                              | Para campos de data sem hora       |
| Flags                      | `boolean()`                           | Nunca `smallint` para boolean      |
| Contadores                 | `integer()` ou `smallint()`           | smallint para valores pequenos     |
