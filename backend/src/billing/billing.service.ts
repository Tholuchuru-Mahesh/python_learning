import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { CreateBillDto } from './dto/create-bill.dto.js';

@Injectable()
export class BillingService {
  constructor(private readonly prisma: PrismaService) {}

  async createBill(shopId: string, staffId: string, dto: CreateBillDto) {
    // 1. Idempotency Check (PRD §9.3 & §10.4): Prevent duplicate bills on network retry
    if (dto.idempotencyKey) {
      const existing = await this.prisma.bill.findUnique({
        where: { idempotencyKey: dto.idempotencyKey },
        include: {
          items: true,
          staff: { select: { id: true, fullName: true, username: true } },
          shop: true,
        },
      });

      if (existing) {
        if (existing.shopId !== shopId) {
          throw new BadRequestException('Idempotency key conflict');
        }
        return this.formatBillResponse(existing, false);
      }
    }

    // 2. Atomic Database Transaction (PRD §9.3)
    return this.prisma.$transaction(async (tx) => {
      // Fetch shop details for currency, tax rate, receipt info
      const shop = await tx.shop.findUnique({ where: { id: shopId } });
      if (!shop) {
        throw new NotFoundException('Shop not found');
      }

      // Fetch all products involved
      const productIds = dto.items.map((i) => i.productId);
      const products = await tx.product.findMany({
        where: { id: { in: productIds }, shopId },
      });

      if (products.length !== productIds.length) {
        throw new BadRequestException('One or more products were not found in this shop');
      }

      const productMap = new Map(products.map((p) => [p.id, p]));

      // Validate stock availability and calculate totals
      let subtotal = 0;
      let totalCostBasis = 0;

      const preparedItems: Array<{
        productId: string;
        productNameSnapshot: string;
        unitSnapshot: string;
        quantity: number;
        unitPriceSnapshot: number;
        unitCostSnapshot: number;
        lineTotal: number;
        lineProfit: number;
        prevStock: number;
        newStock: number;
        threshold: number;
      }> = [];

      for (const item of dto.items) {
        const prod = productMap.get(item.productId)!;
        if (!prod.isActive) {
          throw new BadRequestException(`Product '${prod.name}' is inactive`);
        }

        const currentStock = Number(prod.currentStock);
        if (currentStock < item.quantity) {
          throw new BadRequestException(
            `Insufficient stock for '${prod.name}'. Requested: ${item.quantity}, Available: ${currentStock}`,
          );
        }

        const unitPrice = item.unitPrice !== undefined ? item.unitPrice : Number(prod.sellingPrice);
        const unitCost = Number(prod.purchaseCost);
        const lineTotal = Number((item.quantity * unitPrice).toFixed(2));
        const lineCost = Number((item.quantity * unitCost).toFixed(2));
        const lineProfit = Number((lineTotal - lineCost).toFixed(2));

        subtotal += lineTotal;
        totalCostBasis += lineCost;

        preparedItems.push({
          productId: prod.id,
          productNameSnapshot: prod.name,
          unitSnapshot: prod.unit,
          quantity: item.quantity,
          unitPriceSnapshot: unitPrice,
          unitCostSnapshot: unitCost,
          lineTotal,
          lineProfit,
          prevStock: currentStock,
          newStock: currentStock - item.quantity,
          threshold: Number(prod.lowStockThreshold),
        });
      }

      const discountAmount = Math.min(dto.discountAmount ?? 0, subtotal);
      const taxableAmount = Math.max(0, subtotal - discountAmount);
      const taxRate = Number(shop.taxPercentage);
      const taxAmount = Number(((taxableAmount * taxRate) / 100).toFixed(2));
      const finalTotal = Number((subtotal - discountAmount + taxAmount).toFixed(2));
      const estimatedGrossProfit = Number((subtotal - discountAmount - totalCostBasis).toFixed(2));

      // Generate sequential bill number: BILL-YYYYMMDD-XXXX (PRD §5.3)
      const now = new Date();
      const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
      const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const countToday = await tx.bill.count({
        where: { shopId, createdAt: { gte: dayStart } },
      });
      const sequence = String(countToday + 1).padStart(4, '0');
      const billNumber = `BILL-${dateStr}-${sequence}`;

      // Create Bill
      const bill = await tx.bill.create({
        data: {
          shopId,
          staffId,
          billNumber,
          idempotencyKey: dto.idempotencyKey || null,
          subtotal,
          discountAmount,
          taxAmount,
          finalTotal,
          totalCostBasis,
          estimatedGrossProfit,
          status: 'COMPLETED',
          reprintCount: 0,
          notes: dto.notes,
        },
      });

      // Create Bill Items & Deduct Stock & Record Stock Movement
      for (const item of preparedItems) {
        // Save Bill Item snapshot (PRD §10.1)
        await tx.billItem.create({
          data: {
            billId: bill.id,
            productId: item.productId,
            productNameSnapshot: item.productNameSnapshot,
            unitSnapshot: item.unitSnapshot,
            quantity: item.quantity,
            unitPriceSnapshot: item.unitPriceSnapshot,
            unitCostSnapshot: item.unitCostSnapshot,
            lineTotal: item.lineTotal,
            lineProfit: item.lineProfit,
          },
        });

        // Deduct stock exactly once (PRD §5.3)
        await tx.product.update({
          where: { id: item.productId },
          data: { currentStock: item.newStock },
        });

        // Record stock movement (PRD §5.2 & §10.1)
        await tx.stockMovement.create({
          data: {
            shopId,
            productId: item.productId,
            userId: staffId,
            billId: bill.id,
            movementType: 'SALE',
            quantityChange: -item.quantity,
            previousStock: item.prevStock,
            newStock: item.newStock,
            reason: `Bill #${bill.billNumber}`,
          },
        });

        // Check low-stock alert threshold (PRD §5.6 & §7.3)
        if (item.newStock <= item.threshold) {
          const activeAlert = await tx.lowStockAlert.findFirst({
            where: { shopId, productId: item.productId, status: 'ACTIVE' },
          });

          if (!activeAlert) {
            await tx.lowStockAlert.create({
              data: {
                shopId,
                productId: item.productId,
                currentStockSnapshot: item.newStock,
                thresholdSnapshot: item.threshold,
                status: 'ACTIVE',
              },
            });
          } else {
            await tx.lowStockAlert.update({
              where: { id: activeAlert.id },
              data: { currentStockSnapshot: item.newStock },
            });
          }
        }
      }

      // Fetch full bill with relation for response
      const completeBill = await tx.bill.findUnique({
        where: { id: bill.id },
        include: {
          items: true,
          staff: { select: { id: true, fullName: true, username: true } },
          shop: true,
        },
      });

      return this.formatBillResponse(completeBill!, false);
    });
  }

