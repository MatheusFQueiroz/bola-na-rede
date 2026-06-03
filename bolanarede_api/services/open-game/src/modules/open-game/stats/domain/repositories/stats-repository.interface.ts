import type { PlayerStats } from '../models/player-stats.entity';

export const STATS_REPOSITORY = 'STATS_REPOSITORY';

export interface UpsertStatsData {
  gameExternalId: string;
  playerUserId: string;
  goals: number;
  assists: number;
  notes?: string;
}

export interface StatsRepositoryInterface {
  upsertStats(data: UpsertStatsData[]): Promise<PlayerStats[]>;
  findByGame(gameExternalId: string): Promise<PlayerStats[]>;
  findByPlayer(playerUserId: string): Promise<PlayerStats[]>;
}
