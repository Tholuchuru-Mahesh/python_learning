import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);
    final user = ref.watch(authProvider).user;
    final canAcknowledge = user?.hasPermission('UPDATE_STOCK') ?? false;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low-Stock Alerts (${alertsState.alertCount} Active)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(alertsProvider.notifier).fetchAlerts(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PRD §5.6: A single active alert is maintained per product when available stock reaches or falls below the configured threshold.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: alertsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : alertsState.activeAlerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                            const SizedBox(height: 12),
                            const Text('Stock Healthy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('All products are above their minimum stock thresholds.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: alertsState.activeAlerts.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final a = alertsState.activeAlerts[idx];
                          final isZero = a.currentStock <= 0;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: isZero ? Colors.red.shade300 : Colors.amber.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isZero ? Colors.red.shade100 : Colors.amber.shade100,
                                    child: Icon(
                                      isZero ? Icons.error_outline : Icons.warning_amber_rounded,
                                      color: isZero ? Colors.red.shade900 : Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Category: ${a.category} • Triggered: ${df.format(a.triggeredAt)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Current Stock: ${a.currentStock.toStringAsFixed(a.currentStock % 1 == 0 ? 0 : 2)} ${a.unit} (Threshold: ${a.threshold} ${a.unit})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isZero ? Colors.red.shade700 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canAcknowledge)
                                    OutlinedButton(
                                      onPressed: () async {
                                        await ref.read(alertsProvider.notifier).acknowledgeAlert(a.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Alert acknowledged for ${a.productName}')),
                                          );
                                        }
                                      },
                                      child: const Text('Acknowledge'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

