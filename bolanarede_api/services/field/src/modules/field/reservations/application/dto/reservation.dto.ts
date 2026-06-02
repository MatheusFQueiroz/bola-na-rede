import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Reservation } from '../../domain/models/reservation.entity';

export class ReservationDto {
  @ApiProperty() id!: string;
  @ApiProperty() courtId!: string;
  @ApiProperty() fieldId!: string;
  @ApiPropertyOptional() playerUserId!: string | null;
  @ApiProperty() channel!: string;
  @ApiProperty() startsAt!: Date;
  @ApiProperty() endsAt!: Date;
  @ApiProperty() status!: string;
  @ApiPropertyOptional() notes!: string | null;
  @ApiProperty() createdAt!: Date;

  static from(r: Reservation): ReservationDto {
    const dto = new ReservationDto();
    dto.id = r.id;
    dto.courtId = r.courtId;
    dto.fieldId = r.fieldId;
    dto.playerUserId = r.playerUserId;
    dto.channel = r.channel;
    dto.startsAt = r.startsAt;
    dto.endsAt = r.endsAt;
    dto.status = r.status;
    dto.notes = r.notes;
    dto.createdAt = r.createdAt;
    return dto;
  }
}
