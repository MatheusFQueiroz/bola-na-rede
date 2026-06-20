# BolaNaRede API

Plataforma de futebol amador construída como monorepo de microserviços NestJS. Permite que jogadores se cadastrem, criem e entrem em peladas, formem times, realizem matchmaking automático, registrem resultados e acompanhem rankings e gamificação.

## Arquitetura

```
bolanarede_api/
├── shared/              # Módulo compartilhado (@shared/* path alias)
│   └── src/
│       ├── infra/auth/  # JWT Guard, PermissionsGuard, decorators
│       ├── infra/hateoas/  # Interceptor HATEOAS global
│       ├── infra/messaging/ # RabbitMQService base
│       └── contracts/events/ # Enums de eventos (routing keys)
├── services/
│   ├── identity/        # Autenticação e perfis (porta 4001)
│   ├── team/            # Gestão de times (porta 4002)
│   ├── field/           # Campos e reservas (porta 4003)
│   ├── open-game/       # Peladas abertas (porta 4004)
│   ├── social/          # Avaliações e scores (porta 4005)
│   ├── gamification/    # Badges, desafios, temporadas (porta 4006)
│   ├── matchmaking/     # Matchmaking automático (porta 4007)
│   ├── game/            # Partidas e resultados (porta 4008)
│   ├── ranking/         # Rankings por esporte (porta 4009)
│   └── notification/    # Notificações push (porta 4010)
├── nginx/               # Gateway reverso (porta 3000)
├── docker-compose.yml
└── tsconfig.base.json
```

## Pré-requisitos

- Docker + Docker Compose
- Node.js 22+ (apenas para desenvolvimento local)
- curl + jq (para o seed script)

## Rodando com Docker

```bash
# 1. Subir todos os serviços
docker compose up -d --build

# 2. Aguardar os healthchecks (~30s)
docker compose ps

# 3. Popular o banco com dados de teste
chmod +x seed.sh && ./seed.sh
```

## Gateway (ponto de entrada único)

Todos os serviços são acessíveis via gateway nginx na **porta 3000**:

```
http://localhost:3000/v1/auth        → identity (4001)
http://localhost:3000/v1/users       → identity (4001)
http://localhost:3000/v1/teams       → team (4002)
http://localhost:3000/v1/fields      → field (4003)
http://localhost:3000/v1/open-games  → open-game (4004)
http://localhost:3000/v1/reviews     → social (4005)
http://localhost:3000/v1/scores      → social (4005)
http://localhost:3000/v1/profiles    → gamification (4006)
http://localhost:3000/v1/leaderboard → gamification (4006)
http://localhost:3000/v1/seasons     → gamification (4006)
http://localhost:3000/v1/challenges  → gamification (4006)
http://localhost:3000/v1/leagues     → gamification (4006)
http://localhost:3000/v1/match-requests → matchmaking (4007)
http://localhost:3000/v1/matches     → matchmaking (4007)
http://localhost:3000/v1/games       → game (4008)
http://localhost:3000/v1/rankings    → ranking (4009)
http://localhost:3000/v1/notifications → notification (4010)
```

## Serviços

| Serviço       | Porta | Banco                    | Extras         | Status     |
|---------------|-------|--------------------------|----------------|------------|
| identity      | 4001  | PostgreSQL (identity)    | —              | ✅ Completo |
| team          | 4002  | PostgreSQL (team)        | —              | ✅ Completo |
| field         | 4003  | PostgreSQL (field) + PostGIS | —          | ✅ Completo |
| open-game     | 4004  | PostgreSQL (open_game)   | Redis          | ✅ Completo |
| social        | 4005  | PostgreSQL (social)      | —              | ✅ Completo |
| gamification  | 4006  | PostgreSQL (gamification)| —              | ✅ Completo |
| matchmaking   | 4007  | PostgreSQL (matchmaking) | Redis          | ✅ Completo |
| game          | 4008  | PostgreSQL (game)        | —              | ✅ Completo |
| ranking       | 4009  | PostgreSQL (ranking)     | —              | ✅ Completo |
| notification  | 4010  | MongoDB                  | Redis          | ✅ Completo |

## Documentação Swagger

Cada serviço expõe Swagger na rota `/docs`:

| Serviço       | URL                             |
|---------------|---------------------------------|
| identity      | http://localhost:4001/docs      |
| team          | http://localhost:4002/docs      |
| field         | http://localhost:4003/docs      |
| open-game     | http://localhost:4004/docs      |
| social        | http://localhost:4005/docs      |
| gamification  | http://localhost:4006/docs      |
| matchmaking   | http://localhost:4007/docs      |
| game          | http://localhost:4008/docs      |
| ranking       | http://localhost:4009/docs      |
| notification  | http://localhost:4010/docs      |

## Comunicação entre Serviços (RabbitMQ)

Exchange único: `bolanarededb` (topic). Todos os eventos usam idempotência via upsert.

