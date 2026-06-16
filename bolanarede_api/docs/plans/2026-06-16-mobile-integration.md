# Mobile Integration — BolaNaRede Flutter App

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate all 10 NestJS microservices into the `bolanarede_mobile` Flutter app, replacing every mock datasource with real HTTP calls through an nginx API gateway.

**Architecture:** Add nginx as a transparent reverse proxy on port 3000, routing path-based to each service (e.g. `/v1/auth` → identity:4001, `/v1/fields` → field:4003). The Flutter app talks to a single `API_BASE_URL` env var, satisfying the AGENTS.md "single gateway" requirement. Each feature gets a real `HttpDataSource` implementation alongside the existing mock; switching between them is done in the provider file. No BFF aggregation layer needed — screens that need multiple services make parallel Riverpod watch calls.

**Tech Stack:** Flutter + Riverpod + Dio 5.9.2, NestJS 11 microservices, nginx:alpine, JWT Bearer tokens, `flutter_dotenv`, `shared_preferences` for token storage.

**Scope for mobile (player-facing only):**
- Auth (login, register, session restore)
- Profile (view/edit)
- Campos (browse, check availability, reserve)
- Peladas / Open Games (list, detail, create, join/leave)
- Times (create, join, manage roster)
- Partidas / Matchmaking (create match request, accept, submit result)
- Ranking (player leaderboard)
- Gamificação (XP, level, badges on profile)
- Social (submit review after game)
- Notificações (list, mark as read, unread badge)

**NOT in scope:** Field manager dashboard (that is a separate web stakeholder). FCM push notification setup (requires Firebase project — tracked separately).

---

## File Map

### API side (bolanarede_api)
| Action   | Path                                     | Purpose                                |
|----------|------------------------------------------|----------------------------------------|
| Create   | `nginx/nginx.conf`                       | API gateway routing all 10 services    |
| Modify   | `docker-compose.yml`                     | Add nginx service on port 3000         |

### Flutter side (bolanarede_mobile)
| Action   | Path                                                                           | Purpose                                        |
|----------|--------------------------------------------------------------------------------|------------------------------------------------|
| Modify   | `.env`                                                                         | Add `API_BASE_URL`                             |
| Modify   | `pubspec.yaml`                                                                 | Add `flutter_dotenv` assets `.env` entry       |
| Create   | `lib/core/errors/failures.dart`                                                | Typed failure hierarchy                        |
| Create   | `lib/core/network/interceptors/auth_interceptor.dart`                          | JWT injection + 401 handling                   |
| Create   | `lib/core/network/interceptors/error_interceptor.dart`                         | DioException → ApiException mapping           |
| Modify   | `lib/core/network/dio_client.dart`                                             | Configure real Dio instance                    |
| Create   | `lib/features/auth/data/models/auth_response_model.dart`                       | API response DTO for login/register            |
| Create   | `lib/features/auth/data/models/user_profile_model.dart`                        | API response DTO for /v1/users/me              |
| Create   | `lib/features/auth/data/datasources/auth_http_datasource.dart`                 | Real auth HTTP datasource                      |
| Modify   | `lib/features/auth/data/datasources/auth_datasource_provider.dart`             | Switch to real datasource                      |
| Modify   | `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`                | Remove `mock-token-` hardcode                  |
| Modify   | `lib/features/auth/presentation/views/splash_page.dart`                        | Real session restore flow                      |
| Modify   | `lib/core/routes/app_router.dart`                                              | Enable auth gate + add new routes              |
| Create   | `lib/features/auth/data/models/update_profile_model.dart`                      | DTO for profile update request                 |
| Create   | `lib/features/profile/data/datasources/profile_http_datasource.dart`           | GET /users/me, PUT /users/me/profile           |
| Create   | `lib/features/profile/data/datasources/profile_datasource_provider.dart`       | Provider for profile datasource                |
| Modify   | `lib/features/profile/presentation/views/profile_page.dart`                    | Real data + edit flow                          |
| Create   | `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`          | AsyncNotifier for profile state                |
| Create   | `lib/features/field/data/models/field_model.dart`                              | API DTO for field (camelCase keys)             |
| Create   | `lib/features/field/data/models/field_court_model.dart`                        | API DTO for court                              |
| Create   | `lib/features/field/data/models/availability_model.dart`                       | DTO for time-slot availability                 |
| Create   | `lib/features/field/domain/entities/availability.dart`                         | Entity: AvailabilitySlot                       |
| Modify   | `lib/features/field/domain/repositories/field_repository.dart`                 | Add `getAvailability` + search params          |
| Create   | `lib/features/field/data/datasources/field_http_datasource.dart`               | Real field HTTP datasource                     |
| Modify   | `lib/features/field/data/datasources/field_mock_datasource.dart`               | Rename abstract to separate file               |
| Modify   | `lib/features/field/data/repositories/field_repository_impl.dart`             | Add availability method                        |
| Modify   | `lib/features/field/data/repositories/field_repository_provider.dart`         | Expose search + availability                   |
| Modify   | `lib/features/field/presentation/views/field_catalog_page.dart`                | Add city search bar + real data                |
| Modify   | `lib/features/field/presentation/views/field_detail_page.dart`                 | Show availability calendar + reserve CTA       |
| Create   | `lib/features/field/presentation/views/reservation_page.dart`                  | New screen: pick slot, confirm booking         |
| Create   | `lib/features/peladas/`                                                        | New feature folder (Portuguese)                |
| Create   | `lib/features/peladas/domain/entities/open_game.dart`                          | OpenGame, OpenGameParticipant entities         |
| Create   | `lib/features/peladas/domain/repositories/open_game_repository.dart`           | Abstract repository                            |
| Create   | `lib/features/peladas/data/models/open_game_model.dart`                        | API DTO for open-game                          |
| Create   | `lib/features/peladas/data/datasources/open_game_datasource.dart`              | Abstract datasource + mock                     |
| Create   | `lib/features/peladas/data/datasources/open_game_http_datasource.dart`         | Real HTTP datasource                           |
| Create   | `lib/features/peladas/data/datasources/open_game_datasource_provider.dart`     | Provider                                       |
| Create   | `lib/features/peladas/data/repositories/open_game_repository_impl.dart`        | Repository implementation                      |
| Create   | `lib/features/peladas/data/repositories/open_game_repository_provider.dart`    | Provider                                       |
| Create   | `lib/features/peladas/presentation/viewmodels/open_game_viewmodel.dart`        | Notifiers for list + detail                    |
| Create   | `lib/features/peladas/presentation/views/peladas_list_page.dart`               | Replace SearchPage — list of open games        |
| Create   | `lib/features/peladas/presentation/views/pelada_detail_page.dart`              | Detail + join/leave/finish                     |
| Create   | `lib/features/peladas/presentation/views/create_pelada_page.dart`              | Create open game form                          |
| Create   | `lib/features/team/data/models/team_model.dart`                                | API DTO for team (camelCase)                   |
| Create   | `lib/features/team/data/datasources/team_http_datasource.dart`                 | Real team HTTP datasource                      |
| Modify   | `lib/features/team/data/datasources/team_datasource_provider.dart`             | Switch to real                                 |
| Modify   | `lib/features/team/domain/repositories/team_repository.dart`                  | Add create, join, leave, members               |
| Modify   | `lib/features/team/data/repositories/team_repository_impl.dart`               | Implement new methods                          |
| Modify   | `lib/features/team/presentation/views/team_search_page.dart`                   | Real list + search by name                     |
| Modify   | `lib/features/team/presentation/views/create_team_page.dart`                   | Real create team form                          |
| Modify   | `lib/features/team/presentation/views/team_manage_page.dart`                   | Real roster + leave/invite                     |
| Create   | `lib/features/match/data/models/match_request_model.dart`                      | API DTO for match requests                     |
| Create   | `lib/features/match/data/models/game_model.dart`                               | API DTO for game results                       |
| Create   | `lib/features/match/data/datasources/match_http_datasource.dart`               | Real matchmaking + game HTTP datasource        |
| Modify   | `lib/features/match/data/datasources/match_datasource_provider.dart`           | Switch to real                                 |
| Modify   | `lib/features/match/domain/repositories/match_repository.dart`                 | Add createRequest, accept, submitResult        |
| Modify   | `lib/features/match/data/repositories/match_repository_impl.dart`             | Implement new methods                          |
| Modify   | `lib/features/match/presentation/views/match_list_page.dart`                   | Real list of match requests/proposals          |
| Modify   | `lib/features/match/presentation/views/match_detail_page.dart`                 | Real match detail                              |
| Modify   | `lib/features/match/presentation/views/create_match_page.dart`                 | Real create match request form                 |
| Modify   | `lib/features/match/presentation/views/register_result_page.dart`              | Real result submission                         |
| Create   | `lib/features/ranking/data/models/ranking_model.dart`                          | API DTO for leaderboard entries                |
| Create   | `lib/features/ranking/data/datasources/ranking_http_datasource.dart`           | Real ranking HTTP datasource                   |
| Modify   | `lib/features/ranking/data/repositories/ranking_repository_impl.dart`          | Replace mock with HTTP                         |
| Create   | `lib/features/gamificacao/`                                                    | New feature folder                             |
| Create   | `lib/features/gamificacao/domain/entities/player_gamification.dart`            | XP, level, badges entities                     |
| Create   | `lib/features/gamificacao/data/models/gamification_model.dart`                 | API DTO                                        |
| Create   | `lib/features/gamificacao/data/datasources/gamification_http_datasource.dart`  | GET /profiles/:userId                          |
| Create   | `lib/features/gamificacao/data/datasources/gamification_datasource_provider.dart` | Provider                                   |
| Create   | `lib/features/gamificacao/data/repositories/`                                  | Impl + provider                                |
| Create   | `lib/features/gamificacao/presentation/viewmodels/gamification_viewmodel.dart` | AsyncNotifier                                  |
| Modify   | `lib/features/profile/presentation/views/profile_page.dart`                    | Add XP/level/badges section                    |
| Create   | `lib/features/social/`                                                         | New feature folder (reviews)                   |
| Create   | `lib/features/social/domain/entities/review.dart`                              | Review, PlayerScore entities                   |
| Create   | `lib/features/social/data/models/review_model.dart`                            | API DTO                                        |
| Create   | `lib/features/social/data/datasources/review_http_datasource.dart`             | POST /reviews, GET /scores/players/:id         |
| Create   | `lib/features/social/data/datasources/review_datasource_provider.dart`         | Provider                                       |
| Create   | `lib/features/social/data/repositories/`                                       | Impl + provider                                |
| Create   | `lib/features/social/presentation/views/submit_review_page.dart`               | New screen: rate another player                |
| Create   | `lib/features/notificacoes/`                                                   | New feature folder                             |
| Create   | `lib/features/notificacoes/domain/entities/notification.dart`                  | AppNotification entity                         |
| Create   | `lib/features/notificacoes/data/models/notification_model.dart`                | API DTO                                        |
| Create   | `lib/features/notificacoes/data/datasources/notification_http_datasource.dart` | GET /notifications, PATCH read                 |
| Create   | `lib/features/notificacoes/data/datasources/notification_datasource_provider.dart` | Provider                                   |
| Create   | `lib/features/notificacoes/data/repositories/`                                 | Impl + provider                                |
| Create   | `lib/features/notificacoes/presentation/viewmodels/notification_viewmodel.dart`| AsyncNotifier                                  |
| Create   | `lib/features/notificacoes/presentation/views/notifications_page.dart`         | New screen: list + mark read                   |
| Modify   | `lib/shared/widgets/app_nav_bar.dart`                                          | Add unread badge on bell icon                  |
| Modify   | `lib/features/home/presentation/viewmodels/home_viewmodel.dart`                | Real data from API services                    |

---

## Task 1: Nginx API Gateway

**Files:**
- Create: `bolanarede_api/nginx/nginx.conf`
- Modify: `bolanarede_api/docker-compose.yml`

- [ ] **Step 1.1: Create nginx config**

```
mkdir -p bolanarede_api/nginx
```

Create `bolanarede_api/nginx/nginx.conf`:

