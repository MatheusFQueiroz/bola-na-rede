import type { MatchRequest, MatchRequestStatus, SportType } from '../models/match-request.entity';

export const MATCH_REQUEST_REPOSITORY = 'MATCH_REQUEST_REPOSITORY';

export interface CreateMatchRequestData {
  externalId: string;
  requesterUserId: string;
  displayName: string;
  sport: SportType;
  expiresAt: Date;
}

export interface MatchRequestRepositoryInterface {
  create(data: CreateMatchRequestData): Promise<MatchRequest>;
  findByExternalId(externalId: string): Promise<MatchRequest | null>;
  /** Retorna a request pending/matched mais recente do usuário, se existir. */
  findActivByUserId(userId: string): Promise<MatchRequest | null>;
  updateStatus(externalId: string, status: MatchRequestStatus): Promise<void>;
  updateDisplayName(userId: string, displayName: string): Promise<void>;
}
