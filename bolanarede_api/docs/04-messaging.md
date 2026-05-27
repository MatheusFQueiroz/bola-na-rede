# Mensageria — RabbitMQ

## Arquitetura de Eventos

Um exchange único `bolanarededb` do tipo `topic`. Cada serviço tem sua fila dedicada. Routing key = nome do evento.

```
Publisher                Exchange              Consumer Queues
─────────                ────────              ───────────────
open-game  ─ published ─►  bolanarededb  ─────► open-game.identity.profile-updated
identity   ─ published ─►  (topic)       ─────► gamification.open-game.stats-recorded
game       ─ published ─►                ─────► ranking.game.match-completed
```

## Enums de Eventos (shared)

Cada domínio tem seu enum em `shared/src/contracts/events/`:

```typescript
// shared/src/contracts/events/identity-events.enum.ts
export enum IdentityEvents {
  USER_REGISTERED = 'identity.user-registered',
  PROFILE_UPDATED = 'identity.profile-updated',
  DEVICE_TOKEN_UPDATED = 'identity.device-token-updated',
  ACCOUNT_ANONYMIZED = 'identity.account-anonymized',
}

// shared/src/contracts/events/open-game-events.enum.ts
export enum OpenGameEvents {
  CREATED = 'open-game.created',
  PLAYER_JOINED = 'open-game.player-joined',
  PLAYER_LEFT = 'open-game.player-left',
  FULL = 'open-game.full',
  FINISHED = 'open-game.finished',
  CANCELLED = 'open-game.cancelled',
  STATS_RECORDED = 'open-game.stats-recorded',
}

// shared/src/contracts/events/team-events.enum.ts
export enum TeamEvents {
  CREATED = 'team.created',
  PLAYER_JOINED = 'team.player-joined',
  PLAYER_LEFT = 'team.player-left',
  BECAME_INVALID = 'team.became-invalid',
  CAPTAINCY_TRANSFERRED = 'team.captaincy-transferred',
}

// shared/src/contracts/events/field-events.enum.ts
export enum FieldEvents {
  REGISTERED = 'field.registered',
  RESERVATION_CONFIRMED = 'field.reservation-confirmed',
  RESERVATION_CANCELLED = 'field.reservation-cancelled',
  PLAN_SLOT_RELEASED = 'field.plan-slot-released',
}

// shared/src/contracts/events/game-events.enum.ts
export enum GameEvents {
  MATCH_COMPLETED = 'game.match-completed',
  RESULT_DISPUTED = 'game.result-disputed',
}

// shared/src/contracts/events/social-events.enum.ts
export enum SocialEvents {
  PLAYER_REVIEWED = 'social.player-reviewed',
  PLAYER_SCORE_UPDATED = 'social.player-score-updated',
}

// shared/src/contracts/events/gamification-events.enum.ts
export enum GamificationEvents {
  SEASON_ENDED = 'gamification.season-ended',
  BADGE_AWARDED = 'gamification.badge-awarded',
}

// shared/src/contracts/events/matchmaking-events.enum.ts
export enum MatchmakingEvents {
  MATCH_REQUESTED = 'matchmaking.match-requested',
  MATCH_ACCEPTED = 'matchmaking.match-accepted',
  MATCH_EXPIRED = 'matchmaking.match-expired',
}

// shared/src/contracts/events/ranking-events.enum.ts
export enum RankingEvents {
  RECALCULATED = 'ranking.recalculated',
}
```

## Publicando Eventos (Messaging Service)

