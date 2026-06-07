import { Injectable, Logger, Inject } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  MATCH_REQUEST_REPOSITORY,
  MatchRequestRepositoryInterface,
} from '../../domain/repositories/match-request-repository.interface';

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(MATCH_REQUEST_REPOSITORY)
    private readonly requestRepo: MatchRequestRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'matchmaking-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.requestRepo.updateDisplayName(payload.userId, payload.displayName);
      this.logger.debug(`Updated displayName for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to update displayName for ${payload.userId}: ${message}`);
    }
  }
}
