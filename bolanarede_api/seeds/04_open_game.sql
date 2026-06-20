-- =============================================================================
-- BolaNaRede — Open Game Service Seed
-- Database: bolanarededb_open_game
--
-- Idempotency strategy:
--   open_games:       ON CONFLICT (external_id) DO NOTHING
--   game_participants: no unique constraint — guard with WHERE NOT EXISTS
--   player_stats:     ON CONFLICT ON CONSTRAINT uq_player_stats_game_player DO NOTHING
--
-- Tables:
--   open_games (id bigserial, external_id uuid unique, organizer_user_id text,
--               field_id text, field_name_snapshot text, field_address_snapshot text,
--               title text, description text, sport text, scheduled_at timestamptz,
--               duration_minutes smallint, min_players smallint, max_players smallint,
--               price_per_player numeric(10,2), status text, is_active bool,
--               created_at, updated_at)
--   game_participants (id bigserial, game_id bigint FK, player_user_id text,
--                      display_name text, position text, joined_at, left_at)
--   player_stats (id bigserial, game_id bigint FK, player_user_id text,
--                 goals smallint, assists smallint, notes text, created_at)
--                 unique: uq_player_stats_game_player (game_id, player_user_id)
--
-- status values (from schema default): 'open' | 'full' | 'in_progress' | 'finished' | 'cancelled'
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PELADA 1 — Futsal de Terça (open, futuro próximo)
-- Organizer: João Silva (001)
-- -----------------------------------------------------------------------------
INSERT INTO open_games
  (external_id, organizer_user_id, field_name_snapshot, field_address_snapshot,
   title, description, sport, scheduled_at, duration_minutes,
   min_players, max_players, price_per_player, status, is_active)
VALUES
  ('b0000001-0000-0000-0000-000000000001',
   'a1b2c3d4-0000-0000-0000-000000000001',
   'Arena Society Xaxim',
   'Rua das Araucárias, 450, Xaxim, Curitiba',
   'Pelada de Terça — Xaxim',
   'Futsal semanal no Xaxim. Grana pro lanche.',
   'futsal',
   NOW() + INTERVAL '2 days' + INTERVAL '19 hours',
   90, 8, 12, 10.00, 'open', true)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000001', 'João Silva', 'Atacante'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000001'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000002', 'Carlos Souza', 'Goleiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000002'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000003', 'Pedro Alves', 'Zagueiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000003'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa', 'Lateral'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000004'
      AND gp.left_at IS NULL
  );

-- -----------------------------------------------------------------------------
-- PELADA 2 — Society de Domingo (open, no fim de semana)
-- Organizer: Carlos Souza (002)
-- -----------------------------------------------------------------------------
INSERT INTO open_games
  (external_id, organizer_user_id, field_name_snapshot, field_address_snapshot,
   title, description, sport, scheduled_at, duration_minutes,
   min_players, max_players, price_per_player, status, is_active)
VALUES
  ('b0000001-0000-0000-0000-000000000002',
   'a1b2c3d4-0000-0000-0000-000000000002',
   'Campo do Zé',
   'Av. Pinheirinho, 200, Pinheirinho, Curitiba',
   'Pelada de Domingo — Vila',
   'Society todo domingo de manhã. Todos bem-vindos.',
   'society',
   NOW() + INTERVAL '5 days' + INTERVAL '10 hours',
   120, 10, 18, 8.00, 'open', true)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000002', 'Carlos Souza', 'Goleiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000002'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000002'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'Meia'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000002'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000005'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins', 'Atacante'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000002'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000006'
      AND gp.left_at IS NULL
  );

-- -----------------------------------------------------------------------------
-- PELADA 3 — Racha dos Dragões (open, sem campo definido)
-- Organizer: Rafael Lima (005)
-- -----------------------------------------------------------------------------
INSERT INTO open_games
  (external_id, organizer_user_id,
   title, description, sport, scheduled_at, duration_minutes,
   min_players, max_players, price_per_player, status, is_active)
