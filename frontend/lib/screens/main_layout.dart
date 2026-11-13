import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/alerts_provider.dart';
import 'billing_screen.dart';
import 'products_screen.dart';
import 'inventory_screen.dart';
import 'alerts_screen.dart';
import 'reports_screen.dart';
import 'staff_screen.dart';
import 'settings_screen.dart';

class NavTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget widget;
  final String? requiredPermission;

  NavTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.widget,
    this.requiredPermission,
  });
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  List<NavTabItem> _getPermittedTabs(User? user) {
    final allTabs = [
      NavTabItem(
        label: 'POS Billing',
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale,
        widget: const BillingScreen(),
        requiredPermission: 'CREATE_BILLS',
      ),
      NavTabItem(
        label: 'Catalogue',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        widget: const ProductsScreen(),
        requiredPermission: 'VIEW_PRODUCTS',
      ),
      NavTabItem(
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        widget: const InventoryScreen(),
        requiredPermission: 'VIEW_PRODUCTS',
      ),
      NavTabItem(
        label: 'Low-Stock',
        icon: Icons.notifications_none_outlined,
        activeIcon: Icons.notifications,
        widget: const AlertsScreen(),
        requiredPermission: 'VIEW_PRODUCTS',
      ),
      NavTabItem(
        label: 'Reports',
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        widget: const ReportsScreen(),
        requiredPermission: 'VIEW_SALES_REPORTS',
      ),
      NavTabItem(
        label: 'Staff',
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
        widget: const StaffScreen(),
        requiredPermission: 'MANAGE_STAFF',
      ),
      NavTabItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        widget: const SettingsScreen(),
        requiredPermission: 'SHOP_SETTINGS',
      ),
    ];

    if (user == null) return [];

    return allTabs.where((tab) {
      if (user.isOwner) return true;
      if (tab.requiredPermission == null) return true;
      return user.hasPermission(tab.requiredPermission!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final alertsState = ref.watch(alertsProvider);
    final user = authState.user;
    final shop = authState.shop;

    final permittedTabs = _getPermittedTabs(user);

    if (permittedTabs.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No accessible modules granted to this staff account.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedIndex >= permittedTabs.length) {
      _selectedIndex = 0;
    }

    final currentTab = permittedTabs[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 840;

        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            title: Row(
              children: [
                Icon(Icons.store, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                Text(
                  shop?.name ?? 'Unified POS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    shop?.currency ?? '₹',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                  ),
                ),
              ],
            ),
            actions: [
              // Low stock alert bell badge (PRD §5.6)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Low-Stock Alerts',
                    onPressed: () {
                      final alertTabIndex = permittedTabs.indexWhere((t) => t.label == 'Low-Stock');
                      if (alertTabIndex >= 0) {
                        setState(() => _selectedIndex = alertTabIndex);
                      }
                    },
                  ),
                  if (alertsState.alertCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '${alertsState.alertCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),

              // User Info Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user?.isOwner ?? false ? Colors.amber.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: user?.isOwner ?? false ? Colors.amber.shade400 : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      user?.isOwner ?? false ? Icons.admin_panel_settings : Icons.person,
                      size: 14,
                      color: user?.isOwner ?? false ? Colors.amber.shade900 : Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: user?.isOwner ?? false ? Colors.amber.shade900 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                tooltip: 'Sign Out',
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Colors.indigo),
                  selectedLabelTextStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey[700], fontSize: 11),
                  destinations: permittedTabs.map((tab) {
                    return NavigationRailDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.activeIcon),
                      label: Text(tab.label),
                    );
                  }).toList(),
                ),
              if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: currentTab.widget),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  destinations: permittedTabs.map((tab) {
                    return NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.activeIcon),
                      label: tab.label,
                    );
                  }).toList(),
                )
              : null,
        );
      },
    );
  }
}

