import { ApiProperty } from '@nestjs/swagger';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
import type { PlayerBadge } from '../../domain/models/player-badge.entity';

export class BadgeDto {
  @ApiProperty() badgeCode!: string;
  @ApiProperty() earnedAt!: Date;

  static fromBadge(b: PlayerBadge): BadgeDto {
    const dto = new BadgeDto();
    dto.badgeCode = b.badgeCode;
    dto.earnedAt = b.earnedAt;
    return dto;
  }
}

export class ProfileDto {
  @ApiProperty() playerUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() totalXp!: number;
  @ApiProperty() level!: number;
  @ApiProperty({ type: [BadgeDto] }) badges!: BadgeDto[];
  @ApiProperty() updatedAt!: Date;

  static from(profile: PlayerProfile, badges: PlayerBadge[]): ProfileDto {
    const dto = new ProfileDto();
    dto.playerUserId = profile.playerUserId;
    dto.displayName = profile.displayName;
    dto.totalXp = profile.totalXp;
    dto.level = profile.level;
    dto.badges = badges.map((b) => BadgeDto.fromBadge(b));
    dto.updatedAt = profile.updatedAt;
    return dto;
  }
}
