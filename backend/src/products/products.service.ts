import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';
import { UpdateProductDto } from './dto/update-product.dto.js';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async listProducts(
    shopId: string,
    query?: { search?: string; category?: string; includeInactive?: boolean },
  ) {
    const where: Prisma.ProductWhereInput = {
      shopId,
      ...(!query?.includeInactive ? { isActive: true } : {}),
      ...(query?.category ? { category: query.category } : {}),
      ...(query?.search
        ? {
            name: {
              contains: query.search,
            },
          }
        : {}),
    };

    const products = await this.prisma.product.findMany({
      where,
      orderBy: { name: 'asc' },
    });

    return products.map((p) => ({
      id: p.id,
      name: p.name,
      description: p.description,
      category: p.category,
      unit: p.unit,
      purchaseCost: Number(p.purchaseCost),
      sellingPrice: Number(p.sellingPrice),
      currentStock: Number(p.currentStock),
      lowStockThreshold: Number(p.lowStockThreshold),
      isLowStock: Number(p.currentStock) <= Number(p.lowStockThreshold),
      isActive: p.isActive,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }

  async getProduct(shopId: string, productId: string) {
    const p = await this.prisma.product.findFirst({
      where: { id: productId, shopId },
    });

    if (!p) {
      throw new NotFoundException('Product not found');
    }

    return {
      id: p.id,
      name: p.name,
      description: p.description,
      category: p.category,
      unit: p.unit,
      purchaseCost: Number(p.purchaseCost),
      sellingPrice: Number(p.sellingPrice),
      currentStock: Number(p.currentStock),
      lowStockThreshold: Number(p.lowStockThreshold),
      isLowStock: Number(p.currentStock) <= Number(p.lowStockThreshold),
      isActive: p.isActive,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    };
  }

  async createProduct(shopId: string, userId: string, dto: CreateProductDto) {
    const openingStock = dto.openingStock ?? 0;
    const threshold = dto.lowStockThreshold ?? 5;

    return this.prisma.$transaction(async (tx) => {
      const product = await tx.product.create({
        data: {
          shopId,
          name: dto.name,
          description: dto.description,
          category: dto.category || 'General',
          unit: dto.unit || 'piece',
          purchaseCost: dto.purchaseCost,
          sellingPrice: dto.sellingPrice,
          currentStock: openingStock,
          lowStockThreshold: threshold,
          isActive: true,
        },
      });

      // Maintain stock movement history for opening stock (PRD §5.2)
      if (openingStock > 0) {
        await tx.stockMovement.create({
          data: {
            shopId,
            productId: product.id,
            userId,
            movementType: 'OPENING_STOCK',
            quantityChange: openingStock,
            previousStock: 0,
            newStock: openingStock,
            reason: 'Initial opening stock',
          },
        });
      }

      // Check low stock threshold alert (PRD §5.6)
      if (openingStock <= threshold) {
        await tx.lowStockAlert.create({
          data: {
            shopId,
            productId: product.id,
            currentStockSnapshot: openingStock,
            thresholdSnapshot: threshold,
            status: 'ACTIVE',
          },
        });
      }

      return {
        id: product.id,
        name: product.name,
        description: product.description,
        category: product.category,
        unit: product.unit,
        purchaseCost: Number(product.purchaseCost),
        sellingPrice: Number(product.sellingPrice),
        currentStock: Number(product.currentStock),
        lowStockThreshold: Number(product.lowStockThreshold),
        isLowStock: openingStock <= threshold,
        isActive: product.isActive,
        createdAt: product.createdAt,
      };
    });
  }

  async updateProduct(shopId: string, productId: string, dto: UpdateProductDto) {
    const existing = await this.prisma.product.findFirst({
      where: { id: productId, shopId },
    });

    if (!existing) {
      throw new NotFoundException('Product not found');
    }

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.unit !== undefined && { unit: dto.unit }),
        ...(dto.purchaseCost !== undefined && { purchaseCost: dto.purchaseCost }),
        ...(dto.sellingPrice !== undefined && { sellingPrice: dto.sellingPrice }),
        ...(dto.lowStockThreshold !== undefined && {
          lowStockThreshold: dto.lowStockThreshold,
        }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });

    return {
      id: updated.id,
      name: updated.name,
      description: updated.description,
      category: updated.category,
      unit: updated.unit,
      purchaseCost: Number(updated.purchaseCost),
      sellingPrice: Number(updated.sellingPrice),
      currentStock: Number(updated.currentStock),
      lowStockThreshold: Number(updated.lowStockThreshold),
      isLowStock: Number(updated.currentStock) <= Number(updated.lowStockThreshold),
      isActive: updated.isActive,
      updatedAt: updated.updatedAt,
    };
  }

  async deactivateProduct(shopId: string, productId: string) {
    const existing = await this.prisma.product.findFirst({
      where: { id: productId, shopId },
    });

    if (!existing) {
      throw new NotFoundException('Product not found');
    }

    await this.prisma.product.update({
      where: { id: productId },
      data: { isActive: false },
    });

    return { message: 'Product deactivated successfully' };
  }
}

