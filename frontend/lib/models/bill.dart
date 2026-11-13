class BillItemSnapshot {
  final String id;
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double unitCost;
  final double lineTotal;
  final double lineProfit;

  BillItemSnapshot({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.lineTotal,
    required this.lineProfit,
  });

  factory BillItemSnapshot.fromJson(Map<String, dynamic> json) {
    return BillItemSnapshot(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unit: json['unit'] as String? ?? 'piece',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      lineProfit: (json['lineProfit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Bill {
  final String id;
  final String billNumber;
  final String? idempotencyKey;
  final String status;
  final bool isReprint;
  final int reprintCount;
  final String? notes;
  final DateTime createdAt;
  final String? staffName;
  final String? shopName;
  final String? shopCurrency;
  final String? receiptHeader;
  final String? receiptFooter;
  final List<BillItemSnapshot> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double finalTotal;
  final double totalCostBasis;
  final double estimatedGrossProfit;

  int get itemCount => items.length;

  Bill({
    required this.id,
    required this.billNumber,
    this.idempotencyKey,
    required this.status,
    this.isReprint = false,
    this.reprintCount = 0,
    this.notes,
    required this.createdAt,
    this.staffName,
    this.shopName,
    this.shopCurrency = '₹',
    this.receiptHeader,
    this.receiptFooter,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.finalTotal,
    required this.totalCostBasis,
    required this.estimatedGrossProfit,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      billNumber: json['billNumber'] as String,
      idempotencyKey: json['idempotencyKey'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
      isReprint: json['isReprint'] as bool? ?? false,
      reprintCount: json['reprintCount'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      staffName: json['staff']?['fullName'] as String? ?? json['staffName'] as String?,
      shopName: json['shop']?['name'] as String?,
      shopCurrency: json['shop']?['currency'] as String? ?? '₹',
      receiptHeader: json['shop']?['receiptHeader'] as String?,
      receiptFooter: json['shop']?['receiptFooter'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BillItemSnapshot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['finalTotal'] as num?)?.toDouble() ?? 0.0,
      totalCostBasis: (json['totalCostBasis'] as num?)?.toDouble() ?? 0.0,
      estimatedGrossProfit: (json['estimatedGrossProfit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

