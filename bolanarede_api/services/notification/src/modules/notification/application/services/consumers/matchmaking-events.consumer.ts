import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface MatchAcceptedPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

interface MatchExpiredPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

@Injectable()
export class MatchmakingEventsConsumer {
  private readonly logger = new Logger(MatchmakingEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_ACCEPTED,
    queue: 'notification-service.matchmaking.match-accepted',
    queueOptions: { durable: true },
  })
  async handleMatchAccepted(payload: MatchAcceptedPayload): Promise<void> {
    const title = 'Match encontrado!';
    const body = 'Seu jogo foi aceito. Boa sorte!';
    const data: Record<string, unknown> = { matchId: payload.matchId, sport: payload.sport };

    for (const userId of [payload.userAId, payload.userBId]) {
      try {
        await this.notifService.createNotification({
          eventId: `${MatchmakingEvents.MATCH_ACCEPTED}:${payload.matchId}:${userId}`,
          recipientUserId: userId,
          type: NotificationType.MATCH_ACCEPTED,
          title,
          body,
          data,
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(
          `Failed to notify user ${userId} for match-accepted ${payload.matchId}: ${message}`,
        );
      }
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_EXPIRED,
    queue: 'notification-service.matchmaking.match-expired',
    queueOptions: { durable: true },
  })
  async handleMatchExpired(payload: MatchExpiredPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${MatchmakingEvents.MATCH_EXPIRED}:${payload.matchId}:${payload.userAId}`,
        recipientUserId: payload.userAId,
        type: NotificationType.MATCH_EXPIRED,
        title: 'Match expirado',
        body: 'Seu pedido de partida expirou. Tente novamente.',
        data: { matchId: payload.matchId, sport: payload.sport },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify match-expired for match ${payload.matchId}: ${message}`,
      );
    }
  }
}
