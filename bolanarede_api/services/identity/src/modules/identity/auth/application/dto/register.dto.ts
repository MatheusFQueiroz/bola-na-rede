import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ description: 'Email do usuário', example: 'jogador@email.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ description: 'Senha (mínimo 6 caracteres)', example: 'senha123' })
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({ description: 'Nome de exibição', example: 'João Silva' })
  @IsString()
  @MinLength(2)
  displayName!: string;

  @ApiPropertyOptional({ description: 'Telefone', example: '(41) 99999-0001' })
  @IsOptional()
  @IsString()
  phone?: string;
}
