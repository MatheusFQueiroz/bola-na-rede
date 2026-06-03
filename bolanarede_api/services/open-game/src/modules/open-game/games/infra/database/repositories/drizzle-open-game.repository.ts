import { Injectable } from '@nestjs/common';
import { and, eq, gte, inArray, isNull, lte, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateOpenGameData,
  ListOpenGamesFilter,
  OpenGameRepositoryInterface,
  UpdateOpenGameData,
} from '../../domain/repositories/open-game-repository.interface';
import type { OpenGame, GameStatus } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';
import { openGames, type OpenGameRow } from '../schemas/open-game.schema';
import { gameParticipants, type GameParticipantRow } from '../schemas/game-participant.schema';

@Injectable()
export class DrizzleOpenGameRepository implements OpenGameRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateOpenGameData): Promise<OpenGame> {
    const [row] = await this.drizzle.db
      .insert(openGames)
      .values({
        organizerUserId: data.organizerUserId,
        fieldId: data.fieldId ?? null,
        fieldNameSnapshot: data.fieldNameSnapshot ?? null,
        fieldAddressSnapshot: data.fieldAddressSnapshot ?? null,
        title: data.title,
        description: data.description ?? null,
        sport: data.sport,
        scheduledAt: data.scheduledAt,
        durationMinutes: data.durationMinutes ?? 60,
        minPlayers: data.minPlayers ?? 10,
        maxPlayers: data.maxPlayers ?? 22,
        pricePerPlayer: data.pricePerPlayer != null ? String(data.pricePerPlayer) : null,
        status: 'open',
      })
      .returning();
    return this.toGame(row);
  }

  async findById(externalId: string): Promise<OpenGame | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(openGames)
      .where(and(eq(openGames.externalId, externalId), eq(openGames.isActive, true)))
      .limit(1);
    return row ? this.toGame(row) : null;
  }

  async findUpcoming(filter: ListOpenGamesFilter): Promise<OpenGame[]> {
    const conditions = [eq(openGames.isActive, true)];

    if (filter.status && filter.status.length > 0) {
      conditions.push(inArray(openGames.status, filter.status));
    } else {
      conditions.push(inArray(openGames.status, ['open', 'full']));
    }

    if (filter.sport) {
      conditions.push(eq(openGames.sport, filter.sport));
    }
    if (filter.fieldId) {
      conditions.push(eq(openGames.fieldId, filter.fieldId));
    }
    if (filter.fromDate) {
      conditions.push(gte(openGames.scheduledAt, filter.fromDate));
    }
    if (filter.toDate) {
      conditions.push(lte(openGames.scheduledAt, filter.toDate));
    }

    const rows = await this.drizzle.db
      .select()
      .from(openGames)
      .where(and(...conditions))
      .orderBy(openGames.scheduledAt);

    return rows.map((row) => this.toGame(row));
  }

  async update(externalId: string, data: UpdateOpenGameData): Promise<OpenGame> {
    const values: Partial<typeof openGames.$inferInsert> = { updatedAt: new Date() };
    if (data.title !== undefined) values.title = data.title;
    if (data.description !== undefined) values.description = data.description;
    if (data.fieldId !== undefined) values.fieldId = data.fieldId;
    if (data.fieldNameSnapshot !== undefined) values.fieldNameSnapshot = data.fieldNameSnapshot;
    if (data.fieldAddressSnapshot !== undefined) values.fieldAddressSnapshot = data.fieldAddressSnapshot;
    if (data.scheduledAt !== undefined) values.scheduledAt = data.scheduledAt;
    if (data.durationMinutes !== undefined) values.durationMinutes = data.durationMinutes;
    if (data.minPlayers !== undefined) values.minPlayers = data.minPlayers;
    if (data.maxPlayers !== undefined) values.maxPlayers = data.maxPlayers;
    if (data.pricePerPlayer !== undefined) {
      values.pricePerPlayer = data.pricePerPlayer != null ? String(data.pricePerPlayer) : null;
    }

    const [row] = await this.drizzle.db
      .update(openGames)
      .set(values)
      .where(eq(openGames.externalId, externalId))
      .returning();

    if (!row) throw new Error(`OpenGame "${externalId}" not found`);
    return this.toGame(row);
  }

  async updateStatus(externalId: string, status: GameStatus): Promise<void> {
    await this.drizzle.db
      .update(openGames)
      .set({ status, updatedAt: new Date() })
      .where(eq(openGames.externalId, externalId));
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(openGames)
      .set({ isActive: false, status: 'cancelled', updatedAt: new Date() })
      .where(eq(openGames.externalId, externalId));
  }

  async addParticipant(
    gameExternalId: string,
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<GameParticipant> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) throw new Error(`OpenGame "${gameExternalId}" not found`);

    const [row] = await this.drizzle.db
      .insert(gameParticipants)
      .values({ gameId: gameRow.id, playerUserId, displayName, position })
      .returning();

    if (!row) throw new Error(`Failed to add participant to game "${gameExternalId}"`);
    return this.toParticipant(row, gameExternalId);
  }

  async removeParticipant(gameExternalId: string, playerUserId: string): Promise<void> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) throw new Error(`OpenGame "${gameExternalId}" not found`);

    await this.drizzle.db
      .update(gameParticipants)
      .set({ leftAt: new Date() })
      .where(
        and(
          eq(gameParticipants.gameId, gameRow.id),
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      );
  }

  async findParticipant(gameExternalId: string, playerUserId: string): Promise<GameParticipant | null> {
    const [row] = await this.drizzle.db
      .select({ gp: gameParticipants })
      .from(gameParticipants)
      .innerJoin(openGames, eq(openGames.id, gameParticipants.gameId))
      .where(
        and(
          eq(openGames.externalId, gameExternalId),
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      )
      .limit(1);

    return row ? this.toParticipant(row.gp, gameExternalId) : null;
  }

  async findParticipants(gameExternalId: string): Promise<GameParticipant[]> {
    const rows = await this.drizzle.db
      .select({ gp: gameParticipants })
      .from(gameParticipants)
      .innerJoin(openGames, eq(openGames.id, gameParticipants.gameId))
      .where(
        and(
          eq(openGames.externalId, gameExternalId),
          isNull(gameParticipants.leftAt),
        ),
      );

    return rows.map((r) => this.toParticipant(r.gp, gameExternalId));
  }

  async countActiveParticipants(gameExternalId: string): Promise<number> {
    const [gameRow] = await this.drizzle.db
      .select({ id: openGames.id })
      .from(openGames)
      .where(eq(openGames.externalId, gameExternalId))
      .limit(1);

    if (!gameRow) return 0;

    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(gameParticipants)
      .where(
        and(
          eq(gameParticipants.gameId, gameRow.id),
          isNull(gameParticipants.leftAt),
        ),
      );

    return result?.count ?? 0;
  }

  async updateParticipantSnapshot(
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<void> {
    await this.drizzle.db
      .update(gameParticipants)
      .set({ displayName, position })
      .where(
        and(
          eq(gameParticipants.playerUserId, playerUserId),
          isNull(gameParticipants.leftAt),
        ),
      );
  }

  private toGame(row: OpenGameRow): OpenGame {
    return {
      id: row.externalId,
      organizerUserId: row.organizerUserId,
      fieldId: row.fieldId ?? null,
      fieldNameSnapshot: row.fieldNameSnapshot ?? null,
      fieldAddressSnapshot: row.fieldAddressSnapshot ?? null,
      title: row.title,
      description: row.description ?? null,
      sport: row.sport as OpenGame['sport'],
      scheduledAt: row.scheduledAt,
      durationMinutes: row.durationMinutes,
      minPlayers: row.minPlayers,
      maxPlayers: row.maxPlayers,
      pricePerPlayer: row.pricePerPlayer != null ? parseFloat(row.pricePerPlayer) : null,
      status: row.status as OpenGame['status'],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toParticipant(row: GameParticipantRow, gameExternalId: string): GameParticipant {
    return {
      gameExternalId,
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      position: row.position ?? null,
      joinedAt: row.joinedAt,
      leftAt: row.leftAt ?? null,
    };
  }
}
