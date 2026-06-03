import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { OpenGame } from '../../domain/models/open-game.entity';

export class OpenGameDto {
  @ApiProperty() id!: string;
  @ApiProperty() organizerUserId!: string;
  @ApiPropertyOptional() fieldId!: string | null;
  @ApiPropertyOptional() fieldNameSnapshot!: string | null;
  @ApiPropertyOptional() fieldAddressSnapshot!: string | null;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() description!: string | null;
  @ApiProperty() sport!: string;
  @ApiProperty() scheduledAt!: Date;
  @ApiProperty() durationMinutes!: number;
  @ApiProperty() minPlayers!: number;
  @ApiProperty() maxPlayers!: number;
  @ApiPropertyOptional() pricePerPlayer!: number | null;
  @ApiProperty() status!: string;
  @ApiProperty() participantCount!: number;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;

  static fromGame(game: OpenGame, participantCount: number): OpenGameDto {
    const dto = new OpenGameDto();
    dto.id = game.id;
    dto.organizerUserId = game.organizerUserId;
    dto.fieldId = game.fieldId;
    dto.fieldNameSnapshot = game.fieldNameSnapshot;
    dto.fieldAddressSnapshot = game.fieldAddressSnapshot;
    dto.title = game.title;
    dto.description = game.description;
    dto.sport = game.sport;
    dto.scheduledAt = game.scheduledAt;
    dto.durationMinutes = game.durationMinutes;
    dto.minPlayers = game.minPlayers;
    dto.maxPlayers = game.maxPlayers;
    dto.pricePerPlayer = game.pricePerPlayer;
    dto.status = game.status;
    dto.participantCount = participantCount;
    dto.createdAt = game.createdAt;
    dto.updatedAt = game.updatedAt;
    return dto;
  }
}
