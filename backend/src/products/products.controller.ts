import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ProductsService } from './products.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';
import { UpdateProductDto } from './dto/update-product.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { PermissionsGuard } from '../common/guards/permissions.guard.js';
import { RequirePermissions } from '../common/decorators/permissions.decorator.js';
import { Permission } from '../common/constants/permissions.constant.js';
import { CurrentUser, CurrentUserPayload } from '../common/decorators/current-user.decorator.js';

@Controller('api/products')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async listProducts(
    @CurrentUser() user: CurrentUserPayload,
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.productsService.listProducts(user.shopId, {
      search,
      category,
      includeInactive: includeInactive === 'true',
    });
  }

  @Get(':id')
  @RequirePermissions(Permission.VIEW_PRODUCTS)
  async getProduct(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') productId: string,
  ) {
    return this.productsService.getProduct(user.shopId, productId);
  }

  @Post()
  @RequirePermissions(Permission.ADD_EDIT_PRODUCTS)
  async createProduct(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateProductDto,
  ) {
    return this.productsService.createProduct(user.shopId, user.userId, dto);
  }

  @Put(':id')
  @RequirePermissions(Permission.ADD_EDIT_PRODUCTS)
  async updateProduct(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') productId: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.productsService.updateProduct(user.shopId, productId, dto);
  }

  @Delete(':id')
  @RequirePermissions(Permission.ADD_EDIT_PRODUCTS)
  async deactivateProduct(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') productId: string,
  ) {
    return this.productsService.deactivateProduct(user.shopId, productId);
  }
}

