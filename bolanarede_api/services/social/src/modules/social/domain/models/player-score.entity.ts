export class PlayerScore {
  playerUserId!: string;    // UUID do jogador
  displayName!: string;     // snapshot
  totalReviews!: number;
  averageScore!: number;    // média das reviews (0.00 a 5.00)
  updatedAt!: Date;
}
