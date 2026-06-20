import type { PlayerRanking } from '../models/player-ranking.entity';

export const RANKING_REPOSITORY = 'RANKING_REPOSITORY';

export interface UpsertRankingData {
  playerUserId: string;
  displayName?: string;
  sport: string;
  goals: number;
  assists: number;
  isWin: boolean;
  isDraw: boolean;
}

export interface RankingRepositoryInterface {
  /**
   * Tenta inserir o gameId na tabela de controle.
   * Retorna true se inserido (novo), false se já existia (já processado).
   */
  insertProcessedGameIfNew(gameId: string): Promise<boolean>;
  /**
   * Upsert atômico: cria o ranking se não existir, ou incrementa
   * games_played/wins/losses/draws/goals/assists/points se já existir.
   */
  upsertRanking(data: UpsertRankingData): Promise<PlayerRanking>;
  findByPlayerAndSport(playerUserId: string, sport: string): Promise<PlayerRanking | null>;
  /** Retorna os top `limit` jogadores do sport, ordenados por points DESC, wins DESC. */
  getLeaderboard(sport: string, limit: number): Promise<PlayerRanking[]>;
  /** Atualiza o displayName snapshot para todas as linhas do jogador (todos os sports). */
  updateDisplayName(playerUserId: string, displayName: string): Promise<void>;
}
