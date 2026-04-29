# Bola na Rede — Flutter App

This file is the entry point for AI agents working inside `/app`. It describes
**only** the Flutter client. The backend, database design and product specs live
under `../docs/` and are consumed by other parts of the workspace — do not edit
them from here.

---

## 1. Product context (one paragraph)

Bola na Rede is a Brazilian football/pelada social app. Users create open games
("peladas"), join them, manage formal matches, rate other players and progress
through a gamification layer. The Flutter client targets **Android, iOS and
Web** (desktop platforms were intentionally removed). The backend is a set of
NestJS microservices (PostgreSQL · RabbitMQ · Redis), but the app **must talk
to a single BFF/gateway** — never to a service directly. The gateway base URL
is not defined yet; treat it as a `dotenv` value.

When a feature needs domain knowledge (entities, events, business rules), the
source of truth is `../docs/db-*.md` and `../docs/db-overview.md`. Read those
before modeling anything new.

---

## 2. Tech stack

Versions are pinned in `pubspec.yaml` — that file is the source of truth. Do
not bump versions opportunistically; treat any upgrade as an explicit task.

| Concern              | Package               | Notes                                            |
| -------------------- | --------------------- | ------------------------------------------------ |
| State management     | `flutter_riverpod`    | Single source of truth. No Provider/Bloc/GetX.   |
| Routing              | `go_router`           | Declarative routes; deep links via `go_router`.  |
| HTTP                 | `dio`                 | One configured `Dio` instance, shared.           |
| Env / secrets        | `flutter_dotenv`      | `.env` is gitignored. Never hardcode URLs/keys.  |
| Local key-value      | `shared_preferences`  | Tokens, simple flags only — not domain data.     |
| Icons                | `phosphor_flutter`    | Default icon set. Avoid mixing Material icons.   |
| Lints                | `very_good_analysis`  | Plus the extras in `analysis_options.yaml`.      |

**No code generation yet.** Do not introduce `freezed`, `json_serializable`,
`build_runner`, `riverpod_generator`, `auto_route` or similar without an
explicit decision. Models are written by hand (see §7).

---

## 3. Architecture

**Clean Architecture per feature, with MVVM in the presentation layer.**

- `View` (screens under `views/`): pure UI, no business logic, no direct
  repository access. Reads state from a Riverpod provider exposed by a
  `ViewModel`.
- `ViewModel`: presentation logic only — formatting, validation, orchestrating
  use cases / repositories, exposing UI state. Implemented as a Riverpod
  `Notifier` / `AsyncNotifier`.
- `Domain`: framework-agnostic entities and repository **interfaces**. No
  Flutter, no Dio, no Riverpod imports here.
- `Data`: implements the domain repositories using `datasources` (Dio, local
  storage) and `models` (DTOs that convert to/from domain entities).

Data flow: `View → ViewModel → Repository (domain interface) → RepositoryImpl
(data) → DataSource → Dio/SharedPreferences`.

Rules:
- The `domain/` layer must not import anything from `data/` or `presentation/`.
- The `presentation/` layer must not import from `data/` directly — go through
  domain interfaces.
- Cross-feature imports are allowed only through `core/` or `shared/`.

---

## 4. Folder layout

```
app/
├── assets/
│   ├── fonts/
│   └── images/
├── lib/
│   ├── main.dart            # bootstrap: load .env, ProviderScope, runApp
│   ├── app.dart             # MaterialApp.router, theme, locale, router config
│   ├── core/                # cross-cutting infra, no feature logic
│   │   ├── network/         # Dio client, interceptors, error mapping
│   │   ├── routes/          # go_router configuration
│   │   └── themes/          # colors, typography, ThemeData
│   ├── features/
│   │   └── <feature>/
│   │       ├── data/
│   │       │   ├── datasources/   # remote/local IO
│   │       │   ├── models/        # DTOs with fromJson/toJson
│   │       │   └── repositories/  # implementations of domain repos
│   │       ├── domain/
│   │       │   ├── entities/      # plain Dart, immutable
│   │       │   └── repositories/  # abstract classes only
│   │       └── presentation/
│   │           ├── views/         # routed screens (Views)
│   │           ├── viewmodels/    # Riverpod Notifiers
│   │           └── widgets/       # feature-scoped widgets
│   └── shared/
│       └── widgets/         # widgets reused across features
└── pubspec.yaml
```

When adding a new feature, replicate the full `data/domain/presentation` tree
even if some folders start empty — keeps the structure predictable for agents.

---

## 5. Naming & language

- **File names**: `snake_case.dart`. One public class per file when reasonable.
- **Classes**: `PascalCase`. **Variables/methods**: `lowerCamelCase`.
- **Feature folders are in Portuguese.** Examples: `peladas/`, `partidas/`,
  `times/`, `campos/`, `ranking/`, `gamificacao/`, `social/`, `notificacoes/`,
  `perfil/`. **Exception:** `auth/` stays in English (universally understood).
