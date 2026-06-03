import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ description: 'Email do usuário', example: 'jogador@email.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ description: 'Senha', example: 'senha123' })
  @IsString()
  @MinLength(6)
  password!: string;
}
