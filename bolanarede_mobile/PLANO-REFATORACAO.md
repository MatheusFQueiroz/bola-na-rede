# Plano de Refatoração — Telas, Estado e Navegação · Bola na Rede (`/app`)

> Documento de execução. Carregue numa nova sessão e siga as ondas **em ordem**.
> Marque `[x]` conforme concluir. Todas as decisões abaixo já estão **firmadas** —
> não revisar sem motivo novo. Idioma do código segue o `AGENTS.md`.

---

## 1. Contexto

O parecer das telas (`app/lib`) apontou débito em três frentes — **navegação/UX**,
**padrão de estado/arquitetura** e **higiene de código** (crashes latentes, código
morto, inconsistência visual) — além de **autenticação ausente**. A navegação já foi
corrigida (Onda 0). Este plano consolida tudo num refactor ordenado, deixa o funcional
"pré-pronto" e cria uma **fundação de auth robusta porém permissiva** (sem bloquear o
desenvolvimento).

Estado técnico atual: app **100% mock** (`core/network/dio_client.dart` está vazio;
datasources mock com listas em memória e métodos `getXById`). Stack: Flutter + Riverpod
+ go_router; Clean Arch + MVVM por feature; imports **absolutos**; lints `very_good_analysis`.

---

## 2. Decisões firmadas

1. **Estado:** migrar os **8 viewmodels** de `Notifier` manual + enum + `copyWith`
   para **`AsyncNotifier` / `AsyncValue`** (alinha com `AGENTS.md §6`; elimina o bug
   do `copyWith` e a duplicação).
2. **Navegação (FEITO):** abas via `StatefulShellRoute.indexedStack` (troca
   instantânea, estado preservado); detalhe em **tela cheia** com **slide lateral**
   (`pageTransitionsTheme` Cupertino).
3. **Detalhe por ID:** anexar `/:id` aos paths de detalhe **existentes** →
   `/match/detail/:id`, `/fields/detail/:id`, `/team/manage/:id`; detalhe carrega via
   `provider.family(id)`. (Evitar `/match/:id` etc.: colidiria com as rotas estáticas
   irmãs `/match/create`, `/match/result`, `/team/create`, `/team/search`.)
4. **Escopo funcional:** núcleo arquitetural + **"pré-pronto"** — ligar telas
   hardcoded aos mocks onde houver dado; botões mortos recebem placeholder
   consistente (`showComingSoon`) em vez de `onPressed: () {}`.
5. **Auth:** fundação **robusta e bem pensada**, mas **permissiva** — navega/desenvolve
   normal; gate desligável por flag (`kAuthGateEnabled = false`).
6. **Entregável final:** este documento mantido atualizado + reconciliar `AGENTS.md`.

---

## 3. Achados consolidados (parecer + 2 sweeps)

| Tema | Evidência | Onde |
|---|---|---|
| 🔴 Rotas protegidas inexistentes | `redirect` comentado | `core/routes/app_router.dart:44-51` |
| 🔴 Sessão não persiste | user só em memória; `shared_preferences` no pubspec mas não importado | `auth_repository_impl.dart`; `splash_page.dart` |
| 🔴 Navegação de detalhe sem ID | `loadMatchDetail`/`loadFieldDetail` nunca chamados → detalhe sempre mock | match/field/home/search/team views |
| 🔴 `substring(0,2)` (RangeError) | **18 ocorrências** | home(6), match_detail(2), match_list(2), profile, ranking(2), search(2), team(2), create_match |
| 🟡 `copyWith` não limpa `null` | **8 state classes** | todos os viewmodels |
| 🟡 `ref.read` em `build()` | header e ranking não rebuildam | `home_page.dart:73,317` |
| 🟡 Formatação de data duplicada | **5 sites** | home(2), match_detail, match_list, search |
| 🟡 `addPostFrameCallback` no initState | **7 sites** (dissolve com AsyncNotifier) | home, match_list, profile, ranking, search, team_search, create_match |
| 🟡 Botões mortos `(){}` | **23 ocorrências** | múltiplas views |
| 🟡 Dados hardcoded em views | `'Furacao FC'`, `'team-001'`, listas de jogadores | match_detail, register_result, team_manage, profile, ranking |
| 🟢 `withOpacity` (deprec.) | **15 sites** | home, team_manage, ranking, profile, field_detail, splash |
| 🟢 Ícones Material misturados | **11 sites** | field_detail(10), profile(1) |
| 🟢 Import relativo (FEITO) | corrigido | `app_theme.dart` |
| ⚪ Doc×código: codegen | `AGENTS.md` diz "no codegen" mas entidades usam `.g.dart` | `AGENTS.md §2/§7` |

---

## 4. Execução — passo a passo

### ☐ Onda 0 — Navegação (código ✅ FEITO, falta o teste)
Já aplicado: `app_router.dart` (StatefulShellRoute.indexedStack), `app_shell.dart`
(`StatefulNavigationShell` + `goBranch`), `app_theme.dart` (`pageTransitionsTheme`
Cupertino + import absoluto de `app_tokens`).
- [ ] Reescrever `test/shared/widgets/app_shell_test.dart` — ainda usa a API antiga
      `ShellRoute` + `AppShell(child:)` (quebrado). Novo harness com
      `StatefulShellRoute.indexedStack` e `AppShell(navigationShell:)`.
