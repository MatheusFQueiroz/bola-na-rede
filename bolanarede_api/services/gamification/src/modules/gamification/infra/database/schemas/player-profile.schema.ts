import { pgTable, bigserial, text, integer, smallint, timestamp } from 'drizzle-orm/pg-core';

export const playerProfiles = pgTable('player_profiles', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  playerUserId: text('player_user_id').notNull().unique(),
  displayName: text('display_name').notNull().default(''),
  totalXp: integer('total_xp').notNull().default(0),
  level: smallint('level').notNull().default(1),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PlayerProfileRow = typeof playerProfiles.$inferSelect;
