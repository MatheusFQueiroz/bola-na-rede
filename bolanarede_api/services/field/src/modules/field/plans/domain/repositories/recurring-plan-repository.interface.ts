import type { RecurringPlan } from '../models/recurring-plan.entity';
import type { RecurringPlanSlot } from '../models/recurring-plan-slot.entity';

export const RECURRING_PLAN_REPOSITORY = Symbol('RECURRING_PLAN_REPOSITORY');

export interface CreateRecurringPlanData {
  courtExternalId: string;
  fieldExternalId: string;
  playerUserId?: string;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  planStartsAt: Date;
  planEndsAt?: Date;
}

export interface RecurringPlanRepositoryInterface {
  create(data: CreateRecurringPlanData): Promise<RecurringPlan>;
  findById(externalId: string): Promise<RecurringPlan | null>;
  findByField(fieldExternalId: string): Promise<RecurringPlan[]>;
  deactivate(externalId: string): Promise<void>;
  createSlot(planExternalId: string, slotDate: Date): Promise<RecurringPlanSlot>;
  findSlot(slotExternalId: string): Promise<RecurringPlanSlot | null>;
  releaseSlot(slotExternalId: string): Promise<RecurringPlanSlot>;
  findActiveSlotsByField(fieldExternalId: string, date: Date): Promise<RecurringPlanSlot[]>;
}
