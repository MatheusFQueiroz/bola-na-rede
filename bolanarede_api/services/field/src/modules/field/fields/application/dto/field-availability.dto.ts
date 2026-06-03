import { ApiProperty } from '@nestjs/swagger';

export class TimeSlotDto {
  @ApiProperty({ example: '08:00' }) startTime!: string;
  @ApiProperty({ example: '09:00' }) endTime!: string;
  @ApiProperty() isAvailable!: boolean;
}

export class CourtAvailabilityDto {
  @ApiProperty() courtId!: string;
  @ApiProperty() courtName!: string;
  @ApiProperty({ type: [TimeSlotDto] }) slots!: TimeSlotDto[];
}

export class FieldAvailabilityDto {
  @ApiProperty() fieldId!: string;
  @ApiProperty() date!: string;
  @ApiProperty({ type: [CourtAvailabilityDto] }) courts!: CourtAvailabilityDto[];
}
