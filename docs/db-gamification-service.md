# Database: gamification-service

**Technology:** PostgreSQL  
**Bounded Context:** Gamification Context  
**Responsibility:** Temporadas, stats individuais/time, ligas privadas, eventos/desafios, badges, streaks

> **Separação de responsabilidades:** O `ranking-service` mantém o ranking **competitivo formal** de times (W/E/D). O `gamification-service` gerencia a camada de **engajamento individual** — stats de jogador em qualquer modalidade, temporadas, ligas, eventos e conquistas.

---

## Schema

### Table: `seasons`

Períodos de acúmulo de stats.

```sql
CREATE TABLE seasons (
  id          BIGSERIAL   PRIMARY KEY,
  external_id UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  name        TEXT        NOT NULL, -- "Q2 2026", "Verão 2026"
  type        TEXT        NOT NULL DEFAULT 'GLOBAL', -- GLOBAL | LEAGUE | EVENT
  starts_at   DATE        NOT NULL,
  ends_at     DATE        NOT NULL,
  status      TEXT        NOT NULL DEFAULT 'UPCOMING',
  -- UPCOMING | ACTIVE | ENDED
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_seasons_status ON seasons (status, starts_at);
```

**Gestão de temporadas globais:**

```sql
-- Temporadas Q1/Q2/Q3/Q4 criadas antecipadamente pelo sistema
-- Job diário verifica se deve ativar/encerrar
UPDATE seasons SET status = 'ACTIVE'  WHERE status = 'UPCOMING' AND starts_at <= CURRENT_DATE;
UPDATE seasons SET status = 'ENDED'   WHERE status = 'ACTIVE'   AND ends_at   <  CURRENT_DATE;
```

---

### Table: `player_season_stats`

Stats acumuladas do jogador por temporada. Unifica peladas e partidas formais.

```sql
CREATE TABLE player_season_stats (
  id              BIGSERIAL   PRIMARY KEY,
  player_id       TEXT        NOT NULL, -- → users.external_id
  season_id       BIGINT      NOT NULL REFERENCES seasons (id),
  team_id         TEXT,                 -- → teams.external_id (se aplicável)

  -- Stats
  goals           INT         NOT NULL DEFAULT 0,
  assists         INT         NOT NULL DEFAULT 0,
  games_played    INT         NOT NULL DEFAULT 0,
  wins            INT         NOT NULL DEFAULT 0, -- só partidas formais
  losses          INT         NOT NULL DEFAULT 0, -- só partidas formais
  draws           INT         NOT NULL DEFAULT 0, -- só partidas formais
  peladas_played  INT         NOT NULL DEFAULT 0,

  -- Ranking na temporada (recalculado periodicamente)
  goals_rank      INT,
  games_rank      INT,

  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, season_id)
);
CREATE INDEX idx_pss_season_goals  ON player_season_stats (season_id, goals DESC);
CREATE INDEX idx_pss_season_games  ON player_season_stats (season_id, games_played DESC);
CREATE INDEX idx_pss_player_id     ON player_season_stats (player_id);
```

---

### Table: `stat_events_inbox`

Inbox de eventos de stats — padrão CQRS para processamento confiável.

```sql
CREATE TABLE stat_events_inbox (
  id             BIGSERIAL   PRIMARY KEY,
  event_type     TEXT        NOT NULL,
  -- OPEN_GAME_STATS | MATCH_COMPLETED
  source_game_id TEXT        NOT NULL, -- external_id do open_game ou match
  season_id      BIGINT      NOT NULL REFERENCES seasons (id),
  payload        JSONB       NOT NULL,
  -- OPEN_GAME_STATS: [{ player_id, goals, assists }]
  -- MATCH_COMPLETED: { teamAId, teamBId, scoreA, scoreB, players: [...] }
  processed      BOOLEAN     NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at   TIMESTAMPTZ,
  UNIQUE (event_type, source_game_id) -- idempotência
);
CREATE INDEX idx_inbox_unprocessed ON stat_events_inbox (created_at) WHERE processed = false;
```

