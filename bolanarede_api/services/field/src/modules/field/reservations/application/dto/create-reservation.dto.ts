import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsOptional, IsString, IsUUID } from 'class-validator';
import type { ReservationChannel } from '../../domain/models/reservation.entity';

export class CreateReservationDto {
  @ApiProperty({ description: 'UUID da quadra' })
  @IsUUID() courtId!: string;

  @ApiProperty({ enum: ['app', 'manual', 'phone'] })
  @IsIn(['app', 'manual', 'phone']) channel!: ReservationChannel;

  @ApiProperty({ example: '2026-06-15T08:00:00-03:00' })
  @IsDateString() startsAt!: string;

  @ApiProperty({ example: '2026-06-15T09:00:00-03:00' })
  @IsDateString() endsAt!: string;

  @ApiPropertyOptional() @IsOptional() @IsString() notes?: string;
}