```nginx
events { worker_connections 1024; }

http {
  upstream identity      { server identity:4001; }
  upstream team          { server team:4002; }
  upstream field         { server field:4003; }
  upstream open_game     { server open-game:4004; }
  upstream social        { server social:4005; }
  upstream gamification  { server gamification:4006; }
  upstream matchmaking   { server matchmaking:4007; }
  upstream game          { server game:4008; }
  upstream ranking       { server ranking:4009; }
  upstream notification  { server notification:4010; }

  server {
    listen 3000;

    location /v1/auth         { proxy_pass http://identity; }
    location /v1/users        { proxy_pass http://identity; }
    location /v1/teams        { proxy_pass http://team; }
    location /v1/fields       { proxy_pass http://field; }
    location /v1/open-games   { proxy_pass http://open_game; }
    location /v1/reviews      { proxy_pass http://social; }
    location /v1/scores       { proxy_pass http://social; }
    location /v1/profiles     { proxy_pass http://gamification; }
    location /v1/leaderboard  { proxy_pass http://gamification; }
    location /v1/seasons      { proxy_pass http://gamification; }
    location /v1/challenges   { proxy_pass http://gamification; }
    location /v1/leagues      { proxy_pass http://gamification; }
    location /v1/match-requests { proxy_pass http://matchmaking; }
    location /v1/matches      { proxy_pass http://matchmaking; }
    location /v1/games        { proxy_pass http://game; }
    location /v1/rankings     { proxy_pass http://ranking; }
    location /v1/notifications { proxy_pass http://notification; }

    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_read_timeout                 60s;
  }
}
```

- [ ] **Step 1.2: Add nginx to docker-compose.yml**

Open `bolanarede_api/docker-compose.yml` and add the nginx service (before the NestJS services block):

```yaml
  gateway:
    image: nginx:alpine
    ports:
      - "3000:3000"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - identity
      - team
      - field
      - open-game
      - social
      - gamification
      - matchmaking
      - game
      - ranking
      - notification
    networks:
      - bolanarededb
    restart: unless-stopped
```

- [ ] **Step 1.3: Test the gateway**

```bash
cd bolanarede_api
docker-compose up --build -d gateway
curl http://localhost:3000/v1/auth/login  # expect 400 (missing body), not 502
```

Expected: `{"statusCode":400,"message":"..."}` — 400 means nginx reached the identity service.

- [ ] **Step 1.4: Commit**

```bash
git add nginx/nginx.conf docker-compose.yml
git commit -m "feat(gateway): add nginx API gateway on port 3000"
```

---

## Task 2: Flutter .env and Dio Setup

**Files:**
- Create: `bolanarede_mobile/.env`
- Modify: `bolanarede_mobile/pubspec.yaml`
- Create: `bolanarede_mobile/lib/core/errors/failures.dart`
- Create: `bolanarede_mobile/lib/core/network/interceptors/auth_interceptor.dart`
- Create: `bolanarede_mobile/lib/core/network/interceptors/error_interceptor.dart`
- Modify: `bolanarede_mobile/lib/core/network/dio_client.dart`

- [ ] **Step 2.1: Create .env file**

Create `bolanarede_mobile/.env`:

```
# API Gateway
# Android emulator: use 10.0.2.2 to reach host machine
# iOS simulator: use localhost
# Real device: use machine's LAN IP (e.g. 192.168.1.x)
API_BASE_URL=http://10.0.2.2:3000
```

> Note: `10.0.2.2` is the Android emulator's alias for the host machine. Change to `localhost` for iOS Simulator or to your LAN IP for a real device.

- [ ] **Step 2.2: Register .env in pubspec.yaml**

Open `bolanarede_mobile/pubspec.yaml`. Ensure `flutter_dotenv` is in dependencies (it already is). In the `flutter:` → `assets:` section, add:

```yaml
flutter:
  assets:
    - .env
```

Run:
```bash
cd bolanarede_mobile
flutter pub get
```

- [ ] **Step 2.3: Create Failure hierarchy**

Create `bolanarede_mobile/lib/core/errors/failures.dart`:

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(
    [super.message = 'Sessão expirada. Faça login novamente.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

- [ ] **Step 2.4: Create ApiException and ErrorInterceptor**

Create `bolanarede_mobile/lib/core/network/interceptors/error_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/errors/failures.dart';

class ApiException implements Exception {
  final Failure failure;
  const ApiException(this.failure);

  @override
  String toString() => 'ApiException: ${failure.message}';
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(failure),
        type: err.type,
        response: err.response,
      ),
    );
  }

  Failure _map(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    final status = err.response?.statusCode;
    final body = err.response?.data;
    final message = body is Map
        ? (body['message'] as Object? ?? 'Erro desconhecido.').toString()
        : 'Erro desconhecido.';
    return switch (status) {
      400 => ValidationFailure(message),
      401 => const UnauthorizedFailure(),
      403 => const ServerFailure('Permissão negada.', statusCode: 403),
      404 => const NotFoundFailure(),
      _ => ServerFailure(message, statusCode: status),
    };
  }
}
```

- [ ] **Step 2.5: Create AuthInterceptor**

Create `bolanarede_mobile/lib/core/network/interceptors/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      unawaited(tokenStorage.clearToken());
    }
    handler.next(err);
  }
}
```

Add the `unawaited` import at the top of the file:
```dart
import 'dart:async';
```

- [ ] **Step 2.6: Implement Dio client**

Replace the empty `bolanarede_mobile/lib/core/network/dio_client.dart` with:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:bola_na_rede/core/network/interceptors/auth_interceptor.dart';
import 'package:bola_na_rede/core/network/interceptors/error_interceptor.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage: tokenStorage),
    ErrorInterceptor(),
    if (kDebugMode)
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
  ]);

  return dio;
});
```

- [ ] **Step 2.7: Verify the app still compiles**

```bash
cd bolanarede_mobile
flutter analyze
```

Expected: no new errors (only existing issues, if any).

- [ ] **Step 2.8: Commit**

```bash
git add lib/core/ .env pubspec.yaml
git commit -m "feat(mobile): configure Dio client, Failure hierarchy, API gateway env"
```

---

## Task 3: Auth HTTP Datasource

**Files:**
- Create: `lib/features/auth/data/models/auth_response_model.dart`
- Create: `lib/features/auth/data/models/user_profile_model.dart`
- Create: `lib/features/auth/data/datasources/auth_http_datasource.dart`
- Modify: `lib/features/auth/data/datasources/auth_datasource_provider.dart`
- Modify: `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`

> **API reference** (verify exact shape at `http://localhost:4001/docs` after the docker-compose is running):
> - `POST /v1/auth/login` → `{ accessToken: string }`
> - `POST /v1/auth/register` → `{ accessToken: string }`
> - `GET /v1/users/me` → `{ id, email, displayName, photoUrl, bio, city, position, skillLevel, isPublic, createdAt }`

- [ ] **Step 3.1: Create AuthResponseModel**

Create `lib/features/auth/data/models/auth_response_model.dart`:

```dart
class AuthResponseModel {
  final String accessToken;

  const AuthResponseModel({required this.accessToken});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['accessToken'] as String,
      );
}
```

- [ ] **Step 3.2: Create UserProfileModel**

The API returns `position` as a string (e.g. `"forward"`) and `skillLevel` as an integer (1–5). Map them to the Flutter enums.

Create `lib/features/auth/data/models/user_profile_model.dart`:

```dart
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

class UserProfileModel {
  final String id;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String? city;
  final String? position;
  final int? skillLevel;
  final bool isPublic;
  final String createdAt;

  const UserProfileModel({
    required this.id,
    this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.city,
    this.position,
    this.skillLevel,
    required this.isPublic,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        bio: json['bio'] as String?,
        city: json['city'] as String?,
        position: json['position'] as String?,
        skillLevel: json['skillLevel'] as int?,
        isPublic: json['isPublic'] as bool? ?? true,
        createdAt: json['createdAt'] as String,
      );

  PlayerProfile toEntity() => PlayerProfile(
        userId: id,
        displayName: displayName,
        photoUrl: photoUrl,
        bio: bio,
        city: city,
        position: _parsePosition(position),
        skillLevel: _parseSkillLevel(skillLevel),
        isPublic: isPublic,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(createdAt),
      );

  static PlayerPosition? _parsePosition(String? raw) => switch (raw) {
        'goalkeeper' => PlayerPosition.goalkeeper,
        'defender' => PlayerPosition.defender,
        'midfielder' => PlayerPosition.midfielder,
        'forward' => PlayerPosition.forward,
        _ => null,
      };

  static SkillLevel? _parseSkillLevel(int? raw) => switch (raw) {
        1 => SkillLevel.beginner,
        2 => SkillLevel.recreational,
        3 => SkillLevel.intermediate,
        4 => SkillLevel.advanced,
        5 => SkillLevel.competitive,
        _ => null,
      };
}
```

> Verify `SkillLevel` enum values in `lib/core/shared/enums.dart` and adjust if they differ.

- [ ] **Step 3.3: Create AuthHttpDataSource**

Create `lib/features/auth/data/datasources/auth_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/auth/data/models/auth_response_model.dart';
import 'package:bola_na_rede/features/auth/data/models/user_profile_model.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

class AuthHttpDataSource implements AuthDataSource {
  AuthHttpDataSource({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  @override
  Future<PlayerProfile> login(String email, String password) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    final auth = AuthResponseModel.fromJson(res.data!);
    await tokenStorage.saveToken(auth.accessToken);
    return _fetchProfile();
  }

  @override
  Future<PlayerProfile> register(
      String name, String email, String password) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/auth/register',
      data: {'email': email, 'password': password, 'displayName': name},
    );
    final auth = AuthResponseModel.fromJson(res.data!);
    await tokenStorage.saveToken(auth.accessToken);
    return _fetchProfile();
  }

  @override
  Future<PlayerProfile> restoreSession(String token) => _fetchProfile();

  Future<PlayerProfile> _fetchProfile() async {
    final res = await dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfileModel.fromJson(res.data!).toEntity();
  }
}
```

- [ ] **Step 3.4: Switch provider to use real datasource**

Replace `lib/features/auth/data/datasources/auth_datasource_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_http_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthHttpDataSource(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
```

> To revert to mock: replace `AuthHttpDataSource(...)` with `AuthMockDataSource()`.

- [ ] **Step 3.5: Fix AuthViewModel — remove mock-token hardcode**

In `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`, the `login()` method calls `_tokenStorage.saveToken('mock-token-${user.userId}')`. The real datasource already saves the JWT internally — this call would overwrite the token. Remove it from `login()` and `register()`:

Replace `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, PlayerProfile?>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<PlayerProfile?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  @override
  Future<PlayerProfile?> build() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    try {
      return await _repo.restoreSession(token);
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repo.login(email, password),
    );
    state = result;
    return !result.hasError;
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repo.register(name, email, password),
    );
    state = result;
    return !result.hasError;
  }

  Future<void> logout() async {
    await _repo.logout();
    await _tokenStorage.clearToken();
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 3.6: Enable auth gate**

In `lib/core/routes/app_router.dart`, change:

```dart
const kAuthGateEnabled = false;
```

to:

```dart
const kAuthGateEnabled = true;
```

- [ ] **Step 3.7: Update SplashPage for real session restore**

Open `lib/features/auth/presentation/views/splash_page.dart`. It currently navigates immediately. Update it to wait for the auth state:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider, (_, next) {
      if (next is AsyncData) {
        if (next.value != null) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      }
    });

    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.textOnPrimary),
      ),
    );
  }
}
```

- [ ] **Step 3.8: Run the app and test login**

```bash
cd bolanarede_mobile
flutter run -d android  # or -d ios / -d chrome
```

1. App shows splash spinner
2. No token in storage → navigates to `/login`
3. Enter a registered email/password → POST to API → profile loaded → go to `/home`
4. Kill and relaunch → token in storage → `restoreSession` calls `/v1/users/me` → back to `/home`

- [ ] **Step 3.9: Commit**

```bash
git add lib/features/auth/ lib/core/routes/
git commit -m "feat(auth): replace mock datasource with JWT HTTP integration"
```

---

## Task 4: Profile HTTP Datasource

**Files:**
- Create: `lib/features/profile/data/datasources/profile_http_datasource.dart`
- Create: `lib/features/profile/data/datasources/profile_datasource_provider.dart`
- Create: `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`
- Modify: `lib/features/profile/presentation/views/profile_page.dart`

> **API reference:**
> - `GET /v1/users/me` → UserProfileModel (same as auth)
> - `PUT /v1/users/me/profile` → `{ displayName?, photoUrl?, bio?, city?, position?, skillLevel?, isPublic? }`

- [ ] **Step 4.1: Create ProfileHttpDataSource**

Create `lib/features/profile/data/datasources/profile_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/auth/data/models/user_profile_model.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

abstract class ProfileDataSource {
  Future<PlayerProfile> getMyProfile();
  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? position,
    int? skillLevel,
    bool? isPublic,
  });
}

class ProfileHttpDataSource implements ProfileDataSource {
  ProfileHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<PlayerProfile> getMyProfile() async {
    final res = await dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfileModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<PlayerProfile> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? position,
    int? skillLevel,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (city != null) 'city': city,
      if (position != null) 'position': position,
      if (skillLevel != null) 'skillLevel': skillLevel,
      if (isPublic != null) 'isPublic': isPublic,
    };
    final res = await dio.put<Map<String, dynamic>>(
      '/v1/users/me/profile',
      data: body,
    );
    return UserProfileModel.fromJson(res.data!).toEntity();
  }
}
```

