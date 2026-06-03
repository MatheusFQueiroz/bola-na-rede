import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, gte, lte } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateReservationData,
  ReservationRepositoryInterface,
} from '../../../domain/repositories/reservation-repository.interface';
import type { Reservation, ReservationChannel, ReservationStatus } from '../../../domain/models/reservation.entity';
import { reservations, type ReservationRow } from '../schemas/reservation.schema';
import { fieldCourts } from '../../../../fields/infra/database/schemas/field-court.schema';
import { fields } from '../../../../fields/infra/database/schemas/field.schema';

@Injectable()
export class DrizzleReservationRepository implements ReservationRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateReservationData): Promise<Reservation> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id, fieldId: fieldCourts.fieldId })
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
      .insert(reservations)
      .values({
        courtId: court.id,
        fieldId: field.id,
        playerUserId: data.playerUserId ?? null,
        channel: data.channel,
        startsAt: data.startsAt,
        endsAt: data.endsAt,
        notes: data.notes ?? null,
        status: 'confirmed',
      })
      .returning();

    return this.toReservation(row, data.courtExternalId, data.fieldExternalId);
  }

  async findById(externalId: string): Promise<Reservation | null> {
    const [row] = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(eq(reservations.externalId, externalId))
      .limit(1);
    return row ? this.toReservation(row.res, row.courtExtId, row.fieldExtId) : null;
  }

  async findByField(fieldExternalId: string, page: number, limit: number): Promise<Reservation[]> {
    const [field] = await this.drizzle.db
      .select({ id: fields.id })
      .from(fields)
      .where(eq(fields.externalId, fieldExternalId))
      .limit(1);
    if (!field) return [];

    const rows = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(and(eq(reservations.fieldId, field.id), eq(reservations.status, 'confirmed')))
      .orderBy(reservations.startsAt)
      .limit(limit)
      .offset((page - 1) * limit);

    return rows.map((r) => this.toReservation(r.res, r.courtExtId, r.fieldExtId));
  }

  async findOverlapping(courtExternalId: string, startsAt: Date, endsAt: Date): Promise<Reservation[]> {
    const [court] = await this.drizzle.db
      .select({ id: fieldCourts.id })
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);
    if (!court) return [];

    // Overlapping: existing.startsAt < newEndsAt AND existing.endsAt > newStartsAt
    const rows = await this.drizzle.db
      .select({
        res: reservations,
        courtExtId: fieldCourts.externalId,
        fieldExtId: fields.externalId,
      })
      .from(reservations)
      .innerJoin(fieldCourts, eq(reservations.courtId, fieldCourts.id))
      .innerJoin(fields, eq(reservations.fieldId, fields.id))
      .where(
        and(
          eq(reservations.courtId, court.id),
          eq(reservations.status, 'confirmed'),
          lte(reservations.startsAt, endsAt),
          gte(reservations.endsAt, startsAt),
        ),
      );

    return rows.map((r) => this.toReservation(r.res, r.courtExtId, r.fieldExtId));
  }

  async cancel(externalId: string): Promise<Reservation> {
    const existing = await this.findById(externalId);
    if (!existing) throw new NotFoundException(`Reservation ${externalId} not found`);

    await this.drizzle.db
      .update(reservations)
      .set({ status: 'cancelled' })
      .where(eq(reservations.externalId, externalId));

    return { ...existing, status: 'cancelled' };
  }

  private toReservation(row: ReservationRow, courtExternalId: string, fieldExternalId: string): Reservation {
    return {
      id: row.externalId,
      courtId: courtExternalId,
      fieldId: fieldExternalId,
      playerUserId: row.playerUserId,
      channel: row.channel as ReservationChannel,
      startsAt: row.startsAt,
      endsAt: row.endsAt,
      status: row.status as ReservationStatus,
      notes: row.notes,
      createdAt: row.createdAt,
    };
  }
}
