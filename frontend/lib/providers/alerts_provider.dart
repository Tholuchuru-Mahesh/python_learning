import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/low_stock_alert.dart';
import '../services/api_service.dart';

class AlertsState {
  final List<LowStockAlert> activeAlerts;
  final bool isLoading;
  final String? errorMessage;

  AlertsState({
    this.activeAlerts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get alertCount => activeAlerts.length;

  AlertsState copyWith({
    List<LowStockAlert>? activeAlerts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AlertsState(
      activeAlerts: activeAlerts ?? this.activeAlerts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final ApiService _api = ApiService();

  AlertsNotifier() : super(AlertsState()) {
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.get('/api/alerts');
      final list = (res as List<dynamic>)
          .map((e) => LowStockAlert.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(activeAlerts: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      await _api.post('/api/alerts/$alertId/acknowledge');
      await fetchAlerts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier();
});

