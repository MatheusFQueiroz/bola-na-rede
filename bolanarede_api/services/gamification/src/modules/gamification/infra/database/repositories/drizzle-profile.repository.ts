import { Injectable } from '@nestjs/common';
import { eq, desc, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { ProfileRepositoryInterface } from '../../../domain/repositories/profile-repository.interface';
import type { PlayerProfile } from '../../../domain/models/player-profile.entity';
import { playerProfiles, type PlayerProfileRow } from '../schemas/player-profile.schema';

@Injectable()
export class DrizzleProfileRepository implements ProfileRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsertProfile(playerUserId: string, displayName: string): Promise<PlayerProfile> {
    const [row] = await this.drizzle.db
      .insert(playerProfiles)
      .values({ playerUserId, displayName, totalXp: 0, level: 1 })
      .onConflictDoUpdate({
        target: playerProfiles.playerUserId,
        set: { updatedAt: new Date() },
      })
      .returning();
    return this.toProfile(row);
  }

  async findByPlayer(playerUserId: string): Promise<PlayerProfile | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerProfiles)
      .where(eq(playerProfiles.playerUserId, playerUserId))
      .limit(1);
    return row ? this.toProfile(row) : null;
  }

  async addXp(playerUserId: string, xpToAdd: number): Promise<PlayerProfile> {
    const newTotalXp = sql<number>`${playerProfiles.totalXp} + ${xpToAdd}`;
    const newLevel = sql<number>`floor((${playerProfiles.totalXp} + ${xpToAdd}) / 100) + 1`;

    const [row] = await this.drizzle.db
      .update(playerProfiles)
      .set({
        totalXp: newTotalXp,
        level: newLevel,
        updatedAt: new Date(),
      })
      .where(eq(playerProfiles.playerUserId, playerUserId))
      .returning();

    if (!row) throw new Error(`PlayerProfile "${playerUserId}" not found`);
    return this.toProfile(row);
  }

  async updateDisplayName(playerUserId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerProfiles)
      .set({ displayName, updatedAt: new Date() })
      .where(eq(playerProfiles.playerUserId, playerUserId));
  }

  async findTopByXp(limit: number): Promise<PlayerProfile[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerProfiles)
      .orderBy(desc(playerProfiles.totalXp))
      .limit(limit);
    return rows.map((r) => this.toProfile(r));
  }

  private toProfile(row: PlayerProfileRow): PlayerProfile {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      totalXp: row.totalXp,
      level: row.level,
      updatedAt: row.updatedAt,
    };
  }
}
