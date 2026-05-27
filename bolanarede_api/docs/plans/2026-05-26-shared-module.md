# Shared Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o módulo `shared/` com toda infraestrutura reutilizada pelos serviços NestJS.

**Architecture:** Código compartilhado via path alias `@shared/*` (não é npm package). Contém guards JWT, DrizzleService, SharedMessagingService, decorators, HATEOAS e bootstrapHttpApp. Importado pelos serviços via `SharedModule` (marcado como `@Global()`).

**Tech Stack:** NestJS 11, TypeScript 5 (CommonJS), Drizzle ORM, @golevelup/nestjs-rabbitmq, @nestjs/jwt, pg

---

## File Map

```
tsconfig.base.json                                        ← Task 1
biome.json                                                ← Task 2
shared/src/
  contracts/events/
    identity-events.enum.ts                               ← Task 3
    open-game-events.enum.ts                              ← Task 4
    team-events.enum.ts                                   ← Task 5
    field-events.enum.ts                                  ← Task 6
    game-events.enum.ts                                   ← Task 7
    social-events.enum.ts                                 ← Task 8
    gamification-events.enum.ts                           ← Task 9
    matchmaking-events.enum.ts                            ← Task 10
    ranking-events.enum.ts                                ← Task 11
  domain/enums/
    permission.enum.ts                                    ← Task 12
  infra/auth/
    interfaces/authenticated-user.interface.ts            ← Task 13
    guards/jwt-auth.guard.ts                              ← Task 14
    guards/permissions.guard.ts                           ← Task 15
    shared-auth.module.ts                                 ← Task 16
  infra/database/
    drizzle.service.ts                                    ← Task 17
  infra/decorators/
    current-user.decorator.ts                             ← Task 18
    permissions.decorator.ts                              ← Task 19
    public.decorator.ts                                   ← Task 20
  infra/hateoas/
    hateoas.types.ts                                      ← Task 21
    hateoas.interceptor.ts                                ← Task 22
    hateoas-item.decorator.ts                             ← Task 23
    hateoas-list.decorator.ts                             ← Task 24
    index.ts                                              ← Task 25
  infra/http/
    bootstrap-http-app.ts                                 ← Task 26
  infra/messaging/
    rabbitmq.service.ts                                   ← Task 27
    shared-messaging.service.ts                           ← Task 28
  shared.module.ts                                        ← Task 29
```

---

### Task 1: tsconfig.base.json

**File:** `tsconfig.base.json`

- [ ] Criar `tsconfig.base.json` na raiz do repositório:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "strict": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "skipLibCheck": true,
    "target": "ES2021",
    "paths": {
      "@shared/*": ["../../shared/src/*"]
    }
  }
}
```

- [ ] Verificar: arquivo salvo sem erros de sintaxe JSON.
- [ ] Commit: `git add tsconfig.base.json && git commit -m "chore: add tsconfig.base.json with @shared path alias"`

---

### Task 2: biome.json

**File:** `biome.json`

- [ ] Criar `biome.json` na raiz do repositório:

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "trailingCommas": "all"
    }
  },
  "files": {
    "ignore": ["node_modules", "dist", "drizzle", "coverage"]
  }
}
```

- [ ] Verificar: arquivo salvo sem erros de sintaxe JSON.
- [ ] Commit: `git add biome.json && git commit -m "chore: add biome.json linter config"`

---

### Task 3: identity-events.enum.ts

**File:** `shared/src/contracts/events/identity-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/identity-events.enum.ts`:

```typescript
export enum IdentityEvents {
  USER_REGISTERED = 'identity.user-registered',
  PROFILE_UPDATED = 'identity.profile-updated',
  DEVICE_TOKEN_UPDATED = 'identity.device-token-updated',
  ACCOUNT_ANONYMIZED = 'identity.account-anonymized',
}
```

- [ ] Verificar: arquivo salvo.
- [ ] Commit: `git add shared/src/contracts/events/identity-events.enum.ts && git commit -m "feat(shared): add IdentityEvents enum"`

---

### Task 4: open-game-events.enum.ts

**File:** `shared/src/contracts/events/open-game-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/open-game-events.enum.ts`:

```typescript
export enum OpenGameEvents {
  CREATED = 'open-game.created',
  PLAYER_JOINED = 'open-game.player-joined',
  PLAYER_LEFT = 'open-game.player-left',
  FULL = 'open-game.full',
  FINISHED = 'open-game.finished',
  CANCELLED = 'open-game.cancelled',
  STATS_RECORDED = 'open-game.stats-recorded',
}
```

