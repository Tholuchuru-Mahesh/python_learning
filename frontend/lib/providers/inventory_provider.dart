import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_movement.dart';
import '../services/api_service.dart';

class InventorySummary {
  final int totalProducts;
  final double totalStockUnits;
  final double totalStockCostValue;
  final double totalStockRetailValue;
  final int lowStockCount;

  InventorySummary({
    this.totalProducts = 0,
    this.totalStockUnits = 0.0,
    this.totalStockCostValue = 0.0,
    this.totalStockRetailValue = 0.0,
    this.lowStockCount = 0,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalStockUnits: (json['totalStockUnits'] as num?)?.toDouble() ?? 0.0,
      totalStockCostValue: (json['totalStockCostValue'] as num?)?.toDouble() ?? 0.0,
      totalStockRetailValue: (json['totalStockRetailValue'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
    );
  }
}

class InventoryState {
  final InventorySummary? summary;
  final List<StockMovement> movements;
  final bool isLoading;
  final String? errorMessage;

  InventoryState({
    this.summary,
    this.movements = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InventoryState copyWith({
    InventorySummary? summary,
    List<StockMovement>? movements,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InventoryState(
      summary: summary ?? this.summary,
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final ApiService _api = ApiService();

  InventoryNotifier() : super(InventoryState()) {
    fetchInventoryData();
  }

  Future<void> fetchInventoryData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summaryRes = await _api.get('/api/inventory/summary');
      final movementsRes = await _api.get('/api/inventory/movements?limit=100');

      final summary = InventorySummary.fromJson(summaryRes as Map<String, dynamic>);
      final items = (movementsRes['items'] as List<dynamic>?)
              ?.map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      state = state.copyWith(
        summary: summary,
        movements: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> adjustStock({
    required String productId,
    required double quantityChange,
    required String movementType, // RESTOCK, CORRECTION, DAMAGED, ADJUSTMENT
    required String reason, // Mandatory per PRD §5.2
  }) async {
    try {
      await _api.post('/api/inventory/adjust', body: {
        'productId': productId,
        'quantityChange': quantityChange,
        'movementType': movementType,
        'reason': reason,
      });
      await fetchInventoryData();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});

