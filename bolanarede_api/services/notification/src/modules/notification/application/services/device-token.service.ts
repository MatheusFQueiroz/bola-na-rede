import { Injectable, Inject } from '@nestjs/common';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import type { DeviceToken, DevicePlatform } from '../../domain/models/device-token.entity';

@Injectable()
export class DeviceTokenService {
  constructor(
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly repo: DeviceTokenRepositoryInterface,
  ) {}

  async upsertToken(userId: string, token: string, platform: DevicePlatform): Promise<DeviceToken> {
    return this.repo.upsert({ userId, token, platform });
  }

  async getToken(userId: string): Promise<DeviceToken | null> {
    return this.repo.findByUserId(userId);
  }
}
