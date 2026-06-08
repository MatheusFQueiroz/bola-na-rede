import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { RankingService } from './ranking.service';
import { RANKING_REPOSITORY } from '../../domain/repositories/ranking-repository.interface';
import { RankingMessagingService } from './ranking-messaging.service';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

const makeRanking = (overrides: Partial<PlayerRanking> = {}): PlayerRanking => ({
  id: 1,
  playerUserId: 'user-a',
  sport: 'futsal',
  gamesPlayed: 1,
  wins: 1,
  losses: 0,
  draws: 0,
  goals: 2,
  assists: 1,
  points: 3,
  updatedAt: new Date(),
  ...overrides,
});

const matchPayload = {
  gameId: 'game-1',
  matchId: 'match-1',
  sport: 'futsal',
  winnerId: 'user-a' as string | null,
  players: [
    { playerUserId: 'user-a', goals: 2, assists: 1, won: true },
    { playerUserId: 'user-b', goals: 0, assists: 0, won: false },
  ],
};

describe('RankingService', () => {
  let service: RankingService;
  let rankingRepo: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    rankingRepo = {
      insertProcessedGameIfNew: jest.fn(),
      upsertRanking: jest.fn(),
      findByPlayerAndSport: jest.fn(),
      getLeaderboard: jest.fn(),
    };
    messaging = {
      publishRankingRecalculated: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RankingService,
        { provide: RANKING_REPOSITORY, useValue: rankingRepo },
        { provide: RankingMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<RankingService>(RankingService);
  });

  describe('processMatchCompleted', () => {
    it('skips processing if game already processed (idempotent)', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(false);

      await service.processMatchCompleted(matchPayload);

      expect(rankingRepo.upsertRanking).not.toHaveBeenCalled();
      expect(messaging.publishRankingRecalculated).not.toHaveBeenCalled();
    });

    it('awards 3 points to winner and 0 to loser', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      await service.processMatchCompleted(matchPayload);

      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-a', isWin: true, isDraw: false }),
      );
      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-b', isWin: false, isDraw: false }),
      );
    });

    it('awards 1 point to both players on draw', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      const drawPayload = {
        ...matchPayload,
        winnerId: null,
        players: [
          { playerUserId: 'user-a', goals: 1, assists: 0, won: false },
          { playerUserId: 'user-b', goals: 1, assists: 0, won: false },
        ],
      };

      await service.processMatchCompleted(drawPayload);

      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-a', isWin: false, isDraw: true }),
      );
      expect(rankingRepo.upsertRanking).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-b', isWin: false, isDraw: true }),
      );
    });

    it('publishes ranking-recalculated for each player after upsert', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockResolvedValue(undefined);

      await service.processMatchCompleted(matchPayload);

      expect(messaging.publishRankingRecalculated).toHaveBeenCalledTimes(2);
    });

    it('does not throw if messaging publish fails', async () => {
      rankingRepo.insertProcessedGameIfNew.mockResolvedValue(true);
      rankingRepo.upsertRanking.mockResolvedValue(makeRanking());
      messaging.publishRankingRecalculated.mockRejectedValue(new Error('RabbitMQ down'));

      await expect(service.processMatchCompleted(matchPayload)).resolves.not.toThrow();
    });
  });

  describe('getLeaderboard', () => {
    it('returns leaderboard entries with 1-based positions', async () => {
      rankingRepo.getLeaderboard.mockResolvedValue([
        makeRanking({ playerUserId: 'user-a', points: 9 }),
        makeRanking({ playerUserId: 'user-b', points: 3 }),
      ]);

      const result = await service.getLeaderboard('futsal', 10);

      expect(result[0].position).toBe(1);
      expect(result[0].playerUserId).toBe('user-a');
      expect(result[1].position).toBe(2);
      expect(result[1].playerUserId).toBe('user-b');
    });
  });
});