- **Code identifiers stay in English** even inside Portuguese-named features
  (e.g. `class OpenGameRepository`, `void joinGame()`). Use Portuguese only for
  user-facing strings or domain terms with no clean English equivalent
  (`Pelada`, `Racha`) — and when you do, document why next to the symbol.
- **This file (`CLAUDE.md`) and any other agent-facing docs are written in
  English.** Product/business docs under `../docs/` are in Portuguese — do not
  translate them.

---

## 6. State management — Riverpod

- Wrap the app in a single `ProviderScope` at `main.dart`.
- One `Notifier` per ViewModel. Expose the state as the only public surface;
  keep methods small and intention-revealing (`refresh()`, `submit()`).
- Async work uses `AsyncNotifier` and surfaces `AsyncValue<T>` to the View.
  Views render the three states (`data`/`loading`/`error`) explicitly — no
  silent fallbacks.
- Repositories and `Dio` are themselves exposed as providers so they can be
  overridden in tests.
- Never call `ref.read` from inside `build()` — use `ref.watch`. Use
  `ref.read` only inside callbacks / methods.
- Cancel subscriptions and dispose resources in `Notifier.dispose` / via
  `ref.onDispose` — the lint `cancel_subscriptions` is enforced.

---

## 7. Models & serialization (manual, no codegen)

Until codegen is introduced explicitly:

- DTOs live in `data/models/` and own `fromJson` / `toJson`.
- Entities live in `domain/entities/`, are immutable (`final` fields,
  `const` constructors when possible) and have no JSON knowledge.
- DTOs convert to entities through a `toEntity()` method (or a mapper in the
  repository implementation). The View never touches a DTO.
- Use the types defined in `../docs/db-overview.md`:
  - **External IDs are UUIDs (`String`)** — never expose internal `bigint` PKs.
  - Money fields → `Decimal`/`num` parsed from string, not `double`.
  - Timestamps → `DateTime` parsed as UTC.
- For nullable optional fields, prefer `T?` over sentinel values.

---

## 8. Routing — go_router

- All routes are declared in `core/routes/`. No ad-hoc `Navigator.push` of
  named routes from inside features.
- Route paths use `kebab-case`: `/open-games/:id`, `/profile/edit`.
- Route names are exported as constants; features import the constants instead
  of hardcoding paths.
- Auth-gated routes use a single `redirect` function on the root router —
  driven by an auth state provider, not by ad-hoc checks per page.

---

## 9. Networking

- One configured `Dio` instance lives in `core/network/dio_client.dart` and is
  exposed via a Riverpod provider. Every datasource depends on that provider.
- Base URL, timeouts and feature flags come from `.env` via `flutter_dotenv`.
  Never inline URLs in code.
- Interceptors handle: auth token injection, refresh, structured error
  mapping, and request/response logging **outside production builds only**.
- Errors crossing the data → domain boundary are mapped to typed failures
  (define a small `Failure` hierarchy under `core/`). The View never sees a
  raw `DioException`.
- The app talks to a **single BFF/gateway**. Do not add per-microservice base
  URLs. If a screen needs data from multiple services, it is the BFF's job to
  aggregate it.

---

## 10. Theming, assets, i18n

- Colors live in `core/themes/app_colors.dart` and are referenced through the
  `ThemeData` (`Theme.of(context)`), not imported directly into widgets when
  there is a semantic token available.
- Assets are registered in `pubspec.yaml` under `assets/fonts/` and
  `assets/images/`. Add new asset directories explicitly — Flutter does not
  recurse.
- The product is PT-BR. When user-facing strings start to multiply, introduce
  `flutter_localizations` + ARB files; for now, keep strings co-located but
  centralize anything reused in 2+ places.

---

## 11. Coding standards (derived from `analysis_options.yaml`)

The analyzer is strict — read the file before fighting it. Highlights:

- Strict mode is on: `strict-casts`, `strict-inference`, `strict-raw-types`.
- `missing_required_param` and `missing_return` are **errors**, not warnings.
- Always declare return types. No `dynamic` calls. No raw types.
- `prefer_single_quotes`, `prefer_const_constructors`,
  `prefer_const_literals_to_create_immutables`, `prefer_final_locals`,
  `prefer_final_fields` are enforced — write final-by-default.
- `unawaited_futures` is on: every `Future` must be awaited or explicitly
  `unawaited(...)`.
- `avoid_print` is on: use a logger (or `debugPrint` while bootstrapping).
- `avoid_positional_boolean_parameters` is on: use named params for booleans.
- `use_super_parameters`, `use_decorated_box`, `sized_box_for_whitespace` —
  follow the idiomatic forms.
- `public_member_api_docs` is **off intentionally** — do not add empty
  doc comments to satisfy a lint that is not running.

**Imports are always absolute** — use `package:bola_na_rede/...` for every
intra-project import. Relative imports (`../foo/bar.dart`, `./baz.dart`) are
forbidden, even between sibling files in the same folder. This keeps moves
and renames cheap and makes file headers tell you exactly where a symbol
comes from.

