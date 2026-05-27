import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import { UserMessagingService } from '../../../users/application/services/user-messaging.service';

@Injectable()
export class DeviceTokenService {
  private readonly logger = new Logger(DeviceTokenService.name);

  constructor(
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly deviceTokenRepository: DeviceTokenRepositoryInterface,
    private readonly userMessaging: UserMessagingService,
  ) {}

  async upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<void> {
    await this.deviceTokenRepository.upsert(userId, token, platform);
    try {
      await this.userMessaging.publishDeviceTokenUpdated(userId, token, platform);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to publish DEVICE_TOKEN_UPDATED for user ${userId}: ${message}`);
    }
  }
}
