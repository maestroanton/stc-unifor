import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de Design Unificado
class AppDesignSystem {
  AppDesignSystem._();

  // ==================== PALETA DE CORES ====================

  /// Cores primárias
  static const Color primary = Color(0xFF1E5EA4); // Azul escuro
  static const Color primaryLight = Color(0xFFE3F2FD); // Azul claro
  static const Color primaryDark = Color(0xFF1565C0); // Azul escuro

  /// Cores neutras
  static const Color neutral900 = Color(0xFF1F2937);
  static const Color neutral800 = Color(0xFF2D3748);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4A5568);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF8FAFC);

  /// Cores de status
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFED7D7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEBF4FF);

  /// Cores do sistema
  static const Color background = neutral50;
  static const Color surface = Colors.white;
  static const Color systemActive = Color(0xFF48BB78);

  /// Cores neutras adicionais
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ==================== TIPOGRAFIA ====================

  /// Estilos de texto
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: neutral900,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: neutral800,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: neutral700,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: neutral700,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: neutral600,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: neutral500,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: neutral700,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: neutral600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: neutral500,
    letterSpacing: 0.5,
  );

  // ==================== SISTEMA DE ESPAÇAMENTO ====================

  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ==================== RAIO DE BORDA ====================

  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusFull = 9999.0;

  // ==================== CONSTANTES DE ANIMAÇÃO ====================

  /// Durações
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationStandard = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 300);

  /// Curvas
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve animationCurveEmphasized = Curves.easeOutBack;

  // ==================== EFEITOS DE HOVER ====================

  /// Animação de hover
  static Widget hoverAnimation({
    required Widget child,
    VoidCallback? onTap,
    bool enabled = true,
    SystemMouseCursor cursor = SystemMouseCursors.click,
  }) {
    if (!enabled) return child;

    return _HoverAnimationWrapper(onTap: onTap, cursor: cursor, child: child);
  }

  // ==================== SOMBRAS ====================

  static const List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Color.fromARGB(10, 0, 0, 0),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Color.fromARGB(20, 0, 0, 0),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ==================== ESTILOS DE COMPONENTE ====================

  /// Decoração de card
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.all(Radius.circular(radiusL)),
    boxShadow: shadowSM,
  );

  /// Decoração de campo de entrada
  static InputDecoration inputDecoration({
    required String hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: bodyMedium.copyWith(color: neutral400),
      labelStyle: labelMedium,
      filled: true,
      fillColor: surface,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: hasError ? error : neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: hasError ? error : neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: hasError ? error : primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing12,
        vertical: spacing12,
      ),
    );
  }

  /// Estilos de botão
  static const ButtonStyle primaryButton = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(primary),
    foregroundColor: WidgetStatePropertyAll(surface),
    elevation: WidgetStatePropertyAll(0),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    ),
    textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w500))
  );

  static const ButtonStyle secondaryButton = ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(neutral600),
    side: WidgetStatePropertyAll(BorderSide(color: neutral200)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    ),
  );

  static const double spacing10 = 10.0;

  static const Color secondary = neutral600;

  // ==================== PADRÕES DE UI COMUNS ====================

  /// Indicador de status do sistema
  static Widget systemStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing8,
      ),
      decoration: BoxDecoration(
        color: systemActive,
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: spacing8),
          SelectableText(
            'Sistema Ativo',
            style: labelSmall.copyWith(
              color: surface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Cabeçalho de página
  static Widget pageHeader({
    required IconData icon,
    required String title,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing16,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: neutral100,
                foregroundColor: neutral700,
              ),
            ),
            const SizedBox(width: spacing16),
          ],
          Icon(icon, color: primary, size: 24),
          const SizedBox(width: spacing12),
          SelectableText(title, style: h2),
          const Spacer(),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  /// Badge de status
  static Widget statusBadge({
    required String text,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? spacing6 : spacing8,
        vertical: isSmall ? spacing2 : spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusS),
      ),
      child: SelectableText(
        text.toUpperCase(),
        style: (isSmall ? labelSmall : labelMedium).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Indicador de prioridade
  static Widget priorityIndicator(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'alta':
      case 'crítica':
        color = error;
        break;
      case 'média':
        color = warning;
        break;
      case 'baixa':
        color = success;
        break;
      default:
        color = neutral400;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Avatar do usuário
  static Widget userAvatar({
    required String name,
    Color? backgroundColor,
    double size = 32,
  }) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: surface,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Estado vazio
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: neutral300),
          const SizedBox(height: spacing12),
          SelectableText(title, style: bodyLarge.copyWith(color: neutral500)),
          if (subtitle != null) ...[
            const SizedBox(height: spacing8),
            SelectableText(
              subtitle,
              style: bodyMedium.copyWith(color: neutral400),
            ),
          ],
          if (action != null) ...[const SizedBox(height: spacing24), action],
        ],
      ),
    );
  }

  /// Estado de carregamento
  static Widget loadingState() {
    return const Center(child: CircularProgressIndicator(color: primary));
  }
}

/// Wrapper de animação de hover
class _HoverAnimationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final SystemMouseCursor cursor;

  const _HoverAnimationWrapper({
    required this.child,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<_HoverAnimationWrapper> createState() => _HoverAnimationWrapperState();
}

class _HoverAnimationWrapperState extends State<_HoverAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDesignSystem.animationStandard,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppDesignSystem.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        _controller.forward();
      },
      onExit: (_) {
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

// ==================== COMPONENTES DE LAYOUT ====================

/// Wrapper de layout base para todas as telas
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;

  const AppScaffold({super.key, required this.body, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppDesignSystem.background,
      body: body,
    );
  }
}

/// Container de conteúdo
class AppContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const AppContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppDesignSystem.background,
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacing24),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Componente de card
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final String? title;

  const AppCard({super.key, required this.child, this.padding, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacing24),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SelectableText(
              title!.toUpperCase(),
              style: AppDesignSystem.labelSmall.copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacing20),
          ],
          child,
        ],
      ),
    );
  }
}

/// Wrapper de campo de formulário
class AppFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;

  const AppFormField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SelectableText(label, style: AppDesignSystem.labelMedium),
            if (isRequired)
              SelectableText(
                ' *',
                style: AppDesignSystem.labelMedium.copyWith(
                  color: AppDesignSystem.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDesignSystem.spacing6),
        child,
      ],
    );
  }
}
