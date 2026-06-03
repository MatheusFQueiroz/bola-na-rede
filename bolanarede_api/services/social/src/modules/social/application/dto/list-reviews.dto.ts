import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUUID } from 'class-validator';

export class ListReviewsDto {
  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do jogador avaliado' })
  revieweeUserId?: string;

  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do avaliador' })
  reviewerUserId?: string;

  @IsOptional()
  @IsUUID()
  @ApiPropertyOptional({ description: 'Filtrar por UUID do jogo' })
  gameId?: string;
}
