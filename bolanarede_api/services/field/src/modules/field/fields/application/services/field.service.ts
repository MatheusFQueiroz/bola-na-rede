import { ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface, type SearchFieldsParams } from '../../domain/repositories/field-repository.interface';
import { FieldMessagingService } from './field-messaging.service';
import { CreateFieldDto } from '../dto/create-field.dto';
import { CreateCourtDto } from '../dto/create-court.dto';
import { FieldDto } from '../dto/field.dto';
import { FieldCourtDto } from '../dto/field-court.dto';
import { CourtWeeklySlotDto } from '../dto/court-weekly-slots.dto';

@Injectable()
export class FieldService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async register(ownerUserId: string, dto: CreateFieldDto): Promise<FieldDto> {
    const field = await this.fieldRepo.create({
      name: dto.name,
      description: dto.description,
      city: dto.city,
      address: dto.address,
      lat: dto.lat,
      lng: dto.lng,
      ownerUserId,
    });

    try {
      await this.messaging.publishFieldRegistered(field);
    } catch {
      // advisory — não bloqueia resposta
    }

    return FieldDto.from(field);
  }

  async getById(externalId: string): Promise<FieldDto> {
    const field = await this.fieldRepo.findById(externalId);
    if (!field) throw new NotFoundException(`Field ${externalId} not found`);
    return FieldDto.from(field);
  }

  async searchNearby(params: SearchFieldsParams): Promise<FieldDto[]> {
    const results = await this.fieldRepo.findNearby(params);
    return results.map((f) => FieldDto.from(f));
  }

  async findByOwner(ownerUserId: string): Promise<FieldDto[]> {
    const results = await this.fieldRepo.findByOwner(ownerUserId);
    return results.map((f) => FieldDto.from(f));
  }

  async addCourt(ownerUserId: string, fieldExternalId: string, dto: CreateCourtDto): Promise<FieldCourtDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can add courts');

    const court = await this.fieldRepo.addCourt({
      fieldExternalId,
      name: dto.name,
      type: dto.type,
      maxPlayers: dto.maxPlayers ?? 10,
    });

    return FieldCourtDto.from(court);
  }

  async getCourts(fieldExternalId: string): Promise<FieldCourtDto[]> {
    const courts = await this.fieldRepo.findCourts(fieldExternalId);
    return courts.map((c) => FieldCourtDto.from(c));
  }

  async setAvailability(
    ownerUserId: string,
    fieldExternalId: string,
    courtExternalId: string,
    slots: Array<{ dayOfWeek: number; startTime: string; endTime: string; isAvailable: boolean }>,
  ): Promise<void> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can set availability');

    await this.fieldRepo.setAvailabilitySlots(courtExternalId, slots);
  }

  async getCourtWeeklySlots(fieldExternalId: string, courtExternalId: string): Promise<CourtWeeklySlotDto[]> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    const slots = await this.fieldRepo.getAvailabilitySlots(courtExternalId);
    return slots.map((s) => CourtWeeklySlotDto.from(s));
  }
}
