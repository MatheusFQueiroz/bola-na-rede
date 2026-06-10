import { Test, TestingModule } from '@nestjs/testing';
import { GameEventsConsumer } from './game-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('GameEventsConsumer', () => {
  let consumer: GameEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(GameEventsConsumer);
  });

  describe('handleMatchCompleted', () => {
    it('creates MATCH_COMPLETED notification for each player', async () => {
      const payload = {
        gameId: 'game-1',
        matchId: 'match-1',
        sport: 'futsal',
        winnerId: 'user-a',
        players: [
          { playerUserId: 'user-a', goals: 2, assists: 0, won: true },
          { playerUserId: 'user-b', goals: 1, assists: 1, won: false },
        ],
      };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchCompleted(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(2);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-a', type: NotificationType.MATCH_COMPLETED }),
      );
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-b', type: NotificationType.MATCH_COMPLETED }),
      );
    });
  });

  describe('handleResultDisputed', () => {
    it('creates RESULT_DISPUTED notification for disputedByUserId', async () => {
      const payload = { gameId: 'game-1', matchId: 'match-1', sport: 'futsal', disputedByUserId: 'user-b' };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleResultDisputed(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-b', type: NotificationType.RESULT_DISPUTED }),
      );
    });
  });
});
