import type { RabbitMQConfig } from '@golevelup/nestjs-rabbitmq';
import type { ConfigService } from '@nestjs/config';

export function createRabbitMQConfig(config: ConfigService): RabbitMQConfig {
  return {
    exchanges: [
      { name: 'bolanarededb', type: 'topic' },
      { name: 'bolanarededb.dlq', type: 'topic' },
    ],
    uri: config.getOrThrow<string>('RABBITMQ_URL'),
    connectionInitOptions: { wait: false },
  };
}
