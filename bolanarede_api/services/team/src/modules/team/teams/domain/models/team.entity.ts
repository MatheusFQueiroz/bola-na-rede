export class Team {
  id!: string;           // external_id UUID
  name!: string;
  description!: string | null;
  captainUserId!: string;   // identity UUID (cross-service, stored as text)
  minPlayers!: number;
  maxPlayers!: number;
  isActive!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
