import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { XpService } from './xp.service';

interface UserRegisteredPayload {
  userId: string;
  displayName: string;
}

interface ProfileUpdatedPayload {
  userId: string;
  displayName: string;
  position: string | null;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(private readonly xpService: XpService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.USER_REGISTERED,
    queue: 'gamification-service.identity.user-registered',
    queueOptions: { durable: true },
  })
  async handleUserRegistered(payload: UserRegisteredPayload): Promise<void> {
    try {
      await this.xpService.handleUserRegistered(payload.userId, payload.displayName);
      this.logger.debug(`Created profile for new user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to create profile for user ${payload.userId}: ${message}`);
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'gamification-service.identity.profile-updated',
    queueOptions: { durable: true },
  })
  async handleProfileUpdated(payload: ProfileUpdatedPayload): Promise<void> {
    try {
      await this.xpService.handleProfileUpdated(payload.userId, payload.displayName);
      this.logger.debug(`Updated displayName for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to update displayName for user ${payload.userId}: ${message}`);
    }
  }
}
