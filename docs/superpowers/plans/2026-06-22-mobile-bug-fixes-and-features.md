# Mobile App — Bug Fixes & Feature Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir 4 bugs críticos de dados + implementar 5 features de produto no app Flutter.

**Architecture:** Clean Architecture (domain/data/presentation), MVVM com Riverpod. Cada layer segue o padrão existente — datasource HTTP → repo impl → provider → viewmodel → view. Sem novas bibliotecas.

**Tech Stack:** Flutter 3.x, Dart 3.3+, Riverpod 3.3.1, Dio 5.9.2, go_router 17.2.2, phosphor_flutter 2.1.0, json_annotation/json_serializable. Backend: NestJS + gateway nginx :3000.

---

## Diagnóstico dos Bugs

| Bug | Causa raiz |
|-----|-----------|
| Membros do time não carregam | `TeamMemberModel.fromJson` lê `json['userId']` mas backend envia `playerUserId`; `json['name']` mas backend envia `displayName`; role compare `'CAPTAIN'` mas backend envia `'captain'` (lowercase) |
| Home mostra rank 3, 6 jogadores, 8 vitórias fixos | `HomeData.myRank`, `.playerCount`, `.winStreak` são constantes hardcoded no getter |
| Histórico e Ranking vazios | Seed não cria jogos completos (COMPLETED); ranking-service só tem dados após evento `GAME_COMPLETED`; game-service DB não é truncado entre seeds |
| Notificações vazias | Provavelmente vazio porque seed não gera eventos suficientes; corrigido quando games forem completados |

---

## File Map

**Modified:**
- `lib/features/team/data/models/team_model.dart` — fix field names em TeamMemberModel
- `lib/features/team/domain/entities/team.dart` — add `memberCount` field
- `lib/features/team/domain/entities/team.g.dart` — regenerate (manual update)
- `lib/features/home/presentation/viewmodels/home_viewmodel.dart` — real stats
- `lib/features/match/presentation/views/register_result_page.dart` — nav para rating após submit
- `lib/features/peladas/presentation/views/create_pelada_page.dart` — field picker + recurring
- `lib/features/team/presentation/views/team_manage_page.dart` — invite button + "Criar Desafio"
- `lib/features/match/presentation/viewmodels/match_viewmodel.dart` — openChallengesProvider
- `lib/core/routes/app_router.dart` — novas rotas
- `bolanarede_api/seed.sh` — truncate game DB + criar jogos completos

**Created:**
- `lib/features/social/data/datasources/review_http_datasource.dart` — POST /v1/reviews
- `lib/features/social/data/repositories/review_repository_provider.dart`
- `lib/features/match/presentation/views/rate_players_page.dart` — rating pós-jogo
- `lib/features/match/presentation/views/open_challenges_page.dart` — lista de desafios abertos

---

## Task 1: Fix TeamMemberModel field mapping

**Causa:** Backend envia `playerUserId`, `displayName`, `role: 'captain'`; Flutter lê `userId`, `name`, compara com `'CAPTAIN'`.

**Files:**
- Modify: `lib/features/team/data/models/team_model.dart:58-79`

- [ ] **Step 1: Corrigir `TeamMemberModel.fromJson` e `toEntity()`**

```dart
// Em lib/features/team/data/models/team_model.dart
// Substituir TeamMemberModel por:

class TeamMemberModel {
  const TeamMemberModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      TeamMemberModel(
        userId: json['playerUserId'] as String,     // era 'userId'
        name: json['displayName'] as String? ?? '', // era 'name'
        role: json['role'] as String? ?? 'member',  // era 'MEMBER'
        joinedAt: json['joinedAt'] as String,
      );

  final String userId;
  final String name;
  final String role;
  final String joinedAt;

  TeamMember toEntity() => TeamMember(
        teamId: '',
        userId: userId,
        role: role == 'captain'           // era 'CAPTAIN'
            ? TeamMemberRole.captain
            : TeamMemberRole.member,
        joinedAt: DateTime.parse(joinedAt),
        displayName: name.isNotEmpty ? name : null,
      );
}
```

- [ ] **Step 2: Commit**

```bash
cd /c/bola-na-rede/bolanarede_mobile
git add lib/features/team/data/models/team_model.dart
git commit -m "fix(team): corrigir mapeamento de campos TeamMemberModel (playerUserId, displayName, role lowercase)"
```

---

## Task 2: Adicionar memberCount ao Team + corrigir HomeData com stats reais

**Causa:** `HomeData` tem `myRank = 3`, `playerCount = 6`, `winStreak = 8` como constantes. `Team` entity não tem `memberCount`.

**Files:**
- Modify: `lib/features/team/domain/entities/team.dart`
- Modify: `lib/features/team/domain/entities/team.g.dart`
- Modify: `lib/features/team/data/models/team_model.dart`
- Modify: `lib/features/home/presentation/viewmodels/home_viewmodel.dart`

- [ ] **Step 1: Adicionar `memberCount` ao `Team` entity**

```dart
// Em lib/features/team/domain/entities/team.dart
// Adicionar campo memberCount à classe Team:

@JsonSerializable()
class Team {
  final String id;
  final String name;
  final String city;
  final TeamStatus status;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final int memberCount;                // ← NOVO

  const Team({
    required this.id,
    required this.name,
    required this.city,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,               // ← NOVO (default 0)
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}
```

- [ ] **Step 2: Atualizar `team.g.dart` (arquivo gerado, atualizar manualmente)**

