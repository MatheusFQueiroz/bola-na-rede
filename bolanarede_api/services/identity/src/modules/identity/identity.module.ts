import { Module } from '@nestjs/common';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { DeviceTokensModule } from './device-tokens/device-tokens.module';

@Module({
  imports: [UsersModule, AuthModule, DeviceTokensModule],
})
export class IdentityModule {}
