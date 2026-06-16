#!/usr/bin/env bash
# =============================================================================
# BolaNaRede — Seed Script
# Popula o banco de dados para desenvolvimento local.
#
# Pré-requisitos:
#   - docker compose up -d (todos os serviços rodando)
#   - curl e jq instalados
#
# Uso:
#   chmod +x seed.sh
#   ./seed.sh
# =============================================================================

set -euo pipefail

GATEWAY="http://localhost:3000"
FIELD_DB="bolanarededb_field"
FIELD_CONTAINER="bolanarede_api-field-1"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[seed]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
err()   { echo -e "${RED}[err]${NC}  $*"; exit 1; }

wait_for_gateway() {
  info "Aguardando gateway em $GATEWAY..."
  for i in $(seq 1 30); do
    if curl -sf "$GATEWAY/v1/open-games" > /dev/null 2>&1; then
      ok "Gateway acessível"
      return 0
    fi
    sleep 2
  done
  err "Gateway não respondeu após 60s. Verifique: docker compose up -d"
}

# =============================================================================
# 1. USUÁRIOS
# =============================================================================

register_user() {
  local name="$1" email="$2" password="$3"
  info "Registrando usuário: $name ($email)"
  local res
  res=$(curl -sf -X POST "$GATEWAY/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"displayName\":\"$name\",\"email\":\"$email\",\"password\":\"$password\"}" \
    2>&1 || true)

  if echo "$res" | jq -e '.accessToken' > /dev/null 2>&1; then
    echo "$res" | jq -r '.accessToken'
  else
    # Usuário já existe — faz login
    warn "  Usuário já existe, fazendo login..."
    curl -sf -X POST "$GATEWAY/v1/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$email\",\"password\":\"$password\"}" \
      | jq -r '.accessToken'
  fi
}

# =============================================================================
# 2. CAMPOS (via SQL direto — requer fields:write)
# =============================================================================

