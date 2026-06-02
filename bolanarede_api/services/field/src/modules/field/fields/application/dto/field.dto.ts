import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { Field } from '../../domain/models/field.entity';

export class FieldDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiPropertyOptional() description!: string | null;
  @ApiProperty() city!: string;
  @ApiProperty() address!: string;
  @ApiProperty() lat!: number;
  @ApiProperty() lng!: number;
  @ApiProperty() ownerUserId!: string;
  @ApiProperty() isActive!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(field: Field): FieldDto {
    const dto = new FieldDto();
    dto.id = field.id;
    dto.name = field.name;
    dto.description = field.description;
    dto.city = field.city;
    dto.address = field.address;
    dto.lat = field.lat;
    dto.lng = field.lng;
    dto.ownerUserId = field.ownerUserId;
    dto.isActive = field.isActive;
    dto.createdAt = field.createdAt;
    return dto;
  }
}
