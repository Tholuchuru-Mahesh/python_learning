import 'product.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
  });

  double get lineTotal => format2(quantity * unitPrice);
  double get lineCost => format2(quantity * product.purchaseCost);
  double get lineProfit => lineTotal - lineCost;

  static double format2(double val) {
    return double.parse(val.toStringAsFixed(2));
  }
}

