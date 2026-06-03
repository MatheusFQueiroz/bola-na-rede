import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FieldModule } from './modules/field/field.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    FieldModule,
  ],
})
export class AppModule {}
