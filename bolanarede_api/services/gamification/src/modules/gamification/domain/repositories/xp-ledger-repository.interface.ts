import type { XpLedgerEntry, XpSourceType, XpReason } from '../models/xp-ledger.entity';

export const XP_LEDGER_REPOSITORY = 'XP_LEDGER_REPOSITORY';

export interface RecordXpData {
  playerUserId: string;
  sourceType: XpSourceType;
  sourceId: string;
  xpEarned: number;
  reason: XpReason;
}

export interface XpLedgerRepositoryInterface {
  /** Insere entrada de XP. Retorna null se a entrada já existir (idempotente). */
  recordXp(data: RecordXpData): Promise<XpLedgerEntry | null>;
  /** Retorna true se o jogador possui ao menos uma entrada com reason='goal'. */
  hasGoal(playerUserId: string): Promise<boolean>;
}
