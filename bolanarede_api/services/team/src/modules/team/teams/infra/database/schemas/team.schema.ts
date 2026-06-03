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
