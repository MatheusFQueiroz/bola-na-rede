import { pgTable, bigserial, text, timestamp } from 'drizzle-orm/pg-core';

export const matchRequests = pgTable('match_requests', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  requesterUserId: text('requester_user_id').notNull(),
  displayName: text('display_name').notNull().default(''),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('pending'),
  requestedAt: timestamp('requested_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type MatchRequestRow = typeof matchRequests.$inferSelect;
