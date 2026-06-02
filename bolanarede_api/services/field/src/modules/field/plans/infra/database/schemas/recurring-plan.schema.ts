import {
  pgTable,
  bigserial,
  uuid,
  bigint,
  text,
  smallint,
  boolean,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

export const recurringPlans = pgTable(
  'recurring_plans',
  {
    id: bigserial('id', { mode: 'bigint' }).primaryKey(),
    externalId: uuid('external_id').defaultRandom().notNull().unique(),
    courtId: bigint('court_id', { mode: 'bigint' })
      .notNull()
      .references(() => fieldCourts.id, { onDelete: 'cascade' }),
    fieldId: bigint('field_id', { mode: 'bigint' })
      .notNull()
      .references(() => fields.id, { onDelete: 'cascade' }),
    playerUserId: text('player_user_id'),
    dayOfWeek: smallint('day_of_week').notNull(),
    startTime: text('start_time').notNull(),
    endTime: text('end_time').notNull(),
    planStartsAt: timestamp('plan_starts_at', { withTimezone: true }).notNull(),
    planEndsAt: timestamp('plan_ends_at', { withTimezone: true }),
    isActive: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (t) => ({
    idxCourtActive: index('idx_recurring_plans_court_active').on(
      t.courtId,
      t.isActive,
    ),
  }),
);

export type RecurringPlanRow = typeof recurringPlans.$inferSelect;
export type NewRecurringPlanRow = typeof recurringPlans.$inferInsert;
