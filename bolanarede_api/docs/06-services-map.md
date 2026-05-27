# Mapa de Serviços BolaNaRede

Referência completa de todos os serviços, suas entidades e responsabilidades.

---

## identity (porta 4001 · banco: bolanarededb_identity)

**Responsabilidade:** Autenticação, usuários, perfil público do jogador, tokens de dispositivo.

### Módulos e Entidades

```
modules/identity/
├── identity.module.ts
├── users/
│   ├── domain/models/user.entity.ts
│   ├── domain/models/player-profile.entity.ts
│   ├── application/dto/create-user.dto.ts
│   ├── application/dto/update-profile.dto.ts
│   ├── application/dto/user.dto.ts
│   ├── application/services/user.service.ts
│   ├── application/services/user-messaging.service.ts
│   ├── infra/controllers/users.controller.ts
│   ├── infra/database/schemas/user.schema.ts
│   ├── infra/database/schemas/player-profile.schema.ts
│   └── infra/repositories/drizzle-user.repository.ts
├── auth/
│   ├── application/dto/login.dto.ts
│   ├── application/services/auth.service.ts
│   └── infra/controllers/auth.controller.ts
└── device-tokens/
    ├── application/services/device-token.service.ts
    ├── infra/database/schemas/device-token.schema.ts
    └── infra/repositories/drizzle-device-token.repository.ts
```

### Eventos Publicados

- `IdentityEvents.USER_REGISTERED` — `{ userId, email, createdAt }`
- `IdentityEvents.PROFILE_UPDATED` — `{ userId, displayName, photoUrl, city, position }`
- `IdentityEvents.DEVICE_TOKEN_UPDATED` — `{ userId, token, platform }`
- `IdentityEvents.ACCOUNT_ANONYMIZED` — `{ userId, anonymizedAt }`

### Rotas Principais

- `POST /v1/auth/login` — `@Public()`
- `POST /v1/auth/register` — `@Public()`
- `POST /v1/auth/refresh` — `@Public()`
- `GET /v1/users/me` — `@Permissions('players:read')`
- `PUT /v1/users/me/profile` — `@Permissions('players:write')`
- `GET /v1/users/:id/profile` — `@Public()`

---

## team (porta 4002 · banco: bolanarededb_team)

**Responsabilidade:** Times, membros, capitania.

### Entidades

- `Team` — time com captain e membros
- `TeamMember` — relação jogador↔time
- `TeamInvitation` — convites pendentes
- `CaptaincyTransfer` — histórico de transferências

### Eventos Publicados

- `TeamEvents.CREATED` — `{ teamId, name, city, captainId }`
- `TeamEvents.PLAYER_JOINED` — `{ teamId, userId, role }`
- `TeamEvents.PLAYER_LEFT` — `{ teamId, userId }`
- `TeamEvents.BECAME_INVALID` — `{ teamId, memberCount }`
- `TeamEvents.CAPTAINCY_TRANSFERRED` — `{ teamId, fromUserId, toUserId }`

### Rotas Principais

- `POST /v1/teams` — `@Permissions('teams:write')`
- `GET /v1/teams/:id` — `@Public()`
- `POST /v1/teams/:id/members` — `@Permissions('teams:write')`
- `DELETE /v1/teams/:id/members/:userId` — `@Permissions('teams:write')`
- `POST /v1/teams/:id/transfer-captaincy` — `@Permissions('teams:write')`

---

## field (porta 4003 · banco: bolanarededb_field)

**Responsabilidade:** Catálogo de campos, reservas de todos os canais, planos recorrentes, financeiro básico.

### Entidades

- `Field` — campo com localização (PostGIS)
- `FieldCourt` — quadras dentro do campo
- `PricingRule` — preços por horário/dia
- `AvailabilitySlot` — disponibilidade padrão
- `Reservation` — reserva (todos os canais: app, manual, telefone)
- `RecurringPlan` — plano semanal fixo
- `RecurringPlanSlot` — instância semanal do plano
- `FieldCustomer` — CRM básico

### Eventos Publicados

- `FieldEvents.REGISTERED` — `{ fieldId, name, city, location }`
- `FieldEvents.RESERVATION_CONFIRMED` — `{ reservationId, fieldId, date, channelRefId }`
- `FieldEvents.RESERVATION_CANCELLED` — `{ reservationId, fieldId }`
- `FieldEvents.PLAN_SLOT_RELEASED` — `{ planId, slotDate, fieldId }`

### Rotas Principais

