import {
  pgTable,
  bigserial,
  uuid,
  bigint,
  text,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { recurringPlans } from './recurring-plan.schema';
import { fields } from '../../../../fields/infra/database/schemas/field.schema';

export const recurringPlanSlots = pgTable(
  'recurring_plan_slots',
  {
    id: bigserial('id', { mode: 'bigint' }).primaryKey(),
    externalId: uuid('external_id').defaultRandom().notNull().unique(),
    planId: bigint('plan_id', { mode: 'bigint' })
      .notNull()
      .references(() => recurringPlans.id, { onDelete: 'cascade' }),
    fieldId: bigint('field_id', { mode: 'bigint' })
      .notNull()
      .references(() => fields.id, { onDelete: 'cascade' }),
    slotDate: timestamp('slot_date', { withTimezone: true }).notNull(),
    status: text('status').default('active').notNull(), // 'active' | 'released' | 'cancelled'
  },
  (t) => ({
    idxPlanDate: index('idx_recurring_plan_slots_plan_date').on(
      t.planId,
      t.slotDate,
    ),
    idxFieldDate: index('idx_recurring_plan_slots_field_date').on(
      t.fieldId,
      t.slotDate,
    ),
  }),
);

export type RecurringPlanSlotRow = typeof recurringPlanSlots.$inferSelect;
