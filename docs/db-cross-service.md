# BolaNaRede — Arquitetura: Dependências Cross-Service

**Versão:** 1.0  
**Contexto:** Decisão arquitetural crítica para o modelo de microserviços  
**Stack:** NestJS · PostgreSQL · RabbitMQ · Redis

---

## 1. O Problema Real

Você levantou a questão correta. Em microserviços, **armazenar apenas o UUID de outra entidade é insuficiente** para dois cenários:

**Cenário A — Disponibilidade:**
O `open-game-service` exibe uma pelada. Precisa do nome do campo, endereço e foto. Se o `field-service` estiver fora do ar, a pelada some da tela do usuário — mesmo que ela exista perfeitamente no banco do `open-game-service`.

**Cenário B — Performance:**
Renderizar o feed de peladas exige dados de 3–4 serviços por card. Com 50 peladas no feed, seriam 150–200 chamadas HTTP em paralelo a cada request. Inviável em produção.

A solução **não é** voltar ao banco compartilhado. É usar os padrões corretos de propagação de dados entre serviços.

---

## 2. Classificação das Dependências

Nem toda dependência cross-service é igual. Antes de escolher o padrão, classifique:

| Tipo                     | Característica                                                  | Exemplos no BolaNaRede                                        |
| ------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------- |
| **Transacional**         | Consistência imediata obrigatória                               | Verificar auth, debitar pagamento                             |
| **Imutável na criação**  | Dado que não muda após o evento                                 | Endereço do campo numa reserva, nome do time numa partida     |
| **Exibição eventual**    | Muda raramente, tolerável ficar desatualizado por minutos/horas | Nome do jogador no card da pelada, rating do time             |
| **Agregação de leitura** | Dados de múltiplas fontes para montar uma tela                  | Perfil completo do jogador (identity + social + gamification) |

---

## 3. Os Quatro Padrões (Abordagem Híbrida)

### Padrão 1: Chamada Síncrona com Circuit Breaker

**Para:** dados transacionais onde consistência imediata é obrigatória.

```typescript
// Apenas para operações críticas — não para exibição
@Injectable()
export class AuthGuard {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Chamada sync ao identity-service
    // Com timeout de 500ms e circuit breaker
    const user = await this.identityClient.verifyToken(token);
    return !!user;
  }
}
```

**Circuit breaker com NestJS + RxJS:**

```typescript
import { CircuitBreaker } from "@nestjs/axios"; // ou implementar manualmente

// Se 3 falhas em 10s → abre o circuito por 30s
// Retorna fallback ou lança erro controlado
```

**Use para:** verificação de token, processamento de pagamento, cancelamento com estorno.  
**Não use para:** exibição de dados em feeds, cards, listas.

---

### Padrão 2: Snapshot na Criação

**Para:** dados imutáveis — o estado no momento do evento é o que importa.

Quando uma `open_game` é criada, o endereço do campo é snapshottado. Se o campo mudar de nome amanhã, a pelada de ontem ainda exibe o nome correto.

```typescript
// open-game-service: ao criar uma pelada
async createOpenGame(dto: CreateOpenGameDto): Promise<OpenGame> {
  // Busca snapshot do campo UMA VEZ, no momento da criação
  const fieldSnapshot = await this.fieldClient.getFieldSnapshot(dto.fieldId);

  return this.openGameRepo.create({
    ...dto,
    field_id: dto.fieldId,
    // Snapshot imutável — não atualizado por eventos
    field_snapshot: {
      name: fieldSnapshot.name,
      address: fieldSnapshot.address,
      lat: fieldSnapshot.lat,
      lng: fieldSnapshot.lng,
      photo_url: fieldSnapshot.coverPhotoUrl,
    },
    organizer_snapshot: {
      user_id: dto.organizerId,
      name: dto.organizerName,    // vem do JWT
      photo_url: dto.organizerPhoto,
    },
  });
}
```

**Onde aplicar no BolaNaRede:**

| Dado snapshotado                     | Onde                                    | Origem                 |
| ------------------------------------ | --------------------------------------- | ---------------------- |
| `field_snapshot`                     | `open_games`, `matches`, `reservations` | field-service          |
| `organizer_snapshot`                 | `open_games`                            | identity-service (JWT) |
| `team_a_snapshot`, `team_b_snapshot` | `matches`                               | team-service           |
| `field_snapshot`                     | `match_results` (para o histórico)      | field-service          |

---

### Padrão 3: Projeção Local via Eventos (Read Replica)

**Para:** dados que mudam às vezes e são exibidos com frequência em listas/feeds.

Cada serviço mantém uma tabela local que é uma "visão" atualizada de dados de outro serviço. Atualizada via RabbitMQ, não por chamada direta.

