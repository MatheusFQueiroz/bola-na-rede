#!/usr/bin/env bash
# =============================================================================
# BolaNaRede — Seed Script v2
# Dados realistas com relacionamentos consistentes entre usuários.
#
# Uso:  chmod +x seed.sh && ./seed.sh
# Pré:  docker compose up -d (todos os serviços rodando)
# =============================================================================

set -uo pipefail

GATEWAY="http://localhost:3000"

DB_IDENTITY="bolanarede_api-postgres-identity-1"
DB_FIELD="bolanarede_api-postgres-field-1"
DB_TEAM="bolanarede_api-postgres-team-1"
DB_OPENGAME="bolanarede_api-postgres-open-game-1"
DB_SOCIAL="bolanarede_api-postgres-social-1"
DB_MATCHMAKING="bolanarede_api-postgres-matchmaking-1"
DB_RANKING="bolanarede_api-postgres-ranking-1"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[seed]${NC} $*" >&2; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*" >&2; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*" >&2; }
err()   { echo -e "${RED}[err]${NC}  $*" >&2; exit 1; }

# =============================================================================
# 0. TRUNCAR TODOS OS BANCOS
# =============================================================================

truncate_all() {
  info "Truncando bancos de dados..."

  docker exec "$DB_FIELD" psql -U postgres -d bolanarededb_field -c \
    "TRUNCATE reservations, recurring_plan_slots, recurring_plans, availability_slots, field_courts, fields CASCADE;" \
    > /dev/null 2>&1 && ok "field-db truncado" || warn "field-db: truncate falhou"

  docker exec "$DB_TEAM" psql -U postgres -d bolanarededb_team -c \
    "TRUNCATE team_members, teams CASCADE;" \
    > /dev/null 2>&1 && ok "team-db truncado" || warn "team-db: truncate falhou"

  docker exec "$DB_OPENGAME" psql -U postgres -d bolanarededb_open_game -c \
    "TRUNCATE game_participants, player_stats, open_games CASCADE;" \
    > /dev/null 2>&1 && ok "open-game-db truncado" || warn "open-game-db: truncate falhou"

  docker exec "$DB_SOCIAL" psql -U postgres -d bolanarededb_social -c \
    "TRUNCATE player_reviews, player_scores CASCADE;" \
    > /dev/null 2>&1 && ok "social-db truncado" || warn "social-db: truncate falhou"

  docker exec "$DB_MATCHMAKING" psql -U postgres -d bolanarededb_matchmaking -c \
    "TRUNCATE pending_matches, match_requests CASCADE;" \
    > /dev/null 2>&1 && ok "matchmaking-db truncado" || warn "matchmaking-db: truncate falhou"

  docker exec "$DB_RANKING" psql -U postgres -d bolanarededb_ranking -c \
    "TRUNCATE ranking_processed_games, player_rankings CASCADE;" \
    > /dev/null 2>&1 && ok "ranking-db truncado" || warn "ranking-db: truncate falhou"

  docker exec "$DB_IDENTITY" psql -U postgres -d bolanarededb_identity -c \
    "TRUNCATE device_tokens, player_profiles, credentials, users CASCADE;" \
    > /dev/null 2>&1 && ok "identity-db truncado" || warn "identity-db: truncate falhou"
}

# =============================================================================
# 1. AGUARDAR GATEWAY
# =============================================================================

wait_for_gateway() {
  info "Aguardando gateway em $GATEWAY..."
  for i in $(seq 1 30); do
    if curl -sf "$GATEWAY/v1/open-games" > /dev/null 2>&1; then
      ok "Gateway acessivel"
      return 0
    fi
    sleep 2
  done
  err "Gateway nao respondeu apos 60s. Verifique: docker compose up -d"
}

# =============================================================================
# 2. USUARIOS
# =============================================================================

register_user() {
  local name="$1" email="$2" password="$3" phone="${4:-}"
  info "Registrando: $name ($email)"
  local tmp res
  tmp=$(mktemp)
  if [ -n "$phone" ]; then
    jq -cn --arg n "$name" --arg e "$email" --arg p "$password" --arg ph "$phone" \
      '{displayName:$n,email:$e,password:$p,phone:$ph}' > "$tmp"
  else
    jq -cn --arg n "$name" --arg e "$email" --arg p "$password" \
      '{displayName:$n,email:$e,password:$p}' > "$tmp"
  fi
  res=$(curl -sf -X POST "$GATEWAY/v1/auth/register" \
    -H "Content-Type: application/json" \
    --data-binary "@$tmp" 2>&1 || true)
  rm -f "$tmp"

  if echo "$res" | jq -e '.accessToken' > /dev/null 2>&1; then
    echo "$res" | jq -r '.accessToken'
  else
    warn "  $name ja existe, fazendo login..."
    local ltmp
    ltmp=$(mktemp)
    jq -cn --arg e "$email" --arg p "$password" '{email:$e,password:$p}' > "$ltmp"
    local tok
    tok=$(curl -sf -X POST "$GATEWAY/v1/auth/login" \
      -H "Content-Type: application/json" \
      --data-binary "@$ltmp" 2>/dev/null | jq -r '.accessToken // empty')
    rm -f "$ltmp"
    echo "$tok"
  fi
}

