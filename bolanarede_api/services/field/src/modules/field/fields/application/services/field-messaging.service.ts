import { Injectable } from '@nestjs/common';
import type { Field } from '../../domain/models/field.entity';
import type { Reservation } from '../../../reservations/domain/models/reservation.entity';
import type { RecurringPlanSlot } from '../../../plans/domain/models/recurring-plan-slot.entity';

@Injectable()
export class FieldMessagingService {
  async publishFieldRegistered(_field: Field): Promise<void> {}
  async publishReservationConfirmed(_reservation: Reservation): Promise<void> {}
  async publishReservationCancelled(_reservation: Reservation): Promise<void> {}
  async publishPlanSlotReleased(_slot: RecurringPlanSlot): Promise<void> {}
}
