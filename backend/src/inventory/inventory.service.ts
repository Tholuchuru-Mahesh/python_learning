import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { AdjustStockDto } from './dto/adjust-stock.dto.js';

@Injectable()
export class InventoryService {
  constructor(private readonly prisma: PrismaService) {}

  async adjustStock(shopId: string, userId: string, dto: AdjustStockDto) {
    return this.prisma.$transaction(async (tx) => {
      const product = await tx.product.findFirst({
        where: { id: dto.productId, shopId },
      });

      if (!product) {
        throw new NotFoundException('Product not found in this shop');
      }

      const prevStock = Number(product.currentStock);
      const newStock = prevStock + dto.quantityChange;

      // PRD §5.2: Prevent accidental negative stock by default
      if (newStock < 0) {
        throw new BadRequestException(
          `Cannot reduce stock by ${Math.abs(
            dto.quantityChange,
          )}. Current stock is ${prevStock}. Negative stock is prevented.`,
        );
      }

      // 1. Update product stock
      const updatedProduct = await tx.product.update({
        where: { id: product.id },
        data: { currentStock: newStock },
      });

      // 2. Log stock movement history (PRD §5.2 & §10.1)
      const movement = await tx.stockMovement.create({
        data: {
          shopId,
          productId: product.id,
          userId,
          movementType: dto.movementType,
          quantityChange: dto.quantityChange,
          previousStock: prevStock,
          newStock,
          reason: dto.reason,
        },
      });

      // 3. Low-stock alert management (PRD §5.6 & §7.3)
      const threshold = Number(product.lowStockThreshold);
      if (newStock <= threshold) {
        const activeAlert = await tx.lowStockAlert.findFirst({
          where: { shopId, productId: product.id, status: 'ACTIVE' },
        });

        if (!activeAlert) {
          await tx.lowStockAlert.create({
            data: {
              shopId,
              productId: product.id,
              currentStockSnapshot: newStock,
              thresholdSnapshot: threshold,
              status: 'ACTIVE',
            },
          });
        } else {
          await tx.lowStockAlert.update({
            where: { id: activeAlert.id },
            data: { currentStockSnapshot: newStock },
          });
        }
      } else {
        // Stock replenished above threshold: resolve active alerts (PRD §7.3)
        await tx.lowStockAlert.updateMany({
          where: { shopId, productId: product.id, status: 'ACTIVE' },
          data: { status: 'RESOLVED', resolvedAt: new Date() },
        });
      }

      return {
        product: {
          id: updatedProduct.id,
          name: updatedProduct.name,
          currentStock: Number(updatedProduct.currentStock),
          lowStockThreshold: Number(updatedProduct.lowStockThreshold),
          isLowStock: newStock <= threshold,
        },
        movement: {
          id: movement.id,
          movementType: movement.movementType,
          quantityChange: Number(movement.quantityChange),
          previousStock: Number(movement.previousStock),
          newStock: Number(movement.newStock),
          reason: movement.reason,
          createdAt: movement.createdAt,
        },
      };
    });
  }

  async getStockMovements(
    shopId: string,
    params?: { productId?: string; limit?: number; offset?: number },
  ) {
    const limit = Math.min(params?.limit ?? 50, 100);
    const offset = params?.offset ?? 0;

    const where: any = { shopId };
    if (params?.productId) {
      where.productId = params.productId;
    }

    const [total, movements] = await Promise.all([
      this.prisma.stockMovement.count({ where }),
      this.prisma.stockMovement.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        include: {
          product: { select: { id: true, name: true, unit: true } },
          user: { select: { id: true, fullName: true, username: true } },
          bill: { select: { id: true, billNumber: true } },
        },
      }),
    ]);

    return {
      total,
      limit,
      offset,
      items: movements.map((m) => ({
        id: m.id,
        productId: m.productId,
        productName: m.product.name,
        unit: m.product.unit,
        userId: m.userId,
        userName: m.user.fullName,
        billId: m.billId,
        billNumber: m.bill?.billNumber ?? null,
        movementType: m.movementType,
        quantityChange: Number(m.quantityChange),
        previousStock: Number(m.previousStock),
        newStock: Number(m.newStock),
        reason: m.reason,
        createdAt: m.createdAt,
      })),
    };
  }

  async getInventorySummary(shopId: string) {
    const products = await this.prisma.product.findMany({
      where: { shopId, isActive: true },
    });

    let totalProducts = products.length;
    let totalStockUnits = 0;
    let totalStockCostValue = 0;
    let totalStockRetailValue = 0;
    let lowStockCount = 0;

    for (const p of products) {
      const stock = Number(p.currentStock);
      const cost = Number(p.purchaseCost);
      const price = Number(p.sellingPrice);
      const threshold = Number(p.lowStockThreshold);

      totalStockUnits += stock;
      totalStockCostValue += stock * cost;
      totalStockRetailValue += stock * price;

      if (stock <= threshold) {
        lowStockCount++;
      }
    }

    return {
      totalProducts,
      totalStockUnits: Number(totalStockUnits.toFixed(3)),
      totalStockCostValue: Number(totalStockCostValue.toFixed(2)),
      totalStockRetailValue: Number(totalStockRetailValue.toFixed(2)),
      lowStockCount,
    };
  }
}

