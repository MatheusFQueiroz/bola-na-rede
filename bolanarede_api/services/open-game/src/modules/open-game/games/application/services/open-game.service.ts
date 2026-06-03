import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  OPEN_GAME_REPOSITORY,
  OpenGameRepositoryInterface,
} from '../../domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from './open-game-messaging.service';
import { GameCacheService } from '../../infra/cache/game-cache.service';
import { CreateOpenGameDto } from '../dto/create-open-game.dto';
import { UpdateOpenGameDto } from '../dto/update-open-game.dto';
import { ListOpenGamesDto } from '../dto/list-open-games.dto';
import { OpenGameDto } from '../dto/open-game.dto';
import { GameParticipantDto } from '../dto/game-participant.dto';

@Injectable()
export class OpenGameService {
  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly repo: OpenGameRepositoryInterface,
    private readonly messaging: OpenGameMessagingService,
    private readonly cache: GameCacheService,
  ) {}

  async create(userId: string, _displayName: string, dto: CreateOpenGameDto): Promise<OpenGameDto> {
    const game = await this.repo.create({
      organizerUserId: userId,
      fieldId: dto.fieldId,
      fieldNameSnapshot: dto.fieldNameSnapshot,
      fieldAddressSnapshot: dto.fieldAddressSnapshot,
      title: dto.title,
      description: dto.description,
      sport: dto.sport,
      scheduledAt: new Date(dto.scheduledAt),
      durationMinutes: dto.durationMinutes,
      minPlayers: dto.minPlayers,
      maxPlayers: dto.maxPlayers,
      pricePerPlayer: dto.pricePerPlayer,
    });

    await this.cache.invalidate();

    try {
      await this.messaging.publishCreated(game, 0);
    } catch {
      // advisory
    }

    return OpenGameDto.fromGame(game, 0);
  }

  async list(query: ListOpenGamesDto): Promise<OpenGameDto[]> {
    const hasFilters = Boolean(query.sport || query.fieldId || query.from || query.to);

    if (!hasFilters) {
      const cached = await this.cache.getUpcoming();
      if (cached) return cached;
    }

    const games = await this.repo.findUpcoming({
      sport: query.sport,
      fieldId: query.fieldId,
      fromDate: query.from ? new Date(query.from) : undefined,
      toDate: query.to ? new Date(query.to) : undefined,
    });

    const dtos = await Promise.all(
      games.map(async (g) => {
        const count = await this.repo.countActiveParticipants(g.id);
        return OpenGameDto.fromGame(g, count);
      }),
    );

    if (!hasFilters) {
      await this.cache.setUpcoming(dtos);
    }

    return dtos;
  }

  async getById(gameId: string): Promise<OpenGameDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const count = await this.repo.countActiveParticipants(gameId);
    return OpenGameDto.fromGame(game, count);
  }

  async update(userId: string, gameId: string, dto: UpdateOpenGameDto): Promise<OpenGameDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can update this game');
    }

    const updated = await this.repo.update(gameId, {
      title: dto.title,
      description: dto.description,
      fieldId: dto.fieldId,
      fieldNameSnapshot: dto.fieldNameSnapshot,
      fieldAddressSnapshot: dto.fieldAddressSnapshot,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
      durationMinutes: dto.durationMinutes,
      minPlayers: dto.minPlayers,
      maxPlayers: dto.maxPlayers,
      pricePerPlayer: dto.pricePerPlayer,
    });

    await this.cache.invalidate();
    const count = await this.repo.countActiveParticipants(gameId);
    return OpenGameDto.fromGame(updated, count);
  }

  async cancel(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can cancel this game');
    }

    await this.repo.deactivate(gameId);
    await this.cache.invalidate();

    try {
      await this.messaging.publishCancelled(game);
    } catch {
      // advisory
    }
  }

  async join(userId: string, displayName: string, position: string | null, gameId: string): Promise<GameParticipantDto> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.status === 'finished' || game.status === 'cancelled') {
      throw new ConflictException('Cannot join a finished or cancelled game');
    }

    const acquired = await this.cache.acquireJoinLock(gameId);
    if (!acquired) {
      throw new ConflictException('Another join is in progress — try again in a moment');
    }

    try {
      const existing = await this.repo.findParticipant(gameId, userId);
      if (existing) throw new ConflictException('Already joined this game');

      const count = await this.repo.countActiveParticipants(gameId);
      if (count >= game.maxPlayers) throw new ConflictException('Game is full');

      const participant = await this.repo.addParticipant(gameId, userId, displayName, position);
      const newCount = count + 1;

      await this.cache.invalidate();

      try {
        await this.messaging.publishPlayerJoined(game, participant);
        if (newCount === game.minPlayers) {
          await this.repo.updateStatus(gameId, 'full');
          await this.messaging.publishFull(game);
        }
      } catch {
        // advisory
      }

      return GameParticipantDto.fromParticipant(participant);
    } finally {
      await this.cache.releaseJoinLock(gameId);
    }
  }

  async leave(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);

    const participant = await this.repo.findParticipant(gameId, userId);
    if (!participant) throw new NotFoundException('Not a participant of this game');

    await this.repo.removeParticipant(gameId, userId);

    const remainingCount = await this.repo.countActiveParticipants(gameId);
    if (remainingCount < game.minPlayers && game.status === 'full') {
      await this.repo.updateStatus(gameId, 'open');
    }

    await this.cache.invalidate();

    try {
      await this.messaging.publishPlayerLeft(game, userId);
    } catch {
      // advisory
    }
  }

  async finish(userId: string, gameId: string): Promise<void> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    if (game.organizerUserId !== userId) {
      throw new ForbiddenException('Only the organizer can finish this game');
    }

    await this.repo.updateStatus(gameId, 'finished');
    await this.cache.invalidate();

    try {
      await this.messaging.publishFinished(game);
    } catch {
      // advisory
    }
  }

  async getParticipants(gameId: string): Promise<GameParticipantDto[]> {
    const game = await this.repo.findById(gameId);
    if (!game) throw new NotFoundException(`Open game ${gameId} not found`);
    const participants = await this.repo.findParticipants(gameId);
    return participants.map(GameParticipantDto.fromParticipant);
  }
}
