import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { MATCH_REQUEST_REPOSITORY } from './domain/repositories/match-request-repository.interface';
import { PENDING_MATCH_REPOSITORY } from './domain/repositories/pending-match-repository.interface';
import { DrizzleMatchRequestRepository } from './infra/database/repositories/drizzle-match-request.repository';
import { DrizzlePendingMatchRepository } from './infra/database/repositories/drizzle-pending-match.repository';
import { RedisService } from './infra/cache/redis.service';
import { MatchmakingQueueService } from './application/services/matchmaking-queue.service';
import { MatchmakingMessagingService } from './application/services/matchmaking-messaging.service';
import { MatchmakingService } from './application/services/matchmaking.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { MatchRequestsController } from './infra/controllers/match-requests.controller';
import { MatchesController } from './infra/controllers/matches.controller';

@Module({
  imports: [SharedModule],
  controllers: [MatchRequestsController, MatchesController],
  providers: [
    { provide: MATCH_REQUEST_REPOSITORY, useClass: DrizzleMatchRequestRepository },
    { provide: PENDING_MATCH_REPOSITORY, useClass: DrizzlePendingMatchRepository },
    RedisService,
    MatchmakingQueueService,
    MatchmakingMessagingService,
    MatchmakingService,
    IdentityEventsConsumer,
  ],
})
export class MatchmakingModule {}
