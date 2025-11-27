import 'package:flutter/material.dart';
import './design_system.dart';
import './utilities/shared/responsive.dart';

/// Modelo base para páginas
abstract class BasePageTemplate extends StatelessWidget {
  const BasePageTemplate({super.key});

  String get pageTitle;
  IconData get pageIcon;
  bool get hasBackButton => false;
  VoidCallback? get onBack => null;
  List<Widget>? get headerActions => null;

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          if (!Responsive.isSmallScreen(context))
            AppDesignSystem.pageHeader(
              icon: pageIcon,
              title: pageTitle,
              onBack: hasBackButton ? onBack : null,
              actions: headerActions,
            ),
          Expanded(child: buildContent(context)),
        ],
      ),
    );
  }
}

/// Modelo para páginas de lista
abstract class ListPageTemplate extends BasePageTemplate {
  const ListPageTemplate({super.key});

  Widget? buildTopSection(BuildContext context) => null;
  Widget? buildFilters(BuildContext context) => null;
  Widget buildList(BuildContext context);
  bool get showStats => false;
  Widget? buildStats(BuildContext context) => null;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        // Seção superior (busca, filtros, etc.)
        if (buildTopSection(context) != null)
          Container(
            color: AppDesignSystem.surface,
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: buildTopSection(context),
          ),

        // Filtros
        if (buildFilters(context) != null)
          Container(
            color: AppDesignSystem.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing24,
              vertical: AppDesignSystem.spacing12,
            ),
            child: buildFilters(context),
          ),

        // Estatísticas
        if (showStats && buildStats(context) != null)
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: buildStats(context),
          ),

        // Lista principal
        Expanded(child: buildList(context)),
      ],
    );
  }
}

/// Modelo para páginas de formulário
abstract class FormPageTemplate extends BasePageTemplate {
  const FormPageTemplate({super.key});

  GlobalKey<FormState> get formKey;
  Widget buildForm(BuildContext context);
  Widget? buildFormActions(BuildContext context) => null;
  double get maxFormWidth => 600;

  @override
  Widget buildContent(BuildContext context) {
    return AppContentContainer(
      maxWidth: maxFormWidth,
      child: AppCard(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildForm(context),
              if (buildFormActions(context) != null) ...[
                const SizedBox(height: AppDesignSystem.spacing32),
                buildFormActions(context)!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modelo para páginas de detalhe
abstract class DetailPageTemplate extends BasePageTemplate {
  const DetailPageTemplate({super.key});

  @override
  bool get hasBackButton => true;

  Widget buildHeader(BuildContext context);
  Widget buildMainContent(BuildContext context);
  Widget? buildSidebar(BuildContext context) => null;
  double get maxContentWidth => 800;

  @override
  Widget buildContent(BuildContext context) {
    return AppContentContainer(
      maxWidth: maxContentWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context),

          const SizedBox(height: AppDesignSystem.spacing24),

          if (buildSidebar(context) != null &&
              !Responsive.isSmallScreen(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: buildMainContent(context)),
                const SizedBox(width: AppDesignSystem.spacing24),
                Expanded(flex: 1, child: buildSidebar(context)!),
              ],
            )
          else
            buildMainContent(context),
        ],
      ),
    );
  }
}

/// Modelo para páginas de visualização dividida
abstract class SplitViewTemplate extends BasePageTemplate {
  const SplitViewTemplate({super.key});

  Widget buildLeftPanel(BuildContext context);
  Widget buildRightPanel(BuildContext context);
  double get leftPanelWidth => 400;

