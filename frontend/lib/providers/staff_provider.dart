import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class StaffState {
  final List<User> staffList;
  final bool isLoading;
  final String? errorMessage;

  StaffState({
    this.staffList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StaffState copyWith({
    List<User>? staffList,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StaffState(
      staffList: staffList ?? this.staffList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class StaffNotifier extends StateNotifier<StaffState> {
  final ApiService _api = ApiService();

  StaffNotifier() : super(StaffState()) {
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.get('/api/staff');
      final list = (res as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(staffList: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createStaff({
    required String fullName,
    required String username,
    required String password,
    required List<String> permissions,
  }) async {
    try {
      await _api.post('/api/staff', body: {
        'fullName': fullName,
        'username': username,
        'password': password,
        'permissions': permissions,
      });
      await fetchStaff();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStaffPermissions({
    required String staffId,
    required List<String> permissions,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{'permissions': permissions};
      if (isActive != null) body['isActive'] = isActive;

      await _api.put('/api/staff/$staffId', body: body);
      await fetchStaff();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> revokeStaff(String staffId) async {
    try {
      await _api.delete('/api/staff/$staffId');
      await fetchStaff();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final staffProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier();
});

