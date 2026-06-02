import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { TeamService } from './application/services/team.service';
import { TeamMessagingService } from './application/services/team-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { TeamsController } from './infra/controllers/teams.controller';
import { DrizzleTeamRepository } from './infra/repositories/drizzle-team.repository';
import { TEAM_REPOSITORY } from './domain/repositories/team-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [TeamsController],
  providers: [
    TeamService,
    TeamMessagingService,
    IdentityEventsConsumer,
    { provide: TEAM_REPOSITORY, useClass: DrizzleTeamRepository },
  ],
  exports: [TeamService],
})
export class TeamsModule {}