- [ ] Commit: `git add shared/src/contracts/events/open-game-events.enum.ts && git commit -m "feat(shared): add OpenGameEvents enum"`

---

### Task 5: team-events.enum.ts

**File:** `shared/src/contracts/events/team-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/team-events.enum.ts`:

```typescript
export enum TeamEvents {
  CREATED = 'team.created',
  PLAYER_JOINED = 'team.player-joined',
  PLAYER_LEFT = 'team.player-left',
  BECAME_INVALID = 'team.became-invalid',
  CAPTAINCY_TRANSFERRED = 'team.captaincy-transferred',
}
```

- [ ] Commit: `git add shared/src/contracts/events/team-events.enum.ts && git commit -m "feat(shared): add TeamEvents enum"`

---

### Task 6: field-events.enum.ts

**File:** `shared/src/contracts/events/field-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/field-events.enum.ts`:

```typescript
export enum FieldEvents {
  REGISTERED = 'field.registered',
  RESERVATION_CONFIRMED = 'field.reservation-confirmed',
  RESERVATION_CANCELLED = 'field.reservation-cancelled',
  PLAN_SLOT_RELEASED = 'field.plan-slot-released',
}
```

- [ ] Commit: `git add shared/src/contracts/events/field-events.enum.ts && git commit -m "feat(shared): add FieldEvents enum"`

---

### Task 7: game-events.enum.ts

**File:** `shared/src/contracts/events/game-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/game-events.enum.ts`:

```typescript
export enum GameEvents {
  MATCH_COMPLETED = 'game.match-completed',
  RESULT_DISPUTED = 'game.result-disputed',
}
```

- [ ] Commit: `git add shared/src/contracts/events/game-events.enum.ts && git commit -m "feat(shared): add GameEvents enum"`

---

### Task 8: social-events.enum.ts

**File:** `shared/src/contracts/events/social-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/social-events.enum.ts`:

```typescript
export enum SocialEvents {
  PLAYER_REVIEWED = 'social.player-reviewed',
  PLAYER_SCORE_UPDATED = 'social.player-score-updated',
}
```

- [ ] Commit: `git add shared/src/contracts/events/social-events.enum.ts && git commit -m "feat(shared): add SocialEvents enum"`

---

### Task 9: gamification-events.enum.ts

**File:** `shared/src/contracts/events/gamification-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/gamification-events.enum.ts`:

```typescript
export enum GamificationEvents {
  SEASON_ENDED = 'gamification.season-ended',
  BADGE_AWARDED = 'gamification.badge-awarded',
  CHALLENGE_ENDED = 'gamification.challenge-ended',
}
```

- [ ] Commit: `git add shared/src/contracts/events/gamification-events.enum.ts && git commit -m "feat(shared): add GamificationEvents enum"`

---

### Task 10: matchmaking-events.enum.ts

**File:** `shared/src/contracts/events/matchmaking-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/matchmaking-events.enum.ts`:

```typescript
export enum MatchmakingEvents {
  MATCH_REQUESTED = 'matchmaking.match-requested',
  MATCH_ACCEPTED = 'matchmaking.match-accepted',
  MATCH_EXPIRED = 'matchmaking.match-expired',
}
```

- [ ] Commit: `git add shared/src/contracts/events/matchmaking-events.enum.ts && git commit -m "feat(shared): add MatchmakingEvents enum"`

---

### Task 11: ranking-events.enum.ts

**File:** `shared/src/contracts/events/ranking-events.enum.ts`

- [ ] Criar `shared/src/contracts/events/ranking-events.enum.ts`:

```typescript
export enum RankingEvents {
  RECALCULATED = 'ranking.recalculated',
}
```

- [ ] Commit: `git add shared/src/contracts/events/ranking-events.enum.ts && git commit -m "feat(shared): add RankingEvents enum"`

---

### Task 12: permission.enum.ts

**File:** `shared/src/domain/enums/permission.enum.ts`

- [ ] Criar `shared/src/domain/enums/permission.enum.ts`:

