# Shared Module

Código compartilhado entre todos os serviços. Localizado em `shared/src/`. Referenciado via path alias `@shared/*` configurado no `tsconfig.base.json`. Não é um pacote npm separado.

## O Que Está no Shared

```
shared/src/
├── contracts/
│   └── events/                     ← enums de eventos RabbitMQ (ver 04-messaging.md)
├── domain/
│   └── enums/
│       └── permission.enum.ts      ← enum de permissões
├── infra/
│   ├── auth/
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── permissions.guard.ts
│   │   ├── interfaces/
│   │   │   └── authenticated-user.interface.ts
│   │   └── shared-auth.module.ts
│   ├── database/
│   │   └── drizzle.service.ts      ← serviço de conexão com PostgreSQL via Drizzle
│   ├── decorators/
│   │   ├── current-user.decorator.ts
│   │   ├── permissions.decorator.ts
│   │   └── public.decorator.ts
│   ├── hateoas/
│   │   ├── hateoas-item.decorator.ts
│   │   ├── hateoas-list.decorator.ts
│   │   ├── hateoas.interceptor.ts
│   │   ├── hateoas.types.ts
│   │   └── index.ts
│   ├── http/
│   │   └── bootstrap-http-app.ts   ← bootstrap compartilhado (prefixo, Swagger, pipes)
│   └── messaging/
│       ├── rabbitmq.service.ts     ← configuração do RabbitMQ
│       └── shared-messaging.service.ts ← publicar eventos
└── shared.module.ts
```

## Como Usar em um Serviço

### Importar SharedModule no módulo da entidade

```typescript
// {entity}.module.ts
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';

@Module({
  imports: [SharedModule],   // ← sempre importar SharedModule
  controllers: [...],
  providers: [...],
})
export class OpenGameModule {}
```

### DrizzleService

```typescript
import { DrizzleService } from '@shared/infra/database/drizzle.service';

@Injectable()
export class DrizzleOpenGameRepository {
  constructor(private readonly drizzle: DrizzleService) {}

  async findById(id: string) {
    return this.drizzle.db.select().from(openGames).where(eq(openGames.id, id));
  }
}
```

### SharedMessagingService

```typescript
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';

@Injectable()
export class OpenGameMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishCreated(payload: Record<string, unknown>) {
    await this.messaging.publish(OpenGameEvents.CREATED, payload);
  }
}
```

### AuthenticatedUser Interface

```typescript
import { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';

// Estrutura do usuário extraído do JWT
interface AuthenticatedUser {
  id: string; // user external_id
  name: string;
  email: string;
  permissions: string[];
}
```

### Decorators

```typescript
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';

// @Public() → rota sem autenticação
// @Permissions('resource:action') → exige permissão específica
// @CurrentUser() user: AuthenticatedUser → extrai usuário do JWT
```

### Guards

```typescript
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';

// Aplicar em todo controller protegido:
@UseGuards(JwtAuthGuard, PermissionsGuard)
```

### HATEOAS

```typescript
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';

@HateoasItem(OpenGameDto)   // resposta de item único
@HateoasList(OpenGameDto)   // resposta de lista
```

### bootstrapHttpApp

```typescript
// main.ts de qualquer serviço
import { bootstrapHttpApp } from '@shared/infra/http/bootstrap-http-app';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await bootstrapHttpApp(app);
  // aplica automaticamente:
  // - prefixo global /v1
  // - Swagger em /docs
  // - ValidationPipe global
  // - HATEOAS interceptor
}
```

## Permissões do BolaNaRede

Definidas em `shared/src/domain/enums/permission.enum.ts`:

```typescript
export enum Permission {
  // Players
  PLAYERS_READ = 'players:read',
  PLAYERS_WRITE = 'players:write',

  // Teams
  TEAMS_READ = 'teams:read',
  TEAMS_WRITE = 'teams:write',

  // Fields
  FIELDS_READ = 'fields:read',
  FIELDS_WRITE = 'fields:write',

  // Open Games (Peladas)
  OPEN_GAMES_READ = 'open-games:read',
  OPEN_GAMES_WRITE = 'open-games:write',

  // Reviews
  REVIEWS_READ = 'reviews:read',
  REVIEWS_WRITE = 'reviews:write',

  // Seasons / Stats
  SEASONS_READ = 'seasons:read',
  SEASONS_WRITE = 'seasons:write',

  // Matches
  MATCHES_READ = 'matches:read',
  MATCHES_WRITE = 'matches:write',

  // Rankings
  RANKINGS_READ = 'rankings:read',

  // Notifications
  NOTIFICATIONS_WRITE = 'notifications:write',
}
```

## Regra: Nunca Criar Código Duplicado

Tudo que é compartilhado entre 2 ou mais serviços vai para `shared/`. Nunca copiar código de um serviço para outro.

Exemplos do que vai no shared:

- Guards de auth
- Decorators (`@CurrentUser`, `@Public`, `@Permissions`)
- DrizzleService
- SharedMessagingService
- bootstrapHttpApp
- Enums de eventos
- Enum de permissões
- Tipos de HATEOAS
