import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
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
}
