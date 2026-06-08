import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  GAME_REPOSITORY,
  GameRepositoryInterface,
} from '../../domain/repositories/game-repository.interface';
import { GameMessagingService } from './game-messaging.service';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';
import type { SubmitResultDto } from '../dto/submit-result.dto';

@Injectable()
export class GameService {
  private readonly logger = new Logger(GameService.name);

  constructor(
    @Inject(GAME_REPOSITORY)
    private readonly gameRepo: GameRepositoryInterface,
    private readonly messaging: GameMessagingService,
  ) {}

  async submitResult(
    userId: string,
    gameExternalId: string,
    dto: SubmitResultDto,
  ): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');

    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }

    if (game.status !== 'scheduled') {
      throw new ConflictException(`Game is already ${game.status}`);
    }

    const winnerId =
      dto.playerAGoals > dto.playerBGoals
        ? game.userAId
        : dto.playerBGoals > dto.playerAGoals
          ? game.userBId
          : null;

    const updated = await this.gameRepo.submitResult(gameExternalId, {
      playerAGoals: dto.playerAGoals,
      playerBGoals: dto.playerBGoals,
      playerAAssists: dto.playerAAssists,
      playerBAssists: dto.playerBAssists,
      winnerId,
      submittedByUserId: userId,
    });

    try {
      await this.messaging.publishMatchCompleted(updated);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish match-completed for ${gameExternalId}: ${message}`);
    }

    return updated;
  }

  async disputeResult(userId: string, gameExternalId: string): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');

    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }

    if (game.status !== 'completed') {
      throw new ConflictException(`Cannot dispute a game with status ${game.status}`);
    }

    if (game.submittedByUserId !== null && game.submittedByUserId === userId) {
      throw new ForbiddenException('Cannot dispute your own submission');
    }

    const updated = await this.gameRepo.dispute(gameExternalId);

    try {
      await this.messaging.publishResultDisputed(updated, userId);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish result-disputed for ${gameExternalId}: ${message}`);
    }

    return updated;
  }

  async getGame(userId: string, gameExternalId: string): Promise<CompetitiveGame> {
    const game = await this.gameRepo.findByExternalId(gameExternalId);
    if (!game) throw new NotFoundException('Game not found');
    if (game.userAId !== userId && game.userBId !== userId) {
      throw new ForbiddenException('You are not a participant in this game');
    }
    return game;
  }
}
