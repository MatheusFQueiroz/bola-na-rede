"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.DrizzleUserRepository = void 0;
const common_1 = require("@nestjs/common");
const drizzle_orm_1 = require("drizzle-orm");
const drizzle_service_1 = require("@shared/infra/database/drizzle.service");
const user_schema_1 = require("../database/schemas/user.schema");
const credential_schema_1 = require("../database/schemas/credential.schema");
const player_profile_schema_1 = require("../database/schemas/player-profile.schema");
let DrizzleUserRepository = class DrizzleUserRepository {
    constructor(drizzle) {
        this.drizzle = drizzle;
    }
    async findById(externalId) {
        const [row] = await this.drizzle.db
            .select()
            .from(user_schema_1.users)
            .where((0, drizzle_orm_1.and)((0, drizzle_orm_1.eq)(user_schema_1.users.externalId, externalId), (0, drizzle_orm_1.isNull)(user_schema_1.users.deletedAt)))
            .limit(1);
        return row ? this.toUser(row) : null;
    }
    async findByEmail(email) {
        const [row] = await this.drizzle.db
            .select({ user: user_schema_1.users, credential: credential_schema_1.credentials })
            .from(user_schema_1.users)
            .leftJoin(credential_schema_1.credentials, (0, drizzle_orm_1.eq)(credential_schema_1.credentials.userId, user_schema_1.users.id))
            .where((0, drizzle_orm_1.and)((0, drizzle_orm_1.eq)(user_schema_1.users.email, email), (0, drizzle_orm_1.isNull)(user_schema_1.users.deletedAt)))
            .limit(1);
        if (!row)
            return null;
        return { ...this.toUser(row.user), passwordHash: row.credential?.passwordHash ?? null };
    }
    async create(data) {
        return this.drizzle.db.transaction(async (tx) => {
            const [userRow] = await tx
                .insert(user_schema_1.users)
                .values({ email: data.email })
                .returning();
            await tx.insert(credential_schema_1.credentials).values({
                userId: userRow.id,
                provider: 'email',
                passwordHash: data.passwordHash,
            });
            await tx.insert(player_profile_schema_1.playerProfiles).values({
                userId: userRow.id,
                displayName: data.displayName,
            });
            return this.toUser(userRow);
        });
    }
    async findProfileById(userId) {
        const [row] = await this.drizzle.db
            .select({ profile: player_profile_schema_1.playerProfiles, externalId: user_schema_1.users.externalId })
            .from(player_profile_schema_1.playerProfiles)
            .innerJoin(user_schema_1.users, (0, drizzle_orm_1.eq)(user_schema_1.users.id, player_profile_schema_1.playerProfiles.userId))
            .where((0, drizzle_orm_1.eq)(user_schema_1.users.externalId, userId))
            .limit(1);
        return row ? this.toProfile(row.profile, row.externalId) : null;
    }
    async updateProfile(userId, data) {
        const [userRow] = await this.drizzle.db
            .select({ id: user_schema_1.users.id, externalId: user_schema_1.users.externalId })
            .from(user_schema_1.users)
            .where((0, drizzle_orm_1.eq)(user_schema_1.users.externalId, userId))
            .limit(1);
        if (!userRow) {
            throw new Error(`User with externalId "${userId}" not found`);
        }
        const updateData = { updatedAt: new Date() };
        if (data.displayName !== undefined)
            updateData.displayName = data.displayName;
        if (data.photoUrl !== undefined)
            updateData.photoUrl = data.photoUrl;
        if (data.bio !== undefined)
            updateData.bio = data.bio;
        if (data.city !== undefined)
            updateData.city = data.city;
        if (data.position !== undefined)
            updateData.position = data.position;
        if (data.skillLevel !== undefined)
            updateData.skillLevel = data.skillLevel;
        if (data.isPublic !== undefined)
            updateData.isPublic = data.isPublic;
        const [row] = await this.drizzle.db
            .update(player_profile_schema_1.playerProfiles)
            .set(updateData)
            .where((0, drizzle_orm_1.eq)(player_profile_schema_1.playerProfiles.userId, userRow.id))
            .returning();
        if (!row) {
            throw new Error(`PlayerProfile not found for user "${userRow.externalId}"`);
        }
        return this.toProfile(row, userRow.externalId);
    }
    toUser(row) {
        return {
            id: row.externalId,
            email: row.email,
            phone: row.phone,
            status: row.status,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt ?? null,
        };
    }
    toProfile(row, externalId) {
        return {
            id: externalId,
            displayName: row.displayName,
            photoUrl: row.photoUrl ?? null,
            bio: row.bio ?? null,
            city: row.city ?? null,
            position: row.position,
            skillLevel: row.skillLevel ?? null,
            isPublic: row.isPublic,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
        };
    }
};
exports.DrizzleUserRepository = DrizzleUserRepository;
exports.DrizzleUserRepository = DrizzleUserRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof drizzle_service_1.DrizzleService !== "undefined" && drizzle_service_1.DrizzleService) === "function" ? _a : Object])
], DrizzleUserRepository);
