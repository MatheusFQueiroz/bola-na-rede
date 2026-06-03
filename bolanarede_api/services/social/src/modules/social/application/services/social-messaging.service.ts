import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { SocialEvents } from '@shared/contracts/events/social-events.enum';
import type { PlayerReview } from '../../domain/models/player-review.entity';
import type { PlayerScore } from '../../domain/models/player-score.entity';

@Injectable()
export class SocialMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishPlayerReviewed(review: PlayerReview): Promise<void> {
    await this.messaging.publish(SocialEvents.PLAYER_REVIEWED, {
      reviewId: review.id,
      gameId: review.gameId,
      gameType: review.gameType,
      reviewerUserId: review.reviewerUserId,
      revieweeUserId: review.revieweeUserId,
      score: review.score,
    });
  }

  async publishScoreUpdated(score: PlayerScore): Promise<void> {
    await this.messaging.publish(SocialEvents.PLAYER_SCORE_UPDATED, {
      playerUserId: score.playerUserId,
      averageScore: score.averageScore,
      totalReviews: score.totalReviews,
    });
  }
}
