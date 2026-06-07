CREATE TABLE "player_profiles" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "display_name" text DEFAULT '' NOT NULL,
  "total_xp" integer DEFAULT 0 NOT NULL,
  "level" smallint DEFAULT 1 NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "player_profiles_player_user_id_unique" UNIQUE("player_user_id")
);

CREATE TABLE "xp_ledger" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "source_type" text NOT NULL,
  "source_id" text NOT NULL,
  "xp_earned" smallint NOT NULL,
  "reason" text NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_xp_ledger_player_source_reason" UNIQUE("player_user_id","source_id","reason")
);

CREATE TABLE "player_badges" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "badge_code" text NOT NULL,
  "earned_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_player_badge" UNIQUE("player_user_id","badge_code")
);
