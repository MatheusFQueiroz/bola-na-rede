import { Injectable, Inject, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { v4 as uuidv4 } from 'uuid';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import {
  GAME_REPOSITORY,
  GameRepositoryInterface,
} from '../../domain/repositories/game-repository.interface';

interface MatchAcceptedPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

@Injectable()
export class MatchmakingEventsConsumer {
  private readonly logger = new Logger(MatchmakingEventsConsumer.name);

  constructor(
    @Inject(GAME_REPOSITORY)
    private readonly gameRepo: GameRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_ACCEPTED,
    queue: 'game-service.matchmaking.match-accepted',
    queueOptions: { durable: true },
  })
  async handleMatchAccepted(payload: MatchAcceptedPayload): Promise<void> {
    try {
      const game = await this.gameRepo.create({
        externalId: uuidv4(),
        matchId: payload.matchId,
        userAId: payload.userAId,
        userBId: payload.userBId,
        sport: payload.sport,
      });

      if (!game) {
        // onConflictDoNothing: partida para este matchId já existe (re-entrega idempotente)
        this.logger.debug(`Game for match ${payload.matchId} already exists, skipping`);
        return;
      }

      this.logger.log(`Game ${game.externalId} created for match ${payload.matchId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to create game for match ${payload.matchId}: ${message}`);
    }
  }
}
