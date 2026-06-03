import { Module } from '@nestjs/common';
import { SharedModule } from '@shared/shared.module';
import { FieldService } from './application/services/field.service';
import { AvailabilityService } from './application/services/availability.service';
import { FieldMessagingService } from './application/services/field-messaging.service';
import { DrizzleFieldRepository } from './infra/database/repositories/drizzle-field.repository';
import { FieldsController } from './infra/controllers/fields.controller';
import { FIELD_REPOSITORY } from './domain/repositories/field-repository.interface';

@Module({
  imports: [SharedModule],
  controllers: [FieldsController],
  providers: [
    FieldService,
    AvailabilityService,
    FieldMessagingService,
    { provide: FIELD_REPOSITORY, useClass: DrizzleFieldRepository },
  ],
  exports: [FIELD_REPOSITORY, FieldMessagingService],
})
export class FieldsModule {}
