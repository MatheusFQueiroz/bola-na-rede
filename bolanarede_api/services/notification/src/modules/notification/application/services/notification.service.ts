import { Injectable, Inject, Logger, NotFoundException } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../infra/redis/redis.provider';
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepositoryInterface,
} from '../../domain/repositories/notification-repository.interface';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import { PushNotificationService } from '../../infra/push/push-notification.service';
import type { Notification, NotificationType } from '../../domain/models/notification.entity';

export interface CreateNotificationData {
  eventId: string;
  recipientUserId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, unknown>;
}

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @Inject(NOTIFICATION_REPOSITORY)
    private readonly notifRepo: NotificationRepositoryInterface,
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly tokenRepo: DeviceTokenRepositoryInterface,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly push: PushNotificationService,
  ) {}

  async createNotification(data: CreateNotificationData): Promise<void> {
    const dedupKey = `notification:dedup:${data.eventId}`;
    const set = await this.redis.set(dedupKey, '1', 'EX', 86400, 'NX');
    if (set === null) {
      this.logger.debug(`Event ${data.eventId} already processed, skipping`);
      return;
    }

    const notif = await this.notifRepo.create({
      recipientUserId: data.recipientUserId,
      type: data.type,
      title: data.title,
      body: data.body,
      data: data.data,
    });

    const deviceToken = await this.tokenRepo.findByUserId(data.recipientUserId);
    if (deviceToken) {
      try {
        await this.push.send(deviceToken.token, data.title, data.body, data.data);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(
          `Push notification failed for user ${data.recipientUserId}: ${message}`,
        );
      }
    }

    this.logger.debug(`Notification ${notif.id} created for user ${data.recipientUserId}`);
  }

  async getNotifications(userId: string, skip: number, limit: number): Promise<Notification[]> {
    return this.notifRepo.findByUserId(userId, skip, limit);
  }

  async markAsRead(notificationId: string, userId: string): Promise<Notification> {
    const notif = await this.notifRepo.markAsRead(notificationId, userId);
    if (!notif) throw new NotFoundException(`Notification ${notificationId} not found`);
    return notif;
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notifRepo.markAllAsRead(userId);
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notifRepo.countUnread(userId);
  }
}
