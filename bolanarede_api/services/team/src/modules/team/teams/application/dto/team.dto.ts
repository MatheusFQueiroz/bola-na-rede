import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Team } from '../../domain/models/team.entity';

export class TeamDto {
  @ApiProperty({ description: 'ID público da equipe (UUID)' })
  id!: string;

  @ApiProperty({ description: 'Nome da equipe' })
  name!: string;

  @ApiPropertyOptional({ description: 'Descrição da equipe' })
  description!: string | null;

  @ApiProperty({ description: 'UUID do capitão (identity)' })
  captainUserId!: string;

  @ApiProperty({ description: 'Mínimo de jogadores para partida' })
  minPlayers!: number;

  @ApiProperty({ description: 'Máximo de jogadores no elenco' })
  maxPlayers!: number;

  @ApiProperty({ description: 'Número de membros ativos' })
  memberCount!: number;

  @ApiProperty({ description: 'Equipe ativa?' })
  isActive!: boolean;

  @ApiProperty({ description: 'Data de criação' })
  createdAt!: Date;

  static fromTeamAndCount(team: Team, count: number): TeamDto {
    const dto = new TeamDto();
    dto.id = team.id;
    dto.name = team.name;
    dto.description = team.description;
    dto.captainUserId = team.captainUserId;
    dto.minPlayers = team.minPlayers;
    dto.maxPlayers = team.maxPlayers;
    dto.memberCount = count;
    dto.isActive = team.isActive;
    dto.createdAt = team.createdAt;
    return dto;
  }
}