No arquivo `lib/features/team/domain/entities/team.g.dart`, adicionar `memberCount` em `_$TeamFromJson` e `_$TeamToJson`:

```dart
// Em _$TeamFromJson — adicionar linha:
memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,

// Em _$TeamToJson — adicionar linha:
'memberCount': instance.memberCount,
```

- [ ] **Step 3: Mapear `memberCount` em `TeamModel.toEntity()`**

```dart
// Em lib/features/team/data/models/team_model.dart
// Substituir toEntity():

Team toEntity() => Team(
      id: id,
      name: name,
      city: '',
      status: isActive ? TeamStatus.active : TeamStatus.inactive,
      createdBy: captainUserId,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(createdAt),
      memberCount: memberCount,          // ← NOVO
    );
```

- [ ] **Step 4: Converter `HomeData` para usar stats reais**

```dart
// Substituir lib/features/home/presentation/viewmodels/home_viewmodel.dart inteiro:

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/home/data/repositories/home_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class HomeData {
  final Match? nextMatch;
  final Match? pendingRequest;
  final Team? myTeam;
  final int myRank;
  final int playerCount;
  final int winStreak;

  const HomeData({
    this.nextMatch,
    this.pendingRequest,
    this.myTeam,
    this.myRank = 0,
    this.playerCount = 0,
    this.winStreak = 0,
  });
}

class HomeVM extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final myTeam = await ref.watch(myTeamProvider.future);
    final teamId = myTeam?.id ?? '';
    final repo = ref.watch(homeRepositoryProvider);
    final rankingRepo = ref.watch(rankingRepositoryProvider);

    final results = await Future.wait([
      repo.getNextMatch(teamId),
      repo.getPendingRequest(teamId),
      repo.getMyTeam(teamId),
      rankingRepo.getPlayerRankings(),
    ]);

    final rankings = results[3] as List<dynamic>;

    // Rank do usuário atual no ranking (0 = não rankeado)
    int myRank = 0;
    try {
      final rankingRepo2 = ref.read(rankingRepositoryProvider);
      final allRankings = await rankingRepo2.getPlayerRankings();
      if (allRankings.isNotEmpty) {
        myRank = allRankings.first.rank; // posição 1 = melhor
      }
    } catch (_) {}

    // Win streak: contagem de vitórias consecutivas mais recentes
    int winStreak = 0;
    try {
      final matchRepo = ref.read(homeRepositoryProvider);
      final recentMatches = await matchRepo.getRecentMatches();
      for (final m in recentMatches) {
        if (m.status == MatchStatus.completed && m.winnerId != null) {
          winStreak++;
        } else {
          break;
        }
      }
    } catch (_) {}

    final resolvedTeam = results[2] as Team? ?? myTeam;

    return HomeData(
      nextMatch: results[0] as Match?,
      pendingRequest: results[1] as Match?,
      myTeam: resolvedTeam,
      myRank: myRank,
      playerCount: resolvedTeam?.memberCount ?? 0,
      winStreak: winStreak,
    );
  }
}

final homeProvider = AsyncNotifierProvider<HomeVM, HomeData>(HomeVM.new);
```

> **Nota:** `homeRepositoryProvider.getRecentMatches()` pode não existir ainda — verificar `HomeRepository` e adicionar se necessário, ou usar `matchRepositoryProvider.getMatches()` diretamente.

- [ ] **Step 5: Se `HomeRepository` não tiver `getRecentMatches()`, simplificar**

Se o método não existir, usar apenas os dados do time para `winStreak`:

```dart
// Versão simplificada sem getRecentMatches():
winStreak = 0; // deixar 0 até ter dados de jogos completos
```

E para `myRank`, usar o ranking real:

```dart
// No build() simplificado:
final rankings = await rankingRepo.getPlayerRankings();
myRank = rankings.isEmpty ? 0 : rankings.first.rank;
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/team/domain/entities/team.dart \
        lib/features/team/domain/entities/team.g.dart \
        lib/features/team/data/models/team_model.dart \
        lib/features/home/presentation/viewmodels/home_viewmodel.dart
git commit -m "fix(home): substituir stats hardcoded por dados reais; adicionar memberCount ao Team"
```

---

## Task 3: Atualizar seed — truncar game DB + criar jogos completos

**Causa:** Seed não trunca o game-service DB entre execuções, e não cria jogos COMPLETED → ranking e histórico ficam vazios.

**Files:**
- Modify: `bolanarede_api/seed.sh`

- [ ] **Step 1: Adicionar truncate do game-service ao `truncate_all()`**

No bloco `truncate_all()`, após os existentes, adicionar:

```bash
  docker exec bolanarede_api-postgres-game-1 psql -U postgres -d bolanarededb_game -c \
    "TRUNCATE competitive_games CASCADE;" \
    > /dev/null 2>&1 && ok "game-db truncado" || warn "game-db: truncate falhou"
```

- [ ] **Step 2: Adicionar função `create_and_complete_game()` ao seed**

Adicionar após `truncate_all()` e antes da seção de usuários:

