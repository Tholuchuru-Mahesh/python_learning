import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRegistering = false;

  final _usernameController = TextEditingController(text: 'owner');
  final _passwordController = TextEditingController(text: 'password123');

  // Register fields
  final _shopNameController = TextEditingController();
  final _ownerFullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _currencyController = TextEditingController(text: '₹');
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _ownerFullNameController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _currencyController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _submitRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).registerShop(
            shopName: _shopNameController.text.trim(),
            ownerFullName: _ownerFullNameController.text.trim(),
            username: _regUsernameController.text.trim(),
            password: _regPasswordController.text,
            currency: _currencyController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(Icons.storefront_rounded, size: 56, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        'Unified POS Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegistering ? 'Register your shop & owner account' : 'Sign in to access your retail POS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Error message banner
                      if (authState.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!_isRegistering) ...[
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onFieldSubmitted: (_) => _submitLogin(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: authState.status == AuthStatus.loading ? null : _submitLogin,
                          child: authState.status == AuthStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        // Demo Accounts Quick Selection
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quick Demo Accounts:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.admin_panel_settings, size: 14),
                                    label: const Text('Owner', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _usernameController.text = 'owner';
                                        _passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.point_of_sale, size: 14),
                                    label: const Text('Cashier', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _usernameController.text = 'cashier';
                                        _passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.inventory_2, size: 14),
                                    label: const Text('Inventory Clerk', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _usernameController.text = 'inventory';
                                        _passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _shopNameController,
                          decoration: const InputDecoration(labelText: 'Shop Name *', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ownerFullNameController,
                          decoration: const InputDecoration(labelText: 'Owner Full Name *', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _regUsernameController,
                                decoration: const InputDecoration(labelText: 'Username *', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                                validator: (v) => v == null || v.length < 3 ? 'Min 3 chars' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _currencyController,
                                decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: authState.status == AuthStatus.loading ? null : _submitRegister,
                          child: authState.status == AuthStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Register Shop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                          });
                        },
                        child: Text(
                          _isRegistering ? 'Already registered? Sign in here' : 'New shop owner? Register your shop',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

