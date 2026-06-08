import { Injectable } from '@nestjs/common';
import { eq, desc, and, inArray } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  MatchRequestRepositoryInterface,
  CreateMatchRequestData,
} from '../../../domain/repositories/match-request-repository.interface';
import type { MatchRequest, MatchRequestStatus } from '../../../domain/models/match-request.entity';
import { matchRequests, type MatchRequestRow } from '../schemas/match-request.schema';

@Injectable()
export class DrizzleMatchRequestRepository implements MatchRequestRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateMatchRequestData): Promise<MatchRequest> {
    const [row] = await this.drizzle.db
      .insert(matchRequests)
      .values({
        externalId: data.externalId,
        requesterUserId: data.requesterUserId,
        displayName: data.displayName,
        sport: data.sport,
        expiresAt: data.expiresAt,
        status: 'pending',
      })
      .returning();
    return this.toEntity(row);
  }

  async findByExternalId(externalId: string): Promise<MatchRequest | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(matchRequests)
      .where(eq(matchRequests.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async findActivByUserId(userId: string): Promise<MatchRequest | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(matchRequests)
      .where(eq(matchRequests.requesterUserId, userId))
      .orderBy(desc(matchRequests.requestedAt))
      .limit(1);

    if (!row) return null;
    if (row.status === 'pending' || row.status === 'matched') {
      // Lazy expiry: treat expired requests as inactive so user can create a new one
      if (row.expiresAt < new Date()) return null;
      return this.toEntity(row);
    }
    return null;
  }

  async updateStatus(externalId: string, status: MatchRequestStatus): Promise<void> {
    await this.drizzle.db
      .update(matchRequests)
      .set({ status, updatedAt: new Date() })
      .where(eq(matchRequests.externalId, externalId));
  }

  async updateDisplayName(userId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(matchRequests)
      .set({ displayName, updatedAt: new Date() })
      .where(
        and(
          eq(matchRequests.requesterUserId, userId),
          inArray(matchRequests.status, ['pending', 'matched']),
        ),
      );
  }

  private toEntity(row: MatchRequestRow): MatchRequest {
    return {
      id: row.id,
      externalId: row.externalId,
      requesterUserId: row.requesterUserId,
      displayName: row.displayName,
      sport: row.sport as MatchRequest['sport'],
      status: row.status as MatchRequest['status'],
      requestedAt: row.requestedAt,
      expiresAt: row.expiresAt,
      updatedAt: row.updatedAt,
    };
  }
}
