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
  sport: text('sport').notNull(),
  scheduledAt: timestamp('scheduled_at', { withTimezone: true }).notNull(),
  durationMinutes: smallint('duration_minutes').notNull().default(60),
  minPlayers: smallint('min_players').notNull().default(10),
  maxPlayers: smallint('max_players').notNull().default(22),
  pricePerPlayer: numeric('price_per_player', { precision: 10, scale: 2 }),
  status: text('status').notNull().default('open'),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type OpenGameRow = typeof openGames.$inferSelect;
export type NewOpenGameRow = typeof openGames.$inferInsert;