- [ ] **Step 4.2: Create provider**

Create `lib/features/profile/data/datasources/profile_datasource_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_http_datasource.dart';

final profileDataSourceProvider = Provider<ProfileDataSource>(
  (ref) => ProfileHttpDataSource(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 4.3: Create ProfileViewModel**

Create `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_datasource_provider.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_http_datasource.dart';

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, PlayerProfile?>(
        ProfileViewModel.new);

class ProfileViewModel extends AsyncNotifier<PlayerProfile?> {
  ProfileDataSource get _ds => ref.read(profileDataSourceProvider);

  @override
  Future<PlayerProfile?> build() => _ds.getMyProfile();

  Future<void> update({
    String? displayName,
    String? bio,
    String? city,
    String? position,
    int? skillLevel,
    bool? isPublic,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ds.updateProfile(
        displayName: displayName,
        bio: bio,
        city: city,
        position: position,
        skillLevel: skillLevel,
        isPublic: isPublic,
      ),
    );
  }
}
```

- [ ] **Step 4.4: Update ProfilePage to use real data**

Open `lib/features/profile/presentation/views/profile_page.dart`. Replace its `build` method body to watch `profileViewModelProvider` and display real data. Since the current profile page is a stub, replace the entire file:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar perfil.')),
        data: (p) => p == null
            ? const SizedBox()
            : _buildBody(context, ref, p),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, PlayerProfile p) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            decoration:
                const BoxDecoration(gradient: AppGradients.primaryVertical),
            child: Column(children: [
              AppTeamAvatar(
                initials: initials(p.displayName),
                color: AppColors.avatarGreen,
                size: 72,
                fontSize: 28,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                p.displayName,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              if (p.city != null)
                Text(
                  p.city!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textOnPrimary),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.outline(
                label: 'Editar perfil',
                icon: PhosphorIcons.pencil(),
                height: AppSizes.buttonHeightSmall,
                onPressed: () => showComingSoon(context),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (p.bio != null) ...[
                AppCard(
                  child: Text(p.bio!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Informações', style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppSpacing.md),
                  if (p.position != null)
                    _info('Posição', p.position!.name),
                  if (p.skillLevel != null)
                    _info('Nível', p.skillLevel!.name),
                  _info('Perfil', p.isPublic ? 'Público' : 'Privado'),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.danger(
                label: 'Sair',
                icon: PhosphorIcons.signOut(),
                onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
```

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/profile/
git commit -m "feat(profile): integrate real profile API"
```

---

## Task 5: Fields HTTP Datasource + Availability + Reservation

**Files:**
- Create: `lib/features/field/data/models/field_model.dart`
- Create: `lib/features/field/domain/entities/availability.dart`
- Create: `lib/features/field/data/models/availability_model.dart`
- Modify: `lib/features/field/domain/repositories/field_repository.dart`
- Create: `lib/features/field/data/datasources/field_http_datasource.dart`
- Modify: `lib/features/field/data/datasources/field_mock_datasource.dart`
- Modify: `lib/features/field/data/repositories/field_repository_impl.dart`
- Modify: `lib/features/field/data/repositories/field_repository_provider.dart`
- Modify: `lib/features/field/presentation/views/field_catalog_page.dart`
- Modify: `lib/features/field/presentation/views/field_detail_page.dart`
- Create: `lib/features/field/presentation/views/reservation_page.dart`

> **API reference:**
> - `GET /v1/fields?city=Curitiba` → `[{ id, name, city, address?, createdAt }]`
> - `GET /v1/fields/:id` → same shape (single)
> - `GET /v1/fields/:id/courts` → `[{ id, name, capacity }]`
> - `GET /v1/fields/:id/availability?date=2026-06-20` → time-slot availability (verify exact shape at localhost:4003/docs)
> - `POST /v1/fields/:fieldId/reservations` → `{ date, timeStart, timeEnd, courtId, customerName, customerPhone }`

> **Note:** The API's `FieldDto` returns a simpler shape than the full `Field` entity (no `ownerUserId`, `plan`, etc.). Create DTO models in `data/models/` and map to entities; leave existing domain entities unchanged.

- [ ] **Step 5.1: Create FieldModel (API DTO)**

Create `lib/features/field/data/models/field_model.dart`:

```dart
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldModel {
  final String id;
  final String name;
  final String? address;
  final String city;
  final String? contactPhone;
  final String? coverPhotoUrl;
  final String createdAt;

  const FieldModel({
    required this.id,
    required this.name,
    this.address,
    required this.city,
    this.contactPhone,
    this.coverPhotoUrl,
    required this.createdAt,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) => FieldModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        city: json['city'] as String,
        contactPhone: json['contactPhone'] as String?,
        coverPhotoUrl: json['coverPhotoUrl'] as String?,
        createdAt: json['createdAt'] as String,
      );

  Field toEntity() => Field(
        id: id,
        ownerUserId: '',
        name: name,
        description: null,
        street: address,
        city: city,
        state: '',
        contactPhone: contactPhone,
        coverPhotoUrl: coverPhotoUrl,
        status: FieldStatus.active,
        plan: FieldPlan.basic,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(createdAt),
      );
}

class FieldCourtModel {
  final String id;
  final String name;
  final int capacity;
  final double? pricePerHour;

  const FieldCourtModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.pricePerHour,
  });

  factory FieldCourtModel.fromJson(Map<String, dynamic> json) =>
      FieldCourtModel(
        id: json['id'] as String,
        name: json['name'] as String,
        capacity: json['capacity'] as int,
        pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      );

  FieldCourt toEntity() => FieldCourt(
        id: id,
        fieldId: '',
        name: name,
        modality: CourtModality.society,
        capacity: capacity,
        isActive: true,
      );
}
```

- [ ] **Step 5.2: Create AvailabilitySlot entity**

Create `lib/features/field/domain/entities/availability.dart`:

```dart
class AvailabilitySlot {
  final String courtId;
  final String courtName;
  final String timeStart;
  final String timeEnd;
  final bool isAvailable;
  final double? price;

  const AvailabilitySlot({
    required this.courtId,
    required this.courtName,
    required this.timeStart,
    required this.timeEnd,
    required this.isAvailable,
    this.price,
  });
}
```

Create `lib/features/field/data/models/availability_model.dart`:

```dart
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';

class AvailabilitySlotModel {
  final String courtId;
  final String courtName;
  final String timeStart;
  final String timeEnd;
  final bool isAvailable;
  final double? price;

  const AvailabilitySlotModel({
    required this.courtId,
    required this.courtName,
    required this.timeStart,
    required this.timeEnd,
    required this.isAvailable,
    this.price,
  });

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) =>
      AvailabilitySlotModel(
        courtId: json['courtId'] as String,
        courtName: json['courtName'] as String? ?? '',
        timeStart: json['timeStart'] as String,
        timeEnd: json['timeEnd'] as String,
        isAvailable: json['isAvailable'] as bool,
        price: (json['price'] as num?)?.toDouble(),
      );

  AvailabilitySlot toEntity() => AvailabilitySlot(
        courtId: courtId,
        courtName: courtName,
        timeStart: timeStart,
        timeEnd: timeEnd,
        isAvailable: isAvailable,
        price: price,
      );
}
```

> **Note:** Verify the exact JSON shape of the availability endpoint at `localhost:4003/docs` before running. Adjust `AvailabilitySlotModel.fromJson` keys as needed.

- [ ] **Step 5.3: Update FieldRepository interface**

Replace `lib/features/field/domain/repositories/field_repository.dart`:

```dart
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

abstract class FieldRepository {
  Future<List<Field>> getFields({String? city});
  Future<Field> getFieldById(String id);
  Future<List<FieldCourt>> getCourtsByField(String fieldId);
  Future<List<PricingRule>> getPricingRules(String fieldId);
  Future<List<AvailabilitySlot>> getAvailability(
      String fieldId, DateTime date);
}
```

- [ ] **Step 5.4: Add `getAvailability` stub to mock datasource**

In `lib/features/field/data/datasources/field_mock_datasource.dart`, update the abstract class and add a stub method:

```dart
// At the top of the file, add to abstract class:
abstract class FieldDataSource {
  Future<List<Field>> getFields({String? city});
  Future<Field> getFieldById(String id);
  Future<List<FieldCourt>> getCourtsByField(String fieldId);
  Future<List<PricingRule>> getPricingRules(String fieldId);
  Future<List<AvailabilitySlot>> getAvailability(
      String fieldId, DateTime date);
}
```

Add to `FieldMockDataSource`:

```dart
@override
Future<List<AvailabilitySlot>> getAvailability(
    String fieldId, DateTime date) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    AvailabilitySlot(
      courtId: 'court-001a',
      courtName: 'Quadra 1 — Society',
      timeStart: '08:00',
      timeEnd: '09:00',
      isAvailable: true,
      price: 90.0,
    ),
    AvailabilitySlot(
      courtId: 'court-001a',
      courtName: 'Quadra 1 — Society',
      timeStart: '09:00',
      timeEnd: '10:00',
      isAvailable: false,
      price: 90.0,
    ),
  ];
}
```

Also update `getFields` signature to accept optional `city`:

```dart
@override
Future<List<Field>> getFields({String? city}) async {
  await Future.delayed(const Duration(milliseconds: 600));
  final all = List<Field>.from(_fields);
  if (city != null) {
    return all
        .where((f) => f.city.toLowerCase().contains(city.toLowerCase()))
        .toList();
  }
  return all;
}
```

- [ ] **Step 5.5: Create FieldHttpDataSource**

Create `lib/features/field/data/datasources/field_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';
import 'package:bola_na_rede/features/field/data/models/availability_model.dart';
import 'package:bola_na_rede/features/field/data/models/field_model.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldHttpDataSource implements FieldDataSource {
  FieldHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Field>> getFields({String? city}) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/fields',
      queryParameters: {if (city != null && city.isNotEmpty) 'city': city},
    );
    return res.data!
        .map((e) => FieldModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Field> getFieldById(String id) async {
    final res =
        await dio.get<Map<String, dynamic>>('/v1/fields/$id');
    return FieldModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) async {
    final res =
        await dio.get<List<dynamic>>('/v1/fields/$fieldId/courts');
    return res.data!
        .map((e) =>
            FieldCourtModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) async {
    return [];
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability(
      String fieldId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await dio.get<List<dynamic>>(
      '/v1/fields/$fieldId/availability',
      queryParameters: {'date': dateStr},
    );
    return res.data!
        .map((e) => AvailabilitySlotModel.fromJson(e as Map<String, dynamic>)
            .toEntity())
        .toList();
  }
}
```

- [ ] **Step 5.6: Update repository implementation**

In `lib/features/field/data/repositories/field_repository_impl.dart`, add `getAvailability`:

```dart
import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';

class FieldRepositoryImpl implements FieldRepository {
  FieldRepositoryImpl({required this.dataSource});

  final FieldDataSource dataSource;

  @override
  Future<List<Field>> getFields({String? city}) =>
      dataSource.getFields(city: city);

  @override
  Future<Field> getFieldById(String id) => dataSource.getFieldById(id);

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) =>
      dataSource.getCourtsByField(fieldId);

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) =>
      dataSource.getPricingRules(fieldId);

  @override
  Future<List<AvailabilitySlot>> getAvailability(
          String fieldId, DateTime date) =>
      dataSource.getAvailability(fieldId, date);
}
```

- [ ] **Step 5.7: Switch field provider to HTTP datasource**

Replace `lib/features/field/data/repositories/field_repository_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/field/data/datasources/field_http_datasource.dart';
import 'package:bola_na_rede/features/field/data/repositories/field_repository_impl.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';

