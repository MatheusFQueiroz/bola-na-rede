# Estrutura do Projeto BolaNaRede

## Visão Geral

Single Git repository com múltiplos microserviços NestJS independentes. Cada serviço tem seu próprio `package.json`, banco PostgreSQL e processo. Não é monolito, não usa pnpm workspaces ou Nx.

## Estrutura de Pastas

```
bolanarededb/
├── services/                    ← microserviços NestJS
│   ├── identity/                ← auth, usuários, perfil do jogador
│   ├── team/                    ← times, membros, capitania
│   ├── field/                   ← campos, reservas, planos recorrentes
│   ├── open-game/               ← peladas, participações
│   ├── social/                  ← avaliações, scores
│   ├── gamification/            ← temporadas, stats, ligas, desafios
│   ├── matchmaking/             ← solicitações e propostas de partida
│   ├── game/                    ← execução de partidas, resultados
│   ├── ranking/                 ← standings de times
│   └── notification/            ← push notifications
├── shared/                      ← código compartilhado (path alias, não npm package)
│   └── src/
│       ├── contracts/
│       │   └── events/          ← enums de eventos por domínio
│       ├── domain/
│       │   └── enums/           ← enums de domínio compartilhados
│       ├── infra/
│       │   ├── auth/            ← JwtAuthGuard, PermissionsGuard
│       │   ├── database/        ← DrizzleService
│       │   ├── decorators/      ← @CurrentUser, @Permissions, @Public
│       │   ├── hateoas/         ← interceptor + decorators HATEOAS
│       │   ├── http/            ← bootstrapHttpApp()
│       │   └── messaging/       ← RabbitMQService, SharedMessagingService
│       └── shared.module.ts
├── docker/
│   └── postgres/
│       └── init/
│           └── 01-create-databases.sql
├── docker-compose.yml
├── Dockerfile.service           ← único Dockerfile para todos os serviços
├── biome.json                   ← linter (Biome, não ESLint)
├── tsconfig.base.json           ← base com path alias @shared/*
├── tsconfig.json
└── package.json                 ← scripts: npm run start:identity etc.
```

## Portas e Bancos

| Serviço      | Porta | Banco                     |
| ------------ | ----- | ------------------------- |
| identity     | 4001  | bolanarededb_identity     |
| team         | 4002  | bolanarededb_team         |
| field        | 4003  | bolanarededb_field        |
| open-game    | 4004  | bolanarededb_open_game    |
| social       | 4005  | bolanarededb_social       |
| gamification | 4006  | bolanarededb_gamification |
| matchmaking  | 4007  | bolanarededb_matchmaking  |
| game         | 4008  | bolanarededb_game         |
| ranking      | 4009  | bolanarededb_ranking      |
| notification | 4010  | bolanarededb_notification |

## Variáveis de Ambiente

Todo serviço usa as mesmas 4 variáveis (valores mudam por serviço):

```env
PORT=4001
JWT_SECRET=bolanarededb-secret
DATABASE_URL=postgres://postgres:postgres@localhost:5432/bolanarededb_identity
RABBITMQ_URL=amqp://admin:admin@localhost:5672
```

O `JWT_SECRET` é **idêntico** em todos os serviços.

## tsconfig.base.json (path alias obrigatório)

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "strict": true,
    "paths": {
      "@shared/*": ["../../shared/src/*"]
    }
  }
}
```

Cada serviço estende com:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "baseUrl": "./"
  }
}
```

## Linter: Biome

Nunca instalar ESLint, Prettier ou plugins. O projeto usa Biome.

```json
// biome.json (raiz)
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": { "enabled": true, "rules": { "recommended": true } },
  "formatter": { "enabled": true, "indentStyle": "space", "indentWidth": 2 }
}
```

## Convenções de Nomenclatura

- Arquivos: **kebab-case** (`open-game.service.ts`)
- Classes: **PascalCase** (`OpenGameService`)
- Constantes de injeção: **UPPER_SNAKE_CASE** (`OPEN_GAME_REPOSITORY`)
- Variáveis/métodos: **camelCase**
- IDs: sempre **UUID**
- Timestamps: sempre **timestamptz** (com timezone)

## Regras Absolutas

- Sem `any` implícito — TypeScript strict
- Sem `console.log` — usar `Logger` do NestJS
- Sem chamadas HTTP entre serviços para buscar dados de exibição
- Sem banco compartilhado entre serviços
- Sem imports entre pastas de serviços diferentes
- Toda validação de DTO via `class-validator`
- Todo endpoint documentado com `@ApiProperty()` e `@ApiTags()`