```typescript
export enum Permission {
  PLAYERS_READ = 'players:read',
  PLAYERS_WRITE = 'players:write',
  TEAMS_READ = 'teams:read',
  TEAMS_WRITE = 'teams:write',
  FIELDS_READ = 'fields:read',
  FIELDS_WRITE = 'fields:write',
  OPEN_GAMES_READ = 'open-games:read',
  OPEN_GAMES_WRITE = 'open-games:write',
  REVIEWS_READ = 'reviews:read',
  REVIEWS_WRITE = 'reviews:write',
  SEASONS_READ = 'seasons:read',
  SEASONS_WRITE = 'seasons:write',
  MATCHES_READ = 'matches:read',
  MATCHES_WRITE = 'matches:write',
  RANKINGS_READ = 'rankings:read',
  NOTIFICATIONS_WRITE = 'notifications:write',
}
```

- [ ] Commit: `git add shared/src/domain/enums/permission.enum.ts && git commit -m "feat(shared): add Permission enum"`

---

### Task 13: authenticated-user.interface.ts

**File:** `shared/src/infra/auth/interfaces/authenticated-user.interface.ts`

- [ ] Criar `shared/src/infra/auth/interfaces/authenticated-user.interface.ts`:

```typescript
export interface AuthenticatedUser {
  id: string;          // users.external_id (UUID)
  name: string;        // player_profiles.display_name
  email: string;
  permissions: string[];
}
```

- [ ] Commit: `git add shared/src/infra/auth/interfaces/authenticated-user.interface.ts && git commit -m "feat(shared): add AuthenticatedUser interface"`

---

### Task 14: jwt-auth.guard.ts

**File:** `shared/src/infra/auth/guards/jwt-auth.guard.ts`

- [ ] Criar `shared/src/infra/auth/guards/jwt-auth.guard.ts`:

```typescript
import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { IS_PUBLIC_KEY } from '../../../decorators/public.decorator';
import type { AuthenticatedUser } from '../interfaces/authenticated-user.interface';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context
      .switchToHttp()
      .getRequest<{ user?: AuthenticatedUser; headers: { authorization?: string } }>();

    const token = this.extractToken(request.headers.authorization);
    if (!token) throw new UnauthorizedException();

    try {
      const payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
      });
      request.user = payload;
    } catch {
      throw new UnauthorizedException();
    }

    return true;
  }

  private extractToken(authorization?: string): string | undefined {
    const [type, token] = authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
```

- [ ] Commit: `git add shared/src/infra/auth/guards/jwt-auth.guard.ts && git commit -m "feat(shared): add JwtAuthGuard"`

---

### Task 15: permissions.guard.ts

**File:** `shared/src/infra/auth/guards/permissions.guard.ts`

- [ ] Criar `shared/src/infra/auth/guards/permissions.guard.ts`:

```typescript
import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../../../decorators/permissions.decorator';
import type { AuthenticatedUser } from '../interfaces/authenticated-user.interface';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const request = context.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    const user = request.user;
    if (!user) return false;

    return required.every((p) => user.permissions.includes(p));
  }
}
```

- [ ] Commit: `git add shared/src/infra/auth/guards/permissions.guard.ts && git commit -m "feat(shared): add PermissionsGuard"`

---

### Task 16: shared-auth.module.ts

**File:** `shared/src/infra/auth/shared-auth.module.ts`

- [ ] Criar `shared/src/infra/auth/shared-auth.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { PermissionsGuard } from './guards/permissions.guard';

@Module({
  imports: [JwtModule.register({})],
  providers: [JwtAuthGuard, PermissionsGuard],
  exports: [JwtAuthGuard, PermissionsGuard, JwtModule],
})
export class SharedAuthModule {}
```

- [ ] Commit: `git add shared/src/infra/auth/shared-auth.module.ts && git commit -m "feat(shared): add SharedAuthModule"`

---

### Task 17: drizzle.service.ts

**File:** `shared/src/infra/database/drizzle.service.ts`

- [ ] Criar `shared/src/infra/database/drizzle.service.ts`:

```typescript
import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DrizzleService.name);
  private pool!: Pool;
  db!: NodePgDatabase;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const url = this.config.getOrThrow<string>('DATABASE_URL');
    this.pool = new Pool({ connectionString: url });
    this.db = drizzle(this.pool);
    this.logger.log('Database connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
    this.logger.log('Database disconnected');
  }
}
```

- [ ] Commit: `git add shared/src/infra/database/drizzle.service.ts && git commit -m "feat(shared): add DrizzleService"`

---

### Task 18: current-user.decorator.ts

**File:** `shared/src/infra/decorators/current-user.decorator.ts`

- [ ] Criar `shared/src/infra/decorators/current-user.decorator.ts`:

```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthenticatedUser => {
    const request = ctx.switchToHttp().getRequest<{ user: AuthenticatedUser }>();
    return request.user;
  },
);
```

