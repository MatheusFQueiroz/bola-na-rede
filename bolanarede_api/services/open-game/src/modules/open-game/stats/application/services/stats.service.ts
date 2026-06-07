import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  STATS_REPOSITORY,
  StatsRepositoryInterface,
} from '../../domain/repositories/stats-repository.interface';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../../games/domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from '../../../games/application/services/open-game-messaging.service';
import { RecordStatsDto } from '../dto/record-stats.dto';
import { StatsDto } from '../dto/stats.dto';

@Injectable()
export class StatsService {
  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly gameRepo: OpenGameRepositoryInterface,
    @Inject(STATS_REPOSITORY)
    private readonly statsRepo: StatsRepositoryInterface,
    private readonly messaging: OpenGameMessagingService,
  ) {}

  async recordStats(userId: string, gameId: string, dto: RecordStatsDto): Promise<StatsDto[]> {
    const game = await this.gameRepo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can record stats');
    }

    const stats = await this.statsRepo.upsertStats(
      dto.players.map((p) => ({
        gameExternalId: gameId,
        playerUserId: p.playerUserId,
        goals: p.goals,
        assists: p.assists,
        notes: p.notes,
      })),
    );

    try {
      await this.messaging.publishStatsRecorded(
        game,
        stats.map((s) => ({
          playerUserId: s.playerUserId,
          goals: s.goals,
          assists: s.assists,
        })),
      );
    } catch {
      // advisory
    }

    return stats.map(StatsDto.fromStats);
  }

  async getGameStats(gameId: string): Promise<StatsDto[]> {
    const game = await this.gameRepo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const stats = await this.statsRepo.findByGame(gameId);
    return stats.map(StatsDto.fromStats);
  }
}
