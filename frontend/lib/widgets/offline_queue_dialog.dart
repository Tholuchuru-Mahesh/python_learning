import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/offline_bill.dart';
import '../providers/offline_billing_provider.dart';

class OfflineQueueDialog extends ConsumerWidget {
  const OfflineQueueDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const OfflineQueueDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineBillingProvider);
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Offline Bill Queue (Release 1)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bills created during network disruptions are saved locally with guaranteed idempotency and automatically synchronized when connectivity returns.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(height: 20),

            // Queue Statistics Pills
            Row(
              children: [
                _buildStatBadge('Pending', offlineState.pendingCount, Colors.orange),
                const SizedBox(width: 8),
                _buildStatBadge('Failed', offlineState.failedCount, Colors.red),
                const SizedBox(width: 8),
                _buildStatBadge('Synced', offlineState.syncedCount, Colors.green),
                const Spacer(),
                if (offlineState.syncedCount > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.cleaning_services, size: 16),
                    label: const Text('Clear Synced', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ref.read(offlineBillingProvider.notifier).clearSyncedBills();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (offlineState.syncMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  offlineState.syncMessage!,
                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                ),
              ),

            // Queue List
            Expanded(
              child: offlineState.bills.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                          const SizedBox(height: 8),
                          const Text('No Pending Offline Bills', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('All counter bills are synced with the backend.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: offlineState.bills.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final bill = offlineState.bills[idx];
                        return ListTile(
                          dense: true,
                          leading: _buildStatusIcon(bill.status),
                          title: Row(
                            children: [
                              Text(bill.localId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              _buildStatusBadge(bill.status),
                              if (bill.serverBillNumber != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '→ ${bill.serverBillNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${df.format(bill.createdAt)} • ${bill.items.length} items • Total: ₹${bill.finalTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (bill.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Error (retry #${bill.retryCount}): ${bill.errorMessage}',
                                    style: const TextStyle(color: Colors.red, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: offlineState.isSyncing
                        ? null
                        : () => ref.read(offlineBillingProvider.notifier).syncAllPendingBills(),
                    icon: offlineState.isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: Text(
                      offlineState.isSyncing ? 'Synchronizing...' : 'Sync Pending Bills Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(OfflineBillStatus status) {
    switch (status) {
      case OfflineBillStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case OfflineBillStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case OfflineBillStatus.syncing:
        return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
      case OfflineBillStatus.pending:
        return const Icon(Icons.access_time, color: Colors.orange, size: 20);
    }
  }

  Widget _buildStatusBadge(OfflineBillStatus status) {
    Color bg = Colors.orange.shade100;
    Color fg = Colors.orange.shade900;
    String label = 'PENDING';

    if (status == OfflineBillStatus.synced) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
      label = 'SYNCED';
    } else if (status == OfflineBillStatus.failed) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
      label = 'FAILED';
    } else if (status == OfflineBillStatus.syncing) {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
      label = 'SYNCING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

