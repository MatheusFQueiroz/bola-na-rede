import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { GameParticipant } from '../../domain/models/game-participant.entity';

export class GameParticipantDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiPropertyOptional() position!: string | null;
  @ApiProperty() joinedAt!: Date;

  static fromParticipant(p: GameParticipant): GameParticipantDto {
    const dto = new GameParticipantDto();
    dto.playerUserId = p.playerUserId;
    dto.displayName = p.displayName;
    dto.position = p.position;
    dto.joinedAt = p.joinedAt;
    return dto;
  }
}
