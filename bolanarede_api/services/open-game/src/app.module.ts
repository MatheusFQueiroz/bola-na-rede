import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OpenGameModule } from './modules/open-game/open-game.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    OpenGameModule,
  ],
})
export class AppModule {}
