import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InventoryService } from './inventory.service.js';
import { AdjustStockDto } from './dto/adjust-stock.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/inventory')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Post('adjust')
  @RequirePermissions(Permission.UPDATE_STOCK)
  async adjustStock(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: AdjustStockDto,
  ) {
    return this.inventoryService.adjustStock(user.shopId, user.userId, dto);
  }

  @Get('movements')
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async getMovements(
    @CurrentUser() user: CurrentUserPayload,
    @Query('productId') productId?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.inventoryService.getStockMovements(user.shopId, {
      productId,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    });
  }

  @Get('summary')
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async getSummary(@CurrentUser() user: CurrentUserPayload) {
    return this.inventoryService.getInventorySummary(user.shopId);
  }
}

