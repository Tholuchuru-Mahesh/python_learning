import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/billing_provider.dart';
import '../providers/offline_billing_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/offline_queue_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(authProvider).shop;
      if (shop != null) {
        ref.read(cartProvider.notifier).setTaxPercentage(shop.taxPercentage);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _completeBill() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add products to create a bill.')),
      );
      return;
    }

    final bill = await ref.read(billingProvider.notifier).createBill(
          items: cart.items,
          discountAmount: cart.discountAmount,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

    if (bill != null) {
      // Clear cart
      ref.read(cartProvider.notifier).clear();
      _discountController.clear();
      _notesController.clear();
      // Refresh products to reflect new stock quantities
      ref.read(productsProvider.notifier).fetchProducts();

      // Show receipt modal immediately
      if (mounted) {
        ReceiptDialog.show(context, bill);
      }
    } else {
      final error = ref.read(billingProvider).errorMessage ?? 'Network unreachable';
      // Fallback to Offline Persistent Queue (PRD Release 1)
      final offlineBill = await ref.read(offlineBillingProvider.notifier).enqueueOfflineBill(
            cartItems: cart.items,
            subtotal: cart.subtotal,
            discountAmount: cart.discountAmount,
            taxAmount: cart.taxAmount,
            finalTotal: cart.finalTotal,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      ref.read(cartProvider.notifier).clear();
      _discountController.clear();
      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Network error ($error). Bill saved locally to Offline Queue (${offlineBill.localId}). Will auto-sync when online.',
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View Queue',
              textColor: Colors.white,
              onPressed: () => OfflineQueueDialog.show(context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productsState = ref.watch(productsProvider);
    final billingState = ref.watch(billingProvider);
    final shop = ref.watch(authProvider).shop;
    final currency = shop?.currency ?? '₹';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        if (_showHistory) {
          return _buildBillHistoryView(billingState, currency);
        }

        return isWide
            ? Row(
                children: [
                  // Left: Products Grid
                  Expanded(
                    flex: 6,
                    child: _buildProductsPanel(productsState, currency),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: Cart Panel
                  Expanded(
                    flex: 4,
                    child: _buildCartPanel(cart, billingState, currency),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildProductsPanel(productsState, currency)),
                  Container(
                    color: Colors.white,
                    child: ExpansionTile(
                      title: Text(
                        'Cart (${cart.itemCount} items) • $currency${cart.finalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        SizedBox(
                          height: 320,
                          child: _buildCartPanel(cart, billingState, currency),
                        ),
                      ],
                    ),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildProductsPanel(ProductsState productsState, String currency) {
    return Column(
      children: [
        // Top Toolbar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
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
                  onChanged: (val) {
                    ref.read(productsProvider.notifier).setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) {
                  final offState = ref.watch(offlineBillingProvider);
                  return Badge(
                    isLabelVisible: offState.totalUnsynced > 0,
                    label: Text('${offState.totalUnsynced}'),
                    backgroundColor: Colors.orange,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.cloud_sync_outlined,
                        size: 18,
                        color: offState.totalUnsynced > 0 ? Colors.orange.shade800 : null,
                      ),
                      label: const Text('Offline Queue'),
                      onPressed: () => OfflineQueueDialog.show(context),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Bills / Reprint'),
                onPressed: () {
                  ref.read(billingProvider.notifier).fetchBills();
                  setState(() => _showHistory = true);
                },
              ),
            ],
          ),
        ),

        // Category Filter Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: productsState.categories.map((cat) {
              final isSelected = (productsState.selectedCategory ?? 'All') == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: Colors.indigo,
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
        const SizedBox(height: 8),

        // Products Grid
        Expanded(
          child: productsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productsState.filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        'No products found matching your search.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 210,
                        childAspectRatio: 1.25,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: productsState.filteredProducts.length,
                      itemBuilder: (ctx, idx) {
                        final product = productsState.filteredProducts[idx];
                        return _buildProductCard(product, currency);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, String currency) {
    final isOutOfStock = product.currentStock <= 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: product.isLowStock ? Colors.orange.shade300 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isOutOfStock
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} is currently out of stock')),
                );
              }
            : () {
                ref.read(cartProvider.notifier).addToCart(product);
              },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.shade100
                          : (product.isLowStock ? Colors.amber.shade100 : Colors.green.shade100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOutOfStock
                          ? 'Out'
                          : '${product.currentStock.toStringAsFixed(product.currentStock % 1 == 0 ? 0 : 2)} ${product.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? Colors.red.shade900
                            : (product.isLowStock ? Colors.amber.shade900 : Colors.green.shade900),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currency${product.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                  ),
                  const Icon(Icons.add_shopping_cart, size: 18, color: Colors.indigo),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(CartState cart, BillingState billingState, String currency) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Bill (${cart.itemCount} items)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (cart.items.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                  onPressed: () {
                    ref.read(cartProvider.notifier).clear();
                  },
                ),
            ],
          ),
          const Divider(),

          // Cart Items List
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Your cart is empty', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('Click items on the left to add them to this bill', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, index) => const Divider(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = cart.items[idx];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  '$currency${item.unitPrice.toStringAsFixed(2)} / ${item.product.unit}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Stepper
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1);
                                },
                              ),
                              Text(
                                item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1);
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '$currency${item.lineTotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () {
                              ref.read(cartProvider.notifier).removeFromCart(item.product.id);
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const Divider(),

          // Discount & Notes
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount ($currency)',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    ref.read(cartProvider.notifier).setDiscount(d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Notes (optional)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Financial Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 13)),
              Text('$currency${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (cart.discountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(fontSize: 13, color: Colors.green)),
                  Text('-$currency${cart.discountAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
                ],
              ),
            ),
          if (cart.taxAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax (${cart.taxPercentage}%)', style: const TextStyle(fontSize: 13)),
                  Text('+$currency${cart.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '$currency${cart.finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button (PRD §5.3)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: cart.items.isEmpty || billingState.isLoading ? null : _completeBill,
            icon: billingState.isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Complete & Print Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBillHistoryView(BillingState billingState, String currency) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showHistory = false),
              ),
              const SizedBox(width: 8),
              const Text('Completed Bills & Reprint History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(billingProvider.notifier).fetchBills(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: billingState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : billingState.bills.isEmpty
                  ? Center(child: Text('No bills recorded yet.', style: TextStyle(color: Colors.grey[600])))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: billingState.bills.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final b = billingState.bills[idx];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade50,
                              child: const Icon(Icons.receipt, color: Colors.indigo),
                            ),
                            title: Row(
                              children: [
                                Text(b.billNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (b.reprintCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Reprinted x${b.reprintCount}', style: TextStyle(fontSize: 10, color: Colors.amber.shade900)),
                                  ),
                              ],
                            ),
                            subtitle: Text('Cashier: ${b.staffName ?? "Staff"} • ${b.itemCount} items'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$currency${b.finalTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.black87,
                                  ),
                                  icon: const Icon(Icons.print, size: 16),
                                  label: const Text('Reprint'),
                                  onPressed: () async {
                                    final reprintBill = await ref.read(billingProvider.notifier).reprintBill(b.id);
                                    if (reprintBill != null && mounted) {
                                      ReceiptDialog.show(context, reprintBill);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

