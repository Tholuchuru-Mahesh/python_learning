import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  category?: string;

  @IsString()
  @IsOptional()
  unit?: string; // piece, packet, bottle, kg, litre (PRD §5.2)

  @IsNumber()
  @Min(0)
  purchaseCost: number;

  @IsNumber()
  @Min(0)
  sellingPrice: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  openingStock?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  lowStockThreshold?: number;
}

