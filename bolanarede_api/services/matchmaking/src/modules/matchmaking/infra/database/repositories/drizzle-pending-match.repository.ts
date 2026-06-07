import { Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  PendingMatchRepositoryInterface,
  CreatePendingMatchData,
} from '../../../domain/repositories/pending-match-repository.interface';
import type { PendingMatch, PendingMatchStatus } from '../../../domain/models/pending-match.entity';
import { pendingMatches, type PendingMatchRow } from '../schemas/pending-match.schema';

@Injectable()
export class DrizzlePendingMatchRepository implements PendingMatchRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreatePendingMatchData): Promise<PendingMatch> {
    const [row] = await this.drizzle.db
      .insert(pendingMatches)
      .values({
        externalId: data.externalId,
        requestAExternalId: data.requestAExternalId,
        requestBExternalId: data.requestBExternalId,
        userAId: data.userAId,
        userBId: data.userBId,
        sport: data.sport,
        expiresAt: data.expiresAt,
        status: 'proposed',
        acceptedByA: false,
        acceptedByB: false,
      })
      .returning();
    return this.toEntity(row);
  }

  async findByExternalId(externalId: string): Promise<PendingMatch | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(pendingMatches)
      .where(eq(pendingMatches.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async accept(externalId: string, role: 'A' | 'B'): Promise<PendingMatch> {
    const [row] = await this.drizzle.db
      .update(pendingMatches)
      .set({ [role === 'A' ? 'acceptedByA' : 'acceptedByB']: true, updatedAt: new Date() })
      .where(eq(pendingMatches.externalId, externalId))
      .returning();
    return this.toEntity(row);
  }

  async updateStatus(externalId: string, status: PendingMatchStatus): Promise<void> {
    await this.drizzle.db
      .update(pendingMatches)
      .set({ status, updatedAt: new Date() })
      .where(eq(pendingMatches.externalId, externalId));
  }

  private toEntity(row: PendingMatchRow): PendingMatch {
    return {
      id: row.id,
      externalId: row.externalId,
      requestAExternalId: row.requestAExternalId,
      requestBExternalId: row.requestBExternalId,
      userAId: row.userAId,
      userBId: row.userBId,
      sport: row.sport,
      status: row.status as PendingMatch['status'],
      acceptedByA: row.acceptedByA,
      acceptedByB: row.acceptedByB,
      proposedAt: row.proposedAt,
      expiresAt: row.expiresAt,
      updatedAt: row.updatedAt,
    };
  }
}
