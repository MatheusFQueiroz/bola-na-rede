import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
export declare class UserMessagingService {
    private readonly messaging;
    constructor(messaging: SharedMessagingService);
    publishUserRegistered(user: User): Promise<void>;
    publishProfileUpdated(user: User, profile: PlayerProfile): Promise<void>;
    publishDeviceTokenUpdated(userId: string, token: string, platform: string): Promise<void>;
}
