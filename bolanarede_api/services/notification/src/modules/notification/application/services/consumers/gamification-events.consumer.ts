import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GamificationEvents } from '@shared/contracts/events/gamification-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface BadgeAwardedPayload {
  playerUserId: string;
  badgeCode: string;
  earnedAt: Date;
}

@Injectable()
export class GamificationEventsConsumer {
  private readonly logger = new Logger(GamificationEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GamificationEvents.BADGE_AWARDED,
    queue: 'notification-service.gamification.badge-awarded',
    queueOptions: { durable: true },
  })
  async handleBadgeAwarded(payload: BadgeAwardedPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${GamificationEvents.BADGE_AWARDED}:${payload.playerUserId}:${payload.badgeCode}`,
        recipientUserId: payload.playerUserId,
        type: NotificationType.BADGE_AWARDED,
        title: 'Nova conquista!',
        body: `Você ganhou o badge ${payload.badgeCode}!`,
        data: { badgeCode: payload.badgeCode, earnedAt: payload.earnedAt },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify badge-awarded for user ${payload.playerUserId}: ${message}`,
      );
    }
  }
}
