import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { RankingEvents } from '@shared/contracts/events/ranking-events.enum';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

@Injectable()
export class RankingMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishRankingRecalculated(ranking: PlayerRanking): Promise<void> {
    await this.messaging.publish(RankingEvents.RECALCULATED, {
      playerUserId: ranking.playerUserId,
      sport: ranking.sport,
      points: ranking.points,
      wins: ranking.wins,
      losses: ranking.losses,
      draws: ranking.draws,
      gamesPlayed: ranking.gamesPlayed,
    });
  }
}
