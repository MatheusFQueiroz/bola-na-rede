import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsUUID, IsInt, Min, IsOptional, IsString, ValidateNested, ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';

export class PlayerStatEntryDto {
  @ApiProperty({ description: 'UUID do jogador (identity)' })
  @IsUUID()
  playerUserId!: string;

  @ApiProperty({ default: 0 }) @IsInt() @Min(0) goals!: number;
  @ApiProperty({ default: 0 }) @IsInt() @Min(0) assists!: number;

  @ApiPropertyOptional() @IsString() @IsOptional() notes?: string;
}

export class RecordStatsDto {
  @ApiProperty({ type: [PlayerStatEntryDto] })
  @ValidateNested({ each: true })
  @ArrayMinSize(1)
  @Type(() => PlayerStatEntryDto)
  players!: PlayerStatEntryDto[];
}
