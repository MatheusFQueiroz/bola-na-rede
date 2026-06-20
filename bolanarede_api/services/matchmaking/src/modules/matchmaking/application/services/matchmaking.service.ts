import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import {
  MATCH_REQUEST_REPOSITORY,
  MatchRequestRepositoryInterface,
} from '../../domain/repositories/match-request-repository.interface';
import {
  PENDING_MATCH_REPOSITORY,
  PendingMatchRepositoryInterface,
} from '../../domain/repositories/pending-match-repository.interface';
import { MatchmakingQueueService } from './matchmaking-queue.service';
import { MatchmakingMessagingService } from './matchmaking-messaging.service';
import type { MatchRequest, SportType } from '../../domain/models/match-request.entity';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

const REQUEST_TTL_MS = 5 * 60 * 1000; // 5 min
const MATCH_TTL_MS = 2 * 60 * 1000;   // 2 min

@Injectable()
export class MatchmakingService {
  private readonly logger = new Logger(MatchmakingService.name);

  constructor(
    @Inject(MATCH_REQUEST_REPOSITORY)
    private readonly requestRepo: MatchRequestRepositoryInterface,
    @Inject(PENDING_MATCH_REPOSITORY)
    private readonly matchRepo: PendingMatchRepositoryInterface,
    private readonly queueService: MatchmakingQueueService,
    private readonly messaging: MatchmakingMessagingService,
  ) {}

  async createRequest(
    userId: string,
    displayName: string,
    sport: SportType,
  ): Promise<MatchRequest> {
    // Validate no active request exists
    const existing = await this.requestRepo.findActivByUserId(userId);
    if (existing) {
      throw new ConflictException('Player already has an active match request');
    }

    const now = new Date();
    const request = await this.requestRepo.create({
      externalId: uuidv4(),
      requesterUserId: userId,
      displayName,
      sport,
      expiresAt: new Date(now.getTime() + REQUEST_TTL_MS),
    });

    // Buscar e reivindicar oponente na fila (atômico via ZREM)
    const candidateId = await this.queueService.findAndClaimCandidate(sport, request.externalId);

    if (candidateId) {
      const opponent = await this.requestRepo.findByExternalId(candidateId);
      // Verify candidate is a different user and still pending
      if (opponent && opponent.requesterUserId !== userId && opponent.status === 'pending') {
        return this.proposeMatch(request, opponent);
      }
    }

    // No opponent found — enqueue
    await this.queueService.enqueue(request);
    return request;
  }

  async cancelRequest(userId: string, requestExternalId: string): Promise<void> {
    const request = await this.requestRepo.findByExternalId(requestExternalId);
    if (!request) throw new NotFoundException('Match request not found');
    if (request.requesterUserId !== userId) {
      throw new ForbiddenException("Cannot cancel another player's request");
    }

    await this.requestRepo.updateStatus(requestExternalId, 'cancelled');
    await this.queueService.dequeue(request.sport, requestExternalId);
  }

  async getRequest(userId: string, requestExternalId: string): Promise<MatchRequest> {
    const request = await this.requestRepo.findByExternalId(requestExternalId);
    if (!request) throw new NotFoundException('Match request not found');
    if (request.requesterUserId !== userId) {
      throw new ForbiddenException("Cannot view another player's request");
    }

    // Lazy expiration check
    if (request.status === 'pending' && request.expiresAt < new Date()) {
      await this.requestRepo.updateStatus(requestExternalId, 'expired');
      await this.queueService.dequeue(request.sport, requestExternalId);
      return { ...request, status: 'expired' };
    }

    return request;
  }

  async getActiveRequest(userId: string): Promise<MatchRequest | null> {
    return this.requestRepo.findActivByUserId(userId);
  }

  async acceptMatch(userId: string, matchExternalId: string): Promise<PendingMatch> {
    const match = await this.matchRepo.findByExternalId(matchExternalId);
    if (!match) throw new NotFoundException('Pending match not found');

    if (match.status !== 'proposed') {
      throw new ConflictException(`Match is already ${match.status}`);
    }

    // Lazy expiration check
    if (match.expiresAt < new Date()) {
      await this.matchRepo.updateStatus(matchExternalId, 'expired');
      try {
        await this.messaging.publishMatchExpired({ ...match, status: 'expired' });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(`Failed to publish match-expired for ${matchExternalId}: ${message}`);
      }
      throw new ConflictException('Match has expired');
    }

    // Determine player role
    let role: 'A' | 'B';
    if (match.userAId === userId) role = 'A';
    else if (match.userBId === userId) role = 'B';
    else throw new ForbiddenException('You are not part of this match');

    const updated = await this.matchRepo.accept(matchExternalId, role);

    if (updated.acceptedByA && updated.acceptedByB) {
      await this.matchRepo.updateStatus(matchExternalId, 'accepted');
      const accepted = { ...updated, status: 'accepted' as const };
      try {
        await this.messaging.publishMatchAccepted(accepted);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(`Failed to publish match-accepted for ${matchExternalId}: ${message}`);
      }
      return accepted;
    }

    return updated;
  }

  private async proposeMatch(requestA: MatchRequest, requestB: MatchRequest): Promise<MatchRequest> {
    const now = new Date();
    const match = await this.matchRepo.create({
      externalId: uuidv4(),
      requestAExternalId: requestA.externalId,
      requestBExternalId: requestB.externalId,
      userAId: requestA.requesterUserId,
      userBId: requestB.requesterUserId,
      sport: requestA.sport,
      expiresAt: new Date(now.getTime() + MATCH_TTL_MS),
    });

    await this.requestRepo.updateStatus(requestA.externalId, 'matched');
    await this.requestRepo.updateStatus(requestB.externalId, 'matched');
    // requestB was already removed from Redis atomically by findAndClaimCandidate.
    // requestA was never enqueued (enqueue only happens when no candidate is found).

    try {
      await this.messaging.publishMatchRequested(match);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to publish match-requested for ${match.externalId}: ${message}`);
    }

    return { ...requestA, status: 'matched' };
  }
}
