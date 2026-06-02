import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsNotEmpty, IsString, Max, Min, ValidateNested } from 'class-validator';

export class AvailabilitySlotDto {
  @ApiProperty({ description: '0=Dom, 1=Seg, ..., 6=Sáb' })
  @IsInt() @Min(0) @Max(6) dayOfWeek!: number;
  @ApiProperty({ example: '08:00' }) @IsString() @IsNotEmpty() startTime!: string;
  @ApiProperty({ example: '09:00' }) @IsString() @IsNotEmpty() endTime!: string;
  @ApiProperty() @IsBoolean() isAvailable!: boolean;
}

export class SetAvailabilityDto {
  @ApiProperty({ type: [AvailabilitySlotDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AvailabilitySlotDto)
  slots!: AvailabilitySlotDto[];
}
