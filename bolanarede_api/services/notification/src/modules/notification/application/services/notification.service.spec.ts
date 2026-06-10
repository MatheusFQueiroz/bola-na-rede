import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { NotificationService, type CreateNotificationData } from './notification.service';
import { NOTIFICATION_REPOSITORY } from '../../domain/repositories/notification-repository.interface';
import { DEVICE_TOKEN_REPOSITORY } from '../../domain/repositories/device-token-repository.interface';
import { REDIS_CLIENT } from '../../infra/redis/redis.provider';
import { PushNotificationService } from '../../infra/push/push-notification.service';
import { NotificationType } from '../../domain/models/notification.entity';

const mockNotifRepo = {
  create: jest.fn(),
  findByUserId: jest.fn(),
  findById: jest.fn(),
  markAsRead: jest.fn(),
  markAllAsRead: jest.fn(),
  countUnread: jest.fn(),
};
const mockTokenRepo = { upsert: jest.fn(), findByUserId: jest.fn() };
const mockRedis = { set: jest.fn() };
const mockPush = { send: jest.fn() };

const makeNotif = (overrides = {}) => ({
  id: 'abc123',
  recipientUserId: 'user-1',
  type: NotificationType.MATCH_ACCEPTED,
  title: 'Match encontrado!',
  body: 'Seu jogo foi aceito.',
  data: {},
  isRead: false,
  createdAt: new Date(),
  ...overrides,
});

describe('NotificationService', () => {
  let service: NotificationService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        { provide: NOTIFICATION_REPOSITORY, useValue: mockNotifRepo },
        { provide: DEVICE_TOKEN_REPOSITORY, useValue: mockTokenRepo },
        { provide: REDIS_CLIENT, useValue: mockRedis },
        { provide: PushNotificationService, useValue: mockPush },
      ],
    }).compile();
    service = module.get(NotificationService);
  });

  describe('createNotification', () => {
    const data: CreateNotificationData = {
      eventId: 'evt-001',
      recipientUserId: 'user-1',
      type: NotificationType.MATCH_ACCEPTED,
      title: 'Match encontrado!',
      body: 'Seu jogo foi aceito.',
      data: {},
    };

    it('skips if event already processed (Redis NX returns null)', async () => {
      mockRedis.set.mockResolvedValue(null);
      await service.createNotification(data);
      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    it('creates notification and sends push when device token exists', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue({ token: 'tok-123', platform: 'ios' });
      mockPush.send.mockResolvedValue(undefined);

      await service.createNotification(data);

      expect(mockNotifRepo.create).toHaveBeenCalledWith({
        recipientUserId: data.recipientUserId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data,
      });
      expect(mockPush.send).toHaveBeenCalledWith('tok-123', data.title, data.body, data.data);
    });

    it('creates notification without push when no device token', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue(null);

      await service.createNotification(data);

      expect(mockNotifRepo.create).toHaveBeenCalled();
      expect(mockPush.send).not.toHaveBeenCalled();
    });

    it('does not throw if push send fails', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue({ token: 'tok-123', platform: 'ios' });
      mockPush.send.mockRejectedValue(new Error('FCM error'));

      await expect(service.createNotification(data)).resolves.not.toThrow();
    });
  });

  describe('markAsRead', () => {
    it('throws NotFoundException if notification not found or not owned by user', async () => {
      mockNotifRepo.markAsRead.mockResolvedValue(null);
      await expect(service.markAsRead('notif-id', 'user-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getUnreadCount', () => {
    it('delegates to repository', async () => {
      mockNotifRepo.countUnread.mockResolvedValue(5);
      const count = await service.getUnreadCount('user-1');
      expect(count).toBe(5);
    });
  });
});
