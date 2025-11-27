import 'package:flutter/material.dart';
import '../../core/utilities/dashboard/inventario_dashboard_utils.dart';
import '../../core/utilities/dashboard/base_dashboard_widget.dart';
import '../../core/utilities/shared/responsive.dart';
import '../../core/design_system.dart';
import '../../core/visuals/status_indicator.dart';
import '../../core/visuals/dialogue.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';

class InventarioDashboardWidget extends StatefulWidget {
  final List<NotaFiscal> notasFiscais;
  final List<Inventario> inventarios;
  final VoidCallback onRefresh;
  final VoidCallback onNavigateToList;
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToForm;
  final Function(Map<String, dynamic>) onNavigateToListWithFilters;
  final Function(Inventario) onNavigateToView;
  final Function(NotaFiscal)? onNavigateToNotaView;

  const InventarioDashboardWidget({
    super.key,
    required this.notasFiscais,
    required this.inventarios,
    required this.onRefresh,
    required this.onNavigateToList,
    required this.onNavigateToSearch,
    required this.onNavigateToForm,
    required this.onNavigateToListWithFilters,
    required this.onNavigateToView,
    this.onNavigateToNotaView,
  });

  @override
  State<InventarioDashboardWidget> createState() =>
      _InventarioDashboardWidgetState();
}

