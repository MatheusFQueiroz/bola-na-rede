import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { FieldService } from './application/services/field.service';
import { AvailabilityService } from './application/services/availability.service';
import { FieldMessagingService } from './application/services/field-messaging.service';
import { DrizzleFieldRepository } from './infra/database/repositories/drizzle-field.repository';
import { FieldsController } from './infra/controllers/fields.controller';
import { FIELD_REPOSITORY } from './domain/repositories/field-repository.interface';
import { DrizzleReservationRepository } from '../reservations/infra/database/repositories/drizzle-reservation.repository';
import { RESERVATION_REPOSITORY } from '../reservations/domain/repositories/reservation-repository.interface';
import { DrizzleRecurringPlanRepository } from '../plans/infra/database/repositories/drizzle-recurring-plan.repository';
import { RECURRING_PLAN_REPOSITORY } from '../plans/domain/repositories/recurring-plan-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [FieldsController],
  providers: [
    FieldService,
    AvailabilityService,
    FieldMessagingService,
    { provide: FIELD_REPOSITORY, useClass: DrizzleFieldRepository },
    { provide: RESERVATION_REPOSITORY, useClass: DrizzleReservationRepository },
    { provide: RECURRING_PLAN_REPOSITORY, useClass: DrizzleRecurringPlanRepository },
  ],
  exports: [FIELD_REPOSITORY, RESERVATION_REPOSITORY, RECURRING_PLAN_REPOSITORY, FieldMessagingService],
})
export class FieldsModule {}
