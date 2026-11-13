import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_bill.dart';
import '../models/cart_item.dart';
import '../services/offline_billing_service.dart';

class OfflineBillingState {
  final List<OfflineBill> bills;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? syncMessage;

  OfflineBillingState({
    this.bills = const [],
    this.isSyncing = false,
    this.lastSyncTime,
    this.syncMessage,
  });

  int get pendingCount => bills.where((b) => b.status == OfflineBillStatus.pending).length;
  int get failedCount => bills.where((b) => b.status == OfflineBillStatus.failed).length;
  int get syncedCount => bills.where((b) => b.status == OfflineBillStatus.synced).length;
  int get totalUnsynced => pendingCount + failedCount;

  OfflineBillingState copyWith({
    List<OfflineBill>? bills,
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? syncMessage,
  }) {
    return OfflineBillingState(
      bills: bills ?? this.bills,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncMessage: syncMessage ?? this.syncMessage,
    );
  }
}

class OfflineBillingNotifier extends StateNotifier<OfflineBillingState> {
  final OfflineBillingService _service = OfflineBillingService();
  final _uuid = const Uuid();

  OfflineBillingNotifier() : super(OfflineBillingState()) {
    loadOfflineBills();
  }

  Future<void> loadOfflineBills() async {
    final loaded = await _service.loadBillsFromStorage();
    state = state.copyWith(bills: loaded);
  }

  Future<OfflineBill> enqueueOfflineBill({
    required List<CartItem> cartItems,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double finalTotal,
    String? notes,
  }) async {
    final localId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    final idempotencyKey = _uuid.v4();

    final bill = OfflineBill.fromCart(
      localId: localId,
      idempotencyKey: idempotencyKey,
      cartItems: cartItems,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      finalTotal: finalTotal,
      notes: notes,
    );

    final updated = [...state.bills, bill];
    state = state.copyWith(bills: updated);
    await _service.saveBillsToStorage(updated);
    return bill;
  }

  Future<void> syncAllPendingBills() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, syncMessage: 'Synchronizing offline bills with server...');

    final all = List<OfflineBill>.from(state.bills);
    int successCount = 0;
    int failCount = 0;

    for (var i = 0; i < all.length; i++) {
      final bill = all[i];
      if (bill.status == OfflineBillStatus.pending || bill.status == OfflineBillStatus.failed) {
        bill.status = OfflineBillStatus.syncing;
        state = state.copyWith(bills: List.from(all));

        final res = await _service.syncBill(bill);
        if (res.success) {
          successCount++;
        } else {
          failCount++;
        }
      }
    }

    await _service.saveBillsToStorage(all);

    state = state.copyWith(
      bills: all,
      isSyncing: false,
      lastSyncTime: DateTime.now(),
      syncMessage: successCount > 0
          ? 'Synced $successCount bills successfully.${failCount > 0 ? " $failCount remaining." : ""}'
          : (failCount > 0 ? 'Failed to sync. Backend may still be unreachable.' : null),
    );
  }

  Future<void> clearSyncedBills() async {
    final remaining = state.bills.where((b) => b.status != OfflineBillStatus.synced).toList();
    state = state.copyWith(bills: remaining);
    await _service.saveBillsToStorage(remaining);
  }
}

final offlineBillingProvider =
    StateNotifierProvider<OfflineBillingNotifier, OfflineBillingState>((ref) {
  return OfflineBillingNotifier();
});

