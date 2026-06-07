import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';
import type { OpenGame } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

@Injectable()
export class OpenGameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishCreated(game: OpenGame, participantCount: number): Promise<void> {
    await this.messaging.publish(OpenGameEvents.CREATED, {
      gameId: game.id,
      organizerUserId: game.organizerUserId,
      title: game.title,
      sport: game.sport,
      scheduledAt: game.scheduledAt,
      fieldId: game.fieldId,
      minPlayers: game.minPlayers,
      maxPlayers: game.maxPlayers,
      participantCount,
    });
  }

  async publishPlayerJoined(game: OpenGame, participant: GameParticipant): Promise<void> {
    await this.messaging.publish(OpenGameEvents.PLAYER_JOINED, {
      gameId: game.id,
      playerUserId: participant.playerUserId,
      displayName: participant.displayName,
    });
  }

  async publishPlayerLeft(game: OpenGame, playerUserId: string): Promise<void> {
    await this.messaging.publish(OpenGameEvents.PLAYER_LEFT, {
      gameId: game.id,
      playerUserId,
    });
  }

  async publishFull(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.FULL, {
      gameId: game.id,
      minPlayers: game.minPlayers,
    });
  }

  async publishFinished(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.FINISHED, {
      gameId: game.id,
      scheduledAt: game.scheduledAt,
      sport: game.sport,
    });
  }

  async publishCancelled(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.CANCELLED, {
      gameId: game.id,
    });
  }

  async publishStatsRecorded(
    game: OpenGame,
    players: Array<{ playerUserId: string; goals: number; assists: number }>,
  ): Promise<void> {
    await this.messaging.publish(OpenGameEvents.STATS_RECORDED, {
      gameId: game.id,
      sport: game.sport,
      players,
    });
  }
}
