import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { MatchmakingService } from './matchmaking.service';
import { MATCH_REQUEST_REPOSITORY } from '../../domain/repositories/match-request-repository.interface';
import { PENDING_MATCH_REPOSITORY } from '../../domain/repositories/pending-match-repository.interface';
import { MatchmakingQueueService } from './matchmaking-queue.service';
import { MatchmakingMessagingService } from './matchmaking-messaging.service';
import type { MatchRequest } from '../../domain/models/match-request.entity';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

const makeRequest = (overrides: Partial<MatchRequest> = {}): MatchRequest => ({
  id: 1,
  externalId: 'req-1',
  requesterUserId: 'user-1',
  displayName: 'Alice',
  sport: 'futsal',
  status: 'pending',
  requestedAt: new Date(),
  expiresAt: new Date(Date.now() + 5 * 60 * 1000),
  updatedAt: new Date(),
  ...overrides,
});

const makeMatch = (overrides: Partial<PendingMatch> = {}): PendingMatch => ({
  id: 1,
  externalId: 'match-1',
  requestAExternalId: 'req-1',
  requestBExternalId: 'req-2',
  userAId: 'user-1',
  userBId: 'user-2',
  sport: 'futsal',
  status: 'proposed',
  acceptedByA: false,
  acceptedByB: false,
  proposedAt: new Date(),
  expiresAt: new Date(Date.now() + 2 * 60 * 1000),
  updatedAt: new Date(),
  ...overrides,
});

describe('MatchmakingService', () => {
  let service: MatchmakingService;
  let requestRepo: jest.Mocked<any>;
  let matchRepo: jest.Mocked<any>;
  let queueService: jest.Mocked<any>;
  let messaging: jest.Mocked<any>;

  beforeEach(async () => {
    requestRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      findActivByUserId: jest.fn(),
      updateStatus: jest.fn(),
      updateDisplayName: jest.fn(),
    };
    matchRepo = {
      create: jest.fn(),
      findByExternalId: jest.fn(),
      accept: jest.fn(),
      updateStatus: jest.fn(),
    };
    queueService = {
      enqueue: jest.fn(),
      dequeue: jest.fn(),
      findAndClaimCandidate: jest.fn(),
    };
    messaging = {
      publishMatchRequested: jest.fn(),
      publishMatchAccepted: jest.fn(),
      publishMatchExpired: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchmakingService,
        { provide: MATCH_REQUEST_REPOSITORY, useValue: requestRepo },
        { provide: PENDING_MATCH_REPOSITORY, useValue: matchRepo },
        { provide: MatchmakingQueueService, useValue: queueService },
        { provide: MatchmakingMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<MatchmakingService>(MatchmakingService);
  });

  describe('createRequest', () => {
    it('creates pending request and enqueues when no opponent found', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(null);
      requestRepo.create.mockResolvedValue(makeRequest());
      queueService.findAndClaimCandidate.mockResolvedValue(null);
      queueService.enqueue.mockResolvedValue(undefined);

      const result = await service.createRequest('user-1', 'Alice', 'futsal');

      expect(requestRepo.create).toHaveBeenCalled();
      expect(queueService.findAndClaimCandidate).toHaveBeenCalled();
      expect(queueService.enqueue).toHaveBeenCalled();
      expect(result.status).toBe('pending');
    });

    it('throws ConflictException when user already has active request', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(makeRequest({ status: 'pending' }));

      await expect(service.createRequest('user-1', 'Alice', 'futsal')).rejects.toThrow(
        ConflictException,
      );
    });

    it('creates match and publishes MATCH_REQUESTED when opponent found in queue', async () => {
      requestRepo.findActivByUserId.mockResolvedValue(null);
      const ownRequest = makeRequest({ externalId: 'req-1', requesterUserId: 'user-1' });
      requestRepo.create.mockResolvedValue(ownRequest);
      queueService.findAndClaimCandidate.mockResolvedValue('req-2');
      const opponentRequest = makeRequest({
        externalId: 'req-2',
        requesterUserId: 'user-2',
        displayName: 'Bob',
      });
      requestRepo.findByExternalId.mockResolvedValue(opponentRequest);
      const pendingMatch = makeMatch();
      matchRepo.create.mockResolvedValue(pendingMatch);
      requestRepo.updateStatus.mockResolvedValue(undefined);
      queueService.dequeue.mockResolvedValue(undefined);
      messaging.publishMatchRequested.mockResolvedValue(undefined);

      const result = await service.createRequest('user-1', 'Alice', 'futsal');

      expect(matchRepo.create).toHaveBeenCalled();
      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-1', 'matched');
      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-2', 'matched');
      expect(messaging.publishMatchRequested).toHaveBeenCalled();
      expect(result.status).toBe('matched');
    });
  });

  describe('cancelRequest', () => {
    it('cancels own request and removes from queue', async () => {
      requestRepo.findByExternalId.mockResolvedValue(makeRequest({ requesterUserId: 'user-1' }));
      requestRepo.updateStatus.mockResolvedValue(undefined);
      queueService.dequeue.mockResolvedValue(undefined);

      await service.cancelRequest('user-1', 'req-1');

      expect(requestRepo.updateStatus).toHaveBeenCalledWith('req-1', 'cancelled');
      expect(queueService.dequeue).toHaveBeenCalled();
    });

    it('throws ForbiddenException when cancelling someone else request', async () => {
      requestRepo.findByExternalId.mockResolvedValue(makeRequest({ requesterUserId: 'user-2' }));

      await expect(service.cancelRequest('user-1', 'req-1')).rejects.toThrow(ForbiddenException);
    });
  });

  describe('acceptMatch', () => {
    it('marks partial acceptance (only one player accepted)', async () => {
      const proposed = makeMatch({ status: 'proposed', acceptedByA: false, acceptedByB: false });
      matchRepo.findByExternalId.mockResolvedValue(proposed);
      const afterAccept = makeMatch({ acceptedByA: true, acceptedByB: false });
      matchRepo.accept.mockResolvedValue(afterAccept);

      const result = await service.acceptMatch('user-1', 'match-1');

      expect(matchRepo.accept).toHaveBeenCalledWith('match-1', 'A');
      expect(matchRepo.updateStatus).not.toHaveBeenCalledWith('match-1', 'accepted');
      expect(messaging.publishMatchAccepted).not.toHaveBeenCalled();
      expect(result.status).toBe('proposed');
    });

    it('marks accepted and publishes MATCH_ACCEPTED when both players accept', async () => {
      const proposed = makeMatch({ status: 'proposed', acceptedByA: true, acceptedByB: false });
      matchRepo.findByExternalId.mockResolvedValue(proposed);
      const fullyAccepted = makeMatch({ status: 'accepted', acceptedByA: true, acceptedByB: true });
      matchRepo.accept.mockResolvedValue(fullyAccepted);
      matchRepo.updateStatus.mockResolvedValue(undefined);
      messaging.publishMatchAccepted.mockResolvedValue(undefined);

      const result = await service.acceptMatch('user-2', 'match-1');

      expect(matchRepo.accept).toHaveBeenCalledWith('match-1', 'B');
      expect(matchRepo.updateStatus).toHaveBeenCalledWith('match-1', 'accepted');
      expect(messaging.publishMatchAccepted).toHaveBeenCalled();
      expect(result.status).toBe('accepted');
    });

    it('throws NotFoundException when match does not exist', async () => {
      matchRepo.findByExternalId.mockResolvedValue(null);

      await expect(service.acceptMatch('user-1', 'non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
