import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface MatchCompletedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{ playerUserId: string; goals: number; assists: number; won: boolean }>;
}

interface ResultDisputedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  disputedByUserId: string;
}

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'notification-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    const data: Record<string, unknown> = {
      gameId: payload.gameId,
      matchId: payload.matchId,
      sport: payload.sport,
    };

    for (const player of payload.players) {
      try {
        await this.notifService.createNotification({
          eventId: `${GameEvents.MATCH_COMPLETED}:${payload.gameId}:${player.playerUserId}`,
          recipientUserId: player.playerUserId,
          type: NotificationType.MATCH_COMPLETED,
          title: 'Resultado registrado',
          body: 'O resultado do seu jogo foi registrado.',
          data,
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(
          `Failed to notify player ${player.playerUserId} for match-completed ${payload.gameId}: ${message}`,
        );
      }
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.RESULT_DISPUTED,
    queue: 'notification-service.game.result-disputed',
    queueOptions: { durable: true },
  })
  async handleResultDisputed(payload: ResultDisputedPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${GameEvents.RESULT_DISPUTED}:${payload.gameId}:${payload.disputedByUserId}`,
        recipientUserId: payload.disputedByUserId,
        type: NotificationType.RESULT_DISPUTED,
        title: 'Resultado contestado',
        body: 'O resultado do seu jogo foi contestado.',
        data: { gameId: payload.gameId, matchId: payload.matchId, sport: payload.sport },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify result-disputed for game ${payload.gameId}: ${message}`,
      );
    }
  }
}