```typescript
// application/services/open-game-messaging.service.ts
import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';
import { OpenGame } from '../../domain/models/open-game.entity';

@Injectable()
export class OpenGameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishCreated(game: OpenGame): Promise<void> {
    await this.messaging.publish(OpenGameEvents.CREATED, {
      gameId: game.id,
      organizerId: game.organizerId,
      scheduledAt: game.scheduledAt,
      maxPlayers: game.maxPlayers,
      fieldId: game.fieldId,
    });
  }

  async publishPlayerJoined(
    gameId: string,
    playerId: string,
    confirmedCount: number,
  ): Promise<void> {
    await this.messaging.publish(OpenGameEvents.PLAYER_JOINED, {
      gameId,
      playerId,
      confirmedCount,
    });
  }

  async publishFinished(
    game: OpenGame,
    confirmedPlayers: string[],
  ): Promise<void> {
    await this.messaging.publish(OpenGameEvents.FINISHED, {
      gameId: game.id,
      confirmedPlayers,
      scheduledAt: game.scheduledAt,
    });
  }

  async publishStatsRecorded(
    gameId: string,
    stats: { playerId: string; goals: number; assists: number }[],
  ): Promise<void> {
    await this.messaging.publish(OpenGameEvents.STATS_RECORDED, {
      gameId,
      stats,
    });
  }
}
```

## Consumindo Eventos (Message Consumer Service)

```typescript
// application/services/player-summary-message-consumer.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { SocialEvents } from '@shared/contracts/events/social-events.enum';
import {
  PlayerSummaryRepositoryInterface,
  PLAYER_SUMMARY_REPOSITORY,
} from '../../domain/repositories/player-summary-repository.interface';

@Injectable()
export class PlayerSummaryMessageConsumerService {
  constructor(
    @Inject(PLAYER_SUMMARY_REPOSITORY)
    private readonly playerSummaryRepository: PlayerSummaryRepositoryInterface,
  ) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.PROFILE_UPDATED,
    queue: 'open-game.identity.profile-updated', // fila única por serviço+evento
  })
  async handleProfileUpdated(payload: {
    userId: string;
    displayName: string;
    photoUrl: string;
    city: string;
    position: string;
  }): Promise<void> {
    await this.playerSummaryRepository.upsert({
      playerId: payload.userId,
      displayName: payload.displayName,
      photoUrl: payload.photoUrl,
      city: payload.city,
      position: payload.position,
    });
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: SocialEvents.PLAYER_SCORE_UPDATED,
    queue: 'open-game.social.player-score-updated',
  })
  async handlePlayerScoreUpdated(payload: {
    playerId: string;
    overallAvg: number;
    reviewCount: number;
  }): Promise<void> {
    await this.playerSummaryRepository.updateScore({
      playerId: payload.playerId,
      overallScore: payload.overallAvg,
      reviewCount: payload.reviewCount,
    });
  }
}
```

## Nomeação de Filas

Padrão: `{consumer-service}.{producer-service}.{event-name}`

```
open-game.identity.profile-updated
open-game.social.player-score-updated
gamification.open-game.stats-recorded
gamification.game.match-completed
ranking.game.match-completed
notification.open-game.finished
notification.game.match-completed
social.open-game.finished            ← abre janela de avaliação
matchmaking.team.created
matchmaking.team.player-joined
matchmaking.team.player-left
matchmaking.ranking.recalculated
```

## Dead-Letter Queue

Configurar em cada consumer para evitar loop infinito em caso de falha:

```typescript
@RabbitSubscribe({
  exchange: 'bolanarededb',
  routingKey: IdentityEvents.PROFILE_UPDATED,
  queue: 'open-game.identity.profile-updated',
  queueOptions: {
    durable: true,
    arguments: {
      'x-dead-letter-exchange': 'bolanarededb.dlq',
      'x-dead-letter-routing-key': 'dlq.open-game.identity.profile-updated',
    },
  },
})
```

## Idempotência

Todo consumer deve ser idempotente — a mesma mensagem pode chegar mais de uma vez. Usar `upsert` ao invés de `insert`, ou verificar se o registro já existe:

```typescript
// Correto: upsert é idempotente
await this.repo.upsert({ playerId, displayName });

// Errado: insert pode falhar com duplicata
await this.repo.create({ playerId, displayName });
```

## Onde Importar

```typescript
// Enums do shared
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { OpenGameEvents } from '@shared/contracts/events/open-game-events.enum';

// Serviço de messaging
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
```
