import { Injectable } from '@nestjs/common';
import { eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  StatsRepositoryInterface,
  UpsertStatsData,
} from '../../../domain/repositories/stats-repository.interface';
import type { PlayerStats } from '../../../domain/models/player-stats.entity';
import { playerStats, type PlayerStatsRow } from '../schemas/player-stats.schema';
import { openGames } from '../../../../games/infra/database/schemas/open-game.schema';

@Injectable()
export class DrizzleStatsRepository implements StatsRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async upsertStats(data: UpsertStatsData[]): Promise<PlayerStats[]> {
    if (data.length === 0) return [];

    const rows = await Promise.all(
      data.map(async (d) => {
        const [gameRow] = await this.drizzle.db
          .select({ id: openGames.id })
          .from(openGames)
          .where(eq(openGames.externalId, d.gameExternalId))
          .limit(1);

        if (!gameRow) throw new Error(`OpenGame "${d.gameExternalId}" not found`);

        const [row] = await this.drizzle.db
          .insert(playerStats)
          .values({
            gameId: gameRow.id,
            playerUserId: d.playerUserId,
            goals: d.goals,
            assists: d.assists,
            notes: d.notes ?? null,
          })
          .onConflictDoUpdate({
            target: [playerStats.gameId, playerStats.playerUserId],
            set: {
              goals: sql`excluded.goals`,
              assists: sql`excluded.assists`,
              notes: sql`excluded.notes`,
            },
          })
          .returning();

        return this.toStats(row, d.gameExternalId);
      }),
    );

    return rows;
  }

  async findByGame(gameExternalId: string): Promise<PlayerStats[]> {
    const rows = await this.drizzle.db
      .select({ ps: playerStats, gameExternalId: openGames.externalId })
      .from(playerStats)
      .innerJoin(openGames, eq(openGames.id, playerStats.gameId))
      .where(eq(openGames.externalId, gameExternalId));

    return rows.map((r) => this.toStats(r.ps, r.gameExternalId));
  }

  async findByPlayer(playerUserId: string): Promise<PlayerStats[]> {
    const rows = await this.drizzle.db
      .select({ ps: playerStats, gameExternalId: openGames.externalId })
      .from(playerStats)
      .innerJoin(openGames, eq(openGames.id, playerStats.gameId))
      .where(eq(playerStats.playerUserId, playerUserId));

    return rows.map((r) => this.toStats(r.ps, r.gameExternalId));
  }

  private toStats(row: PlayerStatsRow, gameExternalId: string): PlayerStats {
    return {
      gameExternalId,
      playerUserId: row.playerUserId,
      goals: row.goals,
      assists: row.assists,
      notes: row.notes ?? null,
      createdAt: row.createdAt,
    };
  }
}
