import type { PlayerReview } from '../models/player-review.entity';

export const REVIEW_REPOSITORY = 'REVIEW_REPOSITORY';

export interface CreateReviewData {
  gameId: string;
  gameType: string;
  reviewerUserId: string;
  reviewerDisplayName: string;
  revieweeUserId: string;
  revieweeDisplayName: string;
  score: number;
  comment?: string;
}

export interface ListReviewsFilter {
  revieweeUserId?: string;
  reviewerUserId?: string;
  gameId?: string;
}

export interface ReviewRepositoryInterface {
  create(data: CreateReviewData): Promise<PlayerReview>;
  findById(externalId: string): Promise<PlayerReview | null>;
  findAll(filter: ListReviewsFilter): Promise<PlayerReview[]>;
  existsForGame(reviewerUserId: string, gameId: string): Promise<boolean>;
  updateDisplayNames(userId: string, displayName: string): Promise<void>;
}
