import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SocialModule } from './modules/social/social.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SocialModule,
  ],
})
export class AppModule {}
