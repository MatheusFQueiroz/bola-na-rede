import {
  pgTable,
  bigserial,
  uuid,
  bigint,
  text,
  smallint,
  boolean,
  numeric,
} from 'drizzle-orm/pg-core';
import { fields } from './field.schema';

export const fieldCourts = pgTable('field_courts', {
  id: bigserial('id', { mode: 'bigint' }).primaryKey(),
  externalId: uuid('external_id').defaultRandom().notNull().unique(),
  fieldId: bigint('field_id', { mode: 'bigint' })
    .notNull()
    .references(() => fields.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  type: text('type').notNull(), // 'society' | 'futsal' | 'grass' | 'synthetic'
  maxPlayers: smallint('max_players').default(10).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  pricePerHour: numeric('price_per_hour', { precision: 10, scale: 2 }),
});

export type FieldCourtRow = typeof fieldCourts.$inferSelect;
export type NewFieldCourtRow = typeof fieldCourts.$inferInsert;