```bash
# =============================================================================
# HELPER: cria e completa um jogo entre 2 jogadores
# Args: token_a token_b sport goals_a goals_b assists_a assists_b label
# =============================================================================
create_and_complete_game() {
  local token_a="$1" token_b="$2" sport="$3"
  local goals_a="${4:-2}" goals_b="${5:-1}"
  local assists_a="${6:-1}" assists_b="${7:-0}"
  local label="${8:-$sport}"

  # Criar request de cada jogador
  curl -s -X POST "$GATEWAY/v1/match-requests" \
    -H "Authorization: Bearer $token_a" \
    -H "Content-Type: application/json" \
    -d "{\"sport\":\"$sport\"}" > /dev/null 2>&1 || true

  sleep 1

  curl -s -X POST "$GATEWAY/v1/match-requests" \
    -H "Authorization: Bearer $token_b" \
    -H "Content-Type: application/json" \
    -d "{\"sport\":\"$sport\"}" > /dev/null 2>&1 || true

  sleep 3  # aguardar auto-matching

  # Buscar jogo criado pelo matching (mais recente do jogador A)
  local tmp_games
  tmp_games=$(curl -s "$GATEWAY/v1/games" \
    -H "Authorization: Bearer $token_a" 2>/dev/null)
  local game_id
  game_id=$(echo "$tmp_games" | jq -r '.data | sort_by(.createdAt) | last | .id // empty' 2>/dev/null)

  if [ -z "$game_id" ]; then
    warn "Jogo $label: nao encontrado apos matching"
    return 1
  fi

  # Verificar se jogo nao ja foi completado
  local game_status
  game_status=$(curl -s "$GATEWAY/v1/games/$game_id" \
    -H "Authorization: Bearer $token_a" 2>/dev/null | jq -r '.data.status // "SCHEDULED"')

  if [ "$game_status" = "COMPLETED" ]; then
    ok "Jogo $label ($game_id) ja completo"
    return 0
  fi

  # Submeter resultado (jogador A submete)
  curl -s -X POST "$GATEWAY/v1/games/$game_id/result" \
    -H "Authorization: Bearer $token_a" \
    -H "Content-Type: application/json" \
    -d "{\"playerAGoals\":$goals_a,\"playerBGoals\":$goals_b,\"playerAAssists\":$assists_a,\"playerBAssists\":$assists_b}" \
    > /dev/null 2>&1 || true

  sleep 1

  # Confirmar resultado (jogador B confirma)
  curl -s -X POST "$GATEWAY/v1/games/$game_id/results/confirm" \
    -H "Authorization: Bearer $token_b" \
    > /dev/null 2>&1 || true

  ok "Jogo $label: $game_id completo ($goals_a x $goals_b)"
}
```

- [ ] **Step 3: Adicionar seção de jogos ao seed, após os match requests**

Substituir a seção `=== MATCH REQUESTS ===` por:

```bash
# =============================================================================
# 5. JOGOS COMPLETOS (popula ranking e historico)
# =============================================================================

info "=== JOGOS COMPLETOS ==="

# Futsal: Carlos vs Andre — Carlos vence 3x1
create_and_complete_game "$TOKEN_CARLOS" "$TOKEN_ANDRE" "futsal" 3 1 2 0 "Carlos vs Andre (futsal)"

# Society: Carlos vs Rafael — Rafael vence 1x3
create_and_complete_game "$TOKEN_CARLOS" "$TOKEN_RAFAEL" "society" 1 3 0 2 "Carlos vs Rafael (society)"

# Futsal: Marcos vs Felipe — Marcos vence 2x1
create_and_complete_game "$TOKEN_MARCOS" "$TOKEN_FELIPE" "futsal" 2 1 1 0 "Marcos vs Felipe (futsal)"

# Futsal: Pedro vs Bruno — Empate 1x1
create_and_complete_game "$TOKEN_PEDRO" "$TOKEN_BRUNO" "futsal" 1 1 0 0 "Pedro vs Bruno (empate)"

# Society: Mateus vs Thiago — Mateus vence 4x2
create_and_complete_game "$TOKEN_MATEUS" "$TOKEN_THIAGO" "society" 4 2 2 1 "Mateus vs Thiago (society)"

# =============================================================================
# 6. MATCH REQUESTS ABERTOS (para teste de matchmaking no app)
# =============================================================================

info "=== MATCH REQUESTS ABERTOS ==="

tmp_mr=$(mktemp)
ok_mr=0

mr_resp=$(curl -s -o "$tmp_mr" -w "%{http_code}" -X POST "$GATEWAY/v1/match-requests" \
  -H "Authorization: Bearer $TOKEN_GABRIEL" \
  -H "Content-Type: application/json" \
  -d '{"sport":"futsal"}' 2>/dev/null)
[ "$mr_resp" = "201" ] && { ok "Match request Gabriel (futsal)"; ok_mr=$((ok_mr+1)); } || warn "Match request Gabriel falhou ($mr_resp)"

mr_resp=$(curl -s -o "$tmp_mr" -w "%{http_code}" -X POST "$GATEWAY/v1/match-requests" \
  -H "Authorization: Bearer $TOKEN_RODRIGO" \
  -H "Content-Type: application/json" \
  -d '{"sport":"society"}' 2>/dev/null)
[ "$mr_resp" = "201" ] && { ok "Match request Rodrigo (society)"; ok_mr=$((ok_mr+1)); } || warn "Match request Rodrigo falhou ($mr_resp)"

rm -f "$tmp_mr"
```

- [ ] **Step 4: Rodar o seed e verificar**

```bash
cd /c/bola-na-rede/bolanarede_api
bash seed.sh 2>&1 | tail -40
```

Verificar que aparece:
- `[ok] game-db truncado`
- `[ok] Jogo Carlos vs Andre (futsal): <uuid> completo (3 x 1)`
- 5 jogos completos listados

