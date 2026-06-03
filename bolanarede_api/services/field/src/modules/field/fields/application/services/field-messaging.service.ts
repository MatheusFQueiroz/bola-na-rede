import { Injectable } from '@nestjs/common';
import { SharedMessagingService } from '@shared/infra/messaging/shared-messaging.service';
import { FieldEvents } from '@shared/contracts/events/field-events.enum';
import type { Field } from '../../domain/models/field.entity';
import type { Reservation } from '../../../reservations/domain/models/reservation.entity';
import type { RecurringPlanSlot } from '../../../plans/domain/models/recurring-plan-slot.entity';

@Injectable()
export class FieldMessagingService {
  constructor(private readonly messaging: SharedMessagingService) {}

  async publishFieldRegistered(field: Field): Promise<void> {
    await this.messaging.publish(FieldEvents.REGISTERED, {
      fieldId: field.id,
      name: field.name,
      city: field.city,
      location: { lat: field.lat, lng: field.lng },
    });
  }

  async publishReservationConfirmed(reservation: Reservation): Promise<void> {
    await this.messaging.publish(FieldEvents.RESERVATION_CONFIRMED, {
      reservationId: reservation.id,
      fieldId: reservation.fieldId,
      courtId: reservation.courtId,
      startsAt: reservation.startsAt.toISOString(),
      endsAt: reservation.endsAt.toISOString(),
      channel: reservation.channel,
    });
  }

  async publishReservationCancelled(reservation: Reservation): Promise<void> {
    await this.messaging.publish(FieldEvents.RESERVATION_CANCELLED, {
      reservationId: reservation.id,
      fieldId: reservation.fieldId,
    });
  }

  async publishPlanSlotReleased(slot: RecurringPlanSlot): Promise<void> {
    await this.messaging.publish(FieldEvents.PLAN_SLOT_RELEASED, {
      planId: slot.planId,
      slotId: slot.id,
      slotDate: slot.slotDate.toISOString(),
      fieldId: slot.fieldId,
    });
  }
}
