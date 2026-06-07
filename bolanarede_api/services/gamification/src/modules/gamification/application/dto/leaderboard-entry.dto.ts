import { ApiProperty } from '@nestjs/swagger';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

export class LeaderboardEntryDto {
  @ApiProperty() rank!: number;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalXp!: number;
  @ApiProperty() level!: number;

  static from(profile: PlayerProfile, rank: number): LeaderboardEntryDto {
    const dto = new LeaderboardEntryDto();
    dto.rank = rank;
    dto.playerUserId = profile.playerUserId;
    dto.displayName = profile.displayName;
    dto.totalXp = profile.totalXp;
    dto.level = profile.level;
    return dto;
  }
}