- [ ] `flutter analyze` + `flutter test` verdes.

### ☐ Onda 1 — Utilitários compartilhados + correções de segurança (baixo risco, independente)
- [ ] Criar `lib/shared/utils/string_utils.dart` → `String initials(String value, {int max = 2})`
      seguro (sem RangeError em string curta/vazia; retorna `'?'` se vazio).
- [ ] Criar `lib/shared/utils/date_utils.dart` → `String formatDate(DateTime)` (dd/MM/yyyy)
      e `String formatTimeRange(String start, String end)`.
- [ ] Adicionar `showComingSoon(BuildContext)` em `lib/shared/widgets/app_components.dart`
      (SnackBar "Em breve").
- [ ] Substituir as **18** `substring(...)` por `initials(...)`.
- [ ] Substituir os **5** blocos de data inline por `formatDate(...)`.

### ☐ Onda 2 — Migração para AsyncNotifier/AsyncValue (núcleo)
Reescrever cada feature em **providers focados** (quebrar estados multi-async). Views
passam a usar `ref.watch(provider).when(data/loading/error)` — isso **remove os
`addPostFrameCallback`** e o **`ref.read`-em-build**. Desenho por feature:

- [ ] **match** → `matchListProvider` (`AsyncNotifier<List<Match>>`, carrega em `build()`);
      `matchDetailProvider = FutureProvider.family<Match, String>((ref, id) => repo.getMatchById(id))`;
      `createMatchProvider` (`AsyncNotifier<void>` com `submit(...)` via `AsyncValue.guard`).
- [ ] **field** → `fieldListProvider`; `fieldDetailProvider.family(id)` agregando
      field + courts + pricing.
- [ ] **home** → `homeProvider` (`AsyncNotifier<HomeData>`: nextMatch?/pendingRequest?/myTeam?).
      Carregar **ranking** aqui também (hoje nada chama `loadRanking`).
- [ ] **profile** → `profileProvider` (`AsyncNotifier<ProfileData>`: profile + recentMatches + stats).
- [ ] **ranking** → `rankingProvider` (`AsyncNotifier<RankingData>`: team + player rankings).
- [ ] **search** → `searchProvider` (`AsyncNotifier<List<...>>` com método `search(query)`).
- [ ] **team** → `teamListProvider`; `teamDetailProvider.family(id)`; `createTeamProvider`.
- [ ] **auth** → ver Onda 4.
- Manter repos/datasources como estão (já são `Provider`s sobreponíveis).
- Sketch de referência:
  ```dart
  class MatchListVM extends AsyncNotifier<List<Match>> {
    @override
    Future<List<Match>> build() => ref.read(matchRepositoryProvider).getMatches();
    Future<void> refresh() async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => ref.read(matchRepositoryProvider).getMatches());
    }
  }
  ```
  ```dart
  // View
  ref.watch(matchListProvider).when(
    data: (matches) => /* lista */,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('Não foi possível carregar.')),
  );
  ```

### ☐ Onda 3 — Rotas com ID + ligar detalhe aos dados
- [ ] `AppRoutes`: anexar `/:id` aos paths de detalhe existentes →
      `/match/detail/:id`, `/fields/detail/:id`, `/team/manage/:id`, com helpers
      (`static String matchDetail(String id) => '/match/detail/$id';`). Manter como
      rotas **top-level** (tela cheia, fora do shell). **Não** usar `/match/:id`:
      colide com `/match/create` e `/match/result` (idem team).
- [ ] Detalhes (`match_detail`, `field_detail`, `team_manage`) viram `ConsumerWidget`
      que lêem `GoRouterState.of(context).pathParameters['id']` e consomem
      `xDetailProvider(id)`.
- [ ] Atualizar **todos** os `context.push(AppRoutes.xDetail)` para passar o id
      (home, match_list, search, field_catalog, profile, create_team).
- [ ] "Pré-pronto": trocar blocos hardcoded por dados do provider quando o mock
      fornecer (nomes/snapshots). Onde o mock não tiver (jogadores do match_detail,
      register_result), manter placeholder **claramente marcado** + `showComingSoon`
      nas ações.

### ☐ Onda 4 — Fundação de auth (robusta, permissiva)
- [ ] `lib/features/auth/data/` → `TokenStorage` (abstração) sobre `shared_preferences`;
      mock datasource emite/lê token fake. Exposto como `Provider`.
- [ ] `AuthNotifier extends AsyncNotifier<PlayerProfile?>`: `build()` **restaura sessão**
      do `TokenStorage`; `login/register/logout` via `AsyncValue.guard`. Remover o
      `currentTeamId = 'team-001'` hardcoded (derivar de dado real/mock).
- [ ] `routerProvider`: adicionar `refreshListenable` ligado ao auth + função `redirect`
      **escrita e completa**, controlada por flag `const kAuthGateEnabled = false`
      (permissivo por ora; trivial de ligar depois).
