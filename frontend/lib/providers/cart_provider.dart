import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final double discountAmount;
  final double taxPercentage;

  CartState({
    this.items = const [],
    this.discountAmount = 0.0,
    this.taxPercentage = 0.0,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get totalUnits => items.fold(0.0, (sum, i) => sum + i.quantity);
  int get itemCount => items.length;

  double get taxableAmount {
    final net = subtotal - discountAmount;
    return net > 0 ? net : 0.0;
  }

  double get taxAmount {
    return double.parse(((taxableAmount * taxPercentage) / 100).toStringAsFixed(2));
  }

  double get finalTotal {
    final net = subtotal - discountAmount + taxAmount;
    return double.parse(net.toStringAsFixed(2));
  }

  CartState copyWith({
    List<CartItem>? items,
    double? discountAmount,
    double? taxPercentage,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void setTaxPercentage(double tax) {
    state = state.copyWith(taxPercentage: tax);
  }

  void addToCart(Product product, {double quantity = 1.0}) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final currentItem = state.items[existingIndex];
      final newQty = currentItem.quantity + quantity;
      updateQuantity(product.id, newQty);
    } else {
      final newItem = CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return CartItem(
          product: item.product,
          quantity: quantity,
          unitPrice: item.unitPrice,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void updateUnitPrice(String productId, double price) {
    if (price < 0) return;
    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return CartItem(
          product: item.product,
          quantity: item.quantity,
          unitPrice: price,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount >= 0 ? discount : 0.0);
  }

  void clear() {
    state = state.copyWith(items: [], discountAmount: 0.0);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