| Evento (routing key)             | Publicador    | Consumidores                          |
|----------------------------------|---------------|---------------------------------------|
| `identity.user-registered`       | identity      | gamification, notification            |
| `identity.profile-updated`       | identity      | team, open-game, game, gamification   |
| `identity.device-token-updated`  | identity      | notification                          |
| `identity.account-anonymized`    | identity      | team, social, gamification            |
| `team.created`                   | team          | gamification                          |
| `team.player-joined`             | team          | gamification                          |
| `team.player-left`               | team          | gamification                          |
| `team.became-invalid`            | team          | —                                     |
| `team.captaincy-transferred`     | team          | —                                     |
| `open-game.created`              | open-game     | notification                          |
| `open-game.player-joined`        | open-game     | notification                          |
| `open-game.finished`             | open-game     | gamification, ranking, notification   |
| `open-game.stats-recorded`       | open-game     | gamification                          |
| `open-game.cancelled`            | open-game     | notification                          |
| `matchmaking.match-requested`    | matchmaking   | game, notification                    |
| `matchmaking.match-accepted`     | matchmaking   | game, notification                    |
| `matchmaking.match-expired`      | matchmaking   | notification                          |
| `game.match-completed`           | game          | social, gamification, ranking, notification |
| `game.result-disputed`           | game          | notification                          |
| `social.player-reviewed`         | social        | gamification                          |
| `social.player-score-updated`    | social        | gamification, ranking                 |
| `gamification.badge-awarded`     | gamification  | notification                          |
| `gamification.challenge-ended`   | gamification  | notification                          |
| `gamification.season-ended`      | gamification  | ranking, notification                 |

## Variáveis de Ambiente

Cada serviço possui um `.env.example`. Valores padrão para desenvolvimento local:

```env
PORT=400N
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_{service}
RABBITMQ_URL=amqp://admin:admin@localhost:5672
REDIS_URL=redis://localhost:6379          # apenas open-game e matchmaking
MONGODB_URI=mongodb://localhost:27017/bolanarededb_notification  # apenas notification
```

## Infra de Suporte (Docker Compose)

| Serviço             | Porta  | Credenciais        |
|---------------------|--------|--------------------|
| PostgreSQL (shared) | 5432   | postgres/postgres  |
| MongoDB             | 27017  | sem auth           |
| Redis               | 6379   | sem auth           |
| RabbitMQ            | 5672   | admin/admin        |
| RabbitMQ Management | 15672  | admin/admin        |
| nginx (gateway)     | 3000   | —                  |

## Fluxo de Teste

```bash
# 1. Registrar usuário
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Teste","email":"teste@test.com","password":"senha123"}'

# 2. Login
TOKEN=$(curl -s -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@test.com","password":"senha123"}' | jq -r '.accessToken')

# 3. Ver perfil
curl http://localhost:3000/v1/users/me -H "Authorization: Bearer $TOKEN"

# 4. Criar time
curl -X POST http://localhost:3000/v1/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Meu Time","minPlayers":5,"maxPlayers":14}'

# 5. Criar pelada
curl -X POST http://localhost:3000/v1/open-games \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Pelada de Terça","sport":"futsal","scheduledAt":"2026-07-01T19:00:00Z","durationMinutes":90,"minPlayers":10,"maxPlayers":18}'

# 6. Ver ranking
curl "http://localhost:3000/v1/rankings?sport=futsal"

# 7. Buscar campos
curl "http://localhost:3000/v1/fields?city=Curitiba"
```

## Padrões de API

### Autenticação
Todas as rotas protegidas requerem `Authorization: Bearer <token>` no header.

### HATEOAS
Todas as respostas de item incluem `_links` com navegação hipermídia:
```json
{
  "data": { "id": "uuid", "name": "Furacão FC", ... },
  "_links": {
    "self":    { "href": "/v1/teams/uuid", "method": "GET" },
    "update":  { "href": "/v1/teams/uuid", "method": "PUT" },
    "delete":  { "href": "/v1/teams/uuid", "method": "DELETE" },
    "members": { "href": "/v1/teams/uuid/members", "method": "GET" }
  }
}
```

Respostas de lista incluem `_links` por item e links de coleção:
```json
{
  "data": [
    { "id": "uuid", ..., "_links": { "self": { ... } } }
  ],
  "_links": {
    "self":   { "href": "/v1/teams", "method": "GET" },
    "create": { "href": "/v1/teams", "method": "POST" }
  }
}
```

### IDs Públicos
Todos os recursos expõem UUIDs como identificadores públicos. PKs internas (BIGSERIAL) nunca são expostas.

### Timestamps
Todos os timestamps são `timestamptz` (UTC com timezone).

## Desenvolvimento Local (sem Docker)

```bash
# Dependências (na raiz do monorepo)
npm install

# Variáveis de ambiente
cd services/identity
cp .env.example .env

# Migrations
npm run db:generate
npm run db:migrate

# Rodar em modo desenvolvimento
npm run start:dev
```

## Stack Técnica

- **Runtime**: Node.js 22, TypeScript 5
- **Framework**: NestJS 11
- **ORM**: Drizzle ORM
- **Mensageria**: RabbitMQ + @golevelup/nestjs-rabbitmq
- **Cache/Queue**: Redis (ioredis)
- **Banco relacional**: PostgreSQL 16 (+ PostGIS para field)
- **Banco documental**: MongoDB 7 (notification)
- **Gateway**: nginx
- **Lint/Format**: Biome
- **Containerização**: Docker + Docker Compose
