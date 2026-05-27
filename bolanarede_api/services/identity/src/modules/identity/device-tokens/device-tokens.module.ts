import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { UsersModule } from '../users/users.module';
import { DeviceTokenService } from './application/services/device-token.service';
import { DrizzleDeviceTokenRepository } from './infra/repositories/drizzle-device-token.repository';
import { DEVICE_TOKEN_REPOSITORY } from './domain/repositories/device-token-repository.interface';

@Module({
  imports: [SharedModule, UsersModule],
  providers: [
    DeviceTokenService,
    { provide: DEVICE_TOKEN_REPOSITORY, useClass: DrizzleDeviceTokenRepository },
  ],
  exports: [DeviceTokenService],
})
export class DeviceTokensModule {}
