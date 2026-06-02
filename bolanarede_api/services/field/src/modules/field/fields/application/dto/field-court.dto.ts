import { ApiProperty } from '@nestjs/swagger';
import type { FieldCourt } from '../../domain/models/field-court.entity';

export class FieldCourtDto {
  @ApiProperty() id!: string;
  @ApiProperty() fieldId!: string;
  @ApiProperty() name!: string;
  @ApiProperty() type!: string;
  @ApiProperty() maxPlayers!: number;
  @ApiProperty() isActive!: boolean;

  static from(court: FieldCourt): FieldCourtDto {
    const dto = new FieldCourtDto();
    dto.id = court.id;
    dto.fieldId = court.fieldId;
    dto.name = court.name;
    dto.type = court.type;
    dto.maxPlayers = court.maxPlayers;
    dto.isActive = court.isActive;
    return dto;
  }
}
