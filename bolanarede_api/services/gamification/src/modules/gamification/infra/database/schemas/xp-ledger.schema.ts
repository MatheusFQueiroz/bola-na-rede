import { pgTable, bigserial, text, smallint, timestamp, unique } from 'drizzle-orm/pg-core';

export const xpLedger = pgTable(
  'xp_ledger',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    playerUserId: text('player_user_id').notNull(),
    sourceType: text('source_type').notNull(),
    sourceId: text('source_id').notNull(),
    xpEarned: smallint('xp_earned').notNull(),
    reason: text('reason').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [unique('uq_xp_ledger_player_source_reason').on(t.playerUserId, t.sourceId, t.reason)],
);

export type XpLedgerRow = typeof xpLedger.$inferSelect;
