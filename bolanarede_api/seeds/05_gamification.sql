-- =============================================================================
-- BolaNaRede — Gamification Service Seed
-- Database: bolanarededb_gamification
--
-- Idempotent:
--   player_profiles: ON CONFLICT (player_user_id) DO UPDATE
--   xp_ledger:       ON CONFLICT (player_user_id, source_id, reason) DO NOTHING
--   player_badges:   ON CONFLICT (player_user_id, badge_code) DO NOTHING
--
-- Level formula (from drizzle-profile.repository.ts):
--   level = floor(total_xp / 100) + 1
--
-- XP rules (from xp.service.ts):
--   participation: +10 per open game
--   goal:          +5  per goal scored in open game
--   assist:        +3  per assist in open game
--
-- Badge codes: 'first-game', 'goal-scorer', 'level-5', 'level-10'
--
-- Source games used:
--   Pelada 4 (finished): b0000001-0000-0000-0000-000000000004
--     001: 2g,1a → 10+10+3 = 23 XP
--     004: 1g,2a → 10+5+6  = 21 XP
--     005: 3g,1a → 10+15+3 = 28 XP
--     006: 0g,0a → 10      = 10 XP
--
--   Historical peladas (b0000001-ffff-0000-0000-0000000000XX) to enrich levels:
--     001: played 7 historical games (avg 3g,1a each) → +161 XP extra → total ~184, level 2
--     005: played 8 historical games (avg 3g,2a each) → +184 XP extra → total ~212, level 3
--     004: played 4 historical games (avg 1g,1a each) → +72 XP extra  → total ~93, level 1
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PLAYER PROFILES (gamification)
-- Columns: id, player_user_id (unique), display_name, total_xp, level, updated_at
-- -----------------------------------------------------------------------------
INSERT INTO player_profiles (player_user_id, display_name, total_xp, level)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'João Silva',       184, 2),
  ('a1b2c3d4-0000-0000-0000-000000000002', 'Carlos Souza',      10, 1),
  ('a1b2c3d4-0000-0000-0000-000000000003', 'Pedro Alves',       20, 1),
  ('a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa',       93, 1),
  ('a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima',      212, 3),
  ('a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins',     10, 1),
  ('a1b2c3d4-0000-0000-0000-000000000007', 'Felipe Rocha',      10, 1),
  ('a1b2c3d4-0000-0000-0000-000000000008', 'Matheus Oliveira',  10, 1)
ON CONFLICT (player_user_id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  total_xp     = EXCLUDED.total_xp,
  level        = EXCLUDED.level,
  updated_at   = NOW();

-- -----------------------------------------------------------------------------
-- XP LEDGER
-- Columns: id, player_user_id, source_type, source_id, xp_earned (smallint),
--          reason, created_at
-- Unique: (player_user_id, source_id, reason)
-- -----------------------------------------------------------------------------

-- ── Pelada 4 (b0000001-0000-0000-0000-000000000004) — finished ────────────────
-- João Silva (001): 10 participation + 10 goals (2×5) + 3 assist (1×3)
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 10, 'goal')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 3, 'assist')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Lucas Costa (004): 10 participation + 5 goal (1×5) + 6 assists (2×3)
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 5, 'goal')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 6, 'assist')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Rafael Lima (005): 10 participation + 15 goals (3×5) + 3 assist (1×3)
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 15, 'goal')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 3, 'assist')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Bruno Martins (006): 10 participation only
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000006', 'open-game',
        'b0000001-0000-0000-0000-000000000004', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- ── Historical peladas — João Silva (001) ─────────────────────────────────────
-- 7 historical games, avg 3g/1a each → 10+15+3 = 28 XP per game → 196 XP
-- We already have 23 from Pelada 4; to reach total_xp=184 we add 161 across 7 games.
-- Rounding: 5 games at 25 XP (2g,1a: 10+10+3=23) + 2 at 31 XP (3g,2a: 10+15+6=31)
-- = 5×23 + 2×31 = 115+62 = 177 → plus 23 from P4 = 200 → too much.
-- Let's do: 6 games at 10+10+3=23 XP each (2g,1a) = 138 → +23 from P4 = 161 → 23 short.
-- Adjust: add 1 game at 10+15+3=28 (3g,1a) + 5 at 10+10+3=23 = 28+115=143 → +23=166. Still a bit off.
-- Simplify: just emit 7 entries each 23 XP; total from history = 161 → +23 = 184. Done.
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000001', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000002', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000003', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000004', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000005', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000006', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'open-game',
        'b0000001-ffff-0000-0000-000000000007', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- ── Historical peladas — Rafael Lima (005) ────────────────────────────────────
-- 8 historical games at 23 XP each = 184 → +28 from P4 = 212 → level 3 (floor(212/100)+1=3). Correct.
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000011', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000012', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000013', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000014', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000015', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000016', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000017', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'open-game',
        'b0000001-ffff-0000-0000-000000000018', 23, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- ── Historical peladas — Lucas Costa (004) ────────────────────────────────────
-- 4 historical games at 18 XP (1g,1a: 10+5+3=18) each = 72 → +21 from P4 = 93 → level 1. Correct.
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-ffff-0000-0000-000000000021', 18, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-ffff-0000-0000-000000000022', 18, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-ffff-0000-0000-000000000023', 18, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'open-game',
        'b0000001-ffff-0000-0000-000000000024', 18, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- ── Carlos Souza (002) — first game participation only ────────────────────────
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000002', 'open-game',
        'b0000001-ffff-0000-0000-000000000031', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Pedro Alves (003) — 2 participations
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000003', 'open-game',
        'b0000001-ffff-0000-0000-000000000041', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000003', 'open-game',
        'b0000001-ffff-0000-0000-000000000042', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Felipe Rocha (007) — 1 participation
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000007', 'open-game',
        'b0000001-ffff-0000-0000-000000000051', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- Matheus Oliveira (008) — 1 participation
INSERT INTO xp_ledger (player_user_id, source_type, source_id, xp_earned, reason)
VALUES ('a1b2c3d4-0000-0000-0000-000000000008', 'open-game',
        'b0000001-ffff-0000-0000-000000000061', 10, 'participation')
ON CONFLICT ON CONSTRAINT uq_xp_ledger_player_source_reason DO NOTHING;

-- -----------------------------------------------------------------------------
-- PLAYER BADGES
-- Columns: id, player_user_id, badge_code, earned_at
-- Unique: (player_user_id, badge_code)
-- Badge codes: 'first-game', 'goal-scorer', 'level-5', 'level-10'
-- -----------------------------------------------------------------------------

-- João Silva (001): first-game + goal-scorer (scored in Pelada 4)
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'goal-scorer')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Carlos Souza (002): first-game
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000002', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Pedro Alves (003): first-game
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000003', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Lucas Costa (004): first-game + goal-scorer
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000004', 'goal-scorer')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Rafael Lima (005): first-game + goal-scorer (most XP — level 3)
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000005', 'goal-scorer')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Bruno Martins (006): first-game
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000006', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Felipe Rocha (007): first-game
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000007', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;

-- Matheus Oliveira (008): first-game
INSERT INTO player_badges (player_user_id, badge_code)
VALUES ('a1b2c3d4-0000-0000-0000-000000000008', 'first-game')
ON CONFLICT ON CONSTRAINT uq_player_badge DO NOTHING;
