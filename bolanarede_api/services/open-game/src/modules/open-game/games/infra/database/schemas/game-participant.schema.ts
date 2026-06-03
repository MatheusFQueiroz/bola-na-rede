import {
  pgTable,
  bigserial,
  bigint,
  text,
  timestamp,
} from 'drizzle-orm/pg-core';
import { openGames } from './open-game.schema';

export const gameParticipants = pgTable('game_participants', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  gameId: bigint('game_id', { mode: 'number' }).notNull().references(() => openGames.id),
  playerUserId: text('player_user_id').notNull(),
  displayName: text('display_name').notNull(),
  position: text('position'),
  joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
  leftAt: timestamp('left_at', { withTimezone: true }),
});

export type GameParticipantRow = typeof gameParticipants.$inferSelect;
export type NewGameParticipantRow = typeof gameParticipants.$inferInsert;
