# Database: social-service

**Technology:** PostgreSQL  
**Bounded Context:** Social Context  
**Responsibility:** Avaliações de jogadores, scores de reputação

---

## Schema

### Table: `player_reviews`

```sql
CREATE TABLE player_reviews (
  id               BIGSERIAL   PRIMARY KEY,
  reviewer_id      TEXT        NOT NULL, -- → users.external_id
  reviewed_id      TEXT        NOT NULL, -- → users.external_id
  game_id          TEXT        NOT NULL, -- → open_games.external_id
  game_type        TEXT        NOT NULL DEFAULT 'OPEN_GAME', -- OPEN_GAME | FORMAL_MATCH (futuro)

  -- Critérios (1–5)
  fair_play        SMALLINT    NOT NULL CHECK (fair_play    BETWEEN 1 AND 5),
  punctuality      SMALLINT    NOT NULL CHECK (punctuality  BETWEEN 1 AND 5),
  skill            SMALLINT    NOT NULL CHECK (skill        BETWEEN 1 AND 5),
  vibe             SMALLINT    NOT NULL CHECK (vibe         BETWEEN 1 AND 5),

  is_anonymous     BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_reviewer_reviewed_game UNIQUE (reviewer_id, reviewed_id, game_id),
  CONSTRAINT no_self_review CHECK (reviewer_id <> reviewed_id)
);
CREATE INDEX idx_reviews_reviewed_id ON player_reviews (reviewed_id);
CREATE INDEX idx_reviews_game_id     ON player_reviews (game_id);
CREATE INDEX idx_reviews_reviewer_id ON player_reviews (reviewer_id);
```

---

### Table: `review_windows`

Janela de tempo em que avaliações ficam abertas após o encerramento de um jogo.

```sql
CREATE TABLE review_windows (
  id               BIGSERIAL   PRIMARY KEY,
  game_id          TEXT        NOT NULL UNIQUE, -- → open_games.external_id
  game_type        TEXT        NOT NULL DEFAULT 'OPEN_GAME',
  eligible_players TEXT[]      NOT NULL DEFAULT '{}', -- quem fez check-in
  opens_at         TIMESTAMPTZ NOT NULL,
  closes_at        TIMESTAMPTZ NOT NULL, -- opens_at + 24h
  is_open          BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_review_windows_game_id  ON review_windows (game_id);
CREATE INDEX idx_review_windows_open     ON review_windows (closes_at) WHERE is_open = true;
```

**Job de fechamento:**

```sql
UPDATE review_windows SET is_open = false
WHERE is_open = true AND closes_at <= now();
```

---

### Table: `player_scores` (Read Model)

Score calculado — atualizado após cada nova avaliação. CQRS write side.

```sql
CREATE TABLE player_scores (
  player_id        TEXT        PRIMARY KEY, -- → users.external_id
  fair_play_avg    NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  punctuality_avg  NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  skill_avg        NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  vibe_avg         NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  overall_avg      NUMERIC(3,1) NOT NULL DEFAULT 0.0,
  review_count     INT          NOT NULL DEFAULT 0,
  last_updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```

**Cálculo (executado após cada nova avaliação):**

```sql
-- Recalcular score do jogador revisado (últimas 50 avaliações)
WITH recent AS (
  SELECT *
  FROM player_reviews
  WHERE reviewed_id = $1
  ORDER BY created_at DESC
  LIMIT 50
)
INSERT INTO player_scores (player_id, fair_play_avg, punctuality_avg, skill_avg, vibe_avg, overall_avg, review_count, last_updated_at)
SELECT
  $1,
  ROUND(AVG(fair_play)::numeric, 1),
  ROUND(AVG(punctuality)::numeric, 1),
  ROUND(AVG(skill)::numeric, 1),
  ROUND(AVG(vibe)::numeric, 1),
  ROUND(((AVG(fair_play) + AVG(punctuality) + AVG(skill) + AVG(vibe)) / 4)::numeric, 1),
  COUNT(*),
  now()
FROM recent
ON CONFLICT (player_id) DO UPDATE
  SET fair_play_avg   = EXCLUDED.fair_play_avg,
      punctuality_avg = EXCLUDED.punctuality_avg,
      skill_avg       = EXCLUDED.skill_avg,
      vibe_avg        = EXCLUDED.vibe_avg,
      overall_avg     = EXCLUDED.overall_avg,
      review_count    = EXCLUDED.review_count,
      last_updated_at = now();
```

---

## Domain Events Published

| Event                | Trigger           | Payload                                                |
| -------------------- | ----------------- | ------------------------------------------------------ |
| `PlayerReviewed`     | Avaliação criada  | `{ reviewId, reviewedId, gameId }`                     |
| `PlayerScoreUpdated` | Score recalculado | `{ playerId, overallAvg, reviewCount, scores: {...} }` |

## Domain Events Consumed

| Event               | Source            | Action                                                          |
| ------------------- | ----------------- | --------------------------------------------------------------- |
| `OpenGameFinished`  | open-game-service | Cria `review_window` com `eligible_players` = quem fez check-in |
| `AccountAnonymized` | identity-service  | Deleta reviews do usuário, recalcula scores afetados            |

---

## Business Rules

| Rule  | Description                                                        |
| ----- | ------------------------------------------------------------------ |
| RNS01 | Só avalia quem está em `review_windows.eligible_players`           |
| RNS02 | Janela de avaliação: 24h após `OpenGameFinished`                   |
| RNS03 | UNIQUE (reviewer, reviewed, game) — uma avaliação por par por jogo |
| RNS04 | `reviewer_id <> reviewed_id` — não pode se auto-avaliar            |
| RNS05 | Score calculado sobre as **últimas 50** avaliações recebidas       |
