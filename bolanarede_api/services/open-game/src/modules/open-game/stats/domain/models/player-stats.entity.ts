export class PlayerStats {
  gameExternalId!: string;   // UUID do jogo
  playerUserId!: string;     // identity UUID
  goals!: number;
  assists!: number;
  notes!: string | null;
  createdAt!: Date;
}
