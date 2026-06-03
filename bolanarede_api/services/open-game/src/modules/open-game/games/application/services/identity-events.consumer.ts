import { Inject, Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../domain/repositories/open-game-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly repo: OpenGameRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'open-game-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.repo.updateParticipantSnapshot(
        payload.userId,
        payload.displayName,
        payload.position,
      );
      this.logger.debug(`Updated participant snapshot for player ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update participant snapshot for player ${payload.userId}: ${message}`,
      );
      // Don't rethrow — idempotent; snapshot corrected on next profile update
    }
  }
}
