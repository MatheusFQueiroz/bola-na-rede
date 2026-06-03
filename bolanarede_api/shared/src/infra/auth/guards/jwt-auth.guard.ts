import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { IS_PUBLIC_KEY } from '../../decorators/public.decorator';
import type { AuthenticatedUser } from '../interfaces/authenticated-user.interface';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context
      .switchToHttp()
      .getRequest<{ user?: AuthenticatedUser; headers: { authorization?: string } }>();

    const token = this.extractToken(request.headers.authorization);
    if (!token) throw new UnauthorizedException();

    try {
      const payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
      });
      request.user = payload;
    } catch {
      throw new UnauthorizedException();
    }

    return true;
  }

  private extractToken(authorization?: string): string | undefined {
    const [type, token] = authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
