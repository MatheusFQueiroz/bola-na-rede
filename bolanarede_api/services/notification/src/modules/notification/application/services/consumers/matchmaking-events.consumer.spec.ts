import { Test, TestingModule } from '@nestjs/testing';
import { MatchmakingEventsConsumer } from './matchmaking-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('MatchmakingEventsConsumer', () => {
  let consumer: MatchmakingEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchmakingEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(MatchmakingEventsConsumer);
  });

  describe('handleMatchAccepted', () => {
    it('creates MATCH_ACCEPTED notifications for both players', async () => {
      const payload = { matchId: 'match-1', userAId: 'user-a', userBId: 'user-b', sport: 'futsal' };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchAccepted(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(2);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-a', type: NotificationType.MATCH_ACCEPTED }),
      );
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-b', type: NotificationType.MATCH_ACCEPTED }),
      );
    });
  });

  describe('handleMatchExpired', () => {
    it('creates MATCH_EXPIRED notification for userAId only', async () => {
      const payload = { matchId: 'match-1', userAId: 'user-a', userBId: 'user-b', sport: 'futsal' };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchExpired(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-a', type: NotificationType.MATCH_EXPIRED }),
      );
    });
  });
});