---

### Table: `leagues`

Ligas privadas entre amigos.

```sql
CREATE TABLE leagues (
  id              BIGSERIAL   PRIMARY KEY,
  external_id     UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  created_by      TEXT        NOT NULL, -- → users.external_id
  name            TEXT        NOT NULL,
  photo_url       TEXT,
  scoring_metric  TEXT        NOT NULL DEFAULT 'goals',
  -- goals | games_played | assists | wins | custom
  invite_token    TEXT        NOT NULL DEFAULT gen_random_uuid()::text UNIQUE,
  is_public       BOOLEAN     NOT NULL DEFAULT false,
  status          TEXT        NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | ARCHIVED
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_leagues_external_id   ON leagues (external_id);
CREATE INDEX idx_leagues_invite_token  ON leagues (invite_token);
CREATE INDEX idx_leagues_created_by    ON leagues (created_by);
```

---

### Table: `league_members`

```sql
CREATE TABLE league_members (
  id          BIGSERIAL   PRIMARY KEY,
  league_id   BIGINT      NOT NULL REFERENCES leagues (id) ON DELETE CASCADE,
  player_id   TEXT        NOT NULL, -- → users.external_id
  role        TEXT        NOT NULL DEFAULT 'MEMBER', -- ADMIN | MEMBER
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at     TIMESTAMPTZ,
  UNIQUE (league_id, player_id)
);
CREATE INDEX idx_league_members_league  ON league_members (league_id) WHERE left_at IS NULL;
CREATE INDEX idx_league_members_player  ON league_members (player_id) WHERE left_at IS NULL;
```

---

### Table: `league_seasons`

Temporada de uma liga (pode ser diferente das temporadas globais).

```sql
CREATE TABLE league_seasons (
  id          BIGSERIAL   PRIMARY KEY,
  league_id   BIGINT      NOT NULL REFERENCES leagues (id) ON DELETE CASCADE,
  season_id   BIGINT      NOT NULL REFERENCES seasons (id),
  -- Ou pode ter temporada própria:
  name        TEXT,
  starts_at   DATE        NOT NULL,
  ends_at     DATE        NOT NULL,
  status      TEXT        NOT NULL DEFAULT 'ACTIVE',
  winner_id   TEXT,       -- → users.external_id — preenchido ao encerrar
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (league_id, season_id)
);
```

---

### Table: `challenges` (Eventos/Desafios)

Desafios públicos criados pelo BolaNaRede ou patrocinadores.

```sql
CREATE TABLE challenges (
  id                BIGSERIAL    PRIMARY KEY,
  external_id       UUID         NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  title             TEXT         NOT NULL,
  description       TEXT,
  sponsor_name      TEXT,        -- nome da marca patrocinadora
  sponsor_logo_url  TEXT,
  metric            TEXT         NOT NULL,
  -- goals | games_played | assists | wins | peladas_played
  scope             TEXT         NOT NULL DEFAULT 'NATIONAL',
  -- NATIONAL | STATE | CITY
  scope_value       TEXT,        -- ex: "PR", "Curitiba"
  target_audience   TEXT         NOT NULL DEFAULT 'ALL',
  -- ALL | PLAYERS | TEAMS
  prize_description TEXT,
  starts_at         TIMESTAMPTZ  NOT NULL,
  ends_at           TIMESTAMPTZ  NOT NULL,
  status            TEXT         NOT NULL DEFAULT 'UPCOMING',
  -- UPCOMING | ACTIVE | ENDED
  winner_ids        TEXT[],      -- preenchido ao encerrar
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_challenges_status ON challenges (status, starts_at);
CREATE INDEX idx_challenges_scope  ON challenges (scope, scope_value) WHERE status = 'ACTIVE';
```

---

### Table: `challenge_participants`

