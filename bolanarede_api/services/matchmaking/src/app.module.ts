import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MatchmakingModule } from './modules/matchmaking/matchmaking.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MatchmakingModule,
  ],
})
export class AppModule {}
