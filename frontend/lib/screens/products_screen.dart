import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../providers/auth_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([Product? product]) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final catCtrl = TextEditingController(text: product?.category ?? 'General');
    String selectedUnit = product?.unit ?? 'piece';
    final costCtrl = TextEditingController(text: product != null ? product.purchaseCost.toString() : '');
    final priceCtrl = TextEditingController(text: product != null ? product.sellingPrice.toString() : '');
    final openingStockCtrl = TextEditingController(text: product != null ? product.currentStock.toString() : '0');
    final thresholdCtrl = TextEditingController(text: product != null ? product.lowStockThreshold.toString() : '5');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: catCtrl,
                            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'piece', child: Text('Piece')),
                              DropdownMenuItem(value: 'packet', child: Text('Packet')),
                              DropdownMenuItem(value: 'bottle', child: Text('Bottle')),
                              DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                              DropdownMenuItem(value: 'litre', child: Text('Litre (L)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Purchase Cost *',
                              helperText: 'For gross profit basis',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Selling Price *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!isEditing)
                          Expanded(
                            child: TextFormField(
                              controller: openingStockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Opening Stock',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        if (!isEditing) const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: thresholdCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Low Stock Alert Threshold',
                              helperText: 'Alerts owner when <=',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final cost = double.parse(costCtrl.text.trim());
                    final price = double.parse(priceCtrl.text.trim());
                    final threshold = double.parse(thresholdCtrl.text.trim());

                    if (isEditing) {
                      await ref.read(productsProvider.notifier).updateProduct(
                            id: product.id,
                            name: nameCtrl.text.trim(),
                            category: catCtrl.text.trim(),
                            unit: selectedUnit,
                            purchaseCost: cost,
                            sellingPrice: price,
                            lowStockThreshold: threshold,
                            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                          );
                    } else {
                      final opening = double.tryParse(openingStockCtrl.text.trim()) ?? 0.0;
                      await ref.read(productsProvider.notifier).createProduct(
                            name: nameCtrl.text.trim(),
                            category: catCtrl.text.trim(),
                            unit: selectedUnit,
                            purchaseCost: cost,
                            sellingPrice: price,
                            openingStock: opening,
                            lowStockThreshold: threshold,
                            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                          );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final user = ref.watch(authProvider).user;
    final shop = ref.watch(authProvider).shop;
    final currency = shop?.currency ?? '₹';
    final canEdit = user?.hasPermission('ADD_EDIT_PRODUCTS') ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name or category...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(productsProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => ref.read(productsProvider.notifier).setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),
              if (canEdit)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Categories
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: productsState.categories.map((cat) {
                final isSelected = (productsState.selectedCategory ?? 'All') == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(productsProvider.notifier).setCategory(cat == 'All' ? null : cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Product List Table
          Expanded(
            child: productsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productsState.filteredProducts.isEmpty
                    ? Center(child: Text('No products found', style: TextStyle(color: Colors.grey[600])))
                    : Card(
                        child: ListView.separated(
                          itemCount: productsState.filteredProducts.length,
                          separatorBuilder: (_, index) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final p = productsState.filteredProducts[idx];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.isLowStock ? Colors.amber.shade100 : Colors.indigo.shade50,
                                child: Icon(
                                  p.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                                  color: p.isLowStock ? Colors.amber.shade900 : Colors.indigo,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                    child: Text(p.category, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                                  ),
                                  if (p.isLowStock)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('LOW STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Unit: ${p.unit} • Cost: $currency${p.purchaseCost.toStringAsFixed(2)} • Selling: $currency${p.sellingPrice.toStringAsFixed(2)} • Threshold: ${p.lowStockThreshold}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: ${p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 2)} ${p.unit}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: p.isLowStock ? Colors.red.shade700 : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Val: $currency${(p.currentStock * p.sellingPrice).toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  if (canEdit) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showAddEditDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Deactivate Product'),
                                            content: Text('Are you sure you want to deactivate "${p.name}"?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                onPressed: () async {
                                                  await ref.read(productsProvider.notifier).deactivateProduct(p.id);
                                                  if (c.mounted) Navigator.of(c).pop();
                                                },
                                                child: const Text('Deactivate'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

