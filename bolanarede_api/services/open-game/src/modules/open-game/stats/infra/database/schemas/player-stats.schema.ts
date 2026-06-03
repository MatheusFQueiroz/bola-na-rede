import {
  pgTable,
  bigserial,
  bigint,
  text,
  smallint,
  timestamp,
  unique,
} from 'drizzle-orm/pg-core';
import { openGames } from '../../../games/infra/database/schemas/open-game.schema';

export const playerStats = pgTable(
  'player_stats',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    gameId: bigint('game_id', { mode: 'number' }).notNull().references(() => openGames.id),
    playerUserId: text('player_user_id').notNull(),
    goals: smallint('goals').notNull().default(0),
    assists: smallint('assists').notNull().default(0),
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_player_stats_game_player').on(t.gameId, t.playerUserId)],
);

export type PlayerStatsRow = typeof playerStats.$inferSelect;
export type NewPlayerStatsRow = typeof playerStats.$inferInsert;
