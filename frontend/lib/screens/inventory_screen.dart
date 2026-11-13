import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  void _showAdjustStockDialog() {
    final products = ref.read(productsProvider).products;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to adjust.')),
      );
      return;
    }

    Product selectedProduct = products.first;
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String movementType = 'RESTOCK';
    bool isAdding = true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentStock = selectedProduct.currentStock;
          final inputQty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
          final effectiveChange = isAdding ? inputQty : -inputQty;
          final projectedNewStock = currentStock + effectiveChange;
          final willBeNegative = projectedNewStock < 0;

          return AlertDialog(
            title: const Text('Authorized Stock Adjustment'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Selector
                    DropdownButtonFormField<Product>(
                      initialValue: selectedProduct,
                      decoration: const InputDecoration(labelText: 'Select Product *', border: OutlineInputBorder()),
                      items: products.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (Cur: ${p.currentStock} ${p.unit})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedProduct = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Add vs Deduct toggle
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('+ Restock / Add')),
                            selected: isAdding,
                            selectedColor: Colors.green.shade100,
                            onSelected: (val) {
                              setDialogState(() {
                                isAdding = true;
                                movementType = 'RESTOCK';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('- Reduce / Damage')),
                            selected: !isAdding,
                            selectedColor: Colors.red.shade100,
                            onSelected: (val) {
                              setDialogState(() {
                                isAdding = false;
                                movementType = 'DAMAGED';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Movement Type
                    DropdownButtonFormField<String>(
                      initialValue: movementType,
                      decoration: const InputDecoration(labelText: 'Adjustment Type *', border: OutlineInputBorder()),
                      items: [
                        if (isAdding) ...[
                          const DropdownMenuItem(value: 'RESTOCK', child: Text('RESTOCK (Inventory shipment)')),
                          const DropdownMenuItem(value: 'CORRECTION', child: Text('CORRECTION (Audit count surplus)')),
                        ] else ...[
                          const DropdownMenuItem(value: 'DAMAGED', child: Text('DAMAGED (Spoilage or broken)')),
                          const DropdownMenuItem(value: 'CORRECTION', child: Text('CORRECTION (Audit count deficit)')),
                          const DropdownMenuItem(value: 'ADJUSTMENT', child: Text('ADJUSTMENT (General reduction)')),
                        ],
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => movementType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quantity
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity to ${isAdding ? "Add" : "Reduce"} (${selectedProduct.unit}) *',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Must be greater than 0';
                        if (!isAdding && (currentStock - num < 0)) {
                          return 'Cannot reduce below zero (Negative stock prevented)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mandatory Reason (PRD §5.2)
                    TextFormField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mandatory Reason *',
                        helperText: 'e.g. Broken in storage, Weekly supplier delivery',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required by PRD' : null,
                    ),
                    const SizedBox(height: 16),

                    // Live Stock Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: willBeNegative ? Colors.red.shade50 : Colors.grey.shade100,
                        border: Border.all(color: willBeNegative ? Colors.red : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Stock:'),
                              Text('$currentStock ${selectedProduct.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Projected New Stock:'),
                              Text(
                                '${projectedNewStock.toStringAsFixed(projectedNewStock % 1 == 0 ? 0 : 2)} ${selectedProduct.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: willBeNegative ? Colors.red : Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          if (willBeNegative)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'PRD Rule: Negative stock is prohibited.',
                                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: willBeNegative
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final qty = double.parse(qtyCtrl.text.trim());
                          final finalChange = isAdding ? qty : -qty;

                          final success = await ref.read(inventoryProvider.notifier).adjustStock(
                                productId: selectedProduct.id,
                                quantityChange: finalChange,
                                movementType: movementType,
                                reason: reasonCtrl.text.trim(),
                              );

                          if (success) {
                            ref.read(productsProvider.notifier).fetchProducts();
                            if (context.mounted) Navigator.of(context).pop();
                          } else {
                            final err = ref.read(inventoryProvider).errorMessage;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err ?? 'Error adjusting stock'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                child: const Text('Confirm Adjustment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryProvider);
    final user = ref.watch(authProvider).user;
    final shop = ref.watch(authProvider).shop;
    final currency = shop?.currency ?? '₹';
    final canAdjust = user?.hasPermission('UPDATE_STOCK') ?? false;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    final summary = invState.summary;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(inventoryProvider.notifier).fetchInventoryData();
        await ref.read(productsProvider.notifier).fetchProducts();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Inventory Control & Valuation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (canAdjust)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _showAdjustStockDialog,
                    icon: const Icon(Icons.tune),
                    label: const Text('Adjust Stock'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary KPI Cards (PRD §5.2 & §8)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 700;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildKpiCard(
                      'Total Active Items',
                      '${summary?.totalProducts ?? 0}',
                      Icons.category_outlined,
                      Colors.blue,
                      isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                    ),
                    _buildKpiCard(
                      'Stock Units on Hand',
                      '${summary?.totalStockUnits.toStringAsFixed(0) ?? "0"} units',
                      Icons.inventory_2_outlined,
                      Colors.teal,
                      isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                    ),
                    _buildKpiCard(
                      'Cost Basis Valuation',
                      '$currency${summary?.totalStockCostValue.toStringAsFixed(2) ?? "0.00"}',
                      Icons.account_balance_wallet_outlined,
                      Colors.indigo,
                      isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                    ),
                    _buildKpiCard(
                      'Low Stock Alerts',
                      '${summary?.lowStockCount ?? 0}',
                      Icons.warning_amber_rounded,
                      Colors.amber.shade800,
                      isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Stock Movement Audit Ledger (PRD §5.2 & §10.1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stock Movement Ledger (Audit Trail)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(inventoryProvider.notifier).fetchInventoryData(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            invState.isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : invState.movements.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No stock movements recorded yet.', style: TextStyle(color: Colors.grey[600]))))
                    : Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invState.movements.length,
                          separatorBuilder: (_, index) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final m = invState.movements[idx];
                            final isPositive = m.quantityChange > 0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                                child: Icon(
                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(m.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getMovementTypeColor(m.movementType),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m.movementType,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Reason: ${m.reason ?? "N/A"} • By: ${m.userName} • ${df.format(m.createdAt)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isPositive ? "+" : ""}${m.quantityChange.toStringAsFixed(m.quantityChange % 1 == 0 ? 0 : 2)} ${m.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${m.previousStock} → ${m.newStock} ${m.unit}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Color _getMovementTypeColor(String type) {
    switch (type) {
      case 'SALE':
        return Colors.blue.shade700;
      case 'RESTOCK':
        return Colors.green.shade700;
      case 'DAMAGED':
        return Colors.red.shade700;
      case 'OPENING_STOCK':
        return Colors.indigo.shade700;
      case 'CORRECTION':
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

