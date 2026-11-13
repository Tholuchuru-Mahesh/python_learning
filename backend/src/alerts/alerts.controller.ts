import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { AlertsService } from './alerts.service.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/alerts')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class AlertsController {
  constructor(private readonly alertsService: AlertsService) {}

  @Get()
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async listActiveAlerts(@CurrentUser() user: CurrentUserPayload) {
    return this.alertsService.listActiveAlerts(user.shopId);
  }

  @Post(':id/acknowledge')
  @RequirePermissions(Permission.UPDATE_STOCK)
  async acknowledgeAlert(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') alertId: string,
  ) {
    return this.alertsService.acknowledgeAlert(user.shopId, alertId);
  }
}