- [ ] **Step 5: Verificar ranking populado**

```bash
curl -s "http://localhost:3000/v1/rankings?sport=futsal&limit=10" | jq '.data | length'
```

Deve retornar >= 1 (players com jogos futsal).

```bash
curl -s "http://localhost:3000/v1/games" \
  -H "Authorization: Bearer $(curl -s -X POST http://localhost:3000/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"email":"carlos@seed.com","password":"senha123"}' | jq -r '.data.token')" \
  | jq '.data | length'
```

Deve retornar >= 5 jogos.

- [ ] **Step 6: Commit**

```bash
cd /c/bola-na-rede/bolanarede_api
git add seed.sh
git commit -m "fix(seed): truncar game-db + criar 5 jogos completos para popular ranking e historico"
```

---

## Task 4: Team invite via clipboard

**Feature:** Capitão pode copiar link/código de convite para compartilhar com novos membros.

**Files:**
- Modify: `lib/features/team/presentation/views/team_manage_page.dart`

- [ ] **Step 1: Adicionar botão "Convidar Jogador" para capitão em `team_manage_page.dart`**

No método `build()`, dentro da seção de ações do capitão (onde aparecem opções como "Editar"), adicionar:

```dart
// Importar no topo:
import 'package:flutter/services.dart';

// No widget de ações do capitão, adicionar:
ListTile(
  leading: const Icon(PhosphorIconsRegular.userPlus),
  title: const Text('Convidar Jogador'),
  subtitle: Text('ID: ${team.id.substring(0, 8)}...'),
  trailing: const Icon(PhosphorIconsRegular.copy),
  onTap: () async {
    final invite = 'Junte-se ao time ${team.name} no Bola na Rede!\n'
        'ID do time: ${team.id}';
    await Clipboard.setData(ClipboardData(text: invite));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado! Cole em qualquer chat.'),
        duration: Duration(seconds: 2),
      ),
    );
  },
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/team/presentation/views/team_manage_page.dart
git commit -m "feat(team): adicionar botao de convite com copia de ID do time"
```

---

## Task 5: Buscar e entrar em um time

**Feature:** Usuário sem time pode buscar times disponíveis e entrar. Atualmente `team_search_page.dart` é só para buscar adversário — adicionar rota de "entrar em time".

**Files:**
- Modify: `lib/features/team/presentation/views/team_search_page.dart`
- Modify: `lib/core/routes/app_router.dart`
- Modify: `lib/features/profile/presentation/views/profile_page.dart` (ou home_page.dart)

- [ ] **Step 1: Adicionar parâmetro `mode` à `TeamSearchPage`**

```dart
// Em lib/features/team/presentation/views/team_search_page.dart
// Adicionar enum e parâmetro:

enum TeamSearchMode { joinTeam, findOpponent }

class TeamSearchPage extends ConsumerStatefulWidget {
  const TeamSearchPage({
    super.key,
    this.mode = TeamSearchMode.findOpponent,
  });

  final TeamSearchMode mode;

  @override
  ConsumerState<TeamSearchPage> createState() => _TeamSearchPageState();
}
```

- [ ] **Step 2: Adaptar a ação do botão de cada time baseado no `mode`**

No `_buildTeamTile(Team team)` widget (ou equivalente), verificar o modo:

```dart
Widget _teamAction(Team team) {
  if (widget.mode == TeamSearchMode.joinTeam) {
    return ElevatedButton(
      onPressed: () => _joinTeam(team),
      child: const Text('Entrar'),
    );
  }
  // modo findOpponent: botão "Desafiar" existente
  return ElevatedButton(
    onPressed: () => _selectOpponent(team),
    child: const Text('Desafiar'),
  );
}

Future<void> _joinTeam(Team team) async {
  try {
    await ref.read(teamRepositoryProvider).joinTeam(team.id);
    ref.invalidate(teamListProvider);
    ref.invalidate(myTeamProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Você entrou em ${team.name}!')),
    );
    context.pop();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível entrar no time.')),
    );
  }
}
```

- [ ] **Step 3: Adicionar rota `/team/search/join` no `app_router.dart`**

```dart
// Em lib/core/routes/app_router.dart
// Adicionar ao GoRouter, ao lado de /team/search existente:

GoRoute(
  path: '/team/search/join',
  builder: (_, __) => const TeamSearchPage(mode: TeamSearchMode.joinTeam),
),
```

E adicionar constante:
```dart
static const teamSearchJoin = '/team/search/join';
```

- [ ] **Step 4: Adicionar botão "Procurar Time" na profile_page.dart ou home quick actions**

Na `profile_page.dart`, se o usuário não tiver time, mostrar:

```dart
// Verificar se usuário tem time:
final myTeam = ref.watch(myTeamProvider);

myTeam.when(
  data: (team) {
    if (team == null) {
      return AppCard(
        child: Column(children: [
          const Text('Você não está em nenhum time.'),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: 'Procurar Time',
            icon: PhosphorIcons.users(),
            onPressed: () => context.push(AppRoutes.teamSearchJoin),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton.ghost(
            label: 'Criar Time',
            icon: PhosphorIcons.plus(),
            onPressed: () => context.push(AppRoutes.teamCreate),
          ),
        ]),
      );
    }
    // ... exibir time existente
    return _buildTeamCard(team);
  },
  loading: () => const CircularProgressIndicator(),
  error: (_, __) => const SizedBox.shrink(),
),
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/team/presentation/views/team_search_page.dart \
        lib/core/routes/app_router.dart \
        lib/features/profile/presentation/views/profile_page.dart
git commit -m "feat(team): adicionar modo joinTeam em TeamSearchPage + rota /team/search/join"
```

