export class GameParticipant {
  gameExternalId!: string;   // UUID do jogo (para retorno na API)
  playerUserId!: string;     // identity UUID
  displayName!: string;      // snapshot atualizado via identity.profile-updated
  position!: string | null;  // snapshot
  joinedAt!: Date;
  leftAt!: Date | null;
}
