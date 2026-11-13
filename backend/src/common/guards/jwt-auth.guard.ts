import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authentication token missing or invalid format');
    }

    const token = authHeader.substring(7);
    try {
      const secret = this.configService.get<string>('JWT_SECRET', 'unified-pos-super-secret-jwt-key-2026');
      const payload = await this.jwtService.verifyAsync(token, { secret });
      
      // Attach user payload to request
      request.user = {
        userId: payload.sub,
        shopId: payload.shopId,
        username: payload.username,
        fullName: payload.fullName,
        isOwner: Boolean(payload.isOwner),
        permissions: Array.isArray(payload.permissions) ? payload.permissions : [],
      };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token');
    }
  }
}

