import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateReviewDto {
  @IsUUID()
  @ApiProperty({ description: 'UUID do jogo (open-game ou game)' })
  gameId!: string;

  @IsIn(['open-game', 'game'])
  @ApiProperty({ enum: ['open-game', 'game'], description: 'Tipo do jogo' })
  gameType!: string;

  @IsUUID()
  @ApiProperty({ description: 'UUID do jogador avaliado' })
  revieweeUserId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  @ApiProperty({ minimum: 1, maximum: 5, description: 'Nota de 1 a 5' })
  score!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  @ApiPropertyOptional({ maxLength: 500 })
  comment?: string;
}
