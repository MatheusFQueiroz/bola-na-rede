import { Injectable } from '@nestjs/common';
import { and, eq, isNull } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateUserData,
  UserRepositoryInterface,
  UserWithCredential,
} from '../../domain/repositories/user-repository.interface';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import { users, type UserRow } from '../database/schemas/user.schema';
import { credentials } from '../database/schemas/credential.schema';
import { playerProfiles, type PlayerProfileRow } from '../database/schemas/player-profile.schema';

@Injectable()
export class DrizzleUserRepository implements UserRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async findById(externalId: string): Promise<User | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(users)
      .where(and(eq(users.externalId, externalId), isNull(users.deletedAt)))
      .limit(1);
    return row ? this.toUser(row) : null;
  }

  async findByEmail(email: string): Promise<UserWithCredential | null> {
    const [row] = await this.drizzle.db
      .select({ user: users, credential: credentials })
      .from(users)
      .leftJoin(credentials, eq(credentials.userId, users.id))
      .where(and(eq(users.email, email), isNull(users.deletedAt)))
      .limit(1);

    if (!row) return null;
    return { ...this.toUser(row.user), passwordHash: row.credential?.passwordHash ?? null };
  }

  async create(data: CreateUserData): Promise<User> {
    return this.drizzle.db.transaction(async (tx) => {
      const [userRow] = await tx
        .insert(users)
        .values({ email: data.email })
        .returning();

      await tx.insert(credentials).values({
        userId: userRow.id,
        provider: 'email',
        passwordHash: data.passwordHash,
      });

      await tx.insert(playerProfiles).values({
        userId: userRow.id,
        displayName: data.displayName,
      });

      return this.toUser(userRow);
    });
  }

  async findProfileById(userId: string): Promise<PlayerProfile | null> {
    const [row] = await this.drizzle.db
      .select({ profile: playerProfiles, externalId: users.externalId })
      .from(playerProfiles)
      .innerJoin(users, eq(users.id, playerProfiles.userId))
      .where(eq(users.externalId, userId))
      .limit(1);

    return row ? this.toProfile(row.profile, row.externalId) : null;
  }

  async updateProfile(userId: string, data: Partial<PlayerProfile>): Promise<PlayerProfile> {
    const [userRow] = await this.drizzle.db
      .select({ id: users.id, externalId: users.externalId })
      .from(users)
      .where(eq(users.externalId, userId))
      .limit(1);

    if (!userRow) {
      throw new Error(`User with externalId "${userId}" not found`);
    }

    const updateData: Partial<typeof playerProfiles.$inferInsert> = { updatedAt: new Date() };
    if (data.displayName !== undefined) updateData.displayName = data.displayName;
    if (data.photoUrl !== undefined) updateData.photoUrl = data.photoUrl;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.city !== undefined) updateData.city = data.city;
    if (data.position !== undefined) updateData.position = data.position;
    if (data.skillLevel !== undefined) updateData.skillLevel = data.skillLevel;
    if (data.isPublic !== undefined) updateData.isPublic = data.isPublic;

    const [row] = await this.drizzle.db
      .update(playerProfiles)
      .set(updateData)
      .where(eq(playerProfiles.userId, userRow.id))
      .returning();

    if (!row) {
      throw new Error(`PlayerProfile not found for user "${userRow.externalId}"`);
    }

    return this.toProfile(row, userRow.externalId);
  }

  private toUser(row: UserRow): User {
    return {
      id: row.externalId,
      email: row.email,
      phone: row.phone,
      status: row.status as 'ACTIVE' | 'ANONYMIZED',
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt ?? null,
    };
  }

  private toProfile(row: PlayerProfileRow, externalId: string): PlayerProfile {
    return {
      id: externalId,
      displayName: row.displayName,
      photoUrl: row.photoUrl ?? null,
      bio: row.bio ?? null,
      city: row.city ?? null,
      position: row.position as PlayerProfile['position'],
      skillLevel: row.skillLevel ?? null,
      isPublic: row.isPublic,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
