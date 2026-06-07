export type BadgeCode = 'first-game' | 'goal-scorer' | 'level-5' | 'level-10';

export class PlayerBadge {
  playerUserId!: string;
  badgeCode!: BadgeCode;
  earnedAt!: Date;
}
