CREATE EXTENSION IF NOT EXISTS postgis;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "fields" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"city" text NOT NULL,
	"address" text NOT NULL,
	"lat" double precision NOT NULL,
	"lng" double precision NOT NULL,
	"owner_user_id" text NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "fields_external_id_unique" UNIQUE("external_id")
);
--> statement-breakpoint
ALTER TABLE "fields" ADD COLUMN IF NOT EXISTS "location" geometry(POINT,4326);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_fields_location" ON "fields" USING GIST ("location");
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "field_courts" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"field_id" bigint NOT NULL,
	"name" text NOT NULL,
	"type" text NOT NULL,
	"max_players" smallint DEFAULT 10 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "field_courts_external_id_unique" UNIQUE("external_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "availability_slots" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"court_id" bigint NOT NULL,
	"day_of_week" smallint NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL,
	"is_available" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "recurring_plans" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"court_id" bigint NOT NULL,
	"field_id" bigint NOT NULL,
	"player_user_id" text,
	"day_of_week" smallint NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL,
	"plan_starts_at" timestamp with time zone NOT NULL,
	"plan_ends_at" timestamp with time zone,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "recurring_plans_external_id_unique" UNIQUE("external_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "recurring_plan_slots" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"plan_id" bigint NOT NULL,
	"field_id" bigint NOT NULL,
	"slot_date" timestamp with time zone NOT NULL,
	"status" text DEFAULT 'active' NOT NULL,
	CONSTRAINT "recurring_plan_slots_external_id_unique" UNIQUE("external_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "reservations" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"external_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"court_id" bigint NOT NULL,
	"field_id" bigint NOT NULL,
	"player_user_id" text,
	"channel" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	"status" text DEFAULT 'confirmed' NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "reservations_external_id_unique" UNIQUE("external_id")
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "field_courts" ADD CONSTRAINT "field_courts_field_id_fields_id_fk" FOREIGN KEY ("field_id") REFERENCES "public"."fields"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "availability_slots" ADD CONSTRAINT "availability_slots_court_id_field_courts_id_fk" FOREIGN KEY ("court_id") REFERENCES "public"."field_courts"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "recurring_plans" ADD CONSTRAINT "recurring_plans_court_id_field_courts_id_fk" FOREIGN KEY ("court_id") REFERENCES "public"."field_courts"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "recurring_plans" ADD CONSTRAINT "recurring_plans_field_id_fields_id_fk" FOREIGN KEY ("field_id") REFERENCES "public"."fields"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "recurring_plan_slots" ADD CONSTRAINT "recurring_plan_slots_plan_id_recurring_plans_id_fk" FOREIGN KEY ("plan_id") REFERENCES "public"."recurring_plans"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "recurring_plan_slots" ADD CONSTRAINT "recurring_plan_slots_field_id_fields_id_fk" FOREIGN KEY ("field_id") REFERENCES "public"."fields"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "reservations" ADD CONSTRAINT "reservations_court_id_field_courts_id_fk" FOREIGN KEY ("court_id") REFERENCES "public"."field_courts"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "reservations" ADD CONSTRAINT "reservations_field_id_fields_id_fk" FOREIGN KEY ("field_id") REFERENCES "public"."fields"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_availability_slots_court_day" ON "availability_slots" USING btree ("court_id","day_of_week");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_recurring_plans_court_active" ON "recurring_plans" USING btree ("court_id","is_active");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_recurring_plan_slots_plan_date" ON "recurring_plan_slots" USING btree ("plan_id","slot_date");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_recurring_plan_slots_field_date" ON "recurring_plan_slots" USING btree ("field_id","slot_date");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reservations_court_status" ON "reservations" USING btree ("court_id","status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reservations_field_id" ON "reservations" USING btree ("field_id");
