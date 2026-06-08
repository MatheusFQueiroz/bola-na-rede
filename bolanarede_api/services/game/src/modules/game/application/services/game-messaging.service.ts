import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

@Injectable()
export class GameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishMatchCompleted(game: CompetitiveGame): Promise<void> {
    const players = [
      {
        playerUserId: game.userAId,
        goals: game.playerAGoals,
        assists: game.playerAAssists,
        won: game.winnerId === game.userAId,
      },
      {
        playerUserId: game.userBId,
        goals: game.playerBGoals,
        assists: game.playerBAssists,
        won: game.winnerId === game.userBId,
      },
    ];

    await this.messaging.publish(GameEvents.MATCH_COMPLETED, {
      gameId: game.externalId,
      matchId: game.matchId,
      sport: game.sport,
      players,
    });
  }

  async publishResultDisputed(game: CompetitiveGame, disputedByUserId: string): Promise<void> {
    await this.messaging.publish(GameEvents.RESULT_DISPUTED, {
      gameId: game.externalId,
      matchId: game.matchId,
      sport: game.sport,
      disputedByUserId,
    });
  }
}