class _InventarioDashboardWidgetState extends State<InventarioDashboardWidget>
    with BaseDashboardState<InventarioDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoadingState();
    }

    return buildDashboardScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            title: 'Inventário',
            icon: Icons.inventory_2_outlined,
            userUf: userUf,
            isAdmin: isAdmin,
            onRefresh: widget.onRefresh,
          ),
          SizedBox(height: Responsive.largeSpacing(context)),
          _buildSummaryCards(context),
          SizedBox(height: Responsive.largeSpacing(context)),
          _buildQuickActions(context),
          SizedBox(height: Responsive.largeSpacing(context)),
          _buildRecentNotas(context),
          SizedBox(height: Responsive.largeSpacing(context)),
          _buildAlerts(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final totalNotas = widget.notasFiscais.length;
    final totalItems = widget.inventarios.length;
    final presentes = widget.inventarios
        .where((i) => i.estado == 'Presente')
        .length;
    final valorTotal = widget.notasFiscais.fold<double>(
      0,
      (sum, nf) => sum + nf.valorTotal,
    );

    final summaryData = [
      SummaryCardData(
        title: 'Notas Fiscais',
        value: totalNotas.toString(),
        icon: Icons.receipt_long_outlined,
        color: AppDesignSystem.primary,
        change: '$totalNotas notas cadastradas',
        isPositive: true,
        cardType: 'totalNotas',
        count: totalNotas,
      ),
      SummaryCardData(
        title: 'Presentes',
        value: presentes.toString(),
        icon: Icons.check_circle_outline,
        color: AppDesignSystem.success,
        change: totalItems > 0
            ? '${((presentes / totalItems) * 100).toStringAsFixed(1)}% do total'
            : 'Nenhum presente',
        isPositive: true,
        cardType: 'presente',
        count: presentes,
      ),
      SummaryCardData(
        title: 'Total de Itens',
        value: totalItems.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppDesignSystem.info,
        change: '$totalItems itens cadastrados',
        isPositive: false,
        cardType: 'total',
        count: totalItems,
      ),
      SummaryCardData(
        title: 'Valor Total',
        value: 'R\$ ${InventarioDashboardUtils.formatCurrency(valorTotal)}',
        icon: Icons.attach_money_outlined,
        color: AppDesignSystem.warning,
        change:
            '+R\$ ${InventarioDashboardUtils.formatCurrency(valorTotal * 0.08)}',
        isPositive: true,
        cardType: 'valorTotal',
        count: totalNotas,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridCrossAxisCount(
          context,
          mobileCount: 2,
          smallTabletCount: 2,
          tabletCount: 3,
          desktopCount: 4,
        ),
        crossAxisSpacing: AppDesignSystem.spacing16,
        mainAxisSpacing: AppDesignSystem.spacing16,
        childAspectRatio: Responsive.valueDetailed(
          context,
          mobile: 1.3,
          smallTablet: 1.2,
          tablet: 1.25,
          desktop: 1.8,
        ),
      ),
      itemCount: summaryData.length,
      itemBuilder: (context, index) => SummaryCard(
        data: summaryData[index],
        onTap: () => _handleCardTap(
          summaryData[index].cardType,
          summaryData[index].count,
        ),
      ),
    );
  }

  void _handleCardTap(String cardType, int count) {
    final filters = InventarioDashboardUtils.createFilterForCardType(cardType);
    filters['expectedCount'] = count;
    filters['sourceCard'] = cardType;
    widget.onNavigateToListWithFilters(filters);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickActionData(
        title: 'Nova Nota',
        subtitle: 'Adicionar Nota Fiscal',
        icon: Icons.add_circle_outline,
        color: AppDesignSystem.success,
        onTap: widget.onNavigateToForm,
      ),
      QuickActionData(
        title: 'Pesquisar',
        subtitle: 'Buscar notas ou itens',
        icon: Icons.search_outlined,
        color: AppDesignSystem.info,
        onTap: widget.onNavigateToSearch,
      ),
      QuickActionData(
        title: 'Estatísticas',
        subtitle: 'Ver estatísticas detalhadas',
        icon: Icons.analytics_outlined,
        color: AppDesignSystem.primary,
        onTap: () => _showStatsDialog(context),
      ),
      QuickActionData(
        title: 'Ver Lista',
        subtitle: 'Visualizar todas as notas',
        icon: Icons.list_outlined,
        color: AppDesignSystem.warning,
        onTap: widget.onNavigateToList,
      ),
    ];

    return AppCard(
      title: 'Ações Rápidas',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridCrossAxisCount(
            context,
            mobileCount: 2,
            tabletCount: 4,
            desktopCount: 4,
          ),
          crossAxisSpacing: AppDesignSystem.spacing12,
          mainAxisSpacing: AppDesignSystem.spacing12,
          childAspectRatio: Responsive.value(
            context,
            mobile: 1.8,
            tablet: 2.2,
            desktop: 2.4,
          ),
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) =>
            QuickActionCard(action: actions[index]),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final totalNotas = widget.notasFiscais.length;
    final totalItems = widget.inventarios.length;
    final presentes = widget.inventarios
        .where((i) => i.estado == 'Presente')
        .length;
    final ausentes = widget.inventarios
        .where((i) => i.estado == 'Ausente')
        .length;
    final valorTotal = widget.notasFiscais.fold<double>(
      0,
      (sum, nf) => sum + nf.valorTotal,
    );

    DialogUtils.showInfoDialog(
      context: context,
      title: 'Estatísticas Gerais',
      subtitle: 'Resumo geral do inventário',
      icon: Icons.analytics_outlined,
      iconColor: AppDesignSystem.info,
      contentBuilder: (setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visão geral: Notas Fiscais
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: AppDesignSystem.primaryLight,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDesignSystem.radiusS),
              ),
              border: Border.all(
                color: AppDesignSystem.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppDesignSystem.primary,
                  size: 24,
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas Fiscais',
                        style: AppDesignSystem.labelMedium.copyWith(
                          color: AppDesignSystem.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$totalNotas',
                        style: AppDesignSystem.h1.copyWith(
                          color: AppDesignSystem.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppDesignSystem.statusBadge(
                  text:
                      'R\$ ${InventarioDashboardUtils.formatCurrency(valorTotal)}',
                  color: AppDesignSystem.primary,
                  isSmall: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDesignSystem.spacing16),

          // Visão geral: Total de itens
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: AppDesignSystem.infoLight,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDesignSystem.radiusS),
              ),
              border: Border.all(
                color: AppDesignSystem.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppDesignSystem.info,
                  size: 24,
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Itens',
                        style: AppDesignSystem.labelMedium.copyWith(
                          color: AppDesignSystem.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$totalItems',
                        style: AppDesignSystem.h1.copyWith(
                          color: AppDesignSystem.info,
                        ),
                      ),
                    ],
                  ),
                ),
                AppDesignSystem.statusBadge(
                  text: '$totalItems itens',
                  color: AppDesignSystem.info,
                  isSmall: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDesignSystem.spacing16),

          const Text(
            'Distribuição por Status',
            style: AppDesignSystem.labelLarge,
          ),

          const SizedBox(height: AppDesignSystem.spacing12),

          StatItem(
            label: 'Presentes',
            count: presentes,
            total: totalItems,
            color: AppDesignSystem.success,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          StatItem(
            label: 'Ausentes',
            count: ausentes,
            total: totalItems,
            color: AppDesignSystem.error,
            icon: Icons.warning_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotas(BuildContext context) {
    final sortedNotas = List<NotaFiscal>.from(widget.notasFiscais)
      ..sort((a, b) => b.dataCompra.compareTo(a.dataCompra));
    final recentNotas = sortedNotas
        .take(Responsive.isMobile(context) ? 2 : 3)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Responsive.isMobile(context)
                    ? 'Notas Recentes'
                    : 'Notas Fiscais Recentes',
                style: AppDesignSystem.h3.copyWith(
                  fontSize: Responsive.subHeaderFontSize(context),
                ),
              ),
              AppDesignSystem.hoverAnimation(
                onTap: widget.onNavigateToList,
                child: Text(
                  Responsive.isMobile(context) ? 'Ver' : 'Ver todas',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          if (recentNotas.isEmpty)
            AppDesignSystem.emptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhuma nota encontrada',
              subtitle: 'As notas fiscais aparecerão aqui quando disponíveis',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentNotas.length,
              separatorBuilder: (context, index) => const Divider(
                height: AppDesignSystem.spacing24,
                color: AppDesignSystem.neutral200,
              ),
              itemBuilder: (context, index) =>
                  _buildRecentNotaItem(recentNotas[index], context),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentNotaItem(NotaFiscal nota, BuildContext context) {
    // Conta itens desta nota
    final itemCount = widget.inventarios
        .where((inv) => inv.notaFiscalId == nota.id)
        .length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onNavigateToNotaView != null
            ? () => widget.onNavigateToNotaView!(nota)
            : widget.onNavigateToList,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDesignSystem.radiusS),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDesignSystem.spacing6,
            horizontal: AppDesignSystem.spacing8,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacing6),
                decoration: BoxDecoration(
                  color: AppDesignSystem.primaryLight,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppDesignSystem.radiusS),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppDesignSystem.primary,
                  size: Responsive.smallIconSize(context),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NF: ${nota.numeroNota}',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.smallFontSize(context),
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spacing2),
                    Text(
                      'Fornecedor: ${nota.fornecedor}',
                      style: AppDesignSystem.bodySmall.copyWith(
                        fontSize: Responsive.smallFontSize(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!Responsive.isMobile(context)) ...[
                      const SizedBox(height: AppDesignSystem.spacing2),
                      Text(
                        'Compra: ${InventarioDashboardUtils.formatDate(nota.dataCompra)}',
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontSize: Responsive.smallFontSize(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'R\$ ${nota.valorTotal.toStringAsFixed(2)}',
                    style: AppDesignSystem.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.smallFontSize(context),
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacing2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DotIndicators.standard(
                        text: '$itemCount ${itemCount == 1 ? 'item' : 'itens'}',
                        dotColor: AppDesignSystem.info,
                      ),
                      const SizedBox(width: AppDesignSystem.spacing6),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppDesignSystem.neutral400,
                        size: Responsive.smallIconSize(context) - 2,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context) {
    final expiringWarranty =
        InventarioDashboardUtils.getItemsWithExpiringWarranty(
          widget.inventarios,
        );
    final highValueNoSerial =
        InventarioDashboardUtils.getHighValueItemsWithoutSerial(
          widget.inventarios,
        );
    final ufDistribution = InventarioDashboardUtils.getItemsByUF(
      widget.inventarios,
    );
    final growth = InventarioDashboardUtils.calculateMonthlyGrowth(
      widget.notasFiscais,
    );

    final alertsData = [
      AlertItem(
        icon: Icons.warning_amber_outlined,
        title: Responsive.isMobile(context)
            ? 'Alto valor s/ serial'
            : 'Itens de alto valor sem nº de série',
        subtitle:
            '${highValueNoSerial.length} ${Responsive.isMobile(context) ? 'itens' : 'itens requerem atenção'}',
        color: AppDesignSystem.warning,
      ),
      AlertItem(
        icon: Icons.schedule_outlined,
        title: Responsive.isMobile(context)
            ? 'Garantias'
            : 'Garantias Expirando',
        subtitle:
            '${expiringWarranty.length} ${Responsive.isMobile(context) ? 'expirando' : 'itens com garantia expirando'}',
        color: AppDesignSystem.warning,
      ),
      AlertItem(
        icon: Icons.trending_flat,
        title: 'Crescimento',
        subtitle: growth['isPositive']
            ? '+${growth['absoluteChange']} notas vs mês anterior'
            : 'Estável vs mês anterior',
        color: growth['isPositive']
            ? AppDesignSystem.success
            : AppDesignSystem.info,
      ),
      AlertItem(
        icon: Icons.location_on_outlined,
        title: 'Por Estado',
        subtitle:
            'CE: ${ufDistribution['CE'] ?? 0}, SP: ${ufDistribution['SP'] ?? 0} ${Responsive.isMobile(context) ? 'itens' : 'itens registrados'}',
        color: AppDesignSystem.success,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Responsive.isMobile(context) ? 'Alertas' : 'Alertas e Notificações',
            style: AppDesignSystem.h3.copyWith(
              fontSize: Responsive.subHeaderFontSize(context),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          ...alertsData.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
              child: alert,
            ),
          ),
        ],
      ),
    );
  }
}
