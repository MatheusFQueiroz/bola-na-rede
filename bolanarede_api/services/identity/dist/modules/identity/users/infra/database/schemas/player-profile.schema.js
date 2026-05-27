"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.playerProfiles = void 0;
const pg_core_1 = require("drizzle-orm/pg-core");
const user_schema_1 = require("./user.schema");
exports.playerProfiles = (0, pg_core_1.pgTable)('player_profiles', {
    id: (0, pg_core_1.bigserial)('id', { mode: 'number' }).primaryKey(),
    userId: (0, pg_core_1.bigint)('user_id', { mode: 'number' })
        .notNull()
        .references(() => user_schema_1.users.id, { onDelete: 'cascade' }),
    displayName: (0, pg_core_1.text)('display_name').notNull(),
    photoUrl: (0, pg_core_1.text)('photo_url'),
    bio: (0, pg_core_1.text)('bio'),
    city: (0, pg_core_1.text)('city'),
    position: (0, pg_core_1.text)('position'),
    skillLevel: (0, pg_core_1.smallint)('skill_level'),
    isPublic: (0, pg_core_1.boolean)('is_public').notNull().default(true),
    createdAt: (0, pg_core_1.timestamp)('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: (0, pg_core_1.timestamp)('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [(0, pg_core_1.uniqueIndex)('uq_player_profiles_user_id').on(table.userId)]);
