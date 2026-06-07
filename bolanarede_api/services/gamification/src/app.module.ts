import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GamificationModule } from './modules/gamification/gamification.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    GamificationModule,
  ],
})
export class AppModule {}
