import { Module } from '@nestjs/common';
import { FieldsModule } from './fields/fields.module';
import { ReservationsModule } from './reservations/reservations.module';
import { PlansModule } from './plans/plans.module';

@Module({
  imports: [FieldsModule, ReservationsModule, PlansModule],
})
export class FieldModule {}
