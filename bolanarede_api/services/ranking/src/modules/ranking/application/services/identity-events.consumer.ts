import { Injectable, Logger, Inject } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import {
  RANKING_REPOSITORY,
  type RankingRepositoryInterface,
} from '../../domain/repositories/ranking-repository.interface';

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(
    @Inject(RANKING_REPOSITORY)
    private readonly rankingRepo: RankingRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'ranking-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: {
    userId: string;
    displayName: string;
    photoUrl?: string | null;
    city?: string | null;
    position?: string | null;
  }): Promise<void> {
    if (!payload.displayName) return;
    try {
      await this.rankingRepo.updateDisplayName(payload.userId, payload.displayName);
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to update displayName for ${payload.userId}: ${msg}`);
    }
  }
}
