class Shop {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String currency;
  final double taxPercentage;
  final String? receiptHeader;
  final String? receiptFooter;

  Shop({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.currency = '₹',
    this.taxPercentage = 0.0,
    this.receiptHeader,
    this.receiptFooter,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      currency: json['currency'] as String? ?? '₹',
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      receiptHeader: json['receiptHeader'] as String?,
      receiptFooter: json['receiptFooter'] as String?,
    );
  }
}

