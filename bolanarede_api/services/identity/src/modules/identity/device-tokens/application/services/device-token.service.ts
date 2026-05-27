import { Inject, Injectable } from '@nestjs/common';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import { UserMessagingService } from '../../../users/application/services/user-messaging.service';

@Injectable()
export class DeviceTokenService {
  constructor(
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly deviceTokenRepository: DeviceTokenRepositoryInterface,
    private readonly userMessaging: UserMessagingService,
  ) {}

  async upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<void> {
    await this.deviceTokenRepository.upsert(userId, token, platform);
    await this.userMessaging.publishDeviceTokenUpdated(userId, token, platform);
  }
}
