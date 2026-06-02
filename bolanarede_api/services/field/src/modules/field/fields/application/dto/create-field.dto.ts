import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateFieldDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiPropertyOptional() @IsString() @IsOptional() description?: string;
  @ApiProperty() @IsString() @IsNotEmpty() city!: string;
  @ApiProperty() @IsString() @IsNotEmpty() address!: string;
  @ApiProperty({ description: 'Latitude (-90 a 90)' })
  @IsNumber() @Min(-90) @Max(90) lat!: number;
  @ApiProperty({ description: 'Longitude (-180 a 180)' })
  @IsNumber() @Min(-180) @Max(180) lng!: number;
}
