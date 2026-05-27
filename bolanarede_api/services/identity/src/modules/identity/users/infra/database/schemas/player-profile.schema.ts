import {
  pgTable,
  bigserial,
  bigint,
  text,
  smallint,
  boolean,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { users } from './user.schema';

export const playerProfiles = pgTable(
  'player_profiles',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    userId: bigint('user_id', { mode: 'number' })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    displayName: text('display_name').notNull(),
    photoUrl: text('photo_url'),
    bio: text('bio'),
    city: text('city'),
    position: text('position'),
    skillLevel: smallint('skill_level'),
    isPublic: boolean('is_public').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [uniqueIndex('uq_player_profiles_user_id').on(table.userId)],
);

export type PlayerProfileRow = typeof playerProfiles.$inferSelect;
export type NewPlayerProfileRow = typeof playerProfiles.$inferInsert;
