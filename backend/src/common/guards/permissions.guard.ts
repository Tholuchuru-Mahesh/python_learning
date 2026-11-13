import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator.js';
import { Permission } from '../constants/permissions.constant.js';
import { CurrentUserPayload } from '../decorators/current-user.decorator.js';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user as CurrentUserPayload;

    if (!user) {
      throw new ForbiddenException('User session not found');
    }

    // Owner/manager has full access across all modules (PRD §4.2)
    if (user.isOwner) {
      return true;
    }

    const userPermissions = new Set(user.permissions || []);
    const hasAllRequired = requiredPermissions.every((permission) =>
      userPermissions.has(permission),
    );

    if (!hasAllRequired) {
      throw new ForbiddenException(
        `Access denied. Missing required permission: ${requiredPermissions
          .filter((p) => !userPermissions.has(p))
          .join(', ')}`,
      );
    }

    return true;
  }
}

