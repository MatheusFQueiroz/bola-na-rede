# Database: open-game-service

**Technology:** PostgreSQL + Redis  
**Bounded Context:** Open Game Context (Pelada)  
**Responsibility:** Peladas abertas, participações, planos recorrentes de grupo

---

## Schema

### Table: `open_games`

```sql
CREATE TABLE open_games (
  id                  BIGSERIAL   PRIMARY KEY,
  external_id         UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  organizer_id        TEXT        NOT NULL, -- → users.external_id

  -- Snapshot imutável do organizador (padrão Snapshot)
  organizer_snapshot  JSONB       NOT NULL DEFAULT '{}',
  -- { user_id, display_name, photo_url }

  title               TEXT        NOT NULL,
  type                TEXT        NOT NULL DEFAULT 'OPEN', -- OPEN | CLOSED
  status              TEXT        NOT NULL DEFAULT 'OPEN',
  -- DRAFT | OPEN | FULL | CANCELLED | FINISHED

  -- Campo (snapshot imutável se tiver campo do catálogo)
  field_id            TEXT,       -- → fields.external_id
  field_snapshot      JSONB       NOT NULL DEFAULT '{}',
  -- { field_id, name, address, lat, lng, photo_url } ou { free_address: "..." }

  -- Plano recorrente (se aplicável)
  recurring_plan_id   TEXT,       -- → recurring_plans.external_id no field-service

  -- Horário
  scheduled_at        TIMESTAMPTZ NOT NULL,
  duration_min        SMALLINT    NOT NULL DEFAULT 60,

  -- Vagas
  max_players         SMALLINT    NOT NULL,
  min_players         SMALLINT,   -- se definido: cancelamento auto se não atingir
  confirmed_count     SMALLINT    NOT NULL DEFAULT 0,

  -- Configurações
  description         TEXT,
  share_token         TEXT        NOT NULL DEFAULT gen_random_uuid()::text UNIQUE,

  -- Expiração para inscrições
  registration_closes_at TIMESTAMPTZ NOT NULL, -- padrão: scheduled_at - 1h

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_og_external_id     ON open_games (external_id);
CREATE INDEX idx_og_organizer       ON open_games (organizer_id);
CREATE INDEX idx_og_status_date     ON open_games (status, scheduled_at) WHERE status IN ('OPEN', 'FULL');
CREATE INDEX idx_og_share_token     ON open_games (share_token);
CREATE INDEX idx_og_recurring_plan  ON open_games (recurring_plan_id) WHERE recurring_plan_id IS NOT NULL;
-- Índice geográfico: usar field_snapshot->>'lat' e ->>'lng' com cast
-- Para queries de proximidade, usar Redis GEO ou consultar via BFF no field-service
```

---

### Table: `game_participations`

```sql
CREATE TABLE game_participations (
  id               BIGSERIAL   PRIMARY KEY,
  open_game_id     BIGINT      NOT NULL REFERENCES open_games (id) ON DELETE CASCADE,
  player_id        TEXT        NOT NULL, -- → users.external_id
  status           TEXT        NOT NULL DEFAULT 'PENDING',
  -- PENDING | CONFIRMED | DECLINED | WAITLIST | NO_SHOW
  position         TEXT,       -- goalkeeper | defender | midfielder | forward
  requested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at     TIMESTAMPTZ,
  checked_in       BOOLEAN     NOT NULL DEFAULT false,
  checked_in_at    TIMESTAMPTZ,
  UNIQUE (open_game_id, player_id)
);
CREATE INDEX idx_gp_game_id     ON game_participations (open_game_id, status);
CREATE INDEX idx_gp_player_id   ON game_participations (player_id, status);
CREATE INDEX idx_gp_checkin     ON game_participations (open_game_id) WHERE checked_in = true;
```

---

### Table: `game_stats`

Stats registradas pelo organizador ao encerrar a pelada (tap rápido).

```sql
CREATE TABLE game_stats (
  id             BIGSERIAL   PRIMARY KEY,
  open_game_id   BIGINT      NOT NULL REFERENCES open_games (id) ON DELETE CASCADE UNIQUE,
  recorded_by    TEXT        NOT NULL, -- → users.external_id (organizador)
  stats          JSONB       NOT NULL DEFAULT '[]',
  -- [{ player_id, goals, assists }]
  recorded_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_game_stats_game_id ON game_stats (open_game_id);
```

**Exemplo do JSONB:**

```json
[
  { "player_id": "uuid-1", "goals": 2, "assists": 1 },
  { "player_id": "uuid-2", "goals": 0, "assists": 3 }
]
```

---

### Table: `player_summaries` (Projeção Local)

Projeção read-only sincronizada via eventos do `identity-service` e `social-service`.  
Usada para exibir quem vai na pelada sem chamar outros serviços.

```sql
CREATE TABLE player_summaries (
  player_id     TEXT        PRIMARY KEY, -- = users.external_id
  display_name  TEXT        NOT NULL,
  photo_url     TEXT,
  city          TEXT,
  position      TEXT,
  overall_score NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  review_count  INT          NOT NULL DEFAULT 0,
  synced_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```

**Atualizado via consumers:**

- `identity.events → ProfileUpdated` → atualiza display_name, photo_url, city, position
- `social.events → PlayerScoreUpdated` → atualiza overall_score, review_count

---

## Redis Usage

| Key                       | Type   | TTL | Purpose                                                      |
| ------------------------- | ------ | --- | ------------------------------------------------------------ |
| `og:feed:{city}:sorted`   | ZSet   | 1h  | Feed de peladas abertas por cidade (scored por scheduled_at) |
| `og:geo:games`            | GEO    | 1h  | Peladas ativas com coordenadas para query por proximidade    |
| `og:{id}:confirmed_count` | String | —   | Contador de vagas para evitar race condition                 |
| `og:{id}:lock`            | String | 10s | Lock distribuído ao confirmar participação                   |

---

## Domain Events Published

| Event               | Trigger                    | Payload                                                       |
| ------------------- | -------------------------- | ------------------------------------------------------------- |
| `OpenGameCreated`   | Pelada criada              | `{ gameId, organizerId, scheduledAt, fieldId, maxPlayers }`   |
| `PlayerJoinedGame`  | Jogador confirmado         | `{ gameId, playerId, confirmedCount }`                        |
| `PlayerLeftGame`    | Jogador saiu               | `{ gameId, playerId }`                                        |
| `OpenGameFull`      | Vagas esgotadas            | `{ gameId }`                                                  |
| `OpenGameFinished`  | Check-in encerrado + stats | `{ gameId, confirmedPlayers: [userId], statsRecorded: bool }` |
| `OpenGameCancelled` | Pelada cancelada           | `{ gameId, reason, affectedPlayers: [userId] }`               |
| `GameStatsRecorded` | Stats registradas          | `{ gameId, stats: [{playerId, goals, assists}] }`             |

## Domain Events Consumed

| Event                | Source           | Action                                                        |
| -------------------- | ---------------- | ------------------------------------------------------------- |
| `ProfileUpdated`     | identity-service | Upsert em `player_summaries`                                  |
| `PlayerScoreUpdated` | social-service   | Atualiza score em `player_summaries`                          |
| `AccountAnonymized`  | identity-service | Anonymiza dados em `player_summaries` e `game_participations` |
