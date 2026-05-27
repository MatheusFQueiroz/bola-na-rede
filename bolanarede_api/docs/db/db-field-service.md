# Database: field-service

**Technology:** PostgreSQL + PostGIS  
**Bounded Context:** Field Management Context  
**Responsibility:** Field catalog, availability, **ALL reservations from ALL channels**, recurring plans, financial tracking, basic CRM

> **Posicionamento:** Este serviço gerencia o campo como um **negócio completo** — não apenas como um ponto no mapa. O ecossistema BolaNaRede é um canal de reservas, mas o campo também recebe reservas por telefone, WhatsApp e outros meios, todos gerenciados aqui.

---

## Setup

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

---

## Schema

### Table: `fields`

```sql
CREATE TABLE fields (
  id               BIGSERIAL    PRIMARY KEY,
  external_id      UUID         NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  owner_user_id    TEXT         NOT NULL, -- → users.external_id
  name             TEXT         NOT NULL,
  description      TEXT,
  street           TEXT,
  city             TEXT         NOT NULL,
  state            TEXT         NOT NULL,
  zip_code         TEXT,
  location         GEOGRAPHY(POINT, 4326) NOT NULL,
  contact_phone    TEXT,
  contact_email    TEXT,
  cover_photo_url  TEXT,
  status           TEXT         NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | INACTIVE | SUSPENDED
  plan             TEXT         NOT NULL DEFAULT 'BASIC', -- BASIC | PRO | MULTI
  plan_expires_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_fields_external_id    ON fields (external_id);
CREATE INDEX idx_fields_owner          ON fields (owner_user_id);
CREATE INDEX idx_fields_location       ON fields USING GIST (location);
CREATE INDEX idx_fields_city_status    ON fields (city, status);
```

**Nota:** Campo no plano BASIC só aparece no catálogo BolaNaRede se fizer upgrade para PRO (regra de negócio no application layer).

---

### Table: `field_photos`

```sql
CREATE TABLE field_photos (
  id          BIGSERIAL   PRIMARY KEY,
  field_id    BIGINT      NOT NULL REFERENCES fields (id) ON DELETE CASCADE,
  url         TEXT        NOT NULL,
  sort_order  SMALLINT    NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_field_photos_field_id ON field_photos (field_id);
```

---

### Table: `field_courts`

Campos com mais de uma quadra/espaço físico.

```sql
CREATE TABLE field_courts (
  id           BIGSERIAL  PRIMARY KEY,
  field_id     BIGINT     NOT NULL REFERENCES fields (id) ON DELETE CASCADE,
  name         TEXT       NOT NULL, -- "Quadra 1", "Campo Society"
  modality     TEXT       NOT NULL, -- society | futsal | salao
  surface      TEXT,                -- grass | synthetic | concrete
  capacity     SMALLINT   NOT NULL, -- jogadores por time
  is_active    BOOLEAN    NOT NULL DEFAULT true
);
CREATE INDEX idx_courts_field_id ON field_courts (field_id);
```

---

### Table: `pricing_rules`

Preços configuráveis por horário/dia do campo.

```sql
CREATE TABLE pricing_rules (
  id            BIGSERIAL    PRIMARY KEY,
  field_id      BIGINT       NOT NULL REFERENCES fields (id) ON DELETE CASCADE,
  court_id      BIGINT       REFERENCES field_courts (id) ON DELETE CASCADE,
  name          TEXT         NOT NULL, -- "Noturno", "Fim de semana"
  day_of_week   SMALLINT[],            -- NULL = todos os dias
  start_time    TIME         NOT NULL,
  end_time      TIME         NOT NULL,
  price         NUMERIC(8,2) NOT NULL,
  is_active     BOOLEAN      NOT NULL DEFAULT true
);
CREATE INDEX idx_pricing_rules_field_id ON pricing_rules (field_id);
```

---

### Table: `availability_slots`

Grade de horários disponíveis por padrão, por dia da semana.

```sql
CREATE TABLE availability_slots (
  id            BIGSERIAL   PRIMARY KEY,
  field_id      BIGINT      NOT NULL REFERENCES fields (id) ON DELETE CASCADE,
  court_id      BIGINT      REFERENCES field_courts (id),
  day_of_week   SMALLINT    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time    TIME        NOT NULL,
  end_time      TIME        NOT NULL,
  is_available  BOOLEAN     NOT NULL DEFAULT true,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_time_range CHECK (start_time < end_time)
);
CREATE INDEX idx_availability_field_day ON availability_slots (field_id, day_of_week);
CREATE INDEX idx_availability_available ON availability_slots (is_available) WHERE is_available = true;
```

---

### Table: `reservations` ⭐ Central

**Todas as reservas**, independentemente do canal de origem.

