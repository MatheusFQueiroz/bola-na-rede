# Database: identity-service

**Technology:** PostgreSQL (isolated)  
**Bounded Context:** Identity Context  
**Responsibility:** Authentication, user base, player public profile, LGPD

---

## Schema

### Table: `users`

```sql
CREATE TABLE users (
  id           BIGSERIAL   PRIMARY KEY,
  external_id  UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  email        TEXT        UNIQUE,
  phone        TEXT        UNIQUE,
  status       TEXT        NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | ANONYMIZED
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at   TIMESTAMPTZ
);
CREATE INDEX idx_users_external_id ON users (external_id);
CREATE INDEX idx_users_email       ON users (email)  WHERE deleted_at IS NULL;
CREATE INDEX idx_users_phone       ON users (phone)  WHERE phone IS NOT NULL AND deleted_at IS NULL;
```

---

### Table: `credentials`

```sql
CREATE TABLE credentials (
  id            BIGSERIAL   PRIMARY KEY,
  user_id       BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  provider      TEXT        NOT NULL DEFAULT 'email',
  password_hash TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, provider)
);
CREATE INDEX idx_credentials_user_id ON credentials (user_id);
```

---

### Table: `player_profiles`

Perfil público do jogador — dados declarados pelo usuário.  
**Nota:** `player_score` vive no `social-service`. Este registro contém apenas o que o próprio usuário declarou.

```sql
CREATE TABLE player_profiles (
  id            BIGSERIAL   PRIMARY KEY,
  user_id       BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE UNIQUE,
  display_name  TEXT        NOT NULL,
  photo_url     TEXT,
  bio           TEXT,
  city          TEXT,
  position      TEXT, -- goalkeeper | defender | midfielder | forward
  skill_level   SMALLINT CHECK (skill_level BETWEEN 1 AND 5),
  is_public     BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_player_profiles_user_id ON player_profiles (user_id);
CREATE INDEX idx_player_profiles_city    ON player_profiles (city) WHERE is_public = true;
```

---

### Table: `device_tokens`

Tokens FCM para push notifications. Projeção consumida pelo `notification-service`.

```sql
CREATE TABLE device_tokens (
  id          BIGSERIAL   PRIMARY KEY,
  user_id     BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL, -- ios | android
  is_active   BOOLEAN     NOT NULL DEFAULT true,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, platform)
);
CREATE INDEX idx_device_tokens_user_id ON device_tokens (user_id) WHERE is_active = true;
```

---

### Table: `account_deletions`

Audit trail para LGPD (RN11).

```sql
CREATE TABLE account_deletions (
  id             BIGSERIAL   PRIMARY KEY,
  user_id        BIGINT      NOT NULL REFERENCES users (id),
  requested_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at   TIMESTAMPTZ,
  anonymized_at  TIMESTAMPTZ,
  reason         TEXT
);
```

---

## Domain Events Published

| Event                | Trigger              | Payload                                   |
| -------------------- | -------------------- | ----------------------------------------- |
| `UserRegistered`     | Novo usuário criado  | `{ userId, email, createdAt }`            |
| `ProfileUpdated`     | Perfil alterado      | `{ userId, displayName, photoUrl, city }` |
| `DeviceTokenUpdated` | Token FCM atualizado | `{ userId, token, platform }`             |
| `UserDeleted`        | Exclusão solicitada  | `{ userId, requestedAt }`                 |
| `AccountAnonymized`  | LGPD concluída       | `{ userId, anonymizedAt }`                |
