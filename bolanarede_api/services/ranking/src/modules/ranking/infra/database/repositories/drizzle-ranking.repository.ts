import { Injectable } from '@nestjs/common';
import { and, desc, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  RankingRepositoryInterface,
  UpsertRankingData,
} from '../../../domain/repositories/ranking-repository.interface';
import type { PlayerRanking } from '../../../domain/models/player-ranking.entity';
import { playerRankings, type PlayerRankingRow } from '../schemas/player-ranking.schema';
import { rankingProcessedGames } from '../schemas/ranking-processed-game.schema';

@Injectable()
export class DrizzleRankingRepository implements RankingRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async insertProcessedGameIfNew(gameId: string): Promise<boolean> {
    const result = await this.drizzle.db
      .insert(rankingProcessedGames)
      .values({ gameId })
      .onConflictDoNothing()
      .returning();
    return result.length > 0;
  }

  async upsertRanking(data: UpsertRankingData): Promise<PlayerRanking> {
    const wins = data.isWin && !data.isDraw ? 1 : 0;
    const losses = !data.isWin && !data.isDraw ? 1 : 0;
    const draws = data.isDraw && !data.isWin ? 1 : 0;
    const points = data.isWin && !data.isDraw ? 3 : data.isDraw ? 1 : 0;

    const [row] = await this.drizzle.db
      .insert(playerRankings)
      .values({
        playerUserId: data.playerUserId,
        sport: data.sport,
        gamesPlayed: 1,
        wins,
        losses,
        draws,
        goals: data.goals,
        assists: data.assists,
        points,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [playerRankings.playerUserId, playerRankings.sport],
        set: {
          gamesPlayed: sql`${playerRankings.gamesPlayed} + 1`,
          wins: sql`${playerRankings.wins} + ${wins}`,
          losses: sql`${playerRankings.losses} + ${losses}`,
          draws: sql`${playerRankings.draws} + ${draws}`,
          goals: sql`${playerRankings.goals} + ${data.goals}`,
          assists: sql`${playerRankings.assists} + ${data.assists}`,
          points: sql`${playerRankings.points} + ${points}`,
          updatedAt: new Date(),
        },
      })
      .returning();
    return this.toEntity(row);
  }

  async findByPlayerAndSport(playerUserId: string, sport: string): Promise<PlayerRanking | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(playerRankings)
      .where(and(eq(playerRankings.playerUserId, playerUserId), eq(playerRankings.sport, sport)))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async getLeaderboard(sport: string, limit: number): Promise<PlayerRanking[]> {
    const rows = await this.drizzle.db
      .select()
      .from(playerRankings)
      .where(eq(playerRankings.sport, sport))
      .orderBy(desc(playerRankings.points), desc(playerRankings.wins))
      .limit(limit);
    return rows.map((r) => this.toEntity(r));
  }

  private toEntity(row: PlayerRankingRow): PlayerRanking {
    return {
      id: row.id,
      playerUserId: row.playerUserId,
      sport: row.sport,
      gamesPlayed: row.gamesPlayed,
      wins: row.wins,
      losses: row.losses,
      draws: row.draws,
      goals: row.goals,
      assists: row.assists,
      points: row.points,
      updatedAt: row.updatedAt,
    };
  }
}
