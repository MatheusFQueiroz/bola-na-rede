import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

@Injectable()
export class MatchmakingMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishMatchRequested(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_REQUESTED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
      expiresAt: match.expiresAt,
    });
  }

  async publishMatchAccepted(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_ACCEPTED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
    });
  }

  async publishMatchExpired(match: PendingMatch): Promise<void> {
    await this.messaging.publish(MatchmakingEvents.MATCH_EXPIRED, {
      matchId: match.externalId,
      userAId: match.userAId,
      userBId: match.userBId,
      sport: match.sport,
    });
  }
}
