import { Injectable } from '@nestjs/common';
import { RedisService } from '../../infra/cache/redis.service';
import type { MatchRequest, SportType } from '../../domain/models/match-request.entity';

const REQUEST_TTL_MS = 5 * 60 * 1000; // 5 minutes

@Injectable()
export class MatchmakingQueueService {
  constructor(private readonly redis: RedisService) {}

  private queueKey(sport: SportType): string {
    return `matchmaking:queue:${sport}`;
  }

  /** Adiciona request à fila. Score = timestamp ms (FIFO por mais antigo). */
  async enqueue(request: MatchRequest): Promise<void> {
    await this.redis.client.zadd(
      this.queueKey(request.sport),
      request.requestedAt.getTime(),
      request.externalId,
    );
  }

  /** Remove request da fila (cancelamento). */
  async dequeue(sport: SportType, externalId: string): Promise<void> {
    await this.redis.client.zrem(this.queueKey(sport), externalId);
  }

  /**
   * Busca e reivindica atomicamente o candidato mais antigo na fila.
   * Usa ZREM para garantir que apenas um worker processe cada candidato.
   * Remove entradas expiradas durante a busca.
   * Retorna o externalId do candidato ou null se nenhum disponível.
   */
  async findAndClaimCandidate(
    sport: SportType,
    excludeExternalId: string,
  ): Promise<string | null> {
    const now = Date.now();
    const validSince = now - REQUEST_TTL_MS;

    // Remove requests expirados (score < validSince)
    await this.redis.client.zremrangebyscore(this.queueKey(sport), '-inf', validSince - 1);

    // Busca até 20 candidatos válidos (ordenados por tempo de entrada)
    const candidates = await this.redis.client.zrangebyscore(
      this.queueKey(sport),
      validSince,
      '+inf',
      'LIMIT',
      0,
      20,
    );

    for (const candidateId of candidates) {
      if (candidateId !== excludeExternalId) {
        // Reivindicação atômica: apenas um worker remove com sucesso
        const removed = await this.redis.client.zrem(this.queueKey(sport), candidateId);
        if (removed === 1) return candidateId;
        // Outro worker já reivindicou — tentar próximo
      }
    }

    return null;
  }
}
