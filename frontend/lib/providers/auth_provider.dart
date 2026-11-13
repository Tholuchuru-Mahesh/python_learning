import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/shop.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final Shop? shop;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.shop,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Shop? shop,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      shop: shop ?? this.shop,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api = ApiService();

  AuthNotifier() : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _api.initToken();
    if (_api.token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final res = await _api.get('/api/auth/me');
      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      final shop = Shop.fromJson(res['shop'] as Map<String, dynamic>);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        shop: shop,
        errorMessage: null,
      );
    } catch (_) {
      await _api.clearToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _api.post('/api/auth/login', body: {
        'username': username,
        'password': password,
      });

      final token = res['accessToken'] as String;
      await _api.saveToken(token);

      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      final shop = Shop.fromJson(res['shop'] as Map<String, dynamic>);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        shop: shop,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registerShop({
    required String shopName,
    required String ownerFullName,
    required String username,
    required String password,
    String? currency,
    String? address,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _api.post('/api/auth/register-shop', body: {
        'shopName': shopName,
        'ownerFullName': ownerFullName,
        'username': username,
        'password': password,
        'currency': currency ?? '₹',
        'address': address,
        'phone': phone,
      });

      final token = res['accessToken'] as String;
      await _api.saveToken(token);

      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      final shop = Shop.fromJson(res['shop'] as Map<String, dynamic>);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        shop: shop,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> updateShop(Shop updatedShop) async {
    state = state.copyWith(shop: updatedShop);
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

