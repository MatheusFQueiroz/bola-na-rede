CREATE TABLE "competitive_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "match_id" text NOT NULL,
  "user_a_id" text NOT NULL,
  "user_b_id" text NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'scheduled' NOT NULL,
  "player_a_goals" integer DEFAULT 0 NOT NULL,
  "player_b_goals" integer DEFAULT 0 NOT NULL,
  "player_a_assists" integer DEFAULT 0 NOT NULL,
  "player_b_assists" integer DEFAULT 0 NOT NULL,
  "winner_id" text,
  "submitted_by_user_id" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "competitive_games_external_id_unique" UNIQUE("external_id"),
  CONSTRAINT "competitive_games_match_id_unique" UNIQUE("match_id")
);

CREATE INDEX "idx_competitive_games_user_a" ON "competitive_games" ("user_a_id");
CREATE INDEX "idx_competitive_games_user_b" ON "competitive_games" ("user_b_id");
CREATE INDEX "idx_competitive_games_status" ON "competitive_games" ("status");
