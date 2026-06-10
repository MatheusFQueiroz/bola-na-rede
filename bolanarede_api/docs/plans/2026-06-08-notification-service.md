# Notification Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the notification service that consumes domain events from all other services and delivers in-app notifications (stored in MongoDB) to users, with optional push notification support.

**Architecture:** Standalone NestJS service on port 4010 that does **NOT** import SharedModule (SharedModule injects DrizzleService which requires PostgreSQL — notification uses MongoDB instead). JWT, RabbitMQ, and Mongoose are configured manually in AppModule. Redis is used for event deduplication via SET NX. Consumers translate domain events into Notification documents in MongoDB. REST endpoints let authenticated users read and acknowledge notifications.

**Tech Stack:** NestJS 11, TypeScript 5, @nestjs/mongoose + Mongoose 8, ioredis 5, @golevelup/nestjs-rabbitmq 4, @nestjs/jwt 10, MongoDB 7, Redis 7, Biome (formatting/linting).

---

## File Map

```
services/notification/
├── package.json
├── tsconfig.json
├── .env.example
├── Dockerfile
├── docker-entrypoint.sh
├── scripts/
│   └── setup-indexes.js          — creates MongoDB indexes on startup
└── src/
    ├── main.ts
    ├── app.module.ts              — ConfigModule + MongooseModule + RabbitMQModule + JwtModule + NotificationModule
    └── modules/
        └── notification/
            ├── notification.module.ts
            ├── domain/
            │   ├── models/
            │   │   ├── notification.entity.ts   — NotificationType enum + Notification class
            │   │   └── device-token.entity.ts   — DevicePlatform type + DeviceToken class
            │   └── repositories/
            │       ├── notification-repository.interface.ts  — NOTIFICATION_REPOSITORY token
            │       └── device-token-repository.interface.ts  — DEVICE_TOKEN_REPOSITORY token
            ├── application/
            │   ├── services/
            │   │   ├── notification.service.ts       — createNotification (dedup+save+push), get, mark-read
            │   │   ├── notification.service.spec.ts  — 6 tests
            │   │   ├── device-token.service.ts
            │   │   ├── device-token.service.spec.ts  — 3 tests
            │   │   └── consumers/
            │   │       ├── identity-events.consumer.ts           — device-token-updated
            │   │       ├── matchmaking-events.consumer.ts        — match-accepted + match-expired
            │   │       ├── matchmaking-events.consumer.spec.ts   — 2 tests
            │   │       ├── game-events.consumer.ts               — match-completed + result-disputed
            │   │       ├── game-events.consumer.spec.ts          — 2 tests
            │   │       ├── gamification-events.consumer.ts       — badge-awarded
            │   │       └── gamification-events.consumer.spec.ts  — 2 tests
            │   └── dto/
            │       └── notification-response.dto.ts
            └── infra/
                ├── schemas/
                │   ├── notification.schema.ts   — NotificationDoc + NotificationSchema
                │   └── device-token.schema.ts   — DeviceTokenDoc + DeviceTokenSchema
                ├── database/
                │   └── repositories/
                │       ├── mongoose-notification.repository.ts
                │       └── mongoose-device-token.repository.ts
                ├── redis/
                │   └── redis.provider.ts        — REDIS_CLIENT token
                ├── push/
                │   └── push-notification.service.ts  — stub: logs instead of calling FCM
                └── controllers/
                    └── notifications.controller.ts
```

## Event Payloads (consumed)

| Event | Routing Key | Payload shape |
|-------|-------------|---------------|
| Device token | `identity.device-token-updated` | `{ userId, token, platform }` |
| Match accepted | `matchmaking.match-accepted` | `{ matchId, userAId, userBId, sport }` |
| Match expired | `matchmaking.match-expired` | `{ matchId, userAId, userBId, sport }` |
| Match completed | `game.match-completed` | `{ gameId, matchId, sport, winnerId, players: [{playerUserId, goals, assists, won}] }` |
| Result disputed | `game.result-disputed` | `{ gameId, matchId, sport, disputedByUserId }` |
| Badge awarded | `gamification.badge-awarded` | `{ playerUserId, badgeCode, earnedAt }` |

---

### Task 1: package.json + tsconfig.json

**Files:**
- Create: `services/notification/package.json`
- Create: `services/notification/tsconfig.json`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "@bolanarede/notification",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "start": "node dist/services/notification/src/main",
    "test": "jest --passWithNoTests",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "@golevelup/nestjs-rabbitmq": "^4.1.0",
    "@nestjs/common": "^11.0.0",
    "@nestjs/config": "^3.2.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/jwt": "^10.2.0",
    "@nestjs/mongoose": "^10.1.0",
    "@nestjs/platform-express": "^11.0.0",
    "@nestjs/swagger": "^8.0.0",
    "class-transformer": "^0.5.1",
    "class-validator": "^0.14.1",
    "ioredis": "^5.4.1",
    "mongoose": "^8.9.0",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.4",
    "@nestjs/testing": "^11.0.0",
    "@types/node": "^22.0.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.2.5",
    "typescript": "^5.7.3"
  },
  "jest": {
    "moduleFileExtensions": ["js", "json", "ts"],
    "rootDir": "src",
    "testRegex": ".*\\.spec\\.ts$",
    "transform": { "^.+\\.(t|j)s$": "ts-jest" },
    "collectCoverageFrom": ["**/*.(t|j)s"],
    "coverageDirectory": "../coverage",
    "testEnvironment": "node",
    "moduleNameMapper": {
      "^@shared/(.*)$": "<rootDir>/../../../shared/src/$1"
    },
    "modulePaths": ["<rootDir>/../node_modules"]
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "../../dist/services/notification",
    "rootDir": ".",
    "baseUrl": ".",
    "paths": {
      "@shared/*": ["../../shared/src/*"]
    }
  },
  "include": ["src/**/*", "../../shared/src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 3: Install dependencies (from monorepo root)**

```bash
npm install --legacy-peer-deps
```

- [ ] **Step 4: Verify TypeScript config parses**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -5
```
Expected: empty output or "error TS18003: No inputs were found" (no source files yet — both are acceptable)

- [ ] **Step 5: Commit**

```bash
git add services/notification/package.json services/notification/tsconfig.json
git commit -m "chore(notification): scaffold notification service — package.json + tsconfig"
```

---

### Task 2: main.ts + app.module.ts

**Files:**
- Create: `services/notification/src/main.ts`
- Create: `services/notification/src/app.module.ts`

**Context:** SharedModule is NOT imported here because it injects DrizzleService (requires PostgreSQL DATABASE_URL). Instead, RabbitMQ, JWT, and Mongoose are configured directly. The `bootstrapHttpApp` helper from shared is still used for consistent HTTP setup (global prefix `v1`, ValidationPipe, Swagger, etc.).

- [ ] **Step 1: Create main.ts**

```typescript
// services/notification/src/main.ts
import { bootstrapHttpApp } from '@shared/infra/http/bootstrap-http-app';
import { AppModule } from './app.module';

bootstrapHttpApp(AppModule);
```

- [ ] **Step 2: Create app.module.ts**

```typescript
// services/notification/src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { RabbitMQModule } from '@golevelup/nestjs-rabbitmq';
import { createRabbitMQConfig } from '@shared/infra/messaging/rabbitmq.service';
import { NotificationModule } from './modules/notification/notification.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        uri: config.getOrThrow<string>('MONGODB_URL'),
        autoIndex: true,
      }),
      inject: [ConfigService],
    }),
    RabbitMQModule.forRootAsync(RabbitMQModule, {
      imports: [ConfigModule],
      useFactory: createRabbitMQConfig,
      inject: [ConfigService],
    }),
    JwtModule.registerAsync({
      global: true,
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
      }),
      inject: [ConfigService],
    }),
    NotificationModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 3: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add services/notification/src/main.ts services/notification/src/app.module.ts
