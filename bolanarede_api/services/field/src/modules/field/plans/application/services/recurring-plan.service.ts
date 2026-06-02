import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../../fields/domain/repositories/field-repository.interface';
import { RECURRING_PLAN_REPOSITORY, type RecurringPlanRepositoryInterface } from '../../domain/repositories/recurring-plan-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import { CreateRecurringPlanDto } from '../dto/create-recurring-plan.dto';
import { RecurringPlanDto } from '../dto/recurring-plan.dto';

@Injectable()
export class RecurringPlanService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RECURRING_PLAN_REPOSITORY) private readonly planRepo: RecurringPlanRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async create(ownerUserId: string, fieldExternalId: string, dto: CreateRecurringPlanDto): Promise<RecurringPlanDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can create plans');

    const plan = await this.planRepo.create({
      courtExternalId: dto.courtId,
      fieldExternalId,
      playerUserId: dto.playerUserId,
      dayOfWeek: dto.dayOfWeek,
      startTime: dto.startTime,
      endTime: dto.endTime,
      planStartsAt: new Date(dto.planStartsAt),
      planEndsAt: dto.planEndsAt ? new Date(dto.planEndsAt) : undefined,
    });

    return RecurringPlanDto.from(plan);
  }

  async releaseSlot(ownerUserId: string, fieldExternalId: string, slotExternalId: string): Promise<{ id: string; status: string }> {
    const slot = await this.planRepo.findSlot(slotExternalId);
    if (!slot) throw new NotFoundException(`Slot ${slotExternalId} not found`);
    if (slot.fieldId !== fieldExternalId) throw new ForbiddenException('Slot does not belong to this field');

    const released = await this.planRepo.releaseSlot(slotExternalId);

    try {
      await this.messaging.publishPlanSlotReleased(released);
    } catch {
      // advisory
    }

    return { id: released.id, status: released.status };
  }

  async getByField(fieldExternalId: string): Promise<RecurringPlanDto[]> {
    const plans = await this.planRepo.findByField(fieldExternalId);
    return plans.map((p) => RecurringPlanDto.from(p));
  }
}
