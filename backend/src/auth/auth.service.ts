import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { RegisterShopDto } from './dto/register-shop.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { ALL_PERMISSIONS } from '../common/constants/permissions.constant.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async registerShop(dto: RegisterShopDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { username: dto.username },
    });
    if (existingUser) {
      throw new BadRequestException('Username is already taken');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    // Create shop and owner inside transaction (PRD §5.1)
    const result = await this.prisma.$transaction(async (tx) => {
      const shop = await tx.shop.create({
        data: {
          name: dto.shopName,
          address: dto.address,
          phone: dto.phone,
          currency: dto.currency || '₹',
          taxPercentage: 0.0,
          receiptHeader: `Welcome to ${dto.shopName}`,
          receiptFooter: 'Thank you for shopping with us!',
        },
      });

      const owner = await tx.user.create({
        data: {
          shopId: shop.id,
          fullName: dto.ownerFullName,
          username: dto.username,
          passwordHash,
          isOwner: true,
          isActive: true,
          permissions: JSON.stringify(ALL_PERMISSIONS),
        },
      });

      return { shop, owner };
    });

    const token = await this.generateToken(result.owner);
    return {
      accessToken: token,
      user: {
        id: result.owner.id,
        username: result.owner.username,
        fullName: result.owner.fullName,
        isOwner: result.owner.isOwner,
        permissions: ALL_PERMISSIONS,
      },
      shop: {
        id: result.shop.id,
        name: result.shop.name,
        currency: result.shop.currency,
        address: result.shop.address,
        phone: result.shop.phone,
        taxPercentage: Number(result.shop.taxPercentage),
        receiptHeader: result.shop.receiptHeader,
        receiptFooter: result.shop.receiptFooter,
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { username: dto.username },
      include: { shop: true },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid username or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('This account has been deactivated. Contact the shop owner.');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid username or password');
    }

    let parsedPermissions: string[] = [];
    try {
      parsedPermissions = typeof user.permissions === 'string'
        ? JSON.parse(user.permissions)
        : Array.isArray(user.permissions)
        ? (user.permissions as string[])
        : [];
    } catch {
      parsedPermissions = [];
    }

    // Owner always has all permissions (PRD §4.2)
    const effectivePermissions = user.isOwner ? ALL_PERMISSIONS : parsedPermissions;

    const token = await this.generateToken(user, effectivePermissions);

    return {
      accessToken: token,
      user: {
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        isOwner: user.isOwner,
        permissions: effectivePermissions,
      },
      shop: {
        id: user.shop.id,
        name: user.shop.name,
        currency: user.shop.currency,
        address: user.shop.address,
        phone: user.shop.phone,
        taxPercentage: Number(user.shop.taxPercentage),
        receiptHeader: user.shop.receiptHeader,
        receiptFooter: user.shop.receiptFooter,
      },
    };
  }

  async getCurrentUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { shop: true },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('User session invalid or inactive');
    }

    let parsedPermissions: string[] = [];
    try {
      parsedPermissions = typeof user.permissions === 'string'
        ? JSON.parse(user.permissions)
        : Array.isArray(user.permissions)
        ? (user.permissions as string[])
        : [];
    } catch {
      parsedPermissions = [];
    }

    const effectivePermissions = user.isOwner ? ALL_PERMISSIONS : parsedPermissions;

    return {
      user: {
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        isOwner: user.isOwner,
        permissions: effectivePermissions,
      },
      shop: {
        id: user.shop.id,
        name: user.shop.name,
        currency: user.shop.currency,
        address: user.shop.address,
        phone: user.shop.phone,
        taxPercentage: Number(user.shop.taxPercentage),
        receiptHeader: user.shop.receiptHeader,
        receiptFooter: user.shop.receiptFooter,
      },
    };
  }

  private async generateToken(user: any, permissions?: string[]) {
    const secret = this.configService.get<string>('JWT_SECRET', 'unified-pos-super-secret-jwt-key-2026');
    const expiresIn = this.configService.get<string>('JWT_EXPIRES_IN', '7d');

    const payload = {
      sub: user.id,
      shopId: user.shopId,
      username: user.username,
      fullName: user.fullName,
      isOwner: user.isOwner,
      permissions: permissions ?? ALL_PERMISSIONS,
    };

    return this.jwtService.signAsync(payload, {
      secret,
      expiresIn: expiresIn as any,
    });
  }
}
