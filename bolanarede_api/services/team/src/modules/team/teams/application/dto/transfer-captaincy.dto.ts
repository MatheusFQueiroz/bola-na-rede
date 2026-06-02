import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class TransferCaptaincyDto {
  @ApiProperty({
    description: 'UUID do novo capitão (deve ser membro ativo da equipe)',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  newCaptainId!: string;
}
