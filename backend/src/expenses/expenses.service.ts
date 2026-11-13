import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service.js';
import { CreateExpenseDto } from './dto/create-expense.dto.js';

@Injectable()
export class ExpensesService {
  constructor(private readonly prisma: PrismaService) {}

  async createExpense(shopId: string, userId: string, dto: CreateExpenseDto) {
    const expense = await this.prisma.expense.create({
      data: {
        shopId,
        userId,
        title: dto.title,
        category: dto.category || 'GENERAL',
        amount: dto.amount,
        expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : new Date(),
        notes: dto.notes,
      },
    });

    return {
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: Number(expense.amount),
      expenseDate: expense.expenseDate,
      notes: expense.notes,
      createdAt: expense.createdAt,
    };
  }

  async listExpenses(
    shopId: string,
    params?: { startDate?: string; endDate?: string },
  ) {
    const where: any = { shopId };
    if (params?.startDate || params?.endDate) {
      where.expenseDate = {};
      if (params.startDate) {
        where.expenseDate.gte = new Date(params.startDate);
      }
      if (params.endDate) {
        const end = new Date(params.endDate);
        end.setHours(23, 59, 59, 999);
        where.expenseDate.lte = end;
      }
    }

    const expenses = await this.prisma.expense.findMany({
      where,
      orderBy: { expenseDate: 'desc' },
      include: {
        user: { select: { fullName: true, username: true } },
      },
    });

    const totalAmount = expenses.reduce((acc, curr) => acc + Number(curr.amount), 0);

    return {
      totalAmount: Number(totalAmount.toFixed(2)),
      count: expenses.length,
      items: expenses.map((e) => ({
        id: e.id,
        title: e.title,
        category: e.category,
        amount: Number(e.amount),
        expenseDate: e.expenseDate,
        notes: e.notes,
        createdByName: e.user.fullName,
        createdAt: e.createdAt,
      })),
    };
  }

  async deleteExpense(shopId: string, expenseId: string) {
    const expense = await this.prisma.expense.findFirst({
      where: { id: expenseId, shopId },
    });

    if (!expense) {
      throw new NotFoundException('Expense not found');
    }

    await this.prisma.expense.delete({ where: { id: expenseId } });
    return { message: 'Expense deleted successfully' };
  }
}

