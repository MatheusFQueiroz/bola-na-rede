# Database: matchmaking-service

**Technology:** PostgreSQL + Redis  
**Bounded Context:** Matchmaking Context (Core)  
**Responsibility:** Match discovery, proposals, expiration

---

## PostgreSQL Schema

### Table: `match_requests`

```sql
CREATE TABLE match_requests (
  id                   BIGSERIAL   PRIMARY KEY,
  external_id          UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  requesting_team_id   TEXT        NOT NULL, -- UUID from team-service
  preferred_date       DATE        NOT NULL,
  preferred_time_start TIME        NOT NULL,
  preferred_time_end   TIME        NOT NULL,
  preferred_city       TEXT        NOT NULL,
  location_range_km    NUMERIC(5,1) NOT NULL DEFAULT 10,
  status               TEXT        NOT NULL DEFAULT 'PENDING', -- PENDING | MATCHED | EXPIRED | CANCELLED
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at           TIMESTAMPTZ NOT NULL, -- 48h from created_at (RN05)
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_match_requests_team_status ON match_requests (requesting_team_id, status);
CREATE INDEX idx_match_requests_status_date ON match_requests (status, preferred_date) WHERE status = 'PENDING';
CREATE INDEX idx_match_requests_expires_at  ON match_requests (expires_at) WHERE status = 'PENDING';
```

**Notes:**

- RN05: max 3 open requests per team → enforced at app level by counting `status = 'PENDING'` per `requesting_team_id`.
- Expiration job queries: `WHERE status = 'PENDING' AND expires_at <= now()`.

---

### Table: `match_proposals`

```sql
CREATE TABLE match_proposals (
  id                  BIGSERIAL   PRIMARY KEY,
  external_id         UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  match_request_id    BIGINT      NOT NULL REFERENCES match_requests (id) ON DELETE CASCADE,
  proposing_team_id   TEXT        NOT NULL, -- UUID from team-service
  field_id            TEXT,                 -- UUID from field-service (optional)
  proposed_date       DATE        NOT NULL,
  proposed_time_start TIME        NOT NULL,
  proposed_time_end   TIME        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'PENDING', -- PENDING | ACCEPTED | REJECTED | EXPIRED
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ NOT NULL, -- 48h (RN05)
  responded_at        TIMESTAMPTZ
);

CREATE INDEX idx_proposals_request_id ON match_proposals (match_request_id, status);
CREATE INDEX idx_proposals_team_id    ON match_proposals (proposing_team_id, status);
CREATE INDEX idx_proposals_expires_at ON match_proposals (expires_at) WHERE status = 'PENDING';
```

---

### Table: `team_summaries` (read-only replica from team-service)

Synced via domain events from `team-service`. Used for fast matching lookups without cross-service calls.

```sql
CREATE TABLE team_summaries (
  id             TEXT        PRIMARY KEY, -- = team external_id from team-service
  name           TEXT        NOT NULL,
  city           TEXT        NOT NULL,
  rating         NUMERIC(6,2) NOT NULL DEFAULT 1000,
  player_count   SMALLINT    NOT NULL DEFAULT 0,
  status         TEXT        NOT NULL DEFAULT 'ACTIVE', -- mirrors team status
  synced_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_team_summaries_city_status  ON team_summaries (city, status);
CREATE INDEX idx_team_summaries_rating       ON team_summaries (rating) WHERE status = 'ACTIVE';
```

**Notes:**

- Updated by consuming `TeamCreated`, `PlayerJoined`, `PlayerLeft`, `TeamBecameInvalid` events.
- `rating` updated by consuming `RankingRecalculated` events from ranking-service.

---

## Redis Usage

| Key Pattern                         | Type   | TTL    | Purpose                                     |
| ----------------------------------- | ------ | ------ | ------------------------------------------- |
| `match_req:{team_id}:active_count`  | String | 1 hour | Cache of open request count per team (RN05) |
| `match_proposals:{request_id}:lock` | String | 30s    | Distributed lock during proposal matching   |
| `expiration_queue`                  | ZSet   | —      | Sorted set by `expires_at` for expiry jobs  |

---

## Domain Events Published

| Event            | Trigger                           | Payload                                                |
| ---------------- | --------------------------------- | ------------------------------------------------------ |
| `MatchRequested` | New match request created         | `{ requestId, teamId, date, city, expiresAt }`         |
| `MatchAccepted`  | Proposal accepted by both teams   | `{ requestId, proposalId, teamAId, teamBId, fieldId }` |
| `MatchExpired`   | Request or proposal expired (48h) | `{ requestId, teamId, expiredAt }`                     |
| `MatchCancelled` | Request cancelled by team         | `{ requestId, teamId, cancelledAt }`                   |

## Domain Events Consumed

| Event                 | Source          | Action                                     |
| --------------------- | --------------- | ------------------------------------------ |
| `TeamCreated`         | team-service    | Insert into `team_summaries`               |
| `PlayerJoined`        | team-service    | Update `team_summaries.player_count`       |
| `PlayerLeft`          | team-service    | Update `team_summaries.player_count`       |
| `TeamBecameInvalid`   | team-service    | Update `team_summaries.status = 'INVALID'` |
| `RankingRecalculated` | ranking-service | Update `team_summaries.rating`             |

---

## Business Rules

| Rule | Description                  | Enforcement                                                    |
| ---- | ---------------------------- | -------------------------------------------------------------- |
| RN05 | Max 3 open requests per team | App-level count on `match_requests` WHERE `status = 'PENDING'` |
| RN05 | Proposals expire after 48h   | `expires_at` field + scheduled expiration job via Redis ZSet   |
