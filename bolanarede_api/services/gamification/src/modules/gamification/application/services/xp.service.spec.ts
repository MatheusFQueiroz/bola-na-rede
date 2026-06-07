import { Test, TestingModule } from '@nestjs/testing';
import { XpService } from './xp.service';
import { PROFILE_REPOSITORY } from '../../domain/repositories/profile-repository.interface';
import { XP_LEDGER_REPOSITORY } from '../../domain/repositories/xp-ledger-repository.interface';
import { BADGE_REPOSITORY } from '../../domain/repositories/badge-repository.interface';
import { GamificationMessagingService } from './gamification-messaging.service';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

const mockProfile = (overrides: Partial<PlayerProfile> = {}): PlayerProfile => ({
  playerUserId: 'user-1',
  displayName: 'Alice',
  totalXp: 0,
  level: 1,
  updatedAt: new Date(),
  ...overrides,
});

const mockBadge = (badgeCode: string): PlayerBadge => ({
  playerUserId: 'user-1',
  badgeCode: badgeCode as PlayerBadge['badgeCode'],
  earnedAt: new Date(),
});

describe('XpService', () => {
  let service: XpService;
  let profileRepo: {
    upsertProfile: jest.Mock;
    findByPlayer: jest.Mock;
    addXp: jest.Mock;
    updateDisplayName: jest.Mock;
    findTopByXp: jest.Mock;
  };
  let xpLedgerRepo: { recordXp: jest.Mock; hasGoal: jest.Mock };
  let badgeRepo: { awardBadge: jest.Mock; findEarnedBadges: jest.Mock };
  let messaging: { publishBadgeAwarded: jest.Mock };

  beforeEach(async () => {
    profileRepo = {
      upsertProfile: jest.fn(),
      findByPlayer: jest.fn(),
      addXp: jest.fn(),
      updateDisplayName: jest.fn(),
      findTopByXp: jest.fn(),
    };
    xpLedgerRepo = {
      recordXp: jest.fn(),
      hasGoal: jest.fn(),
    };
    badgeRepo = {
      awardBadge: jest.fn(),
      findEarnedBadges: jest.fn(),
    };
    messaging = { publishBadgeAwarded: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        XpService,
        { provide: PROFILE_REPOSITORY, useValue: profileRepo },
        { provide: XP_LEDGER_REPOSITORY, useValue: xpLedgerRepo },
        { provide: BADGE_REPOSITORY, useValue: badgeRepo },
        { provide: GamificationMessagingService, useValue: messaging },
      ],
    }).compile();

    service = module.get<XpService>(XpService);
  });

  describe('processOpenGameStats', () => {
    it('grants participation XP and first-game badge on first game', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      xpLedgerRepo.recordXp.mockImplementation(async (data: any) => {
        if (data.reason === 'participation') return { ...data, id: 1, createdAt: new Date() };
        return null;
      });
      badgeRepo.awardBadge.mockImplementation(async (_: string, code: string) =>
        code === 'first-game' ? mockBadge('first-game') : null,
      );
      const afterXp = mockProfile({ totalXp: 10, level: 1 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(profileRepo.upsertProfile).toHaveBeenCalledWith('user-1', 'Alice');
      expect(xpLedgerRepo.recordXp).toHaveBeenCalledWith(
        expect.objectContaining({ playerUserId: 'user-1', reason: 'participation', xpEarned: 10 }),
      );
      expect(profileRepo.addXp).toHaveBeenCalledWith('user-1', 10);
      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'first-game');
      expect(messaging.publishBadgeAwarded).toHaveBeenCalled();
    });

    it('skips XP grant when participation already recorded (idempotent)', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      xpLedgerRepo.recordXp.mockResolvedValue(null); // already exists
      badgeRepo.awardBadge.mockResolvedValue(null);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(profileRepo.addXp).not.toHaveBeenCalled();
    });

    it('grants goal XP and goal-scorer badge on first goal', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile());
      xpLedgerRepo.recordXp.mockImplementation(async (data: any) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(true);
      badgeRepo.awardBadge.mockImplementation(async (_: string, code: string) =>
        mockBadge(code),
      );
      profileRepo.addXp.mockResolvedValue(mockProfile({ totalXp: 15, level: 1 }));
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-1',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 1, assists: 0 }],
      });

      const xpCalls = xpLedgerRepo.recordXp.mock.calls.map((c: any[]) => c[0]);
      expect(xpCalls).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ reason: 'participation', xpEarned: 10 }),
          expect.objectContaining({ reason: 'goal', xpEarned: 5 }),
        ]),
      );
      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'goal-scorer');
    });

    it('awards level-5 badge when totalXp crosses 400', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile({ totalXp: 390 }));
      xpLedgerRepo.recordXp.mockImplementation(async (data: any) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(false);
      const afterXp = mockProfile({ totalXp: 400, level: 5 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      badgeRepo.awardBadge.mockImplementation(async (_: string, code: string) =>
        code === 'level-5' ? mockBadge('level-5') : null,
      );
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-2',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'level-5');
      expect(messaging.publishBadgeAwarded).toHaveBeenCalledWith(
        expect.objectContaining({ badgeCode: 'level-5' }),
      );
    });

    it('awards level-10 badge when totalXp crosses 900', async () => {
      profileRepo.upsertProfile.mockResolvedValue(mockProfile({ totalXp: 890 }));
      xpLedgerRepo.recordXp.mockImplementation(async (data: any) => ({
        ...data, id: 1, createdAt: new Date(),
      }));
      xpLedgerRepo.hasGoal.mockResolvedValue(false);
      const afterXp = mockProfile({ totalXp: 900, level: 10 });
      profileRepo.addXp.mockResolvedValue(afterXp);
      badgeRepo.awardBadge.mockImplementation(async (_: string, code: string) =>
        code === 'level-10' ? mockBadge('level-10') : null,
      );
      messaging.publishBadgeAwarded.mockResolvedValue(undefined);

      await service.processOpenGameStats({
        gameId: 'game-3',
        players: [{ playerUserId: 'user-1', displayName: 'Alice', goals: 0, assists: 0 }],
      });

      expect(badgeRepo.awardBadge).toHaveBeenCalledWith('user-1', 'level-10');
    });
  });

  describe('getProfile', () => {
    it('returns profile with badges for existing player', async () => {
      profileRepo.findByPlayer.mockResolvedValue(mockProfile({ totalXp: 50 }));
      badgeRepo.findEarnedBadges.mockResolvedValue([mockBadge('first-game')]);

      const result = await service.getProfile('user-1');

      expect(result.profile!.totalXp).toBe(50);
      expect(result.badges).toHaveLength(1);
      expect(result.badges[0].badgeCode).toBe('first-game');
    });

    it('returns null profile for unknown player', async () => {
      profileRepo.findByPlayer.mockResolvedValue(null);
      badgeRepo.findEarnedBadges.mockResolvedValue([]);

      const result = await service.getProfile('unknown');

      expect(result.profile).toBeNull();
    });
  });
});
