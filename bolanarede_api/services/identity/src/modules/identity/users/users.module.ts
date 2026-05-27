import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UserService } from './application/services/user.service';
import { UserMessagingService } from './application/services/user-messaging.service';
import { UsersController } from './infra/controllers/users.controller';
import { DrizzleUserRepository } from './infra/repositories/drizzle-user.repository';
import { USER_REPOSITORY } from './domain/repositories/user-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [UsersController],
  providers: [
    UserService,
    UserMessagingService,
    { provide: USER_REPOSITORY, useClass: DrizzleUserRepository },
  ],
  exports: [UserService, UserMessagingService],
})
export class UsersModule {}
