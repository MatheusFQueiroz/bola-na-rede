import { ApiProperty } from '@nestjs/swagger';
import type { PendingMatch } from '../../domain/models/pending-match.entity';

export class PendingMatchDto {
  @ApiProperty() id!: string;
  @ApiProperty() sport!: string;
  @ApiProperty() status!: string;
  @ApiProperty() acceptedByA!: boolean;
  @ApiProperty() acceptedByB!: boolean;
  @ApiProperty() proposedAt!: Date;
  @ApiProperty() expiresAt!: Date;

  static from(m: PendingMatch): PendingMatchDto {
    const dto = new PendingMatchDto();
    dto.id = m.externalId;
    dto.sport = m.sport;
    dto.status = m.status;
    dto.acceptedByA = m.acceptedByA;
    dto.acceptedByB = m.acceptedByB;
    dto.proposedAt = m.proposedAt;
    dto.expiresAt = m.expiresAt;
    return dto;
  }
}
