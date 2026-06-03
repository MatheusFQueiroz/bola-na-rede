import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  Min,
} from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ description: 'Nome de exibição', example: 'João Silva' })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional({ description: 'URL da foto de perfil' })
  @IsOptional()
  @IsUrl()
  photoUrl?: string;

  @ApiPropertyOptional({ description: 'Apresentação do jogador' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ description: 'Cidade', example: 'Curitiba' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({
    description: 'Posição em campo',
    enum: ['goalkeeper', 'defender', 'midfielder', 'forward'],
  })
  @IsOptional()
  @IsIn(['goalkeeper', 'defender', 'midfielder', 'forward'])
  position?: string;

  @ApiPropertyOptional({ description: 'Nível de habilidade (1–5)', minimum: 1, maximum: 5 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  skillLevel?: number;

  @ApiPropertyOptional({ description: 'Perfil visível publicamente?' })
  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
