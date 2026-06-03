import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString, IsNotEmpty, IsEnum, IsISO8601, IsOptional,
  IsPositive, IsInt, Min, Max, IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOpenGameDto {
  @ApiProperty({ example: 'Pelada de terça' })
  @IsString() @IsNotEmpty()
  title!: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  description?: string;

  @ApiProperty({ enum: ['futsal', 'society', 'campo'] })
  @IsEnum(['futsal', 'society', 'campo'])
  sport!: string;

  @ApiProperty({ example: '2026-07-01T19:00:00Z', description: 'ISO 8601 UTC' })
  @IsISO8601()
  scheduledAt!: string;

  @ApiPropertyOptional({ default: 60 })
  @IsInt() @IsPositive() @IsOptional()
  @Type(() => Number)
  durationMinutes?: number;

  @ApiPropertyOptional({ default: 10 })
  @IsInt() @Min(2) @Max(30) @IsOptional()
  @Type(() => Number)
  minPlayers?: number;

  @ApiPropertyOptional({ default: 22 })
  @IsInt() @Min(2) @Max(30) @IsOptional()
  @Type(() => Number)
  maxPlayers?: number;

  @ApiPropertyOptional({ description: 'UUID do campo cadastrado no field-service' })
  @IsUUID() @IsOptional()
  fieldId?: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  fieldNameSnapshot?: string;

  @ApiPropertyOptional()
  @IsString() @IsOptional()
  fieldAddressSnapshot?: string;

  @ApiPropertyOptional({ description: 'Preço por jogador em reais (null = gratuito)' })
  @IsPositive() @IsOptional()
  @Type(() => Number)
  pricePerPlayer?: number;
}
