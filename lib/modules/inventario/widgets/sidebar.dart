// Sidebar do módulo Inventário - usa SharedSidebar
import 'package:flutter/material.dart';
import '../../shared/sidebar_shared.dart';

class InventarioSidebar extends StatelessWidget {
  final Function(int) onNavigate;
  final int selectedIndex;

  const InventarioSidebar({
    super.key,
    required this.onNavigate,
    this.selectedIndex = 0,
  });

  List<SidebarItem> _getMenuItems(
    String? userUf,
    bool isAdmin,
    bool hasReportAccess,
  ) {
    final items = [
      const SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        index: 0,
      ),
      const SidebarItem(icon: Icons.list, label: 'Lista', index: 1),
      const SidebarItem(icon: Icons.search, label: 'Pesquisar', index: 2),
      const SidebarItem(
        icon: Icons.delete_sweep_outlined,
        label: 'Lixeira',
        index: 3,
      ),
      if (userUf != null)
        const SidebarItem(
          icon: Icons.document_scanner_outlined,
          label: 'Formulário',
          index: 4,
        ),
    ];

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SharedSidebar(
      onNavigate: onNavigate,
      selectedIndex: selectedIndex,
      getMenuItems: _getMenuItems,
    );
  }
}
