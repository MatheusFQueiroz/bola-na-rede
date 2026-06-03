import { Injectable } from '@nestjs/common';
import { RedisService } from '../../../../../infra/cache/redis.service';
import type { OpenGameDto } from '../../application/dto/open-game.dto';

const UPCOMING_KEY = 'games:upcoming';
const UPCOMING_TTL = 30; // seconds

@Injectable()
export class GameCacheService {
  constructor(private readonly redis: RedisService) {}

  async getUpcoming(): Promise<OpenGameDto[] | null> {
    const cached = await this.redis.client.get(UPCOMING_KEY);
    return cached ? (JSON.parse(cached) as OpenGameDto[]) : null;
  }

  async setUpcoming(games: OpenGameDto[]): Promise<void> {
    await this.redis.client.set(UPCOMING_KEY, JSON.stringify(games), 'EX', UPCOMING_TTL);
  }

  async invalidate(): Promise<void> {
    await this.redis.client.del(UPCOMING_KEY);
  }

  /** Tenta adquirir lock exclusivo (SET NX PX). Retorna true se lock adquirido. */
  async acquireJoinLock(gameId: string): Promise<boolean> {
    const result = await this.redis.client.set(
      `lock:join:game:${gameId}`,
      '1',
      'PX',
      3000,
      'NX',
    );
    return result === 'OK';
  }

  async releaseJoinLock(gameId: string): Promise<void> {
    await this.redis.client.del(`lock:join:game:${gameId}`);
  }
}