```dart
// good
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

// bad
import '../domain/entities/user.dart';
```

**Import order** is enforced by `import_sorter` (in `dev_dependencies`,
configured in `pubspec.yaml`). The tool splits imports into groups separated
by a blank line, in this fixed order:

```
1. dart:          (SDK)
2. package:flutter (Flutter SDK only)
3. package:other  (third-party)
4. package:bola_na_rede  (this project — always last)
```

No section comments are emitted (`comments: false`). Generated files
(`*.g.dart`) are ignored. Run the tool after touching imports broadly:

```
dart run import_sorter:main
```

`directives_ordering` lint is disabled in `analysis_options.yaml` because it
conflicts with import_sorter's grouping (the lint wants strict alphabetical
with no blank lines).

---

## 12. Testing conventions

The framework is `flutter_test` (already in `dev_dependencies`). No additional
testing libraries are wired in — do not add any without an explicit decision.

### Layout

`test/` mirrors `lib/` 1:1. A test for `lib/features/auth/domain/entities/
user.dart` lives at `test/features/auth/domain/entities/user_test.dart`. Test
files always end in `_test.dart`.

### What to test (and what not to)

| Layer / Type               | Test? | What to assert                                       |
| -------------------------- | ----- | ---------------------------------------------------- |
| `domain/entities`          | yes   | invariants, equality, value-object rules             |
| `domain` use cases         | yes   | input → output, error paths                          |
| `data/repositories`        | yes   | DTO ↔ entity mapping, error mapping to `Failure`     |
| `data/datasources`         | yes   | request shape & response parsing (via fake Dio)      |
| `presentation/viewmodels`  | yes   | state transitions (`AsyncValue` data/loading/error)  |
| critical widgets/views     | yes   | smoke + key user flow (form submit, empty state)     |
| trivial widgets            | no    | don't assert on `const Text('x')`                    |
| third-party libs           | no    | trust the package's own test suite                   |
| generated code             | no    | n/a — none yet                                       |

### Test doubles

- Use **hand-written fakes** for the narrow `domain/repositories` interfaces.
  They are small enough that a `FakeAuthRepository` covers most needs without
  extra tooling.
- Never test against a real network or real `SharedPreferences`. Inject a
  fake at the provider boundary.

### Riverpod testing

- For pure ViewModel/Notifier tests, use `ProviderContainer`:

```dart
final container = ProviderContainer(
  overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
);
addTearDown(container.dispose);
```

- For widget tests, wrap the tree in `ProviderScope(overrides: [...])` and
  override **at the provider level**. Never reach into a Notifier through
  global state.
- Listen to state with `container.listen` (unit) or `find.byType` /
  `tester.widget` (widget) — don't poke at private fields.

### Style & structure

- Top-level `group('<ClassName>', () { ... })`; one nested `group` per method
  or behavior cluster.
- Test names read as behavior: `test('returns Failure when token expired', ...)`.
  Present tense, no "should".
- **Arrange / Act / Assert** layout, with blank lines separating the three.
  Keep setup minimal and per-test — only hoist to `setUp` when 3+ tests need it.
- For async assertions use `expectLater(future, completion(...))` /
  `expectLater(future, throwsA(...))` — don't `await` then `expect`.
- Widget tests pump with `tester.pumpWidget(...)` then `await tester.pump()`
  for each frame you care about; never use real `Future.delayed` to wait for
  animations — use `tester.pump(duration)`.

### Coverage

Not enforced. Run `flutter test --coverage` locally when you want a sanity
check; the report lands at `coverage/lcov.info` (already gitignored).

---

## 13. What NOT to do

- Do **not** add new state-management, routing, DI, or codegen libraries
  without the user's go-ahead.
- Do **not** call microservices directly — always through the BFF.
- Do **not** put business logic in widgets, or networking in ViewModels.
- Do **not** expose internal `bigint` IDs anywhere; use the UUID `external_id`.
- Do **not** silence analyzer errors with `// ignore:` — fix the cause.
- Do **not** create `*.md` docs inside `/app` unless the user asks.
- Do **not** read or edit files in `../docs/` or `../bolanarede_api/` from a
  task scoped to the Flutter app.

---

## 14. Useful commands

```
flutter pub get             # install deps
flutter analyze             # run the analyzer (strict, see §11)
flutter test                # run unit/widget tests
flutter test --coverage     # generate coverage/lcov.info
flutter run -d chrome       # web target
flutter run -d <device>     # mobile target
dart run import_sorter:main # sort imports project-wide
```

---

## 15. Where to find more context

- Backend & domain: `../docs/db-overview.md` (start here), then the per-service
  files (`db-identity-service.md`, `db-open-game-service.md`, etc.).
- Cross-service patterns (snapshots, projections, events):
  `../docs/db-cross-service.md`.
- Linting source of truth: `app/analysis_options.yaml`.
- Dependencies & assets: `app/pubspec.yaml`.
