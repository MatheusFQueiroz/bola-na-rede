import { Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateFieldData,
  CreateCourtData,
  AvailabilitySlotData,
  SearchFieldsParams,
  FieldRepositoryInterface,
} from '../../../domain/repositories/field-repository.interface';
import type { Field } from '../../../domain/models/field.entity';
import type { FieldCourt, CourtType } from '../../../domain/models/field-court.entity';
import type { AvailabilitySlot } from '../../../domain/models/availability-slot.entity';
import { fields, type FieldRow } from '../schemas/field.schema';
import { fieldCourts, type FieldCourtRow } from '../schemas/field-court.schema';
import { availabilitySlots, type AvailabilitySlotRow } from '../schemas/availability-slot.schema';

@Injectable()
export class DrizzleFieldRepository implements FieldRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateFieldData): Promise<Field> {
    const [row] = await this.drizzle.db
      .insert(fields)
      .values({
        name: data.name,
        description: data.description ?? null,
        city: data.city,
        address: data.address,
        lat: data.lat,
        lng: data.lng,
        ownerUserId: data.ownerUserId,
      })
      .returning();

    // Atualiza a coluna geometry (adicionada manualmente na migration)
    await this.drizzle.db.execute(sql`
      UPDATE fields
      SET location = ST_SetSRID(ST_MakePoint(${data.lng}, ${data.lat}), 4326)
      WHERE id = ${row.id}
    `);

    return this.toField(row);
  }

  async findById(externalId: string): Promise<Field | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(fields)
      .where(eq(fields.externalId, externalId))
      .limit(1);
    return row ? this.toField(row) : null;
  }

  async findNearby(params: SearchFieldsParams): Promise<Field[]> {
    const { city, lat, lng, radiusKm } = params;
    const hasGeo = lat != null && lng != null && radiusKm != null;

    const rows = await this.drizzle.db
      .select()
      .from(fields)
      .where(
        and(
          eq(fields.isActive, true),
          city ? eq(fields.city, city) : undefined,
          hasGeo
            ? sql`ST_DWithin(
                location::geography,
                ST_SetSRID(ST_MakePoint(${lng!}, ${lat!}), 4326)::geography,
                ${radiusKm! * 1000}
              )`
            : undefined,
        ),
      )
      .orderBy(
        hasGeo
          ? sql`ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(${lng!}, ${lat!}), 4326)::geography)`
          : fields.createdAt,
      )
      .limit(50);

    return rows.map((r) => this.toField(r));
  }

  async findByOwner(ownerUserId: string): Promise<Field[]> {
    const rows = await this.drizzle.db
      .select()
      .from(fields)
      .where(and(eq(fields.ownerUserId, ownerUserId), eq(fields.isActive, true)));
    return rows.map((r) => this.toField(r));
  }

  async addCourt(data: CreateCourtData): Promise<FieldCourt> {
    const [fieldRow] = await this.drizzle.db
      .select()
      .from(fields)
      .where(eq(fields.externalId, data.fieldExternalId))
      .limit(1);

    if (!fieldRow) {
      throw new NotFoundException(`Field ${data.fieldExternalId} not found`);
    }

    const [row] = await this.drizzle.db
      .insert(fieldCourts)
      .values({
        fieldId: fieldRow.id,
        name: data.name,
        type: data.type,
        maxPlayers: data.maxPlayers,
        pricePerHour: data.pricePerHour != null ? String(data.pricePerHour) : null,
      })
      .returning();

    return this.toCourt(row, fieldRow.externalId);
  }

  async findCourt(courtExternalId: string): Promise<FieldCourt | null> {
    const [row] = await this.drizzle.db
      .select({ court: fieldCourts, fieldExternalId: fields.externalId })
      .from(fieldCourts)
      .innerJoin(fields, eq(fieldCourts.fieldId, fields.id))
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);
    return row ? this.toCourt(row.court, row.fieldExternalId) : null;
  }

  async findCourts(fieldExternalId: string): Promise<FieldCourt[]> {
    const rows = await this.drizzle.db
      .select({ court: fieldCourts, fieldExternalId: fields.externalId })
      .from(fieldCourts)
      .innerJoin(fields, eq(fieldCourts.fieldId, fields.id))
      .where(and(eq(fields.externalId, fieldExternalId), eq(fieldCourts.isActive, true)));
    return rows.map((r) => this.toCourt(r.court, r.fieldExternalId));
  }

  async setAvailabilitySlots(courtExternalId: string, slots: AvailabilitySlotData[]): Promise<void> {
    const [court] = await this.drizzle.db
      .select()
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);

    if (!court) throw new NotFoundException(`Court ${courtExternalId} not found`);

    await this.drizzle.db.transaction(async (tx) => {
      await tx.delete(availabilitySlots).where(eq(availabilitySlots.courtId, court.id));
      if (slots.length > 0) {
        await tx.insert(availabilitySlots).values(
          slots.map((s) => ({
            courtId: court.id,
            dayOfWeek: s.dayOfWeek,
            startTime: s.startTime,
            endTime: s.endTime,
            isAvailable: s.isAvailable,
          })),
        );
      }
    });
  }

  async getAvailabilitySlots(courtExternalId: string): Promise<AvailabilitySlot[]> {
    const [court] = await this.drizzle.db
      .select()
      .from(fieldCourts)
      .where(eq(fieldCourts.externalId, courtExternalId))
      .limit(1);

    if (!court) return [];

    const rows = await this.drizzle.db
      .select()
      .from(availabilitySlots)
      .where(eq(availabilitySlots.courtId, court.id));
    return rows.map((r) => this.toSlot(r));
  }

  private toField(row: FieldRow): Field {
    return {
      id: row.externalId,
      name: row.name,
      description: row.description,
      city: row.city,
      address: row.address,
      lat: row.lat,
      lng: row.lng,
      ownerUserId: row.ownerUserId,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toCourt(row: FieldCourtRow, fieldExternalId: string): FieldCourt {
    return {
      id: row.externalId,
      fieldId: fieldExternalId,
      name: row.name,
      type: row.type as CourtType,
      maxPlayers: row.maxPlayers,
      isActive: row.isActive,
      pricePerHour: row.pricePerHour != null ? Number(row.pricePerHour) : null,
    };
  }

  private toSlot(row: AvailabilitySlotRow): AvailabilitySlot {
    return {
      id: row.id,
      courtId: row.courtId,
      dayOfWeek: row.dayOfWeek,
      startTime: row.startTime,
      endTime: row.endTime,
      isAvailable: row.isAvailable,
    };
  }
}