- [ ] Commit: `git add shared/src/infra/decorators/current-user.decorator.ts && git commit -m "feat(shared): add CurrentUser decorator"`

---

### Task 19: permissions.decorator.ts

**File:** `shared/src/infra/decorators/permissions.decorator.ts`

- [ ] Criar `shared/src/infra/decorators/permissions.decorator.ts`:

```typescript
import { SetMetadata } from '@nestjs/common';

export const PERMISSIONS_KEY = 'permissions';

export const Permissions = (...permissions: string[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
```

- [ ] Commit: `git add shared/src/infra/decorators/permissions.decorator.ts && git commit -m "feat(shared): add Permissions decorator"`

---

### Task 20: public.decorator.ts

**File:** `shared/src/infra/decorators/public.decorator.ts`

- [ ] Criar `shared/src/infra/decorators/public.decorator.ts`:

```typescript
import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
```

- [ ] Commit: `git add shared/src/infra/decorators/public.decorator.ts && git commit -m "feat(shared): add Public decorator"`

---

### Task 21: hateoas.types.ts

**File:** `shared/src/infra/hateoas/hateoas.types.ts`

- [ ] Criar `shared/src/infra/hateoas/hateoas.types.ts`:

```typescript
export const HATEOAS_ITEM_KEY = 'hateoas:item';
export const HATEOAS_LIST_KEY = 'hateoas:list';

export interface HateoasLink {
  href: string;
}

export interface HateoasResponse<T> {
  data: T;
  _links: { self: HateoasLink };
}
```

- [ ] Commit: `git add shared/src/infra/hateoas/hateoas.types.ts && git commit -m "feat(shared): add HATEOAS types"`

---

### Task 22: hateoas.interceptor.ts

**File:** `shared/src/infra/hateoas/hateoas.interceptor.ts`

- [ ] Criar `shared/src/infra/hateoas/hateoas.interceptor.ts`:

```typescript
import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { HATEOAS_ITEM_KEY, HATEOAS_LIST_KEY } from './hateoas.types';

@Injectable()
export class HateoasInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const isItem = this.reflector.get<boolean>(HATEOAS_ITEM_KEY, context.getHandler());
    const isList = this.reflector.get<boolean>(HATEOAS_LIST_KEY, context.getHandler());

    if (!isItem && !isList) return next.handle();

    const request = context
      .switchToHttp()
      .getRequest<{ protocol: string; get: (h: string) => string; url: string }>();

    const selfHref = `${request.protocol}://${request.get('host')}${request.url}`;

    return next.handle().pipe(
      map((data) => ({ data, _links: { self: { href: selfHref } } })),
    );
  }
}
```

- [ ] Commit: `git add shared/src/infra/hateoas/hateoas.interceptor.ts && git commit -m "feat(shared): add HateoasInterceptor"`

---

### Task 23: hateoas-item.decorator.ts

**File:** `shared/src/infra/hateoas/hateoas-item.decorator.ts`

- [ ] Criar `shared/src/infra/hateoas/hateoas-item.decorator.ts`:

```typescript
import { SetMetadata } from '@nestjs/common';
import { HATEOAS_ITEM_KEY } from './hateoas.types';

export const HateoasItem = (_dto: unknown) => SetMetadata(HATEOAS_ITEM_KEY, true);
```

- [ ] Commit: `git add shared/src/infra/hateoas/hateoas-item.decorator.ts && git commit -m "feat(shared): add HateoasItem decorator"`

---

### Task 24: hateoas-list.decorator.ts

**File:** `shared/src/infra/hateoas/hateoas-list.decorator.ts`

- [ ] Criar `shared/src/infra/hateoas/hateoas-list.decorator.ts`:

```typescript
import { SetMetadata } from '@nestjs/common';
import { HATEOAS_LIST_KEY } from './hateoas.types';

