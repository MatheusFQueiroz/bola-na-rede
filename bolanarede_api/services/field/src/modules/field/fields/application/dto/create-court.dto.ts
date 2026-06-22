import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsIn, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateCourtDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty({ enum: ['society', 'futsal', 'grass', 'synthetic'] })
  @IsNotEmpty() @IsIn(['society', 'futsal', 'grass', 'synthetic']) type!: string;
  @ApiPropertyOptional({ default: 10 })
  @IsNumber() @IsOptional() @Min(2) @Max(22) maxPlayers?: number;
  @ApiPropertyOptional({ description: 'Preço por hora em BRL', example: 90 })
  @IsNumber() @IsOptional() @Min(0) pricePerHour?: number;
}
