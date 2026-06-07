import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { GamificationEvents } from '@shared/contracts/events/gamification-events.enum';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

@Injectable()
export class GamificationMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishBadgeAwarded(badge: PlayerBadge): Promise<void> {
    await this.messaging.publish(GamificationEvents.BADGE_AWARDED, {
      playerUserId: badge.playerUserId,
      badgeCode: badge.badgeCode,
      earnedAt: badge.earnedAt,
    });
  }
}
