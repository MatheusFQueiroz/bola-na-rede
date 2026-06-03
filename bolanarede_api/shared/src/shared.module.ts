import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { RabbitMQModule } from '@golevelup/nestjs-rabbitmq';
import { DrizzleService } from './infra/database/drizzle.service';
import { JwtAuthGuard } from './infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from './infra/auth/guards/permissions.guard';
import { SharedMessagingService } from './infra/messaging/shared-messaging.service';
import { createRabbitMQConfig } from './infra/messaging/rabbitmq.service';

@Global()
@Module({
  imports: [
    ConfigModule,
    JwtModule.register({}),
    RabbitMQModule.forRootAsync(RabbitMQModule, {
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: createRabbitMQConfig,
    }),
  ],
  providers: [DrizzleService, JwtAuthGuard, PermissionsGuard, SharedMessagingService],
  exports: [DrizzleService, JwtAuthGuard, PermissionsGuard, SharedMessagingService, JwtModule, RabbitMQModule],
})
export class SharedModule {}
