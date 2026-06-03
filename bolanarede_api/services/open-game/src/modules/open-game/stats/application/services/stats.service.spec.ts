import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { StatsService } from './stats.service';
import { STATS_REPOSITORY } from '../../domain/repositories/stats-repository.interface';
import { OPEN_GAME_REPOSITORY } from '../../../games/domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from '../../../games/application/services/open-game-messaging.service';
import type { OpenGame } from '../../../games/domain/models/open-game.entity';
import type { PlayerStats } from '../../domain/models/player-stats.entity';

const mockGameRepo = {
  findById: jest.fn(),
};

const mockStatsRepo = {
  upsertStats: jest.fn(),
  findByGame: jest.fn(),
  findByPlayer: jest.fn(),
};

const mockMessaging = {
  publishStatsRecorded: jest.fn(),
};

const mockGame: OpenGame = {
  id: 'game-uuid-1',
  organizerUserId: 'organizer-uuid-1',
  fieldId: null,
  fieldNameSnapshot: null,
  fieldAddressSnapshot: null,
  title: 'Pelada',
  description: null,
  sport: 'society',
  scheduledAt: new Date('2026-07-01T19:00:00Z'),
  durationMinutes: 60,
  minPlayers: 10,
  maxPlayers: 22,
  pricePerPlayer: null,
  status: 'finished',
  createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-06-01'),
};

const mockStats: PlayerStats = {
  gameExternalId: 'game-uuid-1',
  playerUserId: 'player-uuid-1',
  goals: 2,
  assists: 1,
  notes: null,
  createdAt: new Date('2026-07-01'),
};

describe('StatsService', () => {
  let service: StatsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        StatsService,
        { provide: OPEN_GAME_REPOSITORY, useValue: mockGameRepo },
        { provide: STATS_REPOSITORY, useValue: mockStatsRepo },
        { provide: OpenGameMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(StatsService);
  });

  describe('recordStats', () => {
    it('lança NotFoundException se jogo não encontrado', async () => {
      mockGameRepo.findById.mockResolvedValue(null);
      await expect(
        service.recordStats('organizer-uuid-1', 'not-found', { players: [] }),
      ).rejects.toThrow(NotFoundException);
    });

    it('lança ForbiddenException se não é o organizador', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      await expect(
        service.recordStats('other-user', 'game-uuid-1', { players: [] }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('faz upsert de stats e publica STATS_RECORDED', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      mockStatsRepo.upsertStats.mockResolvedValue([mockStats]);

      const result = await service.recordStats('organizer-uuid-1', 'game-uuid-1', {
        players: [{ playerUserId: 'player-uuid-1', goals: 2, assists: 1 }],
      });

      expect(mockStatsRepo.upsertStats).toHaveBeenCalledWith([
        expect.objectContaining({
          gameExternalId: 'game-uuid-1',
          playerUserId: 'player-uuid-1',
          goals: 2,
          assists: 1,
        }),
      ]);
      expect(mockMessaging.publishStatsRecorded).toHaveBeenCalledWith(mockGame);
      expect(result[0].goals).toBe(2);
    });
  });

  describe('getGameStats', () => {
    it('retorna stats de um jogo', async () => {
      mockGameRepo.findById.mockResolvedValue(mockGame);
      mockStatsRepo.findByGame.mockResolvedValue([mockStats]);

      const result = await service.getGameStats('game-uuid-1');

      expect(result).toHaveLength(1);
      expect(result[0].goals).toBe(2);
    });

    it('lança NotFoundException se jogo não existe', async () => {
      mockGameRepo.findById.mockResolvedValue(null);
      await expect(service.getGameStats('not-found')).rejects.toThrow(NotFoundException);
    });
  });
});
