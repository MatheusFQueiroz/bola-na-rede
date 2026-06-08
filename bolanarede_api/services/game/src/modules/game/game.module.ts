import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { GAME_REPOSITORY } from './domain/repositories/game-repository.interface';
import { DrizzleGameRepository } from './infra/database/repositories/drizzle-game.repository';
import { GameMessagingService } from './application/services/game-messaging.service';
import { GameService } from './application/services/game.service';
import { MatchmakingEventsConsumer } from './application/services/matchmaking-events.consumer';
import { GamesController } from './infra/controllers/games.controller';

@Module({
  imports: [SharedModule],
  controllers: [GamesController],
  providers: [
    { provide: GAME_REPOSITORY, useClass: DrizzleGameRepository },
    GameMessagingService,
    GameService,
    MatchmakingEventsConsumer,
  ],
})
export class GameModule {}
