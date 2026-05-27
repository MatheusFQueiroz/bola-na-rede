import type { DeviceToken } from '../models/device-token.entity';

export const DEVICE_TOKEN_REPOSITORY = 'DEVICE_TOKEN_REPOSITORY';

export interface DeviceTokenRepositoryInterface {
  upsert(userId: string, token: string, platform: 'ios' | 'android'): Promise<DeviceToken>;
  findByUserId(userId: string): Promise<DeviceToken[]>;
}
