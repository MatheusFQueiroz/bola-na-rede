import type { Team } from '../models/team.entity';
import type { TeamMember } from '../models/team-member.entity';

export const TEAM_REPOSITORY = 'TEAM_REPOSITORY';

export interface CreateTeamData {
  name: string;
  description?: string;
  captainUserId: string;
  captainDisplayName: string;
  minPlayers: number;
  maxPlayers: number;
}

export interface TeamWithCount extends Team {
  memberCount: number;
}

export interface TeamRepositoryInterface {
  create(data: CreateTeamData): Promise<Team>;
  findById(externalId: string): Promise<Team | null>;
  findByIdWithMemberCount(externalId: string): Promise<TeamWithCount | null>;
  update(externalId: string, data: Partial<Pick<Team, 'name' | 'description'>>): Promise<Team>;
  deactivate(externalId: string): Promise<void>;
  addMember(teamExternalId: string, playerUserId: string, displayName: string, position: string | null): Promise<TeamMember>;
  removeMember(teamExternalId: string, playerUserId: string): Promise<void>;
  findMember(teamExternalId: string, playerUserId: string): Promise<TeamMember | null>;
  findMembers(teamExternalId: string): Promise<TeamMember[]>;
  countActiveMembers(teamExternalId: string): Promise<number>;
  setCaptain(teamExternalId: string, newCaptainUserId: string): Promise<void>;
  updateMemberSnapshot(playerUserId: string, displayName: string, position: string | null): Promise<void>;
}
