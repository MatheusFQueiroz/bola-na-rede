import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { RANKING_REPOSITORY } from './domain/repositories/ranking-repository.interface';
import { DrizzleRankingRepository } from './infra/database/repositories/drizzle-ranking.repository';
import { RankingMessagingService } from './application/services/ranking-messaging.service';
import { RankingService } from './application/services/ranking.service';
import { GameEventsConsumer } from './application/services/game-events.consumer';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { RankingsController } from './infra/controllers/rankings.controller';

@Module({
  imports: [SharedModule],
  controllers: [RankingsController],
  providers: [
    { provide: RANKING_REPOSITORY, useClass: DrizzleRankingRepository },
    RankingMessagingService,
    RankingService,
    GameEventsConsumer,
    IdentityEventsConsumer,
  ],
})
export class RankingModule {}
