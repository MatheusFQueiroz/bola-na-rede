import {
  pgTable,
  bigserial,
  uuid,
  text,
  smallint,
  timestamp,
  unique,
} from 'drizzle-orm/pg-core';

export const playerReviews = pgTable(
  'player_reviews',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    externalId: uuid('external_id').defaultRandom().notNull().unique(),
    gameId: text('game_id').notNull(),
    gameType: text('game_type').notNull(),
    reviewerUserId: text('reviewer_user_id').notNull(),
    reviewerDisplayName: text('reviewer_display_name').notNull(),
    revieweeUserId: text('reviewee_user_id').notNull(),
    revieweeDisplayName: text('reviewee_display_name').notNull(),
    score: smallint('score').notNull(),
    comment: text('comment'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    unique('uq_review_reviewer_game').on(t.reviewerUserId, t.gameId),
  ],
);

export type PlayerReviewRow = typeof playerReviews.$inferSelect;
export type NewPlayerReviewRow = typeof playerReviews.$inferInsert;