VALUES
  ('b0000001-0000-0000-0000-000000000003',
   'a1b2c3d4-0000-0000-0000-000000000005',
   'Racha dos Dragões',
   'Campo 7 a 7 aberto. Quem chegar joga.',
   'campo',
   NOW() + INTERVAL '3 days' + INTERVAL '17 hours',
   90, 6, 14, 0.00, 'open', true)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'Meia'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000003'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000005'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000007', 'Felipe Rocha', 'Zagueiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000003'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000007'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000008', 'Matheus Oliveira', 'Goleiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000003'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000008'
      AND gp.left_at IS NULL
  );

-- -----------------------------------------------------------------------------
-- PELADA 4 — Futesal Society da Sexta (finished, com stats)
-- Organizer: Lucas Costa (004) — já aconteceu, com estatísticas registradas
-- -----------------------------------------------------------------------------
INSERT INTO open_games
  (external_id, organizer_user_id, field_name_snapshot, field_address_snapshot,
   title, description, sport, scheduled_at, duration_minutes,
   min_players, max_players, price_per_player, status, is_active)
VALUES
  ('b0000001-0000-0000-0000-000000000004',
   'a1b2c3d4-0000-0000-0000-000000000004',
   'Arena Society Xaxim',
   'Rua das Araucárias, 450, Xaxim, Curitiba',
   'Pelada da Sexta — Society',
   'Jogo semanal da galera do bairro.',
   'society',
   NOW() - INTERVAL '3 days' + INTERVAL '19 hours',
   90, 8, 14, 10.00, 'finished', true)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000001', 'João Silva', 'Atacante'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000001'
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000004', 'Lucas Costa', 'Lateral'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000004'
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000005', 'Rafael Lima', 'Meia'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000005'
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins', 'Atacante'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000006'
  );

-- Player stats for Pelada 4 (finished) — unique: uq_player_stats_game_player (game_id, player_user_id)
INSERT INTO player_stats (game_id, player_user_id, goals, assists)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000001', 2, 1
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
ON CONFLICT ON CONSTRAINT uq_player_stats_game_player DO NOTHING;

INSERT INTO player_stats (game_id, player_user_id, goals, assists)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000004', 1, 2
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
ON CONFLICT ON CONSTRAINT uq_player_stats_game_player DO NOTHING;

INSERT INTO player_stats (game_id, player_user_id, goals, assists)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000005', 3, 1
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
ON CONFLICT ON CONSTRAINT uq_player_stats_game_player DO NOTHING;

INSERT INTO player_stats (game_id, player_user_id, goals, assists)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000006', 0, 0
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000004'
ON CONFLICT ON CONSTRAINT uq_player_stats_game_player DO NOTHING;

-- -----------------------------------------------------------------------------
-- PELADA 5 — Futsal da Comunidade (open, com vagas limitadas)
-- Organizer: Bruno Martins (006)
-- -----------------------------------------------------------------------------
INSERT INTO open_games
  (external_id, organizer_user_id,
   title, description, sport, scheduled_at, duration_minutes,
   min_players, max_players, price_per_player, status, is_active)
VALUES
  ('b0000001-0000-0000-0000-000000000005',
   'a1b2c3d4-0000-0000-0000-000000000006',
   'Futsal da Comunidade — Sábado',
   'Pelada no CTG. Trazer chinelo reserva.',
   'futsal',
   NOW() + INTERVAL '8 days' + INTERVAL '15 hours',
   60, 6, 10, 5.00, 'open', true)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000006', 'Bruno Martins', 'Atacante'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000005'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000006'
      AND gp.left_at IS NULL
  );

INSERT INTO game_participants (game_id, player_user_id, display_name, position)
SELECT og.id, 'a1b2c3d4-0000-0000-0000-000000000003', 'Pedro Alves', 'Zagueiro'
FROM open_games og WHERE og.external_id = 'b0000001-0000-0000-0000-000000000005'
  AND NOT EXISTS (
    SELECT 1 FROM game_participants gp
    WHERE gp.game_id = og.id
      AND gp.player_user_id = 'a1b2c3d4-0000-0000-0000-000000000003'
      AND gp.left_at IS NULL
  );
