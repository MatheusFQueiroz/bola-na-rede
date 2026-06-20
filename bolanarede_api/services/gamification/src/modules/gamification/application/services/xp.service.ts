import { Inject, Injectable, Logger } from '@nestjs/common';
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

export interface MatchCompletedPayload {
  gameId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{
    playerUserId: string;
    goals: number;
    assists: number;
    won: boolean;
  }>;
}

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
  private readonly logger = new Logger(XpService.name);

  constructor(
    @Inject(PROFILE_REPOSITORY)
    private readonly profileRepo: ProfileRepositoryInterface,
    @Inject(XP_LEDGER_REPOSITORY)
    private readonly xpLedgerRepo: XpLedgerRepositoryInterface,
    @Inject(BADGE_REPOSITORY)
    private readonly badgeRepo: BadgeRepositoryInterface,
    private readonly messaging: GamificationMessagingService,
  ) {}

  async processMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    for (const player of payload.players) {
      await this.grantCompetitiveXp(payload.gameId, player);
    }
  }

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

  private async grantCompetitiveXp(
    gameId: string,
    player: { playerUserId: string; goals: number; assists: number; won: boolean },
  ): Promise<void> {
    const existing = await this.profileRepo.findByPlayer(player.playerUserId);
    const displayName = existing?.displayName ?? '';
    await this.profileRepo.upsertProfile(player.playerUserId, displayName);

    const participationEntry = await this.xpLedgerRepo.recordXp({
      playerUserId: player.playerUserId,
      sourceType: 'game',
      sourceId: gameId,
      xpEarned: 15,
      reason: 'participation',
    });

    if (!participationEntry) return;

    let totalXpToAdd = 15;
    const badgesToCheck: BadgeCode[] = ['first-game'];

    if (player.won) {
      const winEntry = await this.xpLedgerRepo.recordXp({
        playerUserId: player.playerUserId,
        sourceType: 'game',
        sourceId: gameId,
        xpEarned: 20,
        reason: 'win',
      });
      if (winEntry) totalXpToAdd += 20;
    }

    if (player.goals > 0) {
      const goalEntry = await this.xpLedgerRepo.recordXp({
        playerUserId: player.playerUserId,
        sourceType: 'game',
        sourceId: gameId,
        xpEarned: player.goals * 8,
        reason: 'goal',
      });
      if (goalEntry) {
        totalXpToAdd += player.goals * 8;
        badgesToCheck.push('goal-scorer');
      }
    }

    if (player.assists > 0) {
      const assistEntry = await this.xpLedgerRepo.recordXp({
        playerUserId: player.playerUserId,
        sourceType: 'game',
        sourceId: gameId,
        xpEarned: player.assists * 4,
        reason: 'assist',
      });
      if (assistEntry) totalXpToAdd += player.assists * 4;
    }

    const updatedProfile = await this.profileRepo.addXp(player.playerUserId, totalXpToAdd);

    if (updatedProfile.level >= 5) badgesToCheck.push('level-5');
    if (updatedProfile.level >= 10) badgesToCheck.push('level-10');

    try {
      for (const badgeCode of badgesToCheck) {
        const badge = await this.badgeRepo.awardBadge(player.playerUserId, badgeCode);
        if (badge) await this.messaging.publishBadgeAwarded(badge);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Badge grant failed for player ${player.playerUserId}: ${message}`);
    }
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
    let isNewParticipationRecorded = false;
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
      isNewParticipationRecorded = true;
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

    if (isNewParticipationRecorded) {
      badgesToCheck.push('first-game');
    }

    if (earnedGoal) {
      badgesToCheck.push('goal-scorer');
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Badge grant failed for player ${playerUserId}: ${message}`);
    }
  }
}
