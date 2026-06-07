import type { PlayerBadge, BadgeCode } from '../models/player-badge.entity';

export const BADGE_REPOSITORY = 'BADGE_REPOSITORY';

export interface BadgeRepositoryInterface {
  /** Concede badge ao jogador. Retorna null se já possuía o badge (idempotente). */
  awardBadge(playerUserId: string, badgeCode: BadgeCode): Promise<PlayerBadge | null>;
  findEarnedBadges(playerUserId: string): Promise<PlayerBadge[]>;
}
