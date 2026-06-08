import { Injectable, NotFoundException } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  GameRepositoryInterface,
  CreateGameData,
  SubmitResultData,
} from '../../../domain/repositories/game-repository.interface';
import type { CompetitiveGame } from '../../../domain/models/competitive-game.entity';
import { competitiveGames, type CompetitiveGameRow } from '../schemas/competitive-game.schema';

@Injectable()
export class DrizzleGameRepository implements GameRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateGameData): Promise<CompetitiveGame | null> {
    const result = await this.drizzle.db
      .insert(competitiveGames)
      .values({
        externalId: data.externalId,
        matchId: data.matchId,
        userAId: data.userAId,
        userBId: data.userBId,
        sport: data.sport,
        status: 'scheduled',
        playerAGoals: 0,
        playerBGoals: 0,
        playerAAssists: 0,
        playerBAssists: 0,
        winnerId: null,
        submittedByUserId: null,
      })
      .onConflictDoNothing()
      .returning();
    return result[0] ? this.toEntity(result[0]) : null;
  }

  async findByExternalId(externalId: string): Promise<CompetitiveGame | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(competitiveGames)
      .where(eq(competitiveGames.externalId, externalId))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async submitResult(externalId: string, data: SubmitResultData): Promise<CompetitiveGame> {
    const [row] = await this.drizzle.db
      .update(competitiveGames)
      .set({
        status: 'completed',
        playerAGoals: data.playerAGoals,
        playerBGoals: data.playerBGoals,
        playerAAssists: data.playerAAssists,
        playerBAssists: data.playerBAssists,
        winnerId: data.winnerId,
        submittedByUserId: data.submittedByUserId,
        updatedAt: new Date(),
      })
      .where(eq(competitiveGames.externalId, externalId))
      .returning();
    if (!row) throw new NotFoundException(`Game ${externalId} not found`);
    return this.toEntity(row);
  }

  async dispute(externalId: string): Promise<CompetitiveGame> {
    const [row] = await this.drizzle.db
      .update(competitiveGames)
      .set({ status: 'disputed', updatedAt: new Date() })
      .where(eq(competitiveGames.externalId, externalId))
      .returning();
    if (!row) throw new NotFoundException(`Game ${externalId} not found`);
    return this.toEntity(row);
  }

  private toEntity(row: CompetitiveGameRow): CompetitiveGame {
    return {
      id: row.id,
      externalId: row.externalId,
      matchId: row.matchId,
      userAId: row.userAId,
      userBId: row.userBId,
      sport: row.sport,
      status: row.status as CompetitiveGame['status'],
      playerAGoals: row.playerAGoals,
      playerBGoals: row.playerBGoals,
      playerAAssists: row.playerAAssists,
      playerBAssists: row.playerBAssists,
      winnerId: row.winnerId,
      submittedByUserId: row.submittedByUserId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
