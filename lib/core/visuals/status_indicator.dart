// lib/components/dot_indicators.dart
import 'package:flutter/material.dart';
import '../design_system.dart';
import '../utilities/shared/responsive.dart';

/// Padrões padronizados de indicadores de ponto para interface consistente
class DotIndicators {
  // ==================== PADRÃO RECOMENDADO ====================

  /// Indicador de ponto padrão - ponto colorido + texto neutro
  /// UTILIZE ISTO para: Status, Prioridade, Categoria em tabelas e cartões
  ///
  /// Comportamento responsivo (automático via Builder):
  /// - Desktop/Tablet: Texto completo com ponto
  /// - Mobile: Texto abreviado com ponto
  /// - Small screens: Apenas ponto com tooltip
  static Widget standard({
    required String text,
    required Color dotColor,
    bool isUppercase = false,
    String? shortText,
    String? tooltipText,
  }) {
    // Utilize Builder para obter o context automaticamente
    return Builder(
      builder: (context) {
        // Utilize shortText se fornecido, caso contrário tente abreviar automaticamente
        final abbreviated = shortText ?? _abbreviateText(text);
        final tooltip = tooltipText ?? text;

        return Responsive.valueDetailed<Widget>(
          context,
          mobile: _buildResponsiveDot(
            text: abbreviated,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing6,
            fontSize: 12,
            tooltip: tooltip,
          ),
          smallTablet: _buildResponsiveDot(
            text: abbreviated,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing8,
            fontSize: 13,
            tooltip: tooltip,
          ),
          tablet: _buildResponsiveDot(
            text: text,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing8,
            fontSize: 13,
            tooltip: tooltip,
          ),
          desktop: _buildResponsiveDot(
            text: text,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing8,
            fontSize: 13,
            tooltip: tooltip,
          ),
        );
      },
    );
  }

  /// Versão compacta - mostra apenas o ponto em mobile, abrevia em tablet e mostra completo em desktop
  static Widget compact({
    required String text,
    required Color dotColor,
    bool isUppercase = false,
    String? shortText,
  }) {
    return Builder(
      builder: (context) {
        final abbreviated = shortText ?? _abbreviateText(text);
        final tooltip = text;

        return Responsive.valueDetailed<Widget>(
          context,
          mobile: _buildDotOnly(
            dotColor: dotColor,
            tooltip: tooltip,
            dotSize: 8,
          ),
          smallTablet: _buildResponsiveDot(
            text: abbreviated,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing6,
            fontSize: 12,
            tooltip: tooltip,
          ),
          tablet: _buildResponsiveDot(
            text: text,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing8,
            fontSize: 13,
            tooltip: tooltip,
          ),
          desktop: _buildResponsiveDot(
            text: text,
            dotColor: dotColor,
            isUppercase: isUppercase,
            dotSize: 6,
            spacing: AppDesignSystem.spacing8,
            fontSize: 13,
            tooltip: tooltip,
          ),
        );
      },
    );
  }

  // Auxiliar para construir ponto responsivo com texto
  static Widget _buildResponsiveDot({
    required String text,
    required Color dotColor,
    required bool isUppercase,
    required double dotSize,
    required double spacing,
    required double fontSize,
    String? tooltip,
  }) {
    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: spacing),
        Text(
          isUppercase ? text.toUpperCase() : text,
          style: AppDesignSystem.bodyMedium.copyWith(
            color: AppDesignSystem.neutral700,
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );

    return tooltip != null ? Tooltip(message: tooltip, child: widget) : widget;
  }

  // Auxiliar para construir apenas ponto (para telas muito pequenas)
  static Widget _buildDotOnly({
    required Color dotColor,
    required String tooltip,
    required double dotSize,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );
  }

  // Auxiliar para abreviar texto automaticamente
  static String _abbreviateText(String text) {
    // Abreviações comuns para termos de status/prioridade em Português
    final abbreviations = {
      'Pendente': 'Pend.',
      'Aprovado': 'Aprov.',
      'Reprovado': 'Reprov.',
      'Concluído': 'Concl.',
      'Em Andamento': 'Em And.',
      'Cancelado': 'Cancel.',
      'Urgente': 'Urg.',
      'Crítica': 'Crít.',
      'Alta': 'Alta',
      'Média': 'Méd.',
      'Baixa': 'Baixa',
    };

    return abbreviations[text] ??
        (text.length > 8 ? '${text.substring(0, 6)}.' : text);
  }

  // ==================== PADRÕES ALTERNATIVOS ====================

