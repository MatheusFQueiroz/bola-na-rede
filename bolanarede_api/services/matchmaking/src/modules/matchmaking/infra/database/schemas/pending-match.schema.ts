import { pgTable, bigserial, text, boolean, timestamp } from 'drizzle-orm/pg-core';

export const pendingMatches = pgTable('pending_matches', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  externalId: text('external_id').notNull().unique(),
  requestAExternalId: text('request_a_external_id').notNull(),
  requestBExternalId: text('request_b_external_id').notNull(),
  userAId: text('user_a_id').notNull(),
  userBId: text('user_b_id').notNull(),
  sport: text('sport').notNull(),
  status: text('status').notNull().default('proposed'),
  acceptedByA: boolean('accepted_by_a').notNull().default(false),
  acceptedByB: boolean('accepted_by_b').notNull().default(false),
  proposedAt: timestamp('proposed_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PendingMatchRow = typeof pendingMatches.$inferSelect;
