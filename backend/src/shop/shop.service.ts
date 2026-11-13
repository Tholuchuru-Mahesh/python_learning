import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { UpdateShopDto } from './dto/update-shop.dto.js';

@Injectable()
export class ShopService {
  constructor(private readonly prisma: PrismaService) {}

  async getShopProfile(shopId: string) {
    const shop = await this.prisma.shop.findUnique({
      where: { id: shopId },
    });
    if (!shop) {
      throw new NotFoundException('Shop profile not found');
    }
    return {
      id: shop.id,
      name: shop.name,
      address: shop.address,
      phone: shop.phone,
      currency: shop.currency,
      taxPercentage: Number(shop.taxPercentage),
      receiptHeader: shop.receiptHeader,
      receiptFooter: shop.receiptFooter,
      createdAt: shop.createdAt,
    };
  }

  async updateShopProfile(shopId: string, dto: UpdateShopDto) {
    const shop = await this.prisma.shop.findUnique({
      where: { id: shopId },
    });
    if (!shop) {
      throw new NotFoundException('Shop profile not found');
    }

    const updated = await this.prisma.shop.update({
      where: { id: shopId },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.address !== undefined && { address: dto.address }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.currency !== undefined && { currency: dto.currency }),
        ...(dto.taxPercentage !== undefined && { taxPercentage: dto.taxPercentage }),
        ...(dto.receiptHeader !== undefined && { receiptHeader: dto.receiptHeader }),
        ...(dto.receiptFooter !== undefined && { receiptFooter: dto.receiptFooter }),
      },
    });

    return {
      id: updated.id,
      name: updated.name,
      address: updated.address,
      phone: updated.phone,
      currency: updated.currency,
      taxPercentage: Number(updated.taxPercentage),
      receiptHeader: updated.receiptHeader,
      receiptFooter: updated.receiptFooter,
      updatedAt: updated.updatedAt,
    };
  }
}

