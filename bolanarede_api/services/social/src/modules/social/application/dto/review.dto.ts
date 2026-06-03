import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { PlayerReview } from '../../domain/models/player-review.entity';

export class ReviewDto {
  @ApiProperty() id!: string;
  @ApiProperty() gameId!: string;
  @ApiProperty() gameType!: string;
  @ApiProperty() reviewerUserId!: string;
  @ApiProperty() reviewerDisplayName!: string;
  @ApiProperty() revieweeUserId!: string;
  @ApiProperty() revieweeDisplayName!: string;
  @ApiProperty() score!: number;
  @ApiPropertyOptional() comment?: string;
  @ApiProperty() createdAt!: Date;

  static fromReview(review: PlayerReview): ReviewDto {
    const dto = new ReviewDto();
    dto.id = review.id;
    dto.gameId = review.gameId;
    dto.gameType = review.gameType;
    dto.reviewerUserId = review.reviewerUserId;
    dto.reviewerDisplayName = review.reviewerDisplayName;
    dto.revieweeUserId = review.revieweeUserId;
    dto.revieweeDisplayName = review.revieweeDisplayName;
    dto.score = review.score;
    dto.comment = review.comment;
    dto.createdAt = review.createdAt;
    return dto;
  }
}
