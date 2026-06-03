import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { OpenGameService } from './open-game.service';
import { OPEN_GAME_REPOSITORY } from '../../domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from './open-game-messaging.service';
import { GameCacheService } from '../../infra/cache/game-cache.service';
import type { OpenGame } from '../../domain/models/open-game.entity';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

const mockRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findUpcoming: jest.fn(),
  update: jest.fn(),
  updateStatus: jest.fn(),
  deactivate: jest.fn(),
  addParticipant: jest.fn(),
  removeParticipant: jest.fn(),
  findParticipant: jest.fn(),
  findParticipants: jest.fn(),
  countActiveParticipants: jest.fn(),
  updateParticipantSnapshot: jest.fn(),
};

const mockMessaging = {
  publishCreated: jest.fn(),
  publishPlayerJoined: jest.fn(),
  publishPlayerLeft: jest.fn(),
  publishFull: jest.fn(),
  publishFinished: jest.fn(),
  publishCancelled: jest.fn(),
};

const mockCache = {
  getUpcoming: jest.fn(),
  setUpcoming: jest.fn(),
  invalidate: jest.fn(),
  acquireJoinLock: jest.fn(),
  releaseJoinLock: jest.fn(),
};

const mockGame: OpenGame = {
  id: 'game-uuid-1',
  organizerUserId: 'organizer-uuid-1',
  fieldId: null,
  fieldNameSnapshot: null,
  fieldAddressSnapshot: null,
  title: 'Pelada de terça',
  description: null,
  sport: 'society',
  scheduledAt: new Date('2026-07-01T19:00:00Z'),
  durationMinutes: 60,
  minPlayers: 10,
  maxPlayers: 22,
  pricePerPlayer: null,
  status: 'open',
  createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-06-01'),
};

const mockParticipant: GameParticipant = {
  gameExternalId: 'game-uuid-1',
  playerUserId: 'player-uuid-1',
  displayName: 'João Silva',
  position: 'atacante',
  joinedAt: new Date('2026-06-01'),
  leftAt: null,
};

describe('OpenGameService', () => {
  let service: OpenGameService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        OpenGameService,
        { provide: OPEN_GAME_REPOSITORY, useValue: mockRepo },
        { provide: OpenGameMessagingService, useValue: mockMessaging },
        { provide: GameCacheService, useValue: mockCache },
      ],
    }).compile();
    service = module.get(OpenGameService);
  });

  describe('create', () => {
    it('cria jogo, invalida cache e publica CREATED', async () => {
      mockRepo.create.mockResolvedValue(mockGame);
      mockRepo.countActiveParticipants.mockResolvedValue(0);

      const result = await service.create('organizer-uuid-1', 'João', {
        title: 'Pelada de terça',
        sport: 'society',
        scheduledAt: '2026-07-01T19:00:00Z',
      });

      expect(mockRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        organizerUserId: 'organizer-uuid-1',
        title: 'Pelada de terça',
        sport: 'society',
      }));
      expect(mockCache.invalidate).toHaveBeenCalled();
      expect(mockMessaging.publishCreated).toHaveBeenCalledWith(mockGame, 0);
      expect(result.id).toBe('game-uuid-1');
    });
  });

  describe('getById', () => {
    it('retorna jogo com contagem de participantes', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.countActiveParticipants.mockResolvedValue(5);

      const result = await service.getById('game-uuid-1');

      expect(result.id).toBe('game-uuid-1');
      expect(result.participantCount).toBe(5);
    });

    it('lança NotFoundException se jogo não encontrado', async () => {
      mockRepo.findById.mockResolvedValue(null);
      await expect(service.getById('not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('cancel', () => {
    it('lança ForbiddenException se usuário não é o organizador', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      await expect(service.cancel('other-user', 'game-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('cancela jogo, invalida cache e publica CANCELLED', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);

      await service.cancel('organizer-uuid-1', 'game-uuid-1');

      expect(mockRepo.deactivate).toHaveBeenCalledWith('game-uuid-1');
      expect(mockCache.invalidate).toHaveBeenCalled();
    });
  });

  describe('join', () => {
    it('lança ConflictException se jogador já está no jogo', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(mockParticipant);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      await expect(
        service.join('player-uuid-1', 'João', null, 'game-uuid-1'),
      ).rejects.toThrow(ConflictException);

      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
    });

    it('lança ConflictException se jogo está lotado (count >= maxPlayers)', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(null);
      mockRepo.countActiveParticipants.mockResolvedValue(22);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      await expect(
        service.join('player-uuid-1', 'João', null, 'game-uuid-1'),
      ).rejects.toThrow(ConflictException);

      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
    });

    it('adiciona participante, publica PLAYER_JOINED e FULL ao atingir minPlayers', async () => {
      mockRepo.findById.mockResolvedValue(mockGame); // minPlayers=10
      mockRepo.findParticipant.mockResolvedValue(null);
      mockRepo.countActiveParticipants.mockResolvedValue(9); // count pré-join
      mockRepo.addParticipant.mockResolvedValue(mockParticipant);
      mockCache.acquireJoinLock.mockResolvedValue(true);

      const result = await service.join('player-uuid-1', 'João', null, 'game-uuid-1');

      expect(mockRepo.addParticipant).toHaveBeenCalled();
      expect(mockMessaging.publishPlayerJoined).toHaveBeenCalledWith(mockGame, mockParticipant);
      // 9 + 1 = 10 = minPlayers → deve publicar FULL e atualizar status
      expect(mockRepo.updateStatus).toHaveBeenCalledWith('game-uuid-1', 'full');
      expect(mockMessaging.publishFull).toHaveBeenCalledWith(mockGame);
      expect(mockCache.invalidate).toHaveBeenCalled();
      expect(mockCache.releaseJoinLock).toHaveBeenCalledWith('game-uuid-1');
      expect(result.playerUserId).toBe('player-uuid-1');
    });
  });

  describe('leave', () => {
    it('remove participante e publica PLAYER_LEFT', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(mockParticipant);
      mockRepo.countActiveParticipants.mockResolvedValue(11);

      await service.leave('player-uuid-1', 'game-uuid-1');

      expect(mockRepo.removeParticipant).toHaveBeenCalledWith('game-uuid-1', 'player-uuid-1');
      expect(mockCache.invalidate).toHaveBeenCalled();
    });

    it('lança NotFoundException se participante não encontrado', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      mockRepo.findParticipant.mockResolvedValue(null);

      await expect(service.leave('player-uuid-1', 'game-uuid-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('finish', () => {
    it('lança ForbiddenException se não é o organizador', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);
      await expect(service.finish('other-user', 'game-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('marca jogo como finalizado e publica FINISHED', async () => {
      mockRepo.findById.mockResolvedValue(mockGame);

      await service.finish('organizer-uuid-1', 'game-uuid-1');

      expect(mockRepo.updateStatus).toHaveBeenCalledWith('game-uuid-1', 'finished');
      expect(mockMessaging.publishFinished).toHaveBeenCalledWith(mockGame);
      expect(mockCache.invalidate).toHaveBeenCalled();
    });
  });
});
