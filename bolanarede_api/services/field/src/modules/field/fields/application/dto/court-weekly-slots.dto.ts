import { ApiProperty } from '@nestjs/swagger';

export class CourtWeeklySlotDto {
  @ApiProperty({ description: '0=Dom, 1=Seg, ..., 6=Sáb' }) dayOfWeek!: number;
  @ApiProperty({ example: '08:00' }) startTime!: string;
  @ApiProperty({ example: '09:00' }) endTime!: string;
  @ApiProperty() isAvailable!: boolean;

  static from(slot: { dayOfWeek: number; startTime: string; endTime: string; isAvailable: boolean }): CourtWeeklySlotDto {
    const dto = new CourtWeeklySlotDto();
    dto.dayOfWeek = slot.dayOfWeek;
    dto.startTime = slot.startTime;
    dto.endTime = slot.endTime;
    dto.isAvailable = slot.isAvailable;
    return dto;
  }
}
