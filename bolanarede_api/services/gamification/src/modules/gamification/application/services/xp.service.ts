import { Inject, Injectable } from '@nestjs/common';
import {
  PROFILE_REPOSITORY,
  ProfileRepositoryInterface,
} from '../../domain/repositories/profile-repository.interface';
import {
  XP_LEDGER_REPOSITORY,
  XpLedgerRepositoryInterface,
} from '../../domain/repositories/xp-ledger-repository.interface';
import {
  BADGE_REPOSITORY,
  BadgeRepositoryInterface,
} from '../../domain/repositories/badge-repository.interface';
import { GamificationMessagingService } from './gamification-messaging.service';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge, BadgeCode } from '../../domain/models/player-badge.entity';

export interface OpenGameStatsPayload {
  gameId: string;
  players: Array<{
    playerUserId: string;
    displayName: string;
    goals: number;
    assists: number;
  }>;
}

@Injectable()
export class XpService {
  constructor(
    @Inject(PROFILE_REPOSITORY)
    private readonly profileRepo: ProfileRepositoryInterface,
    @Inject(XP_LEDGER_REPOSITORY)
    private readonly xpLedgerRepo: XpLedgerRepositoryInterface,
    @Inject(BADGE_REPOSITORY)
    private readonly badgeRepo: BadgeRepositoryInterface,
    private readonly messaging: GamificationMessagingService,
  ) {}

  async processOpenGameStats(payload: OpenGameStatsPayload): Promise<void> {
    for (const player of payload.players) {
      await this.grantXpForPlayer(
        player.playerUserId,
        player.displayName,
        payload.gameId,
        player.goals,
        player.assists,
      );
    }
  }

  async handleUserRegistered(playerUserId: string, displayName: string): Promise<void> {
    await this.profileRepo.upsertProfile(playerUserId, displayName);
  }

  async handleProfileUpdated(playerUserId: string, displayName: string): Promise<void> {
    await this.profileRepo.updateDisplayName(playerUserId, displayName);
  }

  async getProfile(
    playerUserId: string,
  ): Promise<{ profile: PlayerProfile | null; badges: PlayerBadge[] }> {
    const [profile, badges] = await Promise.all([
      this.profileRepo.findByPlayer(playerUserId),
      this.badgeRepo.findEarnedBadges(playerUserId),
    ]);
    return { profile, badges };
  }

  async getLeaderboard(): Promise<PlayerProfile[]> {
    return this.profileRepo.findTopByXp(10);
  }

  private async grantXpForPlayer(
    playerUserId: string,
    displayName: string,
    gameId: string,
    goals: number,
    assists: number,
  ): Promise<void> {
    await this.profileRepo.upsertProfile(playerUserId, displayName);

    let totalXpToAdd = 0;
    let isFirstGame = false;
    let earnedGoal = false;

    // Participation XP (idempotency gate)
    const participationEntry = await this.xpLedgerRepo.recordXp({
      playerUserId,
      sourceType: 'open-game',
      sourceId: gameId,
      xpEarned: 10,
      reason: 'participation',
    });

    if (participationEntry) {
      totalXpToAdd += 10;
      isFirstGame = true;
    } else {
      // Already processed — skip to avoid double XP
      return;
    }

    // Goal XP
    if (goals > 0) {
      const goalEntry = await this.xpLedgerRepo.recordXp({
        playerUserId,
        sourceType: 'open-game',
        sourceId: gameId,
        xpEarned: goals * 5,
        reason: 'goal',
      });
      if (goalEntry) {
        totalXpToAdd += goals * 5;
        earnedGoal = true;
      }
    }

    // Assist XP
    if (assists > 0) {
      const assistEntry = await this.xpLedgerRepo.recordXp({
        playerUserId,
        sourceType: 'open-game',
        sourceId: gameId,
        xpEarned: assists * 3,
        reason: 'assist',
      });
      if (assistEntry) {
        totalXpToAdd += assists * 3;
      }
    }

    if (totalXpToAdd === 0) return;

    const updatedProfile = await this.profileRepo.addXp(playerUserId, totalXpToAdd);

    // Collect badges to check
    const badgesToCheck: BadgeCode[] = [];

    if (isFirstGame) {
      badgesToCheck.push('first-game');
    }

    if (earnedGoal) {
      const hasGoalNow = await this.xpLedgerRepo.hasGoal(playerUserId);
      if (hasGoalNow) {
        badgesToCheck.push('goal-scorer');
      }
    }

    if (updatedProfile.level >= 5) {
      badgesToCheck.push('level-5');
    }

    if (updatedProfile.level >= 10) {
      badgesToCheck.push('level-10');
    }

    // Fire-and-forget badge grants
    try {
      for (const badgeCode of badgesToCheck) {
        const badge = await this.badgeRepo.awardBadge(playerUserId, badgeCode);
        if (badge) {
          await this.messaging.publishBadgeAwarded(badge);
        }
      }
    } catch {
      // advisory
    }
  }
}
