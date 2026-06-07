import { ApiProperty } from '@nestjs/swagger';
import type { MatchRequest } from '../../domain/models/match-request.entity';

export class MatchRequestDto {
  @ApiProperty() id!: string;
  @ApiProperty() requesterUserId!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() requestedAt!: Date;
  @ApiProperty() expiresAt!: Date;

  static from(r: MatchRequest): MatchRequestDto {
    const dto = new MatchRequestDto();
    dto.id = r.externalId;
    dto.requesterUserId = r.requesterUserId;
    dto.displayName = r.displayName;
    dto.sport = r.sport;
    dto.status = r.status;
    dto.requestedAt = r.requestedAt;
    dto.expiresAt = r.expiresAt;
    return dto;
  }
}
