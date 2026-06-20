import { pgTable, bigserial, text, integer, timestamp, unique } from 'drizzle-orm/pg-core';

export const playerRankings = pgTable(
  'player_rankings',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    displayName: text('display_name').notNull().default(''),
    sport: text('sport').notNull(),
    gamesPlayed: integer('games_played').notNull().default(0),
    wins: integer('wins').notNull().default(0),
    losses: integer('losses').notNull().default(0),
    draws: integer('draws').notNull().default(0),
    goals: integer('goals').notNull().default(0),
    assists: integer('assists').notNull().default(0),
    /** wins×3 + draws×1 */
    points: integer('points').notNull().default(0),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    unique('player_rankings_player_sport_unique').on(table.playerUserId, table.sport),
  ],
);

export type PlayerRankingRow = typeof playerRankings.$inferSelect;
