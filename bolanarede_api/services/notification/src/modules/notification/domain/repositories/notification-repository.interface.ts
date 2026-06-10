import type { Notification, NotificationType } from '../models/notification.entity';

export const NOTIFICATION_REPOSITORY = 'NOTIFICATION_REPOSITORY';

export interface CreateNotificationData {
  recipientUserId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, unknown>;
}

export interface NotificationRepositoryInterface {
  create(data: CreateNotificationData): Promise<Notification>;
  findByUserId(userId: string, skip: number, limit: number): Promise<Notification[]>;
  findById(id: string, userId: string): Promise<Notification | null>;
  markAsRead(id: string, userId: string): Promise<Notification | null>;
  markAllAsRead(userId: string): Promise<void>;
  countUnread(userId: string): Promise<number>;
}
