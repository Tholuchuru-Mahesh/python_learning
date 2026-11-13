class LowStockAlert {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final String unit;
  final double currentStock;
  final double threshold;
  final String status;
  final DateTime triggeredAt;

  LowStockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.threshold,
    required this.status,
    required this.triggeredAt,
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      id: json['id'] as String,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      unit: json['unit'] as String? ?? 'piece',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
      triggeredAt: DateTime.tryParse(json['triggeredAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

