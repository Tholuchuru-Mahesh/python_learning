import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { StaffService } from './staff.service.js';
import { CreateStaffDto } from './dto/create-staff.dto.js';
import { UpdateStaffDto } from './dto/update-staff-permissions.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/staff')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class StaffController {
  constructor(private readonly staffService: StaffService) {}

  @Get()
  @RequirePermissions(Permission.MANAGE_STAFF)
  async listStaff(@CurrentUser() user: CurrentUserPayload) {
    return this.staffService.listStaff(user.shopId);
  }

  @Post()
  @RequirePermissions(Permission.MANAGE_STAFF)
  async createStaff(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateStaffDto,
  ) {
    return this.staffService.createStaff(user.shopId, dto);
  }

  @Put(':id')
  @RequirePermissions(Permission.MANAGE_STAFF)
  async updateStaff(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') staffId: string,
    @Body() dto: UpdateStaffDto,
  ) {
    return this.staffService.updateStaff(user.shopId, staffId, dto);
  }

  @Delete(':id')
  @RequirePermissions(Permission.MANAGE_STAFF)
  async revokeStaff(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') staffId: string,
  ) {
    return this.staffService.revokeStaff(user.shopId, staffId);
  }
}

