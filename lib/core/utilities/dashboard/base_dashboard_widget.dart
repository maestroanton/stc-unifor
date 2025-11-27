import 'package:flutter/material.dart';
import '../../design_system.dart';
import '../shared/responsive.dart';
import '../../../helpers/uf_helper.dart';

/// Mixin de estado base para widgets de dashboard
mixin BaseDashboardState<T extends StatefulWidget> on State<T> {
  String? userUf;
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final uf = await UfHelper.getCurrentUserUf();
    final admin = await UfHelper.isAdmin();
    if (mounted) {
      setState(() {
        userUf = uf;
        isAdmin = admin;
        isLoading = false;
      });
    }
  }

  Widget buildLoadingState() {
    return const AppScaffold(
      backgroundColor: AppDesignSystem.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildDashboardScaffold({required Widget child}) {
    return AppScaffold(
      backgroundColor: AppDesignSystem.background,
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: child,
      ),
    );
  }
}

/// Cabeçalho comum do dashboard
class DashboardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? userUf;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.userUf,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final adminSuffix = isAdmin ? " (Admin)" : "";

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing12),
            decoration: BoxDecoration(
              color: AppDesignSystem.primaryLight,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(
              icon,
              size: Responsive.largeIconSize(context),
              color: AppDesignSystem.primary,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppDesignSystem.h2.copyWith(
                    fontSize: Responsive.headerFontSize(context),
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  userUf != null
                      ? 'Estado: $userUf$adminSuffix'
                      : 'Carregando...',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontSize: Responsive.bodyFontSize(context),
                  ),
                ),
              ],
            ),
          ),
          AppDesignSystem.hoverAnimation(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              decoration: BoxDecoration(
                color: AppDesignSystem.primaryLight,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
              child: Icon(
                Icons.refresh,
                color: AppDesignSystem.primary,
                size: Responsive.iconSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrutura de dados para cartões de resumo
class SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;
  final String cardType;
  final int count;

  const SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
    required this.cardType,
    required this.count,
  });
}

/// Widget de cartão de resumo
class SummaryCard extends StatelessWidget {
  final SummaryCardData data;
  final VoidCallback onTap;

  const SummaryCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppDesignSystem.hoverAnimation(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.05),
          border: Border.all(color: data.color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusS,
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: Responsive.iconSize(context),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        data.isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: data.isPositive
                            ? AppDesignSystem.success
                            : AppDesignSystem.warning,
                        size: Responsive.smallIconSize(context),
                      ),
                      const SizedBox(width: AppDesignSystem.spacing4),
                      Text(
                        data.isPositive ? '+' : '-',
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: data.isPositive
                              ? AppDesignSystem.success
                              : AppDesignSystem.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.value,
                style: AppDesignSystem.h1.copyWith(
                  fontSize: Responsive.value(
                    context,
                    mobile: 18.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                data.title,
                style: AppDesignSystem.bodyMedium.copyWith(
                  fontSize: Responsive.value(
                    context,
                    mobile: 11.0,
                    tablet: 12.0,
                    desktop: 13.0,
                  ),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                data.change,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: data.isPositive
                      ? AppDesignSystem.success
                      : AppDesignSystem.warning,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.value(
                    context,
                    mobile: 9.0,
                    tablet: 10.0,
                    desktop: 11.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estrutura de dados para ações rápidas
class QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Widget de ação rápida
class QuickActionCard extends StatelessWidget {
  final QuickActionData action;

  const QuickActionCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return AppDesignSystem.hoverAnimation(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        decoration: BoxDecoration(
          color: AppDesignSystem.surface,
          border: Border.all(color: AppDesignSystem.neutral200),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: Responsive.value(
                context,
                mobile: 20.0,
                tablet: 24.0,
                desktop: 26.0,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              action.title,
              style: AppDesignSystem.labelMedium.copyWith(
                fontSize: Responsive.value(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 13.0,
                ),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!Responsive.isMobile(context)) ...[
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                action.subtitle,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral500,
                  fontSize: Responsive.value(
                    context,
                    mobile: 9.0,
                    tablet: 10.0,
                    desktop: 11.0,
                  ),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de alerta comum
class AlertItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const AlertItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.smallFontSize(context),
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing2),
                Text(
                  subtitle,
                  style: AppDesignSystem.bodySmall.copyWith(
                    fontSize: Responsive.smallFontSize(context),
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

/// Item de estatística comum para diálogos
class StatItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const StatItem({
    super.key,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0
        ? ((count / total) * 100).toStringAsFixed(1)
        : '0.0';
    final progressValue = total > 0 ? count / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: AppDesignSystem.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppDesignSystem.bodyMedium),
                    Text(
                      '$count ($percentage%)',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing6),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.neutral200,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXS,
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(
                          AppDesignSystem.radiusXS,
                        ),
                      ),
                    ),
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

/// Funções utilitárias comuns
class DashboardUtils {
  static String formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  static DateTime parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Fallback: retorna data atual se parsing falhar
    }
    return DateTime.now();
  }
}
