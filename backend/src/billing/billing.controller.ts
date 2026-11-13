import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { BillingService } from './billing.service.js';
import { CreateBillDto } from './dto/create-bill.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/billing')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Post()
  @RequirePermissions(Permission.CREATE_BILLS)
  async createBill(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateBillDto,
  ) {
    return this.billingService.createBill(user.shopId, user.userId, dto);
  }

  @Get()
  @RequirePermissions(Permission.VIEW_SALES_REPORTS)
  async listBills(
    @CurrentUser() user: CurrentUserPayload,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.billingService.listBills(user.shopId, {
      startDate,
      endDate,
      status,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    });
  }

  @Get(':id')
  @RequirePermissions(Permission.CREATE_BILLS)
  async getBill(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') billId: string,
  ) {
    return this.billingService.getBill(user.shopId, billId);
  }

  @Post(':id/reprint')
  @RequirePermissions(Permission.CREATE_BILLS)
  async reprintBill(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') billId: string,
  ) {
    return this.billingService.reprintBill(user.shopId, billId);
  }

  @Post(':id/void')
  @RequirePermissions(Permission.SHOP_SETTINGS)
  async voidBill(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') billId: string,
    @Body('reason') reason: string,
  ) {
    return this.billingService.voidBill(
      user.shopId,
      user.userId,
      billId,
      reason || 'Owner voided',
    );
  }
}

