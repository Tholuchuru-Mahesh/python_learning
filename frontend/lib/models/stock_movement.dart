class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String unit;
  final String userName;
  final String? billNumber;
  final String movementType; // SALE, OPENING_STOCK, ADJUSTMENT, RESTOCK, CORRECTION, DAMAGED
  final double quantityChange;
  final double previousStock;
  final double newStock;
  final String? reason;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.userName,
    this.billNumber,
    required this.movementType,
    required this.quantityChange,
    required this.previousStock,
    required this.newStock,
    this.reason,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unit: json['unit'] as String? ?? 'piece',
      userName: json['userName'] as String? ?? 'Staff',
      billNumber: json['billNumber'] as String?,
      movementType: json['movementType'] as String? ?? 'ADJUSTMENT',
      quantityChange: (json['quantityChange'] as num?)?.toDouble() ?? 0.0,
      previousStock: (json['previousStock'] as num?)?.toDouble() ?? 0.0,
      newStock: (json['newStock'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

