import { Injectable } from '@nestjs/common';
import { and, desc, eq } from 'drizzle-orm';
import type { SQL } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateReviewData,
  ListReviewsFilter,
  ReviewRepositoryInterface,
} from '../../../domain/repositories/review-repository.interface';
import type { PlayerReview, GameType, ReviewScore } from '../../../domain/models/player-review.entity';
import { playerReviews, type PlayerReviewRow } from '../schemas/player-review.schema';

@Injectable()
export class DrizzleReviewRepository implements ReviewRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateReviewData): Promise<PlayerReview> {
    const [row] = await this.drizzle.db
      .insert(playerReviews)
      .values({
        gameId: data.gameId,
        gameType: data.gameType,
        reviewerUserId: data.reviewerUserId,
        reviewerDisplayName: data.reviewerDisplayName,
        revieweeUserId: data.revieweeUserId,
        revieweeDisplayName: data.revieweeDisplayName,
        score: data.score,
        comment: data.comment,
      })
      .returning();
    return this.toReview(row);
  }

  async findById(externalId: string): Promise<PlayerReview | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerReviews)
      .where(eq(playerReviews.externalId, externalId))
      .limit(1);
    return row ? this.toReview(row) : null;
  }

  async findAll(filter: ListReviewsFilter): Promise<PlayerReview[]> {
    const conditions: SQL[] = [];
    if (filter.revieweeUserId) {
      conditions.push(eq(playerReviews.revieweeUserId, filter.revieweeUserId));
    }
    if (filter.reviewerUserId) {
      conditions.push(eq(playerReviews.reviewerUserId, filter.reviewerUserId));
    }
    if (filter.gameId) {
      conditions.push(eq(playerReviews.gameId, filter.gameId));
    }

    const rows = await this.drizzle.db
      .select()
      .from(playerReviews)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(playerReviews.createdAt));

    return rows.map((row) => this.toReview(row));
  }

  async existsForGame(reviewerUserId: string, gameId: string): Promise<boolean> {
    const [row] = await this.drizzle.db
      .select({ id: playerReviews.id })
      .from(playerReviews)
      .where(
        and(
          eq(playerReviews.reviewerUserId, reviewerUserId),
          eq(playerReviews.gameId, gameId),
        ),
      )
      .limit(1);
    return Boolean(row);
  }

  async updateDisplayNames(userId: string, displayName: string): Promise<void> {
    await this.drizzle.db
      .update(playerReviews)
      .set({ reviewerDisplayName: displayName })
      .where(eq(playerReviews.reviewerUserId, userId));
    await this.drizzle.db
      .update(playerReviews)
      .set({ revieweeDisplayName: displayName })
      .where(eq(playerReviews.revieweeUserId, userId));
  }

  private toReview(row: PlayerReviewRow): PlayerReview {
    return {
      id: row.externalId,
      gameId: row.gameId,
      gameType: row.gameType as GameType,
      reviewerUserId: row.reviewerUserId,
      reviewerDisplayName: row.reviewerDisplayName,
      revieweeUserId: row.revieweeUserId,
      revieweeDisplayName: row.revieweeDisplayName,
      score: row.score as ReviewScore,
      comment: row.comment ?? undefined,
      createdAt: row.createdAt,
    };
  }
}