```sql
CREATE TABLE reservations (
  id                BIGSERIAL    PRIMARY KEY,
  external_id       UUID         NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  field_id          BIGINT       NOT NULL REFERENCES fields (id),
  court_id          BIGINT       REFERENCES field_courts (id),
  recurring_plan_id BIGINT       REFERENCES recurring_plans (id),

  -- Canal de origem
  channel           TEXT         NOT NULL,
  -- bolanarededb_app | manual | whatsapp | phone | link
  channel_ref_id    TEXT,        -- ID do open_game ou match no canal de origem

  -- Quem reservou (snapshot)
  booker_user_id    TEXT,        -- → users.external_id (se veio pelo app)
  booker_snapshot   JSONB        NOT NULL DEFAULT '{}',
  -- { name, photo_url, type: "player"|"team"|"group", contact_phone }

  -- Horário
  date              DATE         NOT NULL,
  start_time        TIME         NOT NULL,
  end_time          TIME         NOT NULL,

  -- Valor
  price             NUMERIC(8,2) NOT NULL DEFAULT 0,
  platform_fee_pct  NUMERIC(4,2) NOT NULL DEFAULT 0, -- % de comissão BolaNaRede
  platform_fee_amt  NUMERIC(8,2) NOT NULL DEFAULT 0,
  net_amount        NUMERIC(8,2) GENERATED ALWAYS AS (price - platform_fee_amt) STORED,

  -- Status
  status            TEXT         NOT NULL DEFAULT 'PENDING',
  -- PENDING | CONFIRMED | CANCELLED | NO_SHOW | COMPLETED

  payment_status    TEXT         NOT NULL DEFAULT 'UNPAID',
  -- UNPAID | PAID | REFUNDED | EXTERNAL (pagamento fora do app)

  notes             TEXT,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  cancelled_at      TIMESTAMPTZ,
  cancellation_reason TEXT
);
CREATE INDEX idx_reservations_field_date  ON reservations (field_id, date, start_time);
CREATE INDEX idx_reservations_channel_ref ON reservations (channel, channel_ref_id) WHERE channel_ref_id IS NOT NULL;
CREATE INDEX idx_reservations_plan_id     ON reservations (recurring_plan_id) WHERE recurring_plan_id IS NOT NULL;
CREATE INDEX idx_reservations_booker      ON reservations (booker_user_id) WHERE booker_user_id IS NOT NULL;
CREATE INDEX idx_reservations_status      ON reservations (field_id, status, date);
```

---

### Table: `recurring_plans` ⭐ Diferencial

Planos de horário fixo semanal. Podem ser vinculados a um grupo de pelada ou time formal.

```sql
CREATE TABLE recurring_plans (
  id                 BIGSERIAL    PRIMARY KEY,
  external_id        UUID         NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  field_id           BIGINT       NOT NULL REFERENCES fields (id),
  court_id           BIGINT       REFERENCES field_courts (id),

  -- Responsável pelo plano
  owner_user_id      TEXT         NOT NULL, -- → users.external_id (capitão ou organizador)
  owner_snapshot     JSONB        NOT NULL DEFAULT '{}',
  linked_entity_type TEXT,        -- 'open_game_group' | 'team'
  linked_entity_id   TEXT,        -- external_id do grupo ou time

  -- Recorrência
  day_of_week        SMALLINT     NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time         TIME         NOT NULL,
  end_time           TIME         NOT NULL,
  price_per_slot     NUMERIC(8,2) NOT NULL,
  platform_fee_pct   NUMERIC(4,2) NOT NULL DEFAULT 6, -- 6% para planos recorrentes

  -- Regra de liberação
  release_before_h   SMALLINT     NOT NULL DEFAULT 12,
  -- horas antes que o slot é liberado se não houver jogo confirmado

  -- Status
  status             TEXT         NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | PAUSED | CANCELLED
  valid_from         DATE         NOT NULL DEFAULT CURRENT_DATE,
  valid_until        DATE,        -- NULL = indefinido
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_recurring_plans_field_id ON recurring_plans (field_id, status);
CREATE INDEX idx_recurring_plans_owner    ON recurring_plans (owner_user_id);
```

---

### Table: `recurring_plan_slots`

Instâncias semanais do plano. Uma row por semana/horário.

