export class PlayerRanking {
  id!: number;
  playerUserId!: string;
  sport!: string;
  gamesPlayed!: number;
  wins!: number;
  losses!: number;
  draws!: number;
  goals!: number;
  assists!: number;
  /** wins×3 + draws×1 */
  points!: number;
  updatedAt!: Date;
}