export const HateoasList = (_dto: unknown) => SetMetadata(HATEOAS_LIST_KEY, true);
```

- [ ] Commit: `git add shared/src/infra/hateoas/hateoas-list.decorator.ts && git commit -m "feat(shared): add HateoasList decorator"`

---

### Task 25: hateoas/index.ts

**File:** `shared/src/infra/hateoas/index.ts`

- [ ] Criar `shared/src/infra/hateoas/index.ts`:

```typescript
export * from './hateoas.types';
export * from './hateoas.interceptor';
export * from './hateoas-item.decorator';
export * from './hateoas-list.decorator';
```

- [ ] Commit: `git add shared/src/infra/hateoas/index.ts && git commit -m "feat(shared): add HATEOAS barrel export"`

---

### Task 26: bootstrap-http-app.ts

**File:** `shared/src/infra/http/bootstrap-http-app.ts`

- [ ] Criar `shared/src/infra/http/bootstrap-http-app.ts`:

```typescript
import { INestApplication, Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { HateoasInterceptor } from '../hateoas/hateoas.interceptor';

export async function bootstrapHttpApp(app: INestApplication): Promise<void> {
  const logger = new Logger('Bootstrap');
  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3000);
  const reflector = app.get(Reflector);

  app.setGlobalPrefix('v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalInterceptors(new HateoasInterceptor(reflector));

  const swaggerConfig = new DocumentBuilder()
    .setTitle('BolaNaRede API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  await app.listen(port);
  logger.log(`Service running on port ${port}`);
}
```

- [ ] Commit: `git add shared/src/infra/http/bootstrap-http-app.ts && git commit -m "feat(shared): add bootstrapHttpApp helper"`

---

### Task 27: rabbitmq.service.ts

**File:** `shared/src/infra/messaging/rabbitmq.service.ts`

- [ ] Criar `shared/src/infra/messaging/rabbitmq.service.ts`:

```typescript
import type { RabbitMQConfig } from '@golevelup/nestjs-rabbitmq';
import type { ConfigService } from '@nestjs/config';

export function createRabbitMQConfig(config: ConfigService): RabbitMQConfig {
  return {
    exchanges: [
      { name: 'bolanarededb', type: 'topic' },
      { name: 'bolanarededb.dlq', type: 'topic' },
    ],
    uri: config.getOrThrow<string>('RABBITMQ_URL'),
    connectionInitOptions: { wait: false },
  };
}
```

- [ ] Commit: `git add shared/src/infra/messaging/rabbitmq.service.ts && git commit -m "feat(shared): add RabbitMQ config factory"`

---

### Task 28: shared-messaging.service.ts

**File:** `shared/src/infra/messaging/shared-messaging.service.ts`

- [ ] Criar `shared/src/infra/messaging/shared-messaging.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { AmqpConnection } from '@golevelup/nestjs-rabbitmq';

@Injectable()
export class SharedMessagingService {
  private readonly logger = new Logger(SharedMessagingService.name);

  constructor(private readonly amqp: AmqpConnection) {}

  async publish(routingKey: string, payload: Record<string, unknown>): Promise<void> {
    await this.amqp.publish('bolanarededb', routingKey, payload);
    this.logger.debug(`Published event: ${routingKey}`);
  }
}
```

- [ ] Commit: `git add shared/src/infra/messaging/shared-messaging.service.ts && git commit -m "feat(shared): add SharedMessagingService"`

---

### Task 29: shared.module.ts

**File:** `shared/src/shared.module.ts`

- [ ] Criar `shared/src/shared.module.ts`:

```typescript
import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { RabbitMQModule } from '@golevelup/nestjs-rabbitmq';
import { DrizzleService } from './infra/database/drizzle.service';
import { JwtAuthGuard } from './infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from './infra/auth/guards/permissions.guard';
import { SharedMessagingService } from './infra/messaging/shared-messaging.service';
import { createRabbitMQConfig } from './infra/messaging/rabbitmq.service';

@Global()
@Module({
  imports: [
    ConfigModule,
    JwtModule.register({}),
    RabbitMQModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: createRabbitMQConfig,
    }),
  ],
  providers: [DrizzleService, JwtAuthGuard, PermissionsGuard, SharedMessagingService],
  exports: [DrizzleService, JwtAuthGuard, PermissionsGuard, SharedMessagingService, JwtModule],
})
export class SharedModule {}
```

- [ ] Verificar: todos os arquivos `shared/src/` criados corretamente.
- [ ] Commit: `git add shared/ && git commit -m "feat(shared): add SharedModule — completes shared module implementation"`

---

## Verificação Final

Após a Task 29, o shared module está completo. A verificação real acontece quando o `identity-service` compilar com sucesso (Task 12 do plano de identity).

**Checklist de conclusão:**
- [ ] Todos os 29 arquivos criados
- [ ] Nenhum `any` explícito sem justificativa
- [ ] Nenhum `console.log` (usar `Logger` do NestJS)
- [ ] Atualizar `docs/plans/_status.md`: `shared | ✅ DONE | 29/29`
