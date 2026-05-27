# Database: team-service

**Technology:** PostgreSQL  
**Bounded Context:** Team Management Context (Supporting)  
**Responsibility:** Team creation, members, captaincy

---

## Schema

### Table: `teams`

```sql
CREATE TABLE teams (
  id              BIGSERIAL   PRIMARY KEY,
  external_id     UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  name            TEXT        NOT NULL,
  city            TEXT        NOT NULL,
  status          TEXT        NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | INACTIVE | INVALID
  created_by      TEXT        NOT NULL, -- UUID from identity-service
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_teams_external_id    ON teams (external_id);
CREATE INDEX idx_teams_city_status    ON teams (city, status);
CREATE INDEX idx_teams_created_by     ON teams (created_by);
```

**Notes:**

- `created_by` stores `users.external_id` from identity-service (ACL pattern).
- `status = 'INVALID'` when team drops below 5 players (RN04).

---

### Table: `team_members`

```sql
CREATE TABLE team_members (
  id          BIGSERIAL   PRIMARY KEY,
  team_id     BIGINT      NOT NULL REFERENCES teams (id) ON DELETE CASCADE,
  user_id     TEXT        NOT NULL, -- UUID from identity-service
  role        TEXT        NOT NULL DEFAULT 'MEMBER', -- CAPTAIN | MEMBER
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at     TIMESTAMPTZ,
  UNIQUE (team_id, user_id, left_at) -- allows re-joining
);

CREATE INDEX idx_team_members_team_id        ON team_members (team_id) WHERE left_at IS NULL;
CREATE INDEX idx_team_members_user_id        ON team_members (user_id) WHERE left_at IS NULL;
CREATE INDEX idx_team_members_user_active    ON team_members (user_id, team_id) WHERE left_at IS NULL;
```

**Notes:**

- Query active members: `WHERE left_at IS NULL`.
- To enforce RN02 (max 3 teams per player): count active rows by `user_id WHERE left_at IS NULL`.
- To enforce RN04 (min 5 players): count active members per team.
- Only one `CAPTAIN` per team enforced at application level.

---

### Table: `team_invitations`

```sql
CREATE TABLE team_invitations (
  id               BIGSERIAL   PRIMARY KEY,
  team_id          BIGINT      NOT NULL REFERENCES teams (id) ON DELETE CASCADE,
  invited_user_id  TEXT        NOT NULL, -- UUID from identity-service
  invited_by       TEXT        NOT NULL, -- UUID from identity-service (must be CAPTAIN)
  status           TEXT        NOT NULL DEFAULT 'PENDING', -- PENDING | ACCEPTED | REJECTED | EXPIRED
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at       TIMESTAMPTZ NOT NULL,
  responded_at     TIMESTAMPTZ
);

CREATE INDEX idx_invitations_team_id         ON team_invitations (team_id, status);
CREATE INDEX idx_invitations_invited_user_id ON team_invitations (invited_user_id, status);
```

---

### Table: `captaincy_transfers`

Audit trail for RN10 (captaincy transfer).

```sql
CREATE TABLE captaincy_transfers (
  id              BIGSERIAL   PRIMARY KEY,
  team_id         BIGINT      NOT NULL REFERENCES teams (id),
  from_user_id    TEXT        NOT NULL, -- UUID from identity-service
  to_user_id      TEXT        NOT NULL, -- UUID from identity-service
  transferred_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_captaincy_transfers_team_id ON captaincy_transfers (team_id);
```

---

## Domain Events Published

| Event                  | Trigger              | Payload                                           |
| ---------------------- | -------------------- | ------------------------------------------------- |
| `TeamCreated`          | New team created     | `{ teamId, name, city, captainId, createdAt }`    |
| `PlayerJoined`         | Member added to team | `{ teamId, userId, role, joinedAt }`              |
| `PlayerLeft`           | Member left/removed  | `{ teamId, userId, leftAt }`                      |
| `CaptaincyTransferred` | Captain role changed | `{ teamId, fromUserId, toUserId, transferredAt }` |
| `TeamBecameInvalid`    | Active members < 5   | `{ teamId, memberCount }`                         |

---

## Business Rules

| Rule | Description                                     | Enforcement                                          |
| ---- | ----------------------------------------------- | ---------------------------------------------------- |
| RN02 | A player may be in at most 3 active teams       | App-level check via `team_members` count             |
| RN03 | Roles: CAPTAIN or MEMBER                        | `role` constraint + one CAPTAIN per team (app-level) |
| RN04 | Team needs minimum 5 active members             | App-level check; `status = 'INVALID'` if violated    |
| RN10 | Captaincy can be transferred by current captain | `captaincy_transfers` audit + app-level logic        |
