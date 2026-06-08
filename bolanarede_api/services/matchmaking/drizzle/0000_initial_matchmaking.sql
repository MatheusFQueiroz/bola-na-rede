CREATE TABLE "match_requests" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "requester_user_id" text NOT NULL,
  "display_name" text DEFAULT '' NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'pending' NOT NULL,
  "requested_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "match_requests_external_id_unique" UNIQUE("external_id")
);

CREATE TABLE "pending_matches" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "external_id" text NOT NULL,
  "request_a_external_id" text NOT NULL,
  "request_b_external_id" text NOT NULL,
  "user_a_id" text NOT NULL,
  "user_b_id" text NOT NULL,
  "sport" text NOT NULL,
  "status" text DEFAULT 'proposed' NOT NULL,
  "accepted_by_a" boolean DEFAULT false NOT NULL,
  "accepted_by_b" boolean DEFAULT false NOT NULL,
  "proposed_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "updated_at" timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT "pending_matches_external_id_unique" UNIQUE("external_id")
);

CREATE INDEX "idx_match_requests_user_status" ON "match_requests" ("requester_user_id", "status");
CREATE INDEX "idx_match_requests_sport_status" ON "match_requests" ("sport", "status");
