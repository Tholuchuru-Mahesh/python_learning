import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reports.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ReportsState {
  final TodayOverview? todayOverview;
  final SalesProfitSummary? salesProfitSummary;
  final List<Expense> expenses;
  final bool isLoading;
  final String? errorMessage;
  final String selectedPeriodLabel;

  ReportsState({
    this.todayOverview,
    this.salesProfitSummary,
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedPeriodLabel = 'Last 30 Days',
  });

  ReportsState copyWith({
    TodayOverview? todayOverview,
    SalesProfitSummary? salesProfitSummary,
    List<Expense>? expenses,
    bool? isLoading,
    String? errorMessage,
    String? selectedPeriodLabel,
  }) {
    return ReportsState(
      todayOverview: todayOverview ?? this.todayOverview,
      salesProfitSummary: salesProfitSummary ?? this.salesProfitSummary,
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedPeriodLabel: selectedPeriodLabel ?? this.selectedPeriodLabel,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ApiService _api = ApiService();

  ReportsNotifier() : super(ReportsState()) {
    fetchInitialReports();
  }

  Future<void> fetchInitialReports() async {
    await fetchTodayOverview();
    await fetchSalesProfitSummary();
    await fetchExpenses();
  }

  Future<void> fetchTodayOverview() async {
    try {
      final res = await _api.get('/api/reports/today-overview');
      final overview = TodayOverview.fromJson(res as Map<String, dynamic>);
      state = state.copyWith(todayOverview: overview);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> fetchSalesProfitSummary({String? startDate, String? endDate, String? periodLabel}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final query = <String, String>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;

      final res = await _api.get('/api/reports/sales-profit-summary', queryParams: query);
      final summary = SalesProfitSummary.fromJson(res as Map<String, dynamic>);

      state = state.copyWith(
        salesProfitSummary: summary,
        isLoading: false,
        selectedPeriodLabel: periodLabel ?? state.selectedPeriodLabel,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchExpenses({String? startDate, String? endDate}) async {
    try {
      final query = <String, String>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;

      final res = await _api.get('/api/expenses', queryParams: query);
      final items = (res['items'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = state.copyWith(expenses: items);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> createExpense({
    required String title,
    String? category,
    required double amount,
    String? notes,
  }) async {
    try {
      await _api.post('/api/expenses', body: {
        'title': title,
        'category': category ?? 'GENERAL',
        'amount': amount,
        'notes': notes,
      });
      await fetchExpenses();
      await fetchSalesProfitSummary();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _api.delete('/api/expenses/$expenseId');
      await fetchExpenses();
      await fetchSalesProfitSummary();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<String> downloadSalesCsv({String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    return _api.getCsv('/api/reports/export/sales-csv', queryParams: query);
  }

  Future<String> downloadInventoryCsv() async {
    return _api.getCsv('/api/reports/export/inventory-csv');
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier();
});

