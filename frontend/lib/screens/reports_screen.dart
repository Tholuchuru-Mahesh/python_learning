import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../providers/auth_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  void _setPeriod(String label, int daysAgo) {
    final now = DateTime.now();
    final end = DateFormat('yyyy-MM-dd').format(now);
    final start = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: daysAgo)));

    ref.read(reportsProvider.notifier).fetchSalesProfitSummary(
          startDate: start,
          endDate: end,
          periodLabel: label,
        );
    ref.read(reportsProvider.notifier).fetchExpenses(startDate: start, endDate: end);
  }

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'PACKAGING';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Record Shop Expense (PRD §5.7)'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Expense Title *', helperText: 'e.g. Shop Rent, Electricity, Bags', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                      DropdownMenuItem(value: 'UTILITY', child: Text('Utility (Electricity, Water)')),
                      DropdownMenuItem(value: 'PACKAGING', child: Text('Packaging & Bags')),
                      DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                      DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder()),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Valid amount' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    await ref.read(reportsProvider.notifier).createExpense(
                          title: titleCtrl.text.trim(),
                          category: category,
                          amount: double.parse(amountCtrl.text.trim()),
                          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: const Text('Save Expense'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _downloadCsv(String type) async {
    try {
      final String csvContent;
      if (type == 'sales') {
        csvContent = await ref.read(reportsProvider.notifier).downloadSalesCsv();
      } else {
        csvContent = await ref.read(reportsProvider.notifier).downloadInventoryCsv();
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('$type Report CSV Exported'),
            content: SizedBox(
              width: 500,
              height: 250,
              child: SingleChildScrollView(
                child: SelectableText(
                  csvContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final user = ref.watch(authProvider).user;
    final shop = ref.watch(authProvider).shop;
    final currency = shop?.currency ?? '₹';
    final canViewProfit = user?.hasPermission('VIEW_PROFIT_REPORTS') ?? false;

    final today = reportsState.todayOverview;
    final summary = reportsState.salesProfitSummary;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportsProvider.notifier).fetchInitialReports();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar with CSV Exports
            Row(
              children: [
                const Text('Sales & Profitability Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Sales CSV'),
                  onPressed: () => _downloadCsv('sales'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Inventory CSV'),
                  onPressed: () => _downloadCsv('inventory'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1: Today's Sales Overview (PRD §5.4)
            const Text("Today's Performance (PRD §5.4)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard("Today's Revenue", '$currency${today?.todaySalesValue.toStringAsFixed(2) ?? "0.00"}', Icons.monetization_on_outlined, Colors.indigo, cardWidth),
                    _buildMetricCard("Today's Bills", '${today?.todayBillsCount ?? 0} bills', Icons.receipt_long_outlined, Colors.blue, cardWidth),
                    _buildMetricCard(
                      'Top Selling (by Units)',
                      today?.topSellingProductByQuantity != null
                          ? '${today!.topSellingProductByQuantity!.name}\n(${today.topSellingProductByQuantity!.quantity} ${today.topSellingProductByQuantity!.unit})'
                          : 'No sales yet',
                      Icons.trending_up,
                      Colors.green.shade700,
                      cardWidth,
                    ),
                    _buildMetricCard(
                      'Top Revenue Product',
                      today?.topRevenueProduct != null
                          ? '${today!.topRevenueProduct!.name}\n($currency${today.topRevenueProduct!.revenue.toStringAsFixed(2)})'
                          : 'No sales yet',
                      Icons.star_outline,
                      Colors.amber.shade900,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 2: Period Filter Selector
            Row(
              children: [
                Text('Performance Period: ${reportsState.selectedPeriodLabel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Today', label: Text('Today')),
                    ButtonSegment(value: 'Last 7 Days', label: Text('7 Days')),
                    ButtonSegment(value: 'Last 30 Days', label: Text('30 Days')),
                  ],
                  selected: {reportsState.selectedPeriodLabel},
                  onSelectionChanged: (set) {
                    final sel = set.first;
                    if (sel == 'Today') _setPeriod('Today', 0);
                    if (sel == 'Last 7 Days') _setPeriod('Last 7 Days', 7);
                    if (sel == 'Last 30 Days') _setPeriod('Last 30 Days', 30);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Profit & Loss Summary (PRD §5.5 & §8)
            if (canViewProfit && summary != null) ...[
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Gross Profit & Margins (PRD §5.5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(4)),
                            child: Text('Gross Margin: ${summary.grossMarginPercentage}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfitCol('Total Sales Revenue', '$currency${summary.totalRevenue.toStringAsFixed(2)}'),
                          _buildProfitCol('Recorded Cost Basis', '$currency${summary.totalCostBasis.toStringAsFixed(2)}'),
                          _buildProfitCol('Total Discounts', '-$currency${summary.totalDiscountAmount.toStringAsFixed(2)}'),
                          _buildProfitCol('Estimated Gross Profit', '$currency${summary.estimatedGrossProfit.toStringAsFixed(2)}', isBold: true, color: Colors.indigo.shade900),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Labeled strictly as Estimated Gross Profit (before operating expenses and taxes) in accordance with PRD §5.5.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 3: Operating Result & Expenses (PRD §5.7)
            if (canViewProfit) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shop Expenses & Operating Result (PRD §5.7)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                            onPressed: _showAddExpenseDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Expense'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (summary?.hasRecordedExpenses ?? false)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Recorded Expenses: $currency${summary!.totalExpenses.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                'Estimated Operating Result: $currency${summary.estimatedOperatingResult?.toStringAsFixed(2) ?? "N/A"}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal.shade900),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No expenses recorded for this period. As per PRD §5.7, definitive operating results are presented only when expense data is entered.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      if (reportsState.expenses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Recorded Expenses:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        ...reportsState.expenses.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text(e.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.title, style: const TextStyle(fontSize: 13))),
                                Text('$currency${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                  onPressed: () => ref.read(reportsProvider.notifier).deleteExpense(e.id),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 4: Product Performance Breakdown Table
            const Text('Product-wise Sales Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              child: summary?.productPerformance.isEmpty ?? true
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No product sales recorded in selected period.', style: TextStyle(color: Colors.grey[600]))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary!.productPerformance.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final p = summary.productPerformance[idx];
                        return ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty Sold: ${p.quantitySold} ${p.unit} • Sales: $currency${p.salesValue.toStringAsFixed(2)}'),
                          trailing: canViewProfit
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Gross Profit: $currency${p.estimatedGrossProfit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    Text('Margin: ${p.grossMarginPercentage}%', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitCol(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }
}

