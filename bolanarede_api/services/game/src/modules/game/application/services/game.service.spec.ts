// game.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { GameService } from './game.service';
import { GAME_REPOSITORY } from '../../domain/repositories/game-repository.interface';
import { GameMessagingService } from './game-messaging.service';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

const makeGame = (overrides: Partial<CompetitiveGame> = {}): CompetitiveGame => ({
  id: 1,
  externalId: 'game-1',
  matchId: 'match-1',
  userAId: 'user-a',
  userBId: 'user-b',
  sport: 'futsal',
  status: 'scheduled',
  playerAGoals: 0,
  playerBGoals: 0,
  playerAAssists: 0,
  playerBAssists: 0,
  winnerId: null,
  submittedByUserId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  ...overrides,
});

describe('GameService', () => {
  let service: GameService;
  let gameRepo: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    gameRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      submitResult: jest.fn(),
      dispute: jest.fn(),
    };
    messaging = {
      publishMatchCompleted: jest.fn(),
      publishResultDisputed: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameService,
        { provide: GAME_REPOSITORY, useValue: gameRepo },
        { provide: GameMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<GameService>(GameService);
  });

  describe('submitResult', () => {
    const dto = { playerAGoals: 3, playerBGoals: 1, playerAAssists: 1, playerBAssists: 0 };

    it('completes game with winner A when A has more goals', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b' }));
      const completed = makeGame({ status: 'completed', playerAGoals: 3, playerBGoals: 1, winnerId: 'user-a', submittedByUserId: 'user-a' });
      gameRepo.submitResult.mockResolvedValue(completed);
      messaging.publishMatchCompleted.mockResolvedValue(undefined);

      const result = await service.submitResult('user-a', 'game-1', dto);

      expect(gameRepo.submitResult).toHaveBeenCalledWith('game-1', expect.objectContaining({ winnerId: 'user-a' }));
      expect(messaging.publishMatchCompleted).toHaveBeenCalled();
      expect(result.status).toBe('completed');
      expect(result.winnerId).toBe('user-a');
    });

    it('completes game with null winner on draw', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b' }));
      const drawn = makeGame({ status: 'completed', playerAGoals: 2, playerBGoals: 2, winnerId: null, submittedByUserId: 'user-a' });
      gameRepo.submitResult.mockResolvedValue(drawn);
      messaging.publishMatchCompleted.mockResolvedValue(undefined);

      await service.submitResult('user-a', 'game-1', { playerAGoals: 2, playerBGoals: 2, playerAAssists: 0, playerBAssists: 0 });

      expect(gameRepo.submitResult).toHaveBeenCalledWith('game-1', expect.objectContaining({ winnerId: null }));
    });

    it('throws ForbiddenException if user is not a participant', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ userAId: 'user-a', userBId: 'user-b' }));

      await expect(service.submitResult('user-x', 'game-1', dto)).rejects.toThrow(ForbiddenException);
    });

    it('throws ConflictException if game is not scheduled', async () => {
      gameRepo.findByExternalId.mockResolvedValue(makeGame({ status: 'completed' }));

      await expect(service.submitResult('user-a', 'game-1', dto)).rejects.toThrow(ConflictException);
    });
  });

  describe('disputeResult', () => {
    it('transitions to disputed and publishes event', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'completed', userAId: 'user-a', userBId: 'user-b', submittedByUserId: 'user-a' }),
      );
      const disputed = makeGame({ status: 'disputed' });
      gameRepo.dispute.mockResolvedValue(disputed);
      messaging.publishResultDisputed.mockResolvedValue(undefined);

      const result = await service.disputeResult('user-b', 'game-1');

      expect(gameRepo.dispute).toHaveBeenCalledWith('game-1');
      expect(messaging.publishResultDisputed).toHaveBeenCalledWith(disputed, 'user-b');
      expect(result.status).toBe('disputed');
    });

    it('throws ForbiddenException if submitter tries to dispute own submission', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'completed', userAId: 'user-a', userBId: 'user-b', submittedByUserId: 'user-a' }),
      );

      await expect(service.disputeResult('user-a', 'game-1')).rejects.toThrow(ForbiddenException);
    });

    it('throws ConflictException if game is not completed', async () => {
      gameRepo.findByExternalId.mockResolvedValue(
        makeGame({ status: 'scheduled', userAId: 'user-a', userBId: 'user-b', submittedByUserId: null }),
      );

      await expect(service.disputeResult('user-b', 'game-1')).rejects.toThrow(ConflictException);
    });
  });
});
