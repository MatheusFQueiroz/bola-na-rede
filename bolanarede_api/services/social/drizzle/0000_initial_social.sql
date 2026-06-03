CREATE TABLE IF NOT EXISTS "player_reviews" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" uuid DEFAULT gen_random_uuid() NOT NULL UNIQUE,
  "game_id" text NOT NULL,
  "game_type" text NOT NULL,
  "reviewer_user_id" text NOT NULL,
  "reviewer_display_name" text NOT NULL,
  "reviewee_user_id" text NOT NULL,
  "reviewee_display_name" text NOT NULL,
  "score" smallint NOT NULL,
  "comment" text,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "uq_review_reviewer_game" UNIQUE ("reviewer_user_id", "game_id")
);

CREATE TABLE IF NOT EXISTS "player_scores" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "player_user_id" text NOT NULL UNIQUE,
  "display_name" text NOT NULL,
  "total_reviews" integer DEFAULT 0 NOT NULL,
  "average_score" numeric(3, 2) DEFAULT '0.00' NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_player_reviews_reviewee" ON "player_reviews" ("reviewee_user_id");
CREATE INDEX IF NOT EXISTS "idx_player_reviews_reviewer" ON "player_reviews" ("reviewer_user_id");
CREATE INDEX IF NOT EXISTS "idx_player_reviews_game" ON "player_reviews" ("game_id");
