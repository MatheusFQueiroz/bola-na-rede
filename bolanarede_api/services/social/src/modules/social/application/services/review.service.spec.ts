import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { ReviewService } from './review.service';
import { REVIEW_REPOSITORY } from '../../domain/repositories/review-repository.interface';
import { SCORE_REPOSITORY } from '../../domain/repositories/score-repository.interface';
import { SocialMessagingService } from './social-messaging.service';
import type { PlayerReview } from '../../domain/models/player-review.entity';
import type { PlayerScore } from '../../domain/models/player-score.entity';
import type { CreateReviewDto } from '../dto/create-review.dto';

const mockReview: PlayerReview = {
  id: 'review-uuid-1',
  gameId: 'game-uuid-1',
  gameType: 'open-game',
  reviewerUserId: 'user-a',
  reviewerDisplayName: 'Player A',
  revieweeUserId: 'user-b',
  revieweeDisplayName: 'Player B',
  score: 4,
  createdAt: new Date('2026-01-01'),
};

const mockScore: PlayerScore = {
  playerUserId: 'user-b',
  displayName: 'Player B',
  totalReviews: 1,
  averageScore: 4.0,
  updatedAt: new Date('2026-01-01'),
};

describe('ReviewService', () => {
  let service: ReviewService;
  let mockReviewRepo: jest.Mocked<any>;
  let mockScoreRepo: jest.Mocked<any>;
  let mockMessaging: jest.Mocked<any>;

  beforeEach(async () => {
    mockReviewRepo = {
      create: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      existsForGame: jest.fn(),
      updateDisplayNames: jest.fn(),
    };

    mockScoreRepo = {
      findByPlayer: jest.fn(),
      recalculate: jest.fn(),
      updateDisplayName: jest.fn(),
    };

    mockMessaging = {
      publishPlayerReviewed: jest.fn().mockResolvedValue(undefined),
      publishScoreUpdated: jest.fn().mockResolvedValue(undefined),
    };

    const module = await Test.createTestingModule({
      providers: [
        ReviewService,
        { provide: REVIEW_REPOSITORY, useValue: mockReviewRepo },
        { provide: SCORE_REPOSITORY, useValue: mockScoreRepo },
        { provide: SocialMessagingService, useValue: mockMessaging },
      ],
    }).compile();

    service = module.get(ReviewService);
  });

  describe('createReview', () => {
    const dto: CreateReviewDto = {
      gameId: 'game-uuid-1',
      gameType: 'open-game',
      revieweeUserId: 'user-b',
      score: 4,
    };

    it('cria review, recalcula score e publica eventos', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(false);
      mockScoreRepo.findByPlayer.mockResolvedValue(mockScore);
      mockReviewRepo.create.mockResolvedValue(mockReview);
      mockScoreRepo.recalculate.mockResolvedValue(mockScore);

      const result = await service.createReview('user-a', 'Player A', dto);

      expect(mockReviewRepo.existsForGame).toHaveBeenCalledWith('user-a', 'game-uuid-1');
      expect(mockReviewRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUserId: 'user-a',
          reviewerDisplayName: 'Player A',
          revieweeUserId: 'user-b',
          score: 4,
          gameId: 'game-uuid-1',
          gameType: 'open-game',
        }),
      );
      expect(mockScoreRepo.recalculate).toHaveBeenCalledWith('user-b', expect.any(String));
      expect(mockMessaging.publishPlayerReviewed).toHaveBeenCalledWith(mockReview);
      expect(mockMessaging.publishScoreUpdated).toHaveBeenCalledWith(mockScore);
      expect(result.id).toBe('review-uuid-1');
    });

    it('lança BadRequestException quando reviewer === reviewee', async () => {
      await expect(
        service.createReview('user-b', 'Player B', { ...dto, revieweeUserId: 'user-b' }),
      ).rejects.toThrow(BadRequestException);

      expect(mockReviewRepo.existsForGame).not.toHaveBeenCalled();
    });

    it('lança ConflictException quando reviewer já avaliou neste jogo', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(true);

      await expect(service.createReview('user-a', 'Player A', dto)).rejects.toThrow(
        ConflictException,
      );

      expect(mockReviewRepo.create).not.toHaveBeenCalled();
    });

    it('não propaga erro de messaging (fire-and-forget)', async () => {
      mockReviewRepo.existsForGame.mockResolvedValue(false);
      mockScoreRepo.findByPlayer.mockResolvedValue(null);
      mockReviewRepo.create.mockResolvedValue(mockReview);
      mockScoreRepo.recalculate.mockResolvedValue(mockScore);
      mockMessaging.publishPlayerReviewed.mockRejectedValue(new Error('AMQP down'));

      await expect(service.createReview('user-a', 'Player A', dto)).resolves.toBeDefined();
    });
  });

  describe('listReviews', () => {
    it('retorna lista de ReviewDtos', async () => {
      mockReviewRepo.findAll.mockResolvedValue([mockReview]);

      const result = await service.listReviews({ revieweeUserId: 'user-b' });

      expect(mockReviewRepo.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ revieweeUserId: 'user-b' }),
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('review-uuid-1');
    });
  });

  describe('getPlayerScore', () => {
    it('retorna PlayerScoreDto quando score existe', async () => {
      mockScoreRepo.findByPlayer.mockResolvedValue(mockScore);

      const result = await service.getPlayerScore('user-b');

      expect(result.playerUserId).toBe('user-b');
      expect(result.totalReviews).toBe(1);
      expect(result.averageScore).toBe(4.0);
    });

    it('retorna score vazio quando jogador não tem reviews', async () => {
      mockScoreRepo.findByPlayer.mockResolvedValue(null);

      const result = await service.getPlayerScore('user-c');

      expect(result.playerUserId).toBe('user-c');
      expect(result.totalReviews).toBe(0);
      expect(result.averageScore).toBe(0);
    });
  });
});
