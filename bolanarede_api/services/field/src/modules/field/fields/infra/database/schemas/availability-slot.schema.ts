import {
  pgTable,
  bigserial,
  bigint,
  smallint,
  text,
  boolean,
  index,
} from 'drizzle-orm/pg-core';
import { fieldCourts } from './field-court.schema';

export const availabilitySlots = pgTable(
  'availability_slots',
  {
    id: bigserial('id', { mode: 'bigint' }).primaryKey(),
    courtId: bigint('court_id', { mode: 'bigint' })
      .notNull()
      .references(() => fieldCourts.id, { onDelete: 'cascade' }),
    dayOfWeek: smallint('day_of_week').notNull(), // 0=Dom ... 6=Sáb
    startTime: text('start_time').notNull(), // "HH:MM"
    endTime: text('end_time').notNull(), // "HH:MM"
    isAvailable: boolean('is_available').default(true).notNull(),
  },
  (t) => ({
    idxCourtDay: index('idx_availability_slots_court_day').on(
      t.courtId,
      t.dayOfWeek,
    ),
  }),
);

export type AvailabilitySlotRow = typeof availabilitySlots.$inferSelect;
