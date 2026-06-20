import { Injectable } from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { DeviceTokenRepositoryInterface } from '../../domain/repositories/device-token-repository.interface';
import type { DeviceToken } from '../../domain/models/device-token.entity';
import { deviceTokens, type DeviceTokenRow } from '../database/schemas/device-token.schema';
import { users } from '../../../users/infra/database/schemas/user.schema';

@Injectable()
export class DrizzleDeviceTokenRepository implements DeviceTokenRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<DeviceToken> {
    return this.drizzle.db.transaction(async (tx) => {
      const [userRow] = await tx
        .select({ id: users.id })
        .from(users)
        .where(eq(users.externalId, userId))
        .limit(1);

      if (!userRow) throw new Error(`User with externalId "${userId}" not found`);

      const [row] = await tx
        .insert(deviceTokens)
        .values({ userId: userRow.id, token, platform, isActive: true, updatedAt: new Date() })
        .onConflictDoUpdate({
          target: [deviceTokens.userId, deviceTokens.platform],
          set: { token, isActive: true, updatedAt: new Date() },
        })
        .returning();

      if (!row) throw new Error(`Failed to upsert device token for user "${userId}"`);

      return { userId, token: row.token, platform: row.platform as 'ios' | 'android', isActive: row.isActive, updatedAt: row.updatedAt };
    });
  }

  async findByUserId(userId: string): Promise<DeviceToken[]> {
    const rows = await this.drizzle.db
      .select({ dt: deviceTokens })
      .from(deviceTokens)
      .innerJoin(users, eq(users.id, deviceTokens.userId))
      .where(and(eq(users.externalId, userId), eq(deviceTokens.isActive, true)));

    return rows.map((r: { dt: DeviceTokenRow }) => ({
      userId,
      token: r.dt.token,
      platform: r.dt.platform as 'ios' | 'android',
      isActive: r.dt.isActive,
      updatedAt: r.dt.updatedAt,
    }));
  }
}
