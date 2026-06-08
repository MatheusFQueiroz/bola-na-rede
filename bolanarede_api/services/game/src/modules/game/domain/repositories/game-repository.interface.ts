import type { CompetitiveGame } from '../models/competitive-game.entity';

export const GAME_REPOSITORY = 'GAME_REPOSITORY';

export interface CreateGameData {
  externalId: string;
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

export interface SubmitResultData {
  playerAGoals: number;
  playerBGoals: number;
  playerAAssists: number;
  playerBAssists: number;
  winnerId: string | null;
  submittedByUserId: string;
}

export interface GameRepositoryInterface {
  /** Idempotente: ignora duplicata via onConflictDoNothing. Retorna null se já existia. */
  create(data: CreateGameData): Promise<CompetitiveGame | null>;
  findByExternalId(externalId: string): Promise<CompetitiveGame | null>;
  /** Atualiza status para 'completed' e grava o placar. */
  submitResult(externalId: string, data: SubmitResultData): Promise<CompetitiveGame>;
  /** Atualiza status para 'disputed'. */
  dispute(externalId: string): Promise<CompetitiveGame>;
}