---

## Task 6: Lista de desafios abertos (team match challenges)

**Feature:** Usuário vê match requests pendentes de outros jogadores/times, pode aceitar. "Criar Desafio" = criar match request. "Buscar Adversário" = ver a lista de abertos.

**Files:**
- Create: `lib/features/match/presentation/views/open_challenges_page.dart`
- Modify: `lib/features/match/presentation/viewmodels/match_viewmodel.dart`
- Modify: `lib/core/routes/app_router.dart`
- Modify: `lib/features/team/presentation/views/team_manage_page.dart` (botão Criar Desafio)
- Modify: `lib/features/home/presentation/views/home_page.dart` (quick action)

- [ ] **Step 1: Adicionar `openChallengesProvider` no `match_viewmodel.dart`**

```dart
// Adicionar ao final de lib/features/match/presentation/viewmodels/match_viewmodel.dart:

final openChallengesProvider = FutureProvider.autoDispose<List<MatchRequest>>(
  (ref) => ref.read(matchRepositoryProvider).getMatchRequests(),
);
```

- [ ] **Step 2: Criar `open_challenges_page.dart`**

```dart
// lib/features/match/presentation/views/open_challenges_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class OpenChallengesPage extends ConsumerWidget {
  const OpenChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(openChallengesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(children: [
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft(),
                      color: AppColors.textOnPrimary),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'Desafios Abertos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.plus(), color: AppColors.textOnPrimary),
                  onPressed: () => context.push(AppRoutes.matchCreate),
                  tooltip: 'Criar Desafio',
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: challengesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erro ao carregar desafios: $e'),
            ),
            data: (challenges) {
              final pending = challenges
                  .where((c) => c.status == MatchRequestStatus.pending)
                  .toList();
              if (pending.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.soccerBall(),
                          size: 48, color: AppColors.textDisabled),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Nenhum desafio aberto no momento.',
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.primary(
                        label: 'Criar meu desafio',
                        icon: PhosphorIcons.plus(),
                        onPressed: () => context.push(AppRoutes.matchCreate),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(openChallengesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _ChallengeCard(request: pending[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.request});

  final MatchRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = _sportLabel(request.requestingTeamId); // fallback: usar sport do entity
    final timeAgo = _timeAgo(request.createdAt);

    return AppCard(
      child: Row(children: [
        AppTeamAvatar(
          initials: request.requestingTeamId.substring(0, 2).toUpperCase(),
          color: AppColors.avatarBlue,
          size: 44,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jogador em busca de partida',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('$sport · $timeAgo',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => _accept(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
          ),
          child: const Text('Aceitar'),
        ),
      ]),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(matchRepositoryProvider).acceptMatch(request.id);
      ref.invalidate(openChallengesProvider);
      ref.invalidate(matchListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desafio aceito! Jogo criado.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível aceitar o desafio.')),
      );
    }
  }

  String _sportLabel(String _) => 'Futsal / Society';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
```

> **Nota:** `request.requestingTeamId` é o UUID do jogador, não o nome. O backend inclui `displayName` no MatchRequestModel mas o `MatchRequest` entity não tem. Em task futura, adicionar `displayName` ao `MatchRequest` entity. Por ora, mostrar texto genérico.

- [ ] **Step 3: Adicionar rota `/match/open-challenges` no `app_router.dart`**

```dart
// Adicionar junto das rotas de match:
static const matchOpenChallenges = '/match/open-challenges';

GoRoute(
  path: '/match/open-challenges',
  builder: (_, __) => const OpenChallengesPage(),
),
```

- [ ] **Step 4: Adicionar botão "Desafios Abertos" na `match_list_page.dart` ou `home_page.dart`**

Na home quick actions, substituir ou adicionar ao botão "Buscar Partida":

```dart
// Em home_page.dart ou match_list_page.dart, alterar botão de buscar:
_QuickAction(
  icon: PhosphorIcons.swords(),
  label: 'Desafios\nAbertos',
  onTap: () => context.push(AppRoutes.matchOpenChallenges),
),
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/match/presentation/views/open_challenges_page.dart \
        lib/features/match/presentation/viewmodels/match_viewmodel.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(match): adicionar pagina de desafios abertos com aceitar partida"
```

---

## Task 7: Seleção de campo no fluxo de criar pelada

**Feature:** Ao criar pelada, usuário pode (opcionalmente) selecionar um campo do catálogo. O campo selecionado é salvo como `fieldId` + snapshots na pelada.

**Files:**
- Modify: `lib/features/peladas/presentation/views/create_pelada_page.dart`
- Modify: `lib/features/peladas/data/datasources/open_game_http_datasource.dart`

- [ ] **Step 1: Adicionar estado de campo selecionado à `_CreatePeladaPageState`**

```dart
// Adicionar no _CreatePeladaPageState:
String? _selectedFieldId;
String? _selectedFieldName;
String? _selectedFieldAddress;
```

- [ ] **Step 2: Adicionar seção "Selecionar Campo" no form (antes da Descrição)**

