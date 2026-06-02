import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { RecurringPlanService } from './application/services/recurring-plan.service';
import { DrizzleRecurringPlanRepository } from './infra/database/repositories/drizzle-recurring-plan.repository';
import { PlansController } from './infra/controllers/plans.controller';
import { RECURRING_PLAN_REPOSITORY } from './domain/repositories/recurring-plan-repository.interface';
import { FieldsModule } from '../fields/fields.module';

@Module({
  imports: [SharedModule, FieldsModule],
  controllers: [PlansController],
  providers: [
    RecurringPlanService,
    { provide: RECURRING_PLAN_REPOSITORY, useClass: DrizzleRecurringPlanRepository },
  ],
  exports: [RECURRING_PLAN_REPOSITORY],
})
export class PlansModule {}