```sql
CREATE TABLE recurring_plan_slots (
  id                BIGSERIAL   PRIMARY KEY,
  plan_id           BIGINT      NOT NULL REFERENCES recurring_plans (id) ON DELETE CASCADE,
  slot_date         DATE        NOT NULL,
  status            TEXT        NOT NULL DEFAULT 'PRE_RESERVED',
  -- PRE_RESERVED | CONFIRMED | RELEASED | CANCELLED
  reservation_id    BIGINT      REFERENCES reservations (id),
  game_ref_id       TEXT,       -- open_game ou match external_id confirmado
  release_at        TIMESTAMPTZ NOT NULL, -- calculado: slot_date + start_time - release_before_h
  confirmed_at      TIMESTAMPTZ,
  released_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (plan_id, slot_date)
);
CREATE INDEX idx_plan_slots_plan_id     ON recurring_plan_slots (plan_id, status);
CREATE INDEX idx_plan_slots_release_at  ON recurring_plan_slots (release_at) WHERE status = 'PRE_RESERVED';
CREATE INDEX idx_plan_slots_date        ON recurring_plan_slots (slot_date, status);
```

**Job de liberação automática:**

```sql
-- Roda a cada hora — libera slots não confirmados vencidos
UPDATE recurring_plan_slots
SET status = 'RELEASED', released_at = now()
WHERE status = 'PRE_RESERVED'
  AND release_at <= now();
```

---

### Table: `field_customers` (CRM básico)

Registro de quem reservou o campo — independentemente do canal.

```sql
CREATE TABLE field_customers (
  id                 BIGSERIAL   PRIMARY KEY,
  field_id           BIGINT      NOT NULL REFERENCES fields (id),
  user_id            TEXT,       -- → users.external_id (se veio pelo app)
  display_name       TEXT        NOT NULL,
  contact_phone      TEXT,
  contact_email      TEXT,
  customer_type      TEXT        NOT NULL DEFAULT 'individual', -- individual | group | team
  first_booking_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_booking_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  total_bookings     INT         NOT NULL DEFAULT 1,
  notes              TEXT,       -- campo livre para o dono anotar
  UNIQUE (field_id, user_id) -- se vier do app, user_id é único por campo
);
CREATE INDEX idx_customers_field_id ON field_customers (field_id);
CREATE INDEX idx_customers_user_id  ON field_customers (user_id) WHERE user_id IS NOT NULL;
```

---

### Table: `field_blocked_slots`

Bloqueios manuais de horário (manutenção, eventos privados, feriados).

```sql
CREATE TABLE field_blocked_slots (
  id          BIGSERIAL   PRIMARY KEY,
  field_id    BIGINT      NOT NULL REFERENCES fields (id) ON DELETE CASCADE,
  court_id    BIGINT      REFERENCES field_courts (id),
  date        DATE        NOT NULL,
  start_time  TIME        NOT NULL,
  end_time    TIME        NOT NULL,
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_blocked_field_date ON field_blocked_slots (field_id, date);
```

---

## View: `daily_occupancy`

View para o dashboard de taxa de ocupação.

```sql
CREATE VIEW daily_occupancy AS
SELECT
  r.field_id,
  r.date,
  COUNT(*) FILTER (WHERE r.status IN ('CONFIRMED', 'COMPLETED')) AS booked_slots,
  COUNT(*) FILTER (WHERE r.status = 'CANCELLED') AS cancelled_slots,
  SUM(r.price) FILTER (WHERE r.status IN ('CONFIRMED', 'COMPLETED')) AS gross_revenue,
  SUM(r.net_amount) FILTER (WHERE r.status IN ('CONFIRMED', 'COMPLETED')) AS net_revenue,
  COUNT(*) FILTER (WHERE r.channel = 'bolanarededb_app') AS app_bookings,
  COUNT(*) FILTER (WHERE r.channel != 'bolanarededb_app') AS direct_bookings
FROM reservations r
GROUP BY r.field_id, r.date;
```

---

## Domain Events Published

| Event                  | Trigger                       | Payload                                                     |
| ---------------------- | ----------------------------- | ----------------------------------------------------------- |
| `FieldRegistered`      | Novo campo cadastrado         | `{ fieldId, name, city, location }`                         |
| `AvailabilityUpdated`  | Grade alterada                | `{ fieldId, dayOfWeek }`                                    |
| `ReservationCreated`   | Nova reserva (qualquer canal) | `{ reservationId, fieldId, channel, date, bookerSnapshot }` |
| `ReservationConfirmed` | Reserva confirmada            | `{ reservationId, fieldId, date, channelRefId }`            |
| `ReservationCancelled` | Reserva cancelada             | `{ reservationId, fieldId, date, reason }`                  |
| `PlanSlotReleased`     | Slot de plano liberado        | `{ planId, slotDate, fieldId }`                             |

## Domain Events Consumed

| Event               | Source              | Action                                   |
| ------------------- | ------------------- | ---------------------------------------- |
| `MatchAccepted`     | matchmaking-service | Confirma slot do plano, cria reservation |
| `OpenGameFinished`  | open-game-service   | Atualiza reservation para COMPLETED      |
| `OpenGameCancelled` | open-game-service   | Cancela reservation vinculada            |
