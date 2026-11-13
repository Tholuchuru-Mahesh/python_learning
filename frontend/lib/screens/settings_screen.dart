import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currencyController = TextEditingController();
  final _taxController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final shop = ref.read(authProvider).shop;
    if (shop != null) {
      _nameController.text = shop.name;
      _addressController.text = shop.address ?? '';
      _phoneController.text = shop.phone ?? '';
      _currencyController.text = shop.currency;
      _taxController.text = shop.taxPercentage.toString();
      _headerController.text = shop.receiptHeader ?? '';
      _footerController.text = shop.receiptFooter ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _currencyController.dispose();
    _taxController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final api = ApiService();
      final res = await api.put('/api/shop/profile', body: {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'currency': _currencyController.text.trim(),
        'taxPercentage': double.tryParse(_taxController.text.trim()) ?? 0.0,
        'receiptHeader': _headerController.text.trim(),
        'receiptFooter': _footerController.text.trim(),
      });

      final updatedShop = Shop.fromJson(res as Map<String, dynamic>);
      ref.read(authProvider.notifier).updateShop(updatedShop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop settings updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Shop Profile & Receipt Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('PRD §5.1: Manage shop identity, receipt header/footer, and tax rates.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Divider(height: 24),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Shop Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currencyController,
                          decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. ₹, \$)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Default Tax Rate (%)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _headerController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Header Message',
                      helperText: 'Appears at top of printed thermal receipts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _footerController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Footer Message',
                      helperText: 'Appears at bottom of printed thermal receipts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Shop Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