git commit -m "chore(notification): add main.ts and app.module.ts"
```

---

### Task 3: NotificationType enum + domain entities

**Files:**
- Create: `services/notification/src/modules/notification/domain/models/notification.entity.ts`
- Create: `services/notification/src/modules/notification/domain/models/device-token.entity.ts`

- [ ] **Step 1: Create notification.entity.ts**

```typescript
// services/notification/src/modules/notification/domain/models/notification.entity.ts

export enum NotificationType {
  MATCH_ACCEPTED = 'match_accepted',
  MATCH_EXPIRED = 'match_expired',
  MATCH_COMPLETED = 'match_completed',
  RESULT_DISPUTED = 'result_disputed',
  BADGE_AWARDED = 'badge_awarded',
}

export class Notification {
  id!: string;
  recipientUserId!: string;
  type!: NotificationType;
  title!: string;
  body!: string;
  data!: Record<string, unknown>;
  isRead!: boolean;
  createdAt!: Date;
}
```

- [ ] **Step 2: Create device-token.entity.ts**

```typescript
// services/notification/src/modules/notification/domain/models/device-token.entity.ts

export type DevicePlatform = 'ios' | 'android' | 'web';

export class DeviceToken {
  id!: string;
  userId!: string;
  token!: string;
  platform!: DevicePlatform;
  updatedAt!: Date;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/domain/models/
git commit -m "feat(notification): add Notification entity, NotificationType enum, DeviceToken entity"
```

---

### Task 4: Repository interfaces

**Files:**
- Create: `services/notification/src/modules/notification/domain/repositories/notification-repository.interface.ts`
- Create: `services/notification/src/modules/notification/domain/repositories/device-token-repository.interface.ts`

- [ ] **Step 1: Create notification-repository.interface.ts**

```typescript
// services/notification/src/modules/notification/domain/repositories/notification-repository.interface.ts
import type { Notification, NotificationType } from '../models/notification.entity';

export const NOTIFICATION_REPOSITORY = 'NOTIFICATION_REPOSITORY';

export interface CreateNotificationData {
  recipientUserId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, unknown>;
}

export interface NotificationRepositoryInterface {
  create(data: CreateNotificationData): Promise<Notification>;
  findByUserId(userId: string, skip: number, limit: number): Promise<Notification[]>;
  findById(id: string, userId: string): Promise<Notification | null>;
  markAsRead(id: string, userId: string): Promise<Notification | null>;
  markAllAsRead(userId: string): Promise<void>;
  countUnread(userId: string): Promise<number>;
}
```

- [ ] **Step 2: Create device-token-repository.interface.ts**

```typescript
// services/notification/src/modules/notification/domain/repositories/device-token-repository.interface.ts
import type { DeviceToken, DevicePlatform } from '../models/device-token.entity';

export const DEVICE_TOKEN_REPOSITORY = 'DEVICE_TOKEN_REPOSITORY';

export interface UpsertDeviceTokenData {
  userId: string;
  token: string;
  platform: DevicePlatform;
}

export interface DeviceTokenRepositoryInterface {
  upsert(data: UpsertDeviceTokenData): Promise<DeviceToken>;
  findByUserId(userId: string): Promise<DeviceToken | null>;
}
```

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/domain/repositories/
git commit -m "feat(notification): add repository interfaces with injection tokens"
```

---

### Task 5: MongoDB schemas

**Files:**
- Create: `services/notification/src/modules/notification/infra/schemas/notification.schema.ts`
- Create: `services/notification/src/modules/notification/infra/schemas/device-token.schema.ts`

**Context:** `@nestjs/mongoose` uses class decorators (`@Schema`, `@Prop`) to define schemas. The schema class (e.g. `NotificationDoc`) is separate from the domain entity (`Notification`) to avoid naming conflicts. `SchemaFactory.createForClass(NotificationDoc)` generates the Mongoose schema object. Compound indexes are created on the schema object after creation. Adding `createdAt?: Date` and `updatedAt?: Date` on the schema class exposes timestamp fields for TypeScript use.

- [ ] **Step 1: Create notification.schema.ts**

```typescript
// services/notification/src/modules/notification/infra/schemas/notification.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { NotificationType } from '../../domain/models/notification.entity';

export type NotificationDocument = NotificationDoc & Document;

@Schema({ timestamps: true, collection: 'notifications' })
export class NotificationDoc {
  @Prop({ required: true }) recipientUserId!: string;
  @Prop({ required: true, enum: NotificationType }) type!: NotificationType;
  @Prop({ required: true }) title!: string;
  @Prop({ required: true }) body!: string;
  @Prop({ type: Object, default: {} }) data!: Record<string, unknown>;
  @Prop({ default: false }) isRead!: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(NotificationDoc);
NotificationSchema.index({ recipientUserId: 1, createdAt: -1 });
NotificationSchema.index({ recipientUserId: 1, isRead: 1 });
```

- [ ] **Step 2: Create device-token.schema.ts**

```typescript
// services/notification/src/modules/notification/infra/schemas/device-token.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import type { DevicePlatform } from '../../domain/models/device-token.entity';

export type DeviceTokenDocument = DeviceTokenDoc & Document;

@Schema({ timestamps: true, collection: 'device_tokens' })
export class DeviceTokenDoc {
  @Prop({ required: true, unique: true }) userId!: string;
  @Prop({ required: true }) token!: string;
  @Prop({ required: true, enum: ['ios', 'android', 'web'] }) platform!: DevicePlatform;
  updatedAt?: Date;
}

export const DeviceTokenSchema = SchemaFactory.createForClass(DeviceTokenDoc);
```

- [ ] **Step 3: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add services/notification/src/modules/notification/infra/schemas/
git commit -m "feat(notification): add NotificationDoc and DeviceTokenDoc Mongoose schemas"
```

---

### Task 6: MongooseNotificationRepository

**Files:**
- Create: `services/notification/src/modules/notification/infra/database/repositories/mongoose-notification.repository.ts`

**Context:** `@InjectModel(NotificationDoc.name)` injects the Mongoose model. `NotificationDoc.name` equals the string `'NotificationDoc'` (JavaScript class name). This must match the `name` used in `MongooseModule.forFeature`. The `_id` field on a Mongoose document is `Types.ObjectId` — call `.toString()` to get the string representation.

- [ ] **Step 1: Create mongoose-notification.repository.ts**

```typescript
// services/notification/src/modules/notification/infra/database/repositories/mongoose-notification.repository.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type {
  NotificationRepositoryInterface,
  CreateNotificationData,
} from '../../../domain/repositories/notification-repository.interface';
import type { Notification } from '../../../domain/models/notification.entity';
import { NotificationDoc, type NotificationDocument } from '../../schemas/notification.schema';

@Injectable()
export class MongooseNotificationRepository implements NotificationRepositoryInterface {
  constructor(
    @InjectModel(NotificationDoc.name)
    private readonly model: Model<NotificationDocument>,
  ) {}