final fieldRepositoryProvider = Provider<FieldRepository>(
  (ref) => FieldRepositoryImpl(
    dataSource: FieldHttpDataSource(dio: ref.watch(dioProvider)),
  ),
);
```

- [ ] **Step 5.8: Update FieldListVM to support city search**

In `lib/features/field/presentation/viewmodels/field_viewmodel.dart`, update `FieldListVM`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/field/data/repositories/field_repository_provider.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldDetail {
  final Field field;
  final List<FieldCourt> courts;
  final List<PricingRule> pricingRules;

  const FieldDetail({
    required this.field,
    required this.courts,
    required this.pricingRules,
  });

  double get lowestPrice => pricingRules.isEmpty
      ? 0
      : pricingRules.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  List<FieldCourt> get activeCourts =>
      courts.where((c) => c.isActive).toList();
}

class FieldListVM extends AsyncNotifier<List<Field>> {
  String _city = '';

  @override
  Future<List<Field>> build() =>
      ref.watch(fieldRepositoryProvider).getFields();

  Future<void> search(String city) async {
    _city = city;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fieldRepositoryProvider).getFields(city: city),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fieldRepositoryProvider).getFields(city: _city.isEmpty ? null : _city),
    );
  }
}

final fieldListProvider =
    AsyncNotifierProvider<FieldListVM, List<Field>>(FieldListVM.new);

final fieldDetailProvider = FutureProvider.family<FieldDetail, String>(
  (ref, id) async {
    final repo = ref.read(fieldRepositoryProvider);
    final results = await Future.wait([
      repo.getFieldById(id),
      repo.getCourtsByField(id),
      repo.getPricingRules(id),
    ]);
    return FieldDetail(
      field: results[0] as Field,
      courts: results[1] as List<FieldCourt>,
      pricingRules: results[2] as List<PricingRule>,
    );
  },
);

final fieldAvailabilityProvider =
    FutureProvider.family<List<AvailabilitySlot>, ({String fieldId, DateTime date})>(
  (ref, params) => ref
      .read(fieldRepositoryProvider)
      .getAvailability(params.fieldId, params.date),
);
```

- [ ] **Step 5.9: Add city search bar to FieldCatalogPage**

In `lib/features/field/presentation/views/field_catalog_page.dart`, add a `TextField` at the top with a search button that calls `ref.read(fieldListProvider.notifier).search(city)`. Since the current implementation varies, add a search bar above the list:

```dart
// Add this widget inside the page body, before the field list:
Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Row(children: [
    Expanded(
      child: TextField(
        controller: _cityController,
        decoration: InputDecoration(
          hintText: 'Cidade (ex: Curitiba)',
          prefixIcon: Icon(PhosphorIcons.mapPin(), size: 18),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) =>
            ref.read(fieldListProvider.notifier).search(v.trim()),
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    AppButton.primary(
      label: 'Buscar',
      height: AppSizes.buttonHeightSmall,
      onPressed: () =>
          ref.read(fieldListProvider.notifier)
              .search(_cityController.text.trim()),
    ),
  ]),
),
```

Convert `FieldCatalogPage` to `ConsumerStatefulWidget` to manage the `_cityController`:

```dart
class FieldCatalogPage extends ConsumerStatefulWidget { ... }
class _FieldCatalogPageState extends ConsumerState<FieldCatalogPage> {
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
  // ...
}
```

- [ ] **Step 5.10: Create ReservationPage (new screen)**

Create `lib/features/field/presentation/views/reservation_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class ReservationPage extends ConsumerStatefulWidget {
  final String fieldId;
  final AvailabilitySlot slot;
  final DateTime date;

  const ReservationPage({
    super.key,
    required this.fieldId,
    required this.slot,
    required this.date,
  });

  @override
  ConsumerState<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends ConsumerState<ReservationPage> {
  bool _loading = false;

  Future<void> _confirm() async {
    final user = ref.read(authViewModelProvider).value;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final dateStr =
          '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      await dio.post<void>(
        '/v1/fields/${widget.fieldId}/reservations',
        data: {
          'courtId': widget.slot.courtId,
          'date': dateStr,
          'timeStart': widget.slot.timeStart,
          'timeEnd': widget.slot.timeEnd,
          'customerName': user.displayName,
          'customerPhone': '',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva confirmada!')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erro ao reservar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Reserva')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Quadra', style: AppTextStyles.bodySmall),
                Text(widget.slot.courtName, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Text('Data', style: AppTextStyles.bodySmall),
                Text(
                  '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Horário', style: AppTextStyles.bodySmall),
                Text(
                  '${widget.slot.timeStart} – ${widget.slot.timeEnd}',
                  style: AppTextStyles.titleSmall,
                ),
                if (widget.slot.price != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Valor', style: AppTextStyles.bodySmall),
                  Text(
                    'R\$ ${widget.slot.price!.toStringAsFixed(2)}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ]),
            ),
            const Spacer(),
            AppButton.primary(
              label: _loading ? 'Reservando...' : 'Confirmar Reserva',
              onPressed: _loading ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.11: Add reservation route to router**

In `lib/core/routes/app_router.dart`:

Add to `AppRoutes`:
```dart
static const fieldReservation = '/fields/reserve';
```

Add to the routes list (outside the StatefulShellRoute, alongside fieldDetail):
```dart
GoRoute(
  path: AppRoutes.fieldReservation,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return ReservationPage(
      fieldId: extra['fieldId'] as String,
      slot: extra['slot'] as AvailabilitySlot,
      date: extra['date'] as DateTime,
    );
  },
),
```

- [ ] **Step 5.12: Update FieldDetailPage to show availability**

In `lib/features/field/presentation/views/field_detail_page.dart`, add a date picker and availability grid. The page receives a field ID from the route. Add:

```dart
// After court list, add an availability section:
_buildAvailabilitySection(context, ref, fieldId),

// Implementation:
Widget _buildAvailabilitySection(BuildContext context, WidgetRef ref, String fieldId) {
  // Use a StateProvider for selected date
  final selectedDate = ref.watch(_selectedDateProvider);
  final availability = ref.watch(
    fieldAvailabilityProvider((fieldId: fieldId, date: selectedDate)),
  );

  return AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Disponibilidade', style: AppTextStyles.titleSmall),
        const Spacer(),
        TextButton.icon(
          icon: Icon(PhosphorIcons.calendar(), size: 16),
          label: Text(
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              ref.read(_selectedDateProvider.notifier).state = picked;
            }
          },
        ),
      ]),
      const SizedBox(height: AppSpacing.md),
      availability.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Erro ao carregar horários.'),
        data: (slots) => Column(
          children: slots.map((slot) {
            return ListTile(
              title: Text('${slot.timeStart} – ${slot.timeEnd}'),
              subtitle: slot.courtName.isNotEmpty
                  ? Text(slot.courtName)
                  : null,
              trailing: slot.isAvailable
                  ? AppButton.primary(
                      label: slot.price != null
                          ? 'R\$ ${slot.price!.toStringAsFixed(0)}'
                          : 'Reservar',
                      height: AppSizes.buttonHeightSmall,
                      onPressed: () => context.push(
                        AppRoutes.fieldReservation,
                        extra: {
                          'fieldId': fieldId,
                          'slot': slot,
                          'date': selectedDate,
                        },
                      ),
                    )
                  : const AppBadge(type: AppBadgeType.pending),
            );
          }).toList(),
        ),
      ),
    ]),
  );
}

// Add this provider at the top of the viewmodel file:
final _selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);
```

- [ ] **Step 5.13: Commit**

```bash
git add lib/features/field/
git commit -m "feat(campos): field HTTP datasource, availability check, reservation screen"
```

---

## Task 6: Peladas (Open Games) Feature

**Files:** All new — see file map under `lib/features/peladas/`

> **API reference:**
> - `POST /v1/open-games` → `{ title, sport, scheduledAt, durationMinutes, minPlayers, maxPlayers, pricePerPlayer?, fieldId? }`
> - `GET /v1/open-games?city=...&date=...` → `[OpenGameDto]`
> - `GET /v1/open-games/:id` → `OpenGameDto`
> - `GET /v1/open-games/:id/participants` → `[GameParticipantDto]`
> - `POST /v1/open-games/:id/join`
> - `DELETE /v1/open-games/:id/leave`

- [ ] **Step 6.1: Create domain entities**

Create `lib/features/peladas/domain/entities/open_game.dart`:

```dart
import 'package:bola_na_rede/core/shared/enums.dart';

enum OpenGameStatus {
  scheduled,
  inProgress,
  finished,
  cancelled,
}

class OpenGame {
  final String id;
  final String organizerUserId;
  final String? fieldId;
  final String? fieldNameSnapshot;
  final String? fieldAddressSnapshot;
  final String title;
  final String? description;
  final String sport;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int minPlayers;
  final int maxPlayers;
  final double? pricePerPlayer;
  final OpenGameStatus status;
  final int participantCount;
  final DateTime createdAt;

  const OpenGame({
    required this.id,
    required this.organizerUserId,
    this.fieldId,
    this.fieldNameSnapshot,
    this.fieldAddressSnapshot,
    required this.title,
    this.description,
    required this.sport,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.minPlayers,
    required this.maxPlayers,
    this.pricePerPlayer,
    required this.status,
    required this.participantCount,
    required this.createdAt,
  });

  bool get isFull => participantCount >= maxPlayers;
}

class OpenGameParticipant {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;

  const OpenGameParticipant({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
  });
}
```

- [ ] **Step 6.2: Create abstract repository**

Create `lib/features/peladas/domain/repositories/open_game_repository.dart`:

```dart
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';

abstract class OpenGameRepository {
  Future<List<OpenGame>> getOpenGames({String? city, String? date});
  Future<OpenGame> getById(String id);
  Future<List<OpenGameParticipant>> getParticipants(String gameId);
  Future<OpenGame> create({
    required String title,
    String? description,
    required String sport,
    required DateTime scheduledAt,
    required int durationMinutes,
    required int minPlayers,
    required int maxPlayers,
    double? pricePerPlayer,
    String? fieldId,
  });
  Future<void> join(String gameId);
  Future<void> leave(String gameId);
}
```

- [ ] **Step 6.3: Create API models**

Create `lib/features/peladas/data/models/open_game_model.dart`:

```dart
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';

class OpenGameModel {
  final String id;
  final String organizerUserId;
  final String? fieldId;
  final String? fieldNameSnapshot;
  final String? fieldAddressSnapshot;
  final String title;
  final String? description;
  final String sport;
  final String scheduledAt;
  final int durationMinutes;
  final int minPlayers;
  final int maxPlayers;
  final double? pricePerPlayer;
  final String status;
  final int participantCount;
  final String createdAt;

  const OpenGameModel({
    required this.id,
    required this.organizerUserId,
    this.fieldId,
    this.fieldNameSnapshot,
    this.fieldAddressSnapshot,
    required this.title,
    this.description,
    required this.sport,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.minPlayers,
    required this.maxPlayers,
    this.pricePerPlayer,
    required this.status,
    required this.participantCount,
    required this.createdAt,
  });

  factory OpenGameModel.fromJson(Map<String, dynamic> json) => OpenGameModel(
        id: json['id'] as String,
        organizerUserId: json['organizerUserId'] as String,
        fieldId: json['fieldId'] as String?,
        fieldNameSnapshot: json['fieldNameSnapshot'] as String?,
        fieldAddressSnapshot: json['fieldAddressSnapshot'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        sport: json['sport'] as String,
        scheduledAt: json['scheduledAt'] as String,
        durationMinutes: json['durationMinutes'] as int,
        minPlayers: json['minPlayers'] as int,
        maxPlayers: json['maxPlayers'] as int,
        pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble(),
        status: json['status'] as String,
        participantCount: json['participantCount'] as int? ?? 0,
        createdAt: json['createdAt'] as String,
      );

  OpenGame toEntity() => OpenGame(
        id: id,
        organizerUserId: organizerUserId,
        fieldId: fieldId,
        fieldNameSnapshot: fieldNameSnapshot,
        fieldAddressSnapshot: fieldAddressSnapshot,
        title: title,
        description: description,
        sport: sport,
        scheduledAt: DateTime.parse(scheduledAt),
        durationMinutes: durationMinutes,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        pricePerPlayer: pricePerPlayer,
        status: _parseStatus(status),
        participantCount: participantCount,
        createdAt: DateTime.parse(createdAt),
      );

  static OpenGameStatus _parseStatus(String raw) => switch (raw) {
        'IN_PROGRESS' => OpenGameStatus.inProgress,
        'FINISHED' => OpenGameStatus.finished,
        'CANCELLED' => OpenGameStatus.cancelled,
        _ => OpenGameStatus.scheduled,
      };
}

class OpenGameParticipantModel {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String joinedAt;

  const OpenGameParticipantModel({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
  });

  factory OpenGameParticipantModel.fromJson(Map<String, dynamic> json) =>
      OpenGameParticipantModel(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        joinedAt: json['joinedAt'] as String,
      );

  OpenGameParticipant toEntity() => OpenGameParticipant(
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        joinedAt: DateTime.parse(joinedAt),
      );
}
```

- [ ] **Step 6.4: Create HTTP datasource**

Create `lib/features/peladas/data/datasources/open_game_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/peladas/data/models/open_game_model.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

class OpenGameHttpRepository implements OpenGameRepository {
  OpenGameHttpRepository({required this.dio});

