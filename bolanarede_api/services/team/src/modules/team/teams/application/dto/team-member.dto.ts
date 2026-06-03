import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { TeamMember } from '../../domain/models/team-member.entity';

export class TeamMemberDto {
  @ApiProperty({ description: 'UUID do jogador (identity)' })
  playerUserId!: string;

  @ApiProperty({ description: 'Nome de exibição (snapshot)' })
  displayName!: string;

  @ApiPropertyOptional({ description: 'Posição preferida (snapshot)' })
  position!: string | null;

  @ApiProperty({ enum: ['captain', 'member'], description: 'Papel na equipe' })
  role!: 'captain' | 'member';

  @ApiProperty({ description: 'Data de entrada na equipe' })
  joinedAt!: Date;

  static fromMember(member: TeamMember): TeamMemberDto {
    const dto = new TeamMemberDto();
    dto.playerUserId = member.playerUserId;
    dto.displayName = member.displayName;
    dto.position = member.position;
    dto.role = member.role;
    dto.joinedAt = member.joinedAt;
    return dto;
  }
}
