import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import { RankingService } from './ranking.service';

interface MatchCompletedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{
    playerUserId: string;
    goals: number;
    assists: number;
    won: boolean;
  }>;
}

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  constructor(private readonly rankingService: RankingService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'ranking-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    try {
      await this.rankingService.processMatchCompleted(payload);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to process match-completed for game ${payload.gameId}: ${message}`,
      );
    }
  }
}
