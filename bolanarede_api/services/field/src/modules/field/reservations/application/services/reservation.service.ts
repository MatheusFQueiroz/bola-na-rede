import { ConflictException, ForbiddenException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { FIELD_REPOSITORY, type FieldRepositoryInterface } from '../../../fields/domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY, type ReservationRepositoryInterface } from '../../domain/repositories/reservation-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import { CreateReservationDto } from '../dto/create-reservation.dto';
import { ReservationDto } from '../dto/reservation.dto';

@Injectable()
export class ReservationService {
  constructor(
    @Inject(FIELD_REPOSITORY) private readonly fieldRepo: FieldRepositoryInterface,
    @Inject(RESERVATION_REPOSITORY) private readonly reservationRepo: ReservationRepositoryInterface,
    private readonly messaging: FieldMessagingService,
  ) {}

  async createManual(ownerUserId: string, fieldExternalId: string, dto: CreateReservationDto): Promise<ReservationDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can create reservations');

    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);

    const overlapping = await this.reservationRepo.findOverlapping(dto.courtId, startsAt, endsAt);
    if (overlapping.length > 0) {
      throw new ConflictException('Time slot is already reserved');
    }

    const reservation = await this.reservationRepo.create({
      courtExternalId: dto.courtId,
      fieldExternalId,
      channel: dto.channel as any,
      startsAt,
      endsAt,
      notes: dto.notes,
    });

    try {
      await this.messaging.publishReservationConfirmed(reservation);
    } catch {
      // advisory
    }

    return ReservationDto.from(reservation);
  }

  async cancel(ownerUserId: string, fieldExternalId: string, reservationExternalId: string): Promise<ReservationDto> {
    const field = await this.fieldRepo.findById(fieldExternalId);
    if (!field) throw new NotFoundException(`Field ${fieldExternalId} not found`);
    if (field.ownerUserId !== ownerUserId) throw new ForbiddenException('Only field owner can cancel reservations');

    const existing = await this.reservationRepo.findById(reservationExternalId);
    if (!existing) throw new NotFoundException(`Reservation ${reservationExternalId} not found`);

    const cancelled = await this.reservationRepo.cancel(reservationExternalId);

    try {
      await this.messaging.publishReservationCancelled(cancelled);
    } catch {
      // advisory
    }

    return ReservationDto.from(cancelled);
  }

  async list(fieldExternalId: string, page: number, limit: number): Promise<ReservationDto[]> {
    const reservations = await this.reservationRepo.findByField(fieldExternalId, page, limit);
    return reservations.map((r) => ReservationDto.from(r));
  }
}
