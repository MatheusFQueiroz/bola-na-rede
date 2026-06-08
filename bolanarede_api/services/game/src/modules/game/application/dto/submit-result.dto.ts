import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class SubmitResultDto {
  @ApiProperty({ description: 'Goals scored by player A', minimum: 0 })
  @IsInt()
  @Min(0)
  playerAGoals!: number;

  @ApiProperty({ description: 'Goals scored by player B', minimum: 0 })
  @IsInt()
  @Min(0)
  playerBGoals!: number;

  @ApiProperty({ description: 'Assists by player A', minimum: 0 })
  @IsInt()
  @Min(0)
  playerAAssists!: number;

  @ApiProperty({ description: 'Assists by player B', minimum: 0 })
  @IsInt()
  @Min(0)
  playerBAssists!: number;
}
