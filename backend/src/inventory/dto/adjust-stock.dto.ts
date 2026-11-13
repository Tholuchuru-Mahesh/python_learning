import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsString,
} from 'class-validator';

export enum StockAdjustmentType {
  RESTOCK = 'RESTOCK',
  CORRECTION = 'CORRECTION',
  DAMAGED = 'DAMAGED',
  ADJUSTMENT = 'ADJUSTMENT',
}

export class AdjustStockDto {
  @IsString()
  @IsNotEmpty()
  productId: string;

  @IsNumber()
  quantityChange: number; // positive or negative

  @IsEnum(StockAdjustmentType)
  movementType: StockAdjustmentType;

  @IsString()
  @IsNotEmpty()
  reason: string; // Mandatory reason (PRD §5.2)
}

