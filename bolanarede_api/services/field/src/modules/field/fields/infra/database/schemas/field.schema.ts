import {
  pgTable,
  bigserial,
  uuid,
  text,
  boolean,
  doublePrecision,
  timestamp,
} from 'drizzle-orm/pg-core';

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
  createdAt: timestamp('created_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});

export type FieldRow = typeof fields.$inferSelect;
export type NewFieldRow = typeof fields.$inferInsert;
