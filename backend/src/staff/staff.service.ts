import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { CreateStaffDto } from './dto/create-staff.dto.js';
import { UpdateStaffDto } from './dto/update-staff-permissions.dto.js';
import { ALL_PERMISSIONS } from '../common/constants/permissions.constant.js';

@Injectable()
export class StaffService {
  constructor(private readonly prisma: PrismaService) {}

  async listStaff(shopId: string) {
    const users = await this.prisma.user.findMany({
      where: { shopId },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        fullName: true,
        username: true,
        isOwner: true,
        isActive: true,
        permissions: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return users.map((u) => {
      let parsedPermissions: string[] = [];
      try {
        parsedPermissions = typeof u.permissions === 'string'
          ? JSON.parse(u.permissions)
          : Array.isArray(u.permissions)
          ? (u.permissions as string[])
          : [];
      } catch {
        parsedPermissions = [];
      }

      return {
        ...u,
        permissions: u.isOwner ? ALL_PERMISSIONS : parsedPermissions,
      };
    });
  }

  async createStaff(shopId: string, dto: CreateStaffDto) {
    const existing = await this.prisma.user.findUnique({
      where: { username: dto.username },
    });
    if (existing) {
      throw new BadRequestException('Username is already taken');
    }

    // Validate permission names against ALL_PERMISSIONS
    const validPermissions = dto.permissions.filter((p) =>
      ALL_PERMISSIONS.includes(p as any),
    );

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const staff = await this.prisma.user.create({
      data: {
        shopId,
        fullName: dto.fullName,
        username: dto.username,
        passwordHash,
        isOwner: false,
        isActive: true,
        permissions: JSON.stringify(validPermissions),
      },
      select: {
        id: true,
        fullName: true,
        username: true,
        isOwner: true,
        isActive: true,
        permissions: true,
        createdAt: true,
      },
    });

    return {
      ...staff,
      permissions: validPermissions,
    };
  }

  async updateStaff(shopId: string, staffId: string, dto: UpdateStaffDto) {
    const user = await this.prisma.user.findFirst({
      where: { id: staffId, shopId },
    });

    if (!user) {
      throw new NotFoundException('Staff account not found');
    }

    // Immutable owner protection (PRD §4.2)
    if (user.isOwner) {
      throw new ForbiddenException('Owner account permissions and status cannot be modified');
    }

    const dataToUpdate: any = {};

    if (dto.permissions !== undefined) {
      const validPermissions = dto.permissions.filter((p) =>
        ALL_PERMISSIONS.includes(p as any),
      );
      dataToUpdate.permissions = JSON.stringify(validPermissions);
    }

    if (dto.isActive !== undefined) {
      dataToUpdate.isActive = dto.isActive;
    }

    const updated = await this.prisma.user.update({
      where: { id: staffId },
      data: dataToUpdate,
      select: {
        id: true,
        fullName: true,
        username: true,
        isOwner: true,
        isActive: true,
        permissions: true,
        updatedAt: true,
      },
    });

    let parsedPermissions: string[] = [];
    try {
      parsedPermissions = typeof updated.permissions === 'string'
        ? JSON.parse(updated.permissions)
        : Array.isArray(updated.permissions)
        ? (updated.permissions as string[])
        : [];
    } catch {
      parsedPermissions = [];
    }

    return {
      ...updated,
      permissions: parsedPermissions,
    };
  }

  async revokeStaff(shopId: string, staffId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: staffId, shopId },
    });

    if (!user) {
      throw new NotFoundException('Staff account not found');
    }

    if (user.isOwner) {
      throw new ForbiddenException('Owner account cannot be deactivated');
    }

    await this.prisma.user.update({
      where: { id: staffId },
      data: { isActive: false },
    });

    return { message: 'Staff member account revoked successfully' };
  }
}

