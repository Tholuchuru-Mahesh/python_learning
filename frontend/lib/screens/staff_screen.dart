import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/staff_provider.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  static const Map<String, String> _permissionDescriptions = {
    'CREATE_BILLS': 'Create and save customer bills',
    'VIEW_PRODUCTS': 'See the product catalogue and item details',
    'ADD_EDIT_PRODUCTS': 'Create products or change permitted product details',
    'UPDATE_STOCK': 'Make authorized stock adjustments',
    'VIEW_SALES_REPORTS': 'See sales totals and item-wise sales reports',
    'VIEW_PROFIT_REPORTS': 'See purchase-cost basis, sales value and estimated gross profit',
    'MANAGE_STAFF': 'Create staff accounts and change their permissions',
    'SHOP_SETTINGS': 'Change shop profile, tax/receipt settings, alert thresholds',
  };

  void _showAddEditStaffDialog([User? staff]) {
    final isEditing = staff != null;
    final nameCtrl = TextEditingController(text: staff?.fullName ?? '');
    final usernameCtrl = TextEditingController(text: staff?.username ?? '');
    final passwordCtrl = TextEditingController();

    // Checkbox permissions list (PRD §4.1/4.2)
    final Set<String> selectedPermissions = Set<String>.from(
      staff?.permissions ?? ['CREATE_BILLS', 'VIEW_PRODUCTS'],
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Staff Permissions' : 'Create Staff Account'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isEditing) ...[
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Staff Full Name *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.length < 3 ? 'Min 3 chars' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Owner-Controlled Permissions (PRD §4.1 & §4.2):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the individual actions this staff member is authorized to perform.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 8),

                      // 8 Permission Checkboxes (PRD §4.2)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _permissionDescriptions.entries.map((entry) {
                            final permCode = entry.key;
                            final permLabel = entry.value;
                            final isChecked = selectedPermissions.contains(permCode);

                            return CheckboxListTile(
                              dense: true,
                              title: Text(permCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text(permLabel, style: const TextStyle(fontSize: 11)),
                              value: isChecked,
                              activeColor: Colors.indigo,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedPermissions.add(permCode);
                                  } else {
                                    selectedPermissions.remove(permCode);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    if (isEditing) {
                      await ref.read(staffProvider.notifier).updateStaffPermissions(
                            staffId: staff.id,
                            permissions: selectedPermissions.toList(),
                          );
                    } else {
                      await ref.read(staffProvider.notifier).createStaff(
                            fullName: nameCtrl.text.trim(),
                            username: usernameCtrl.text.trim(),
                            password: passwordCtrl.text,
                            permissions: selectedPermissions.toList(),
                          );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: Text(isEditing ? 'Update Permissions' : 'Create Staff'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Staff Management & Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(
                    'PRD §4.1: Access controlled via granular checkboxes instead of rigid role titles.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () => _showAddEditStaffDialog(),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Staff Account'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: staffState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: staffState.staffList.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final s = staffState.staffList[idx];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: s.isOwner ? Colors.amber.shade100 : Colors.indigo.shade50,
                                    child: Icon(
                                      s.isOwner ? Icons.admin_panel_settings : Icons.person_outline,
                                      color: s.isOwner ? Colors.amber.shade900 : Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(width: 8),
                                            if (s.isOwner)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('OWNER / FULL ACCESS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              )
                                            else if (!s.isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('REVOKED', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        Text('Username: ${s.username}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  if (!s.isOwner) ...[
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.checklist, size: 16),
                                      label: const Text('Permissions'),
                                      onPressed: () => _showAddEditStaffDialog(s),
                                    ),
                                    const SizedBox(width: 8),
                                    if (s.isActive)
                                      IconButton(
                                        icon: const Icon(Icons.block, color: Colors.red, size: 20),
                                        tooltip: 'Revoke Access (PRD §4.2)',
                                        onPressed: () async {
                                          await ref.read(staffProvider.notifier).revokeStaff(s.id);
                                        },
                                      ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: s.permissions.map((p) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(p, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
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

