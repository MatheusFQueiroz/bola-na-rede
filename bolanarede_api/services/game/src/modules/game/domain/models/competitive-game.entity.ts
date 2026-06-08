export type GameStatus = 'scheduled' | 'completed' | 'disputed';

export class CompetitiveGame {
  id!: number;
  externalId!: string;
  matchId!: string;
  userAId!: string;
  userBId!: string;
  sport!: string;
  status!: GameStatus;
  playerAGoals!: number;
  playerBGoals!: number;
  playerAAssists!: number;
  playerBAssists!: number;
  /** null = empate */
  winnerId!: string | null;
  /** userId de quem submeteu o placar */
  submittedByUserId!: string | null;
  createdAt!: Date;
  updatedAt!: Date;
}
