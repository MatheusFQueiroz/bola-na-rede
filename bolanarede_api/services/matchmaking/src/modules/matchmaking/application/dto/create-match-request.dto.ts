import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import type { SportType } from '../../domain/models/match-request.entity';

export class CreateMatchRequestDto {
  @ApiProperty({ enum: ['futsal', 'society', 'campo'] })
  @IsIn(['futsal', 'society', 'campo'])
  sport!: SportType;
}
