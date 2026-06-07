import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { PROFILE_REPOSITORY } from './domain/repositories/profile-repository.interface';
import { XP_LEDGER_REPOSITORY } from './domain/repositories/xp-ledger-repository.interface';
import { BADGE_REPOSITORY } from './domain/repositories/badge-repository.interface';
import { DrizzleProfileRepository } from './infra/database/repositories/drizzle-profile.repository';
import { DrizzleXpBadgeRepository } from './infra/database/repositories/drizzle-xp-badge.repository';
import { XpService } from './application/services/xp.service';
import { GamificationMessagingService } from './application/services/gamification-messaging.service';
import { IdentityEventsConsumer } from './application/services/identity-events.consumer';
import { OpenGameEventsConsumer } from './application/services/open-game-events.consumer';
import { GameEventsConsumer } from './application/services/game-events.consumer';
import { GamificationController } from './infra/controllers/gamification.controller';

@Module({
  imports: [SharedModule],
  controllers: [GamificationController],
  providers: [
    { provide: PROFILE_REPOSITORY, useClass: DrizzleProfileRepository },
    { provide: XP_LEDGER_REPOSITORY, useClass: DrizzleXpBadgeRepository },
    { provide: BADGE_REPOSITORY, useClass: DrizzleXpBadgeRepository },
    XpService,
    GamificationMessagingService,
    IdentityEventsConsumer,
    OpenGameEventsConsumer,
    GameEventsConsumer,
  ],
})
export class GamificationModule {}
