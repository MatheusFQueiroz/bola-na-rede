export class DeviceToken {
  userId!: string; // users.external_id
  token!: string;
  platform!: 'ios' | 'android';
  isActive!: boolean;
  updatedAt!: Date;
}