seed_fields() {
  info "Inserindo campos via SQL no container '$FIELD_CONTAINER'..."

  # Verifica se o container existe
  if ! docker ps --format '{{.Names}}' | grep -q "$FIELD_CONTAINER"; then
    warn "Container '$FIELD_CONTAINER' não encontrado. Tentando nome alternativo..."
    FIELD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i "field" | head -1 || true)
    if [ -z "$FIELD_CONTAINER" ]; then
      warn "Nenhum container de field encontrado. Pulando campos."
      FIELD1_ID=""
      FIELD2_ID=""
      return 0
    fi
    info "  Usando container: $FIELD_CONTAINER"
  fi

  FIELD1_ID=$(docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -tAq \
    -c "INSERT INTO fields (name, description, city, address, lat, lng, owner_user_id, is_active)
        VALUES ('Arena Society Xaxim', 'Quadras de society e futsal com vestiário', 'Curitiba', 'Rua das Araucárias, 450, Xaxim', -25.5108, -49.2647, 'seed-owner-1', true)
        ON CONFLICT DO NOTHING
        RETURNING external_id;" 2>/dev/null || true)

  if [ -z "$FIELD1_ID" ]; then
    FIELD1_ID=$(docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -tAq \
      -c "SELECT external_id FROM fields WHERE name='Arena Society Xaxim' LIMIT 1;" 2>/dev/null | tr -d '[:space:]')
  fi

  FIELD2_ID=$(docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -tAq \
    -c "INSERT INTO fields (name, description, city, address, lat, lng, owner_user_id, is_active)
        VALUES ('Campo do Zé', 'Campo society iluminado', 'Curitiba', 'Av. Pinheirinho, 200, Pinheirinho', -25.5342, -49.2987, 'seed-owner-1', true)
        ON CONFLICT DO NOTHING
        RETURNING external_id;" 2>/dev/null || true)

  if [ -z "$FIELD2_ID" ]; then
    FIELD2_ID=$(docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -tAq \
      -c "SELECT external_id FROM fields WHERE name='Campo do Zé' LIMIT 1;" 2>/dev/null | tr -d '[:space:]')
  fi

  # Quadras do campo 1
  if [ -n "$FIELD1_ID" ]; then
    docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -q \
      -c "INSERT INTO field_courts (field_id, name, type, max_players, is_active)
          SELECT f.id, 'Quadra Society A', 'society', 14, true FROM fields f WHERE f.external_id='$FIELD1_ID'
          ON CONFLICT DO NOTHING;
          INSERT INTO field_courts (field_id, name, type, max_players, is_active)
          SELECT f.id, 'Quadra Futsal B', 'futsal', 10, true FROM fields f WHERE f.external_id='$FIELD1_ID'
          ON CONFLICT DO NOTHING;" 2>/dev/null || true

    # Disponibilidade (seg-sex 18:00-22:00, sab-dom 08:00-22:00)
    COURT1_ID=$(docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -tAq \
      -c "SELECT external_id FROM field_courts WHERE name='Quadra Society A' LIMIT 1;" 2>/dev/null | tr -d '[:space:]')

    if [ -n "$COURT1_ID" ]; then
      for day in 1 2 3 4 5; do
        docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -q \
          -c "INSERT INTO availability_slots (court_id, day_of_week, start_time, end_time, is_available)
              SELECT c.id, $day, '18:00', '22:00', true FROM field_courts c WHERE c.external_id='$COURT1_ID'
              ON CONFLICT DO NOTHING;" 2>/dev/null || true
      done
      for day in 0 6; do
        docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -q \
          -c "INSERT INTO availability_slots (court_id, day_of_week, start_time, end_time, is_available)
              SELECT c.id, $day, '08:00', '22:00', true FROM field_courts c WHERE c.external_id='$COURT1_ID'
              ON CONFLICT DO NOTHING;" 2>/dev/null || true
      done
    fi
  fi

  # Quadra do campo 2
  if [ -n "$FIELD2_ID" ]; then
    docker exec "$FIELD_CONTAINER" psql -U postgres -d "$FIELD_DB" -q \
      -c "INSERT INTO field_courts (field_id, name, type, max_players, is_active)
          SELECT f.id, 'Campo Principal', 'society', 18, true FROM fields f WHERE f.external_id='$FIELD2_ID'
          ON CONFLICT DO NOTHING;" 2>/dev/null || true
  fi

  [ -n "$FIELD1_ID" ] && ok "Campo 1: $FIELD1_ID" || warn "Campo 1 não inserido"
  [ -n "$FIELD2_ID" ] && ok "Campo 2: $FIELD2_ID" || warn "Campo 2 não inserido"
}

# =============================================================================
# 3. TIMES
# =============================================================================

create_team() {
  local token="$1" name="$2" desc="$3"
  info "Criando time: $name"
  curl -sf -X POST "$GATEWAY/v1/teams" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "{\"name\":\"$name\",\"description\":\"$desc\",\"minPlayers\":5,\"maxPlayers\":14}" \
    | jq -r '.id // empty' 2>/dev/null || echo ""
}

join_team() {
  local token="$1" teamId="$2"
  curl -sf -X POST "$GATEWAY/v1/teams/$teamId/members" \
    -H "Authorization: Bearer $token" > /dev/null 2>&1 || true
}

# =============================================================================
# 4. PELADAS (Open Games)
# =============================================================================

create_open_game() {
  local token="$1" title="$2" sport="$3" scheduled="$4" fieldId="${5:-}"
  info "Criando pelada: $title"
  local body="{\"title\":\"$title\",\"sport\":\"$sport\",\"scheduledAt\":\"$scheduled\",\"durationMinutes\":90,\"minPlayers\":10,\"maxPlayers\":18}"
  if [ -n "$fieldId" ]; then
    body="{\"title\":\"$title\",\"sport\":\"$sport\",\"scheduledAt\":\"$scheduled\",\"durationMinutes\":90,\"minPlayers\":10,\"maxPlayers\":18,\"fieldId\":\"$fieldId\"}"
  fi
  curl -sf -X POST "$GATEWAY/v1/open-games" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "$body" \
    | jq -r '.id // empty' 2>/dev/null || echo ""
}

# =============================================================================
# 5. MATCH REQUESTS (Matchmaking)
# =============================================================================

create_match_request() {
  local token="$1" sport="$2"
  info "Criando match request: $sport"
  curl -sf -X POST "$GATEWAY/v1/match-requests" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "{\"sport\":\"$sport\"}" \
    | jq -r '.id // empty' 2>/dev/null || echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
  echo ""
  echo "======================================================"
  echo "  BolaNaRede — Seed Script"
  echo "======================================================"
  echo ""

  wait_for_gateway

  # --- Usuários ---
  echo ""
  info "=== USUÁRIOS ==="
  TOKEN1=$(register_user "Carlos Souza"  "carlos@seed.com"  "senha123")
  TOKEN2=$(register_user "André Lima"    "andre@seed.com"   "senha123")
  TOKEN3=$(register_user "Marcos Rocha"  "marcos@seed.com"  "senha123")

  [ -n "$TOKEN1" ] && ok "User 1 token obtido" || err "Falha ao obter token de user 1"
  [ -n "$TOKEN2" ] && ok "User 2 token obtido" || err "Falha ao obter token de user 2"
  [ -n "$TOKEN3" ] && ok "User 3 token obtido" || err "Falha ao obter token de user 3"

  # --- Campos ---
  echo ""
  info "=== CAMPOS ==="
  FIELD1_ID=""
  FIELD2_ID=""
  seed_fields

  # --- Times ---
  echo ""
  info "=== TIMES ==="
  TEAM1_ID=$(create_team "$TOKEN1" "Furacão FC" "Time de society do bairro Xaxim")
  TEAM2_ID=$(create_team "$TOKEN2" "União Vila" "Pelada da vila todo domingo")
  TEAM3_ID=$(create_team "$TOKEN3" "Dragões da ZL" "Somos da Zona Leste")

  [ -n "$TEAM1_ID" ] && ok "Time 1: $TEAM1_ID" || warn "Time 1 não criado (já existe?)"
  [ -n "$TEAM2_ID" ] && ok "Time 2: $TEAM2_ID" || warn "Time 2 não criado (já existe?)"
  [ -n "$TEAM3_ID" ] && ok "Time 3: $TEAM3_ID" || warn "Time 3 não criado (já existe?)"

  # Membros
  info "Adicionando membros aos times..."
  [ -n "$TEAM1_ID" ] && join_team "$TOKEN2" "$TEAM1_ID" && ok "André entrou no Furacão"  || true
  [ -n "$TEAM1_ID" ] && join_team "$TOKEN3" "$TEAM1_ID" && ok "Marcos entrou no Furacão" || true

  # --- Peladas ---
  echo ""
  info "=== PELADAS (Open Games) ==="
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  # Pelada em 2 dias
  GAME1_DATE=$(date -u -d "+2 days 19:00" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
               python3 -c "from datetime import datetime, timedelta; print((datetime.utcnow()+timedelta(days=2)).strftime('%Y-%m-%dT19:00:00Z'))" 2>/dev/null || \
               echo "2026-07-01T19:00:00Z")
  GAME2_DATE=$(date -u -d "+5 days 10:00" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
               python3 -c "from datetime import datetime, timedelta; print((datetime.utcnow()+timedelta(days=5)).strftime('%Y-%m-%dT10:00:00Z'))" 2>/dev/null || \
               echo "2026-07-04T10:00:00Z")

  GAME1_ID=$(create_open_game "$TOKEN1" "Pelada de Terça - Xaxim" "futsal" "$GAME1_DATE" "$FIELD1_ID")
  GAME2_ID=$(create_open_game "$TOKEN2" "Pelada de Domingo" "society" "$GAME2_DATE" "$FIELD2_ID")
  GAME3_ID=$(create_open_game "$TOKEN3" "Racha dos Dragões" "campo" "$GAME1_DATE" "")

  [ -n "$GAME1_ID" ] && ok "Pelada 1: $GAME1_ID" || warn "Pelada 1 não criada"
  [ -n "$GAME2_ID" ] && ok "Pelada 2: $GAME2_ID" || warn "Pelada 2 não criada"
  [ -n "$GAME3_ID" ] && ok "Pelada 3: $GAME3_ID" || warn "Pelada 3 não criada"

  # Entrar nas peladas
  if [ -n "$GAME1_ID" ]; then
    curl -sf -X POST "$GATEWAY/v1/open-games/$GAME1_ID/join" \
      -H "Authorization: Bearer $TOKEN2" > /dev/null 2>&1 && ok "André entrou na Pelada 1" || true
    curl -sf -X POST "$GATEWAY/v1/open-games/$GAME1_ID/join" \
      -H "Authorization: Bearer $TOKEN3" > /dev/null 2>&1 && ok "Marcos entrou na Pelada 1" || true
  fi

  # --- Match Requests ---
  echo ""
  info "=== MATCH REQUESTS (Matchmaking) ==="
  REQ1=$(create_match_request "$TOKEN1" "futsal")
  REQ2=$(create_match_request "$TOKEN2" "society")

  [ -n "$REQ1" ] && ok "Match request 1: $REQ1" || warn "Match request 1 não criada"
  [ -n "$REQ2" ] && ok "Match request 2: $REQ2" || warn "Match request 2 não criada"

  # --- Resumo ---
  echo ""
  echo "======================================================"
  echo -e "${GREEN}  Seed concluído!${NC}"
  echo "======================================================"
  echo ""
  echo "  Credenciais de teste:"
  echo "    carlos@seed.com  / senha123"
  echo "    andre@seed.com   / senha123"
  echo "    marcos@seed.com  / senha123"
  echo ""
  echo "  Abra o app e faça login com qualquer um desses emails."
  echo "======================================================"
  echo ""
}

main "$@"
