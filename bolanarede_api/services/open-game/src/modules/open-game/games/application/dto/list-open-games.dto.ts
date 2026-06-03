import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsISO8601, IsOptional, IsUUID } from 'class-validator';

export class ListOpenGamesDto {
  @ApiPropertyOptional({ enum: ['futsal', 'society', 'campo'] })
  @IsEnum(['futsal', 'society', 'campo']) @IsOptional()
  sport?: string;

  @ApiPropertyOptional({ description: 'UUID do campo (field-service)' })
  @IsUUID() @IsOptional()
  fieldId?: string;

  @ApiPropertyOptional({ example: '2026-07-01T00:00:00Z' })
  @IsISO8601() @IsOptional()
  from?: string;

  @ApiPropertyOptional({ example: '2026-07-31T23:59:59Z' })
  @IsISO8601() @IsOptional()
  to?: string;
}