```dart
// Após o bloco de duração e antes da descrição:
const SizedBox(height: AppSpacing.md),
const Text('Campo (opcional)', style: AppTextStyles.labelMedium),
const SizedBox(height: AppSpacing.xs),
_selectedFieldId == null
    ? OutlinedButton.icon(
        icon: Icon(PhosphorIcons.mapPin()),
        label: const Text('Selecionar campo'),
        onPressed: _pickField,
      )
    : Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedFieldName ?? '',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              if (_selectedFieldAddress != null)
                Text(_selectedFieldAddress!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => setState(() {
            _selectedFieldId = null;
            _selectedFieldName = null;
            _selectedFieldAddress = null;
          }),
        ),
      ]),
```

- [ ] **Step 3: Implementar `_pickField()` — navegar para catálogo como picker**

Para usar `FieldCatalogPage` como picker, navegar com `context.push` e aguardar retorno.

Primeiro, adicionar suporte a retorno em `FieldCatalogPage`. Mas a forma mais simples é navegar para o catálogo e, quando o usuário tocar em um campo, retornar ao invés de navegar para detalhes.

Abordagem pragmática — usar um `GoRoute` com extra params:

```dart
Future<void> _pickField() async {
  // Navegar para catálogo em modo picker — retorna Map com id, name, address
  final result = await context.push<Map<String, String>>(
    AppRoutes.fieldPickerRoute,
  );
  if (result != null) {
    setState(() {
      _selectedFieldId = result['id'];
      _selectedFieldName = result['name'];
      _selectedFieldAddress = result['address'];
    });
  }
}
```

- [ ] **Step 4: Adicionar rota `/fields/pick` no `app_router.dart`**

```dart
// Nova rota de picker de campo:
static const fieldPicker = '/fields/pick';
static String get fieldPickerRoute => fieldPicker;

GoRoute(
  path: '/fields/pick',
  builder: (_, __) => const FieldPickerPage(),
),
```

- [ ] **Step 5: Criar `FieldPickerPage` (wrapper do catálogo com callback)**

```dart
// lib/features/field/presentation/views/field_picker_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';

class FieldPickerPage extends ConsumerWidget {
  const FieldPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Selecionar Campo', showBackButton: true),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (fields) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: fields.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final f = fields[i];
            return ListTile(
              leading: Icon(PhosphorIcons.mapPin(),
                  color: AppColors.primary),
              title: Text(f.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(f.city),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pop(<String, String>{
                'id': f.id,
                'name': f.name,
                'address': f.address ?? f.city,
              }),
            );
          },
        ),
      ),
    );
  }
}
```

> **Nota:** `FieldDetail` entity precisa ter campos `id`, `name`, `city`, `address`. Verificar `field.dart` entity — ajustar se necessário.

- [ ] **Step 6: Incluir fieldId no submit**

```dart
// Em _submit():
final created = await ref.read(createOpenGameProvider.notifier).create(
      title: _titleCtrl.text.trim(),
      sport: _sport,
      scheduledAt: _scheduledAtIso,
      durationMinutes: _duration,
      minPlayers: _minPlayers,
      maxPlayers: _maxPlayers,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      fieldId: _selectedFieldId,                    // ← NOVO
      fieldNameSnapshot: _selectedFieldName,         // ← NOVO
      fieldAddressSnapshot: _selectedFieldAddress,   // ← NOVO
    );
```

- [ ] **Step 7: Adicionar os novos parâmetros ao método `create()` do `createOpenGameProvider`**

Verificar o `OpenGameViewModel.create()` e adicionar os parâmetros:

```dart
// Em open_game_viewmodel.dart — método create():
Future<OpenGame?> create({
  required String title,
  required String sport,
  required String scheduledAt,
  required int durationMinutes,
  required int minPlayers,
  required int maxPlayers,
  String? description,
  String? fieldId,              // ← NOVO
  String? fieldNameSnapshot,    // ← NOVO
  String? fieldAddressSnapshot, // ← NOVO
}) async {
  // ...
}
```

E no datasource HTTP, incluir os campos no body do POST:

```dart
// Em open_game_http_datasource.dart — método create():
final body = <String, dynamic>{
  'title': title,
  'sport': sport,
  'scheduledAt': scheduledAt,
  'durationMinutes': durationMinutes,
  'minPlayers': minPlayers,
  'maxPlayers': maxPlayers,
  if (description != null) 'description': description,
  if (fieldId != null) 'fieldId': fieldId,
  if (fieldNameSnapshot != null) 'fieldNameSnapshot': fieldNameSnapshot,
  if (fieldAddressSnapshot != null) 'fieldAddressSnapshot': fieldAddressSnapshot,
};
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/peladas/presentation/views/create_pelada_page.dart \
        lib/features/field/presentation/views/field_picker_page.dart \
        lib/features/peladas/data/datasources/open_game_http_datasource.dart \
        lib/features/peladas/presentation/viewmodels/open_game_viewmodel.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(pelada): adicionar seleção de campo opcional no fluxo de criar pelada"
```

---

## Task 8: Pelada Recorrente

**Feature:** Toggle "Recorrente" na criação de pelada. Quando ativo, usuário escolhe dia da semana e o app cria 4 ocorrências (próximas 4 semanas). O backend não suporta recorrência nativa — criamos múltiplos open games.

**Files:**
- Modify: `lib/features/peladas/presentation/views/create_pelada_page.dart`

- [ ] **Step 1: Adicionar estado de recorrência**

