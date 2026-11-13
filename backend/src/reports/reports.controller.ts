import {
  Controller,
  Get,
  Header,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ReportsService } from './reports.service.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/reports')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('today-overview')
  @RequirePermissions(Permission.VIEW_SALES_REPORTS)
  async getTodayOverview(@CurrentUser() user: CurrentUserPayload) {
    return this.reportsService.getTodayOverview(user.shopId);
  }

  @Get('sales-profit-summary')
  @RequirePermissions(Permission.VIEW_SALES_REPORTS)
  async getSalesAndProfitSummary(
    @CurrentUser() user: CurrentUserPayload,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.reportsService.getSalesAndProfitSummary(user.shopId, {
      startDate,
      endDate,
    });
  }

  @Get('inventory-report')
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async getInventoryReport(@CurrentUser() user: CurrentUserPayload) {
    return this.reportsService.getInventoryReport(user.shopId);
  }

  @Get('export/sales-csv')
  @RequirePermissions(Permission.VIEW_SALES_REPORTS)
  @Header('Content-Type', 'text/csv')
  @Header('Content-Disposition', 'attachment; filename="sales_report.csv"')
  async exportSalesCsv(
    @CurrentUser() user: CurrentUserPayload,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Res() res?: any,
  ) {
    const csv = await this.reportsService.exportSalesCsv(user.shopId, {
      startDate,
      endDate,
    });
    res?.send(csv);
  }

  @Get('export/inventory-csv')
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  @Header('Content-Type', 'text/csv')
  @Header('Content-Disposition', 'attachment; filename="inventory_report.csv"')
  async exportInventoryCsv(
    @CurrentUser() user: CurrentUserPayload,
    @Res() res?: any,
  ) {
    const csv = await this.reportsService.exportInventoryCsv(user.shopId);
    res?.send(csv);
  }
}
