class TodayOverview {
  final String date;
  final double todaySalesValue;
  final int todayBillsCount;
  final TopProductQty? topSellingProductByQuantity;
  final TopProductRev? topRevenueProduct;

  TodayOverview({
    required this.date,
    required this.todaySalesValue,
    required this.todayBillsCount,
    this.topSellingProductByQuantity,
    this.topRevenueProduct,
  });

  factory TodayOverview.fromJson(Map<String, dynamic> json) {
    return TodayOverview(
      date: json['date'] as String? ?? '',
      todaySalesValue: (json['todaySalesValue'] as num?)?.toDouble() ?? 0.0,
      todayBillsCount: json['todayBillsCount'] as int? ?? 0,
      topSellingProductByQuantity: json['topSellingProductByQuantity'] != null
          ? TopProductQty.fromJson(json['topSellingProductByQuantity'] as Map<String, dynamic>)
          : null,
      topRevenueProduct: json['topRevenueProduct'] != null
          ? TopProductRev.fromJson(json['topRevenueProduct'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TopProductQty {
  final String name;
  final double quantity;
  final String unit;

  TopProductQty({required this.name, required this.quantity, required this.unit});

  factory TopProductQty.fromJson(Map<String, dynamic> json) {
    return TopProductQty(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'piece',
    );
  }
}

class TopProductRev {
  final String name;
  final double revenue;
  final String unit;

  TopProductRev({required this.name, required this.revenue, required this.unit});

  factory TopProductRev.fromJson(Map<String, dynamic> json) {
    return TopProductRev(
      name: json['name'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'piece',
    );
  }
}

class ProductPerformanceItem {
  final String productId;
  final String name;
  final String unit;
  final double quantitySold;
  final double salesValue;
  final double costBasis;
  final double estimatedGrossProfit;
  final double grossMarginPercentage;

  ProductPerformanceItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantitySold,
    required this.salesValue,
    required this.costBasis,
    required this.estimatedGrossProfit,
    required this.grossMarginPercentage,
  });

  factory ProductPerformanceItem.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceItem(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'piece',
      quantitySold: (json['quantitySold'] as num?)?.toDouble() ?? 0.0,
      salesValue: (json['salesValue'] as num?)?.toDouble() ?? 0.0,
      costBasis: (json['costBasis'] as num?)?.toDouble() ?? 0.0,
      estimatedGrossProfit: (json['estimatedGrossProfit'] as num?)?.toDouble() ?? 0.0,
      grossMarginPercentage: (json['grossMarginPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesProfitSummary {
  final String startDate;
  final String endDate;
  final int totalBillsCount;
  final double totalUnitsSold;
  final double totalRevenue;
  final double totalCostBasis;
  final double totalDiscountAmount;
  final double totalTaxAmount;
  final double estimatedGrossProfit;
  final double grossMarginPercentage;
  final double totalExpenses;
  final bool hasRecordedExpenses;
  final double? estimatedOperatingResult;
  final List<ProductPerformanceItem> productPerformance;

  SalesProfitSummary({
    required this.startDate,
    required this.endDate,
    required this.totalBillsCount,
    required this.totalUnitsSold,
    required this.totalRevenue,
    required this.totalCostBasis,
    required this.totalDiscountAmount,
    required this.totalTaxAmount,
    required this.estimatedGrossProfit,
    required this.grossMarginPercentage,
    required this.totalExpenses,
    required this.hasRecordedExpenses,
    this.estimatedOperatingResult,
    required this.productPerformance,
  });

  factory SalesProfitSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final period = json['period'] as Map<String, dynamic>? ?? {};
    final opResult = json['operatingResult'] as Map<String, dynamic>? ?? {};

    return SalesProfitSummary(
      startDate: period['startDate'] as String? ?? '',
      endDate: period['endDate'] as String? ?? '',
      totalBillsCount: summary['totalBillsCount'] as int? ?? 0,
      totalUnitsSold: (summary['totalUnitsSold'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCostBasis: (summary['totalCostBasis'] as num?)?.toDouble() ?? 0.0,
      totalDiscountAmount: (summary['totalDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      totalTaxAmount: (summary['totalTaxAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedGrossProfit: (summary['estimatedGrossProfit'] as num?)?.toDouble() ?? 0.0,
      grossMarginPercentage: (summary['grossMarginPercentage'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (opResult['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      hasRecordedExpenses: opResult['hasRecordedExpenses'] as bool? ?? false,
      estimatedOperatingResult: (opResult['estimatedOperatingResult'] as num?)?.toDouble(),
      productPerformance: (json['productPerformance'] as List<dynamic>?)
              ?.map((e) => ProductPerformanceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

