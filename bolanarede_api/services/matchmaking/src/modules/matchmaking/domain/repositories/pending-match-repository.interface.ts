import type { PendingMatch, PendingMatchStatus } from '../models/pending-match.entity';
import type { SportType } from '../models/match-request.entity';

export const PENDING_MATCH_REPOSITORY = 'PENDING_MATCH_REPOSITORY';

export interface CreatePendingMatchData {
  externalId: string;
  requestAExternalId: string;
  requestBExternalId: string;
  userAId: string;
  userBId: string;
  sport: SportType;
  expiresAt: Date;
}

export interface PendingMatchRepositoryInterface {
  create(data: CreatePendingMatchData): Promise<PendingMatch>;
  findByExternalId(externalId: string): Promise<PendingMatch | null>;
  /** Marca aceitação do jogador A ou B. Retorna o match atualizado. */
  accept(externalId: string, role: 'A' | 'B'): Promise<PendingMatch>;
  updateStatus(externalId: string, status: PendingMatchStatus): Promise<void>;
}
