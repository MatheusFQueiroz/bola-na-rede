import { ApiProperty } from '@nestjs/swagger';
import type { PlayerScore } from '../../domain/models/player-score.entity';

export class PlayerScoreDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalReviews!: number;
  @ApiProperty() averageScore!: number;
  @ApiProperty() updatedAt!: Date;

  static fromScore(score: PlayerScore): PlayerScoreDto {
    const dto = new PlayerScoreDto();
    dto.playerUserId = score.playerUserId;
    dto.displayName = score.displayName;
    dto.totalReviews = score.totalReviews;
    dto.averageScore = score.averageScore;
    dto.updatedAt = score.updatedAt;
    return dto;
  }

  static empty(playerUserId: string): PlayerScoreDto {
    const dto = new PlayerScoreDto();
    dto.playerUserId = playerUserId;
    dto.displayName = '';
    dto.totalReviews = 0;
    dto.averageScore = 0;
    dto.updatedAt = new Date(0);
    return dto;
  }
}
