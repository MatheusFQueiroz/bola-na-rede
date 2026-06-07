import { pgTable, bigserial, text, timestamp, unique } from 'drizzle-orm/pg-core';

export const playerBadges = pgTable(
  'player_badges',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    badgeCode: text('badge_code').notNull(),
    earnedAt: timestamp('earned_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_player_badge').on(t.playerUserId, t.badgeCode)],
);

export type PlayerBadgeRow = typeof playerBadges.$inferSelect;
