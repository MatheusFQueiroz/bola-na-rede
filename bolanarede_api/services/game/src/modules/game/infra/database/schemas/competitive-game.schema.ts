import { pgTable, bigserial, text, integer, timestamp } from 'drizzle-orm/pg-core';

export const competitiveGames = pgTable('competitive_games', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  /** UNIQUE garante idempotência: MATCH_ACCEPTED re-entregue não cria duplicata */
  matchId: text('match_id').notNull().unique(),
  userAId: text('user_a_id').notNull(),
  userBId: text('user_b_id').notNull(),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('scheduled'),
  playerAGoals: integer('player_a_goals').notNull().default(0),
  playerBGoals: integer('player_b_goals').notNull().default(0),
  playerAAssists: integer('player_a_assists').notNull().default(0),
  playerBAssists: integer('player_b_assists').notNull().default(0),
  winnerId: text('winner_id'),
  submittedByUserId: text('submitted_by_user_id'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type CompetitiveGameRow = typeof competitiveGames.$inferSelect;
