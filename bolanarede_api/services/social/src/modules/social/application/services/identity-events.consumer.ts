import { Inject, Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  REVIEW_REPOSITORY,
  ReviewRepositoryInterface,
} from '../../domain/repositories/review-repository.interface';
import {
  SCORE_REPOSITORY,
  ScoreRepositoryInterface,
} from '../../domain/repositories/score-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(REVIEW_REPOSITORY)
    private readonly reviewRepo: ReviewRepositoryInterface,
    @Inject(SCORE_REPOSITORY)
    private readonly scoreRepo: ScoreRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'social-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.reviewRepo.updateDisplayNames(payload.userId, payload.displayName);
      await this.scoreRepo.updateDisplayName(payload.userId, payload.displayName);
      this.logger.debug(`Updated display names for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update display names for user ${payload.userId}: ${message}`,
      );
      // Don't rethrow — idempotent; snapshot corrected on next profile update
    }
  }
}
