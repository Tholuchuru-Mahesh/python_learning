import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';

@Injectable()
export class AlertsService {
  constructor(private readonly prisma: PrismaService) {}

  async listActiveAlerts(shopId: string) {
    const alerts = await this.prisma.lowStockAlert.findMany({
      where: { shopId, status: 'ACTIVE' },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            unit: true,
            currentStock: true,
            lowStockThreshold: true,
            category: true,
          },
        },
      },
      orderBy: { triggeredAt: 'desc' },
    });

    return alerts.map((a) => ({
      id: a.id,
      productId: a.productId,
      productName: a.product.name,
      category: a.product.category,
      unit: a.product.unit,
      currentStock: Number(a.product.currentStock),
      threshold: Number(a.product.lowStockThreshold),
      status: a.status,
      triggeredAt: a.triggeredAt,
    }));
  }

  async acknowledgeAlert(shopId: string, alertId: string) {
    const alert = await this.prisma.lowStockAlert.findFirst({
      where: { id: alertId, shopId },
    });

    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    const updated = await this.prisma.lowStockAlert.update({
      where: { id: alertId },
      data: { status: 'ACKNOWLEDGED' },
    });

    return { message: 'Alert acknowledged', id: updated.id, status: updated.status };
  }
}

