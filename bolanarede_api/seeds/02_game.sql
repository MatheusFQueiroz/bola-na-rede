-- =============================================================================
-- BolaNaRede — Game Service Seed
-- Database: bolanarededb_game
--
-- Idempotent: ON CONFLICT (external_id) / ON CONFLICT (match_id) DO NOTHING
--
-- User UUID reference (from identity seed):
--   001 = João Silva      (Atacante, avancado)
--   002 = Carlos Souza    (Goleiro,  intermediario)
--   003 = Pedro Alves     (Zagueiro, intermediario)
--   004 = Lucas Costa     (Lateral,  avancado)
--   005 = Rafael Lima     (Meia,     avancado)
--   006 = Bruno Martins   (Atacante, intermediario)
--   007 = Felipe Rocha    (Zagueiro, intermediario)
--   008 = Matheus Oliveira(Goleiro,  intermediario)
--
-- Naming convention:
--   external_id = game UUID (exposed in API)
--   match_id    = matchmaking UUID (idempotency key from MATCH_ACCEPTED event)
--   user_a_id / user_b_id = identity external_id UUIDs (text columns, no FK)
--   winner_id = external_id of winner, NULL = draw
--   status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
-- =============================================================================

-- Game 1: João (001) 3x1 Carlos (002) — futsal — João wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000001',
   'match-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000002',
   'futsal', 'completed',
   3, 1, 2, 0,
   'a1b2c3d4-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000001')
ON CONFLICT (match_id) DO NOTHING;

-- Game 2: Pedro (003) 2x2 Lucas (004) — society — draw
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000002',
   'match-0000-0000-0000-000000000002',
   'a1b2c3d4-0000-0000-0000-000000000003',
   'a1b2c3d4-0000-0000-0000-000000000004',
   'society', 'completed',
   2, 2, 1, 1,
   NULL,
   'a1b2c3d4-0000-0000-0000-000000000003')
ON CONFLICT (match_id) DO NOTHING;

-- Game 3: Rafael (005) 4x0 Bruno (006) — futsal — Rafael wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000003',
   'match-0000-0000-0000-000000000003',
   'a1b2c3d4-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000006',
   'futsal', 'completed',
   4, 0, 1, 0,
   'a1b2c3d4-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000005')
ON CONFLICT (match_id) DO NOTHING;

-- Game 4: Felipe (007) 1x2 Matheus (008) — campo — Matheus wins (as GK scored from PK?)
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000004',
   'match-0000-0000-0000-000000000004',
   'a1b2c3d4-0000-0000-0000-000000000007',
   'a1b2c3d4-0000-0000-0000-000000000008',
   'campo', 'completed',
   1, 2, 0, 1,
   'a1b2c3d4-0000-0000-0000-000000000008',
   'a1b2c3d4-0000-0000-0000-000000000008')
ON CONFLICT (match_id) DO NOTHING;

-- Game 5: João (001) 2x3 Rafael (005) — society — Rafael wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000005',
   'match-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000005',
   'society', 'completed',
   2, 3, 1, 2,
   'a1b2c3d4-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000005')
ON CONFLICT (match_id) DO NOTHING;

-- Game 6: Lucas (004) 1x0 Bruno (006) — futsal — Lucas wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000006',
   'match-0000-0000-0000-000000000006',
   'a1b2c3d4-0000-0000-0000-000000000004',
   'a1b2c3d4-0000-0000-0000-000000000006',
   'futsal', 'completed',
   1, 0, 0, 0,
   'a1b2c3d4-0000-0000-0000-000000000004',
   'a1b2c3d4-0000-0000-0000-000000000004')
ON CONFLICT (match_id) DO NOTHING;

-- Game 7: Carlos (002) 2x2 Pedro (003) — society — draw
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000007',
   'match-0000-0000-0000-000000000007',
   'a1b2c3d4-0000-0000-0000-000000000002',
   'a1b2c3d4-0000-0000-0000-000000000003',
   'society', 'completed',
   2, 2, 1, 0,
   NULL,
   'a1b2c3d4-0000-0000-0000-000000000002')
ON CONFLICT (match_id) DO NOTHING;

-- Game 8: João (001) 5x2 Felipe (007) — futsal — João wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000008',
   'match-0000-0000-0000-000000000008',
   'a1b2c3d4-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000007',
   'futsal', 'completed',
   5, 2, 2, 1,
   'a1b2c3d4-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000001')
ON CONFLICT (match_id) DO NOTHING;

-- Game 9: Rafael (005) 3x3 Lucas (004) — campo — draw
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000009',
   'match-0000-0000-0000-000000000009',
   'a1b2c3d4-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000004',
   'campo', 'completed',
   3, 3, 1, 2,
   NULL,
   'a1b2c3d4-0000-0000-0000-000000000004')
ON CONFLICT (match_id) DO NOTHING;

-- Game 10: Bruno (006) 0x1 Matheus (008) — society — Matheus wins
INSERT INTO competitive_games
  (external_id, match_id, user_a_id, user_b_id, sport, status,
   player_a_goals, player_b_goals, player_a_assists, player_b_assists,
   winner_id, submitted_by_user_id)
VALUES
  ('c0000001-0000-0000-0000-000000000010',
   'match-0000-0000-0000-000000000010',
   'a1b2c3d4-0000-0000-0000-000000000006',
   'a1b2c3d4-0000-0000-0000-000000000008',
   'society', 'completed',
   0, 1, 0, 0,
   'a1b2c3d4-0000-0000-0000-000000000008',
   'a1b2c3d4-0000-0000-0000-000000000008')
ON CONFLICT (match_id) DO NOTHING;