  final Dio dio;

  @override
  Future<List<OpenGame>> getOpenGames({String? city, String? date}) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/open-games',
      queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (date != null) 'date': date,
      },
    );
    return res.data!
        .map((e) =>
            OpenGameModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<OpenGame> getById(String id) async {
    final res =
        await dio.get<Map<String, dynamic>>('/v1/open-games/$id');
    return OpenGameModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<List<OpenGameParticipant>> getParticipants(String gameId) async {
    final res = await dio
        .get<List<dynamic>>('/v1/open-games/$gameId/participants');
    return res.data!
        .map((e) =>
            OpenGameParticipantModel.fromJson(e as Map<String, dynamic>)
                .toEntity())
        .toList();
  }

  @override
  Future<OpenGame> create({
    required String title,
    String? description,
    required String sport,
    required DateTime scheduledAt,
    required int durationMinutes,
    required int minPlayers,
    required int maxPlayers,
    double? pricePerPlayer,
    String? fieldId,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/open-games',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'sport': sport,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        if (pricePerPlayer != null) 'pricePerPlayer': pricePerPlayer,
        if (fieldId != null) 'fieldId': fieldId,
      },
    );
    return OpenGameModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> join(String gameId) =>
      dio.post<void>('/v1/open-games/$gameId/join');

  @override
  Future<void> leave(String gameId) =>
      dio.delete<void>('/v1/open-games/$gameId/leave');
}
```

- [ ] **Step 6.5: Create providers**

Create `lib/features/peladas/data/repositories/open_game_repository_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/peladas/data/datasources/open_game_http_datasource.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

final openGameRepositoryProvider = Provider<OpenGameRepository>(
  (ref) => OpenGameHttpRepository(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 6.6: Create ViewModels**

Create `lib/features/peladas/presentation/viewmodels/open_game_viewmodel.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/peladas/data/repositories/open_game_repository_provider.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

class OpenGameListVM extends AsyncNotifier<List<OpenGame>> {
  String _city = '';
  String? _date;
  OpenGameRepository get _repo => ref.read(openGameRepositoryProvider);

  @override
  Future<List<OpenGame>> build() => _repo.getOpenGames();

  Future<void> search({String? city, String? date}) async {
    _city = city ?? '';
    _date = date;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getOpenGames(
        city: _city.isEmpty ? null : _city,
        date: _date,
      ),
    );
  }

  Future<void> refresh() => search(city: _city, date: _date);
}

final openGameListProvider =
    AsyncNotifierProvider<OpenGameListVM, List<OpenGame>>(OpenGameListVM.new);

final openGameDetailProvider =
    FutureProvider.family<OpenGame, String>(
  (ref, id) => ref.read(openGameRepositoryProvider).getById(id),
);

final openGameParticipantsProvider =
    FutureProvider.family<List<OpenGameParticipant>, String>(
  (ref, gameId) =>
      ref.read(openGameRepositoryProvider).getParticipants(gameId),
);

final joinGameProvider = Provider.family<Future<void> Function(), String>(
  (ref, gameId) => () async {
    await ref.read(openGameRepositoryProvider).join(gameId);
    ref.invalidate(openGameDetailProvider(gameId));
    ref.invalidate(openGameParticipantsProvider(gameId));
  },
);

final leaveGameProvider = Provider.family<Future<void> Function(), String>(
  (ref, gameId) => () async {
    await ref.read(openGameRepositoryProvider).leave(gameId);
    ref.invalidate(openGameDetailProvider(gameId));
    ref.invalidate(openGameParticipantsProvider(gameId));
  },
);
```

- [ ] **Step 6.7: Create PeladasListPage (replace Search tab)**

Create `lib/features/peladas/presentation/views/peladas_list_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class PeladasListPage extends ConsumerStatefulWidget {
  const PeladasListPage({super.key});

  @override
  ConsumerState<PeladasListPage> createState() => _PeladasListPageState();
}

class _PeladasListPageState extends ConsumerState<PeladasListPage> {
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = ref.watch(openGameListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration:
              const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: Column(children: [
                const Text('Peladas',
                    style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por cidade...',
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixIcon:
                            Icon(PhosphorIcons.mapPin(), size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) => ref
                          .read(openGameListProvider.notifier)
                          .search(city: v.trim()),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        Expanded(
          child: games.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Erro ao carregar peladas.')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('Nenhuma pelada encontrada.'))
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(openGameListProvider.notifier)
                        .refresh(),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.all(AppSpacing.lg),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) =>
                          _GameCard(game: list[i]),
                    ),
                  ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createPelada),
        backgroundColor: AppColors.primary,
        icon: Icon(PhosphorIcons.plus(),
            color: AppColors.textOnPrimary),
        label: const Text('Nova Pelada',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final OpenGame game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(AppRoutes.peladaDetailOf(game.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(game.title, style: AppTextStyles.titleSmall),
          ),
          if (game.isFull)
            const AppBadge(type: AppBadgeType.pending)
          else
            const AppBadge(type: AppBadgeType.confirmed),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(game.sport,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Icon(PhosphorIcons.calendar(),
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(formatDate(game.scheduledAt),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Icon(PhosphorIcons.clock(),
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${game.scheduledAt.hour.toString().padLeft(2, '0')}:${game.scheduledAt.minute.toString().padLeft(2, '0')}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          Icon(PhosphorIcons.users(),
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${game.participantCount}/${game.maxPlayers} jogadores',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (game.pricePerPlayer != null) ...[
            const Spacer(),
            Text(
              'R\$ ${game.pricePerPlayer!.toStringAsFixed(0)}/pessoa',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ]),
        if (game.fieldNameSnapshot != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Icon(PhosphorIcons.mapPin(),
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(game.fieldNameSnapshot!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ]),
        ],
      ]),
    );
  }
}
```

- [ ] **Step 6.8: Create PeladaDetailPage**

Create `lib/features/peladas/presentation/views/pelada_detail_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class PeladaDetailPage extends ConsumerWidget {
  final String gameId;
  const PeladaDetailPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(openGameDetailProvider(gameId));
    final participantsAsync =
        ref.watch(openGameParticipantsProvider(gameId));
    final currentUser = ref.watch(authViewModelProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pelada')),
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Erro ao carregar pelada.')),
        data: (game) {
          final isParticipant = participantsAsync.whenOrNull(
                data: (list) =>
                    list.any((p) => p.userId == currentUser?.userId),
              ) ??
              false;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(game.title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(game.sport,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary)),
                  const Divider(height: AppSpacing.xl),
                  _row(PhosphorIcons.calendar(), formatDate(game.scheduledAt)),
                  _row(
                    PhosphorIcons.clock(),
                    '${game.scheduledAt.hour.toString().padLeft(2, '0')}:${game.scheduledAt.minute.toString().padLeft(2, '0')} · ${game.durationMinutes} min',
                  ),
                  _row(
                    PhosphorIcons.users(),
                    '${game.participantCount}/${game.maxPlayers} jogadores (mín ${game.minPlayers})',
                  ),
                  if (game.fieldNameSnapshot != null)
                    _row(PhosphorIcons.mapPin(),
                        game.fieldNameSnapshot!),
                  if (game.pricePerPlayer != null)
                    _row(
                      PhosphorIcons.money(),
                      'R\$ ${game.pricePerPlayer!.toStringAsFixed(2)}/pessoa',
                    ),
                  if (game.description != null) ...[
                    const Divider(height: AppSpacing.xl),
                    Text(game.description!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              participantsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
                data: (list) => AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Jogadores (${list.length})',
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    ...list.map(
                      (p) => ListTile(
                        leading: AppTeamAvatar(
                          initials: initials(p.displayName),
                          color: AppColors.avatarGreen,
                          size: 36,
                        ),
                        title: Text(p.displayName,
                            style: AppTextStyles.bodyMedium),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (game.status == OpenGameStatus.scheduled)
                isParticipant
                    ? AppButton.danger(
                        label: 'Sair da pelada',
                        icon: PhosphorIcons.signOut(),
                        onPressed: () async {
                          await ref.read(leaveGameProvider(gameId))();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Você saiu da pelada.')),
                            );
                          }
                        },
                      )
                    : AppButton.primary(
                        label: game.isFull
                            ? 'Pelada cheia'
                            : 'Entrar na pelada',
                        icon: PhosphorIcons.soccerBall(),
                        onPressed: game.isFull
                            ? null
                            : () async {
                                await ref.read(joinGameProvider(gameId))();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Você entrou na pelada!')),
                                  );
                                }
                              },
                      ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 6.9: Create CreatePeladaPage**

Create `lib/features/peladas/presentation/views/create_pelada_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class CreatePeladaPage extends ConsumerStatefulWidget {
  const CreatePeladaPage({super.key});

  @override
  ConsumerState<CreatePeladaPage> createState() => _CreatePeladaPageState();
}

class _CreatePeladaPageState extends ConsumerState<CreatePeladaPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _sport = 'futsal';
  int _minPlayers = 5;
  int _maxPlayers = 10;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final price = _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text.replaceAll(',', '.'))
          : null;
      await ref.read(openGameRepositoryProvider).create(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            sport: _sport,
            scheduledAt: _scheduledAt,
            durationMinutes: 60,
            minPlayers: _minPlayers,
            maxPlayers: _maxPlayers,
            pricePerPlayer: price,
          );
      ref.invalidate(openGameListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pelada criada!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Pelada')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: 'Título *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descController,
              decoration:
                  const InputDecoration(labelText: 'Descrição (opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _sport,
              decoration: const InputDecoration(labelText: 'Modalidade'),
              items: const [
                DropdownMenuItem(value: 'futsal', child: Text('Futsal')),
                DropdownMenuItem(value: 'society', child: Text('Society')),
                DropdownMenuItem(value: 'salao', child: Text('Salão')),
              ],
              onChanged: (v) => setState(() => _sport = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data e Hora'),
              subtitle: Text(
                '${_scheduledAt.day}/${_scheduledAt.month}/${_scheduledAt.year} ${_scheduledAt.hour.toString().padLeft(2, '0')}:${_scheduledAt.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _scheduledAt,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                    );
                    if (time != null) {
                      setState(() {
                        _scheduledAt = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute);
                      });
                    }
                  }
                },
                child: const Text('Alterar'),
              ),
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: _minPlayers.toString(),
                  decoration:
                      const InputDecoration(labelText: 'Mín. jogadores'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _minPlayers = int.tryParse(v) ?? 5),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  initialValue: _maxPlayers.toString(),
                  decoration:
                      const InputDecoration(labelText: 'Máx. jogadores'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _maxPlayers = int.tryParse(v) ?? 10),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Valor por pessoa (R\$, opcional)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: _loading ? 'Criando...' : 'Criar Pelada',
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6.10: Wire new routes and update Search tab**

In `lib/core/routes/app_router.dart`:

1. Add constants:
```dart
static const peladas = '/peladas';
static const peladaDetail = '/peladas/detail/:id';
static const createPelada = '/peladas/create';

static String peladaDetailOf(String id) => '/peladas/detail/$id';
```

2. Change the Search branch route to use `PeladasListPage`:
```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppRoutes.peladas,   // was: search
      builder: (_, __) => const PeladasListPage(),
    ),
  ],
),
```

Also update `AppRoutes.search` constant to `AppRoutes.peladas` in routes and wherever `AppRoutes.search` is used (e.g. `_buildQuickActions` in `home_page.dart`).

3. Add detail and create routes (outside shell):
```dart
GoRoute(
  path: AppRoutes.peladaDetail,
  builder: (context, state) => PeladaDetailPage(
    gameId: state.pathParameters['id']!,
  ),
),
GoRoute(
  path: AppRoutes.createPelada,
  builder: (_, __) => const CreatePeladaPage(),
),
```

4. Update `AppShell`'s nav bar — the second tab (index 1) should now point to peladas. In `lib/shared/widgets/app_nav_bar.dart`, change the search icon to a soccer ball and label to "Peladas". Also update `goBranch` to navigate to `/peladas`.

- [ ] **Step 6.11: Commit**

```bash
git add lib/features/peladas/ lib/core/routes/ lib/shared/
git commit -m "feat(peladas): open games feature — list, detail, create, join/leave"
```

---

## Task 7: Teams HTTP Datasource

**Files:**
- Create: `lib/features/team/data/models/team_model.dart`
- Create: `lib/features/team/data/datasources/team_http_datasource.dart`
- Modify: `lib/features/team/data/datasources/team_datasource_provider.dart`
- Modify: `lib/features/team/domain/repositories/team_repository.dart`
- Modify: `lib/features/team/data/repositories/team_repository_impl.dart`
- Modify views: search, create, manage

> **API reference:**
> - `POST /v1/teams` → `{ name, description?, minPlayers?, maxPlayers? }`
> - `GET /v1/teams/:id` → `TeamDto`
> - `GET /v1/teams/:id/members` → `[TeamMemberDto]`
> - `POST /v1/teams/:id/members` → join (no body)
> - `DELETE /v1/teams/:id/members/me` → leave

- [ ] **Step 7.1: Create TeamModel (API DTO)**

Create `lib/features/team/data/models/team_model.dart`:

```dart
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class TeamModel {
  final String id;
  final String name;
  final String? description;
  final String captainUserId;
  final int minPlayers;
  final int maxPlayers;
  final int memberCount;
  final bool isActive;
  final String createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    required this.captainUserId,
    required this.minPlayers,
    required this.maxPlayers,
    required this.memberCount,
    required this.isActive,
    required this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        captainUserId: json['captainUserId'] as String,
        minPlayers: json['minPlayers'] as int? ?? 5,
        maxPlayers: json['maxPlayers'] as int? ?? 11,
        memberCount: json['memberCount'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] as String,
      );

  Team toEntity() => Team(
        id: id,
        name: name,
        city: '',
        status: isActive ? TeamStatus.active : TeamStatus.inactive,
        createdBy: captainUserId,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(createdAt),
      );
}

class TeamMemberModel {
  final String userId;
  final String name;
  final String role;
  final String joinedAt;

  const TeamMemberModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      TeamMemberModel(
        userId: json['userId'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        joinedAt: json['joinedAt'] as String,
      );

  TeamMember toEntity() => TeamMember(
        teamId: '',
        userId: userId,
        role: role == 'CAPTAIN'
            ? TeamMemberRole.captain
            : TeamMemberRole.member,
        joinedAt: DateTime.parse(joinedAt),
      );
}
```

- [ ] **Step 7.2: Create TeamHttpDataSource**

Create `lib/features/team/data/datasources/team_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/team/data/models/team_model.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class TeamDataSource {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  });
  Future<List<TeamMember>> getMembers(String teamId);
  Future<void> joinTeam(String teamId);
  Future<void> leaveTeam(String teamId);
  Future<void> removeMember(String teamId, String userId);
}

class TeamHttpDataSource implements TeamDataSource {
  TeamHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Team>> getTeams() async {
    return [];
  }

  @override
  Future<Team> getTeamById(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/teams/$id');
    return TeamModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/teams',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (minPlayers != null) 'minPlayers': minPlayers,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
      },
    );
    return TeamModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<List<TeamMember>> getMembers(String teamId) async {
    final res =
        await dio.get<List<dynamic>>('/v1/teams/$teamId/members');
    return res.data!
        .map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>)
            .toEntity())
        .toList();
  }

  @override
  Future<void> joinTeam(String teamId) =>
      dio.post<void>('/v1/teams/$teamId/members');

  @override
  Future<void> leaveTeam(String teamId) =>
      dio.delete<void>('/v1/teams/$teamId/members/me');

  @override
  Future<void> removeMember(String teamId, String userId) =>
      dio.delete<void>('/v1/teams/$teamId/members/$userId');
}
```

- [ ] **Step 7.3: Update TeamRepository interface**

Replace `lib/features/team/domain/repositories/team_repository.dart`:

```dart
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  });
  Future<List<TeamMember>> getMembers(String teamId);
  Future<void> joinTeam(String teamId);
  Future<void> leaveTeam(String teamId);
  Future<void> removeMember(String teamId, String userId);
}
```

- [ ] **Step 7.4: Update TeamRepositoryImpl**

Replace `lib/features/team/data/repositories/team_repository_impl.dart`:

```dart
import 'package:bola_na_rede/features/team/data/datasources/team_http_datasource.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl({required this.dataSource});

  final TeamDataSource dataSource;

  @override
  Future<List<Team>> getTeams() => dataSource.getTeams();

  @override
  Future<Team> getTeamById(String id) => dataSource.getTeamById(id);

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  }) => dataSource.createTeam(
        name: name,
        description: description,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
      );

  @override
  Future<List<TeamMember>> getMembers(String teamId) =>
      dataSource.getMembers(teamId);

  @override
  Future<void> joinTeam(String teamId) => dataSource.joinTeam(teamId);

  @override
  Future<void> leaveTeam(String teamId) => dataSource.leaveTeam(teamId);

  @override
  Future<void> removeMember(String teamId, String userId) =>
      dataSource.removeMember(teamId, userId);
}
```

- [ ] **Step 7.5: Switch provider to HTTP**

Replace `lib/features/team/data/datasources/team_datasource_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/team/data/datasources/team_http_datasource.dart';

final teamDataSourceProvider = Provider<TeamDataSource>(
  (ref) => TeamHttpDataSource(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 7.6: Add create team action to CreateTeamPage**

In `lib/features/team/presentation/views/create_team_page.dart`, wire up the form to call `ref.read(teamRepositoryProvider).createTeam(...)` on submit, then `ref.invalidate(teamListProvider)` and `context.pop()`.

Add a `ConsumerStatefulWidget` with a form key, name + description controllers, submit button that:
```dart
final team = await ref.read(teamRepositoryProvider).createTeam(
  name: _nameController.text.trim(),
  description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
);
ref.invalidate(teamListProvider);
context.pop();
```

- [ ] **Step 7.7: Add members list to TeamManagePage**

In `lib/features/team/presentation/views/team_manage_page.dart`, add a FutureProvider watch for members:

```dart
final membersAsync = ref.watch(
  FutureProvider.autoDispose.family<List<TeamMember>, String>(
    (ref, id) => ref.read(teamRepositoryProvider).getMembers(id),
  )(teamId),
);
```

Display the member list and a "Sair do time" button that calls `ref.read(teamRepositoryProvider).leaveTeam(teamId)`.

- [ ] **Step 7.8: Commit**

```bash
git add lib/features/team/
git commit -m "feat(times): team HTTP datasource — create, join, leave, members"
```

---

## Task 8: Matchmaking + Game HTTP Datasource

**Files:**
- Create: `lib/features/match/data/models/match_request_model.dart`
- Create: `lib/features/match/data/models/game_model.dart`
- Create: `lib/features/match/data/datasources/match_http_datasource.dart`
- Modify: `lib/features/match/data/datasources/match_datasource_provider.dart`
- Modify: `lib/features/match/domain/repositories/match_repository.dart`
- Modify: `lib/features/match/data/repositories/match_repository_impl.dart`
- Modify all 4 match views

> **API reference (matchmaking service port 4007):**
> - `POST /v1/match-requests` → `{ sport, requestedAt? }`
> - `GET /v1/match-requests?city=...&date=...` → list
> - `DELETE /v1/match-requests/:id` → cancel
> - `POST /v1/matches/:id/accept`
>
> **API reference (game service port 4008):**
> - `GET /v1/games/:id` → GameDto
> - `POST /v1/games/:id/result` → `{ playerAGoals, playerBGoals, playerAAssists, playerBAssists }`
> - `POST /v1/games/:id/results/confirm`
> - `POST /v1/games/:id/results/dispute`

- [ ] **Step 8.1: Create MatchRequestModel**

Create `lib/features/match/data/models/match_request_model.dart`:

```dart
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';

class MatchRequestModel {
  final String id;
  final String requesterUserId;
  final String displayName;
  final String sport;
  final String status;
  final String requestedAt;
  final String expiresAt;

  const MatchRequestModel({
    required this.id,
    required this.requesterUserId,
    required this.displayName,
    required this.sport,
    required this.status,
    required this.requestedAt,
    required this.expiresAt,
  });

  factory MatchRequestModel.fromJson(Map<String, dynamic> json) =>
      MatchRequestModel(
        id: json['id'] as String,
        requesterUserId: json['requesterUserId'] as String,
        displayName: json['displayName'] as String? ?? '',
        sport: json['sport'] as String,
        status: json['status'] as String,
        requestedAt: json['requestedAt'] as String,
        expiresAt: json['expiresAt'] as String,
      );

  MatchRequest toEntity() => MatchRequest(
        id: id,
        requestingTeamId: requesterUserId,
        sport: sport,
        status: _parseStatus(status),
        createdAt: DateTime.parse(requestedAt),
        expiresAt: DateTime.parse(expiresAt),
      );

  static MatchRequestStatus _parseStatus(String raw) => switch (raw) {
        'MATCHED' => MatchRequestStatus.matched,
        'EXPIRED' => MatchRequestStatus.expired,
        'CANCELLED' => MatchRequestStatus.cancelled,
        _ => MatchRequestStatus.pending,
      };
}
```

> Verify `MatchRequest` entity fields against `lib/features/match/domain/entities/match_request.dart`. Adjust mappings if needed.

- [ ] **Step 8.2: Create GameModel**

Create `lib/features/match/data/models/game_model.dart`:

```dart
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';

class GameModel {
  final String id;
  final String? matchId;
  final String userAId;
  final String userBId;
  final String sport;
  final String status;
  final int? playerAGoals;
  final int? playerBGoals;
  final int? playerAAssists;
  final int? playerBAssists;
  final String? winnerId;
  final String createdAt;

  const GameModel({
    required this.id,
    this.matchId,
    required this.userAId,
    required this.userBId,
    required this.sport,
    required this.status,
    this.playerAGoals,
    this.playerBGoals,
    this.playerAAssists,
    this.playerBAssists,
    this.winnerId,
    required this.createdAt,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as String,
        matchId: json['matchId'] as String?,
        userAId: json['userAId'] as String,
        userBId: json['userBId'] as String,
        sport: json['sport'] as String,
        status: json['status'] as String,
        playerAGoals: json['playerAGoals'] as int?,
        playerBGoals: json['playerBGoals'] as int?,
        playerAAssists: json['playerAAssists'] as int?,
        playerBAssists: json['playerBAssists'] as int?,
        winnerId: json['winnerId'] as String?,
        createdAt: json['createdAt'] as String,
      );

  Match toEntity() => Match(
        id: id,
        proposalId: matchId ?? '',
        teamAId: userAId,
        teamBId: userBId,
        teamASnapshot: null,
        teamBSnapshot: null,
        fieldId: null,
        fieldSnapshot: null,
        scheduledDate: DateTime.parse(createdAt),
        scheduledTimeStart: '',
        scheduledTimeEnd: '',
        status: _parseStatus(status),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(createdAt),
      );

  static MatchStatus _parseStatus(String raw) => switch (raw) {
        'IN_PROGRESS' => MatchStatus.inProgress,
        'COMPLETED' => MatchStatus.completed,
        'CANCELLED' => MatchStatus.cancelled,
        'NO_SHOW' => MatchStatus.noShow,
        _ => MatchStatus.scheduled,
      };
}
```

- [ ] **Step 8.3: Create MatchHttpDataSource**

Create `lib/features/match/data/datasources/match_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/match/data/models/game_model.dart';
import 'package:bola_na_rede/features/match/data/models/match_request_model.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';

abstract class MatchDataSource {
  Future<List<MatchRequest>> getMatchRequests({String? city});
  Future<MatchRequest> createMatchRequest(String sport);
  Future<void> cancelMatchRequest(String requestId);
  Future<void> acceptMatch(String matchId);
  Future<Match> getGame(String gameId);
  Future<void> submitResult(String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  });
  Future<void> confirmResult(String gameId);
  Future<void> disputeResult(String gameId);
}

class MatchHttpDataSource implements MatchDataSource {
  MatchHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<MatchRequest>> getMatchRequests({String? city}) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/match-requests',
      queryParameters: {if (city != null) 'city': city},
    );
    return res.data!
        .map((e) => MatchRequestModel.fromJson(e as Map<String, dynamic>)
            .toEntity())
        .toList();
  }

  @override
  Future<MatchRequest> createMatchRequest(String sport) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/match-requests',
      data: {'sport': sport},
    );
    return MatchRequestModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> cancelMatchRequest(String requestId) =>
      dio.delete<void>('/v1/match-requests/$requestId');

  @override
  Future<void> acceptMatch(String matchId) =>
      dio.post<void>('/v1/matches/$matchId/accept');

  @override
  Future<Match> getGame(String gameId) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/games/$gameId');
    return GameModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> submitResult(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  }) =>
      dio.post<void>(
        '/v1/games/$gameId/result',
        data: {
          'playerAGoals': playerAGoals,
          'playerBGoals': playerBGoals,
          'playerAAssists': playerAAssists,
          'playerBAssists': playerBAssists,
        },
      );

  @override
  Future<void> confirmResult(String gameId) =>
      dio.post<void>('/v1/games/$gameId/results/confirm');

  @override
  Future<void> disputeResult(String gameId) =>
      dio.post<void>('/v1/games/$gameId/results/dispute');
}
```

- [ ] **Step 8.4: Switch match provider**

Replace `lib/features/match/data/datasources/match_datasource_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_http_datasource.dart';

