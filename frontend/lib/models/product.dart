class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String unit; // piece, packet, bottle, kg, litre (PRD §5.2)
  final double purchaseCost;
  final double sellingPrice;
  final double currentStock;
  final double lowStockThreshold;
  final bool isLowStock;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.category = 'General',
    this.unit = 'piece',
    required this.purchaseCost,
    required this.sellingPrice,
    required this.currentStock,
    required this.lowStockThreshold,
    this.isLowStock = false,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      unit: json['unit'] as String? ?? 'piece',
      purchaseCost: (json['purchaseCost'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 5.0,
      isLowStock: json['isLowStock'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

