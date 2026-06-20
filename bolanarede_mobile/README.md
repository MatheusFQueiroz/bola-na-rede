# Bola na Rede — Aplicativo Mobile

Rede social de futebol amador para organizar peladas, partidas competitivas, ranking e gamificação entre jogadores.

---

## Descrição

O **Bola na Rede** conecta jogadores de futebol amador em um único aplicativo. Funcionalidades principais:

- **Autenticação** — cadastro e login com JWT persistido localmente
- **Perfil** — visualização de estatísticas, times e partidas recentes
- **Times** — criação, busca e gerenciamento de equipes
- **Peladas** — criação e participação em partidas abertas
- **Partidas** — histórico de partidas competitivas com placar e resultado
- **Matchmaking** — fila de busca por adversário automático (1v1)
- **Ranking** — placar de melhores jogadores por esporte
- **Gamificação** — XP, nível e conquistas por desempenho

---

## Como executar

### Pré-requisitos

- Flutter SDK 3.19+
- Android Studio / VS Code com extensão Flutter
- Dart SDK 3.3+
- Backend Bola na Rede em execução (ou modo mock ativo)

### Configuração

1. Clone o repositório e acesse a pasta do app:
   ```bash
   cd bolanarede_mobile
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Copie e configure o arquivo de ambiente:
   ```bash
   cp .env.example .env
   ```
   Edite `.env` com a URL do gateway:
   ```
   API_BASE_URL=http://10.0.2.2:3000   # Android emulator
   # API_BASE_URL=http://localhost:3000  # iOS simulator / web
   ```

4. Execute o app:
   ```bash
   flutter run
   ```

### Gerar arquivos de serialização (se necessário)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Arquitetura — MVVM com Clean Architecture

O projeto segue **MVVM (Model-View-ViewModel)** combinado com **Clean Architecture por feature**.

```
lib/
├── core/               # Infraestrutura transversal (rede, rotas, temas)
│   ├── network/        # Dio client + interceptors (auth, erros)
│   ├── routes/         # go_router — rotas declarativas
│   └── themes/         # Cores, tipografia, tokens de design
├── features/           # Funcionalidades isoladas por domínio
│   └── <feature>/
│       ├── data/       # DataSources (HTTP/local), Models (DTOs), RepositoryImpl
│       ├── domain/     # Entities (imutáveis), Repository interfaces
│       └── presentation/
│           ├── views/       # Telas (UI pura, sem lógica)
│           └── viewmodels/  # Riverpod Notifiers — estado e orquestração
└── shared/             # Widgets e utilitários reutilizáveis
```

### Camadas do MVVM

| Camada | Responsabilidade | Exemplo |
|--------|-----------------|---------|
| **View** | UI declarativa, sem lógica de negócio | `home_page.dart`, `ranking_page.dart` |
| **ViewModel** | Estado da UI, validações, chamadas ao repositório | `AuthViewModel`, `ProfileVM` |
| **Model** | DTOs com `fromJson/toJson`, conversão para entidades | `UserProfileModel`, `TeamModel` |
| **Domain** | Entidades imutáveis, interfaces de repositório | `PlayerProfile`, `AuthRepository` |
| **Data** | Implementação HTTP/local dos repositórios | `AuthRepositoryImpl`, `ProfileHttpDataSource` |

---

## Padrão de Projeto — Repository Pattern

O padrão **Repository** abstrai o acesso a dados da camada de apresentação.

```
View → ViewModel → Repository (interface) → RepositoryImpl (HTTP/local)
```

**Exemplo aplicado:**

```dart
// domain/repositories/auth_repository.dart — interface
abstract class AuthRepository {
  Future<PlayerProfile> login(String email, String password);
  Future<void> logout();
}