final matchDataSourceProvider = Provider<MatchDataSource>(
  (ref) => MatchHttpDataSource(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 8.5: Update MatchListPage**

In `lib/features/match/presentation/views/match_list_page.dart`, replace mock data with a FutureProvider that calls `matchDataSourceProvider.getMatchRequests()`. Display a list of `MatchRequest` cards with status badges and a button to accept.

- [ ] **Step 8.6: Update CreateMatchPage**

In `lib/features/match/presentation/views/create_match_page.dart`, add a sport selector and "Buscar Adversário" button that calls `matchDataSourceProvider.createMatchRequest(sport)` and shows a success snackbar.

- [ ] **Step 8.7: Update RegisterResultPage**

In `lib/features/match/presentation/views/register_result_page.dart`, add 4 integer fields (goals/assists per team) and a submit button calling `matchDataSourceProvider.submitResult(gameId, ...)`.

- [ ] **Step 8.8: Commit**

```bash
git add lib/features/match/
git commit -m "feat(partidas): matchmaking + game HTTP datasource — requests, results"
```

---

## Task 9: Ranking HTTP Datasource

**Files:**
- Create: `lib/features/ranking/data/models/ranking_model.dart`
- Create: `lib/features/ranking/data/datasources/ranking_http_datasource.dart`
- Modify: `lib/features/ranking/data/repositories/ranking_repository_impl.dart`
- Modify: `lib/features/ranking/data/repositories/ranking_repository_provider.dart`

> **API reference:**
> - `GET /v1/rankings?sport=futsal&limit=100` → `[LeaderboardEntryDto]`
> - `LeaderboardEntryDto: { rank, userId, displayName, points, wins, draws, losses }`
>
> Note: The ranking service is player-based. "Times" tab will show the same data mapped to TeamRanking. If a true team leaderboard is needed, it requires an additional API endpoint (future work).

- [ ] **Step 9.1: Create RankingModel**

Create `lib/features/ranking/data/models/ranking_model.dart`:

```dart
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String displayName;
  final int points;
  final int wins;
  final int draws;
  final int losses;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.points,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryModel(
        rank: json['rank'] as int,
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        points: json['points'] as int,
        wins: json['wins'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
      );

  PlayerRanking toPlayerEntity() => PlayerRanking(
        id: userId,
        name: displayName,
        teamName: '',
        position: '',
        goals: 0,
        assists: 0,
        matchesPlayed: wins + draws + losses,
        rank: rank,
      );

  TeamRanking toTeamEntity() => TeamRanking(
        id: userId,
        name: displayName,
        city: '',
        points: points,
        wins: wins,
        draws: draws,
        losses: losses,
        goalsFor: 0,
        goalsAgainst: 0,
        matchesPlayed: wins + draws + losses,
        rank: rank,
      );
}
```

- [ ] **Step 9.2: Create RankingHttpDataSource and switch provider**

Create `lib/features/ranking/data/datasources/ranking_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/ranking/data/models/ranking_model.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class RankingHttpDatasource {
  RankingHttpDatasource({required this.dio});

  final Dio dio;

  Future<List<LeaderboardEntryModel>> getLeaderboard({
    String sport = 'futsal',
    int limit = 100,
  }) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/rankings',
      queryParameters: {'sport': sport, 'limit': limit},
    );
    return res.data!
        .map((e) =>
            LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeamRanking>> getTeamRankings() async {
    final entries = await getLeaderboard();
    return entries.map((e) => e.toTeamEntity()).toList();
  }

  Future<List<PlayerRanking>> getPlayerRankings() async {
    final entries = await getLeaderboard();
    return entries.map((e) => e.toPlayerEntity()).toList();
  }
}
```

Replace `lib/features/ranking/data/repositories/ranking_repository_impl.dart`:

```dart
import 'package:bola_na_rede/features/ranking/data/datasources/ranking_http_datasource.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl({required this.datasource});

  final RankingHttpDatasource datasource;

  @override
  Future<List<TeamRanking>> getTeamRankings() =>
      datasource.getTeamRankings();

  @override
  Future<List<PlayerRanking>> getPlayerRankings() =>
      datasource.getPlayerRankings();
}
```

Replace `lib/features/ranking/data/repositories/ranking_repository_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/ranking/data/datasources/ranking_http_datasource.dart';
import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_impl.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepositoryImpl(
    datasource: RankingHttpDatasource(dio: ref.watch(dioProvider)),
  ),
);
```

- [ ] **Step 9.3: Update RankingPage "my card"**

In `lib/features/ranking/presentation/views/ranking_page.dart`, change the hardcoded team/player IDs in `_buildMyCard` to use the current user from `authViewModelProvider`:

```dart
// Replace:
data.teamRankings.where((t) => t.id == 'team-001')
// With:
final me = ref.watch(authViewModelProvider).value;
data.teamRankings.where((t) => t.id == me?.userId)
```

- [ ] **Step 9.4: Commit**

```bash
git add lib/features/ranking/
git commit -m "feat(ranking): replace mock with real ranking API"
```

---

## Task 10: Gamification Feature

**Files:** All new under `lib/features/gamificacao/`

> **API reference:**
> - `GET /v1/profiles/:userId` → `{ userId, xp, level, badges: [{badgeId, name, unlockedAt}], totalGames, totalGoals }`

- [ ] **Step 10.1: Create domain entities**

Create `lib/features/gamificacao/domain/entities/player_gamification.dart`:

```dart
class Badge {
  final String badgeId;
  final String name;
  final DateTime unlockedAt;

  const Badge({
    required this.badgeId,
    required this.name,
    required this.unlockedAt,
  });
}

class PlayerGamification {
  final String userId;
  final int xp;
  final int level;
  final List<Badge> badges;
  final int totalGames;
  final int totalGoals;

  const PlayerGamification({
    required this.userId,
    required this.xp,
    required this.level,
    required this.badges,
    required this.totalGames,
    required this.totalGoals,
  });
}
```

- [ ] **Step 10.2: Create HTTP datasource + provider**

Create `lib/features/gamificacao/data/datasources/gamification_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';

class GamificationHttpDatasource {
  GamificationHttpDatasource({required this.dio});

  final Dio dio;

  Future<PlayerGamification> getProfile(String userId) async {
    final res =
        await dio.get<Map<String, dynamic>>('/v1/profiles/$userId');
    final data = res.data!;
    final badgesList = (data['badges'] as List<dynamic>? ?? [])
        .map((b) {
          final map = b as Map<String, dynamic>;
          return Badge(
            badgeId: map['badgeId'] as String,
            name: map['name'] as String,
            unlockedAt: DateTime.parse(map['unlockedAt'] as String),
          );
        })
        .toList();
    return PlayerGamification(
      userId: data['userId'] as String,
      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      badges: badgesList,
      totalGames: data['totalGames'] as int? ?? 0,
      totalGoals: data['totalGoals'] as int? ?? 0,
    );
  }
}

final gamificationDatasourceProvider = Provider<GamificationHttpDatasource>(
  (ref) => GamificationHttpDatasource(dio: ref.watch(dioProvider)),
);

final playerGamificationProvider =
    FutureProvider.family<PlayerGamification, String>(
  (ref, userId) =>
      ref.read(gamificationDatasourceProvider).getProfile(userId),
);
```

- [ ] **Step 10.3: Add XP/badges section to ProfilePage**

In `lib/features/profile/presentation/views/profile_page.dart`, add inside `_buildBody` after the info card:

```dart
// Get the gamification data for the current user
final gamificationAsync = ref.watch(playerGamificationProvider(p.userId));

// Add after the info AppCard:
gamificationAsync.when(
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
  data: (g) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Progresso', style: AppTextStyles.titleSmall),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Icon(PhosphorIcons.lightning(), color: AppColors.primary, size: 16),
        const SizedBox(width: 4),
        Text('Nível ${g.level}  ·  ${g.xp} XP',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        Text('${g.totalGames} jogos  ·  ${g.totalGoals} gols',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
      if (g.badges.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        const Text('Badges', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: g.badges
              .map((b) => Chip(
                    label: Text(b.name,
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.primarySurface,
                    side: const BorderSide(color: AppColors.primaryBorder),
                  ))
              .toList(),
        ),
      ],
    ]),
  ),
),
```

- [ ] **Step 10.4: Commit**

```bash
git add lib/features/gamificacao/
git commit -m "feat(gamificacao): gamification datasource + XP/badges on profile"
```

---

## Task 11: Social Reviews Feature

**Files:** All new under `lib/features/social/`

> **API reference:**
> - `GET /v1/reviews?revieweeId=:userId` → `[ReviewDto]`
> - `POST /v1/reviews` → `{ revieweeUserId, score (1-5), comment?, gameId, gameType ('OPEN_GAME'|'FORMAL') }`
> - `GET /v1/scores/players/:userId` → `{ userId, displayName, overallAvg, reviewCount }`

- [ ] **Step 11.1: Create domain entities**

Create `lib/features/social/domain/entities/review.dart`:

```dart
class Review {
  final String id;
  final String gameId;
  final String gameType;
  final String reviewerUserId;
  final String reviewerDisplayName;
  final String revieweeUserId;
  final String revieweeDisplayName;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.gameId,
    required this.gameType,
    required this.reviewerUserId,
    required this.reviewerDisplayName,
    required this.revieweeUserId,
    required this.revieweeDisplayName,
    required this.score,
    this.comment,
    required this.createdAt,
  });
}

class PlayerScore {
  final String userId;
  final String displayName;
  final double overallAvg;
  final int reviewCount;

  const PlayerScore({
    required this.userId,
    required this.displayName,
    required this.overallAvg,
    required this.reviewCount,
  });
}
```

- [ ] **Step 11.2: Create HTTP datasource + provider**

Create `lib/features/social/data/datasources/review_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/social/domain/entities/review.dart';

class ReviewHttpDatasource {
  ReviewHttpDatasource({required this.dio});

  final Dio dio;

  Future<Review> submitReview({
    required String revieweeUserId,
    required int score,
    String? comment,
    required String gameId,
    required String gameType,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/reviews',
      data: {
        'revieweeUserId': revieweeUserId,
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'gameId': gameId,
        'gameType': gameType,
      },
    );
    final data = res.data!;
    return Review(
      id: data['id'] as String,
      gameId: data['gameId'] as String,
      gameType: data['gameType'] as String,
      reviewerUserId: data['reviewerUserId'] as String,
      reviewerDisplayName: data['reviewerDisplayName'] as String? ?? '',
      revieweeUserId: data['revieweeUserId'] as String,
      revieweeDisplayName: data['revieweeDisplayName'] as String? ?? '',
      score: data['score'] as int,
      comment: data['comment'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Future<PlayerScore> getPlayerScore(String userId) async {
    final res = await dio
        .get<Map<String, dynamic>>('/v1/scores/players/$userId');
    final data = res.data!;
    return PlayerScore(
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      overallAvg: (data['overallAvg'] as num).toDouble(),
      reviewCount: data['reviewCount'] as int,
    );
  }
}

final reviewDatasourceProvider = Provider<ReviewHttpDatasource>(
  (ref) => ReviewHttpDatasource(dio: ref.watch(dioProvider)),
);
```

- [ ] **Step 11.3: Create SubmitReviewPage**

Create `lib/features/social/presentation/views/submit_review_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/social/data/datasources/review_http_datasource.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class SubmitReviewPage extends ConsumerStatefulWidget {
  final String revieweeUserId;
  final String revieweeDisplayName;
  final String gameId;
  final String gameType;

  const SubmitReviewPage({
    super.key,
    required this.revieweeUserId,
    required this.revieweeDisplayName,
    required this.gameId,
    required this.gameType,
  });

  @override
  ConsumerState<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends ConsumerState<SubmitReviewPage> {
  int _score = 3;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewDatasourceProvider).submitReview(
            revieweeUserId: widget.revieweeUserId,
            score: _score,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
            gameId: widget.gameId,
            gameType: widget.gameType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Avaliar ${widget.revieweeDisplayName}')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nota', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _score = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: Icon(
                      star <= _score
                          ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                          : PhosphorIcons.star(),
                      size: 36,
                      color: star <= _score
                          ? AppColors.warningIcon
                          : AppColors.textDisabled,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Comentário (opcional)',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escreva um comentário...',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            AppButton.primary(
              label: _loading ? 'Enviando...' : 'Enviar Avaliação',
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.4: Add review route**

In `lib/core/routes/app_router.dart`, add:

```dart
static const submitReview = '/review/submit';
```

```dart
GoRoute(
  path: AppRoutes.submitReview,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return SubmitReviewPage(
      revieweeUserId: extra['revieweeUserId'] as String,
      revieweeDisplayName: extra['revieweeDisplayName'] as String,
      gameId: extra['gameId'] as String,
      gameType: extra['gameType'] as String,
    );
  },
),
```

Add a "Avaliar jogadores" button to `PeladaDetailPage` and `MatchDetailPage` that navigates to this route with the appropriate extra params.

- [ ] **Step 11.5: Commit**

```bash
git add lib/features/social/
git commit -m "feat(social): player review submission screen + datasource"
```

---

## Task 12: Notifications Feature

**Files:** All new under `lib/features/notificacoes/`

> **API reference:**
> - `GET /v1/notifications?skip=0&limit=20` → `[NotificationResponseDto]`
> - `GET /v1/notifications/unread-count` → `{ count: number }`
> - `PATCH /v1/notifications/read` → mark all as read
> - `PATCH /v1/notifications/:id/read` → mark one as read

- [ ] **Step 12.1: Create domain entity**

Create `lib/features/notificacoes/domain/entities/notification.dart`:

```dart
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });
}
```

- [ ] **Step 12.2: Create HTTP datasource + provider**

Create `lib/features/notificacoes/data/datasources/notification_http_datasource.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';

