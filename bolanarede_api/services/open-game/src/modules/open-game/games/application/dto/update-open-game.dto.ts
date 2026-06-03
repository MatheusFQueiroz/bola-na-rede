import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString, IsISO8601, IsOptional, IsPositive, IsInt,
  Min, Max, IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateOpenGameDto {
  @ApiPropertyOptional() @IsString() @IsOptional() title?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() description?: string;
  @ApiPropertyOptional() @IsISO8601() @IsOptional() scheduledAt?: string;
  @ApiPropertyOptional() @IsInt() @IsPositive() @IsOptional() @Type(() => Number) durationMinutes?: number;
  @ApiPropertyOptional() @IsInt() @Min(2) @Max(30) @IsOptional() @Type(() => Number) minPlayers?: number;
  @ApiPropertyOptional() @IsInt() @Min(2) @Max(30) @IsOptional() @Type(() => Number) maxPlayers?: number;
  @ApiPropertyOptional() @IsUUID() @IsOptional() fieldId?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() fieldNameSnapshot?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() fieldAddressSnapshot?: string;
  @ApiPropertyOptional() @IsPositive() @IsOptional() @Type(() => Number) pricePerPlayer?: number;
}
