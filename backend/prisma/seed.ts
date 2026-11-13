import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { ALL_PERMISSIONS, Permission } from '../src/common/constants/permissions.constant.js';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding initial retail shop data according to PRD v0.2 specifications...');

  // 1. Clean existing data
  await prisma.lowStockAlert.deleteMany();
  await prisma.stockMovement.deleteMany();
  await prisma.billItem.deleteMany();
  await prisma.bill.deleteMany();
  await prisma.expense.deleteMany();
  await prisma.product.deleteMany();
  await prisma.user.deleteMany();
  await prisma.shop.deleteMany();

  // 2. Create Shop (PRD §5.1)
  const shop = await prisma.shop.create({
    data: {
      name: 'City Supermarket & Provisions',
      address: '128 Market Road, Downtown',
      phone: '+91 98765 43210',
      currency: '₹',
      taxPercentage: 5.0,
      receiptHeader: 'City Supermarket & Provisions\nQuality Groceries at Honest Prices',
      receiptFooter: 'Thank you for shopping with us!\nVisit again soon.',
    },
  });

  const passwordHash = await bcrypt.hash('password123', 10);

  // 3. Create Owner Account (PRD §4.1)
  const owner = await prisma.user.create({
    data: {
      shopId: shop.id,
      fullName: 'Ramesh Sharma',
      username: 'owner',
      passwordHash,
      isOwner: true,
      isActive: true,
      permissions: JSON.stringify(ALL_PERMISSIONS),
    },
  });

  // 4. Create Staff Cashier Account with specific checkbox permissions (PRD §4.1/4.2)
  const cashierPermissions = [
    Permission.CREATE_BILLS,
    Permission.VIEW_PRODUCTS,
  ];

  const cashier = await prisma.user.create({
    data: {
      shopId: shop.id,
      fullName: 'Priya Patel',
      username: 'cashier',
      passwordHash,
      isOwner: false,
      isActive: true,
      permissions: JSON.stringify(cashierPermissions),
    },
  });

  // 5. Create Staff Inventory Clerk with specific checkbox permissions (PRD §4.2)
  const stockClerkPermissions = [
    Permission.VIEW_PRODUCTS,
    Permission.ADD_EDIT_PRODUCTS,
    Permission.UPDATE_STOCK,
  ];

  await prisma.user.create({
    data: {
      shopId: shop.id,
      fullName: 'Vikram Singh',
      username: 'inventory',
      passwordHash,
      isOwner: false,
      isActive: true,
      permissions: JSON.stringify(stockClerkPermissions),
    },
  });

  // 6. Create Products with multiple common retail units (PRD §5.2)
  const productsData = [
    {
      name: 'Fresh Mineral Water 1L',
      category: 'Beverages',
      unit: 'bottle',
      purchaseCost: 12.0,
      sellingPrice: 20.0,
      currentStock: 100,
      lowStockThreshold: 25, // PRD §5.6 example: 100 stock, 25 threshold
    },
    {
      name: 'Premium Basmati Rice',
      category: 'Grains & Staples',
      unit: 'kg',
      purchaseCost: 85.0,
      sellingPrice: 120.0,
      currentStock: 50,
      lowStockThreshold: 15,
    },
    {
      name: 'Full Cream Milk 500ml',
      category: 'Dairy',
      unit: 'packet',
      purchaseCost: 28.0,
      sellingPrice: 34.0,
      currentStock: 40,
      lowStockThreshold: 10,
    },
    {
      name: 'Refined Sunflower Oil 1L',
      category: 'Cooking Essentials',
      unit: 'litre',
      purchaseCost: 110.0,
      sellingPrice: 145.0,
      currentStock: 30,
      lowStockThreshold: 8,
    },
    {
      name: 'Organic Brown Eggs (6 pack)',
      category: 'Dairy',
      unit: 'packet',
      purchaseCost: 45.0,
      sellingPrice: 65.0,
      currentStock: 25,
      lowStockThreshold: 5,
    },
    {
      name: 'Whole Wheat Bread 400g',
      category: 'Bakery',
      unit: 'packet',
      purchaseCost: 30.0,
      sellingPrice: 45.0,
      currentStock: 4, // Trigger low stock (< threshold 10)
      lowStockThreshold: 10,
    },
    {
      name: 'Washing Powder 1kg',
      category: 'Household',
      unit: 'packet',
      purchaseCost: 95.0,
      sellingPrice: 140.0,
      currentStock: 20,
      lowStockThreshold: 5,
    },
    {
      name: 'Dark Chocolate Bar 100g',
      category: 'Confectionery',
      unit: 'piece',
      purchaseCost: 60.0,
      sellingPrice: 90.0,
      currentStock: 50,
      lowStockThreshold: 12,
    },
  ];

  const createdProducts = [];
  for (const p of productsData) {
    const product = await prisma.product.create({
      data: {
        shopId: shop.id,
        name: p.name,
        category: p.category,
        unit: p.unit,
        purchaseCost: p.purchaseCost,
        sellingPrice: p.sellingPrice,
        currentStock: p.currentStock,
        lowStockThreshold: p.lowStockThreshold,
        isActive: true,
      },
    });

    // Opening stock record
    await prisma.stockMovement.create({
      data: {
        shopId: shop.id,
        productId: product.id,
        userId: owner.id,
        movementType: 'OPENING_STOCK',
        quantityChange: p.currentStock,
        previousStock: 0,
        newStock: p.currentStock,
        reason: 'Initial shop opening inventory',
      },
    });

    // Check low stock
    if (p.currentStock <= p.lowStockThreshold) {
      await prisma.lowStockAlert.create({
        data: {
          shopId: shop.id,
          productId: product.id,
          currentStockSnapshot: p.currentStock,
          thresholdSnapshot: p.lowStockThreshold,
          status: 'ACTIVE',
        },
      });
    }

    createdProducts.push(product);
  }

  // 7. Seed Initial Sample Completed Bills (PRD §5.3)
  const pWater = createdProducts[0];
  const pRice = createdProducts[1];
  const pMilk = createdProducts[2];

  const item1Total = 2 * Number(pWater.sellingPrice); // 40
  const item1Cost = 2 * Number(pWater.purchaseCost); // 24
  const item2Total = 1 * Number(pMilk.sellingPrice); // 34
  const item2Cost = 1 * Number(pMilk.purchaseCost); // 28
  const subtotal1 = item1Total + item2Total; // 74
  const discount1 = 0;
  const tax1 = Number(((subtotal1 * 5) / 100).toFixed(2)); // 3.70
  const finalTotal1 = subtotal1 + tax1; // 77.70
  const profit1 = subtotal1 - (item1Cost + item2Cost); // 74 - 52 = 22

  const bill1 = await prisma.bill.create({
    data: {
      shopId: shop.id,
      staffId: cashier.id,
      billNumber: 'BILL-20261113-0001',
      idempotencyKey: 'seed-bill-uuid-1',
      subtotal: subtotal1,
      discountAmount: discount1,
      taxAmount: tax1,
      finalTotal: finalTotal1,
      totalCostBasis: item1Cost + item2Cost,
      estimatedGrossProfit: profit1,
      status: 'COMPLETED',
      reprintCount: 0,
      createdAt: new Date(),
    },
  });

  await prisma.billItem.createMany({
    data: [
      {
        billId: bill1.id,
        productId: pWater.id,
        productNameSnapshot: pWater.name,
        unitSnapshot: pWater.unit,
        quantity: 2,
        unitPriceSnapshot: pWater.sellingPrice,
        unitCostSnapshot: pWater.purchaseCost,
        lineTotal: item1Total,
        lineProfit: item1Total - item1Cost,
      },
      {
        billId: bill1.id,
        productId: pMilk.id,
        productNameSnapshot: pMilk.name,
        unitSnapshot: pMilk.unit,
        quantity: 1,
        unitPriceSnapshot: pMilk.sellingPrice,
        unitCostSnapshot: pMilk.purchaseCost,
        lineTotal: item2Total,
        lineProfit: item2Total - item2Cost,
      },
    ],
  });

  // Record stock deductions for seed bill
  await prisma.stockMovement.createMany({
    data: [
      {
        shopId: shop.id,
        productId: pWater.id,
        userId: cashier.id,
        billId: bill1.id,
        movementType: 'SALE',
        quantityChange: -2,
        previousStock: 100,
        newStock: 98,
        reason: 'Bill #BILL-20261113-0001',
      },
      {
        shopId: shop.id,
        productId: pMilk.id,
        userId: cashier.id,
        billId: bill1.id,
        movementType: 'SALE',
        quantityChange: -1,
        previousStock: 40,
        newStock: 39,
        reason: 'Bill #BILL-20261113-0001',
      },
    ],
  });

  await prisma.product.update({
    where: { id: pWater.id },
    data: { currentStock: 98 },
  });
  await prisma.product.update({
    where: { id: pMilk.id },
    data: { currentStock: 39 },
  });

  // 8. Seed Sample Simple Expenses (PRD §5.7)
  await prisma.expense.createMany({
    data: [
      {
        shopId: shop.id,
        userId: owner.id,
        title: 'Packaging Bags & Receipt Rolls',
        category: 'PACKAGING',
        amount: 350.0,
        expenseDate: new Date(),
        notes: 'Monthly bulk paper bags and 80mm thermal rolls',
      },
      {
        shopId: shop.id,
        userId: owner.id,
        title: 'Electricity Bill',
        category: 'UTILITY',
        amount: 1200.0,
        expenseDate: new Date(),
        notes: 'Shop lighting and refrigeration power',
      },
    ],
  });

  console.log('Seed completed successfully!');
  console.log('--- Default Login Credentials ---');
  console.log('Owner Account: username "owner", password "password123"');
  console.log('Cashier Account: username "cashier", password "password123"');
  console.log('Inventory Account: username "inventory", password "password123"');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

