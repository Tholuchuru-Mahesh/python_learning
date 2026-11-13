import 'cart_item.dart';

enum OfflineBillStatus { pending, syncing, synced, failed }

class OfflineBillItem {
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  OfflineBillItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory OfflineBillItem.fromJson(Map<String, dynamic> json) => OfflineBillItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        unit: json['unit'] as String? ?? 'piece',
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

class OfflineBill {
  final String localId;
  final String idempotencyKey;
  final DateTime createdAt;
  final List<OfflineBillItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double finalTotal;
  final String? notes;
  OfflineBillStatus status;
  String? errorMessage;
  String? serverBillNumber;
  int retryCount;

  OfflineBill({
    required this.localId,
    required this.idempotencyKey,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.finalTotal,
    this.notes,
    this.status = OfflineBillStatus.pending,
    this.errorMessage,
    this.serverBillNumber,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'finalTotal': finalTotal,
        'notes': notes,
        'status': status.name,
        'errorMessage': errorMessage,
        'serverBillNumber': serverBillNumber,
        'retryCount': retryCount,
      };

  factory OfflineBill.fromJson(Map<String, dynamic> json) => OfflineBill(
        localId: json['localId'] as String,
        idempotencyKey: json['idempotencyKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>)
            .map((i) => OfflineBillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discountAmount: (json['discountAmount'] as num).toDouble(),
        taxAmount: (json['taxAmount'] as num).toDouble(),
        finalTotal: (json['finalTotal'] as num).toDouble(),
        notes: json['notes'] as String?,
        status: OfflineBillStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => OfflineBillStatus.pending,
        ),
        errorMessage: json['errorMessage'] as String?,
        serverBillNumber: json['serverBillNumber'] as String?,
        retryCount: json['retryCount'] as int? ?? 0,
      );

  factory OfflineBill.fromCart({
    required String localId,
    required String idempotencyKey,
    required List<CartItem> cartItems,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double finalTotal,
    String? notes,
  }) {
    return OfflineBill(
      localId: localId,
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
      items: cartItems.map((c) => OfflineBillItem(
        productId: c.product.id,
        productName: c.product.name,
        unit: c.product.unit,
        quantity: c.quantity,
        unitPrice: c.unitPrice,
        lineTotal: c.lineTotal,
      )).toList(),
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      finalTotal: finalTotal,
      notes: notes,
      status: OfflineBillStatus.pending,
    );
  }
}

