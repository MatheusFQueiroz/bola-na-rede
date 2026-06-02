import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { TeamEvents } from '@shared/contracts/events/team-events.enum';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';

@Injectable()
export class TeamMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishTeamCreated(team: Team, memberCount: number): Promise<void> {
    await this.messaging.publish(TeamEvents.CREATED, {
      teamId: team.id,
      name: team.name,
      captainUserId: team.captainUserId,
      memberCount,
      createdAt: team.createdAt,
    });
  }

  async publishPlayerJoined(team: Team, member: TeamMember): Promise<void> {
    await this.messaging.publish(TeamEvents.PLAYER_JOINED, {
      teamId: team.id,
      playerUserId: member.playerUserId,
      displayName: member.displayName,
    });
  }

  async publishPlayerLeft(team: Team, playerUserId: string): Promise<void> {
    await this.messaging.publish(TeamEvents.PLAYER_LEFT, {
      teamId: team.id,
      playerUserId,
    });
  }

  async publishTeamBecameInvalid(team: Team): Promise<void> {
    await this.messaging.publish(TeamEvents.BECAME_INVALID, {
      teamId: team.id,
    });
  }

  async publishCaptaincyTransferred(
    team: Team,
    previousCaptainId: string,
    newCaptainId: string,
  ): Promise<void> {
    await this.messaging.publish(TeamEvents.CAPTAINCY_TRANSFERRED, {
      teamId: team.id,
      previousCaptainId,
      newCaptainId,
    });
  }
}
