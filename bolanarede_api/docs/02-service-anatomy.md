# Anatomia de um Serviço

Todo serviço segue exatamente esta estrutura interna. Sem exceções.

## Estrutura de Pastas

```
services/{service-name}/
├── .env.example
├── drizzle/                          ← migrations geradas pelo Drizzle Kit
│   ├── 0000_*.sql
│   └── meta/
│       ├── _journal.json
│       └── 0000_snapshot.json
├── drizzle.config.ts
├── nest-cli.json
├── package.json
├── tsconfig.json                     ← extends ../../tsconfig.base.json
├── tsconfig.build.json
└── src/
    ├── app.module.ts
    ├── main.ts
    └── modules/
        └── {domain}/                 ← nome do bounded context (ex: "open-game")
            ├── {domain}.module.ts
            └── {entity}/             ← cada entidade (ex: "open-game", "participation")
                ├── {entity}.module.ts
                ├── application/
                │   ├── dto/
                │   │   ├── create-{entity}.dto.ts
                │   │   ├── update-{entity}.dto.ts
                │   │   └── {entity}.dto.ts
                │   └── services/
                │       ├── {entity}.service.ts
                │       ├── {entity}-messaging.service.ts
                │       └── {entity}-message-consumer.service.ts  ← só se consome eventos
                ├── domain/
                │   ├── models/
                │   │   └── {entity}.entity.ts
                │   └── repositories/
                │       └── {entity}-repository.interface.ts
                └── infra/
                    ├── controllers/
                    │   └── {entities}.controller.ts
                    ├── database/
                    │   └── schemas/
                    │       ├── {entity}.schema.ts          ← schema Drizzle próprio
                    │       └── {projection}.schema.ts      ← projeção de outro serviço
                    └── repositories/
                        └── drizzle-{entity}.repository.ts
```

## Responsabilidade de Cada Camada

### `domain/` — O que existe, não como funciona

- `models/` — Classe pura TypeScript representando a entidade de domínio
- `repositories/` — Interface do repositório + constante de injeção

### `application/` — Como funciona, não onde está

- `dto/` — Objetos de entrada e saída (class-validator, class-transformer)
- `services/` — Lógica de negócio, orquestração, publicação de eventos

### `infra/` — Detalhes técnicos

- `controllers/` — Endpoints HTTP (recebe request, devolve response)
- `database/schemas/` — Schemas Drizzle (tabelas do banco)
- `repositories/` — Implementação Drizzle do repositório

## Arquivos Obrigatórios por Entidade

### 1. domain/models/{entity}.entity.ts

```typescript
export class OpenGame {
  id: string;
  organizerId: string;
  organizerSnapshot: Record<string, unknown>;
  fieldSnapshot: Record<string, unknown>;
  title: string;
  type: 'OPEN' | 'CLOSED';
  status: 'OPEN' | 'FULL' | 'FINISHED' | 'CANCELLED';
  scheduledAt: Date;
  maxPlayers: number;
  minPlayers: number | null;
  confirmedCount: number;
  createdAt: Date;
  updatedAt: Date;
}
```

### 2. domain/repositories/{entity}-repository.interface.ts

```typescript
import { OpenGame } from '../models/open-game.entity';

export const OPEN_GAME_REPOSITORY = 'OPEN_GAME_REPOSITORY';

export interface OpenGameRepositoryInterface {
  findById(id: string): Promise<OpenGame | null>;
  findAll(filters?: Record<string, unknown>): Promise<OpenGame[]>;
  create(data: Partial<OpenGame>): Promise<OpenGame>;
  update(id: string, data: Partial<OpenGame>): Promise<OpenGame>;
  delete(id: string): Promise<void>;
}
```

### 3. application/dto/create-{entity}.dto.ts

```typescript
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsNumber,
  IsOptional,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateOpenGameDto {
  @ApiProperty({ description: 'Título da pelada' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'Data e hora da pelada (ISO 8601)' })
  @IsDateString()
  scheduledAt: string;

  @ApiProperty({ description: 'Número máximo de jogadores' })
  @IsNumber()
  @Min(2)
  maxPlayers: number;

  @ApiPropertyOptional({ description: 'ID do campo (opcional)' })
  @IsString()
  @IsOptional()
  fieldId?: string;
}
```

### 4. application/dto/{entity}.dto.ts

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { OpenGame } from '../../domain/models/open-game.entity';