- `POST /v1/fields` — `@Permissions('fields:write')`
- `GET /v1/fields?city=&lat=&lng=&radius=` — `@Public()`
- `GET /v1/fields/:id` — `@Public()`
- `GET /v1/fields/:id/availability?date=` — `@Public()`
- `POST /v1/fields/:id/reservations` — `@Permissions('fields:write')` (manual)
- `GET /v1/fields/:id/reservations` — `@Permissions('fields:write')`

---

## open-game (porta 4004 · banco: bolanarededb_open_game)

**Responsabilidade:** Peladas (jogos abertos), participações, registro de stats.

### Entidades

- `OpenGame` — pelada com snapshot do organizador e campo
- `GameParticipation` — jogador participando de uma pelada
- `GameStats` — gols e assistências registrados pós-jogo

### Projeções Locais (via eventos)

- `PlayerSummary` — nome, foto, score (de identity + social)

### Eventos Publicados

- `OpenGameEvents.CREATED`
- `OpenGameEvents.PLAYER_JOINED`
- `OpenGameEvents.PLAYER_LEFT`
- `OpenGameEvents.FULL`
- `OpenGameEvents.FINISHED`
- `OpenGameEvents.CANCELLED`
- `OpenGameEvents.STATS_RECORDED`

### Eventos Consumidos

- `IdentityEvents.PROFILE_UPDATED` → atualiza `player_summaries`
- `SocialEvents.PLAYER_SCORE_UPDATED` → atualiza `player_summaries`

### Rotas Principais

- `POST /v1/open-games` — `@Permissions('open-games:write')`
- `GET /v1/open-games?city=&date=` — `@Public()`
- `GET /v1/open-games/:id` — `@Public()`
- `POST /v1/open-games/:id/join` — `@Permissions('open-games:write')`
- `POST /v1/open-games/:id/leave` — `@Permissions('open-games:write')`
- `POST /v1/open-games/:id/participants/:playerId/approve` — `@Permissions('open-games:write')`
- `POST /v1/open-games/:id/checkin/:playerId` — `@Permissions('open-games:write')`
- `POST /v1/open-games/:id/finish` — `@Permissions('open-games:write')`
- `POST /v1/open-games/:id/stats` — `@Permissions('open-games:write')`

---

## social (porta 4005 · banco: bolanarededb_social)

**Responsabilidade:** Avaliações entre jogadores, score de reputação.

### Entidades

- `PlayerReview` — avaliação de um jogador por outro
- `ReviewWindow` — janela de 24h após jogo para avaliar
- `PlayerScore` — score calculado (read model)

### Eventos Publicados

- `SocialEvents.PLAYER_REVIEWED`
- `SocialEvents.PLAYER_SCORE_UPDATED`

### Eventos Consumidos

- `OpenGameEvents.FINISHED` → cria `review_window` com eligible_players

### Rotas Principais

- `POST /v1/reviews` — `@Permissions('reviews:write')`
- `GET /v1/players/:id/score` — `@Public()`

---

## gamification (porta 4006 · banco: bolanarededb_gamification)

**Responsabilidade:** Temporadas, stats individuais, ligas privadas, desafios/eventos, badges, streaks.

### Entidades

- `Season` — período trimestral de acúmulo de stats
- `PlayerSeasonStats` — stats do jogador na temporada
- `StatEventsInbox` — fila de processamento de eventos de stats (CQRS)
- `League` — liga privada entre amigos
- `LeagueMember` — membro de uma liga
- `LeagueSeason` — temporada de uma liga
- `Challenge` — desafio público/patrocinado
- `ChallengeParticipant` — participante de um desafio
- `BadgeDefinition` — catálogo de badges
- `PlayerBadge` — badge conquistado
- `PlayerStreak` — sequência de semanas jogando

### Projeções Locais

- `PlayerIdentity` — nome e foto (de identity)

### Eventos Consumidos

- `OpenGameEvents.STATS_RECORDED` → insere em `stat_events_inbox`
- `GameEvents.MATCH_COMPLETED` → insere em `stat_events_inbox`
- `IdentityEvents.PROFILE_UPDATED` → atualiza `player_identities`

### Rotas Principais

- `GET /v1/seasons/current` — `@Public()`
- `GET /v1/seasons/current/stats/me` — `@Permissions('seasons:read')`
- `GET /v1/seasons/:id/leaderboard?metric=goals` — `@Public()`
- `POST /v1/leagues` — `@Permissions('seasons:write')`
- `POST /v1/leagues/:id/join` — `@Permissions('seasons:write')`
- `GET /v1/leagues/:id/leaderboard` — `@Permissions('seasons:read')`
- `GET /v1/challenges` — `@Public()`
- `POST /v1/challenges/:id/join` — `@Permissions('seasons:write')`

