import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY, type ReservationRepositoryInterface } from '../../../reservations/domain/repositories/reservation-repository.interface';
import { RECURRING_PLAN_REPOSITORY, type RecurringPlanRepositoryInterface } from '../../../plans/domain/repositories/recurring-plan-repository.interface';
import { FieldAvailabilityDto, CourtAvailabilityDto, TimeSlotDto } from '../dto/field-availability.dto';

@Injectable()
export class AvailabilityService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RESERVATION_REPOSITORY) private readonly reservationRepo: ReservationRepositoryInterface,
    @Inject(RECURRING_PLAN_REPOSITORY) private readonly planRepo: RecurringPlanRepositoryInterface,
  ) {}

  async getAvailability(fieldExternalId: string, dateStr: string): Promise<FieldAvailabilityDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);

    const date = new Date(dateStr);
    const dayOfWeek = date.getUTCDay(); // 0=Sun, 6=Sat (date-only strings parse as UTC midnight)

    const courts = await this.fieldRepo.findCourts(fieldExternalId);
    const activeSlotsByField = await this.planRepo.findActiveSlotsByField(fieldExternalId, date);

    const courtAvailabilities: CourtAvailabilityDto[] = [];

    for (const court of courts) {
      const slots = await this.fieldRepo.getAvailabilitySlots(court.id);
      const daySlots = slots.filter((s) => s.dayOfWeek === dayOfWeek && s.isAvailable);

      const slotDtos: TimeSlotDto[] = [];
      for (const slot of daySlots) {
        const slotStart = new Date(`${dateStr}T${slot.startTime}:00Z`);
        const slotEnd = new Date(`${dateStr}T${slot.endTime}:00Z`);

        const overlapping = await this.reservationRepo.findOverlapping(
          court.id,
          slotStart,
          slotEnd,
        );

        const isBlockedByPlan = activeSlotsByField.some((planSlot) => {
          const ps = new Date(planSlot.slotDate);
          return ps >= slotStart && ps < slotEnd;
        });

        const timeSlot = new TimeSlotDto();
        timeSlot.startTime = slot.startTime;
        timeSlot.endTime = slot.endTime;
        timeSlot.isAvailable = overlapping.length === 0 && !isBlockedByPlan;
        slotDtos.push(timeSlot);
      }

      const courtDto = new CourtAvailabilityDto();
      courtDto.courtId = court.id;
      courtDto.courtName = court.name;
      courtDto.slots = slotDtos;
      courtAvailabilities.push(courtDto);
    }

    const result = new FieldAvailabilityDto();
    result.fieldId = fieldExternalId;
    result.date = dateStr;
    result.courts = courtAvailabilities;
    return result;
  }
}
