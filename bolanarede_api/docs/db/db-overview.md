# BolaNaRede — Database Design Overview v2

**Atualizado para:** doc-product v4.0 + doc-business v4.0  
**Inclui:** Modo Pelada, Gamificação, Sistema de Gestão de Campo (SaaS), Social

---

## Service → Database Map

| Service                | Technology           | File                                   |
| ---------------------- | -------------------- | -------------------------------------- |
| `identity-service`     | PostgreSQL isolated  | `db-identity-service.md`               |
| `team-service`         | PostgreSQL           | `db-team-service.md`                   |
| `field-service`        | PostgreSQL + PostGIS | `db-field-service.md`                  |
| `matchmaking-service`  | PostgreSQL + Redis   | `db-matchmaking-service.md`            |
| `game-service`         | PostgreSQL           | `db-game-service.md`                   |
| `ranking-service`      | PostgreSQL           | `db-ranking-service.md`                |
| `open-game-service`    | PostgreSQL + Redis   | `db-open-game-service.md` ← **NEW**    |
| `social-service`       | PostgreSQL           | `db-social-service.md` ← **NEW**       |
| `gamification-service` | PostgreSQL           | `db-gamification-service.md` ← **NEW** |
| `notification-service` | MongoDB + Redis      | `db-notification-service.md`           |

---

## Cross-Service Reference Pattern

Ver `doc-arq-cross-service.md` para o guia completo. Resumo:

| Padrão                     | Quando usar                               | Exemplos                                                      |
| -------------------------- | ----------------------------------------- | ------------------------------------------------------------- |
| **Snapshot (jsonb)**       | Dado imutável no momento do evento        | `field_snapshot` em reservas, `organizer_snapshot` em peladas |
| **Projeção local**         | Display data, atualizada via eventos      | `player_summaries`, `team_summaries`, `player_identities`     |
| **BFF aggregation**        | Telas complexas únicas (perfil, detalhes) | Perfil completo do jogador                                    |
| **Sync + circuit breaker** | Operações críticas e transacionais        | Auth, pagamento                                               |

---

## Cross-Service IDs (ACL Pattern)

Todos os serviços referenciam entidades externas via **UUID externo** — nunca o `bigint` PK interno.

```
identity-service  → users.external_id          (UUID)
team-service      → teams.external_id           (UUID)
field-service     → fields.external_id          (UUID)
                  → reservations.external_id     (UUID)
                  → recurring_plans.external_id  (UUID)
matchmaking-service → match_requests.external_id (UUID)
                    → match_proposals.external_id (UUID)
game-service      → matches.external_id          (UUID)
open-game-service → open_games.external_id       (UUID)
gamification-service → seasons.external_id       (UUID)
                     → leagues.external_id        (UUID)
                     → challenges.external_id     (UUID)
```

---

## Projeções Locais por Serviço

| Tabela              | No serviço           | Origem                            | Sincroniza via                                            |
| ------------------- | -------------------- | --------------------------------- | --------------------------------------------------------- |
| `team_summaries`    | matchmaking-service  | team-service + ranking-service    | `TeamCreated`, `PlayerJoined/Left`, `RankingRecalculated` |
| `player_summaries`  | open-game-service    | identity-service + social-service | `ProfileUpdated`, `PlayerScoreUpdated`                    |
| `player_identities` | gamification-service | identity-service                  | `ProfileUpdated`, `AccountAnonymized`                     |
| `user_tokens`       | notification-service | identity-service                  | `DeviceTokenUpdated`, `UserDeleted`                       |

---

## Snapshots por Serviço

| Campo jsonb                          | Na tabela                               | Snapshota de                |
| ------------------------------------ | --------------------------------------- | --------------------------- |
| `field_snapshot`                     | `open_games`, `matches`, `reservations` | field-service               |
| `organizer_snapshot`                 | `open_games`                            | identity (via JWT)          |
| `team_a_snapshot`, `team_b_snapshot` | `matches`                               | team-service                |
| `booker_snapshot`                    | `reservations`                          | identity / team / open-game |

---

## Fluxo de Eventos (RabbitMQ)

```
identity.events:
  UserRegistered → notification-service, gamification-service
  ProfileUpdated → open-game-service, gamification-service, notification-service
  DeviceTokenUpdated → notification-service
  AccountAnonymized → TODOS os serviços

team.events:
  TeamCreated → matchmaking-service
  PlayerJoined/Left → matchmaking-service
  TeamBecameInvalid → matchmaking-service

field.events:
  ReservationConfirmed → open-game-service, game-service
  PlanSlotReleased → open-game-service (libera slot no feed)

open-game.events:
  OpenGameFinished → social-service (abre review window), gamification-service, notification-service
  OpenGameCancelled → field-service, notification-service
  GameStatsRecorded → gamification-service

game.events:
  MatchCompleted → ranking-service, gamification-service, notification-service
  ResultDisputed → notification-service

ranking.events:
  RankingRecalculated → matchmaking-service (atualiza rating em team_summaries)

social.events:
  PlayerScoreUpdated → open-game-service (atualiza player_summaries), notification-service

gamification.events:
  SeasonEnded → notification-service
  BadgeAwarded → notification-service
  ChallengeEnded → notification-service
```

---

## PostgreSQL Conventions (todos os serviços)

- **IDs internos:** `BIGSERIAL` — nunca expostos fora do serviço
- **IDs externos:** `UUID DEFAULT gen_random_uuid()` com `UNIQUE` constraint
- **Timestamps:** sempre `TIMESTAMPTZ` (nunca `TIMESTAMP`)
- **Strings:** sempre `TEXT` (nunca `VARCHAR(n)`)
- **Dinheiro/preços:** `NUMERIC(8,2)` (nunca `FLOAT`)
- **Flags:** `BOOLEAN` (nunca `int` ou `varchar`)
- **Soft deletes:** `deleted_at TIMESTAMPTZ` + partial index `WHERE deleted_at IS NULL`
- **Colunas geradas:** `GENERATED ALWAYS AS (...) STORED` para cálculos derivados
- **Índices em FK:** toda FK deve ter índice correspondente

---

## Saga: Match Lifecycle Completo (atualizado)

```
[Pelada]
OpenGameCreated
  → PlayerJoinedGame (×N)
  → OpenGameFull (vagas esgotadas) OR vira PRÉ-RESERVADO no campo
  → OpenGameFinished
    → social-service: review_window aberta
    → gamification-service: stat_events_inbox ← GameStatsRecorded
    → field-service: reservation → COMPLETED
    → notification-service: "avalie os jogadores"

[Partida Formal]
MatchRequested
  → MatchAccepted
    → game-service: Match criado
      → field-service: reservation CONFIRMED
    → ResultRegistered
      → ResultConfirmed / ResultDisputed
        → MatchCompleted
          → ranking-service: standings atualizados
          → gamification-service: stat_events_inbox ← MATCH_COMPLETED
          → notification-service: "resultado confirmado"
```
