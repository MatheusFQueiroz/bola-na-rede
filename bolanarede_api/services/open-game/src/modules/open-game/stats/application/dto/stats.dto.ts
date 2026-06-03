import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { PlayerStats } from '../../domain/models/player-stats.entity';

export class StatsDto {
  @ApiProperty() gameId!: string;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() goals!: number;
  @ApiProperty() assists!: number;
  @ApiPropertyOptional() notes!: string | null;
  @ApiProperty() createdAt!: Date;

  static fromStats(s: PlayerStats): StatsDto {
    const dto = new StatsDto();
    dto.gameId = s.gameExternalId;
    dto.playerUserId = s.playerUserId;
    dto.goals = s.goals;
    dto.assists = s.assists;
    dto.notes = s.notes;
    dto.createdAt = s.createdAt;
    return dto;
  }
}
