-- =============================================================================
-- BolaNaRede — Identity Service Seed
-- Database: bolanarededb_identity
--
-- Idempotent: uses ON CONFLICT DO NOTHING / WHERE NOT EXISTS
-- Password hash: bcrypt of "senha123" (cost 10)
-- Pre-computed: $2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- =============================================================================

-- -----------------------------------------------------------------------------
-- USERS
-- Columns: id (bigserial), external_id (uuid unique), email (unique),
--          phone (unique), status, created_at, updated_at, deleted_at
-- -----------------------------------------------------------------------------
INSERT INTO users (external_id, email, phone, status)
VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'joao@bolanarede.com',    NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000002', 'carlos@bolanarede.com',  NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000003', 'pedro@bolanarede.com',   NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000004', 'lucas@bolanarede.com',   NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000005', 'rafael@bolanarede.com',  NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000006', 'bruno@bolanarede.com',   NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000007', 'felipe@bolanarede.com',  NULL, 'ACTIVE'),
  ('a1b2c3d4-0000-0000-0000-000000000008', 'matheus@bolanarede.com', NULL, 'ACTIVE')
ON CONFLICT (external_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- CREDENTIALS
-- Columns: id (bigserial), user_id (bigint FK → users.id), provider,
--          password_hash, created_at, updated_at
-- No unique constraint on (user_id, provider) — guard with WHERE NOT EXISTS.
-- Password: "senha123"
-- Hash: $2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- -----------------------------------------------------------------------------
INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000002'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000003'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000004'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000005'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000006'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000007'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

INSERT INTO credentials (user_id, provider, password_hash)
SELECT u.id, 'email', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM users u
WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000008'
  AND NOT EXISTS (
    SELECT 1 FROM credentials c
    WHERE c.user_id = u.id AND c.provider = 'email'
  );

-- -----------------------------------------------------------------------------
-- PLAYER PROFILES (identity service)
-- Columns: id (bigserial), user_id (bigint FK → users.id), display_name,
--          photo_url, bio, city, position, skill_level (smallint),
--          is_public, created_at, updated_at
-- skill_level: 1=iniciante, 2=intermediario, 3=avancado
-- Unique: unique index uq_player_profiles_user_id on (user_id)
--         — use ON CONFLICT (user_id) since it's an index, not a named constraint
-- -----------------------------------------------------------------------------
INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'João Silva',       'Curitiba', 'Atacante',  3, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000001'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Carlos Souza',     'Curitiba', 'Goleiro',   2, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000002'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Pedro Alves',      'Curitiba', 'Zagueiro',  2, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000003'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Lucas Costa',      'Curitiba', 'Lateral',   3, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000004'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Rafael Lima',      'Curitiba', 'Meia',      3, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000005'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Bruno Martins',    'Curitiba', 'Atacante',  2, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000006'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Felipe Rocha',     'Curitiba', 'Zagueiro',  2, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000007'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO player_profiles (user_id, display_name, city, position, skill_level, is_public)
SELECT u.id, 'Matheus Oliveira', 'Curitiba', 'Goleiro',   2, true
FROM users u WHERE u.external_id = 'a1b2c3d4-0000-0000-0000-000000000008'
ON CONFLICT (user_id) DO NOTHING;
