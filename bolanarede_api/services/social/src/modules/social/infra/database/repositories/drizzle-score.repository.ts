import { Injectable } from '@nestjs/common';
import { avg, count, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  ScoreRepositoryInterface,
} from '../../../domain/repositories/score-repository.interface';
import type { PlayerScore } from '../../../domain/models/player-score.entity';
import { playerScores, type PlayerScoreRow } from '../schemas/player-score.schema';
import { playerReviews } from '../schemas/player-review.schema';

@Injectable()
export class DrizzleScoreRepository implements ScoreRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async findByPlayer(playerUserId: string): Promise<PlayerScore | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerScores)
      .where(eq(playerScores.playerUserId, playerUserId))
      .limit(1);
    return row ? this.toScore(row) : null;
  }

  async recalculate(playerUserId: string, displayName: string): Promise<PlayerScore> {
    const [agg] = await this.drizzle.db
      .select({
        total: count(playerReviews.id),
        average: avg(playerReviews.score),
      })
      .from(playerReviews)
      .where(eq(playerReviews.revieweeUserId, playerUserId));

    const totalReviews = agg?.total ?? 0;
    const averageScore = agg?.average ? Number(agg.average).toFixed(2) : '0.00';

    const [row] = await this.drizzle.db
      .insert(playerScores)
      .values({ playerUserId, displayName, totalReviews, averageScore })
      .onConflictDoUpdate({
        target: playerScores.playerUserId,
        set: {
          totalReviews,
          averageScore: sql`excluded.average_score`,
          displayName,
          updatedAt: sql`now()`,
        },
      })
      .returning();

    return this.toScore(row);
  }

  async updateDisplayName(playerUserId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerScores)
      .set({ displayName })
      .where(eq(playerScores.playerUserId, playerUserId));
  }

  private toScore(row: PlayerScoreRow): PlayerScore {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      totalReviews: row.totalReviews,
      averageScore: parseFloat(row.averageScore),
      updatedAt: row.updatedAt,
    };
  }
}
