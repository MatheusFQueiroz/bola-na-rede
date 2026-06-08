CREATE TABLE "player_rankings" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL,
  "sport" text NOT NULL,
  "games_played" integer DEFAULT 0 NOT NULL,
  "wins" integer DEFAULT 0 NOT NULL,
  "losses" integer DEFAULT 0 NOT NULL,
  "draws" integer DEFAULT 0 NOT NULL,
  "goals" integer DEFAULT 0 NOT NULL,
  "assists" integer DEFAULT 0 NOT NULL,
  "points" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "player_rankings_player_sport_unique" UNIQUE("player_user_id", "sport")
);

CREATE TABLE "ranking_processed_games" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "game_id" text NOT NULL,
  "processed_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "ranking_processed_games_game_id_unique" UNIQUE("game_id")
);

CREATE INDEX "idx_player_rankings_sport_points" ON "player_rankings" ("sport", "points" DESC);
CREATE INDEX "idx_player_rankings_player_user_id" ON "player_rankings" ("player_user_id");