```
[team-service] ──publica──► TeamCreated, PlayerJoined, PlayerLeft
                                        │
                           [RabbitMQ Exchange: team.events]
                                        │
                     ┌──────────────────┼──────────────────┐
                     ▼                  ▼                   ▼
          [matchmaking-service]  [gamification-service]  [open-game-service]
          team_summaries         player_identities       player_summaries
          (local replica)        (local replica)         (local replica)
```

**Implementação no NestJS (consumer):**

```typescript
// matchmaking-service: consumer de eventos do team-service
@EventPattern('team.player_joined')
async handlePlayerJoined(data: PlayerJoinedEvent): Promise<void> {
  await this.teamSummaryRepo.increment(
    { team_id: data.teamId },
    'player_count',
    1,
  );
}

@EventPattern('team.created')
async handleTeamCreated(data: TeamCreatedEvent): Promise<void> {
  await this.teamSummaryRepo.upsert({
    id: data.teamId,
    name: data.name,
    city: data.city,
    rating: 1000, // inicial
    player_count: 1,
    status: 'ACTIVE',
    synced_at: new Date(),
  }, ['id']);
}
```

**Projeções locais por serviço:**

| Serviço                | Tabela local        | Sincroniza de                     | Via eventos                                         |
| ---------------------- | ------------------- | --------------------------------- | --------------------------------------------------- |
| `matchmaking-service`  | `team_summaries`    | team-service + ranking-service    | TeamCreated, PlayerJoined/Left, RankingRecalculated |
| `open-game-service`    | `player_summaries`  | identity-service + social-service | UserRegistered, PlayerScoreUpdated, ProfileUpdated  |
| `gamification-service` | `player_identities` | identity-service                  | UserRegistered, ProfileUpdated, AccountAnonymized   |
| `notification-service` | `user_tokens`       | identity-service                  | DeviceTokenUpdated, UserDeleted                     |

---

### Padrão 4: Agregação no BFF (para telas complexas)

**Para:** telas que precisam de dados de 3+ serviços e a latência é aceitável (navegação, não scroll infinito).

O BFF (bff-mobile) agrega dados de múltiplos serviços para montar respostas ricas. Cache no Redis para queries frequentes.

```typescript
// bff-mobile: endpoint de perfil completo do jogador
@Get('/players/:id/profile')
async getPlayerProfile(@Param('id') playerId: string) {
  const cacheKey = `player:profile:${playerId}`;
  const cached = await this.redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // Paralelo — cada serviço retorna sua parte
  const [identity, score, stats, badges] = await Promise.all([
    this.identityClient.getPlayerProfile(playerId),     // identity-service
    this.socialClient.getPlayerScore(playerId),          // social-service
    this.gamificationClient.getCurrentSeasonStats(playerId), // gamification-service
    this.gamificationClient.getPlayerBadges(playerId),   // gamification-service
  ]);

  const profile = { ...identity, score, stats, badges };

  // Cache por 5 minutos — score não precisa ser real-time
  await this.redis.setex(cacheKey, 300, JSON.stringify(profile));

  return profile;
}
```

**Quando usar BFF vs Projeção local:**

| Cenário                           | Usar BFF                 | Usar Projeção Local            |
| --------------------------------- | ------------------------ | ------------------------------ |
| Feed de peladas (scroll infinito) | ❌ lento                 | ✅ dados locais                |
| Perfil completo do jogador        | ✅ OK — uma tela por vez | ❌ muitos campos para replicar |
| Card de time no matchmaking       | ❌ — chamado em listas   | ✅ team_summaries              |
| Detalhes de uma partida           | ✅ OK — não é lista      | —                              |

---

## 4. Mapa de Dependências Cross-Service

Aqui está o mapa completo de cada dependência, com o padrão recomendado:

### open-game-service

| Dado necessário                       | Origem            | Padrão             | Tabela/Campo local                      |
| ------------------------------------- | ----------------- | ------------------ | --------------------------------------- |
| Nome + endereço + GPS do campo        | field-service     | **Snapshot**       | `open_games.field_snapshot` (jsonb)     |
| Nome + foto do organizador            | identity-service  | **Snapshot**       | `open_games.organizer_snapshot` (jsonb) |
| Nome + foto + score dos participantes | identity + social | **Projeção local** | `player_summaries`                      |
| Token de auth do usuário              | identity-service  | **Sync** (guard)   | —                                       |

### matchmaking-service

| Dado necessário                       | Origem                 | Padrão             | Tabela/Campo local |
| ------------------------------------- | ---------------------- | ------------------ | ------------------ |
| Nome, cidade, rating, membros do time | team-service + ranking | **Projeção local** | `team_summaries`   |
| Token de auth                         | identity-service       | **Sync** (guard)   | —                  |

### game-service

| Dado necessário           | Origem        | Padrão       | Tabela/Campo local                                           |
| ------------------------- | ------------- | ------------ | ------------------------------------------------------------ |
| Nome dos times na partida | team-service  | **Snapshot** | `matches.team_a_snapshot`, `matches.team_b_snapshot` (jsonb) |
| Endereço do campo         | field-service | **Snapshot** | `matches.field_snapshot` (jsonb)                             |

