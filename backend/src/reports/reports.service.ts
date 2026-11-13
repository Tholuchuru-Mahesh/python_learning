import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async getTodayOverview(shopId: string) {
    const now = new Date();
    const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const billsToday = await this.prisma.bill.findMany({
      where: {
        shopId,
        status: 'COMPLETED',
        createdAt: { gte: dayStart, lte: dayEnd },
      },
      include: {
        items: true,
      },
    });

    const totalSalesValue = billsToday.reduce(
      (sum, b) => sum + Number(b.finalTotal),
      0,
    );
    const totalBillsCount = billsToday.length;

    // Aggregate product metrics for today
    const productStats = new Map<
      string,
      {
        name: string;
        unit: string;
        quantity: number;
        revenue: number;
      }
    >();

    for (const b of billsToday) {
      for (const item of b.items) {
        const existing = productStats.get(item.productId) || {
          name: item.productNameSnapshot,
          unit: item.unitSnapshot,
          quantity: 0,
          revenue: 0,
        };
        existing.quantity += Number(item.quantity);
        existing.revenue += Number(item.lineTotal);
        productStats.set(item.productId, existing);
      }
    }

    const items = Array.from(productStats.values());

    // Best-selling product by quantity (PRD §5.4)
    const topByQuantity = [...items].sort((a, b) => b.quantity - a.quantity)[0] || null;

    // Highest-revenue product (PRD §5.4: strictly separate from quantity ranking)
    const topByRevenue = [...items].sort((a, b) => b.revenue - a.revenue)[0] || null;

    return {
      date: dayStart.toISOString().slice(0, 10),
      todaySalesValue: Number(totalSalesValue.toFixed(2)),
      todayBillsCount: totalBillsCount,
      topSellingProductByQuantity: topByQuantity
        ? {
            name: topByQuantity.name,
            quantity: Number(topByQuantity.quantity.toFixed(3)),
            unit: topByQuantity.unit,
          }
        : null,
      topRevenueProduct: topByRevenue
        ? {
            name: topByRevenue.name,
            revenue: Number(topByRevenue.revenue.toFixed(2)),
            unit: topByRevenue.unit,
          }
        : null,
    };
  }

  async getSalesAndProfitSummary(
    shopId: string,
    params?: { startDate?: string; endDate?: string },
  ) {
    const where: any = {
      shopId,
      status: 'COMPLETED',
    };

    let start: Date;
    let end: Date;

    if (params?.startDate) {
      start = new Date(params.startDate);
    } else {
      // Default to last 30 days
      start = new Date();
      start.setDate(start.getDate() - 30);
      start.setHours(0, 0, 0, 0);
    }

    if (params?.endDate) {
      end = new Date(params.endDate);
      end.setHours(23, 59, 59, 999);
    } else {
      end = new Date();
      end.setHours(23, 59, 59, 999);
    }

    where.createdAt = { gte: start, lte: end };

    const [bills, expenses] = await Promise.all([
      this.prisma.bill.findMany({
        where,
        include: { items: true },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.expense.findMany({
        where: {
          shopId,
          expenseDate: { gte: start, lte: end },
        },
      }),
    ]);

    let totalRevenue = 0;
    let totalCostBasis = 0;
    let totalDiscountAmount = 0;
    let totalTaxAmount = 0;
    let totalUnitsSold = 0;

    const productMap = new Map<
      string,
      {
        productId: string;
        name: string;
        unit: string;
        quantitySold: number;
        salesValue: number;
        costBasis: number;
        estimatedGrossProfit: number;
      }
    >();

    for (const b of bills) {
      totalRevenue += Number(b.finalTotal);
      totalCostBasis += Number(b.totalCostBasis);
      totalDiscountAmount += Number(b.discountAmount);
      totalTaxAmount += Number(b.taxAmount);

      for (const item of b.items) {
        const qty = Number(item.quantity);
        const lineTotal = Number(item.lineTotal);
        const lineCost = Number(item.unitCostSnapshot) * qty;
        const lineProfit = lineTotal - lineCost;

        totalUnitsSold += qty;

        const stat = productMap.get(item.productId) || {
          productId: item.productId,
          name: item.productNameSnapshot,
          unit: item.unitSnapshot,
          quantitySold: 0,
          salesValue: 0,
          costBasis: 0,
          estimatedGrossProfit: 0,
        };

        stat.quantitySold += qty;
        stat.salesValue += lineTotal;
        stat.costBasis += lineCost;
        stat.estimatedGrossProfit += lineProfit;
        productMap.set(item.productId, stat);
      }
    }

    const estimatedGrossProfit = Number(
      bills.reduce((sum, b) => sum + Number(b.estimatedGrossProfit), 0).toFixed(2),
    );

    const grossMarginPercentage =
      totalRevenue > 0
        ? Number(((estimatedGrossProfit / totalRevenue) * 100).toFixed(2))
        : 0;

    const totalExpenses = Number(
      expenses.reduce((sum, e) => sum + Number(e.amount), 0).toFixed(2),
    );

    // PRD §5.7: Operating result estimate
    const estimatedOperatingResult =
      expenses.length > 0
        ? Number((estimatedGrossProfit - totalExpenses).toFixed(2))
        : null;

    const productPerformance = Array.from(productMap.values()).map((p) => ({
      productId: p.productId,
      name: p.name,
      unit: p.unit,
      quantitySold: Number(p.quantitySold.toFixed(3)),
      salesValue: Number(p.salesValue.toFixed(2)),
      costBasis: Number(p.costBasis.toFixed(2)),
      estimatedGrossProfit: Number(p.estimatedGrossProfit.toFixed(2)),
      grossMarginPercentage:
        p.salesValue > 0
          ? Number(((p.estimatedGrossProfit / p.salesValue) * 100).toFixed(2))
          : 0,
    }));

    return {
      period: {
        startDate: start.toISOString().slice(0, 10),
        endDate: end.toISOString().slice(0, 10),
      },
      summary: {
        totalBillsCount: bills.length,
        totalUnitsSold: Number(totalUnitsSold.toFixed(3)),
        totalRevenue: Number(totalRevenue.toFixed(2)),
        totalCostBasis: Number(totalCostBasis.toFixed(2)),
        totalDiscountAmount: Number(totalDiscountAmount.toFixed(2)),
        totalTaxAmount: Number(totalTaxAmount.toFixed(2)),
        estimatedGrossProfit,
        grossMarginPercentage,
      },
      operatingResult: {
        totalExpenses,
        hasRecordedExpenses: expenses.length > 0,
        estimatedOperatingResult, // Null if no expenses recorded (PRD §5.7)
      },
      productPerformance: productPerformance.sort((a, b) => b.salesValue - a.salesValue),
    };
  }

  async getInventoryReport(shopId: string) {
    const products = await this.prisma.product.findMany({
      where: { shopId, isActive: true },
      orderBy: { name: 'asc' },
    });

    return products.map((p) => {
      const stock = Number(p.currentStock);
      const cost = Number(p.purchaseCost);
      const price = Number(p.sellingPrice);
      const threshold = Number(p.lowStockThreshold);

      return {
        id: p.id,
        name: p.name,
        category: p.category,
        unit: p.unit,
        currentStock: stock,
        lowStockThreshold: threshold,
        isLowStock: stock <= threshold,
        purchaseCost: cost,
        sellingPrice: price,
        stockCostValue: Number((stock * cost).toFixed(2)),
        stockRetailValue: Number((stock * price).toFixed(2)),
      };
    });
  }

  async exportSalesCsv(
    shopId: string,
    params?: { startDate?: string; endDate?: string },
  ): Promise<string> {
    const data = await this.getSalesAndProfitSummary(shopId, params);

    const headers = [
      'Product Name',
      'Unit',
      'Quantity Sold',
      'Sales Value',
      'Cost Basis',
      'Estimated Gross Profit',
      'Gross Margin %',
    ];

    const rows = data.productPerformance.map((p) => [
      `"${p.name.replace(/"/g, '""')}"`,
      `"${p.unit}"`,
      p.quantitySold,
      p.salesValue,
      p.costBasis,
      p.estimatedGrossProfit,
      `${p.grossMarginPercentage}%`,
    ]);

    const summaryRows = [
      [],
      ['SUMMARY METRICS', 'VALUE'],
      ['Date Range', `${data.period.startDate} to ${data.period.endDate}`],
      ['Total Bills', data.summary.totalBillsCount],
      ['Total Units Sold', data.summary.totalUnitsSold],
      ['Total Sales Revenue', data.summary.totalRevenue],
      ['Total Cost Basis', data.summary.totalCostBasis],
      ['Total Discount', data.summary.totalDiscountAmount],
      ['Estimated Gross Profit', data.summary.estimatedGrossProfit],
      ['Gross Margin %', `${data.summary.grossMarginPercentage}%`],
      ['Total Recorded Expenses', data.operatingResult.totalExpenses],
      [
        'Estimated Operating Result',
        data.operatingResult.estimatedOperatingResult !== null
          ? data.operatingResult.estimatedOperatingResult
          : 'N/A (No expenses recorded)',
      ],
    ];

    return [
      headers.join(','),
      ...rows.map((r) => r.join(',')),
      ...summaryRows.map((r) => r.join(',')),
    ].join('\n');
  }

  async exportInventoryCsv(shopId: string): Promise<string> {
    const products = await this.getInventoryReport(shopId);

    const headers = [
      'Product Name',
      'Category',
      'Unit',
      'Current Stock',
      'Low Stock Threshold',
      'Low Stock Alert?',
      'Purchase Cost',
      'Selling Price',
      'Stock Valuation (Cost)',
      'Stock Valuation (Retail)',
    ];

    const rows = products.map((p) => [
      `"${p.name.replace(/"/g, '""')}"`,
      `"${p.category || 'General'}"`,
      `"${p.unit}"`,
      p.currentStock,
      p.lowStockThreshold,
      p.isLowStock ? 'YES' : 'NO',
      p.purchaseCost,
      p.sellingPrice,
      p.stockCostValue,
      p.stockRetailValue,
    ]);

    return [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
  }
}