```sql
CREATE TABLE challenge_participants (
  id              BIGSERIAL   PRIMARY KEY,
  challenge_id    BIGINT      NOT NULL REFERENCES challenges (id) ON DELETE CASCADE,
  player_id       TEXT        NOT NULL, -- → users.external_id
  score           INT         NOT NULL DEFAULT 0, -- valor do metric acumulado no período
  rank            INT,                            -- recalculado periodicamente
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (challenge_id, player_id)
);
CREATE INDEX idx_cp_challenge_rank   ON challenge_participants (challenge_id, rank);
CREATE INDEX idx_cp_challenge_score  ON challenge_participants (challenge_id, score DESC);
CREATE INDEX idx_cp_player_id        ON challenge_participants (player_id);
```

---

### Table: `badge_definitions`

Catálogo de badges disponíveis.

```sql
CREATE TABLE badge_definitions (
  id            BIGSERIAL  PRIMARY KEY,
  code          TEXT       NOT NULL UNIQUE, -- 'top_scorer_q2_2026', 'streak_8_weeks'
  name          TEXT       NOT NULL,
  description   TEXT       NOT NULL,
  icon_url      TEXT,
  category      TEXT       NOT NULL, -- 'season' | 'streak' | 'event' | 'milestone'
  is_active     BOOLEAN    NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

### Table: `player_badges`

Badges conquistados permanentemente.

```sql
CREATE TABLE player_badges (
  id                  BIGSERIAL   PRIMARY KEY,
  player_id           TEXT        NOT NULL, -- → users.external_id
  badge_id            BIGINT      NOT NULL REFERENCES badge_definitions (id),
  context_id          TEXT,                 -- season_id, challenge_id, etc.
  awarded_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (player_id, badge_id, context_id)
);
CREATE INDEX idx_player_badges_player ON player_badges (player_id);
```

---

### Table: `player_streaks`

```sql
CREATE TABLE player_streaks (
  id                  BIGSERIAL   PRIMARY KEY,
  player_id           TEXT        NOT NULL UNIQUE, -- → users.external_id
  current_streak      INT         NOT NULL DEFAULT 0, -- semanas consecutivas jogando
  longest_streak      INT         NOT NULL DEFAULT 0,
  last_game_week      TEXT,       -- formato 'YYYY-Www' ex: '2026-W15'
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Job semanal:**

```sql
-- Segunda-feira: zera streak de quem não jogou na semana anterior
UPDATE player_streaks
SET current_streak = 0
WHERE last_game_week < to_char(now() - interval '1 week', 'IYYY-"W"IW');
```

---

### Table: `player_identities` (Projeção Local)

Projeção sincronizada do identity-service para exibir nomes e fotos nos rankings.

```sql
CREATE TABLE player_identities (
  player_id     TEXT        PRIMARY KEY, -- = users.external_id
  display_name  TEXT        NOT NULL,
  photo_url     TEXT,
  city          TEXT,
  synced_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Domain Events Published

| Event            | Trigger             | Payload                              |
| ---------------- | ------------------- | ------------------------------------ |
| `SeasonEnded`    | Temporada encerrada | `{ seasonId, topPlayers, topTeams }` |
| `BadgeAwarded`   | Badge conquistado   | `{ playerId, badgeCode, contextId }` |
| `ChallengeEnded` | Desafio encerrado   | `{ challengeId, winnerIds }`         |

## Domain Events Consumed

| Event               | Source            | Action                                               |
| ------------------- | ----------------- | ---------------------------------------------------- |
| `GameStatsRecorded` | open-game-service | Insere em `stat_events_inbox` (tipo OPEN_GAME_STATS) |
| `MatchCompleted`    | game-service      | Insere em `stat_events_inbox` (tipo MATCH_COMPLETED) |
| `ProfileUpdated`    | identity-service  | Upsert em `player_identities`                        |
| `AccountAnonymized` | identity-service  | Anonymiza dados do jogador                           |
