import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UsersModule } from '../users/users.module';
import { AuthService } from './application/services/auth.service';
import { AuthController } from './infra/controllers/auth.controller';

@Module({
  imports: [SharedModule, UsersModule],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
