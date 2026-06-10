import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';

import { NotificationDoc, NotificationSchema } from './infra/schemas/notification.schema';
import { DeviceTokenDoc, DeviceTokenSchema } from './infra/schemas/device-token.schema';

import { NOTIFICATION_REPOSITORY } from './domain/repositories/notification-repository.interface';
import { DEVICE_TOKEN_REPOSITORY } from './domain/repositories/device-token-repository.interface';

import { MongooseNotificationRepository } from './infra/database/repositories/mongoose-notification.repository';
import { MongooseDeviceTokenRepository } from './infra/database/repositories/mongoose-device-token.repository';
import { redisProvider } from './infra/redis/redis.provider';
import { PushNotificationService } from './infra/push/push-notification.service';

import { NotificationService } from './application/services/notification.service';
import { DeviceTokenService } from './application/services/device-token.service';
import { IdentityEventsConsumer } from './application/services/consumers/identity-events.consumer';
import { MatchmakingEventsConsumer } from './application/services/consumers/matchmaking-events.consumer';
import { GameEventsConsumer } from './application/services/consumers/game-events.consumer';
import { GamificationEventsConsumer } from './application/services/consumers/gamification-events.consumer';

import { NotificationsController } from './infra/controllers/notifications.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NotificationDoc.name, schema: NotificationSchema },
      { name: DeviceTokenDoc.name, schema: DeviceTokenSchema },
    ]),
  ],
  controllers: [NotificationsController],
  providers: [
    { provide: NOTIFICATION_REPOSITORY, useClass: MongooseNotificationRepository },
    { provide: DEVICE_TOKEN_REPOSITORY, useClass: MongooseDeviceTokenRepository },
    redisProvider,
    PushNotificationService,
    SharedMessagingService,
    JwtAuthGuard,
    NotificationService,
    DeviceTokenService,
    IdentityEventsConsumer,
    MatchmakingEventsConsumer,
    GameEventsConsumer,
    GamificationEventsConsumer,
  ],
})
export class NotificationModule {}
