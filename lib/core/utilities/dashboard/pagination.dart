// Paginação
import 'package:flutter/material.dart';
import 'dart:math';
import '../../design_system.dart';

/// Gerencia estado de paginação
class PaginationState extends ChangeNotifier {
  int _currentPage = 1;
  int _pageSize = 15; // Itens por página
  int _totalItems = 0;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalItems => _totalItems;
  int get totalPages => (_totalItems / _pageSize).ceil();
  int get startIndex => (_currentPage - 1) * _pageSize;
  int get endIndex => min(startIndex + _pageSize, _totalItems);

  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < totalPages;

  void updateTotalItems(int total) {
    if (_totalItems != total) {
      _totalItems = total;
      // Reinicia para página 1 se atual exceder total
      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = 1;
      }
      notifyListeners();
    }
  }

  void goToPage(int page) {
    final newPage = page.clamp(1, max(1, totalPages));
    if (_currentPage != newPage) {
      _currentPage = newPage as int;
      notifyListeners();
    }
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      notifyListeners();
    }
  }

  void setPageSize(int size) {
    if (_pageSize != size) {
      _pageSize = size;
      _currentPage = 1; // Reinicia ao mudar tamanho da página
      notifyListeners();
    }
  }

  /// Retorna subconjunto de itens paginados
  List<T> getPaginatedItems<T>(List<T> allItems) {
    updateTotalItems(allItems.length);

    if (allItems.isEmpty) return [];

    final start = startIndex;
    final end = min(start + _pageSize, allItems.length);

    if (start >= allItems.length) return [];

    return allItems.sublist(start, end);
  }

  /// Reinicia a paginação ao estado inicial
  void reset() {
    _currentPage = 1;
    _totalItems = 0;
    notifyListeners();
  }
}

/// Rodapé de paginação com controles de navegação
class PaginationFooter extends StatelessWidget {
  final PaginationState paginationState;
  final bool showPageSizeSelector;
  final List<int> pageSizeOptions;

  const PaginationFooter({
    super.key,
    required this.paginationState,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [10, 15, 25, 50],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: paginationState,
      builder: (context, _) {
        if (paginationState.totalItems == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing12,
          ),
          decoration: const BoxDecoration(
            color: AppDesignSystem.surface,
            border: Border(top: BorderSide(color: AppDesignSystem.neutral200)),
          ),
          child: Row(
            children: [
              if (showPageSizeSelector) ...[
                _buildPageSizeSelector(),
                const SizedBox(width: AppDesignSystem.spacing16),
              ],

              const Spacer(),

              // Navegação
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Página anterior
                  _buildPaginationButton(
                    icon: Icons.chevron_left,
                    onPressed: paginationState.hasPreviousPage
                        ? () => paginationState.previousPage()
                        : null,
                    tooltip: 'Página anterior',
                  ),

                  const SizedBox(width: AppDesignSystem.spacing4),

                  // Número da página
                  Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${paginationState.currentPage}',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDesignSystem.spacing4),

                  // Próxima página
                  _buildPaginationButton(
                    icon: Icons.chevron_right,
                    onPressed: paginationState.hasNextPage
                        ? () => paginationState.nextPage()
                        : null,
                    tooltip: 'Próxima página',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing8,
        vertical: AppDesignSystem.spacing6,
      ),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppDesignSystem.neutral200),
          top: BorderSide(color: AppDesignSystem.neutral200),
          right: BorderSide(color: AppDesignSystem.neutral200),
          bottom: BorderSide(color: AppDesignSystem.neutral200),
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(AppDesignSystem.radiusS),
        ),
        color: AppDesignSystem.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.view_list,
            size: 14,
            color: AppDesignSystem.neutral500,
          ),
          const SizedBox(width: AppDesignSystem.spacing4),
          DropdownButton<int>(
            value: paginationState.pageSize,
            underline: const SizedBox(),
            isDense: true,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral600,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: AppDesignSystem.neutral400,
            ),
            items: pageSizeOptions
                .map(
                  (size) => DropdownMenuItem(value: size, child: Text('$size')),
                )
                .toList(),
            onChanged: (value) {
              paginationState.setPageSize(value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      iconSize: 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? AppDesignSystem.neutral700
            : AppDesignSystem.neutral300,
        backgroundColor: onPressed != null
            ? AppDesignSystem.neutral50
            : Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignSystem.radiusS),
          ),
        ),
      ),
    );
  }
}

/// Widget de contagem de resultados de paginação
class PaginationResultsCount extends StatelessWidget {
  final PaginationState paginationState;
  final String? emptyMessage;

  const PaginationResultsCount({
    super.key,
    required this.paginationState,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: paginationState,
      builder: (context, _) {
        if (paginationState.totalItems == 0) {
          return Text(
            emptyMessage ?? 'Nenhum item encontrado',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          );
        }

        return Text(
          'Mostrando ${paginationState.startIndex + 1}–${paginationState.endIndex} de ${paginationState.totalItems}',
          style: AppDesignSystem.bodySmall.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        );
      },
    );
  }
}
