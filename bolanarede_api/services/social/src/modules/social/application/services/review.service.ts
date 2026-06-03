import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
} from '@nestjs/common';
import {
  REVIEW_REPOSITORY,
  ReviewRepositoryInterface,
} from '../../domain/repositories/review-repository.interface';
import {
  SCORE_REPOSITORY,
  ScoreRepositoryInterface,
} from '../../domain/repositories/score-repository.interface';
import { SocialMessagingService } from './social-messaging.service';
import { CreateReviewDto } from '../dto/create-review.dto';
import { ListReviewsDto } from '../dto/list-reviews.dto';
import { ReviewDto } from '../dto/review.dto';
import { PlayerScoreDto } from '../dto/player-score.dto';

@Injectable()
export class ReviewService {
  constructor(
    @Inject(REVIEW_REPOSITORY)
    private readonly reviewRepo: ReviewRepositoryInterface,
    @Inject(SCORE_REPOSITORY)
    private readonly scoreRepo: ScoreRepositoryInterface,
    private readonly messaging: SocialMessagingService,
  ) {}

  async createReview(
    reviewerUserId: string,
    reviewerDisplayName: string,
    dto: CreateReviewDto,
  ): Promise<ReviewDto> {
    if (reviewerUserId === dto.revieweeUserId) {
      throw new BadRequestException('Cannot review yourself');
    }

    const alreadyReviewed = await this.reviewRepo.existsForGame(reviewerUserId, dto.gameId);
    if (alreadyReviewed) {
      throw new ConflictException('Already reviewed a player in this game');
    }

    const existingScore = await this.scoreRepo.findByPlayer(dto.revieweeUserId);
    const revieweeDisplayName = existingScore?.displayName ?? '';

    const review = await this.reviewRepo.create({
      gameId: dto.gameId,
      gameType: dto.gameType,
      reviewerUserId,
      reviewerDisplayName,
      revieweeUserId: dto.revieweeUserId,
      revieweeDisplayName,
      score: dto.score,
      comment: dto.comment,
    });

    const score = await this.scoreRepo.recalculate(dto.revieweeUserId, revieweeDisplayName);

    try {
      await this.messaging.publishPlayerReviewed(review);
      await this.messaging.publishScoreUpdated(score);
    } catch {
      // fire-and-forget — advisory
    }

    return ReviewDto.fromReview(review);
  }

  async listReviews(query: ListReviewsDto): Promise<ReviewDto[]> {
    const reviews = await this.reviewRepo.findAll({
      revieweeUserId: query.revieweeUserId,
      reviewerUserId: query.reviewerUserId,
      gameId: query.gameId,
    });
    return reviews.map((r) => ReviewDto.fromReview(r));
  }

  async getPlayerScore(playerUserId: string): Promise<PlayerScoreDto> {
    const score = await this.scoreRepo.findByPlayer(playerUserId);
    return score ? PlayerScoreDto.fromScore(score) : PlayerScoreDto.empty(playerUserId);
  }
}
