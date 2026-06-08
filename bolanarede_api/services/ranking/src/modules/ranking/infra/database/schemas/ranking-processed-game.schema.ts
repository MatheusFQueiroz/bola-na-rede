import { pgTable, bigserial, text, timestamp } from 'drizzle-orm/pg-core';

export const rankingProcessedGames = pgTable('ranking_processed_games', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  gameId: text('game_id').notNull().unique(),
  processedAt: timestamp('processed_at', { withTimezone: true }).defaultNow().notNull(),
});