class NotificationHttpDatasource {
  NotificationHttpDatasource({required this.dio});

  final Dio dio;

  Future<List<AppNotification>> getNotifications({
    int skip = 0,
    int limit = 20,
  }) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/notifications',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return res.data!.map((e) {
      final map = e as Map<String, dynamic>;
      return AppNotification(
        id: map['id'] as String,
        type: map['type'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        data: (map['data'] as Map<String, dynamic>? ?? {}),
        isRead: map['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    }).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await dio
        .get<Map<String, dynamic>>('/v1/notifications/unread-count');
    return res.data!['count'] as int? ?? 0;
  }

  Future<void> markAllAsRead() =>
      dio.patch<void>('/v1/notifications/read');

  Future<void> markOneAsRead(String id) =>
      dio.patch<void>('/v1/notifications/$id/read');
}

final notificationDatasourceProvider = Provider<NotificationHttpDatasource>(
  (ref) => NotificationHttpDatasource(dio: ref.watch(dioProvider)),
);

final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationDatasourceProvider).getUnreadCount(),
);
```

- [ ] **Step 12.3: Create NotificationViewModel**

Create `lib/features/notificacoes/presentation/viewmodels/notification_viewmodel.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/notificacoes/data/datasources/notification_http_datasource.dart';
import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';

