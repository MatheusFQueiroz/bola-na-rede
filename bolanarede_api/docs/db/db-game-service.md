# Database: game-service

**Technology:** PostgreSQL  
**Bounded Context:** Game Execution Context (Core)  
**Responsibility:** Match execution, results, confirmations, disputes

---

## Schema

### Table: `matches`

```sql
CREATE TABLE matches (
  id                  BIGSERIAL   PRIMARY KEY,
  external_id         UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  proposal_id         TEXT        NOT NULL UNIQUE, -- external_id from matchmaking-service
  team_a_id           TEXT        NOT NULL, -- UUID from team-service
  team_b_id           TEXT        NOT NULL, -- UUID from team-service
  field_id            TEXT,                 -- UUID from field-service
  scheduled_date      DATE        NOT NULL,
  scheduled_time_start TIME       NOT NULL,
  scheduled_time_end  TIME        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'SCHEDULED',
  -- SCHEDULED | IN_PROGRESS | COMPLETED | CANCELLED | NO_SHOW
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_matches_external_id  ON matches (external_id);
CREATE INDEX idx_matches_proposal_id  ON matches (proposal_id);
CREATE INDEX idx_matches_team_a       ON matches (team_a_id, status);
CREATE INDEX idx_matches_team_b       ON matches (team_b_id, status);
CREATE INDEX idx_matches_scheduled    ON matches (scheduled_date, status) WHERE status = 'SCHEDULED';
```

---

### Table: `match_results`

```sql
CREATE TABLE match_results (
  id                    BIGSERIAL   PRIMARY KEY,
  match_id              BIGINT      NOT NULL REFERENCES matches (id) ON DELETE CASCADE UNIQUE,
  score_team_a          SMALLINT    NOT NULL CHECK (score_team_a >= 0),
  score_team_b          SMALLINT    NOT NULL CHECK (score_team_b >= 0),
  registered_by_team_id TEXT        NOT NULL, -- UUID: which team submitted the result
  status                TEXT        NOT NULL DEFAULT 'PENDING_CONFIRMATION',
  -- PENDING_CONFIRMATION | CONFIRMED | DISPUTED | AUTO_ACCEPTED
  registered_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  confirmed_at          TIMESTAMPTZ,
  auto_accept_after     TIMESTAMPTZ -- set to registered_at + 24h (RN06 auto-accept window)
);

CREATE INDEX idx_results_match_id          ON match_results (match_id);
CREATE INDEX idx_results_pending_autoaccept ON match_results (auto_accept_after)
  WHERE status = 'PENDING_CONFIRMATION';
```

**Notes:**

- RN06 bilateral confirmation: both teams must confirm → tracked via `result_confirmations`.
- If the opposing team doesn't respond within 24h, result is `AUTO_ACCEPTED`.

---

### Table: `result_confirmations`

```sql
CREATE TABLE result_confirmations (
  id               BIGSERIAL   PRIMARY KEY,
  match_result_id  BIGINT      NOT NULL REFERENCES match_results (id) ON DELETE CASCADE,
  team_id          TEXT        NOT NULL, -- UUID confirming team
  confirmed        BOOLEAN     NOT NULL,
  responded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (match_result_id, team_id)
);

CREATE INDEX idx_confirmations_result_id ON result_confirmations (match_result_id);
```

---

### Table: `disputes`

```sql
CREATE TABLE disputes (
  id                  BIGSERIAL   PRIMARY KEY,
  match_result_id     BIGINT      NOT NULL REFERENCES match_results (id) ON DELETE CASCADE,
  disputing_team_id   TEXT        NOT NULL, -- UUID from team-service
  reason              TEXT        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'OPEN', -- OPEN | RESOLVED | DISMISSED
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at         TIMESTAMPTZ,
  resolution          TEXT,
  resolved_by         TEXT -- UUID of admin/moderator
);

CREATE INDEX idx_disputes_result_id ON disputes (match_result_id);
CREATE INDEX idx_disputes_status    ON disputes (status) WHERE status = 'OPEN';
```

---

## Domain Events Published

| Event              | Trigger                           | Payload                                                      |
| ------------------ | --------------------------------- | ------------------------------------------------------------ |
| `ResultRegistered` | Team submits match result         | `{ matchId, scoreA, scoreB, registeredBy, registeredAt }`    |
| `ResultConfirmed`  | Both teams confirmed result       | `{ matchId, scoreA, scoreB, confirmedAt }`                   |
| `ResultDisputed`   | Opposing team rejects result      | `{ matchId, disputeId, disputingTeamId, reason }`            |
| `MatchCompleted`   | Result confirmed or auto-accepted | `{ matchId, teamAId, teamBId, scoreA, scoreB, completedAt }` |
| `MatchNoShow`      | Match flagged as no-show          | `{ matchId, teamId, scheduledDate }`                         |

## Domain Events Consumed

| Event           | Source              | Action                      |
| --------------- | ------------------- | --------------------------- |
| `MatchAccepted` | matchmaking-service | Create new row in `matches` |

---

## Business Rules

| Rule | Description                              | Enforcement                                                |
| ---- | ---------------------------------------- | ---------------------------------------------------------- |
| RN06 | Bilateral confirmation required          | Two rows in `result_confirmations`; app checks both        |
| RN06 | Auto-accepted after 24h if no response   | `auto_accept_after` field + scheduled background job       |
| RN09 | Cancellation rules (penalty window etc.) | App-level logic when updating `matches.status`             |
| RN12 | Dispute process                          | `disputes` table; only one open dispute per result allowed |