  async getBill(shopId: string, billId: string) {
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, shopId },
      include: {
        items: true,
        staff: { select: { id: true, fullName: true, username: true } },
        shop: true,
      },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    return this.formatBillResponse(bill, bill.reprintCount > 0);
  }

  async reprintBill(shopId: string, billId: string) {
    const bill = await this.prisma.bill.findFirst({
      where: { id: billId, shopId },
      include: {
        items: true,
        staff: { select: { id: true, fullName: true, username: true } },
        shop: true,
      },
    });

    if (!bill) {
      throw new NotFoundException('Bill not found');
    }

    const updated = await this.prisma.bill.update({
      where: { id: billId },
      data: { reprintCount: bill.reprintCount + 1 },
      include: {
        items: true,
        staff: { select: { id: true, fullName: true, username: true } },
        shop: true,
      },
    });

    // PRD §5.3: "Allow reprinting of an existing receipt with an indication that it is a reprint"
    return this.formatBillResponse(updated, true);
  }

  async listBills(
    shopId: string,
    params?: {
      startDate?: string;
      endDate?: string;
      status?: string;
      limit?: number;
      offset?: number;
    },
  ) {
    const limit = Math.min(params?.limit ?? 50, 100);
    const offset = params?.offset ?? 0;

    const where: any = { shopId };
    if (params?.status) {
      where.status = params.status;
    }
    if (params?.startDate || params?.endDate) {
      where.createdAt = {};
      if (params.startDate) {
        where.createdAt.gte = new Date(params.startDate);
      }
      if (params.endDate) {
        const end = new Date(params.endDate);
        end.setHours(23, 59, 59, 999);
        where.createdAt.lte = end;
      }
    }

    const [total, bills] = await Promise.all([
      this.prisma.bill.count({ where }),
      this.prisma.bill.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        include: {
          items: true,
          staff: { select: { id: true, fullName: true, username: true } },
        },
      }),
    ]);

    return {
      total,
      limit,
      offset,
      bills: bills.map((b) => ({
        id: b.id,
        billNumber: b.billNumber,
        staffName: b.staff.fullName,
        subtotal: Number(b.subtotal),
        discountAmount: Number(b.discountAmount),
        taxAmount: Number(b.taxAmount),
        finalTotal: Number(b.finalTotal),
        estimatedGrossProfit: Number(b.estimatedGrossProfit),
        status: b.status,
        reprintCount: b.reprintCount,
        itemCount: b.items.length,
        createdAt: b.createdAt,
      })),
    };
  }

  async voidBill(shopId: string, userId: string, billId: string, reason: string) {
    return this.prisma.$transaction(async (tx) => {
      const bill = await tx.bill.findFirst({
        where: { id: billId, shopId },
        include: { items: true },
      });

      if (!bill) {
        throw new NotFoundException('Bill not found');
      }

      if (bill.status === 'VOIDED') {
        throw new BadRequestException('Bill is already voided');
      }

      // 1. Mark bill VOIDED
      await tx.bill.update({
        where: { id: billId },
        data: { status: 'VOIDED' },
      });

      // 2. Reverse stock deductions and log audit movements (PRD §10.2)
      for (const item of bill.items) {
        const prod = await tx.product.findUnique({ where: { id: item.productId } });
        if (prod) {
          const prevStock = Number(prod.currentStock);
          const returnedQty = Number(item.quantity);
          const newStock = prevStock + returnedQty;

          await tx.product.update({
            where: { id: item.productId },
            data: { currentStock: newStock },
          });

          await tx.stockMovement.create({
            data: {
              shopId,
              productId: item.productId,
              userId,
              billId: bill.id,
              movementType: 'CORRECTION',
              quantityChange: returnedQty,
              previousStock: prevStock,
              newStock,
              reason: `Void Bill #${bill.billNumber}: ${reason}`,
            },
          });
        }
      }

      return { message: `Bill #${bill.billNumber} voided and stock restored successfully` };
    });
  }

  private formatBillResponse(bill: any, isReprint: boolean) {
    return {
      id: bill.id,
      billNumber: bill.billNumber,
      idempotencyKey: bill.idempotencyKey,
      status: bill.status,
      isReprint, // PRD §5.3 explicit reprint flag
      reprintCount: bill.reprintCount,
      notes: bill.notes,
      createdAt: bill.createdAt,
      staff: {
        id: bill.staff?.id,
        fullName: bill.staff?.fullName,
        username: bill.staff?.username,
      },
      shop: {
        id: bill.shop?.id,
        name: bill.shop?.name,
        currency: bill.shop?.currency,
        address: bill.shop?.address,
        phone: bill.shop?.phone,
        receiptHeader: bill.shop?.receiptHeader,
        receiptFooter: bill.shop?.receiptFooter,
      },
      items: bill.items.map((i: any) => ({
        id: i.id,
        productId: i.productId,
        productName: i.productNameSnapshot,
        unit: i.unitSnapshot,
        quantity: Number(i.quantity),
        unitPrice: Number(i.unitPriceSnapshot),
        unitCost: Number(i.unitCostSnapshot),
        lineTotal: Number(i.lineTotal),
        lineProfit: Number(i.lineProfit),
      })),
      subtotal: Number(bill.subtotal),
      discountAmount: Number(bill.discountAmount),
      taxAmount: Number(bill.taxAmount),
      finalTotal: Number(bill.finalTotal),
      totalCostBasis: Number(bill.totalCostBasis),
      estimatedGrossProfit: Number(bill.estimatedGrossProfit),
    };
  }
}

