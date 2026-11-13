import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedCategory;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategory,
  });

  List<String> get categories {
    final set = <String>{'All'};
    for (var p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCat = selectedCategory == null ||
          selectedCategory == 'All' ||
          p.category == selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ApiService _api = ApiService();

  ProductsNotifier() : super(ProductsState()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.get('/api/products');
      final list = (res as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(products: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<bool> createProduct({
    required String name,
    String? description,
    String? category,
    String? unit,
    required double purchaseCost,
    required double sellingPrice,
    double? openingStock,
    double? lowStockThreshold,
  }) async {
    try {
      await _api.post('/api/products', body: {
        'name': name,
        'description': description,
        'category': category ?? 'General',
        'unit': unit ?? 'piece',
        'purchaseCost': purchaseCost,
        'sellingPrice': sellingPrice,
        'openingStock': openingStock ?? 0.0,
        'lowStockThreshold': lowStockThreshold ?? 5.0,
      });
      await fetchProducts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? purchaseCost,
    double? sellingPrice,
    double? lowStockThreshold,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (unit != null) body['unit'] = unit;
      if (purchaseCost != null) body['purchaseCost'] = purchaseCost;
      if (sellingPrice != null) body['sellingPrice'] = sellingPrice;
      if (lowStockThreshold != null) body['lowStockThreshold'] = lowStockThreshold;
      if (isActive != null) body['isActive'] = isActive;

      await _api.put('/api/products/$id', body: body);
      await fetchProducts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deactivateProduct(String id) async {
    try {
      await _api.delete('/api/products/$id');
      await fetchProducts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});