  @override
  Widget buildContent(BuildContext context) {
    if (Responsive.isSmallScreen(context)) {
      return buildRightPanel(context);
    }

    return Row(
      children: [
        Container(
          width: leftPanelWidth,
          color: AppDesignSystem.neutral50,
          child: buildLeftPanel(context),
        ),

        Container(width: 1, color: AppDesignSystem.neutral200),

        Expanded(child: buildRightPanel(context)),
      ],
    );
  }
}

// ==================== MODELOS ESPECÍFICOS ====================

/// Componente de tabela padrão
class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final bool isLoading;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage,
    this.emptyIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: AppDesignSystem.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacing24,
                vertical: AppDesignSystem.spacing12,
              ),
              decoration: const BoxDecoration(
                color: AppDesignSystem.neutral50,
                border: Border(
                  bottom: BorderSide(color: AppDesignSystem.neutral200),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDesignSystem.radiusL),
                  topRight: Radius.circular(AppDesignSystem.radiusL),
                ),
              ),
              child: Row(
                children: columns.map((column) {
                  return Expanded(
                    flex: column.flex,
                    child: Text(
                      column.title,
                      style: AppDesignSystem.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppDesignSystem.radiusL),
                    bottomRight: Radius.circular(AppDesignSystem.radiusL),
                  ),
                ),
                child: AppDesignSystem.loadingState(),
              ),
            ),
          ],
        ),
      );
    }

    if (rows.isEmpty) {
      return Container(
        decoration: AppDesignSystem.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacing24,
                vertical: AppDesignSystem.spacing12,
              ),
              decoration: const BoxDecoration(
                color: AppDesignSystem.neutral50,
                border: Border(
                  bottom: BorderSide(color: AppDesignSystem.neutral200),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDesignSystem.radiusL),
                  topRight: Radius.circular(AppDesignSystem.radiusL),
                ),
              ),
              child: Row(
                children: columns.map((column) {
                  return Expanded(
                    flex: column.flex,
                    child: Text(
                      column.title,
                      style: AppDesignSystem.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppDesignSystem.surface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppDesignSystem.radiusL),
                    bottomRight: Radius.circular(AppDesignSystem.radiusL),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.neutral50,
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.radiusXL,
                            ),
                          ),
                          child: Icon(
                            emptyIcon ?? Icons.inbox_outlined,
                            size: 40,
                            color: AppDesignSystem.neutral300,
                          ),
                        ),

                        const SizedBox(height: AppDesignSystem.spacing24),

                        Text(
                          emptyMessage ?? 'Nenhum item encontrado',
                          style: AppDesignSystem.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppDesignSystem.neutral600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppDesignSystem.spacing8),

                        Text(
                          'Os itens aparecerão aqui quando disponíveis',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppDesignSystem.neutral400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing24,
              vertical: AppDesignSystem.spacing12,
            ),
            decoration: const BoxDecoration(
              color: AppDesignSystem.neutral50,
              border: Border(
                bottom: BorderSide(color: AppDesignSystem.neutral200),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDesignSystem.radiusL),
                topRight: Radius.circular(AppDesignSystem.radiusL),
              ),
            ),
            child: Row(
              children: columns.map((column) {
                return Expanded(
                  flex: column.flex,
                  child: Text(
                    column.title,
                    style: AppDesignSystem.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDesignSystem.radiusL),
                  bottomRight: Radius.circular(AppDesignSystem.radiusL),
                ),
              ),
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _AppTableRowWidget(
                    row: row,
                    columns: columns,
                    index: index,
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

/// Widget interno para linhas da tabela
class _AppTableRowWidget extends StatefulWidget {
  final AppTableRow row;
  final List<AppTableColumn> columns;
  final int index;

  const _AppTableRowWidget({
    required this.row,
    required this.columns,
    required this.index,
  });

  @override
  State<_AppTableRowWidget> createState() => _AppTableRowWidgetState();
}

class _AppTableRowWidgetState extends State<_AppTableRowWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    // Chama o callback onHover se fornecido
    widget.row.onHover?.call(isHovered);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.row.onTap,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing24,
                    vertical: AppDesignSystem.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.neutral50.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                    border: const Border(
                      bottom: BorderSide(color: AppDesignSystem.neutral100),
                    ),
                    borderRadius: _isHovered
                        ? BorderRadius.circular(AppDesignSystem.radiusS)
                        : BorderRadius.zero,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.02 * _opacityAnimation.value,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: List.generate(
                      widget.columns.length,
                      (colIndex) => Expanded(
                        flex: widget.columns[colIndex].flex,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: Color.lerp(
                              AppDesignSystem.neutral700,
                              AppDesignSystem.neutral800,
                              _opacityAnimation.value,
                            ),
                          ),
                          child: widget.row.cells[colIndex],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppTableColumn {
  final String title;
  final int flex;

  const AppTableColumn({required this.title, this.flex = 1});
}

class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Function(bool)? onHover;

  const AppTableRow({required this.cells, this.onTap, this.onHover});
}

/// Componente de cards de estatísticas
class AppStatsCards extends StatelessWidget {
  final List<Widget> cards;

  const AppStatsCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < cards.length - 1 ? AppDesignSystem.spacing20 : 0,
            ),
            child: card,
          ),
        );
      }).toList(),
    );
  }
}

class AppStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const AppStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 26.0),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppDesignSystem.h1),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  label,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente de chips de filtro
class AppFilterChips extends StatelessWidget {
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  const AppFilterChips({
    super.key,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter;

        return Container(
          margin: const EdgeInsets.only(right: AppDesignSystem.spacing8),
          child: FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) => onFilterChanged(filter),
            backgroundColor: AppDesignSystem.surface,
            selectedColor: AppDesignSystem.primaryLight,
            side: BorderSide(
              color: isSelected
                  ? AppDesignSystem.primary
                  : AppDesignSystem.neutral200,
            ),
            labelStyle: AppDesignSystem.bodyMedium.copyWith(
              color: isSelected
                  ? AppDesignSystem.primary
                  : AppDesignSystem.neutral600,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }
}
