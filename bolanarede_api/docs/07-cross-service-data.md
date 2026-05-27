# Dados Cross-Service

Como lidar com dados de outros serviços. Regra principal: **nunca chamar outro serviço HTTP para exibir dados em listas ou feeds**.

## Os Quatro Padrões

### 1. Snapshot (dados imutáveis no momento do evento)

Quando um registro é criado e precisa de dados de outro serviço, salve o estado naquele momento em um campo `jsonb`. O dado fica congelado — se o campo mudar de nome amanhã, a pelada de ontem ainda exibe o nome correto.

**Onde usar:** campo em reserva, organizador em pelada, times em partida.

```typescript
// Ao criar uma pelada, snapshot do campo (chamada única ao field-service)
async create(dto: CreateOpenGameDto, user: AuthenticatedUser): Promise<OpenGameDto> {
  let fieldSnapshot = {};
  if (dto.fieldId) {
    // Única chamada HTTP permitida — na criação, não na leitura
    const field = await this.fieldClient.getFieldSnapshot(dto.fieldId);
    fieldSnapshot = {
      fieldId: field.id,
      name: field.name,
      address: field.address,
      lat: field.lat,
      lng: field.lng,
      photoUrl: field.coverPhotoUrl,
    };
  }

  return this.openGameRepository.create({
    organizerId: user.id,
    organizerSnapshot: { id: user.id, name: user.name, photoUrl: user.photoUrl },
    fieldId: dto.fieldId ?? null,
    fieldSnapshot,
    // ...
  });
}
```

**Schema Drizzle para snapshot:**

```typescript
organizerSnapshot: jsonb('organizer_snapshot').notNull().default({}),
fieldSnapshot:     jsonb('field_snapshot').notNull().default({}),
teamASnapshot:     jsonb('team_a_snapshot').notNull().default({}),
```

**Snapshots obrigatórios por serviço:**

| Tabela         | Snapshot             | Dados                            |
| -------------- | -------------------- | -------------------------------- |
| `open_games`   | `organizer_snapshot` | id, name, photoUrl               |
| `open_games`   | `field_snapshot`     | fieldId, name, address, lat, lng |
| `matches`      | `team_a_snapshot`    | teamId, name, city               |
| `matches`      | `team_b_snapshot`    | teamId, name, city               |
| `matches`      | `field_snapshot`     | fieldId, name, address           |
| `reservations` | `booker_snapshot`    | name, type, contactPhone         |

---

### 2. Projeção Local (display data atualizada por eventos)

Tabela local que espelha dados de outro serviço. Atualizada via consumer RabbitMQ. Usada para queries frequentes em feeds e listas.

**Quando usar:** nome/foto de jogador em card de pelada, rating de time no matchmaking.

```typescript
// Schema da projeção local no open-game-service
export const playerSummaries = pgTable('player_summaries', {
  playerId: text('player_id').primaryKey(), // = users.external_id
  displayName: text('display_name').notNull(),
  photoUrl: text('photo_url'),
  city: text('city'),
  position: text('position'),
  overallScore: numeric('overall_score', { precision: 3, scale: 1 })
    .notNull()
    .default('0.0'),
  reviewCount: integer('review_count').notNull().default(0),
  syncedAt: timestamp('synced_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});
```

```typescript
// Consumer que mantém a projeção atualizada
@RabbitSubscribe({
  exchange: 'bolanarededb',
  routingKey: IdentityEvents.PROFILE_UPDATED,
  queue: 'open-game.identity.profile-updated',
})
async handleProfileUpdated(payload: { userId: string; displayName: string; photoUrl: string }): Promise<void> {
  // upsert — idempotente
  await this.drizzle.db
    .insert(playerSummaries)
    .values({ playerId: payload.userId, displayName: payload.displayName, photoUrl: payload.photoUrl })
    .onConflictDoUpdate({
      target: playerSummaries.playerId,
      set: { displayName: payload.displayName, photoUrl: payload.photoUrl, syncedAt: new Date() },
    });
}
```

**Projeções locais existentes:**

| Tabela              | No serviço   | Origem            | Evento que atualiza                                       |
| ------------------- | ------------ | ----------------- | --------------------------------------------------------- |
| `player_summaries`  | open-game    | identity + social | `ProfileUpdated`, `PlayerScoreUpdated`                    |
| `team_summaries`    | matchmaking  | team + ranking    | `TeamCreated`, `PlayerJoined/Left`, `RankingRecalculated` |
| `player_identities` | gamification | identity          | `ProfileUpdated`                                          |
| `user_tokens`       | notification | identity          | `DeviceTokenUpdated`                                      |

---

### 3. BFF Aggregation (telas complexas, uma por vez)

Para telas que precisam de dados de 3+ serviços e são acessadas individualmente (não em lista). O BFF chama múltiplos serviços em paralelo e combina as respostas.

**Quando usar:** perfil completo de jogador, detalhes de uma partida.

```typescript
// No bff-mobile ou gateway
@Get('/players/:id/profile')
async getPlayerProfile(@Param('id') playerId: string) {
  const [identity, score, stats] = await Promise.all([
    this.identityService.getProfile(playerId),
    this.socialService.getScore(playerId),
    this.gamificationService.getCurrentSeasonStats(playerId),
  ]);

  return { ...identity, score, stats };
}
```

---

### 4. Chamada Síncrona (somente operações críticas)

Apenas para autenticação (JWT guard) e operações onde consistência imediata é obrigatória. Nunca para buscar dados de exibição.

---

## Regra de Decisão

```
Estou buscando dados para exibir em uma LISTA ou FEED?
  → Usar projeção local ou snapshot

Estou criando um registro que referencia dados de outro serviço?
  → Usar snapshot (salvar o estado no momento da criação)

Estou montando uma TELA ÚNICA e complexa (perfil, detalhes)?
  → Usar BFF com Promise.all()

Estou verificando autenticação ou processando pagamento?
  → Chamada síncrona com timeout e error handling
```

## O Que NUNCA Fazer

```typescript
// ❌ ERRADO: chamada HTTP para popular uma lista
async findAll(): Promise<OpenGameDto[]> {
  const games = await this.openGameRepository.findAll();
  return Promise.all(games.map(async (game) => {
    const field = await this.fieldService.getField(game.fieldId); // NUNCA
    return { ...game, fieldName: field.name };
  }));
}

// ✅ CORRETO: usar o snapshot que já está no registro
async findAll(): Promise<OpenGameDto[]> {
  const games = await this.openGameRepository.findAll();
  return games.map(game => OpenGameDto.fromEntity(game)); // fieldName vem do field_snapshot
}
```