---

## matchmaking (porta 4007 · banco: bolanarededb_matchmaking)

**Responsabilidade:** Solicitações de partida formal entre times, propostas, expiração.

### Entidades

- `MatchRequest` — time buscando adversário
- `MatchProposal` — proposta de adversário

### Projeções Locais

- `TeamSummary` — nome, cidade, rating (de team + ranking)

### Eventos Publicados

- `MatchmakingEvents.MATCH_REQUESTED`
- `MatchmakingEvents.MATCH_ACCEPTED`
- `MatchmakingEvents.MATCH_EXPIRED`

### Eventos Consumidos

- `TeamEvents.CREATED` → insere em `team_summaries`
- `TeamEvents.PLAYER_JOINED` → atualiza `team_summaries.player_count`
- `TeamEvents.PLAYER_LEFT` → atualiza `team_summaries.player_count`
- `TeamEvents.BECAME_INVALID` → atualiza `team_summaries.status`
- `RankingEvents.RECALCULATED` → atualiza `team_summaries.rating`

### Rotas Principais

- `POST /v1/match-requests` — `@Permissions('matches:write')`
- `GET /v1/match-requests?city=&date=` — `@Permissions('matches:read')`
- `POST /v1/match-requests/:id/proposals` — `@Permissions('matches:write')`
- `POST /v1/match-proposals/:id/accept` — `@Permissions('matches:write')`

---

## game (porta 4008 · banco: bolanarededb_game)

**Responsabilidade:** Execução de partidas formais, resultado, confirmação bilateral, disputa.

### Entidades

- `Match` — partida confirmada (com snapshots dos times e campo)
- `MatchResult` — placar registrado
- `ResultConfirmation` — confirmação por time
- `Dispute` — contestação de resultado

### Eventos Publicados

- `GameEvents.MATCH_COMPLETED`
- `GameEvents.RESULT_DISPUTED`

### Eventos Consumidos

- `MatchmakingEvents.MATCH_ACCEPTED` → cria `Match`

### Rotas Principais

- `GET /v1/matches/:id` — `@Permissions('matches:read')`
- `POST /v1/matches/:id/results` — `@Permissions('matches:write')`
- `POST /v1/matches/:id/results/confirm` — `@Permissions('matches:write')`
- `POST /v1/matches/:id/results/dispute` — `@Permissions('matches:write')`

---

## ranking (porta 4009 · banco: bolanarededb_ranking)

**Responsabilidade:** Standings de times baseado em W/E/D. CQRS com inbox de eventos.

### Entidades

- `TeamStanding` — posição do time na temporada
- `RankingEventInbox` — fila de processamento (CQRS inbox)

### Eventos Publicados

- `RankingEvents.RECALCULATED`

### Eventos Consumidos

- `GameEvents.MATCH_COMPLETED` → insere em `ranking_event_inbox` → processa → atualiza standings

### Rotas Principais

- `GET /v1/rankings/teams?city=&season=` — `@Public()`

---

## notification (porta 4010 · banco: MongoDB bolanarededb_notification)

**Responsabilidade:** Envio de push notifications via FCM.

### Estrutura diferente — usa MongoDB, não PostgreSQL

### Coleções MongoDB

- `notifications` — histórico de notificações (TTL 30 dias)
- `notification_preferences` — preferências por tipo

### Projeção Local (PostgreSQL)

- `user_tokens` — device tokens FCM (de identity)

### Eventos Consumidos

Consome eventos de todos os outros serviços para disparar notificações push.

---

## Fluxo de Dados Cross-Service

```
identity ──(ProfileUpdated)──────────────────────────────► open-game [player_summaries]
                                                         ► gamification [player_identities]
                                                         ► notification [atualiza display]

identity ──(DeviceTokenUpdated)──────────────────────────► notification [user_tokens]

team ──(TeamCreated/PlayerJoined/PlayerLeft)──────────────► matchmaking [team_summaries]

open-game ──(Finished)───────────────────────────────────► social [review_window]
open-game ──(StatsRecorded)──────────────────────────────► gamification [stat_events_inbox]

game ──(MatchCompleted)──────────────────────────────────► ranking [ranking_event_inbox]
                                                         ► gamification [stat_events_inbox]
                                                         ► notification

social ──(PlayerScoreUpdated)────────────────────────────► open-game [player_summaries]

ranking ──(Recalculated)─────────────────────────────────► matchmaking [team_summaries.rating]
```
