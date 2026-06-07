export type XpSourceType = 'open-game' | 'game';
export type XpReason = 'participation' | 'goal' | 'assist' | 'win';

export class XpLedgerEntry {
  id!: number;
  playerUserId!: string;
  sourceType!: XpSourceType;
  sourceId!: string;
  xpEarned!: number;
  reason!: XpReason;
  createdAt!: Date;
}
