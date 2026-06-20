# BolaNaRede — SQL Seeds

Seed files for local development. All files are **idempotent** (`ON CONFLICT DO NOTHING` / `DO UPDATE`).
Run them in numbered order after `docker compose up -d` and migrations have been applied.

## Test credentials

All 8 seed users share the same password:

| Email                      | Name              | Password   |
|----------------------------|-------------------|------------|
| joao@bolanarede.com        | João Silva        | senha123   |
| carlos@bolanarede.com      | Carlos Souza      | senha123   |
| pedro@bolanarede.com       | Pedro Alves       | senha123   |
| lucas@bolanarede.com       | Lucas Costa       | senha123   |
| rafael@bolanarede.com      | Rafael Lima       | senha123   |
| bruno@bolanarede.com       | Bruno Martins     | senha123   |
| felipe@bolanarede.com      | Felipe Rocha      | senha123   |
| matheus@bolanarede.com     | Matheus Oliveira  | senha123   |

All users have external_id in the range `a1b2c3d4-0000-0000-0000-00000000000N` (N = 1–8).

## Running via Docker (recommended)

```bash
# From the bolanarede_api/ root:
docker exec -i bolanarede_api-postgres-identity-1  psql -U postgres -d bolanarededb_identity  < seeds/01_identity.sql
docker exec -i bolanarede_api-postgres-game-1       psql -U postgres -d bolanarededb_game       < seeds/02_game.sql
docker exec -i bolanarede_api-postgres-ranking-1    psql -U postgres -d bolanarededb_ranking    < seeds/03_ranking.sql
docker exec -i bolanarede_api-postgres-open-game-1  psql -U postgres -d bolanarededb_open_game  < seeds/04_open_game.sql
docker exec -i bolanarede_api-postgres-gamification-1 psql -U postgres -d bolanarededb_gamification < seeds/05_gamification.sql
```

## Running via local psql

```bash
psql -U postgres -d bolanarededb_identity    -f seeds/01_identity.sql
psql -U postgres -d bolanarededb_game        -f seeds/02_game.sql
psql -U postgres -d bolanarededb_ranking     -f seeds/03_ranking.sql
psql -U postgres -d bolanarededb_open_game   -f seeds/04_open_game.sql
psql -U postgres -d bolanarededb_gamification -f seeds/05_gamification.sql
```

## What each file contains

### 01_identity.sql — `bolanarededb_identity`
- 8 users with fixed UUIDs
- 8 credentials with bcrypt hash of "senha123"
- 8 player profiles (city=Curitiba, mixed positions and skill levels)

### 02_game.sql — `bolanarededb_game`
- 10 completed competitive games across futsal, society and campo
- Mix of wins and draws
- Goals/assists registered for each player side

### 03_ranking.sql — `bolanarededb_ranking`
- `ranking_processed_games` entries to prevent double-processing by the ranking service
- `player_rankings` rows aggregating the 10 games from seed 02 (per-sport rows)
- Points: wins×3 + draws×1

### 04_open_game.sql — `bolanarededb_open_game`
- 5 peladas: 3 future/open, 1 finished (with player_stats), 1 future
- `game_participants` for each pelada
- `player_stats` for the finished pelada (Pelada 4)

### 05_gamification.sql — `bolanarededb_gamification`
- `player_profiles` with XP and levels consistent with open game history
  - Rafael Lima: 212 XP → level 3 (top scorer)
  - João Silva: 184 XP → level 2
  - Lucas Costa: 93 XP → level 1
  - Others: 10–20 XP → level 1
- `xp_ledger` entries (idempotency source: open game IDs)
- `player_badges`: first-game for all; goal-scorer for João, Lucas, Rafael

## Notes

- Seeds do **not** touch: field service, social service, matchmaking service or notification service.
  Those services are either seeded via `seed.sh` (HTTP API calls) or do not need pre-populated data.
- The bcrypt hash `$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy` is the
  well-known bcrypt cost-10 hash of the string `senha123`.
- XP ledger "historical" source IDs use the pattern `b0000001-ffff-0000-0000-0000000000NN`
  (not real open_games rows) so they never collide with actual game data.
