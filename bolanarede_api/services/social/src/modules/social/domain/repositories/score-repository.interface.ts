import type { PlayerScore } from '../models/player-score.entity';

export const SCORE_REPOSITORY = 'SCORE_REPOSITORY';

export interface ScoreRepositoryInterface {
  findByPlayer(playerUserId: string): Promise<PlayerScore | null>;
  recalculate(playerUserId: string, displayName: string): Promise<PlayerScore>;
  updateDisplayName(playerUserId: string, displayName: string): Promise<void>;
}
