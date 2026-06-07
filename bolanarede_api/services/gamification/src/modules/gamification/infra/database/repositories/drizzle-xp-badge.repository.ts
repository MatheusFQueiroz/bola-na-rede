import { Injectable } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { XpLedgerRepositoryInterface, RecordXpData } from '../../../domain/repositories/xp-ledger-repository.interface';
import type { BadgeRepositoryInterface } from '../../../domain/repositories/badge-repository.interface';
import type { XpLedgerEntry } from '../../../domain/models/xp-ledger.entity';
import type { PlayerBadge, BadgeCode } from '../../../domain/models/player-badge.entity';
import { xpLedger, type XpLedgerRow } from '../schemas/xp-ledger.schema';
import { playerBadges, type PlayerBadgeRow } from '../schemas/player-badge.schema';

@Injectable()
export class DrizzleXpBadgeRepository
  implements XpLedgerRepositoryInterface, BadgeRepositoryInterface
{
  constructor(private readonly drizzle: DrizzleService) {}

  async recordXp(data: RecordXpData): Promise<XpLedgerEntry | null> {
    const [row] = await this.drizzle.db
      .insert(xpLedger)
      .values({
        playerUserId: data.playerUserId,
        sourceType: data.sourceType,
        sourceId: data.sourceId,
        xpEarned: data.xpEarned,
        reason: data.reason,
      })
      .onConflictDoNothing()
      .returning();

    return row ? this.toEntry(row) : null;
  }

  async hasGoal(playerUserId: string): Promise<boolean> {
    const [row] = await this.drizzle.db
      .select({ id: xpLedger.id })
      .from(xpLedger)
      .where(
        and(
          eq(xpLedger.playerUserId, playerUserId),
          eq(xpLedger.reason, 'goal'),
        ),
      )
      .limit(1);
    return !!row;
  }

  async awardBadge(playerUserId: string, badgeCode: BadgeCode): Promise<PlayerBadge | null> {
    const [row] = await this.drizzle.db
      .insert(playerBadges)
      .values({ playerUserId, badgeCode })
      .onConflictDoNothing()
      .returning();
    return row ? this.toBadge(row) : null;
  }

  async findEarnedBadges(playerUserId: string): Promise<PlayerBadge[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerBadges)
      .where(eq(playerBadges.playerUserId, playerUserId));
    return rows.map((r) => this.toBadge(r));
  }

  private toEntry(row: XpLedgerRow): XpLedgerEntry {
    return {
      id: row.id,
      playerUserId: row.playerUserId,
      sourceType: row.sourceType as XpLedgerEntry['sourceType'],
      sourceId: row.sourceId,
      xpEarned: row.xpEarned,
      reason: row.reason as XpLedgerEntry['reason'],
      createdAt: row.createdAt,
    };
  }

  private toBadge(row: PlayerBadgeRow): PlayerBadge {
    return {
      playerUserId: row.playerUserId,
      badgeCode: row.badgeCode as BadgeCode,
      earnedAt: row.earnedAt,
    };
  }
}
