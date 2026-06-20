import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import { XpService, MatchCompletedPayload } from './xp.service';

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  constructor(private readonly xpService: XpService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'gamification-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    try {
      await this.xpService.processMatchCompleted(payload);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to process match-completed XP for game ${payload.gameId}: ${message}`,
      );
    }
  }
}
