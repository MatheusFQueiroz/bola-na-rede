import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  TEAM_REPOSITORY,
  TeamRepositoryInterface,
} from '../../domain/repositories/team-repository.interface';
import { TeamMessagingService } from './team-messaging.service';
import { CreateTeamDto } from '../dto/create-team.dto';
import { UpdateTeamDto } from '../dto/update-team.dto';
import { TransferCaptaincyDto } from '../dto/transfer-captaincy.dto';
import { TeamDto } from '../dto/team.dto';
import { TeamMemberDto } from '../dto/team-member.dto';

@Injectable()
export class TeamService {
  constructor(
    @Inject(TEAM_REPOSITORY)
    private readonly teamRepository: TeamRepositoryInterface,
    private readonly messaging: TeamMessagingService,
  ) {}

  async create(userId: string, userName: string, dto: CreateTeamDto): Promise<TeamDto> {
    const team = await this.teamRepository.create({
      name: dto.name,
      description: dto.description,
      captainUserId: userId,
      captainDisplayName: userName,
      minPlayers: dto.minPlayers ?? 5,
      maxPlayers: dto.maxPlayers ?? 11,
    });

    await this.messaging.publishTeamCreated(team, 1);
    return TeamDto.fromTeamAndCount(team, 1);
  }

  async getTeam(teamId: string): Promise<TeamDto> {
    const result = await this.teamRepository.findByIdWithMemberCount(teamId);
    if (!result) throw new NotFoundException(`Team ${teamId} not found`);
    return TeamDto.fromTeamAndCount(result, result.memberCount);
  }

  async update(userId: string, teamId: string, dto: UpdateTeamDto): Promise<TeamDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can update the team');
    }

    const updated = await this.teamRepository.update(teamId, {
      name: dto.name,
      description: dto.description,
    });
    const count = await this.teamRepository.countActiveMembers(teamId);
    return TeamDto.fromTeamAndCount(updated, count);
  }

  async deactivate(userId: string, teamId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can deactivate the team');
    }

    await this.teamRepository.deactivate(teamId);

    try {
      await this.messaging.publishTeamBecameInvalid(team);
    } catch (error) {
      // Advisory event — don't fail the deactivation
    }
  }

  async join(userId: string, userName: string, teamId: string): Promise<TeamMemberDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team || !team.isActive) throw new NotFoundException(`Team ${teamId} not found`);

    const existing = await this.teamRepository.findMember(teamId, userId);
    if (existing) throw new ConflictException('Already a member of this team');

    const count = await this.teamRepository.countActiveMembers(teamId);
    if (count >= team.maxPlayers) throw new ConflictException('Team is full');

    const member = await this.teamRepository.addMember(teamId, userId, userName, null);

    try {
      await this.messaging.publishPlayerJoined(team, member);
    } catch (error) {
      // Advisory event
    }

    return TeamMemberDto.fromMember(member);
  }

  async leave(userId: string, teamId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);

    if (team.captainUserId === userId) {
      throw new ForbiddenException('Captain must transfer captaincy before leaving');
    }

    const member = await this.teamRepository.findMember(teamId, userId);
    if (!member) throw new NotFoundException('Not a member of this team');

    await this.teamRepository.removeMember(teamId, userId);

    const count = await this.teamRepository.countActiveMembers(teamId);

    try {
      await this.messaging.publishPlayerLeft(team, userId);
      if (count < team.minPlayers) {
        await this.messaging.publishTeamBecameInvalid(team);
      }
    } catch (error) {
      // Advisory events
    }
  }

  async removeMember(captainId: string, teamId: string, playerId: string): Promise<void> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== captainId) {
      throw new ForbiddenException('Only the captain can remove members');
    }
    if (playerId === captainId) {
      throw new ForbiddenException('Captain cannot remove themselves; use leave instead');
    }

    const member = await this.teamRepository.findMember(teamId, playerId);
    if (!member) throw new NotFoundException('Player is not a member of this team');

    await this.teamRepository.removeMember(teamId, playerId);

    const count = await this.teamRepository.countActiveMembers(teamId);

    try {
      await this.messaging.publishPlayerLeft(team, playerId);
      if (count < team.minPlayers) {
        await this.messaging.publishTeamBecameInvalid(team);
      }
    } catch (error) {
      // Advisory events
    }
  }

  async transferCaptaincy(
    userId: string,
    teamId: string,
    dto: TransferCaptaincyDto,
  ): Promise<TeamDto> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    if (team.captainUserId !== userId) {
      throw new ForbiddenException('Only the captain can transfer captaincy');
    }

    const newCaptain = await this.teamRepository.findMember(teamId, dto.newCaptainId);
    if (!newCaptain) throw new NotFoundException('New captain is not a member of this team');

    await this.teamRepository.setCaptain(teamId, dto.newCaptainId);

    const [updatedTeam, count] = await Promise.all([
      this.teamRepository.findById(teamId),
      this.teamRepository.countActiveMembers(teamId),
    ]);

    try {
      await this.messaging.publishCaptaincyTransferred(updatedTeam!, userId, dto.newCaptainId);
    } catch (error) {
      // Advisory event
    }

    return TeamDto.fromTeamAndCount(updatedTeam!, count);
  }

  async getMembers(teamId: string): Promise<TeamMemberDto[]> {
    const team = await this.teamRepository.findById(teamId);
    if (!team) throw new NotFoundException(`Team ${teamId} not found`);
    const members = await this.teamRepository.findMembers(teamId);
    return members.map(TeamMemberDto.fromMember);
  }

  async listByUser(userId: string): Promise<TeamDto[]> {
    const userTeams = await this.teamRepository.listByUser(userId);
    const results = await Promise.all(
      userTeams.map(async (team) => {
        const count = await this.teamRepository.countActiveMembers(team.id);
        return TeamDto.fromTeamAndCount(team, count);
      }),
    );
    return results;
  }
}
