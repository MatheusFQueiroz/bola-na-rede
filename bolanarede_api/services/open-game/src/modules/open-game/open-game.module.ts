import { Module } from '@nestjs/common';
import { GamesModule } from './games/games.module';
import { StatsModule } from './stats/stats.module';

@Module({
  imports: [GamesModule, StatsModule],
})
export class OpenGameModule {}
