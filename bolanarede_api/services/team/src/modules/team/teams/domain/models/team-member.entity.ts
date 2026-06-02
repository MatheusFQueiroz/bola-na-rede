export class TeamMember {
  playerUserId!: string;     // identity UUID (cross-service, stored as text)
  displayName!: string;      // snapshot from identity.profile-updated events
  position!: string | null;  // snapshot from identity.profile-updated events
  role!: 'captain' | 'member';
  joinedAt!: Date;
  leftAt!: Date | null;      // null = active member
}