```dart
// Em _CreatePeladaPageState, adicionar:
bool _isRecurring = false;
int _recurringWeeks = 4;
int _recurringDayOfWeek = 2; // 2 = Terça (DateTime: 1=Mon, 2=Tue, ..., 7=Sun)

static const _weekDayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
```

- [ ] **Step 2: Adicionar seção de recorrência no form (após data/hora)**

```dart
// Após os campos de data/hora:
const SizedBox(height: AppSpacing.md),
SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Recorrente', style: AppTextStyles.labelMedium),
  subtitle: const Text('Criar nas próximas semanas'),
  value: _isRecurring,
  onChanged: (v) => setState(() => _isRecurring = v),
),
if (_isRecurring) ...[
  const SizedBox(height: AppSpacing.sm),
  const Text('Dia da semana', style: AppTextStyles.labelSmall),
  const SizedBox(height: AppSpacing.xs),
  Wrap(
    spacing: AppSpacing.xs,
    children: List.generate(7, (i) {
      final dayNum = i + 1; // 1=Mon...7=Sun
      return ChoiceChip(
        label: Text(_weekDayLabels[i]),
        selected: _recurringDayOfWeek == dayNum,
        onSelected: (_) => setState(() => _recurringDayOfWeek = dayNum),
      );
    }),
  ),
  const SizedBox(height: AppSpacing.sm),
  Row(children: [
    const Text('Repetir por ', style: AppTextStyles.bodyMedium),
    DropdownButton<int>(
      value: _recurringWeeks,
      items: [4, 8, 12].map((w) => DropdownMenuItem(
        value: w,
        child: Text('$w semanas'),
      )).toList(),
      onChanged: (v) => setState(() => _recurringWeeks = v ?? 4),
    ),
  ]),
],
```

- [ ] **Step 3: Atualizar `_submit()` para criar N peladas quando recorrente**

```dart
Future<void> _submit() async {
  if (_titleCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe o título da pelada.')),
    );
    return;
  }

  if (_isRecurring) {
    await _submitRecurring();
  } else {
    await _submitSingle();
  }
}

Future<void> _submitSingle() async {
  final created = await ref.read(createOpenGameProvider.notifier).create(
        title: _titleCtrl.text.trim(),
        sport: _sport,
        scheduledAt: _scheduledAtIso,
        durationMinutes: _duration,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        fieldId: _selectedFieldId,
        fieldNameSnapshot: _selectedFieldName,
        fieldAddressSnapshot: _selectedFieldAddress,
      );
  if (!mounted) return;
  if (created != null) {
    ref.invalidate(openGameListProvider);
    context.pop();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível criar a pelada.')),
    );
  }
}

Future<void> _submitRecurring() async {
  // Calcular as próximas N datas no dia da semana escolhido
  final dates = _nextOccurrences(_recurringDayOfWeek, _recurringWeeks);
  int created = 0;
  for (final date in dates) {
    final dt = DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
    final scheduledAt = dt.toUtc().toIso8601String();
    final result = await ref.read(createOpenGameProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          sport: _sport,
          scheduledAt: scheduledAt,
          durationMinutes: _duration,
          minPlayers: _minPlayers,
          maxPlayers: _maxPlayers,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          fieldId: _selectedFieldId,
          fieldNameSnapshot: _selectedFieldName,
          fieldAddressSnapshot: _selectedFieldAddress,
        );
    if (result != null) created++;
  }
  if (!mounted) return;
  ref.invalidate(openGameListProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$created peladas recorrentes criadas!')),
  );
  context.pop();
}

// Retorna as próximas `weeks` ocorrências de `weekday` a partir de hoje
List<DateTime> _nextOccurrences(int weekday, int weeks) {
  final result = <DateTime>[];
  var dt = DateTime.now();
  // Avançar até o próximo dia da semana escolhido
  while (dt.weekday != weekday) {
    dt = dt.add(const Duration(days: 1));
  }
  for (int i = 0; i < weeks; i++) {
    result.add(dt);
    dt = dt.add(const Duration(days: 7));
  }
  return result;
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/peladas/presentation/views/create_pelada_page.dart
git commit -m "feat(pelada): adicionar opcao de pelada recorrente (cria N ocorrencias)"
```

---

## Task 9: Avaliação de jogadores pós-partida

**Feature:** Após submeter resultado, navegar para página de avaliação do adversário (1-5 estrelas + comentário opcional). Chama `POST /v1/reviews` (social-service).

**Files:**
- Create: `lib/features/social/data/datasources/review_http_datasource.dart`
- Create: `lib/features/social/data/repositories/review_repository_provider.dart`
- Create: `lib/features/match/presentation/views/rate_players_page.dart`
- Modify: `lib/features/match/presentation/views/register_result_page.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Criar datasource de reviews**

```dart
// lib/features/social/data/datasources/review_http_datasource.dart

import 'package:dio/dio.dart';

class ReviewHttpDatasource {
  const ReviewHttpDatasource({required this.dio});

  final Dio dio;