update_profile() {
  local token="$1" city="$2" position="$3" skill="$4" bio="$5"
  curl -sf -X PUT "$GATEWAY/v1/users/me/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "{\"city\":\"$city\",\"position\":\"$position\",\"skillLevel\":$skill,\"bio\":\"$bio\",\"isPublic\":true}" \
    > /dev/null 2>&1 || true
}

# =============================================================================
# 3. TIMES
# =============================================================================

create_team() {
  local token="$1" name="$2" desc="$3"
  local tmp id
  tmp=$(mktemp)
  jq -cn --arg n "$name" --arg d "$desc" \
    '{name:$n,description:$d}' > "$tmp"
  id=$(curl -sf -X POST "$GATEWAY/v1/teams" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    --data-binary "@$tmp" 2>/dev/null \
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo "")
  rm -f "$tmp"
  echo "$id"
}

join_team() {
  local token="$1" teamId="$2"
  curl -sf -X POST "$GATEWAY/v1/teams/$teamId/join" \
    -H "Authorization: Bearer $token" > /dev/null 2>&1 || true
}

# =============================================================================
# 4. CAMPOS, QUADRAS, DISPONIBILIDADE E RESERVAS
# =============================================================================

seed_campos() {
  info "Registrando dono: Ze do Campo (dono@bolanarede.com)"
  TOKEN_DONO=$(register_user "Ze do Campo" "dono@bolanarede.com" "senha123" "(41) 99999-0000")
  [ -n "$TOKEN_DONO" ] && ok "Token dono obtido" || { warn "Token dono nao obtido. Pulando campos."; return 0; }

  # ── Campo 1 — Arena Society Xaxim ────────────────────────────────────────
  info "Criando campo 1: Arena Society Xaxim"
  local tmp1 resp1
  tmp1=$(mktemp)
  jq -cn '{
    name: "Arena Society Xaxim",
    description: "Quadras de society e futsal com vestiario e iluminacao",
    city: "Curitiba",
    address: "Rua das Araucarias, 450, Xaxim, Curitiba - PR",
    lat: -25.5108,
    lng: -49.2647
  }' > "$tmp1"
  resp1=$(curl -sf -X POST "$GATEWAY/v1/fields" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_DONO" \
    --data-binary "@$tmp1" 2>/dev/null || true)
  rm -f "$tmp1"
  FIELD1_ID=$(echo "$resp1" | jq -r '.data.id // .id // empty' 2>/dev/null || true)

  if [ -n "$FIELD1_ID" ]; then
    ok "Campo 1: $FIELD1_ID"

    # Quadra 1A — Society
    local cr1a
    cr1a=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD1_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Quadra Society A","type":"society","maxPlayers":14,"pricePerHour":120}' 2>/dev/null || true)
    COURT1A_ID=$(echo "$cr1a" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    if [ -n "$COURT1A_ID" ]; then
      ok "  Quadra Society A: $COURT1A_ID"
      curl -sf -X PUT "$GATEWAY/v1/fields/$FIELD1_ID/courts/$COURT1A_ID/availability" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN_DONO" \
        -d '{"slots":[
          {"dayOfWeek":1,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"08:00","endTime":"22:00","isAvailable":true}
        ]}' > /dev/null 2>&1 && ok "  Disponibilidade Society A definida" || warn "  Disponibilidade Society A falhou"
    fi

    # Quadra 1B — Futsal
    local cr1b
    cr1b=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD1_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Quadra Futsal B","type":"futsal","maxPlayers":10,"pricePerHour":90}' 2>/dev/null || true)
    COURT1B_ID=$(echo "$cr1b" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    if [ -n "$COURT1B_ID" ]; then
      ok "  Quadra Futsal B: $COURT1B_ID"
      curl -sf -X PUT "$GATEWAY/v1/fields/$FIELD1_ID/courts/$COURT1B_ID/availability" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN_DONO" \
        -d '{"slots":[
          {"dayOfWeek":1,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"18:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"08:00","endTime":"22:00","isAvailable":true}
        ]}' > /dev/null 2>&1 && ok "  Disponibilidade Futsal B definida" || warn "  Disponibilidade Futsal B falhou"
    fi
  else
    warn "Campo 1 nao criado"
  fi

  # ── Campo 2 — Campo do Ze ─────────────────────────────────────────────────
  info "Criando campo 2: Campo do Ze"
  local tmp2 resp2
  tmp2=$(mktemp)
  jq -cn '{
    name: "Campo do Ze",
    description: "Campo society iluminado com estacionamento amplo",
    city: "Curitiba",
    address: "Av. Pinheirinho, 200, Pinheirinho, Curitiba - PR",
    lat: -25.5342,
    lng: -49.2987
  }' > "$tmp2"
  resp2=$(curl -sf -X POST "$GATEWAY/v1/fields" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_DONO" \
    --data-binary "@$tmp2" 2>/dev/null || true)
  rm -f "$tmp2"
  FIELD2_ID=$(echo "$resp2" | jq -r '.data.id // .id // empty' 2>/dev/null || true)

  if [ -n "$FIELD2_ID" ]; then
    ok "Campo 2: $FIELD2_ID"
    local cr2
    cr2=$(curl -sf -X POST "$GATEWAY/v1/fields/$FIELD2_ID/courts" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_DONO" \
      -d '{"name":"Campo Principal","type":"society","maxPlayers":18,"pricePerHour":100}' 2>/dev/null || true)
    COURT2_ID=$(echo "$cr2" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    if [ -n "$COURT2_ID" ]; then
      ok "  Campo Principal: $COURT2_ID"
      curl -sf -X PUT "$GATEWAY/v1/fields/$FIELD2_ID/courts/$COURT2_ID/availability" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN_DONO" \
        -d '{"slots":[
          {"dayOfWeek":1,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":2,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":3,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":4,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":5,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":6,"startTime":"08:00","endTime":"22:00","isAvailable":true},
          {"dayOfWeek":0,"startTime":"08:00","endTime":"22:00","isAvailable":true}
        ]}' > /dev/null 2>&1 && ok "  Disponibilidade Campo Principal definida" || warn "  Disponibilidade Campo Principal falhou"
    fi
  else
    warn "Campo 2 nao criado"
  fi

  # ── Reservas ──────────────────────────────────────────────────────────────
  if [ -n "$FIELD1_ID" ] && [ -n "${COURT1A_ID:-}" ]; then
    seed_reservas_campo1
  fi
  if [ -n "$FIELD2_ID" ] && [ -n "${COURT2_ID:-}" ]; then
    seed_reservas_campo2
  fi
}

create_reservation() {
  local token="$1" fieldId="$2" courtId="$3" startsAt="$4" endsAt="$5" channel="$6" status="${7:-confirmed}"
  local tmp res resId
  tmp=$(mktemp)
  jq -cn --arg c "$courtId" --arg s "$startsAt" --arg e "$endsAt" --arg ch "$channel" \
    '{courtId:$c,startsAt:$s,endsAt:$e,channel:$ch}' > "$tmp"
  res=$(curl -sf -X POST "$GATEWAY/v1/fields/$fieldId/reservations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    --data-binary "@$tmp" 2>/dev/null || true)
  rm -f "$tmp"

  if [ "$status" = "cancelled" ]; then
    resId=$(echo "$res" | jq -r '.data.id // .id // empty' 2>/dev/null || true)
    if [ -n "$resId" ]; then
      curl -sf -X DELETE "$GATEWAY/v1/fields/$fieldId/reservations/$resId" \
        -H "Authorization: Bearer $token" > /dev/null 2>&1 || true
    fi
  fi
}

seed_reservas_campo1() {
  info "  Criando reservas para Arena Society Xaxim..."
  local year month
  year=$(date +%Y)
  month=$(date +%m)

  create_reservation "$TOKEN_CARLOS"  "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-03T19:00:00-03:00" "${year}-${month}-03T20:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_ANDRE"   "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-05T20:00:00-03:00" "${year}-${month}-05T21:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-07T18:00:00-03:00" "${year}-${month}-07T20:00:00-03:00" "manual" "confirmed"
  create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-09T19:00:00-03:00" "${year}-${month}-09T21:00:00-03:00" "phone"  "confirmed"
  create_reservation "$TOKEN_MARCOS"  "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-10T20:00:00-03:00" "${year}-${month}-10T22:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_GABRIEL" "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-12T18:00:00-03:00" "${year}-${month}-12T19:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-14T19:00:00-03:00" "${year}-${month}-14T21:00:00-03:00" "manual" "cancelled"
  create_reservation "$TOKEN_LUCAS"   "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-15T20:00:00-03:00" "${year}-${month}-15T22:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_FELIPE"  "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-17T18:00:00-03:00" "${year}-${month}-17T20:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-19T19:00:00-03:00" "${year}-${month}-19T21:00:00-03:00" "phone"  "confirmed"
  create_reservation "$TOKEN_RODRIGO" "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-21T20:00:00-03:00" "${year}-${month}-21T21:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_CARLOS"  "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-24T19:00:00-03:00" "${year}-${month}-24T21:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1A_ID" "${year}-${month}-26T20:00:00-03:00" "${year}-${month}-26T22:00:00-03:00" "manual" "confirmed"

  if [ -n "${COURT1B_ID:-}" ]; then
    create_reservation "$TOKEN_MATEUS"  "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-04T18:00:00-03:00" "${year}-${month}-04T19:00:00-03:00" "app"    "confirmed"
    create_reservation "$TOKEN_THIAGO"  "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-08T19:00:00-03:00" "${year}-${month}-08T20:00:00-03:00" "app"    "confirmed"
    create_reservation "$TOKEN_RAFAEL"  "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-11T20:00:00-03:00" "${year}-${month}-11T21:00:00-03:00" "app"    "confirmed"
    create_reservation "$TOKEN_PEDRO"   "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-13T18:00:00-03:00" "${year}-${month}-13T19:00:00-03:00" "app"    "cancelled"
    create_reservation "$TOKEN_DONO"    "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-16T19:00:00-03:00" "${year}-${month}-16T21:00:00-03:00" "phone"  "confirmed"
    create_reservation "$TOKEN_BRUNO"   "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-20T18:00:00-03:00" "${year}-${month}-20T19:00:00-03:00" "app"    "confirmed"
    create_reservation "$TOKEN_MATEUS"  "$FIELD1_ID" "$COURT1B_ID" "${year}-${month}-23T19:00:00-03:00" "${year}-${month}-23T20:00:00-03:00" "app"    "confirmed"
  fi
}

seed_reservas_campo2() {
  info "  Criando reservas para Campo do Ze..."
  local year month
  year=$(date +%Y)
  month=$(date +%m)

  create_reservation "$TOKEN_GABRIEL"  "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-04T10:00:00-03:00" "${year}-${month}-04T12:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"     "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-06T09:00:00-03:00" "${year}-${month}-06T11:00:00-03:00" "manual" "confirmed"
  create_reservation "$TOKEN_MATEUS"   "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-08T10:00:00-03:00" "${year}-${month}-08T12:00:00-03:00" "app"    "cancelled"
  create_reservation "$TOKEN_DONO"     "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-11T09:00:00-03:00" "${year}-${month}-11T11:00:00-03:00" "phone"  "confirmed"
  create_reservation "$TOKEN_LUCAS"    "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-13T10:00:00-03:00" "${year}-${month}-13T12:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_RAFAEL"   "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-15T09:00:00-03:00" "${year}-${month}-15T11:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_THIAGO"   "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-18T10:00:00-03:00" "${year}-${month}-18T12:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_PEDRO"    "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-22T09:00:00-03:00" "${year}-${month}-22T11:00:00-03:00" "app"    "confirmed"
  create_reservation "$TOKEN_DONO"     "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-25T10:00:00-03:00" "${year}-${month}-25T12:00:00-03:00" "manual" "confirmed"
  create_reservation "$TOKEN_GABRIEL"  "$FIELD2_ID" "$COURT2_ID" "${year}-${month}-27T09:00:00-03:00" "${year}-${month}-27T11:00:00-03:00" "app"    "confirmed"
}

# =============================================================================
# 5. PELADAS (Open Games)
# =============================================================================

create_open_game() {
  local token="$1" title="$2" sport="$3" scheduled="$4" fieldId="${5:-}" minP="${6:-8}" maxP="${7:-14}"
  local tmp id
  tmp=$(mktemp)
  if [ -n "$fieldId" ]; then
    jq -cn --arg t "$title" --arg s "$sport" --arg sc "$scheduled" \
           --arg f "$fieldId" --argjson mn "$minP" --argjson mx "$maxP" \
      '{title:$t,sport:$s,scheduledAt:$sc,durationMinutes:90,minPlayers:$mn,maxPlayers:$mx,fieldId:$f}' > "$tmp"
  else
    jq -cn --arg t "$title" --arg s "$sport" --arg sc "$scheduled" \
           --argjson mn "$minP" --argjson mx "$maxP" \
      '{title:$t,sport:$s,scheduledAt:$sc,durationMinutes:90,minPlayers:$mn,maxPlayers:$mx}' > "$tmp"
  fi
  id=$(curl -sf -X POST "$GATEWAY/v1/open-games" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    --data-binary "@$tmp" 2>/dev/null \
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo "")
  rm -f "$tmp"
  echo "$id"
}

join_game() {
  local token="$1" gameId="$2"
  curl -sf -X POST "$GATEWAY/v1/open-games/$gameId/join" \
    -H "Authorization: Bearer $token" > /dev/null 2>&1 || true
}

# =============================================================================
# 6. MATCH REQUESTS (Matchmaking)
# =============================================================================

create_match_request() {
  local token="$1" sport="$2"
  local tmp id
  tmp=$(mktemp)
  jq -cn --arg s "$sport" '{sport:$s}' > "$tmp"
  id=$(curl -sf -X POST "$GATEWAY/v1/match-requests" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    --data-binary "@$tmp" 2>/dev/null \
    | jq -r '.data.id // .id // empty' 2>/dev/null || echo "")
  rm -f "$tmp"
  echo "$id"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
  echo ""
  echo "======================================================"
  echo "  BolaNaRede — Seed Script v2"
  echo "======================================================"
  echo ""

  wait_for_gateway

  echo ""
  info "=== LIMPEZA ==="
  truncate_all

  # ── Tokens globais ────────────────────────────────────────────────────────
  TOKEN_DONO=""
  TOKEN_CARLOS=""; TOKEN_ANDRE=""; TOKEN_MARCOS=""
  TOKEN_FELIPE=""; TOKEN_RODRIGO=""; TOKEN_GABRIEL=""
  TOKEN_MATEUS=""; TOKEN_LUCAS=""; TOKEN_THIAGO=""
  TOKEN_RAFAEL=""; TOKEN_PEDRO=""; TOKEN_BRUNO=""

  FIELD1_ID=""; FIELD2_ID=""
  COURT1A_ID=""; COURT1B_ID=""; COURT2_ID=""

  # ── Usuarios ──────────────────────────────────────────────────────────────
  echo ""
  info "=== USUARIOS ==="

  # Furacão FC — atacante, meia, goleiro, zagueiro, atacante
  TOKEN_CARLOS=$(register_user  "Carlos Souza"    "carlos@seed.com"   "senha123" "(41) 99999-0001")
  TOKEN_ANDRE=$(register_user   "Andre Lima"      "andre@seed.com"    "senha123" "(41) 99999-0002")
  TOKEN_MARCOS=$(register_user  "Marcos Rocha"    "marcos@seed.com"   "senha123" "(41) 99999-0003")
  TOKEN_FELIPE=$(register_user  "Felipe Santos"   "felipe@seed.com"   "senha123" "(41) 99999-0004")
  TOKEN_RODRIGO=$(register_user "Rodrigo Costa"   "rodrigo@seed.com"  "senha123" "(41) 99999-0005")

  # Uniao Vila — meia, goleiro, atacante, zagueiro
  TOKEN_GABRIEL=$(register_user "Gabriel Ferreira" "gabriel@seed.com"  "senha123" "(41) 99999-0006")
  TOKEN_MATEUS=$(register_user  "Mateus Oliveira"  "mateus@seed.com"   "senha123" "(41) 99999-0007")
  TOKEN_LUCAS=$(register_user   "Lucas Mendes"     "lucas@seed.com"    "senha123" "(41) 99999-0008")
  TOKEN_THIAGO=$(register_user  "Thiago Alves"     "thiago@seed.com"   "senha123" "(41) 99999-0009")

  # Dragoes da ZL — meia, atacante, zagueiro
  TOKEN_RAFAEL=$(register_user  "Rafael Pereira"  "rafael@seed.com"   "senha123" "(41) 99999-0010")
  TOKEN_PEDRO=$(register_user   "Pedro Vieira"    "pedro@seed.com"    "senha123" "(41) 99999-0011")
  TOKEN_BRUNO=$(register_user   "Bruno Campos"    "bruno@seed.com"    "senha123" "(41) 99999-0012")

  # Validar
  for var in TOKEN_CARLOS TOKEN_ANDRE TOKEN_MARCOS TOKEN_FELIPE TOKEN_RODRIGO \
             TOKEN_GABRIEL TOKEN_MATEUS TOKEN_LUCAS TOKEN_THIAGO \
             TOKEN_RAFAEL TOKEN_PEDRO TOKEN_BRUNO; do
    eval val=\$$var
    [ -n "$val" ] && ok "$var ok" || err "Falha ao obter $var"
  done

  # ── Atualizar perfis (posicao, cidade, bio, skill) ─────────────────────
  info "Atualizando perfis dos jogadores..."
  update_profile "$TOKEN_CARLOS"  "Curitiba" "forward"    4 "Capitao do Furacao FC. Atacante rapido e goleador."
  update_profile "$TOKEN_ANDRE"   "Curitiba" "midfielder" 3 "Meia criativo. Joga desde os 12 anos no bairro Xaxim."
  update_profile "$TOKEN_MARCOS"  "Curitiba" "goalkeeper" 4 "Goleiro do Furacao FC. Reflexos rapidos."
  update_profile "$TOKEN_FELIPE"  "Curitiba" "defender"   3 "Zagueiro solido e lider da defesa do Furacao."
  update_profile "$TOKEN_RODRIGO" "Curitiba" "forward"    3 "Atacante das beiradas. Ala direito do Furacao FC."
  update_profile "$TOKEN_GABRIEL" "Curitiba" "midfielder" 4 "Capitao da Uniao Vila. Armador de jogadas."
  update_profile "$TOKEN_MATEUS"  "Curitiba" "goalkeeper" 3 "Goleiro da Uniao Vila. Seguranca entre os postes."
  update_profile "$TOKEN_LUCAS"   "Curitiba" "forward"    3 "Artilheiro da Uniao Vila. Gol em todo rachao."
  update_profile "$TOKEN_THIAGO"  "Curitiba" "defender"   3 "Zagueiro impenetravel da Uniao Vila."
  update_profile "$TOKEN_RAFAEL"  "Curitiba" "midfielder" 4 "Capitao dos Dragoes da ZL. Meia box-to-box."
  update_profile "$TOKEN_PEDRO"   "Curitiba" "forward"    3 "Atacante dos Dragoes. Cabecador nato."
  update_profile "$TOKEN_BRUNO"   "Curitiba" "defender"   3 "Zagueiro dos Dragoes. Marcacao firme."
  ok "Perfis atualizados"

  # ── Campos, quadras, disponibilidade e reservas ───────────────────────────
  echo ""
  info "=== CAMPOS E RESERVAS ==="
  seed_campos

  # ── Times ──────────────────────────────────────────────────────────────────
  echo ""
  info "=== TIMES ==="

  TEAM1_ID=$(create_team "$TOKEN_CARLOS"  "Furacao FC"     "Time de society do bairro Xaxim. Tricampeao do rachao.")
  TEAM2_ID=$(create_team "$TOKEN_GABRIEL" "Uniao Vila"     "Pelada da vila. Jogamos toda semana no Pinheirinho.")
  TEAM3_ID=$(create_team "$TOKEN_RAFAEL"  "Dragoes da ZL"  "Time da Zona Leste. Forca e raca em campo.")

  [ -n "$TEAM1_ID" ] && ok "Furacao FC: $TEAM1_ID" || warn "Furacao FC nao criado"
  [ -n "$TEAM2_ID" ] && ok "Uniao Vila: $TEAM2_ID" || warn "Uniao Vila nao criada"
  [ -n "$TEAM3_ID" ] && ok "Dragoes da ZL: $TEAM3_ID" || warn "Dragoes da ZL nao criado"

  # Membros do Furacao FC (Carlos ja e capitao)
  if [ -n "$TEAM1_ID" ]; then
    join_team "$TOKEN_ANDRE"   "$TEAM1_ID" && ok "Andre entrou no Furacao FC"   || true
    join_team "$TOKEN_MARCOS"  "$TEAM1_ID" && ok "Marcos entrou no Furacao FC"  || true
    join_team "$TOKEN_FELIPE"  "$TEAM1_ID" && ok "Felipe entrou no Furacao FC"  || true
    join_team "$TOKEN_RODRIGO" "$TEAM1_ID" && ok "Rodrigo entrou no Furacao FC" || true
  fi

  # Membros da Uniao Vila (Gabriel ja e capitao)
  if [ -n "$TEAM2_ID" ]; then
    join_team "$TOKEN_MATEUS" "$TEAM2_ID" && ok "Mateus entrou na Uniao Vila" || true
    join_team "$TOKEN_LUCAS"  "$TEAM2_ID" && ok "Lucas entrou na Uniao Vila"  || true
    join_team "$TOKEN_THIAGO" "$TEAM2_ID" && ok "Thiago entrou na Uniao Vila" || true
  fi

  # Membros dos Dragoes (Rafael ja e capitao)
  if [ -n "$TEAM3_ID" ]; then
    join_team "$TOKEN_PEDRO" "$TEAM3_ID" && ok "Pedro entrou nos Dragoes"  || true
    join_team "$TOKEN_BRUNO" "$TEAM3_ID" && ok "Bruno entrou nos Dragoes"  || true
  fi

  # ── Peladas ────────────────────────────────────────────────────────────────
  echo ""
  info "=== PELADAS ==="

  # Datas futuras (Python para compatibilidade com macOS e Linux)
  DATE_2D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=2)).strftime('%Y-%m-%dT19:00:00Z'))" 2>/dev/null || echo "2026-07-01T19:00:00Z")
  DATE_3D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=3)).strftime('%Y-%m-%dT20:00:00Z'))" 2>/dev/null || echo "2026-07-02T20:00:00Z")
  DATE_5D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=5)).strftime('%Y-%m-%dT10:00:00Z'))" 2>/dev/null || echo "2026-07-04T10:00:00Z")
  DATE_6D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=6)).strftime('%Y-%m-%dT21:00:00Z'))" 2>/dev/null || echo "2026-07-05T21:00:00Z")
  DATE_7D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=7)).strftime('%Y-%m-%dT10:00:00Z'))" 2>/dev/null || echo "2026-07-06T10:00:00Z")
  DATE_9D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=9)).strftime('%Y-%m-%dT15:00:00Z'))" 2>/dev/null || echo "2026-07-08T15:00:00Z")
  DATE_12D=$(python3 -c "from datetime import datetime,timedelta; print((datetime.utcnow()+timedelta(days=12)).strftime('%Y-%m-%dT19:00:00Z'))" 2>/dev/null || echo "2026-07-11T19:00:00Z")

  # Pelada 1: Furacão vs Geral — Terca na Society A (Campo 1)
  # Carlos cria, Andre e Marcos (Furacao), Gabriel e Lucas (Uniao Vila) participam
  G1=$(create_open_game "$TOKEN_CARLOS" "Pelada da Terca - Xaxim" "society" "$DATE_2D" "${FIELD1_ID:-}" 8 14)
  if [ -n "$G1" ]; then
    ok "Pelada 1: $G1"
    join_game "$TOKEN_ANDRE"   "$G1" && ok "  Andre entrou"   || true
    join_game "$TOKEN_MARCOS"  "$G1" && ok "  Marcos entrou"  || true
    join_game "$TOKEN_GABRIEL" "$G1" && ok "  Gabriel entrou" || true
    join_game "$TOKEN_LUCAS"   "$G1" && ok "  Lucas entrou"   || true
    join_game "$TOKEN_MATEUS"  "$G1" && ok "  Mateus entrou"  || true
    join_game "$TOKEN_THIAGO"  "$G1" && ok "  Thiago entrou"  || true
  fi

  # Pelada 2: Rachao Rapido — Quinta — Futsal (sem campo sistema)
  # Rafael cria, Pedro e Bruno (Dragoes), Thiago e Lucas (Uniao) participam
  G2=$(create_open_game "$TOKEN_RAFAEL" "Rachao Rapido - Quinta" "futsal" "$DATE_3D" "" 6 10)
  if [ -n "$G2" ]; then
    ok "Pelada 2: $G2"
    join_game "$TOKEN_PEDRO"  "$G2" && ok "  Pedro entrou"  || true
    join_game "$TOKEN_BRUNO"  "$G2" && ok "  Bruno entrou"  || true
    join_game "$TOKEN_THIAGO" "$G2" && ok "  Thiago entrou" || true
    join_game "$TOKEN_LUCAS"  "$G2" && ok "  Lucas entrou"  || true
  fi

  # Pelada 3: Rachao do Sabado — Campo 1 Society A
  # Carlos cria, quase todos participam (7+ pessoas)
  G3=$(create_open_game "$TOKEN_CARLOS" "Rachao do Sabado - Xaxim" "society" "$DATE_5D" "${FIELD1_ID:-}" 10 14)
  if [ -n "$G3" ]; then
    ok "Pelada 3: $G3"
    join_game "$TOKEN_ANDRE"   "$G3" && ok "  Andre entrou"   || true
    join_game "$TOKEN_FELIPE"  "$G3" && ok "  Felipe entrou"  || true
    join_game "$TOKEN_RODRIGO" "$G3" && ok "  Rodrigo entrou" || true
    join_game "$TOKEN_GABRIEL" "$G3" && ok "  Gabriel entrou" || true
    join_game "$TOKEN_MATEUS"  "$G3" && ok "  Mateus entrou"  || true
    join_game "$TOKEN_LUCAS"   "$G3" && ok "  Lucas entrou"   || true
    join_game "$TOKEN_PEDRO"   "$G3" && ok "  Pedro entrou"   || true
  fi

  # Pelada 4: Pelada Noturna — Sabado a Noite — Futsal (sem campo)
  # Gabriel cria com jogadores mistos
  G4=$(create_open_game "$TOKEN_GABRIEL" "Pelada Noturna - Sabado" "futsal" "$DATE_6D" "" 6 10)
  if [ -n "$G4" ]; then
    ok "Pelada 4: $G4"
    join_game "$TOKEN_MARCOS"  "$G4" && ok "  Marcos entrou"  || true
    join_game "$TOKEN_THIAGO"  "$G4" && ok "  Thiago entrou"  || true
    join_game "$TOKEN_RAFAEL"  "$G4" && ok "  Rafael entrou"  || true
    join_game "$TOKEN_BRUNO"   "$G4" && ok "  Bruno entrou"   || true
    join_game "$TOKEN_CARLOS"  "$G4" && ok "  Carlos entrou"  || true
  fi

  # Pelada 5: Copa do Bairro — Campo 2 (Pinheirinho)
  # Gabriel cria com mistura dos 3 times
  G5=$(create_open_game "$TOKEN_GABRIEL" "Copa do Bairro - Domingo" "society" "$DATE_7D" "${FIELD2_ID:-}" 10 18)
  if [ -n "$G5" ]; then
    ok "Pelada 5: $G5"
    join_game "$TOKEN_CARLOS"  "$G5" && ok "  Carlos entrou"  || true
    join_game "$TOKEN_ANDRE"   "$G5" && ok "  Andre entrou"   || true
    join_game "$TOKEN_MARCOS"  "$G5" && ok "  Marcos entrou"  || true
    join_game "$TOKEN_MATEUS"  "$G5" && ok "  Mateus entrou"  || true
    join_game "$TOKEN_LUCAS"   "$G5" && ok "  Lucas entrou"   || true
    join_game "$TOKEN_RAFAEL"  "$G5" && ok "  Rafael entrou"  || true
    join_game "$TOKEN_PEDRO"   "$G5" && ok "  Pedro entrou"   || true
    join_game "$TOKEN_THIAGO"  "$G5" && ok "  Thiago entrou"  || true
    join_game "$TOKEN_FELIPE"  "$G5" && ok "  Felipe entrou"  || true
  fi

  # Pelada 6: Pelada Pinheirinho — Terca (Campo 2)
  # Rafael cria com jogadores mistos
  G6=$(create_open_game "$TOKEN_RAFAEL" "Pelada Pinheirinho - Terca" "society" "$DATE_9D" "${FIELD2_ID:-}" 8 12)
  if [ -n "$G6" ]; then
    ok "Pelada 6: $G6"
    join_game "$TOKEN_PEDRO"   "$G6" && ok "  Pedro entrou"   || true
    join_game "$TOKEN_BRUNO"   "$G6" && ok "  Bruno entrou"   || true
    join_game "$TOKEN_GABRIEL" "$G6" && ok "  Gabriel entrou" || true
    join_game "$TOKEN_MATEUS"  "$G6" && ok "  Mateus entrou"  || true
    join_game "$TOKEN_THIAGO"  "$G6" && ok "  Thiago entrou"  || true
  fi

  # Pelada 7: Rachao do Furacao — Futsal (Campo 1 Futsal B)
  # Carlos cria com membros do Furacao + convidados
  G7=$(create_open_game "$TOKEN_CARLOS" "Rachao do Furacao - Futsal" "futsal" "$DATE_12D" "${FIELD1_ID:-}" 6 10)
  if [ -n "$G7" ]; then
    ok "Pelada 7: $G7"
    join_game "$TOKEN_ANDRE"   "$G7" && ok "  Andre entrou"   || true
    join_game "$TOKEN_MARCOS"  "$G7" && ok "  Marcos entrou"  || true
    join_game "$TOKEN_RODRIGO" "$G7" && ok "  Rodrigo entrou" || true
    join_game "$TOKEN_GABRIEL" "$G7" && ok "  Gabriel entrou" || true
    join_game "$TOKEN_RAFAEL"  "$G7" && ok "  Rafael entrou"  || true
  fi

  # ── Match Requests ─────────────────────────────────────────────────────────
  echo ""
  info "=== MATCH REQUESTS ==="
  # Times buscando adversario: Furacao (society) vs Dragoes (society) — devem fazer match
  REQ1=$(create_match_request "$TOKEN_CARLOS"  "society")
  REQ2=$(create_match_request "$TOKEN_RAFAEL"  "society")
  # Uniao Vila buscando no futsal
  REQ3=$(create_match_request "$TOKEN_GABRIEL" "futsal")

  [ -n "$REQ1" ] && ok "Match request Furacao (society): $REQ1"  || warn "Match request 1 nao criada"
  [ -n "$REQ2" ] && ok "Match request Dragoes (society): $REQ2"  || warn "Match request 2 nao criada"
  [ -n "$REQ3" ] && ok "Match request Uniao (futsal): $REQ3"     || warn "Match request 3 nao criada"

  # ── Resumo ─────────────────────────────────────────────────────────────────
  echo ""
  echo "======================================================"
  echo -e "${GREEN}  Seed concluido!${NC}"
  echo "======================================================"
  echo ""
  echo "  DONO DO CAMPO (Dashboard web — localhost:3001):"
  echo "    dono@bolanarede.com  / senha123"
  echo ""
  echo "  JOGADORES (App mobile — emulador Android):"
  echo "    carlos@seed.com    / senha123  → Cap. Furacao FC  (atacante)"
  echo "    andre@seed.com     / senha123  → Furacao FC       (meia)"
  echo "    marcos@seed.com    / senha123  → Furacao FC       (goleiro)"
  echo "    felipe@seed.com    / senha123  → Furacao FC       (zagueiro)"
  echo "    rodrigo@seed.com   / senha123  → Furacao FC       (atacante)"
  echo "    gabriel@seed.com   / senha123  → Cap. Uniao Vila  (meia)"
  echo "    mateus@seed.com    / senha123  → Uniao Vila       (goleiro)"
  echo "    lucas@seed.com     / senha123  → Uniao Vila       (atacante)"
  echo "    thiago@seed.com    / senha123  → Uniao Vila       (zagueiro)"
  echo "    rafael@seed.com    / senha123  → Cap. Dragoes ZL  (meia)"
  echo "    pedro@seed.com     / senha123  → Dragoes da ZL    (atacante)"
  echo "    bruno@seed.com     / senha123  → Dragoes da ZL    (zagueiro)"
  echo ""
  echo "  CAMPOS:"
  echo "    Campo 1: Arena Society Xaxim  → $FIELD1_ID"
  echo "    Campo 2: Campo do Ze          → $FIELD2_ID"
  echo ""
  echo "  TIMES:"
  echo "    Furacao FC:   $TEAM1_ID"
  echo "    Uniao Vila:   $TEAM2_ID"
  echo "    Dragoes ZL:   $TEAM3_ID"
  echo ""
  echo "  PELADAS: 7 criadas com participantes reais"
  echo "  MATCH REQUESTS: Furacao x Dragoes (society), Uniao Vila (futsal)"
  echo "======================================================"
}

main "$@"
