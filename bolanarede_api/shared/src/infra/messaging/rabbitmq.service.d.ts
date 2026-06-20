import type { RabbitMQConfig } from '@golevelup/nestjs-rabbitmq';
import type { ConfigService } from '@nestjs/config';
export declare function createRabbitMQConfig(config: ConfigService): RabbitMQConfig;
