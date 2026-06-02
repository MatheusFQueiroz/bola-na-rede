import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { ReservationService } from './application/services/reservation.service';
import { DrizzleReservationRepository } from './infra/database/repositories/drizzle-reservation.repository';
import { ReservationsController } from './infra/controllers/reservations.controller';
import { RESERVATION_REPOSITORY } from './domain/repositories/reservation-repository.interface';
import { FieldsModule } from '../fields/fields.module';

@Module({
  imports: [SharedModule, FieldsModule],
  controllers: [ReservationsController],
  providers: [
    ReservationService,
    { provide: RESERVATION_REPOSITORY, useClass: DrizzleReservationRepository },
  ],
  exports: [RESERVATION_REPOSITORY],
})
export class ReservationsModule {}
