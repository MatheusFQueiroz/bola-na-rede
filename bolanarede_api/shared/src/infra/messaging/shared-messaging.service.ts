import { Injectable, Logger } from '@nestjs/common';
import { AmqpConnection } from '@golevelup/nestjs-rabbitmq';

@Injectable()
export class SharedMessagingService {
  private readonly logger = new Logger(SharedMessagingService.name);

  constructor(private readonly amqp: AmqpConnection) {}

  async publish(routingKey: string, payload: Record<string, unknown>): Promise<void> {
    await this.amqp.publish('bolanarededb', routingKey, payload);
    this.logger.debug(`Published event: ${routingKey}`);
  }
}
