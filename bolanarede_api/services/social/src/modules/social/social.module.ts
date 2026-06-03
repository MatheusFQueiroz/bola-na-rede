import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { REVIEW_REPOSITORY } from './domain/repositories/review-repository.interface';
import { SCORE_REPOSITORY } from './domain/repositories/score-repository.interface';
import { DrizzleReviewRepository } from './infra/database/repositories/drizzle-review.repository';
import { DrizzleScoreRepository } from './infra/database/repositories/drizzle-score.repository';
import { ReviewService } from './application/services/review.service';
import { SocialMessagingService } from './application/services/social-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { ReviewsController } from './infra/controllers/reviews.controller';
import { ScoresController } from './infra/controllers/scores.controller';

@Module({
  imports: [SharedModule],
  controllers: [ReviewsController, ScoresController],
  providers: [
    { provide: REVIEW_REPOSITORY, useClass: DrizzleReviewRepository },
    { provide: SCORE_REPOSITORY, useClass: DrizzleScoreRepository },
    ReviewService,
    SocialMessagingService,
    IdentityEventsConsumer,
  ],
})
export class SocialModule {}
