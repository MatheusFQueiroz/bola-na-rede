import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateRecurringPlanDto {
  @ApiProperty({ description: 'UUID da quadra' }) @IsString() courtId!: string;
  @ApiProperty({ description: '0=Dom, 1=Seg, ..., 6=Sáb' })
  @IsInt() @Min(0) @Max(6) dayOfWeek!: number;
  @ApiProperty({ example: '08:00' }) @IsString() startTime!: string;
  @ApiProperty({ example: '09:00' }) @IsString() endTime!: string;
  @ApiProperty({ example: '2026-06-01T00:00:00Z' }) @IsDateString() planStartsAt!: string;
  @ApiPropertyOptional() @IsOptional() @IsDateString() planEndsAt?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() playerUserId?: string;
}