  /// Versão com texto colorido - ponto colorido + texto colorido
  /// USE COM MODERAÇÃO: Apenas para ênfase em cabeçalhos/áreas importantes
  /// Comportamento responsivo (automático via Builder):
  /// - Desktop/Tablet: Texto completo em destaque
  /// - Mobile: Texto abreviado
  static Widget emphasized({
    required String text,
    required Color color,
    bool isUppercase = false,
    String? shortText,
  }) {
    return Builder(
      builder: (context) {
        final abbreviated = shortText ?? _abbreviateText(text);

        return Responsive.valueDetailed<Widget>(
          context,
          mobile: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDesignSystem.spacing6),
              Text(
                isUppercase ? abbreviated.toUpperCase() : abbreviated,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          tablet: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                isUppercase ? text.toUpperCase() : text,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          desktop: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                isUppercase ? text.toUpperCase() : text,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ponto grande para cabeçalhos/contextos importantes
  ///
  /// Comportamento responsivo (automático via Builder):
  /// - Desktop: Ponto grande com texto completo
  /// - Tablet: Ponto médio com texto completo
  /// - Mobile: Ponto médio com texto abreviado
  static Widget large({
    required String text,
    required Color dotColor,
    bool emphasizeText = false,
    String? shortText,
  }) {
    return Builder(
      builder: (context) {
        final abbreviated = shortText ?? _abbreviateText(text);

        return Responsive.valueDetailed<Widget>(
          context,
          mobile: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                abbreviated,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: emphasizeText ? dotColor : AppDesignSystem.neutral700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          tablet: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                text,
                style: AppDesignSystem.bodyLarge.copyWith(
                  color: emphasizeText ? dotColor : AppDesignSystem.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          desktop: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                text,
                style: AppDesignSystem.bodyLarge.copyWith(
                  color: emphasizeText ? dotColor : AppDesignSystem.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Exemplos de uso mostrando quando usar cada padrão
class DotPatternExamples extends StatelessWidget {
  const DotPatternExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dot Indicator Patterns', style: AppDesignSystem.h2),
          const SizedBox(height: AppDesignSystem.spacing24),

          // Padrão 1: Padrão (RECOMENDADO para a maioria dos casos)
          _buildPatternSection(
            title: '1. Standard Pattern (RECOMMENDED)',
            subtitle: 'Use for: Tables, lists, most UI elements',
            examples: [
              DotIndicators.standard(
                text: 'Pendente',
                dotColor: AppDesignSystem.warning,
              ),
              DotIndicators.standard(
                text: 'Alta',
                dotColor: AppDesignSystem.error,
              ),
              DotIndicators.standard(
                text: 'TI',
                dotColor: AppDesignSystem.primary,
              ),
            ],
            explanation:
                'Colored dot provides visual context, neutral text ensures readability and consistency. Adapts to screen size automatically via Builder.',
          ),

          const SizedBox(height: AppDesignSystem.spacing32),

          // Padrão 2: Enfatizado (USAR COM MODERAÇÃO)
          _buildPatternSection(
            title: '2. Emphasized Pattern (USE SPARINGLY)',
            subtitle:
                'Use for: Page headers, critical status, important highlights',
            examples: [
              DotIndicators.emphasized(
                text: 'Pendente',
                color: AppDesignSystem.warning,
              ),
              DotIndicators.emphasized(
                text: 'Urgente',
                color: AppDesignSystem.error,
              ),
            ],
            explanation:
                'Both dot and text colored for maximum attention. Use only when status needs emphasis. Abbreviates on mobile automatically.',
          ),

          const SizedBox(height: AppDesignSystem.spacing32),

          // Padrão 3: Grande para cabeçalhos
          _buildPatternSection(
            title: '3. Large Pattern',
            subtitle:
                'Use for: Page headers, detail views, primary status display',
            examples: [
              DotIndicators.large(
                text: 'Pendente de Aprovação',
                dotColor: AppDesignSystem.warning,
                emphasizeText: true,
              ),
            ],
            explanation:
                'Larger dot for header contexts. Can emphasize text when it\'s the main focus. Scales down on mobile automatically.',
          ),

          const SizedBox(height: AppDesignSystem.spacing32),

          // Padrão 4: Compacto para áreas com espaço limitado
          _buildPatternSection(
            title: '4. Compact Pattern',
            subtitle:
                'Use for: Dense tables, mobile-first layouts, space-constrained areas',
            examples: [
              DotIndicators.compact(
                text: 'Pendente',
                dotColor: AppDesignSystem.warning,
              ),
              DotIndicators.compact(
                text: 'Crítica',
                dotColor: AppDesignSystem.error,
              ),
            ],
            explanation:
                'More aggressive responsiveness: dot-only on mobile, abbreviated on tablet, full text on desktop. Best for dense layouts.',
          ),

          const SizedBox(height: AppDesignSystem.spacing32),

          // Diretrizes de uso
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: AppDesignSystem.primaryLight,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(
                color: AppDesignSystem.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.rule_outlined,
                      color: AppDesignSystem.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppDesignSystem.spacing8),
                    Text(
                      'Usage Guidelines',
                      style: AppDesignSystem.labelLarge.copyWith(
                        color: AppDesignSystem.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _buildGuideline(
                  '✅ DO',
                  'Use standard pattern (colored dot + neutral text) for 90% of cases',
                ),
                _buildGuideline(
                  '✅ DO',
                  'Keep dot colors semantic (red=error, orange=warning, green=success)',
                ),
                _buildGuideline(
                  '✅ DO',
                  'Use consistent dot sizes within the same context',
                ),
                _buildGuideline(
                  '✅ DO',
                  'Pass context parameter for responsive behavior',
                ),
                _buildGuideline(
                  '✅ DO',
                  'Use compact pattern for dense tables on mobile',
                ),
                _buildGuideline(
                  '✅ DO',
                  'Provide custom shortText for better mobile abbreviations',
                ),
                _buildGuideline(
                  '❌ DON\'T',
                  'Mix patterns randomly - be intentional',
                ),
                _buildGuideline(
                  '❌ DON\'T',
                  'Use emphasized pattern in tables - it\'s too noisy',
                ),
                _buildGuideline(
                  '❌ DON\'T',
                  'Change patterns mid-design without reason',
                ),
                _buildGuideline(
                  '❌ DON\'T',
                  'Forget to pass BuildContext - it\'s required for responsiveness',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternSection({
    required String title,
    required String subtitle,
    required List<Widget> examples,
    required String explanation,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: AppDesignSystem.neutral200),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppDesignSystem.h3),
          const SizedBox(height: AppDesignSystem.spacing4),
          Text(
            subtitle,
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // Exemplos
          Wrap(
            spacing: AppDesignSystem.spacing24,
            runSpacing: AppDesignSystem.spacing12,
            children: examples,
          ),

          const SizedBox(height: AppDesignSystem.spacing12),
          Text(
            explanation,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String type, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing4),
      child: Text(
        '$type: $text',
        style: AppDesignSystem.bodySmall.copyWith(
          color: AppDesignSystem.primary,
        ),
      ),
    );
  }
}

// ==================== IMPLEMENTAÇÃO RECOMENDADA ====================

/// Como atualizar seu código existente para manter consistência
class RecommendedImplementation {
  // PARA TABELAS (my_requisitions.dart, search.dart):
  static Widget tableStatus(String status, Color statusColor) {
    return DotIndicators.standard(text: status, dotColor: statusColor);
  }

  static Widget tablePriority(String priority) {
    return DotIndicators.standard(
      text: priority,
      dotColor: _getPriorityColor(priority),
    );
  }

  static Widget tableCategory(String category) {
    return DotIndicators.standard(
      text: category,
      dotColor: AppDesignSystem.primary, // Ou cor específica por categoria
    );
  }

  // PARA TABELAS DENSAS (use compact para melhor experiência em mobile):
  static Widget tableStatusCompact(String status, Color statusColor) {
    return DotIndicators.compact(text: status, dotColor: statusColor);
  }

  // PARA CABEÇALHOS/VISUALIZAÇÕES DE DETALHE (view.dart):
  static Widget headerStatus(String status, Color statusColor) {
    return DotIndicators.emphasized(text: status, color: statusColor);
  }

  static Widget sidebarStatusItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppDesignSystem.bodySmall.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
        DotIndicators.standard(text: value, dotColor: color),
      ],
    );
  }

  static Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
      case 'crítica':
        return AppDesignSystem.error;
      case 'média':
        return AppDesignSystem.warning;
      case 'baixa':
        return AppDesignSystem.success;
      default:
        return AppDesignSystem.neutral400;
    }
  }
}

// ==================== SUMMARY ====================
/*
PADRÃO RECOMENDADO PARA O SEU SISTEMA:

1. **90% dos casos**: Use `DotIndicators.standard(text: ..., dotColor: ...)`
  - Tabelas: Status, Prioridade, Categoria
  - Sidebars: Itens de status
  - Listas: Qualquer categorização
  - Padrão: Ponto colorido + texto neutro
  - Responsivo: Abrevia automaticamente no mobile, mostra texto completo em tablet/desktop

2. **Layouts densos**: Use `DotIndicators.compact(text: ..., dotColor: ...)`
  - Tabelas densas com muitas colunas
  - Layouts mobile-first
  - Padrão: Apenas ponto no mobile, abreviado no tablet, completo no desktop

3. **Apenas para cabeçalhos/ênfase**: Use `DotIndicators.emphasized(text: ..., color: ...)`
  - Cabeçalhos de página que mostram o status principal
  - Alertas críticos
  - Padrão: Ponto colorido + texto colorido
  - Responsivo: Abrevia automaticamente no mobile

4. **Contextos grandes**: Use `DotIndicators.large(text: ..., dotColor: ...)`
  - Status principal da página de detalhe
  - Métricas primárias do dashboard
  - Padrão: Ponto grande + texto (neutro ou colorido)
  - Responsivo: Ajusta automaticamente o tamanho do ponto e do texto

COMPORTAMENTO RESPONSIVO (AUTOMÁTICO via Builder):
- Mobile (<600px): Texto abreviado ou apenas ponto (modo compact)
- Small Tablet (600-768px): Texto abreviado
- Tablet/Desktop (>768px): Texto completo
- Todos com tooltips mostrando o texto completo ao passar/ tocar
- NÃO é necessário passar o context — usa Builder internamente!

REGRAS DE CONSISTÊNCIA:
- Mesmo padrão dentro do mesmo contexto (todas as células da tabela usam standard)
- Mesmo tamanho de ponto dentro do mesmo componente
- Cores semânticas (red=error, orange=warning, green=success)
- Não misture padrões sem motivo claro
- Forneça shortText customizado para melhores abreviações quando necessário
*/
