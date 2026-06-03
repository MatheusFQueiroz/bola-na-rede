import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateTeamDto {
  @ApiProperty({ description: 'Nome da equipe', example: 'Los Cracks' })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name!: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe', example: 'Time de pelada do bairro' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  description?: string;

  @ApiPropertyOptional({ description: 'Mínimo de jogadores para partida', default: 5 })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(11)
  minPlayers?: number;

  @ApiPropertyOptional({ description: 'Máximo de jogadores no elenco', default: 11 })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(22)
  maxPlayers?: number;
}
