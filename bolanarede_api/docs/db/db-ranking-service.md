# Database: ranking-service

**Technology:** PostgreSQL  
**Bounded Context:** Ranking Context (Core)  
**Pattern:** CQRS — write side processes events; read side serves leaderboards  
**Responsibility:** Points calculation, team/player rankings, inactivity

---

## Schema

### Table: `team_standings`

Write side (updated by event consumers). Also serves as the read model for leaderboards.

```sql
CREATE TABLE team_standings (
  id               BIGSERIAL    PRIMARY KEY,
  team_id          TEXT         NOT NULL UNIQUE, -- UUID from team-service
  season           TEXT         NOT NULL DEFAULT 'ALL_TIME', -- e.g. '2026-Q1'
  points           INT          NOT NULL DEFAULT 0,
  wins             INT          NOT NULL DEFAULT 0,
  draws            INT          NOT NULL DEFAULT 0,
  losses           INT          NOT NULL DEFAULT 0,
  goals_for        INT          NOT NULL DEFAULT 0,
  goals_against    INT          NOT NULL DEFAULT 0,
  goal_difference  INT          GENERATED ALWAYS AS (goals_for - goals_against) STORED,
  matches_played   INT          NOT NULL DEFAULT 0,
  last_match_at    TIMESTAMPTZ,
  rank             INT,
  is_inactive      BOOLEAN      NOT NULL DEFAULT false, -- RN14
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (team_id, season)
);

-- Leaderboard read query support
CREATE INDEX idx_team_standings_season_rank    ON team_standings (season, rank) WHERE is_inactive = false;
CREATE INDEX idx_team_standings_season_points  ON team_standings (season, points DESC, goal_difference DESC);
CREATE INDEX idx_team_standings_team_id        ON team_standings (team_id);
CREATE INDEX idx_team_standings_inactivity     ON team_standings (last_match_at) WHERE is_inactive = false;
```

**Notes:**

- RN07: points system — app applies win=3pts, draw=1pt, loss=0pts on each `MatchCompleted` event.
- RN14: `is_inactive = true` if no matches in the last 30 days → background job checks `last_match_at`.

---

### Table: `player_standings`

```sql
CREATE TABLE player_standings (
  id              BIGSERIAL    PRIMARY KEY,
  player_id       TEXT         NOT NULL, -- UUID from identity-service
  team_id         TEXT         NOT NULL, -- UUID from team-service
  season          TEXT         NOT NULL DEFAULT 'ALL_TIME',
  goals           INT          NOT NULL DEFAULT 0,
  assists         INT          NOT NULL DEFAULT 0,
  matches_played  INT          NOT NULL DEFAULT 0,
  rank            INT,
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (player_id, season)
);

CREATE INDEX idx_player_standings_season_rank   ON player_standings (season, rank);
CREATE INDEX idx_player_standings_player_id     ON player_standings (player_id);
CREATE INDEX idx_player_standings_team_id       ON player_standings (team_id);
```

**Notes:**

- RN08: player ranking based on goals, assists, matches played.
- Individual player stats are currently aggregated from match-level data via events.

---

### Table: `ranking_events`

Inbox/outbox table for processing incoming domain events reliably.

```sql
CREATE TABLE ranking_events (
  id             BIGSERIAL   PRIMARY KEY,
  event_type     TEXT        NOT NULL, -- MATCH_COMPLETED | TEAM_BECAME_INACTIVE
  match_id       TEXT,                 -- UUID from game-service
  team_a_id      TEXT,
  team_b_id      TEXT,
  score_a        SMALLINT,
  score_b        SMALLINT,
  occurred_at    TIMESTAMPTZ NOT NULL,
  processed      BOOLEAN     NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at   TIMESTAMPTZ
);

-- Queue processing pattern (FOR UPDATE SKIP LOCKED)
CREATE INDEX idx_ranking_events_unprocessed ON ranking_events (created_at) WHERE processed = false;
```

**Processing query (CQRS write side):**

```sql
UPDATE ranking_events
SET processed = true, processed_at = now()
WHERE id = (
  SELECT id FROM ranking_events
  WHERE processed = false
  ORDER BY created_at
  LIMIT 1
  FOR UPDATE SKIP LOCKED
)
RETURNING *;
```

---

## Domain Events Published

| Event                 | Trigger                           | Payload                                            |
| --------------------- | --------------------------------- | -------------------------------------------------- |
| `PointsAwarded`       | After standings recalculation     | `{ teamId, points, wins, losses, draws, season }`  |
| `RankingRecalculated` | Full ranking recomputed           | `{ season, topTeams: [{ teamId, rank, points }] }` |
| `TeamBecameInactive`  | Team inactive for 30+ days (RN14) | `{ teamId, lastMatchAt, inactiveSince }`           |

## Domain Events Consumed

| Event            | Source       | Action                                                |
| ---------------- | ------------ | ----------------------------------------------------- |
| `MatchCompleted` | game-service | Insert into `ranking_events`, update `team_standings` |

---

## Business Rules

| Rule | Description                                      | Enforcement                                             |
| ---- | ------------------------------------------------ | ------------------------------------------------------- |
| RN07 | Points: win=3, draw=1, loss=0                    | Applied in event processor after `MatchCompleted`       |
| RN08 | Player ranking by goals, assists, matches played | `player_standings` updated via event processor          |
| RN14 | Team marked inactive after 30 days without match | Background job checks `last_match_at < now() - 30 days` |
