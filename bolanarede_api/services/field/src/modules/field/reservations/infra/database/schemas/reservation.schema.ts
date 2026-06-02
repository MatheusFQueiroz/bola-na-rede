import {
  pgTable,
  bigserial,
  uuid,
  bigint,
  text,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

export const reservations = pgTable(
  'reservations',
  {
    id: bigserial('id', { mode: 'bigint' }).primaryKey(),
    externalId: uuid('external_id').defaultRandom().notNull().unique(),
    courtId: bigint('court_id', { mode: 'bigint' })
      .notNull()
      .references(() => fieldCourts.id, { onDelete: 'cascade' }),
    fieldId: bigint('field_id', { mode: 'bigint' })
      .notNull()
      .references(() => fields.id, { onDelete: 'cascade' }),
    playerUserId: text('player_user_id'), // null para manual/phone
    channel: text('channel').notNull(), // 'app' | 'manual' | 'phone'
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
    status: text('status').default('confirmed').notNull(), // 'confirmed' | 'cancelled'
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (t) => ({
    idxCourtStatus: index('idx_reservations_court_status').on(
      t.courtId,
      t.status,
    ),
    idxFieldId: index('idx_reservations_field_id').on(t.fieldId),
  }),
);

export type ReservationRow = typeof reservations.$inferSelect;
export type NewReservationRow = typeof reservations.$inferInsert;
