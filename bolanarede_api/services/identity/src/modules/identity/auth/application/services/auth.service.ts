import { ConflictException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import {
  USER_REPOSITORY,
  UserRepositoryInterface,
} from '../../../users/domain/repositories/user-repository.interface';
import type { LoginDto } from '../dto/login.dto';
import type { RegisterDto } from '../dto/register.dto';

const DEFAULT_PERMISSIONS = [
  'players:read',
  'players:write',
  'open-games:read',
  'open-games:write',
  'teams:read',
  'teams:write',
  'reviews:read',
  'reviews:write',
  'seasons:read',
  'seasons:write',
  'matches:read',
  'matches:write',
  'rankings:read',
  'notifications:write',
];

@Injectable()
export class AuthService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepositoryInterface,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<{ accessToken: string }> {
    const existing = await this.userRepository.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already in use');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.userRepository.create({
      email: dto.email,
      passwordHash,
      displayName: dto.displayName,
    });

    const payload: AuthenticatedUser = {
      id: user.id,
      name: dto.displayName,
      email: dto.email,
      permissions: DEFAULT_PERMISSIONS,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_SECRET'),
      expiresIn: '7d',
    });

    return { accessToken };
  }

  async login(dto: LoginDto): Promise<{ accessToken: string }> {
    const user = await this.userRepository.findByEmail(dto.email);
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials');

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) throw new UnauthorizedException('Invalid credentials');

    const profile = await this.userRepository.findProfileById(user.id);

    const payload: AuthenticatedUser = {
      id: user.id,
      name: profile?.displayName ?? user.email ?? user.id,
      email: user.email ?? '',
      permissions: DEFAULT_PERMISSIONS,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_SECRET'),
      expiresIn: '7d',
    });

    return { accessToken };
  }

  async refresh(token: string): Promise<{ accessToken: string }> {
    let payload: AuthenticatedUser;
    try {
      payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
        ignoreExpiration: true,
      });
    } catch {
      throw new UnauthorizedException('Invalid token');
    }

    const newToken = await this.jwtService.signAsync(
      { id: payload.id, name: payload.name, email: payload.email, permissions: payload.permissions },
      { secret: this.config.getOrThrow<string>('JWT_SECRET'), expiresIn: '7d' },
    );

    return { accessToken: newToken };
  }
}
