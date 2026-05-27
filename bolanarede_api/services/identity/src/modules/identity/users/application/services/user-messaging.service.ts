import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

@Injectable()
export class UserMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishUserRegistered(user: User): Promise<void> {
    await this.messaging.publish(IdentityEvents.USER_REGISTERED, {
      userId: user.id,
      email: user.email,
      createdAt: user.createdAt,
    });
  }

  async publishProfileUpdated(user: User, profile: PlayerProfile): Promise<void> {
    await this.messaging.publish(IdentityEvents.PROFILE_UPDATED, {
      userId: user.id,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
      city: profile.city,
      position: profile.position,
    });
  }

  async publishDeviceTokenUpdated(
    userId: string,
    token: string,
    platform: string,
  ): Promise<void> {
    await this.messaging.publish(IdentityEvents.DEVICE_TOKEN_UPDATED, {
      userId,
      token,
      platform,
    });
  }
}
