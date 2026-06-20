-- =============================================================================
-- BolaNaRede — Ranking Service Seed
-- Database: bolanarededb_ranking
--
-- Idempotent: ON CONFLICT (player_user_id, sport) DO UPDATE (upsert)
--
-- Stats derived from the 10 competitive games in 02_game.sql:
--
--  Game 1  (futsal):  001 3x1 002 — 001 wins
--  Game 2  (society): 003 2x2 004 — draw
--  Game 3  (futsal):  005 4x0 006 — 005 wins
--  Game 4  (campo):   007 1x2 008 — 008 wins
--  Game 5  (society): 001 2x3 005 — 005 wins
--  Game 6  (futsal):  004 1x0 006 — 004 wins
--  Game 7  (society): 002 2x2 003 — draw
--  Game 8  (futsal):  001 5x2 007 — 001 wins
--  Game 9  (campo):   005 3x3 004 — draw
--  Game 10 (society): 006 0x1 008 — 008 wins
--
-- Points rule: wins×3 + draws×1
-- =============================================================================

-- Mark processed games so ranking service does not re-process if it starts
-- ranking_processed_games: id (bigserial), game_id (text unique), processed_at
INSERT INTO ranking_processed_games (game_id)
VALUES
  ('c0000001-0000-0000-0000-000000000001'),
  ('c0000001-0000-0000-0000-000000000002'),
  ('c0000001-0000-0000-0000-000000000003'),
  ('c0000001-0000-0000-0000-000000000004'),
  ('c0000001-0000-0000-0000-000000000005'),
  ('c0000001-0000-0000-0000-000000000006'),
  ('c0000001-0000-0000-0000-000000000007'),
  ('c0000001-0000-0000-0000-000000000008'),
  ('c0000001-0000-0000-0000-000000000009'),
  ('c0000001-0000-0000-0000-000000000010')
ON CONFLICT (game_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- PLAYER RANKINGS
-- Columns: id (bigserial), player_user_id (text), display_name (text),
--          sport (text), games_played, wins, losses, draws,
--          goals, assists, points, updated_at
-- Unique: (player_user_id, sport)
-- -----------------------------------------------------------------------------

-- ── João Silva (001) ──────────────────────────────────────────────────────────
-- futsal:  G1 W(3g,2a), G8 W(5g,2a) → 2 games, 2W 0L 0D, 8g 4a, pts=6
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'João Silva', 'futsal', 2, 2, 0, 0, 8, 4, 6)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- society: G5 L(2g,1a) → 1 game, 0W 1L 0D, 2g 1a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'João Silva', 'society', 1, 0, 1, 0, 2, 1, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Carlos Souza (002) ────────────────────────────────────────────────────────
-- futsal: G1 L(1g,0a) → 1 game, 0W 1L 0D, 1g 0a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000002', 'Carlos Souza', 'futsal', 1, 0, 1, 0, 1, 0, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- society: G7 D(2g,1a) → 1 game, 0W 0L 1D, 2g 1a, pts=1
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000002', 'Carlos Souza', 'society', 1, 0, 0, 1, 2, 1, 1)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Pedro Alves (003) ─────────────────────────────────────────────────────────
-- society: G2 D(2g,1a), G7 D(2g,0a) → 2 games, 0W 0L 2D, 4g 1a, pts=2
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000003', 'Pedro Alves', 'society', 2, 0, 0, 2, 4, 1, 2)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Lucas Costa (004) ─────────────────────────────────────────────────────────
-- society: G2 D(2g,1a) → 1 game, 0W 0L 1D, 2g 1a, pts=1
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa', 'society', 1, 0, 0, 1, 2, 1, 1)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- futsal: G6 W(1g,0a) → 1 game, 1W 0L 0D, 1g 0a, pts=3
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa', 'futsal', 1, 1, 0, 0, 1, 0, 3)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- campo: G9 D(3g,2a) → 1 game, 0W 0L 1D, 3g 2a, pts=1
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa', 'campo', 1, 0, 0, 1, 3, 2, 1)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Rafael Lima (005) ─────────────────────────────────────────────────────────
-- futsal: G3 W(4g,1a) → 1 game, 1W 0L 0D, 4g 1a, pts=3
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'futsal', 1, 1, 0, 0, 4, 1, 3)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- society: G5 W(3g,2a) → 1 game, 1W 0L 0D, 3g 2a, pts=3
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'society', 1, 1, 0, 0, 3, 2, 3)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- campo: G9 D(3g,1a) → 1 game, 0W 0L 1D, 3g 1a, pts=1
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'campo', 1, 0, 0, 1, 3, 1, 1)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Bruno Martins (006) ───────────────────────────────────────────────────────
-- futsal: G3 L(0g,0a), G6 L(0g,0a) → 2 games, 0W 2L 0D, 0g 0a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins', 'futsal', 2, 0, 2, 0, 0, 0, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- society: G10 L(0g,0a) → 1 game, 0W 1L 0D, 0g 0a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins', 'society', 1, 0, 1, 0, 0, 0, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Felipe Rocha (007) ────────────────────────────────────────────────────────
-- campo: G4 L(1g,0a) → 1 game, 0W 1L 0D, 1g 0a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000007', 'Felipe Rocha', 'campo', 1, 0, 1, 0, 1, 0, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- futsal: G8 L(2g,1a) → 1 game, 0W 1L 0D, 2g 1a, pts=0
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000007', 'Felipe Rocha', 'futsal', 1, 0, 1, 0, 2, 1, 0)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- ── Matheus Oliveira (008) ────────────────────────────────────────────────────
-- campo: G4 W(2g,1a) → 1 game, 1W 0L 0D, 2g 1a, pts=3
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000008', 'Matheus Oliveira', 'campo', 1, 1, 0, 0, 2, 1, 3)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();

-- society: G10 W(1g,0a) → 1 game, 1W 0L 0D, 1g 0a, pts=3
INSERT INTO player_rankings
  (player_user_id, display_name, sport, games_played, wins, losses, draws, goals, assists, points)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000008', 'Matheus Oliveira', 'society', 1, 1, 0, 0, 1, 0, 3)
ON CONFLICT ON CONSTRAINT player_rankings_player_sport_unique
DO UPDATE SET
  display_name  = EXCLUDED.display_name,
  games_played  = EXCLUDED.games_played,
  wins          = EXCLUDED.wins,
  losses        = EXCLUDED.losses,
  draws         = EXCLUDED.draws,
  goals         = EXCLUDED.goals,
  assists       = EXCLUDED.assists,
  points        = EXCLUDED.points,
  updated_at    = NOW();
