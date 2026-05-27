"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.credentials = void 0;
const pg_core_1 = require("drizzle-orm/pg-core");
const user_schema_1 = require("./user.schema");
exports.credentials = (0, pg_core_1.pgTable)('credentials', {
    id: (0, pg_core_1.bigserial)('id', { mode: 'number' }).primaryKey(),
    userId: (0, pg_core_1.bigint)('user_id', { mode: 'number' })
        .notNull()
        .references(() => user_schema_1.users.id, { onDelete: 'cascade' }),
    provider: (0, pg_core_1.text)('provider').notNull().default('email'),
    passwordHash: (0, pg_core_1.text)('password_hash'),
    createdAt: (0, pg_core_1.timestamp)('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: (0, pg_core_1.timestamp)('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
