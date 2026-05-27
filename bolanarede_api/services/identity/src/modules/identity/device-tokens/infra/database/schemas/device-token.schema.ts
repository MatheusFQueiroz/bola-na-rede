import {
  pgTable,
  bigserial,
  bigint,
  text,
  boolean,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { users } from '../../../../users/infra/database/schemas/user.schema';

export const deviceTokens = pgTable(
  'device_tokens',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    userId: bigint('user_id', { mode: 'number' })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    token: text('token').notNull(),
    platform: text('platform').notNull(),
    isActive: boolean('is_active').notNull().default(true),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('uq_device_tokens_user_platform').on(table.userId, table.platform),
  ],
);

export type DeviceTokenRow = typeof deviceTokens.$inferSelect;
