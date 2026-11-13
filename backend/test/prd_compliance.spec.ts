import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { AppModule } from '../src/app.module.js';
import { AuthService } from '../src/auth/auth.service.js';
import { ProductsService } from '../src/products/products.service.js';
import { BillingService } from '../src/billing/billing.service.js';
import { InventoryService } from '../src/inventory/inventory.service.js';
import { ReportsService } from '../src/reports/reports.service.js';
import { ExpensesService } from '../src/expenses/expenses.service.js';
import { StaffService } from '../src/staff/staff.service.js';
import { PrismaService } from '../src/common/prisma/prisma.service.js';
import { Permission } from '../src/common/constants/permissions.constant.js';

describe('PRD v0.2 Comprehensive Regression & Integration Test Suite', () => {
  let app: TestingModule;
  let authService: AuthService;
  let productsService: ProductsService;
  let billingService: BillingService;
  let inventoryService: InventoryService;
  let reportsService: ReportsService;
  let expensesService: ExpensesService;
  let staffService: StaffService;
  let prisma: PrismaService;

  let testShopId: string;
  let secondShopId: string;
  let ownerId: string;
  let cashierId: string;
  let testProductId: string;

  beforeAll(async () => {
    app = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    authService = app.get<AuthService>(AuthService);
    productsService = app.get<ProductsService>(ProductsService);
    billingService = app.get<BillingService>(BillingService);
    inventoryService = app.get<InventoryService>(InventoryService);
    reportsService = app.get<ReportsService>(ReportsService);
    expensesService = app.get<ExpensesService>(ExpensesService);
    staffService = app.get<StaffService>(StaffService);
    prisma = app.get<PrismaService>(PrismaService);

    // 1. Setup primary isolated test shop
    const testUsername = `owner_reg_${Date.now()}`;
    const registerRes = await authService.registerShop({
      shopName: 'Test Corner Store',
      ownerFullName: 'Test Owner',
      username: testUsername,
      password: 'password123',
      currency: '₹',
    });
    testShopId = registerRes.shop.id;
    ownerId = registerRes.user.id;

    // Configure shop tax percentage to 5% (PRD §5.1)
    await prisma.shop.update({
      where: { id: testShopId },
      data: { taxPercentage: 5.0 },
    });

    // 2. Setup secondary shop for cross-shop isolation verification (PRD §5.9)
    const secondUsername = `owner_sec_${Date.now()}`;
    const secondReg = await authService.registerShop({
      shopName: 'Secondary Isolated Shop',
      ownerFullName: 'Second Owner',
      username: secondUsername,
      password: 'password123',
      currency: '₹',
    });
    secondShopId = secondReg.shop.id;

    // 3. Create staff account in Shop 1 with only CREATE_BILLS & VIEW_PRODUCTS (PRD §4.1/4.2)
    const staffMember = await staffService.createStaff(testShopId, {
      fullName: 'Test Cashier',
      username: `cashier_${Date.now()}`,
      password: 'password123',
      permissions: [Permission.CREATE_BILLS, Permission.VIEW_PRODUCTS],
    });
    cashierId = staffMember.id;

    // 4. Create primary test product: cost 50, price 80, stock 30, threshold 5 (PRD §5.2)
    const prod = await productsService.createProduct(testShopId, ownerId, {
      name: 'Organic Wheat Flour 1kg',
      unit: 'packet',
      category: 'Grains',
      purchaseCost: 50.0,
      sellingPrice: 80.0,
      openingStock: 30.0,
      lowStockThreshold: 5.0,
    });
    testProductId = prod.id;
  });

  afterAll(async () => {
    await prisma.shop.deleteMany({
      where: { id: { in: [testShopId, secondShopId] } },
    });
    await app.close();
  });

  it('1. Staff Permission Enforcement & Protected Owner (PRD §4.1 & §4.2)', async () => {
    const ownerProfile = await authService.getCurrentUser(ownerId);
    expect(ownerProfile.user.isOwner).toBe(true);
    expect(ownerProfile.user.permissions).toContain(Permission.SHOP_SETTINGS);

    const cashierProfile = await authService.getCurrentUser(cashierId);
    expect(cashierProfile.user.isOwner).toBe(false);
    expect(cashierProfile.user.permissions).toContain(Permission.CREATE_BILLS);
    expect(cashierProfile.user.permissions).not.toContain(Permission.VIEW_PROFIT_REPORTS);
    expect(cashierProfile.user.permissions).not.toContain(Permission.MANAGE_STAFF);

    // Verify Owner Account cannot be revoked or altered by anyone (PRD §4.2)
    await expect(
      staffService.updateStaff(testShopId, ownerId, { isActive: false }),
    ).rejects.toThrow();
  });

  it('2. Cross-Shop Data Isolation (PRD §5.9 & §10.1)', async () => {
    // Attempt to access Shop 1 product using Shop 2 ID must fail with 404
    await expect(
      productsService.getProduct(secondShopId, testProductId),
    ).rejects.toThrow();

    // Attempt to bill Shop 1 product from Shop 2 must fail
    await expect(
      billingService.createBill(secondShopId, cashierId, {
        items: [{ productId: testProductId, quantity: 1 }],
      }),
    ).rejects.toThrow();
  });

  it('3. Stock Adjustment Edge Cases & Negative Stock Prevention (PRD §5.2)', async () => {
    // Edge case A: Reducing more than available stock must be rejected
    await expect(
      inventoryService.adjustStock(testShopId, ownerId, {
        productId: testProductId,
        quantityChange: -35.0, // Stock is 30
        movementType: 'DAMAGED' as any,
        reason: 'Large damage test',
      }),
    ).rejects.toThrow();

    // Edge case B: Valid reduction to exact threshold boundary (30 - 25 = 5)
    const result = await inventoryService.adjustStock(testShopId, ownerId, {
      productId: testProductId,
      quantityChange: -25.0,
      movementType: 'CORRECTION' as any,
      reason: 'Physical inventory audit',
    });

    expect(result.product.currentStock).toBe(5.0);
    expect(result.product.isLowStock).toBe(true);

    // Check stock movement audit ledger was recorded
    const movements = await inventoryService.getStockMovements(testShopId, {
      productId: testProductId,
    });
    expect(movements.total).toBeGreaterThanOrEqual(2); // OPENING_STOCK + CORRECTION
  });

  it('4. Low-Stock Alert Generation and Resolution (PRD §5.6 & §7.3)', async () => {
    // Since stock reached threshold 5, active alert must exist
    const alertsBefore = await prisma.lowStockAlert.findMany({
      where: { shopId: testShopId, productId: testProductId, status: 'ACTIVE' },
    });
    expect(alertsBefore.length).toBe(1);

    // Replenish stock above threshold (5 + 10 = 15 > 5)
    await inventoryService.adjustStock(testShopId, ownerId, {
      productId: testProductId,
      quantityChange: 10.0,
      movementType: 'RESTOCK' as any,
      reason: 'Shipment received',
    });

    // Alert must now be automatically marked RESOLVED (PRD §7.3)
    const activeAlertsAfter = await prisma.lowStockAlert.findMany({
      where: { shopId: testShopId, productId: testProductId, status: 'ACTIVE' },
    });
    expect(activeAlertsAfter.length).toBe(0);

    const resolvedAlerts = await prisma.lowStockAlert.findMany({
      where: { shopId: testShopId, productId: testProductId, status: 'RESOLVED' },
    });
    expect(resolvedAlerts.length).toBe(1);
  });

  it('5. Discount, Tax and Gross Profit Arithmetic (PRD §5.3, §5.5 & §8)', async () => {
    // Current stock is 15. Price = 80, Cost = 50.
    // Bill: 3 units @ 80 = 240 subtotal.
    // Discount = 20.
    // Taxable amount = 240 - 20 = 220.
    // Tax (5%) = 220 * 0.05 = 11.00.
    // Final total = 220 + 11 = 231.00.
    // Cost basis = 3 * 50 = 150.00.
    // Estimated Gross Profit = 240 - 20 - 150 = 70.00.
    const bill = await billingService.createBill(testShopId, cashierId, {
      items: [{ productId: testProductId, quantity: 3 }],
      discountAmount: 20.0,
      notes: 'Customer loyalty discount',
      idempotencyKey: `calc_test_${Date.now()}`,
    });

    expect(bill.subtotal).toBe(240.0);
    expect(bill.discountAmount).toBe(20.0);
    expect(bill.taxAmount).toBe(11.0);
    expect(bill.finalTotal).toBe(231.0);
    expect(bill.totalCostBasis).toBe(150.0);
    expect(bill.estimatedGrossProfit).toBe(70.0);

    // Stock reduced by 3 (15 - 3 = 12)
    const prod = await productsService.getProduct(testShopId, testProductId);
    expect(prod.currentStock).toBe(12.0);
  });

  it('6. Concurrent Bill Submissions & Stock Consistency (PRD §9.3 & §10.1)', async () => {
    // Submit 2 bills concurrently each requesting 2 units
    const bill1Promise = billingService.createBill(testShopId, cashierId, {
      items: [{ productId: testProductId, quantity: 2 }],
      idempotencyKey: `concurrent_1_${Date.now()}`,
    });

    const bill2Promise = billingService.createBill(testShopId, cashierId, {
      items: [{ productId: testProductId, quantity: 2 }],
      idempotencyKey: `concurrent_2_${Date.now()}`,
    });

    const [b1, b2] = await Promise.all([bill1Promise, bill2Promise]);

    expect(b1.status).toBe('COMPLETED');
    expect(b2.status).toBe('COMPLETED');
    expect(b1.billNumber).not.toBe(b2.billNumber);

    // Stock was 12; after 2 + 2 = 4 units deducted, stock must be exactly 8
    const prod = await productsService.getProduct(testShopId, testProductId);
    expect(prod.currentStock).toBe(8.0);
  });

  it('7. Idempotency Key Duplicate Submission (PRD §9.3 & §10.4)', async () => {
    const key = `idem_reg_${Date.now()}`;

    const submission1 = await billingService.createBill(testShopId, cashierId, {
      items: [{ productId: testProductId, quantity: 1 }],
      idempotencyKey: key,
    });

    const stockAfter1 = (await productsService.getProduct(testShopId, testProductId)).currentStock; // 8 - 1 = 7

    // Resubmit with exact same key
    const submission2 = await billingService.createBill(testShopId, cashierId, {
      items: [{ productId: testProductId, quantity: 1 }],
      idempotencyKey: key,
    });

    expect(submission2.id).toBe(submission1.id);
    expect(submission2.billNumber).toBe(submission1.billNumber);

    // Stock must not be deducted a second time
    const stockAfterRetry = (await productsService.getProduct(testShopId, testProductId)).currentStock;
    expect(stockAfterRetry).toBe(stockAfter1);
  });

  it('8. Expense Recording & Operating Result Calculation (PRD §5.7)', async () => {
    // Record shop rent expense
    const expense = await expensesService.createExpense(testShopId, ownerId, {
      title: 'Store Rent',
      category: 'RENT',
      amount: 50.0,
      notes: 'Monthly rent portion',
    });

    expect(expense.id).toBeDefined();
    expect(expense.amount).toBe(50.0);

    const summary = await reportsService.getSalesAndProfitSummary(testShopId);
    expect(summary.operatingResult.hasRecordedExpenses).toBe(true);
    expect(summary.operatingResult.totalExpenses).toBeGreaterThanOrEqual(50.0);
    expect(summary.operatingResult.estimatedOperatingResult).toBeDefined();
    // Operating result = Gross profit - Total expenses
    const expectedOperatingResult = Number((summary.summary.estimatedGrossProfit - summary.operatingResult.totalExpenses).toFixed(2));
    expect(summary.operatingResult.estimatedOperatingResult).toBe(expectedOperatingResult);
  });

  it('9. CSV Export Formatting & RFC Compliance (PRD §5.8)', async () => {
    const salesCsv = await reportsService.exportSalesCsv(testShopId);
    expect(salesCsv).toContain('Product Name');
    expect(salesCsv).toContain('Quantity Sold');
    expect(salesCsv).toContain('Estimated Gross Profit');
    expect(salesCsv).toContain('SUMMARY METRICS');

    const invCsv = await reportsService.exportInventoryCsv(testShopId);
    expect(invCsv).toContain('Product Name');
    expect(invCsv).toContain('Current Stock');
    expect(invCsv).toContain('Stock Valuation (Cost)');
  });
});
