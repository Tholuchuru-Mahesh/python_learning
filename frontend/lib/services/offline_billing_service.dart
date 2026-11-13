import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_bill.dart';
import 'api_service.dart';

class OfflineBillingService {
  static const String _storageKey = 'offline_pending_bills_queue_v1';
  final ApiService _api = ApiService();

  Future<List<OfflineBill>> loadBillsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      return decoded.map((e) => OfflineBill.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBillsToStorage(List<OfflineBill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bills.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> enqueueBill(OfflineBill bill) async {
    final current = await loadBillsFromStorage();
    current.add(bill);
    await saveBillsToStorage(current);
  }

  Future<SyncResult> syncBill(OfflineBill bill) async {
    try {
      final payload = {
        'idempotencyKey': bill.idempotencyKey,
        'discountAmount': bill.discountAmount,
        'notes': bill.notes != null ? '${bill.notes} (Offline sync)' : '(Offline sync)',
        'items': bill.items.map((i) => {
          'productId': i.productId,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
        }).toList(),
      };

      final res = await _api.post('/api/billing', body: payload);
      final serverBillNumber = res['billNumber'] as String? ?? 'SYNCED';

      bill.status = OfflineBillStatus.synced;
      bill.serverBillNumber = serverBillNumber;
      bill.errorMessage = null;

      return SyncResult(success: true, billNumber: serverBillNumber);
    } catch (e) {
      bill.status = OfflineBillStatus.failed;
      bill.errorMessage = e.toString();
      bill.retryCount += 1;
      return SyncResult(success: false, errorMessage: e.toString());
    }
  }
}

class SyncResult {
  final bool success;
  final String? billNumber;
  final String? errorMessage;

  SyncResult({required this.success, this.billNumber, this.errorMessage});
}