- [ ] `splash_page`: checagem de sessão (mock) sem bloquear navegação manual
      ("Continuar sem conta" continua funcionando). Trocar `context.push(login/register)`
      por `context.go(...)` (não empilhar sobre a splash).
- [ ] **Validação de formulário** em `login_page` e `register_page`: e-mail vazio/formato,
      senha mínima, e a confirmação de senha (hoje só register compara). Validar via
      `Form`/`TextFormField` validators ou no VM antes do submit; bloquear submit inválido.
- Objetivo: ligar autenticação real depois = flip de flag + trocar mock por Dio.

### ☐ Onda 5 — Consistência visual e código morto
- [ ] `withOpacity(x)` → `withValues(alpha: x)` (**15**).
- [ ] `Icons.*` → `PhosphorIcons.*` (field_detail **10**, profile **1**).
- [ ] Botões mortos restantes → `showComingSoon` (ou ação real quando trivial).
- [ ] **Varredura de comentários legados** (regra `AGENTS.md §11` "default to none"):
      remover banners de seção (`// --- AppBar ---` etc. em `app_theme.dart`),
      narração e `///` redundantes em todo o `lib/`. Manter só os *porquês*
      não-óbvios. Organiza e melhora a leitura.
- [ ] (Opcional) Centralizar/acentuar strings reusadas (`AGENTS.md §10`).

### ☐ Onda 6 — Testes + docs
- [ ] Atualizar os **8** testes de viewmodel para o shape `AsyncValue`
      (usar `container.listen` / `expectLater`; reaproveitar `test/helpers/fake_repositories.dart`).
- [ ] Garantir `app_shell_test.dart` (Onda 0) verde.
- [ ] Reconciliar `AGENTS.md`: codegen (json_serializable **está** em uso), confirmar
      padrão `AsyncNotifier`, documentar regra navbar/detalhe e os novos `shared/utils`.
- [ ] Atualizar este `PLANO-REFATORACAO.md` com o que sair do escopo / itens futuros.

---

## 5. Arquivos críticos
- `lib/core/routes/app_router.dart` (rotas param, redirect/refreshListenable)
- `lib/shared/widgets/app_shell.dart` (✅) · `lib/core/themes/app_theme.dart` (✅)
- `lib/features/*/presentation/viewmodels/*.dart` (8 — reescrita AsyncNotifier)
- `lib/features/*/presentation/views/*.dart` (16 — `.when`, ids, utils, ícones, opacidade)
- `lib/features/auth/data/**` (TokenStorage) · `.../auth/presentation/viewmodels/auth_viewmodel.dart`
- `lib/shared/utils/{string_utils,date_utils}.dart` (novos)
- `test/**` (8 VM tests + `app_shell_test.dart`)

## 6. Reuso (não reinventar)
- `getMatchById` / `getFieldById` / `getTeamById` já existem nos repos/mocks → base da rota-por-ID.
- Providers de repo/datasource já sobreponíveis (Riverpod) → manter.
- `test/helpers/fake_repositories.dart` → reaproveitar nos testes migrados.
- Design system (`app_components.dart`, `app_tokens.dart`) → manter; só adicionar `showComingSoon`.

## 7. Verificação (rodar ao fim de cada onda relevante)
1. `flutter analyze` — zero erros (apenas infos pré-existentes; arquivos novos limpos).
2. `flutter test` — 8 VM tests + widget tests verdes.
3. `dart run import_sorter:main` — após mexer em imports amplamente.
4. `flutter run -d chrome` — validar manualmente:
   - Troca de aba **instantânea**, sem zoom; estado/scroll preservados.
   - Detalhe abre em **slide lateral**, tela cheia (navbar some), volta deslizando.
   - Detalhe mostra o **item correto pelo id** (não o mock fixo).
   - Nomes curtos/vazios **não crasham** (initials seguro).
   - Botões "pré-prontos" mostram **"Em breve"** em vez de não fazer nada.
   - Navegação/dev **livres** (auth permissivo).

## 8. Sequência de PRs
`Onda 0 (testar) → 1 → 2 → 3 → 4 → 5 → 6`.
Ondas **1** e **5** são independentes (entram a qualquer momento). Onda **2** habilita **3** e **4**.

---

## 9. Itens deliberadamente fora deste ciclo (futuro)
- Backend real via Dio (`dio_client.dart` hoje vazio) + `Failure` tipado + mapeamento de erro na camada data.
- Wiring funcional completo dos fluxos (aceitar/recusar convite, reservar campo, registrar resultado).
- **Ligar** o gate de auth (flip `kAuthGateEnabled`) quando autenticação entrar no roadmap.
- i18n / ARB quando as strings multiplicarem.
- **Desvio conhecido (decisão pendente):** o `AGENTS.md §10` pede cores via
  `Theme.of(context)`, mas as views importam `AppColors` direto (padrão pervasivo).
  Decidir: alinhar ao doc ou atualizar o §10 para refletir o uso de tokens diretos.
