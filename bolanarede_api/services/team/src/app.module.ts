import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TeamModule } from './modules/team/team.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TeamModule,
  ],
})
export class AppModule {}
