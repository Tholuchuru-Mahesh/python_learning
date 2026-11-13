import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ShopService } from './shop.service.js';
import { UpdateShopDto } from './dto/update-shop.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/shop')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ShopController {
  constructor(private readonly shopService: ShopService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: CurrentUserPayload) {
    return this.shopService.getShopProfile(user.shopId);
  }

  @Put('profile')
  @RequirePermissions(Permission.SHOP_SETTINGS)
  async updateProfile(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: UpdateShopDto,
  ) {
    return this.shopService.updateShopProfile(user.shopId, dto);
  }
}