  private toEntity(doc: NotificationDocument): Notification {
    return {
      id: doc._id.toString(),
      recipientUserId: doc.recipientUserId,
      type: doc.type,
      title: doc.title,
      body: doc.body,
      data: doc.data,
      isRead: doc.isRead,
      createdAt: doc.createdAt ?? new Date(),
    };
  }

  async create(data: CreateNotificationData): Promise<Notification> {
    const doc = await this.model.create(data);
    return this.toEntity(doc);
  }

  async findByUserId(userId: string, skip: number, limit: number): Promise<Notification[]> {
    const docs = await this.model
      .find({ recipientUserId: userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();
    return docs.map((d) => this.toEntity(d));
  }

  async findById(id: string, userId: string): Promise<Notification | null> {
    const doc = await this.model.findOne({ _id: id, recipientUserId: userId }).exec();
    return doc ? this.toEntity(doc) : null;
  }

  async markAsRead(id: string, userId: string): Promise<Notification | null> {
    const doc = await this.model
      .findOneAndUpdate(
        { _id: id, recipientUserId: userId },
        { $set: { isRead: true } },
        { new: true },
      )
      .exec();
    return doc ? this.toEntity(doc) : null;
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.model
      .updateMany({ recipientUserId: userId, isRead: false }, { $set: { isRead: true } })
      .exec();
  }

  async countUnread(userId: string): Promise<number> {
    return this.model.countDocuments({ recipientUserId: userId, isRead: false }).exec();
  }
}
```

- [ ] **Step 2: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/infra/database/repositories/mongoose-notification.repository.ts
git commit -m "feat(notification): add MongooseNotificationRepository"
```

---

### Task 7: MongooseDeviceTokenRepository

**Files:**
- Create: `services/notification/src/modules/notification/infra/database/repositories/mongoose-device-token.repository.ts`

- [ ] **Step 1: Create mongoose-device-token.repository.ts**

```typescript
// services/notification/src/modules/notification/infra/database/repositories/mongoose-device-token.repository.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type {
  DeviceTokenRepositoryInterface,
  UpsertDeviceTokenData,
} from '../../../domain/repositories/device-token-repository.interface';
import type { DeviceToken } from '../../../domain/models/device-token.entity';
import { DeviceTokenDoc, type DeviceTokenDocument } from '../../schemas/device-token.schema';

@Injectable()
export class MongooseDeviceTokenRepository implements DeviceTokenRepositoryInterface {
  constructor(
    @InjectModel(DeviceTokenDoc.name)
    private readonly model: Model<DeviceTokenDocument>,
  ) {}

  private toEntity(doc: DeviceTokenDocument): DeviceToken {
    return {
      id: doc._id.toString(),
      userId: doc.userId,
      token: doc.token,
      platform: doc.platform,
      updatedAt: doc.updatedAt ?? new Date(),
    };
  }

  async upsert(data: UpsertDeviceTokenData): Promise<DeviceToken> {
    const doc = await this.model
      .findOneAndUpdate(
        { userId: data.userId },
        { $set: { token: data.token, platform: data.platform } },
        { upsert: true, new: true },
      )
      .exec();
    return this.toEntity(doc!);
  }

  async findByUserId(userId: string): Promise<DeviceToken | null> {
    const doc = await this.model.findOne({ userId }).exec();
    return doc ? this.toEntity(doc) : null;
  }
}
```

- [ ] **Step 2: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/infra/database/repositories/mongoose-device-token.repository.ts
git commit -m "feat(notification): add MongooseDeviceTokenRepository"
```

---

### Task 8: Redis provider + PushNotificationService

**Files:**
- Create: `services/notification/src/modules/notification/infra/redis/redis.provider.ts`
- Create: `services/notification/src/modules/notification/infra/push/push-notification.service.ts`

**Context:** Redis is used for event deduplication. The SET NX pattern: `redis.set(key, '1', 'EX', 86400, 'NX')` — the EX option must come before NX (ioredis v5 ordering requirement). Returns `'OK'` on first write, `null` if key already exists. `PushNotificationService` is a stub that logs the push payload — real FCM integration is left as future work.

- [ ] **Step 1: Create redis.provider.ts**

```typescript
// services/notification/src/modules/notification/infra/redis/redis.provider.ts
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export const REDIS_CLIENT = 'REDIS_CLIENT';

export const redisProvider = {
  provide: REDIS_CLIENT,
  useFactory: (config: ConfigService) => {
    return new Redis(config.getOrThrow<string>('REDIS_URL'));
  },
  inject: [ConfigService],
};
```

- [ ] **Step 2: Create push-notification.service.ts**

```typescript
// services/notification/src/modules/notification/infra/push/push-notification.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);

  async send(
    token: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ): Promise<void> {
    // Production: integrate with FCM / APNs using firebase-admin
    this.logger.log(
      `[PUSH] token=${token.slice(0, 12)}... title="${title}" body="${body}" data=${JSON.stringify(data ?? {})}`,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/infra/redis/ \
        services/notification/src/modules/notification/infra/push/
git commit -m "feat(notification): add Redis provider (REDIS_CLIENT) and PushNotificationService stub"
```

---

### Task 9: NotificationService + tests

**Files:**
- Create: `services/notification/src/modules/notification/application/services/notification.service.ts`
- Create: `services/notification/src/modules/notification/application/services/notification.service.spec.ts`

**Context:** `createNotification` deduplicates by eventId via Redis SET NX (EX before NX): `redis.set(key, '1', 'EX', 86400, 'NX')` — returns `'OK'` on first call, `null` if already processed. Push failures must NOT throw (catch + warn log). `markAsRead` throws `NotFoundException` if the notification doesn't belong to the requesting user.

- [ ] **Step 1: Write the failing tests**

```typescript
// services/notification/src/modules/notification/application/services/notification.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { NotificationService, type CreateNotificationData } from './notification.service';
import { NOTIFICATION_REPOSITORY } from '../../domain/repositories/notification-repository.interface';
import { DEVICE_TOKEN_REPOSITORY } from '../../domain/repositories/device-token-repository.interface';
import { REDIS_CLIENT } from '../../infra/redis/redis.provider';
import { PushNotificationService } from '../../infra/push/push-notification.service';
import { NotificationType } from '../../domain/models/notification.entity';

const mockNotifRepo = {
  create: jest.fn(),
  findByUserId: jest.fn(),
  findById: jest.fn(),
  markAsRead: jest.fn(),
  markAllAsRead: jest.fn(),
  countUnread: jest.fn(),
};
const mockTokenRepo = { upsert: jest.fn(), findByUserId: jest.fn() };
const mockRedis = { set: jest.fn() };
const mockPush = { send: jest.fn() };

const makeNotif = (overrides = {}) => ({
  id: 'abc123',
  recipientUserId: 'user-1',
  type: NotificationType.MATCH_ACCEPTED,
  title: 'Match encontrado!',
  body: 'Seu jogo foi aceito.',
  data: {},
  isRead: false,
  createdAt: new Date(),
  ...overrides,
});

describe('NotificationService', () => {
  let service: NotificationService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        { provide: NOTIFICATION_REPOSITORY, useValue: mockNotifRepo },
        { provide: DEVICE_TOKEN_REPOSITORY, useValue: mockTokenRepo },
        { provide: REDIS_CLIENT, useValue: mockRedis },
        { provide: PushNotificationService, useValue: mockPush },
      ],
    }).compile();
    service = module.get(NotificationService);
  });

