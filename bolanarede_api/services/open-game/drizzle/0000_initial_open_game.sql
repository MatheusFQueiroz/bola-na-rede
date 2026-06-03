CREATE TABLE IF NOT EXISTS "open_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" uuid DEFAULT gen_random_uuid() NOT NULL UNIQUE,
  "organizer_user_id" text NOT NULL,
  "field_id" text,
  "field_name_snapshot" text,
  "field_address_snapshot" text,
  "title" text NOT NULL,
  "description" text,
  "sport" text NOT NULL,
  "scheduled_at" timestamptz NOT NULL,
  "duration_minutes" smallint DEFAULT 60 NOT NULL,
  "min_players" smallint DEFAULT 10 NOT NULL,
  "max_players" smallint DEFAULT 22 NOT NULL,
  "price_per_player" numeric(10, 2),
  "status" text DEFAULT 'open' NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "game_participants" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" bigint NOT NULL REFERENCES "open_games"("id"),
  "player_user_id" text NOT NULL,
  "display_name" text NOT NULL,
  "position" text,
  "joined_at" timestamptz DEFAULT now() NOT NULL,
  "left_at" timestamptz
);

CREATE TABLE IF NOT EXISTS "player_stats" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" bigint NOT NULL REFERENCES "open_games"("id"),
  "player_user_id" text NOT NULL,
  "goals" smallint DEFAULT 0 NOT NULL,
  "assists" smallint DEFAULT 0 NOT NULL,
  "notes" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_player_stats_game_player" UNIQUE ("game_id", "player_user_id")
);

CREATE INDEX IF NOT EXISTS "idx_open_games_scheduled_at" ON "open_games" ("scheduled_at");
CREATE INDEX IF NOT EXISTS "idx_open_games_status" ON "open_games" ("status");
CREATE INDEX IF NOT EXISTS "idx_game_participants_player" ON "game_participants" ("player_user_id");
