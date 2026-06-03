import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateTeamDto {
  @ApiPropertyOptional({ description: 'Nome da equipe', example: 'Los Cracks FC' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name?: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  description?: string;
}
