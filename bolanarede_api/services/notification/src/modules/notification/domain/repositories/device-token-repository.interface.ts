import type { DeviceToken, DevicePlatform } from '../models/device-token.entity';

export const DEVICE_TOKEN_REPOSITORY = 'DEVICE_TOKEN_REPOSITORY';

export interface UpsertDeviceTokenData {
  userId: string;
  token: string;
  platform: DevicePlatform;
}

export interface DeviceTokenRepositoryInterface {
  upsert(data: UpsertDeviceTokenData): Promise<DeviceToken>;
  findByUserId(userId: string): Promise<DeviceToken | null>;
}
