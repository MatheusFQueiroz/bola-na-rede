export type DevicePlatform = 'ios' | 'android' | 'web';

export class DeviceToken {
  id!: string;
  userId!: string;
  token!: string;
  platform!: DevicePlatform;
  updatedAt!: Date;
}
