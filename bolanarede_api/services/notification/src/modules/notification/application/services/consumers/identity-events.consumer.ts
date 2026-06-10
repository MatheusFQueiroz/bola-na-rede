import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { DeviceTokenService } from '../device-token.service';
import type { DevicePlatform } from '../../../domain/models/device-token.entity';

interface DeviceTokenUpdatedPayload {
  userId: string;
  token: string;
  platform: DevicePlatform;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(private readonly deviceTokenService: DeviceTokenService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.DEVICE_TOKEN_UPDATED,
    queue: 'notification-service.identity.device-token-updated',
    queueOptions: { durable: true },
  })
  async handleDeviceTokenUpdated(payload: DeviceTokenUpdatedPayload): Promise<void> {
    try {
      await this.deviceTokenService.upsertToken(payload.userId, payload.token, payload.platform);
      this.logger.debug(`Device token updated for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update device token for user ${payload.userId}: ${message}`,
      );
    }
  }
}
