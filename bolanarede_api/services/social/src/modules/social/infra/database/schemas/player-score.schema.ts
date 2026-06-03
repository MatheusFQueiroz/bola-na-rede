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
