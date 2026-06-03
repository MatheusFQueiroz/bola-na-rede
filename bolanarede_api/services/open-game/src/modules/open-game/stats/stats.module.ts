import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { GamesModule } from '../games/games.module';
import { STATS_REPOSITORY } from './domain/repositories/stats-repository.interface';
import { DrizzleStatsRepository } from './infra/database/repositories/drizzle-stats.repository';
import { StatsService } from './application/services/stats.service';
import { StatsController } from './infra/controllers/stats.controller';

@Module({
  imports: [SharedModule, GamesModule],
  controllers: [StatsController],
  providers: [
    { provide: STATS_REPOSITORY, useClass: DrizzleStatsRepository },
    StatsService,
  ],
})
export class StatsModule {}
