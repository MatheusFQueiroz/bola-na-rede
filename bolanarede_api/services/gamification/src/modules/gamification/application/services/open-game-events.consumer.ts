import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';
import { XpService, type OpenGameStatsPayload } from './xp.service';

interface StatsRecordedPayload {
  gameId: string;
  sport: string;
  players: Array<{
    playerUserId: string;
    displayName?: string;
    goals: number;
    assists: number;
  }>;
}

@Injectable()
export class OpenGameEventsConsumer {
  private readonly logger = new Logger(OpenGameEventsConsumer.name);

  constructor(private readonly xpService: XpService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: OpenGameEvents.STATS_RECORDED,
    queue: 'gamification-service.open-game.stats-recorded',
    queueOptions: { durable: true },
  })
  async handleStatsRecorded(payload: StatsRecordedPayload): Promise<void> {
    try {
      const xpPayload: OpenGameStatsPayload = {
        gameId: payload.gameId,
        players: (payload.players ?? []).map((p) => ({
          playerUserId: p.playerUserId,
          displayName: p.displayName ?? '',
          goals: p.goals,
          assists: p.assists,
        })),
      };
      await this.xpService.processOpenGameStats(xpPayload);
      this.logger.debug(`Processed stats for game ${payload.gameId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to process stats for game ${payload.gameId}: ${message}`);
    }
  }
}
