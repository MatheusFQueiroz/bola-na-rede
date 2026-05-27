export class PlayerProfile {
  id!: string;       // maps to users.external_id (player identity)
  displayName!: string;
  photoUrl!: string | null;
  bio!: string | null;
  city!: string | null;
  position!: 'goalkeeper' | 'defender' | 'midfielder' | 'forward' | null;
  skillLevel!: number | null;
  isPublic!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
