import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/offline_bill.dart';
import 'package:frontend/services/offline_billing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Billing Queue Tests (PRD Release 1)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Offline bill serialization and deserialization retains financial accuracy', () {
      final bill = OfflineBill(
        localId: 'LOCAL-TEST-001',
        idempotencyKey: 'idem-uuid-1234',
        createdAt: DateTime(2026, 11, 13, 10, 30),
        items: [
          OfflineBillItem(
            productId: 'prod-1',
            productName: 'Mineral Water 1L',
            unit: 'bottle',
            quantity: 2.0,
            unitPrice: 20.0,
            lineTotal: 40.0,
          ),
          OfflineBillItem(
            productId: 'prod-2',
            productName: 'Basmati Rice 1kg',
            unit: 'kg',
            quantity: 1.5,
            unitPrice: 100.0,
            lineTotal: 150.0,
          ),
        ],
        subtotal: 190.0,
        discountAmount: 10.0,
        taxAmount: 9.0,
        finalTotal: 189.0,
        notes: 'Offline cash counter',
        status: OfflineBillStatus.pending,
      );

      final json = bill.toJson();
      final revived = OfflineBill.fromJson(json);

      expect(revived.localId, 'LOCAL-TEST-001');
      expect(revived.idempotencyKey, 'idem-uuid-1234');
      expect(revived.items.length, 2);
      expect(revived.items[1].quantity, 1.5);
      expect(revived.subtotal, 190.0);
      expect(revived.discountAmount, 10.0);
      expect(revived.taxAmount, 9.0);
      expect(revived.finalTotal, 189.0);
      expect(revived.status, OfflineBillStatus.pending);
    });

    test('2. Offline bills persist across application restart via persistent storage', () async {
      final service = OfflineBillingService();

      final bill1 = OfflineBill(
        localId: 'LOCAL-001',
        idempotencyKey: 'idem-1',
        createdAt: DateTime.now(),
        items: [
          OfflineBillItem(
            productId: 'p1',
            productName: 'Milk',
            unit: 'packet',
            quantity: 1,
            unitPrice: 34.0,
            lineTotal: 34.0,
          ),
        ],
        subtotal: 34.0,
        discountAmount: 0.0,
        taxAmount: 0.0,
        finalTotal: 34.0,
      );

      final bill2 = OfflineBill(
        localId: 'LOCAL-002',
        idempotencyKey: 'idem-2',
        createdAt: DateTime.now(),
        items: [
          OfflineBillItem(
            productId: 'p2',
            productName: 'Bread',
            unit: 'packet',
            quantity: 2,
            unitPrice: 40.0,
            lineTotal: 80.0,
          ),
        ],
        subtotal: 80.0,
        discountAmount: 0.0,
        taxAmount: 0.0,
        finalTotal: 80.0,
      );

      // Save bills before simulated app shutdown
      await service.saveBillsToStorage([bill1, bill2]);

      // Simulate app restart: re-read from storage
      final loadedAfterRestart = await service.loadBillsFromStorage();

      expect(loadedAfterRestart.length, 2);
      expect(loadedAfterRestart[0].localId, 'LOCAL-001');
      expect(loadedAfterRestart[0].idempotencyKey, 'idem-1');
      expect(loadedAfterRestart[1].localId, 'LOCAL-002');
      expect(loadedAfterRestart[1].idempotencyKey, 'idem-2');
    });

    test('3. Enqueueing new bill appends without losing existing pending bills', () async {
      final service = OfflineBillingService();

      final b1 = OfflineBill(
        localId: 'LOCAL-10',
        idempotencyKey: 'k-10',
        createdAt: DateTime.now(),
        items: [],
        subtotal: 50.0,
        discountAmount: 0,
        taxAmount: 0,
        finalTotal: 50.0,
      );
      await service.enqueueBill(b1);

      final b2 = OfflineBill(
        localId: 'LOCAL-20',
        idempotencyKey: 'k-20',
        createdAt: DateTime.now(),
        items: [],
        subtotal: 75.0,
        discountAmount: 0,
        taxAmount: 0,
        finalTotal: 75.0,
      );
      await service.enqueueBill(b2);

      final allBills = await service.loadBillsFromStorage();
      expect(allBills.length, 2);
      expect(allBills.map((b) => b.localId).toList(), ['LOCAL-10', 'LOCAL-20']);
    });
  });
}