### gamification-service

| Dado necessário                                     | Origem            | Padrão                       | Tabela/Campo local       |
| --------------------------------------------------- | ----------------- | ---------------------------- | ------------------------ |
| Nome + foto do jogador (para exibição nos rankings) | identity-service  | **Projeção local**           | `player_identities`      |
| Stats de partidas                                   | game-service      | **Eventos** → processa inbox | `ranking_events` inbox   |
| Stats de peladas                                    | open-game-service | **Eventos** → processa inbox | `game_stat_events` inbox |

### notification-service

| Dado necessário               | Origem           | Padrão             | Tabela/Campo local |
| ----------------------------- | ---------------- | ------------------ | ------------------ |
| Device token (FCM) do usuário | identity-service | **Projeção local** | `user_tokens`      |

### field-service (reservations)

| Dado necessário                        | Origem         | Padrão       | Tabela/Campo local                     |
| -------------------------------------- | -------------- | ------------ | -------------------------------------- |
| Nome + foto do time/grupo que reservou | team/open-game | **Snapshot** | `reservations.booker_snapshot` (jsonb) |

---

## 5. Resiliência: O que Acontece se um Serviço Cair?

Com o padrão híbrido:

| Serviço fora do ar     | Impacto com padrão híbrido                                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `identity-service`     | Auth falha (normal). Feeds continuam (dados locais). Novos logins impossíveis.                                              |
| `field-service`        | Novas reservas falham. Peladas existentes ainda exibem (snapshot).                                                          |
| `social-service`       | Scores ficam desatualizados mas exibem o último valor (projeção).                                                           |
| `team-service`         | Matchmaking exibe dados do `team_summaries` (pode ficar stale).                                                             |
| `gamification-service` | Rankings não atualizam. Stats existentes preservados.                                                                       |
| `rabbitmq`             | **Ponto crítico** → serviços ficam dessincronizados. Mitigação: RabbitMQ em cluster, dead-letter queues, retry com backoff. |

---

## 6. Implementação RabbitMQ no NestJS

### Estrutura de Exchanges e Queues

```
Exchanges (topic):
  identity.events       → UserRegistered, UserDeleted, ProfileUpdated, DeviceTokenUpdated
  team.events           → TeamCreated, PlayerJoined, PlayerLeft, TeamBecameInvalid
  field.events          → FieldRegistered, AvailabilityUpdated, ReservationConfirmed
  open-game.events      → OpenGameCreated, PlayerJoinedGame, OpenGameFinished, OpenGameCancelled
  game.events           → MatchCompleted, ResultConfirmed, ResultDisputed
  ranking.events        → RankingRecalculated, TeamBecameInactive
  social.events         → PlayerScoreUpdated
  gamification.events   → SeasonEnded, BadgeAwarded

Dead-Letter Exchange: dlx.bolanarededb
Retry Queue: retry.{service} (com TTL de 30s → reencaminha ao exchange original)
```

### Configuração NestJS (microservice consumer)

```typescript
// main.ts de qualquer serviço consumer
app.connectMicroservice<MicroserviceOptions>({
  transport: Transport.RMQ,
  options: {
    urls: [process.env.RABBITMQ_URL],
    queue: "matchmaking-service",
    queueOptions: {
      durable: true,
      arguments: {
        "x-dead-letter-exchange": "dlx.bolanarededb",
        "x-dead-letter-routing-key": "dead.matchmaking-service",
      },
    },
    prefetchCount: 10, // processa 10 msgs por vez
    noAck: false, // confirmação manual (at-least-once)
  },
});
```

### Idempotência (obrigatória)

```typescript
// Todo consumer deve ser idempotente — a mesma mensagem pode chegar 2x
@EventPattern('team.player_joined')
async handlePlayerJoined(data: PlayerJoinedEvent): Promise<void> {
  // UPSERT, não INSERT → seguro para duplicatas
  await this.teamSummaryRepo.upsert(
    { team_id: data.teamId, player_count: data.newCount, synced_at: new Date() },
    { conflictPaths: ['team_id'] }
  );
}
```

---

## 7. Decisão Final: O que Fazer no BolaNaRede

```
RESUMO DAS REGRAS:

1. Jamais faça chamadas síncronas para EXIBIR dados em listas ou feeds
   → Use projeção local ou snapshot

2. Snapshots para dados de momento (endereço da reserva, nome do time na partida)
   → Campo jsonb na tabela principal do evento

3. Projeções locais para display data que muda raramente
   → Tabela _summaries ou _snapshots, atualizada por consumers RabbitMQ

4. BFF agrega dados para telas complexas únicas (perfil, detalhes)
   → Com cache Redis de 5–15 minutos

5. Sync only para auth, pagamento e operações críticas
   → Com circuit breaker e timeout agressivo (< 1s)

6. RabbitMQ é o elo fraco — invista em HA e dead-letter queues cedo
```
