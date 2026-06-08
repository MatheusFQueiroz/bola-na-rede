import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  RANKING_REPOSITORY,
  RankingRepositoryInterface,
} from '../../domain/repositories/ranking-repository.interface';
import { RankingMessagingService } from './ranking-messaging.service';
import { RankingDto } from '../dto/ranking.dto';
import { LeaderboardEntryDto } from '../dto/leaderboard-entry.dto';

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
export class RankingService {
  private readonly logger = new Logger(RankingService.name);

  constructor(
    @Inject(RANKING_REPOSITORY)
    private readonly rankingRepo: RankingRepositoryInterface,
    private readonly messaging: RankingMessagingService,
  ) {}

  async processMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    const isNew = await this.rankingRepo.insertProcessedGameIfNew(payload.gameId);
    if (!isNew) {
      this.logger.debug(`Game ${payload.gameId} already processed by ranking, skipping`);
      return;
    }

    for (const player of payload.players) {
      const isWin = payload.winnerId === player.playerUserId;
      const isDraw = payload.winnerId === null;

      const ranking = await this.rankingRepo.upsertRanking({
        playerUserId: player.playerUserId,
        sport: payload.sport,
        goals: player.goals,
        assists: player.assists,
        isWin,
        isDraw,
      });

      try {
        await this.messaging.publishRankingRecalculated(ranking);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(
          `Failed to publish ranking-recalculated for ${player.playerUserId}: ${message}`,
        );
      }
    }
  }

  async getLeaderboard(sport: string, limit: number): Promise<LeaderboardEntryDto[]> {
    const rankings = await this.rankingRepo.getLeaderboard(sport, limit);
    return rankings.map((r, i) => LeaderboardEntryDto.from(r, i + 1));
  }

  async getPlayerRanking(userId: string, sport: string): Promise<RankingDto> {
    const ranking = await this.rankingRepo.findByPlayerAndSport(userId, sport);
    if (!ranking) {
      throw new NotFoundException(`No ranking found for player ${userId} in sport ${sport}`);
    }
    return RankingDto.from(ranking);
  }
}
