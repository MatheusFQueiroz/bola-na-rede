import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, gte, lte } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateRecurringPlanData,
  RecurringPlanRepositoryInterface,
} from '../../domain/repositories/recurring-plan-repository.interface';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';
import type { RecurringPlanSlot, SlotStatus } from '../../domain/models/recurring-plan-slot.entity';
import { recurringPlans, type RecurringPlanRow } from '../schemas/recurring-plan.schema';
import { recurringPlanSlots, type RecurringPlanSlotRow } from '../schemas/recurring-plan-slot.schema';
import { fieldCourts } from '../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../fields/infra/database/schemas/field.schema';

@Injectable()
export class DrizzleRecurringPlanRepository implements RecurringPlanRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateRecurringPlanData): Promise<RecurringPlan> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id })
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, data.courtExternalId))
      .limit(1);
    if (!court) throw new NotFoundException(`Court ${data.courtExternalId} not found`);

    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, data.fieldExternalId))
      .limit(1);
    if (!field) throw new NotFoundException(`Field ${data.fieldExternalId} not found`);

    const [row] = await this.drizzle.db
      .insert(recurringPlans)
      .values({
        courtId: court.id,
        fieldId: field.id,
        playerUserId: data.playerUserId ?? null,
        dayOfWeek: data.dayOfWeek,
        startTime: data.startTime,
        endTime: data.endTime,
        planStartsAt: data.planStartsAt,
        planEndsAt: data.planEndsAt ?? null,
      })
      .returning();

    return this.toPlan(row, data.courtExternalId, data.fieldExternalId);
  }

  async findById(externalId: string): Promise<RecurringPlan | null> {
    const [row] = await this.drizzle.db
      .select({
        plan: recurringPlans,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlans)
      .innerJoin(fieldCourts, eq(recurringPlans.courtId, fieldCourts.id))
      .innerJoin(fields, eq(recurringPlans.fieldId, fields.id))
      .where(eq(recurringPlans.externalId, externalId))
      .limit(1);
    return row ? this.toPlan(row.plan, row.courtExtId, row.fieldExtId) : null;
  }

  async findByField(fieldExternalId: string): Promise<RecurringPlan[]> {
    const rows = await this.drizzle.db
      .select({
        plan: recurringPlans,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlans)
      .innerJoin(fieldCourts, eq(recurringPlans.courtId, fieldCourts.id))
      .innerJoin(fields, eq(recurringPlans.fieldId, fields.id))
      .where(and(eq(fields.externalId, fieldExternalId), eq(recurringPlans.isActive, true)));
    return rows.map((r) => this.toPlan(r.plan, r.courtExtId, r.fieldExtId));
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(recurringPlans)
      .set({ isActive: false })
      .where(eq(recurringPlans.externalId, externalId));
  }

  async createSlot(planExternalId: string, slotDate: Date): Promise<RecurringPlanSlot> {
    const [plan] = await this.drizzle.db
      .select({ id: recurringPlans.id, fieldId: recurringPlans.fieldId })
      .from(recurringPlans)
      .where(eq(recurringPlans.externalId, planExternalId))
      .limit(1);
    if (!plan) throw new NotFoundException(`Plan ${planExternalId} not found`);

    const [row] = await this.drizzle.db
      .insert(recurringPlanSlots)
      .values({ planId: plan.id, fieldId: plan.fieldId, slotDate, status: 'active' })
      .returning();

    const [fieldRow] = await this.drizzle.db
      .select({ externalId: fields.externalId })
      .from(fields)
      .where(eq(fields.id, plan.fieldId))
      .limit(1);

    if (!fieldRow) throw new NotFoundException(`Field for plan ${planExternalId} not found`);

    return this.toSlot(row, planExternalId, fieldRow.externalId);
  }

  async findSlot(slotExternalId: string): Promise<RecurringPlanSlot | null> {
    const [row] = await this.drizzle.db
      .select({
        slot: recurringPlanSlots,
        planExtId: recurringPlans.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlanSlots)
      .innerJoin(recurringPlans, eq(recurringPlanSlots.planId, recurringPlans.id))
      .innerJoin(fields, eq(recurringPlanSlots.fieldId, fields.id))
      .where(eq(recurringPlanSlots.externalId, slotExternalId))
      .limit(1);
    return row ? this.toSlot(row.slot, row.planExtId, row.fieldExtId) : null;
  }

  async releaseSlot(slotExternalId: string): Promise<RecurringPlanSlot> {
    const existing = await this.findSlot(slotExternalId);
    if (!existing) throw new NotFoundException(`Slot ${slotExternalId} not found`);

    await this.drizzle.db
      .update(recurringPlanSlots)
      .set({ status: 'released' })
      .where(eq(recurringPlanSlots.externalId, slotExternalId));

    return { ...existing, status: 'released' };
  }

  async findActiveSlotsByField(fieldExternalId: string, date: Date): Promise<RecurringPlanSlot[]> {
    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, fieldExternalId))
      .limit(1);
    if (!field) return [];

    const dayStart = new Date(date);
    dayStart.setUTCHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setUTCHours(23, 59, 59, 999);

    const rows = await this.drizzle.db
      .select({
        slot: recurringPlanSlots,
        planExtId: recurringPlans.externalId,
        fieldExtId: fields.externalId,
      })
      .from(recurringPlanSlots)
      .innerJoin(recurringPlans, eq(recurringPlanSlots.planId, recurringPlans.id))
      .innerJoin(fields, eq(recurringPlanSlots.fieldId, fields.id))
      .where(
        and(
          eq(recurringPlanSlots.fieldId, field.id),
          eq(recurringPlanSlots.status, 'active'),
          gte(recurringPlanSlots.slotDate, dayStart),
          lte(recurringPlanSlots.slotDate, dayEnd),
        ),
      );

    return rows.map((r) => this.toSlot(r.slot, r.planExtId, r.fieldExtId));
  }

  private toPlan(row: RecurringPlanRow, courtExternalId: string, fieldExternalId: string): RecurringPlan {
    return {
      id: row.externalId,
      courtId: courtExternalId,
      fieldId: fieldExternalId,
      playerUserId: row.playerUserId,
      dayOfWeek: row.dayOfWeek,
      startTime: row.startTime,
      endTime: row.endTime,
      planStartsAt: row.planStartsAt,
      planEndsAt: row.planEndsAt,
      isActive: row.isActive,
      createdAt: row.createdAt,
    };
  }

  private toSlot(row: RecurringPlanSlotRow, planExternalId: string, fieldExternalId: string): RecurringPlanSlot {
    return {
      id: row.externalId,
      planId: planExternalId,
      fieldId: fieldExternalId,
      slotDate: row.slotDate,
      status: row.status as SlotStatus,
    };
  }
}
