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

set -uo pipefail

GATEWAY="http://localhost:3000"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[seed]${NC} $*" >&2; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*" >&2; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*" >&2; }
err()   { echo -e "${RED}[err]${NC}  $*" >&2; exit 1; }

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
# 2. CAMPOS (via API — dono autenticado)
# =============================================================================

seed_field_owner() {
  info "Registrando dono de campo: Zé do Campo (dono@bolanarede.com)"
  TOKEN_DONO=$(register_user "Zé do Campo" "dono@bolanarede.com" "senha123")
  [ -n "$TOKEN_DONO" ] && ok "Dono token obtido" || { warn "Dono token não obtido. Pulando campos."; return 0; }

  # Campo 1
  info "Criando campo: Arena Society Xaxim"
  local resp1
  resp1=$(curl -sf -X POST "$GATEWAY/v1/fields" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_DONO" \
    -d '{"name":"Arena Society Xaxim","description":"Quadras de society e futsal com vestiário","city":"Curitiba","address":"Rua das Araucárias, 450, Xaxim","lat":-25.5108,"lng":-49.2647}' \
    2>/dev/null || true)
  FIELD1_ID=$(echo "$resp1" | jq -r '.data.id // .id // empty' 2>/dev/null || true)

  if [ -z "$FIELD1_ID" ]; then
    warn "Campo 1 não criado (já existe? Tentando buscar...)"
    # If already exists, can't easily get by name via API — skip courts for this field
  else
    ok "Campo 1: $FIELD1_ID"

    # Quadra 1A
    info "  Criando quadra: Quadra Society A"
    local cr1a
    cr1a=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD1_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Quadra Society A","type":"society","maxPlayers":14}' \
      2>/dev/null || true)
    COURT1A_ID=$(echo "$cr1a" | jq -r '.data.id // .id // empty' 2>/dev/null || true)

    if [ -n "$COURT1A_ID" ]; then
      ok "  Quadra 1A: $COURT1A_ID"
      # Disponibilidade: seg-sex 18:00-22:00, sab-dom 08:00-22:00
      info "  Definindo disponibilidade..."
      curl -sf -X PUT "$GATEWAY/v1/fields/$FIELD1_ID/courts/$COURT1A_ID/availability" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN_DONO" \
        -d '{"slots":[
          {"dayOfWeek":1,"startTime":"18:00","endTime":"19:00","isAvailable":true},
          {"dayOfWeek":1,"startTime":"19:00","endTime":"20:00","isAvailable":true},
          {"dayOfWeek":1,"startTime":"20:00","endTime":"21:00","isAvailable":true},
          {"dayOfWeek":1,"startTime":"21:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"18:00","endTime":"19:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"19:00","endTime":"20:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"20:00","endTime":"21:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"21:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"18:00","endTime":"19:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"19:00","endTime":"20:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"20:00","endTime":"21:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"21:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"18:00","endTime":"19:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"19:00","endTime":"20:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"20:00","endTime":"21:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"21:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"18:00","endTime":"19:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"19:00","endTime":"20:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"20:00","endTime":"21:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"21:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"08:00","endTime":"09:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"09:00","endTime":"10:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"10:00","endTime":"11:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"11:00","endTime":"12:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"12:00","endTime":"13:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"08:00","endTime":"09:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"09:00","endTime":"10:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"10:00","endTime":"11:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"11:00","endTime":"12:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"12:00","endTime":"13:00","isAvailable":true}
        ]}' > /dev/null 2>&1 && ok "  Disponibilidade definida" || warn "  Disponibilidade não definida"
    fi

    # Quadra 1B
    info "  Criando quadra: Quadra Futsal B"
    local cr1b
    cr1b=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD1_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Quadra Futsal B","type":"futsal","maxPlayers":10}' \
      2>/dev/null || true)
    COURT1B_ID=$(echo "$cr1b" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    [ -n "$COURT1B_ID" ] && ok "  Quadra 1B: $COURT1B_ID" || warn "  Quadra 1B não criada"
  fi

  # Campo 2
  info "Criando campo: Campo do Zé"
  local resp2
  resp2=$(curl -sf -X POST "$GATEWAY/v1/fields" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_DONO" \
    -d '{"name":"Campo do Zé","description":"Campo society iluminado","city":"Curitiba","address":"Av. Pinheirinho, 200, Pinheirinho","lat":-25.5342,"lng":-49.2987}' \
    2>/dev/null || true)
  FIELD2_ID=$(echo "$resp2" | jq -r '.data.id // .id // empty' 2>/dev/null || true)

  if [ -n "$FIELD2_ID" ]; then
    ok "Campo 2: $FIELD2_ID"

    info "  Criando quadra: Campo Principal"
    local cr2
    cr2=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD2_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Campo Principal","type":"society","maxPlayers":18}' \
      2>/dev/null || true)
    COURT2_ID=$(echo "$cr2" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    [ -n "$COURT2_ID" ] && ok "  Campo Principal: $COURT2_ID" || warn "  Campo Principal não criado"
  else
    warn "Campo 2 não criado"
  fi
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
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo ""
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
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo ""
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
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo ""
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
  TOKEN_DONO=""
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
  seed_field_owner

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
  echo ""
  echo "  === DONO DE CAMPO ==="
  echo "    dono@bolanarede.com  / senha123  → Dashboard web"
  echo ""
  echo "  === JOGADORES (app mobile) ==="
  echo "    carlos@seed.com  / senha123"
  echo "    andre@seed.com   / senha123"
  echo "    marcos@seed.com  / senha123"
  echo ""
  echo "  Abra o app e faça login com qualquer um desses emails."
  echo "======================================================"
  echo ""
}

main "$@"
