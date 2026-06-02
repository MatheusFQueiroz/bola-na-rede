import {
  pgTable,
  bigserial,
  bigint,
  text,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { teams } from './team.schema';

export const teamMembers = pgTable(
  'team_members',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    teamId: bigint('team_id', { mode: 'number' })
      .notNull()
      .references(() => teams.id, { onDelete: 'cascade' }),
    playerUserId: text('player_user_id').notNull(),  // identity UUID, no FK constraint
    displayName: text('display_name').notNull(),
    position: text('position'),
    role: text('role').notNull().default('member'),  // 'captain' | 'member'
    joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
    leftAt: timestamp('left_at', { withTimezone: true }),  // null = active member
  },
  (table) => [
    index('idx_team_members_team_id').on(table.teamId),
    index('idx_team_members_player_user_id').on(table.playerUserId),
  ],
);

export type TeamMemberRow = typeof teamMembers.$inferSelect;
export type NewTeamMemberRow = typeof teamMembers.$inferInsert;
