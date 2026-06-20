import { ApiProperty } from '@nestjs/swagger';
import type { PlayerRanking } from '../../domain/models/player-ranking.entity';

export class LeaderboardEntryDto {
  @ApiProperty() position!: number;
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() gamesPlayed!: number;
  @ApiProperty() wins!: number;
  @ApiProperty() losses!: number;
  @ApiProperty() draws!: number;
  @ApiProperty() goals!: number;
  @ApiProperty() assists!: number;
  @ApiProperty() points!: number;

  static from(r: PlayerRanking, position: number): LeaderboardEntryDto {
    const dto = new LeaderboardEntryDto();
    dto.position = position;
    dto.playerUserId = r.playerUserId;
    dto.displayName = r.displayName;
    dto.sport = r.sport;
    dto.gamesPlayed = r.gamesPlayed;
    dto.wins = r.wins;
    dto.losses = r.losses;
    dto.draws = r.draws;
    dto.goals = r.goals;
    dto.assists = r.assists;
    dto.points = r.points;
    return dto;
  }
}
