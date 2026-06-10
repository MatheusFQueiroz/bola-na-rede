import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export const REDIS_CLIENT = 'REDIS_CLIENT';

export const redisProvider = {
  provide: REDIS_CLIENT,
  useFactory: (config: ConfigService) => {
    return new Redis(config.getOrThrow<string>('REDIS_URL'));
  },
  inject: [ConfigService],
};
