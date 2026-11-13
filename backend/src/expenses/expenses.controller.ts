import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ExpensesService } from './expenses.service.js';
import { CreateExpenseDto } from './dto/create-expense.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/expenses')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  @RequirePermissions(Permission.SHOP_SETTINGS)
  async createExpense(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateExpenseDto,
  ) {
    return this.expensesService.createExpense(user.shopId, user.userId, dto);
  }

  @Get()
  @RequirePermissions(Permission.VIEW_PROFIT_REPORTS)
  async listExpenses(
    @CurrentUser() user: CurrentUserPayload,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.expensesService.listExpenses(user.shopId, { startDate, endDate });
  }

  @Delete(':id')
  @RequirePermissions(Permission.SHOP_SETTINGS)
  async deleteExpense(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') expenseId: string,
  ) {
    return this.expensesService.deleteExpense(user.shopId, expenseId);
  }
}