export class OpenGameDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  status: string;

  @ApiProperty()
  scheduledAt: Date;

  @ApiProperty()
  confirmedCount: number;

  @ApiProperty()
  createdAt: Date;

  static fromEntity(entity: OpenGame): OpenGameDto {
    const dto = new OpenGameDto();
    dto.id = entity.id;
    dto.title = entity.title;
    dto.status = entity.status;
    dto.scheduledAt = entity.scheduledAt;
    dto.confirmedCount = entity.confirmedCount;
    dto.createdAt = entity.createdAt;
    return dto;
  }
}
```

### 5. application/services/{entity}.service.ts

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import {
  OpenGameRepositoryInterface,
  OPEN_GAME_REPOSITORY,
} from '../../domain/repositories/open-game-repository.interface';
import { OpenGameMessagingService } from './open-game-messaging.service';
import { CreateOpenGameDto } from '../dto/create-open-game.dto';
import { OpenGameDto } from '../dto/open-game.dto';
import { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';

@Injectable()
export class OpenGameService {
  constructor(
    @Inject(OPEN_GAME_REPOSITORY)
    private readonly openGameRepository: OpenGameRepositoryInterface,
    private readonly messagingService: OpenGameMessagingService,
  ) {}

  async create(
    dto: CreateOpenGameDto,
    user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    const game = await this.openGameRepository.create({
      ...dto,
      scheduledAt: new Date(dto.scheduledAt),
      organizerId: user.id,
      organizerSnapshot: { id: user.id, name: user.name },
      confirmedCount: 0,
      status: 'OPEN',
    });

    await this.messagingService.publishCreated(game);

    return OpenGameDto.fromEntity(game);
  }

  async findById(id: string): Promise<OpenGameDto> {
    const game = await this.openGameRepository.findById(id);
    if (!game) throw new NotFoundException(`OpenGame ${id} not found`);
    return OpenGameDto.fromEntity(game);
  }
}
```

### 6. infra/controllers/{entities}.controller.ts

```typescript
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { OpenGameService } from '../../application/services/open-game.service';
import { CreateOpenGameDto } from '../../application/dto/create-open-game.dto';
import { OpenGameDto } from '../../application/dto/open-game.dto';

@ApiTags('open-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('open-games')
export class OpenGamesController {
  constructor(private readonly openGameService: OpenGameService) {}

  @Post()
  @Permissions('open-games:write')
  @HateoasItem(OpenGameDto)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Criar uma pelada' })
  create(
    @Body() dto: CreateOpenGameDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    return this.openGameService.create(dto, user);
  }

  @Get()
  @Public()
  @HateoasList(OpenGameDto)
  @ApiOperation({ summary: 'Listar peladas abertas' })
  findAll(): Promise<OpenGameDto[]> {
    return this.openGameService.findAll();
  }

  @Get(':id')
  @Public()
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Buscar pelada por ID' })
  findOne(@Param('id') id: string): Promise<OpenGameDto> {
    return this.openGameService.findById(id);
  }
}
```

### 7. {entity}.module.ts

```typescript
import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { OpenGameService } from './application/services/open-game.service';
import { OpenGameMessagingService } from './application/services/open-game-messaging.service';
import { PlayerSummaryMessageConsumerService } from './application/services/player-summary-message-consumer.service';
import { OpenGamesController } from './infra/controllers/open-games.controller';
import { DrizzleOpenGameRepository } from './infra/repositories/drizzle-open-game.repository';
import { OPEN_GAME_REPOSITORY } from './domain/repositories/open-game-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [OpenGamesController],
  providers: [
    OpenGameService,
    OpenGameMessagingService,
    PlayerSummaryMessageConsumerService,
    {
      provide: OPEN_GAME_REPOSITORY,
      useClass: DrizzleOpenGameRepository,
    },
  ],
})
export class OpenGameModule {}
```

### 8. {domain}.module.ts

```typescript
import { Module } from '@nestjs/common';
import { OpenGameModule } from './open-game/open-game.module';
import { ParticipationModule } from './participation/participation.module';

@Module({
  imports: [OpenGameModule, ParticipationModule],
})
export class OpenGameDomainModule {}
```

### 9. app.module.ts

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OpenGameDomainModule } from './modules/open-game/open-game.module';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), OpenGameDomainModule],
})
export class AppModule {}
```

### 10. main.ts

```typescript
import { NestFactory } from '@nestjs/core';
import { bootstrapHttpApp } from '@shared/infra/http/bootstrap-http-app';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await bootstrapHttpApp(app);
}

bootstrap();
```

## Ordem de Criação de uma Nova Entidade

1. `domain/models/{entity}.entity.ts`
2. `domain/repositories/{entity}-repository.interface.ts`
3. `infra/database/schemas/{entity}.schema.ts`
4. `infra/repositories/drizzle-{entity}.repository.ts`
5. `application/dto/create-{entity}.dto.ts`
6. `application/dto/update-{entity}.dto.ts`
7. `application/dto/{entity}.dto.ts`
8. `application/services/{entity}.service.ts`
9. `application/services/{entity}-messaging.service.ts`
10. `application/services/{entity}-message-consumer.service.ts` (se consome)
11. `infra/controllers/{entities}.controller.ts`
12. `{entity}.module.ts`
13. Registrar no `{domain}.module.ts`
14. `npm run db:generate` → `npm run db:migrate`