// data/repositories/auth_repository_impl.dart — implementação
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<PlayerProfile> login(String email, String password) async {
    final model = await _dataSource.login(email, password);
    return model.toEntity();   // DTO → Entity
  }
}
```

**Benefícios evidentes no projeto:**
- `auth_mock_datasource.dart` substitui `auth_http_datasource.dart` sem alterar a ViewModel
- Testes podem injetar `FakeAuthRepository` via Riverpod override
- Cada feature tem seu próprio repositório isolado (9 features implementadas)

---

## API Remota

O app se comunica com um gateway nginx único (`API_BASE_URL`) que roteia para 10 microserviços NestJS.

**Cliente HTTP:** `dio 5.9.2`

**Configuração central** (`core/network/dio_client.dart`):
- Base URL via `flutter_dotenv`
- Timeout de 15 segundos
- Interceptor de autenticação: injeta `Authorization: Bearer <token>` em toda requisição
- Interceptor de erros: mapeia `DioException` para `Failure` tipado

**Endpoints integrados:**

| Feature | Endpoint | Método |
|---------|----------|--------|
| Auth | `POST /v1/auth/login` | Login |
| Auth | `POST /v1/auth/register` | Cadastro |
| Auth | `GET /v1/auth/me` | Restaurar sessão |
| Profile | `GET /v1/users/me` | Perfil do usuário |
| Teams | `GET /v1/teams` | Listar times do usuário |
| Teams | `POST /v1/teams` | Criar time |
| Teams | `GET /v1/teams/:id/members` | Membros do time |
| Teams | `DELETE /v1/teams/:id/leave` | Sair do time |
| Matchmaking | `POST /v1/matchmaking/requests` | Entrar na fila |
| Matchmaking | `DELETE /v1/matchmaking/requests/:id` | Cancelar fila |
| Games | `GET /v1/games` | Histórico de partidas |
| Ranking | `GET /v1/rankings/:sport` | Ranking por esporte |
| Open Games | `GET /v1/open-games` | Listar peladas |

---

## Armazenamento Local

O projeto utiliza o pacote `shared_preferences 2.5.5` para dois tipos de persistência:

### 1. Token JWT (`TokenStorage`)

**Arquivo:** `lib/features/auth/data/datasources/token_storage.dart`

O token de autenticação é salvo em `SharedPreferences` após login e restaurado automaticamente ao reabrir o app, mantendo o usuário logado.

```dart
class SharedPreferencesTokenStorage implements TokenStorage {
  static const _key = 'auth_token';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
```

**Restauração na inicialização** (`AuthViewModel.build()`): ao abrir o app, o token é lido e a sessão é restaurada automaticamente via `GET /v1/auth/me`.

### 2. Cache de Perfil (`ProfileCache`)

**Arquivo:** `lib/features/profile/data/datasources/profile_cache.dart`

O perfil do jogador (nome, posição, cidade, etc.) é serializado como JSON e salvo em `SharedPreferences` com chave `cached_profile_{userId}`.

**Comportamento:**

1. **Primeiro acesso**: busca da API, salva no cache
2. **Reabertura do app**: exibe o perfil cacheado instantaneamente enquanto busca a versão atualizada em background
3. **Sem internet**: exibe o perfil cacheado enquanto a API não responde
4. **Logout**: cache do perfil é removido junto com o token

```dart
// Estratégia cache-first no ProfileVM
Future<ProfileData> build() async {
  final cached = await cache.read(userId);

  if (cached != null) {
    unawaited(_refreshFromApi(userId, repo, cache)); // atualiza em background
    return ProfileData(profile: cached, recentMatches: const []);
  }

  return _fetchAndCache(userId, repo, cache); // primeira vez
}
```

---

## Tecnologias

| Categoria | Pacote | Versão |
|-----------|--------|--------|
| Estado | `flutter_riverpod` | 3.3.1 |
| Roteamento | `go_router` | 17.2.2 |
| HTTP | `dio` | 5.9.2 |
| Env | `flutter_dotenv` | 6.0.1 |
| Storage local | `shared_preferences` | 2.5.5 |
| Serialização | `json_serializable` | ^6.8.0 |
| Ícones | `phosphor_flutter` | 2.1.0 |
| Lint | `very_good_analysis` | 10.0.0 |

---

## Estrutura de Features

```
features/
├── auth/          # Login, cadastro, sessão, token
├── home/          # Página inicial com resumo e matchmaking
├── profile/       # Perfil do jogador com estatísticas
├── team/          # Times: criar, gerenciar, membros
├── peladas/       # Partidas abertas (peladas)
├── match/         # Histórico de partidas competitivas
├── ranking/       # Leaderboard por esporte
├── gamificacao/   # XP, nível, conquistas
├── search/        # Busca de partidas e times
├── field/         # Catálogo de campos esportivos
├── social/        # Avaliações entre jogadores
└── notifications/ # Central de notificações
```