  Future<void> submitReview({
    required String gameId,
    required String revieweeUserId,
    required int score,
    String? comment,
  }) =>
      dio.post<void>(
        '/v1/reviews',
        data: <String, dynamic>{
          'gameId': gameId,
          'gameType': 'game',
          'revieweeUserId': revieweeUserId,
          'score': score,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
}
```

- [ ] **Step 2: Criar provider de review**

```dart
// lib/features/social/data/repositories/review_repository_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/social/data/datasources/review_http_datasource.dart';

final reviewDatasourceProvider = Provider<ReviewHttpDatasource>(
  (ref) => ReviewHttpDatasource(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 3: Criar `rate_players_page.dart`**

```dart
// lib/features/match/presentation/views/rate_players_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/social/data/repositories/review_repository_provider.dart';
import 'package:bola_na_rede/shared/utils/error_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RatePlayersPage extends ConsumerStatefulWidget {
  const RatePlayersPage({
    required this.gameId,
    required this.opponentId,
    super.key,
  });

  final String gameId;
  final String opponentId;

  @override
  ConsumerState<RatePlayersPage> createState() => _RatePlayersPageState();
}

class _RatePlayersPageState extends ConsumerState<RatePlayersPage> {
  int _score = 3;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewDatasourceProvider).submitReview(
            gameId: widget.gameId,
            revieweeUserId: widget.opponentId,
            score: _score,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação enviada!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/match');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage(e, fallback: 'Erro ao enviar avaliação')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
          title: 'Avaliar Adversário', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          AppTeamAvatar(
            initials: 'ADV',
            color: AppColors.avatarBlue,
            size: 72,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Como foi sua experiência com o adversário?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          // Estrelas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _score = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    _score >= star
                        ? PhosphorIcons.starFill()
                        : PhosphorIcons.star(),
                    size: 40,
                    color: _score >= star
                        ? const Color(0xFFF59E0B)
                        : AppColors.textDisabled,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _scoreLabel(_score),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Comentário opcional...',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: _loading ? 'Enviando…' : 'Enviar Avaliação',
            icon: _loading ? null : PhosphorIcons.star(),
            onPressed: _loading ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => context.go('/match'),
            child: const Text('Pular'),
          ),
        ]),
      ),
    );
  }

  String _scoreLabel(int score) => switch (score) {
        1 => 'Muito ruim',
        2 => 'Ruim',
        3 => 'Regular',
        4 => 'Bom',
        5 => 'Excelente!',
        _ => '',
      };
}
```

- [ ] **Step 4: Adicionar rota `/match/rate/:gameId/:opponentId`**

```dart
// Em lib/core/routes/app_router.dart:

static const ratePlayersBase = '/match/rate';
static String ratePlayersOf(String gameId, String opponentId) =>
    '$ratePlayersBase/$gameId/$opponentId';

GoRoute(
  path: '/match/rate/:gameId/:opponentId',
  builder: (_, state) {
    final gameId = state.pathParameters['gameId']!;
    final opponentId = state.pathParameters['opponentId']!;
    return RatePlayersPage(gameId: gameId, opponentId: opponentId);
  },
),
```

- [ ] **Step 5: Navegar para rating após submit de resultado em `register_result_page.dart`**

```dart
// Em register_result_page.dart, no método _submit(), substituir:
// ANTES:
if (ok) {
  ScaffoldMessenger.of(context).showSnackBar(...);
  context.pop();
}

// DEPOIS:
if (ok) {
  final match = ref.read(matchDetailProvider(widget.gameId)).value;
  if (!mounted) return;
  if (match != null) {
    final myUserId = ref.read(authViewModelProvider).value?.userId ?? '';
    final opponentId = match.teamAId == myUserId ? match.teamBId : match.teamAId;
    context.pushReplacement(
      AppRoutes.ratePlayersOf(widget.gameId, opponentId),
    );
  } else {
    context.pop();
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/social/ \
        lib/features/match/presentation/views/rate_players_page.dart \
        lib/features/match/presentation/views/register_result_page.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(match): adicionar avaliacao de adversario apos submissao de resultado"
```

---

## Verificação Final

Após implementar todas as tasks:

- [ ] `flutter analyze` sem erros
- [ ] `flutter test` sem falhas
- [ ] Rodar `bash seed.sh` → 5 jogos completos + ranking populado
- [ ] Login com `carlos@seed.com / senha123` no emulador
- [ ] Verificar que **membros do time carregam** (deve aparecer Furacao FC com 5 membros)
- [ ] Verificar que **ranking mostra jogadores** com stats reais
- [ ] Verificar que **histórico mostra jogos** de Carlos vs Andre e Carlos vs Rafael
- [ ] Verificar que **stats da home** refletem dados reais (não 3/6/8 fixos)
- [ ] Criar pelada com campo selecionado → aparecer na lista
- [ ] Criar pelada recorrente (4 semanas) → aparecer 4 entradas na lista
- [ ] Submeter resultado de jogo → navegar para tela de avaliação
- [ ] Avaliar adversário → snackbar de sucesso

---

## Notas de Implementação

1. **Ordem de execução:** Tasks 1, 2, 3 são pré-requisitos (bugs críticos). Tasks 4–9 são independentes entre si.
2. **team.g.dart:** Atualização manual necessária pois `build_runner` exige ambiente Flutter configurado. O executor deve editar `_$TeamFromJson` e `_$TeamToJson` diretamente no arquivo.
3. **MatchRequest.displayName:** O modelo `MatchRequestModel` tem `displayName` mas a entity `MatchRequest` não. Task 6 usa texto genérico. Pode ser melhorado futuramente adicionando `displayName` ao entity.
4. **Field entity:** Verificar se `FieldDetail` ou `Field` tem os campos `address` e `city` antes de implementar Task 7. Ajustar o picker conforme a entidade real.
5. **HomeVM imports:** `rankingRepositoryProvider` precisa ser importado no `home_viewmodel.dart`.
