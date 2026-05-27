import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';

export class UserDto {
  @ApiProperty({ description: 'ID público do usuário (UUID)' })
  id: string;

  @ApiPropertyOptional({ description: 'Email' })
  email: string | null;

  @ApiPropertyOptional({ description: 'Nome de exibição' })
  displayName?: string;

  @ApiPropertyOptional({ description: 'URL da foto' })
  photoUrl?: string | null;

  @ApiPropertyOptional({ description: 'Bio' })
  bio?: string | null;

  @ApiPropertyOptional({ description: 'Cidade' })
  city?: string | null;

  @ApiPropertyOptional({ description: 'Posição' })
  position?: string | null;

  @ApiPropertyOptional({ description: 'Nível de habilidade (1–5)' })
  skillLevel?: number | null;

  @ApiPropertyOptional({ description: 'Perfil público?' })
  isPublic?: boolean;

  @ApiProperty({ description: 'Data de criação da conta' })
  createdAt: Date;

  static fromUserAndProfile(user: User, profile: PlayerProfile | null): UserDto {
    const dto = new UserDto();
    dto.id = user.id;
    dto.email = user.email;
    dto.createdAt = user.createdAt;

    if (profile) {
      dto.displayName = profile.displayName;
      dto.photoUrl = profile.photoUrl;
      dto.bio = profile.bio;
      dto.city = profile.city;
      dto.position = profile.position;
      dto.skillLevel = profile.skillLevel;
      dto.isPublic = profile.isPublic;
    }

    return dto;
  }
}