  describe('createNotification', () => {
    const data: CreateNotificationData = {
      eventId: 'evt-001',
      recipientUserId: 'user-1',
      type: NotificationType.MATCH_ACCEPTED,
      title: 'Match encontrado!',
      body: 'Seu jogo foi aceito.',
      data: {},
    };

    it('skips if event already processed (Redis NX returns null)', async () => {
      mockRedis.set.mockResolvedValue(null);

      await service.createNotification(data);

      expect(mockNotifRepo.create).not.toHaveBeenCalled();
    });

    it('creates notification and sends push when device token exists', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue({ token: 'tok-123', platform: 'ios' });
      mockPush.send.mockResolvedValue(undefined);

      await service.createNotification(data);

      expect(mockNotifRepo.create).toHaveBeenCalledWith({
        recipientUserId: data.recipientUserId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data,
      });
      expect(mockPush.send).toHaveBeenCalledWith('tok-123', data.title, data.body, data.data);
    });

    it('creates notification without push when no device token', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue(null);

      await service.createNotification(data);

      expect(mockNotifRepo.create).toHaveBeenCalled();
      expect(mockPush.send).not.toHaveBeenCalled();
    });

    it('does not throw if push send fails', async () => {
      mockRedis.set.mockResolvedValue('OK');
      mockNotifRepo.create.mockResolvedValue(makeNotif());
      mockTokenRepo.findByUserId.mockResolvedValue({ token: 'tok-123', platform: 'ios' });
      mockPush.send.mockRejectedValue(new Error('FCM error'));

      await expect(service.createNotification(data)).resolves.not.toThrow();
    });
  });

  describe('markAsRead', () => {
    it('throws NotFoundException if notification not found or not owned by user', async () => {
      mockNotifRepo.markAsRead.mockResolvedValue(null);

      await expect(service.markAsRead('notif-id', 'user-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getUnreadCount', () => {
    it('delegates to repository', async () => {
      mockNotifRepo.countUnread.mockResolvedValue(5);

      const count = await service.getUnreadCount('user-1');

      expect(count).toBe(5);
    });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/notification && npx jest --testPathPattern="notification.service.spec" --no-coverage 2>&1 | tail -10
```
Expected: FAIL — `Cannot find module './notification.service'`

- [ ] **Step 3: Implement notification.service.ts**

```typescript
// services/notification/src/modules/notification/application/services/notification.service.ts
import { Injectable, Inject, Logger, NotFoundException } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../infra/redis/redis.provider';
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepositoryInterface,
} from '../../domain/repositories/notification-repository.interface';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import { PushNotificationService } from '../../infra/push/push-notification.service';
import type { Notification, NotificationType } from '../../domain/models/notification.entity';

export interface CreateNotificationData {
  eventId: string;
  recipientUserId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, unknown>;
}

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @Inject(NOTIFICATION_REPOSITORY)
    private readonly notifRepo: NotificationRepositoryInterface,
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly tokenRepo: DeviceTokenRepositoryInterface,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly push: PushNotificationService,
  ) {}

  async createNotification(data: CreateNotificationData): Promise<void> {
    const dedupKey = `notification:dedup:${data.eventId}`;
    const set = await this.redis.set(dedupKey, '1', 'EX', 86400, 'NX');
    if (set === null) {
      this.logger.debug(`Event ${data.eventId} already processed, skipping`);
      return;
    }

    const notif = await this.notifRepo.create({
      recipientUserId: data.recipientUserId,
      type: data.type,
      title: data.title,
      body: data.body,
      data: data.data,
    });

    const deviceToken = await this.tokenRepo.findByUserId(data.recipientUserId);
    if (deviceToken) {
      try {
        await this.push.send(deviceToken.token, data.title, data.body, data.data);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.warn(
          `Push notification failed for user ${data.recipientUserId}: ${message}`,
        );
      }
    }

    this.logger.debug(`Notification ${notif.id} created for user ${data.recipientUserId}`);
  }

  async getNotifications(userId: string, skip: number, limit: number): Promise<Notification[]> {
    return this.notifRepo.findByUserId(userId, skip, limit);
  }

  async markAsRead(notificationId: string, userId: string): Promise<Notification> {
    const notif = await this.notifRepo.markAsRead(notificationId, userId);
    if (!notif) throw new NotFoundException(`Notification ${notificationId} not found`);
    return notif;
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notifRepo.markAllAsRead(userId);
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notifRepo.countUnread(userId);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/notification && npx jest --testPathPattern="notification.service.spec" --no-coverage 2>&1 | tail -10
```
Expected: PASS — 6 tests

- [ ] **Step 5: Commit**

```bash
git add services/notification/src/modules/notification/application/services/notification.service.ts \
        services/notification/src/modules/notification/application/services/notification.service.spec.ts
git commit -m "feat(notification): add NotificationService with dedup+push — 6 passing tests"
```

---

### Task 10: DeviceTokenService + tests

**Files:**
- Create: `services/notification/src/modules/notification/application/services/device-token.service.ts`
- Create: `services/notification/src/modules/notification/application/services/device-token.service.spec.ts`

- [ ] **Step 1: Write the failing tests**

```typescript
// services/notification/src/modules/notification/application/services/device-token.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { DeviceTokenService } from './device-token.service';
import { DEVICE_TOKEN_REPOSITORY } from '../../domain/repositories/device-token-repository.interface';

const mockRepo = { upsert: jest.fn(), findByUserId: jest.fn() };

describe('DeviceTokenService', () => {
  let service: DeviceTokenService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeviceTokenService,
        { provide: DEVICE_TOKEN_REPOSITORY, useValue: mockRepo },
      ],
    }).compile();
    service = module.get(DeviceTokenService);
  });

  it('delegates upsert to repository with correct args', async () => {
    const expected = {
      id: '1',
      userId: 'u1',
      token: 'tok',
      platform: 'ios' as const,
      updatedAt: new Date(),
    };
    mockRepo.upsert.mockResolvedValue(expected);

    const result = await service.upsertToken('u1', 'tok', 'ios');

    expect(mockRepo.upsert).toHaveBeenCalledWith({ userId: 'u1', token: 'tok', platform: 'ios' });
    expect(result).toEqual(expected);
  });

  it('returns null when no token found', async () => {
    mockRepo.findByUserId.mockResolvedValue(null);

    const result = await service.getToken('u1');

    expect(result).toBeNull();
  });

  it('returns token when found', async () => {
    const token = {
      id: '1',
      userId: 'u1',
      token: 'tok',
      platform: 'android' as const,
      updatedAt: new Date(),
    };
    mockRepo.findByUserId.mockResolvedValue(token);

    const result = await service.getToken('u1');

    expect(result).toEqual(token);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/notification && npx jest --testPathPattern="device-token.service.spec" --no-coverage 2>&1 | tail -10
```
Expected: FAIL

- [ ] **Step 3: Implement device-token.service.ts**

```typescript
// services/notification/src/modules/notification/application/services/device-token.service.ts
import { Injectable, Inject } from '@nestjs/common';
import {
  DEVICE_TOKEN_REPOSITORY,
  type DeviceTokenRepositoryInterface,
} from '../../domain/repositories/device-token-repository.interface';
import type { DeviceToken, DevicePlatform } from '../../domain/models/device-token.entity';

@Injectable()
export class DeviceTokenService {
  constructor(
    @Inject(DEVICE_TOKEN_REPOSITORY)
    private readonly repo: DeviceTokenRepositoryInterface,
  ) {}

  async upsertToken(userId: string, token: string, platform: DevicePlatform): Promise<DeviceToken> {
    return this.repo.upsert({ userId, token, platform });
  }

  async getToken(userId: string): Promise<DeviceToken | null> {
    return this.repo.findByUserId(userId);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/notification && npx jest --testPathPattern="device-token.service.spec" --no-coverage 2>&1 | tail -10
```
Expected: PASS — 3 tests

- [ ] **Step 5: Commit**

```bash
git add services/notification/src/modules/notification/application/services/device-token.service.ts \
        services/notification/src/modules/notification/application/services/device-token.service.spec.ts
git commit -m "feat(notification): add DeviceTokenService — 3 passing tests"
```

---

### Task 11: IdentityEventsConsumer

**Files:**
- Create: `services/notification/src/modules/notification/application/services/consumers/identity-events.consumer.ts`

**Context:** Consumes `identity.device-token-updated`. Payload: `{ userId, token, platform }`. This is a data ingestion event — calls `DeviceTokenService.upsertToken`, does NOT create a notification. Queue: `notification-service.identity.device-token-updated`.

- [ ] **Step 1: Create identity-events.consumer.ts**

```typescript
// services/notification/src/modules/notification/application/services/consumers/identity-events.consumer.ts
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { IdentityEvents } from '@shared/contracts/events/identity-events.enum';
import { DeviceTokenService } from '../device-token.service';
import type { DevicePlatform } from '../../../domain/models/device-token.entity';

interface DeviceTokenUpdatedPayload {
  userId: string;
  token: string;
  platform: DevicePlatform;
}

@Injectable()
export class IdentityEventsConsumer {
  private readonly logger = new Logger(IdentityEventsConsumer.name);

  constructor(private readonly deviceTokenService: DeviceTokenService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: IdentityEvents.DEVICE_TOKEN_UPDATED,
    queue: 'notification-service.identity.device-token-updated',
    queueOptions: { durable: true },
  })
  async handleDeviceTokenUpdated(payload: DeviceTokenUpdatedPayload): Promise<void> {
    try {
      await this.deviceTokenService.upsertToken(payload.userId, payload.token, payload.platform);
      this.logger.debug(`Device token updated for user ${payload.userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to update device token for user ${payload.userId}: ${message}`,
      );
    }
  }
}
```

- [ ] **Step 2: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add services/notification/src/modules/notification/application/services/consumers/identity-events.consumer.ts
git commit -m "feat(notification): add IdentityEventsConsumer for device-token-updated"
```

---

### Task 12: MatchmakingEventsConsumer + tests

**Files:**
- Create: `services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.ts`
- Create: `services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.spec.ts`

**Context:**
- `match-accepted`: notify both `userAId` and `userBId`. EventId format: `{routingKey}:{matchId}:{userId}` — unique per user per event (deduplication-safe).
- `match-expired`: notify only `userAId` (the requester — the player who initiated the match request). Queue names: `notification-service.matchmaking.match-accepted` and `notification-service.matchmaking.match-expired`.

- [ ] **Step 1: Write the failing tests**

```typescript
// services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { MatchmakingEventsConsumer } from './matchmaking-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('MatchmakingEventsConsumer', () => {
  let consumer: MatchmakingEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchmakingEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(MatchmakingEventsConsumer);
  });

  describe('handleMatchAccepted', () => {
    it('creates MATCH_ACCEPTED notifications for both players', async () => {
      const payload = {
        matchId: 'match-1',
        userAId: 'user-a',
        userBId: 'user-b',
        sport: 'futsal',
      };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchAccepted(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(2);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-a',
          type: NotificationType.MATCH_ACCEPTED,
        }),
      );
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-b',
          type: NotificationType.MATCH_ACCEPTED,
        }),
      );
    });
  });

  describe('handleMatchExpired', () => {
    it('creates MATCH_EXPIRED notification for userAId only', async () => {
      const payload = {
        matchId: 'match-1',
        userAId: 'user-a',
        userBId: 'user-b',
        sport: 'futsal',
      };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchExpired(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-a',
          type: NotificationType.MATCH_EXPIRED,
        }),
      );
    });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/notification && npx jest --testPathPattern="matchmaking-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: FAIL

- [ ] **Step 3: Create matchmaking-events.consumer.ts**

```typescript
// services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.ts
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { MatchmakingEvents } from '@shared/contracts/events/matchmaking-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface MatchAcceptedPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

interface MatchExpiredPayload {
  matchId: string;
  userAId: string;
  userBId: string;
  sport: string;
}

@Injectable()
export class MatchmakingEventsConsumer {
  private readonly logger = new Logger(MatchmakingEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_ACCEPTED,
    queue: 'notification-service.matchmaking.match-accepted',
    queueOptions: { durable: true },
  })
  async handleMatchAccepted(payload: MatchAcceptedPayload): Promise<void> {
    const title = 'Match encontrado!';
    const body = 'Seu jogo foi aceito. Boa sorte!';
    const data: Record<string, unknown> = { matchId: payload.matchId, sport: payload.sport };

    for (const userId of [payload.userAId, payload.userBId]) {
      try {
        await this.notifService.createNotification({
          eventId: `${MatchmakingEvents.MATCH_ACCEPTED}:${payload.matchId}:${userId}`,
          recipientUserId: userId,
          type: NotificationType.MATCH_ACCEPTED,
          title,
          body,
          data,
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(
          `Failed to notify user ${userId} for match-accepted ${payload.matchId}: ${message}`,
        );
      }
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: MatchmakingEvents.MATCH_EXPIRED,
    queue: 'notification-service.matchmaking.match-expired',
    queueOptions: { durable: true },
  })
  async handleMatchExpired(payload: MatchExpiredPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${MatchmakingEvents.MATCH_EXPIRED}:${payload.matchId}:${payload.userAId}`,
        recipientUserId: payload.userAId,
        type: NotificationType.MATCH_EXPIRED,
        title: 'Match expirado',
        body: 'Seu pedido de partida expirou. Tente novamente.',
        data: { matchId: payload.matchId, sport: payload.sport },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify match-expired for match ${payload.matchId}: ${message}`,
      );
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/notification && npx jest --testPathPattern="matchmaking-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: PASS — 2 tests

- [ ] **Step 5: Commit**

```bash
git add services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.ts \
        services/notification/src/modules/notification/application/services/consumers/matchmaking-events.consumer.spec.ts
git commit -m "feat(notification): add MatchmakingEventsConsumer — 2 passing tests"
```

---

### Task 13: GameEventsConsumer + tests

**Files:**
- Create: `services/notification/src/modules/notification/application/services/consumers/game-events.consumer.ts`
- Create: `services/notification/src/modules/notification/application/services/consumers/game-events.consumer.spec.ts`

**Context:**
- `game.match-completed` payload: `{ gameId, matchId, sport, winnerId: string|null, players: [{playerUserId, goals, assists, won}] }` — notify each player in `players`.
- `game.result-disputed` payload: `{ gameId, matchId, sport, disputedByUserId }` — notify `disputedByUserId` only (the full player list is not in this event; notifying the other player requires a game query which this service does not make).

- [ ] **Step 1: Write the failing tests**

```typescript
// services/notification/src/modules/notification/application/services/consumers/game-events.consumer.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { GameEventsConsumer } from './game-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('GameEventsConsumer', () => {
  let consumer: GameEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(GameEventsConsumer);
  });

  describe('handleMatchCompleted', () => {
    it('creates MATCH_COMPLETED notification for each player', async () => {
      const payload = {
        gameId: 'game-1',
        matchId: 'match-1',
        sport: 'futsal',
        winnerId: 'user-a',
        players: [
          { playerUserId: 'user-a', goals: 2, assists: 0, won: true },
          { playerUserId: 'user-b', goals: 1, assists: 1, won: false },
        ],
      };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleMatchCompleted(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(2);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-a',
          type: NotificationType.MATCH_COMPLETED,
        }),
      );
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-b',
          type: NotificationType.MATCH_COMPLETED,
        }),
      );
    });
  });

  describe('handleResultDisputed', () => {
    it('creates RESULT_DISPUTED notification for disputedByUserId', async () => {
      const payload = {
        gameId: 'game-1',
        matchId: 'match-1',
        sport: 'futsal',
        disputedByUserId: 'user-b',
      };
      mockNotifService.createNotification.mockResolvedValue(undefined);

      await consumer.handleResultDisputed(payload);

      expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
      expect(mockNotifService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-b',
          type: NotificationType.RESULT_DISPUTED,
        }),
      );
    });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/notification && npx jest --testPathPattern="game-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: FAIL

- [ ] **Step 3: Create game-events.consumer.ts**

```typescript
// services/notification/src/modules/notification/application/services/consumers/game-events.consumer.ts
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GameEvents } from '@shared/contracts/events/game-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface MatchCompletedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  winnerId: string | null;
  players: Array<{ playerUserId: string; goals: number; assists: number; won: boolean }>;
}

interface ResultDisputedPayload {
  gameId: string;
  matchId: string;
  sport: string;
  disputedByUserId: string;
}

@Injectable()
export class GameEventsConsumer {
  private readonly logger = new Logger(GameEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.MATCH_COMPLETED,
    queue: 'notification-service.game.match-completed',
    queueOptions: { durable: true },
  })
  async handleMatchCompleted(payload: MatchCompletedPayload): Promise<void> {
    const data: Record<string, unknown> = {
      gameId: payload.gameId,
      matchId: payload.matchId,
      sport: payload.sport,
    };

    for (const player of payload.players) {
      try {
        await this.notifService.createNotification({
          eventId: `${GameEvents.MATCH_COMPLETED}:${payload.gameId}:${player.playerUserId}`,
          recipientUserId: player.playerUserId,
          type: NotificationType.MATCH_COMPLETED,
          title: 'Resultado registrado',
          body: 'O resultado do seu jogo foi registrado.',
          data,
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(
          `Failed to notify player ${player.playerUserId} for match-completed ${payload.gameId}: ${message}`,
        );
      }
    }
  }

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GameEvents.RESULT_DISPUTED,
    queue: 'notification-service.game.result-disputed',
    queueOptions: { durable: true },
  })
  async handleResultDisputed(payload: ResultDisputedPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${GameEvents.RESULT_DISPUTED}:${payload.gameId}:${payload.disputedByUserId}`,
        recipientUserId: payload.disputedByUserId,
        type: NotificationType.RESULT_DISPUTED,
        title: 'Resultado contestado',
        body: 'O resultado do seu jogo foi contestado.',
        data: { gameId: payload.gameId, matchId: payload.matchId, sport: payload.sport },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify result-disputed for game ${payload.gameId}: ${message}`,
      );
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/notification && npx jest --testPathPattern="game-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: PASS — 2 tests

- [ ] **Step 5: Commit**

```bash
git add services/notification/src/modules/notification/application/services/consumers/game-events.consumer.ts \
        services/notification/src/modules/notification/application/services/consumers/game-events.consumer.spec.ts
git commit -m "feat(notification): add GameEventsConsumer — 2 passing tests"
```

---

### Task 14: GamificationEventsConsumer + tests

**Files:**
- Create: `services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.ts`
- Create: `services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.spec.ts`

**Context:** Consumes `gamification.badge-awarded`. Payload: `{ playerUserId, badgeCode, earnedAt }`. EventId: `{routingKey}:{playerUserId}:{badgeCode}` — unique per player per badge (re-earning same badge won't create duplicate).

- [ ] **Step 1: Write the failing tests**

```typescript
// services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { GamificationEventsConsumer } from './gamification-events.consumer';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

const mockNotifService = { createNotification: jest.fn() };

describe('GamificationEventsConsumer', () => {
  let consumer: GamificationEventsConsumer;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationEventsConsumer,
        { provide: NotificationService, useValue: mockNotifService },
      ],
    }).compile();
    consumer = module.get(GamificationEventsConsumer);
  });

  it('creates BADGE_AWARDED notification with badge code in body', async () => {
    const payload = {
      playerUserId: 'user-1',
      badgeCode: 'primeiro_gol',
      earnedAt: new Date(),
    };
    mockNotifService.createNotification.mockResolvedValue(undefined);

    await consumer.handleBadgeAwarded(payload);

    expect(mockNotifService.createNotification).toHaveBeenCalledTimes(1);
    expect(mockNotifService.createNotification).toHaveBeenCalledWith(
      expect.objectContaining({
        recipientUserId: 'user-1',
        type: NotificationType.BADGE_AWARDED,
        body: 'Você ganhou o badge primeiro_gol!',
      }),
    );
  });

  it('does not throw if createNotification fails', async () => {
    const payload = {
      playerUserId: 'user-1',
      badgeCode: 'badge',
      earnedAt: new Date(),
    };
    mockNotifService.createNotification.mockRejectedValue(new Error('DB down'));

    await expect(consumer.handleBadgeAwarded(payload)).resolves.not.toThrow();
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/notification && npx jest --testPathPattern="gamification-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: FAIL

- [ ] **Step 3: Create gamification-events.consumer.ts**

```typescript
// services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.ts
import { Injectable, Logger } from '@nestjs/common';
import { RabbitSubscribe } from '@golevelup/nestjs-rabbitmq';
import { GamificationEvents } from '@shared/contracts/events/gamification-events.enum';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../../domain/models/notification.entity';

interface BadgeAwardedPayload {
  playerUserId: string;
  badgeCode: string;
  earnedAt: Date;
}

@Injectable()
export class GamificationEventsConsumer {
  private readonly logger = new Logger(GamificationEventsConsumer.name);

  constructor(private readonly notifService: NotificationService) {}

  @RabbitSubscribe({
    exchange: 'bolanarededb',
    routingKey: GamificationEvents.BADGE_AWARDED,
    queue: 'notification-service.gamification.badge-awarded',
    queueOptions: { durable: true },
  })
  async handleBadgeAwarded(payload: BadgeAwardedPayload): Promise<void> {
    try {
      await this.notifService.createNotification({
        eventId: `${GamificationEvents.BADGE_AWARDED}:${payload.playerUserId}:${payload.badgeCode}`,
        recipientUserId: payload.playerUserId,
        type: NotificationType.BADGE_AWARDED,
        title: 'Nova conquista!',
        body: `Você ganhou o badge ${payload.badgeCode}!`,
        data: { badgeCode: payload.badgeCode, earnedAt: payload.earnedAt },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to notify badge-awarded for user ${payload.playerUserId}: ${message}`,
      );
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/notification && npx jest --testPathPattern="gamification-events.consumer.spec" --no-coverage 2>&1 | tail -10
```
Expected: PASS — 2 tests

- [ ] **Step 5: Run all tests**

```bash
cd services/notification && npx jest --no-coverage 2>&1 | tail -15
```
Expected: PASS — 15 tests total

- [ ] **Step 6: Commit**

```bash
git add services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.ts \
        services/notification/src/modules/notification/application/services/consumers/gamification-events.consumer.spec.ts
git commit -m "feat(notification): add GamificationEventsConsumer — 2 passing tests (15 total)"
```

---

### Task 15: NotificationResponseDto + NotificationsController

**Files:**
- Create: `services/notification/src/modules/notification/application/dto/notification-response.dto.ts`
- Create: `services/notification/src/modules/notification/infra/controllers/notifications.controller.ts`

**Context:** All endpoints require JWT authentication. The user's ID is extracted from `req.user.sub` (the `sub` claim of the JWT). `JwtAuthGuard` is imported directly from `@shared/guards/jwt-auth.guard` (not via SharedModule, but JwtService is available because `JwtModule.registerAsync({ global: true, ... })` is set up in AppModule). Pagination: `skip` and `limit` query params with safe defaults (skip ≥ 0, 1 ≤ limit ≤ 100).

- [ ] **Step 1: Create notification-response.dto.ts**

```typescript
// services/notification/src/modules/notification/application/dto/notification-response.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { NotificationType, type Notification } from '../../domain/models/notification.entity';

export class NotificationResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() recipientUserId!: string;
  @ApiProperty({ enum: NotificationType }) type!: NotificationType;
  @ApiProperty() title!: string;
  @ApiProperty() body!: string;
  @ApiProperty() data!: Record<string, unknown>;
  @ApiProperty() isRead!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(n: Notification): NotificationResponseDto {
    const dto = new NotificationResponseDto();
    dto.id = n.id;
    dto.recipientUserId = n.recipientUserId;
    dto.type = n.type;
    dto.title = n.title;
    dto.body = n.body;
    dto.data = n.data;
    dto.isRead = n.isRead;
    dto.createdAt = n.createdAt;
    return dto;
  }
}
```

- [ ] **Step 2: Create notifications.controller.ts**

```typescript
// services/notification/src/modules/notification/infra/controllers/notifications.controller.ts
import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/guards/jwt-auth.guard';
import { NotificationService } from '../../application/services/notification.service';
import { NotificationResponseDto } from '../../application/dto/notification-response.dto';

interface AuthenticatedRequest extends Express.Request {
  user: { sub: string };
}

@Controller('notifications')
@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifService: NotificationService) {}

  @Get()
  @ApiOperation({ summary: 'List my notifications (newest first, paginated)' })
  @ApiQuery({ name: 'skip', required: false, type: Number, description: 'Default 0' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Default 20, max 100' })
  async listNotifications(
    @Req() req: AuthenticatedRequest,
    @Query('skip') skip?: string,
    @Query('limit') limit?: string,
  ): Promise<NotificationResponseDto[]> {
    const parsedSkip = Math.max(0, parseInt(skip ?? '0', 10) || 0);
    const parsedLimit = Math.min(Math.max(1, parseInt(limit ?? '20', 10) || 20), 100);
    const notifications = await this.notifService.getNotifications(
      req.user.sub,
      parsedSkip,
      parsedLimit,
    );
    return notifications.map(NotificationResponseDto.from);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Count unread notifications' })
  async getUnreadCount(@Req() req: AuthenticatedRequest): Promise<{ count: number }> {
    const count = await this.notifService.getUnreadCount(req.user.sub);
    return { count };
  }

  @Patch('read')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllAsRead(@Req() req: AuthenticatedRequest): Promise<void> {
    await this.notifService.markAllAsRead(req.user.sub);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a single notification as read' })
  async markAsRead(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
  ): Promise<NotificationResponseDto> {
    const notif = await this.notifService.markAsRead(id, req.user.sub);
    return NotificationResponseDto.from(notif);
  }
}
```

- [ ] **Step 3: Verify TypeScript compilation**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1 | head -20
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add services/notification/src/modules/notification/application/dto/ \
        services/notification/src/modules/notification/infra/controllers/
git commit -m "feat(notification): add NotificationResponseDto and NotificationsController"
```

---

### Task 16: NotificationModule

**Files:**
- Create: `services/notification/src/modules/notification/notification.module.ts`

**Context:** Since SharedModule is not used, `JwtAuthGuard` and `SharedMessagingService` must be explicitly provided here. `JwtAuthGuard` depends on `JwtService` (provided globally by `JwtModule.registerAsync({ global: true })` in AppModule). `SharedMessagingService` depends on `AmqpConnection` (provided globally by `RabbitMQModule.forRootAsync(RabbitMQModule, ...)` in AppModule).

- [ ] **Step 1: Create notification.module.ts**

```typescript
// services/notification/src/modules/notification/notification.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtAuthGuard } from '@shared/guards/jwt-auth.guard';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';

import { NotificationDoc, NotificationSchema } from './infra/schemas/notification.schema';
import { DeviceTokenDoc, DeviceTokenSchema } from './infra/schemas/device-token.schema';

import { NOTIFICATION_REPOSITORY } from './domain/repositories/notification-repository.interface';
import { DEVICE_TOKEN_REPOSITORY } from './domain/repositories/device-token-repository.interface';

import { MongooseNotificationRepository } from './infra/database/repositories/mongoose-notification.repository';
import { MongooseDeviceTokenRepository } from './infra/database/repositories/mongoose-device-token.repository';
import { redisProvider } from './infra/redis/redis.provider';
import { PushNotificationService } from './infra/push/push-notification.service';

import { NotificationService } from './application/services/notification.service';
import { DeviceTokenService } from './application/services/device-token.service';
import { IdentityEventsConsumer } from './application/services/consumers/identity-events.consumer';
import { MatchmakingEventsConsumer } from './application/services/consumers/matchmaking-events.consumer';
import { GameEventsConsumer } from './application/services/consumers/game-events.consumer';
import { GamificationEventsConsumer } from './application/services/consumers/gamification-events.consumer';

import { NotificationsController } from './infra/controllers/notifications.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NotificationDoc.name, schema: NotificationSchema },
      { name: DeviceTokenDoc.name, schema: DeviceTokenSchema },
    ]),
  ],
  controllers: [NotificationsController],
  providers: [
    { provide: NOTIFICATION_REPOSITORY, useClass: MongooseNotificationRepository },
    { provide: DEVICE_TOKEN_REPOSITORY, useClass: MongooseDeviceTokenRepository },
    redisProvider,
    PushNotificationService,
    SharedMessagingService,
    JwtAuthGuard,
    NotificationService,
    DeviceTokenService,
    IdentityEventsConsumer,
    MatchmakingEventsConsumer,
    GameEventsConsumer,
    GamificationEventsConsumer,
  ],
})
export class NotificationModule {}
```

- [ ] **Step 2: Verify TypeScript build — full service**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1
```
Expected: 0 errors

- [ ] **Step 3: Run all tests**

```bash
cd services/notification && npx jest --no-coverage 2>&1 | tail -15
```
Expected: PASS — 15 tests total (6 notification.service + 3 device-token.service + 2 matchmaking + 2 game + 2 gamification)

- [ ] **Step 4: Commit**

```bash
git add services/notification/src/modules/notification/notification.module.ts
git commit -m "feat(notification): wire NotificationModule — all providers, consumers, repositories"
```

---

### Task 17: Dockerfile + docker-entrypoint.sh + scripts/setup-indexes.js

**Files:**
- Create: `services/notification/Dockerfile`
- Create: `services/notification/docker-entrypoint.sh`
- Create: `services/notification/scripts/setup-indexes.js`

**Context:** MongoDB is schemaless — no SQL migrations. `setup-indexes.js` creates MongoDB indexes programmatically using the native `mongodb` driver (available as a transitive dependency of `mongoose`). The Dockerfile follows the same multi-stage pattern as all other services in the monorepo.

- [ ] **Step 1: Create Dockerfile**

```dockerfile
# services/notification/Dockerfile
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/notification/ ./services/notification/

RUN npm ci --legacy-peer-deps
RUN npm run build --workspace=services/notification

# ── runner ────────────────────────────────────────────────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app

COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/services/notification/scripts ./services/notification/scripts
COPY --from=builder /app/services/notification/docker-entrypoint.sh ./services/notification/

RUN chmod +x /app/services/notification/docker-entrypoint.sh

EXPOSE 4010

ENTRYPOINT ["/app/services/notification/docker-entrypoint.sh"]
```

- [ ] **Step 2: Create docker-entrypoint.sh**

```sh
#!/bin/sh
set -e
echo "Setting up MongoDB indexes..."
node /app/services/notification/scripts/setup-indexes.js
echo "Starting notification service..."
exec node /app/dist/services/notification/src/main
```

- [ ] **Step 3: Create scripts/setup-indexes.js**

```javascript
// services/notification/scripts/setup-indexes.js
'use strict';

const { MongoClient } = require('mongodb');

const url = process.env.MONGODB_URL;
if (!url) {
  console.error('MONGODB_URL is not set');
  process.exit(1);
}

async function setupIndexes() {
  const client = new MongoClient(url);
  await client.connect();

  const dbName = new URL(url).pathname.slice(1); // extract db name from URL path
  const db = client.db(dbName || 'bolanarededb_notification');

  await db.collection('notifications').createIndex(
    { recipientUserId: 1, createdAt: -1 },
    { background: true },
  );
  await db.collection('notifications').createIndex(
    { recipientUserId: 1, isRead: 1 },
    { background: true },
  );
  await db.collection('device_tokens').createIndex(
    { userId: 1 },
    { unique: true, background: true },
  );

  console.log('MongoDB indexes created successfully');
  await client.close();
}

setupIndexes().catch((err) => {
  console.error('Failed to set up indexes:', err);
  process.exit(1);
});
```

- [ ] **Step 4: Commit**

```bash
git add services/notification/Dockerfile \
        services/notification/docker-entrypoint.sh \
        services/notification/scripts/setup-indexes.js
git commit -m "feat(notification): add Dockerfile, docker-entrypoint.sh, setup-indexes.js"
```

---

### Task 18: docker-compose.yml update

**Files:**
- Modify: `docker-compose.yml`

**Context:** Add a MongoDB service (`mongo:7.0`) and the `notification` service. MongoDB internal port is 27017. The notification service uses the existing `redis` service. The `mongodb` healthcheck uses `mongosh --eval "db.adminCommand('ping')"`.

- [ ] **Step 1: Add mongodb service**

In `docker-compose.yml`, add the following block in the Infrastructure section (after `postgres-ranking`, before the `# ── Services` comment or after existing infrastructure):

```yaml
  mongodb:
    image: mongo:7.0
    restart: unless-stopped
    environment:
      MONGO_INITDB_DATABASE: bolanarededb_notification
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 10s
      retries: 10
```

- [ ] **Step 2: Add notification service**

Add after the `ranking:` service block:

```yaml
  notification:
    build:
      context: .
      dockerfile: services/notification/Dockerfile
    restart: unless-stopped
    environment:
      PORT: 4010
      JWT_SECRET: bolanarededb-secret
      MONGODB_URL: mongodb://mongodb:27017/bolanarededb_notification
      RABBITMQ_URL: amqp://admin:admin@rabbitmq:5672
      REDIS_URL: redis://redis:6379
    ports:
      - "4010:4010"
    depends_on:
      mongodb:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      redis:
        condition: service_healthy
```

- [ ] **Step 3: Add mongodb_data volume**

In the `volumes:` section at the bottom of `docker-compose.yml`, add:

```yaml
  mongodb_data:
```

- [ ] **Step 4: Validate docker-compose syntax**

```bash
docker compose config --quiet 2>&1 | head -5
```
Expected: no output (valid) or no errors

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(notification): add mongodb + notification service to docker-compose"
```

---

### Task 19: .env.example

**Files:**
- Create: `services/notification/.env.example`

- [ ] **Step 1: Create .env.example**

```
# services/notification/.env.example
PORT=4010
JWT_SECRET=bolanarededb-secret
MONGODB_URL=mongodb://localhost:27017/bolanarededb_notification
RABBITMQ_URL=amqp://admin:admin@localhost:5672
REDIS_URL=redis://localhost:6379
```

- [ ] **Step 2: Run all tests one final time**

```bash
cd services/notification && npx jest --no-coverage 2>&1 | tail -15
```
Expected: PASS — 15 tests

- [ ] **Step 3: Full TypeScript build — 0 errors**

```bash
npx tsc -p services/notification/tsconfig.json --noEmit 2>&1
```
Expected: no output (0 errors)

- [ ] **Step 4: Commit**

```bash
git add services/notification/.env.example
git commit -m "chore(notification): add .env.example"
```

---

### Task 20: docs/plans/_status.md update

**Files:**
- Modify: `docs/plans/_status.md`

- [ ] **Step 1: Update _status.md**

Replace the current contents with:

```markdown
# BolaNaRede — Status de Desenvolvimento
Última atualização: 2026-06-08 (notification service DONE)

| Serviço      | Status      | Concluídas | Próxima task pendente        |
|--------------|-------------|------------|------------------------------|
| shared       | ✅ DONE     | 29/29      | —                            |
| identity     | ✅ DONE     | 37/37      | —                            |
| team         | ✅ DONE     | 29/29      | —                            |
| field        | ✅ DONE     | 34/34      | —                            |
| open-game    | ✅ DONE     | 29/29      | —                            |
| social       | ✅ DONE     | 23/23      | —                            |
| gamification | ✅ DONE     | 23/23      | —                            |
| matchmaking  | ✅ DONE     | 24/24      | —                            |
| game         | ✅ DONE     | 20/20      | —                            |
| ranking      | ✅ DONE     | 20/20      | —                            |
| notification | ✅ DONE     | 20/20      | —                            |

## Planos

- `docs/plans/2026-05-26-shared-module.md` — 29 tasks
- `docs/plans/2026-05-26-identity-service.md` — 37 tasks
- `docs/plans/2026-05-27-team-service.md` — 29 tasks
- `docs/plans/2026-06-01-field-service.md` — 34 tasks
- `docs/plans/2026-06-02-open-game-service.md` — 29 tasks
- `docs/plans/2026-06-03-social-service.md` — 23 tasks
- `docs/plans/2026-06-03-gamification-service.md` — 23 tasks
- `docs/plans/2026-06-07-matchmaking-service.md` — 24 tasks
- `docs/plans/2026-06-07-game-service.md` — 20 tasks
- `docs/plans/2026-06-08-ranking-service.md` — 20 tasks
- `docs/plans/2026-06-08-notification-service.md` — 20 tasks
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/_status.md
git commit -m "docs(notification): update _status.md — notification service DONE (20/20)"
```
