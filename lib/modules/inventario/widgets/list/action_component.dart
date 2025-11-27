// Componentes de ação da lista (v2)
import 'package:flutter/material.dart';

import '../../../../core/utilities/shared/responsive.dart';
import '../../../../core/design_system.dart';

class InventarioActionComponents {
  static Widget buildBlueActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isMainAction = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E5EA4),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(77, 30, 94, 164),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(child: Icon(icon, color: Colors.white, size: 20)),
          ),
        ),
      ),
    );
  }

  static Widget buildSortButton({
    required String title,
    required String sortKey,
    required String currentSortBy,
    required VoidCallback onTap,
    TextAlign alignment = TextAlign.start,
  }) {
    final isActive = _isSortActive(sortKey, currentSortBy);

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment == TextAlign.end
              ? MainAxisAlignment.end
              : alignment == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: alignment,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _getSortIcon(sortKey, currentSortBy),
              size: 16,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildPagination({
    required BuildContext context,
    required int currentPage,
    required int totalPages,
    required VoidCallback onPreviousPage,
    required VoidCallback onNextPage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Responsive.shouldUseIconOnlyPagination(context)
              ? IconButton(
                  onPressed: currentPage > 0 ? onPreviousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Anterior',
                )
              : ElevatedButton.icon(
                  onPressed: currentPage > 0 ? onPreviousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
          const SizedBox(width: 16),
          Text(
            'Página ${currentPage + 1} de $totalPages',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          Responsive.shouldUseIconOnlyPagination(context)
              ? IconButton(
                  onPressed: currentPage < totalPages - 1 ? onNextPage : null,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Próxima',
                )
              : ElevatedButton.icon(
                  onPressed: currentPage < totalPages - 1 ? onNextPage : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Próxima'),
                ),
        ],
      ),
    );
  }

  static Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: Responsive.largeIconSize(context) * 2.5,
            color: Colors.grey[400],
          ),
          SizedBox(height: Responsive.spacing(context)),
          Text(
            'Nenhum item de inventário encontrado',
            style: TextStyle(
              fontSize: Responsive.subHeaderFontSize(context),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.smallSpacing(context)),
          Text(
            'Tente ajustar os filtros ou adicionar novos itens',
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildHeaderSection({
    required BuildContext context,
    required VoidCallback onClearFilters,
    required VoidCallback onRefresh,
    required VoidCallback? onCreateNew,
    required VoidCallback? onDataChanged,
    VoidCallback? onImportCsv,
    bool showCreateButton = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            Responsive.isMobile(context) ? 'Lista' : 'Lista de Inventário',
            style: TextStyle(
              fontSize: Responsive.headerFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: Responsive.smallSpacing(context),
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Limpar filtros',
              onPressed: () {
                onClearFilters();
                onDataChanged?.call();
              },
              style: AppDesignSystem.secondaryButton.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: onRefresh,
              style: AppDesignSystem.secondaryButton.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
            if (onImportCsv != null)
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Importar CSV',
                onPressed: onImportCsv,
                style: AppDesignSystem.secondaryButton.copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
            if (showCreateButton && onCreateNew != null)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Novo Item',
                onPressed: onCreateNew,
                style: AppDesignSystem.secondaryButton.copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Widget buildSortControls({
    required BuildContext context,
    required String currentSortBy,
    required List<String> sortOptions,
    required Function(String) onSortChanged,
  }) {
    return Row(
      children: [
        Text(
          Responsive.isMobile(context) ? 'Ordenar:' : 'Ordenar por:',
          style: TextStyle(fontSize: Responsive.bodyFontSize(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButton<String>(
            value: currentSortBy,
            isExpanded: true,
            onChanged: (newValue) {
              if (newValue != null) {
                onSortChanged(newValue);
              }
            },
            items: sortOptions
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: Responsive.bodyFontSize(context),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  static bool _isSortActive(String sortKey, String currentSortBy) {
    switch (sortKey) {
      case 'dataDeCompra':
        return currentSortBy.contains('Data de Compra');
      case 'valor':
        return currentSortBy.contains('Valor');
      case 'estado':
        return currentSortBy.contains('Estado');
      case 'produto':
        return currentSortBy.contains('Produto');
      case 'uf':
        return currentSortBy.contains('UF');
      default:
        return false;
    }
  }

  static IconData _getSortIcon(String sortKey, String currentSortBy) {
    bool isAscending = false;
    bool isActive = false;

    switch (sortKey) {
      case 'dataDeCompra':
        isActive = currentSortBy.contains('Data de Compra');
        isAscending = currentSortBy == 'Data de Compra (antigo)';
        break;
      case 'valor':
        isActive = currentSortBy.contains('Valor');
        isAscending = currentSortBy == 'Valor (menor)';
        break;
      case 'estado':
        isActive = currentSortBy.contains('Estado');
        isAscending = currentSortBy == 'Estado (A-Z)';
        break;
      case 'produto':
        isActive = currentSortBy.contains('Produto');
        isAscending = currentSortBy == 'Produto (A-Z)';
        break;
      case 'uf':
        isActive = currentSortBy.contains('UF');
        isAscending = currentSortBy == 'UF (A-Z)';
        break;
    }

    if (!isActive) {
      return Icons.unfold_more;
    }

    return isAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down;
  }
}
