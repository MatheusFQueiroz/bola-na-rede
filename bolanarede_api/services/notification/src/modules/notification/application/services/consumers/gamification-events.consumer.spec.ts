import { Test, TestingModule } from '@nestjs/testing';
import { GamificationEventsConsumer } from './gamification-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('GamificationEventsConsumer', () => {
  let consumer: GamificationEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(GamificationEventsConsumer);
  });

  it('creates BADGE_AWARDED notification with badge code in body', async () => {
    const payload = { playerUserId: 'user-1', badgeCode: 'primeiro_gol', earnedAt: new Date() };
    mockNotifService.createNotification.mockResolvedValue(undefined);

    await consumer.handleBadgeAwarded(payload);

    expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
    expect(mockNotifService.createNotification).toHaveBeenCalledWith(
      expect.objectContaining({
        recipientUserId: 'user-1',
        type: NotificationType.BADGE_AWARDED,
        body: 'Você ganhou o badge primeiro_gol!',
      }),
    );
  });

  it('does not throw if createNotification fails', async () => {
    const payload = { playerUserId: 'user-1', badgeCode: 'badge', earnedAt: new Date() };
    mockNotifService.createNotification.mockRejectedValue(new Error('DB down'));

    await expect(consumer.handleBadgeAwarded(payload)).resolves.not.toThrow();
  });
});
