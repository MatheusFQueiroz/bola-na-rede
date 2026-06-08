import { ApiProperty } from '@nestjs/swagger';
import type { CompetitiveGame } from '../../domain/models/competitive-game.entity';

export class GameDto {
  @ApiProperty() id!: string;
  @ApiProperty() matchId!: string;
  @ApiProperty() userAId!: string;
  @ApiProperty() userBId!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() playerAGoals!: number;
  @ApiProperty() playerBGoals!: number;
  @ApiProperty() playerAAssists!: number;
  @ApiProperty() playerBAssists!: number;
  @ApiProperty({ nullable: true }) winnerId!: string | null;
  @ApiProperty({ nullable: true }) submittedByUserId!: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;

  static from(g: CompetitiveGame): GameDto {
    const dto = new GameDto();
    dto.id = g.externalId;
    dto.matchId = g.matchId;
    dto.userAId = g.userAId;
    dto.userBId = g.userBId;
    dto.sport = g.sport;
    dto.status = g.status;
    dto.playerAGoals = g.playerAGoals;
    dto.playerBGoals = g.playerBGoals;
    dto.playerAAssists = g.playerAAssists;
    dto.playerBAssists = g.playerBAssists;
    dto.winnerId = g.winnerId;
    dto.submittedByUserId = g.submittedByUserId;
    dto.createdAt = g.createdAt;
    dto.updatedAt = g.updatedAt;
    return dto;
  }
}
