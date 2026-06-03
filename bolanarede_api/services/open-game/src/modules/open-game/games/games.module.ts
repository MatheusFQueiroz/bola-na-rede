import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { OPEN_GAME_REPOSITORY } from './domain/repositories/open-game-repository.interface';
import { DrizzleOpenGameRepository } from './infra/database/repositories/drizzle-open-game.repository';
import { GameCacheService } from './infra/cache/game-cache.service';
import { OpenGameService } from './application/services/open-game.service';
import { OpenGameMessagingService } from './application/services/open-game-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { OpenGamesController } from './infra/controllers/open-games.controller';
import { RedisService } from '../../../infra/cache/redis.service';

@Module({
  imports: [SharedModule],
  controllers: [OpenGamesController],
  providers: [
    { provide: OPEN_GAME_REPOSITORY, useClass: DrizzleOpenGameRepository },
    RedisService,
    GameCacheService,
    OpenGameService,
    OpenGameMessagingService,
    IdentityEventsConsumer,
  ],
  exports: [OPEN_GAME_REPOSITORY, OpenGameMessagingService],
})
export class GamesModule {}