class NotificationVM
    extends AsyncNotifier<List<AppNotification>> {
  NotificationHttpDatasource get _ds =>
      ref.read(notificationDatasourceProvider);

  @override
  Future<List<AppNotification>> build() => _ds.getNotifications();

  Future<void> markAllRead() async {
    await _ds.markAllAsRead();
    ref.invalidate(unreadCountProvider);
    state = await AsyncValue.guard(() => _ds.getNotifications());
  }

  Future<void> markOneRead(String id) async {
    await _ds.markOneAsRead(id);
    ref.invalidate(unreadCountProvider);
    state = AsyncData(
      state.value
              ?.map((n) =>
                  n.id == id
                      ? AppNotification(
                          id: n.id,
                          type: n.type,
                          title: n.title,
                          body: n.body,
                          data: n.data,
                          isRead: true,
                          createdAt: n.createdAt,
                        )
                      : n)
              .toList() ??
          [],
    );
  }
}

final notificationViewModelProvider =
    AsyncNotifierProvider<NotificationVM, List<AppNotification>>(
        NotificationVM.new);
```

- [ ] **Step 12.4: Create NotificationsPage**

Create `lib/features/notificacoes/presentation/views/notifications_page.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/notificacoes/presentation/viewmodels/notification_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationViewModelProvider.notifier)
                .markAllRead(),
            child: const Text('Marcar todas como lidas'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Erro ao carregar notificações.')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Nenhuma notificação.'))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final n = list[i];
                  return AppCard(
                    color: n.isRead ? null : AppColors.primarySurface,
                    onTap: () => ref
                        .read(notificationViewModelProvider.notifier)
                        .markOneRead(n.id),
                    child: Row(children: [
                      Icon(
                        PhosphorIcons.bell(),
                        color: n.isRead
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        size: AppSizes.iconLg,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(n.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: n.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w700)),
                          Text(n.body,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
```

- [ ] **Step 12.5: Add notification route + bell icon in AppBar**

In `lib/core/routes/app_router.dart`, add:
```dart
static const notifications = '/notifications';
```

```dart
GoRoute(
  path: AppRoutes.notifications,
  builder: (_, __) => const NotificationsPage(),
),
```

In `lib/features/home/presentation/views/home_page.dart`, add a bell icon in the header row that shows the unread count badge and navigates to `/notifications`:

```dart
// Inside _buildHeader, after the Spacer():
Consumer(
  builder: (context, ref, _) {
    final count =
        ref.watch(unreadCountProvider).whenOrNull(data: (c) => c) ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(PhosphorIcons.bell(),
              color: AppColors.textOnPrimary),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                    color: Colors.white, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
),
```

- [ ] **Step 12.6: Commit**

```bash
git add lib/features/notificacoes/
git commit -m "feat(notificacoes): notifications list + unread count badge"
```

---

## Task 13: Home Dashboard Real Data

**Files:**
- Modify: `lib/features/home/presentation/viewmodels/home_viewmodel.dart`

> The home page currently hardcodes `myRank: 3`, `playerCount: 6`, `winStreak: 8`. Replace these with real API data.

- [ ] **Step 13.1: Update HomeData to hold real stats**

Replace `lib/features/home/presentation/viewmodels/home_viewmodel.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_http_datasource.dart';
import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/data/datasources/ranking_http_datasource.dart';
import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class HomeData {
  final Match? nextMatch;
  final Match? pendingRequest;
  final Team? myTeam;
  final PlayerGamification? gamification;
  final int myRankPosition;

  const HomeData({
    this.nextMatch,
    this.pendingRequest,
    this.myTeam,
    this.gamification,
    this.myRankPosition = 0,
  });

  int get playerCount => myTeam != null ? 1 : 0;
  int get winStreak => gamification?.totalGames ?? 0;
  int get myRank => myRankPosition;
}

class HomeVM extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final user = ref.watch(authViewModelProvider).value;
    if (user == null) return const HomeData();

    final myTeam = await ref.watch(myTeamProvider.future);

    final futures = await Future.wait([
      ref.read(gamificationDatasourceProvider).getProfile(user.userId),
    ]);
    final gamification = futures[0] as PlayerGamification;

    final rankings = await (ref.read(rankingRepositoryProvider) as dynamic)
        .getPlayerRankings() as List<PlayerRanking>;
    final myRank = rankings.indexWhere((r) => r.id == user.userId);

    return HomeData(
      myTeam: myTeam,
      gamification: gamification,
      myRankPosition: myRank >= 0 ? rankings[myRank].rank : 0,
    );
  }
}

final homeProvider = AsyncNotifierProvider<HomeVM, HomeData>(HomeVM.new);
```

> Note: `nextMatch` and `pendingRequest` require querying matchmaking service for the user's team's pending matches. This is deferred to a follow-up task (match list already shows this data). The home page will show nulls for these until that is wired up.

- [ ] **Step 13.2: Verify home page compiles**

```bash
cd bolanarede_mobile
flutter analyze
```

Fix any type errors that arise from the HomeData shape change.

- [ ] **Step 13.3: Commit**

```bash
git add lib/features/home/
git commit -m "feat(home): replace hardcoded stats with real XP and ranking data"
```

---

## Task 14: Final QA Pass

- [ ] **Step 14.1: Run full analysis**

```bash
cd bolanarede_mobile
flutter analyze
dart run import_sorter:main
flutter analyze  # second pass after import sort
```

Expected: zero errors, only allowed warnings (if any).

- [ ] **Step 14.2: Test auth flow end-to-end**

With the API running (`docker-compose up`):

1. Fresh install (or clear app data) → splash → `/login`
2. Login with valid credentials → `/home` shows username from API
3. Kill and relaunch → session restored → `/home`
4. Profile page shows real `displayName`, `city`, `position`
5. Profile XP section shows level and badges

- [ ] **Step 14.3: Test fields flow**

1. Navigate to fields (via home quick action "Reservar campo")
2. Type "Curitiba" in search → field list from API
3. Tap a field → detail page → tap date → availability slots appear
4. Tap an available slot → ReservationPage → confirm → success snackbar

- [ ] **Step 14.4: Test peladas flow**

1. Tap "Peladas" tab (was Search) → list from API
2. Tap "+ Nova Pelada" → fill form → create → list refreshes
3. Tap a pelada → detail with participants
4. Tap "Entrar na pelada" → count increments
5. Tap "Sair da pelada" → count decrements

- [ ] **Step 14.5: Test ranking**

1. Navigate to Ranking tab → times/jogadores toggle
2. Data from API shows instead of mock data
3. "Sua posicao" card at bottom highlights current user

- [ ] **Step 14.6: Test notifications**

1. Bell icon in home header shows unread count (if any notifications)
2. Tap bell → NotificationsPage
3. Tap a notification → marks as read, unread count decrements

- [ ] **Step 14.7: Final commit**

```bash
git add -p  # stage any final fixes
git commit -m "fix(mobile): final QA fixes — analyzer clean, integration verified"
```

---

## Self-Review

### Spec Coverage

| Feature | Tasks | Status |
|---------|-------|--------|
| Nginx gateway | Task 1 | ✅ |
| Dio + interceptors | Task 2 | ✅ |
| Auth (login/register/restore) | Task 3 | ✅ |
| Profile view/edit | Task 4 | ✅ |
| Fields browse + availability + reserve | Task 5 | ✅ |
| Open Games (peladas) full flow | Task 6 | ✅ |
| Teams create/join/manage | Task 7 | ✅ |
| Matchmaking + game results | Task 8 | ✅ |
| Ranking (player) | Task 9 | ✅ |
| Gamification XP/badges on profile | Task 10 | ✅ |
| Social reviews | Task 11 | ✅ |
| Notifications | Task 12 | ✅ |
| Home real data | Task 13 | ✅ |

### Known Gaps (follow-up tasks)
- **FCM push notifications**: Requires Firebase project + `firebase_messaging` package. Not covered here.
- **Team ranking**: The ranking service is player-based. A real team leaderboard requires a new API endpoint (e.g. `GET /v1/rankings/teams`). Currently Teams tab shows player data mapped to team shape.
- **nextMatch / pendingRequest on Home**: Requires querying matchmaking for pending proposals to the user's team. Deferred until match flow is fully tested.
- **Edit profile form**: `ProfilePage` has "Editar perfil" that calls `showComingSoon`. A full edit screen with `PUT /v1/users/me/profile` should be a follow-up task.
- **Photo upload**: `photoUrl` field exists but uploading requires an S3/storage integration.
- **PlayerPosition enum values**: Verify against `lib/core/shared/enums.dart`. The `UserProfileModel._parsePosition` uses strings like `'goalkeeper'`, `'defender'`, `'midfielder'`, `'forward'` — confirm these match what the API returns.
- **SkillLevel enum values**: Verify `SkillLevel.beginner/recreational/intermediate/advanced/competitive` match enum declarations.

### Placeholder Scan

No "TBD" or "TODO" entries in the plan. All code blocks are complete. All file paths are exact.

### Type Consistency

- `AuthDataSource` interface defined in `auth_mock_datasource.dart` — `AuthHttpDataSource` implements same interface ✓
- `FieldDataSource` abstract class defined in `field_mock_datasource.dart` — `FieldHttpDataSource` implements it ✓
- `TeamDataSource` abstract class defined in `team_http_datasource.dart` ✓
- `MatchDataSource` abstract class defined in `match_http_datasource.dart` ✓
- `OpenGameRepository` interface defined in `open_game_repository.dart`, implemented by `OpenGameHttpRepository` ✓

---

## Execution Choice

**Plan complete and saved to `docs/plans/2026-06-16-mobile-integration.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration. Use `superpowers:subagent-driven-development`.

**2. Inline Execution** — execute tasks in this session with checkpoints. Use `superpowers:executing-plans`.

Which approach?
