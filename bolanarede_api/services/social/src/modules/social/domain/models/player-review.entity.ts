export type ReviewScore = 1 | 2 | 3 | 4 | 5;
export type GameType = 'open-game' | 'game';

export class PlayerReview {
  id!: string;                    // UUID (external_id)
  gameId!: string;                // UUID do jogo (referência externa)
  gameType!: GameType;
  reviewerUserId!: string;        // UUID do avaliador
  reviewerDisplayName!: string;   // snapshot
  revieweeUserId!: string;        // UUID do avaliado
  revieweeDisplayName!: string;   // snapshot
  score!: ReviewScore;            // 1 a 5
  comment?: string;
  createdAt!: Date;
}
