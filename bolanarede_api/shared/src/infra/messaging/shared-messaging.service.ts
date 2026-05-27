import { Injectable, Logger } from '@nestjs/common';
import { AmqpConnection } from '@golevelup/nestjs-rabbitmq';

@Injectable()
export class SharedMessagingService {
  private readonly logger = new Logger(SharedMessagingService.name);

  constructor(private readonly amqp: AmqpConnection) {}

  async publish(routingKey: string, payload: Record<string, unknown>): Promise<void> {
    try {
      await this.amqp.publish('bolanarededb', routingKey, payload);
      this.logger.debug(`Published event: ${routingKey}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to publish event ${routingKey}: ${message}`);
      throw error;
    }
  }
}
