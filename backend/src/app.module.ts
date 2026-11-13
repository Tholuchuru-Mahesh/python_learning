import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './common/prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { ShopModule } from './shop/shop.module.js';
import { StaffModule } from './staff/staff.module.js';
import { ProductsModule } from './products/products.module.js';
import { InventoryModule } from './inventory/inventory.module.js';
import { BillingModule } from './billing/billing.module.js';
import { AlertsModule } from './alerts/alerts.module.js';
import { ExpensesModule } from './expenses/expenses.module.js';
import { ReportsModule } from './reports/reports.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    ShopModule,
    StaffModule,
    ProductsModule,
    InventoryModule,
    BillingModule,
    AlertsModule,
    ExpensesModule,
    ReportsModule,
  ],
})
export class AppModule {}
