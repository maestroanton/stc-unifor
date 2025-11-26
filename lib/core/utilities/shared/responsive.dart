import 'package:flutter/material.dart';

/// Utilitário para medidas e regras responsivas do app
class Responsive {
  // Construtor privado — evita instanciação
  Responsive._();

  // ==================== PONTOS DE CORTE ====================

  /// Ponto de corte para dispositivos móveis
  static const double mobileBreakpoint = 600.0;

  /// Ponto de corte para tablets pequenos / telefones maiores
  static const double smallTabletBreakpoint = 768.0;

  /// Ponto de corte para tablet (entre mobile e desktop)
  static const double tabletBreakpoint = 1024.0;

  /// Ponto de corte para desktop
  static const double desktopBreakpoint = 1200.0;

  /// Ponto de corte para desktops maiores
  static const double largeDesktopBreakpoint = 1440.0;

  // ==================== DETECÇÃO DE TIPO DE TELA ====================

  /// True se a largura for considerada móvel
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// True se a largura for considerada tablet pequeno
  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < smallTabletBreakpoint;
  }

  /// True se a largura for considerada tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallTabletBreakpoint && width < tabletBreakpoint;
  }

  /// True se a largura for considerada desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// True se a largura for considerada desktop grande
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// True se a tela for mobile ou tablet pequeno
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < smallTabletBreakpoint;
  }

  /// True se a tela for algum tipo de tablet
  static bool isAnyTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // ==================== VALORES RESPONSIVOS ====================

  /// Retorna um valor conforme o tamanho da tela (detalhado)
  static T valueDetailed<T>(
    BuildContext context, {
    required T mobile,
    T? smallTablet,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) return mobile;
    if (width < smallTabletBreakpoint) return smallTablet ?? mobile;
    if (width < tabletBreakpoint) return tablet ?? smallTablet ?? mobile;
    if (width < desktopBreakpoint) {
      return desktop ?? tablet ?? smallTablet ?? mobile;
    }
    if (width < largeDesktopBreakpoint) {
      return desktop ?? tablet ?? smallTablet ?? mobile;
    }
    return largeDesktop ?? desktop ?? tablet ?? smallTablet ?? mobile;
  }

  /// Retorna um valor conforme o tamanho da tela (simplificado)
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    return valueDetailed(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Retorna um valor considerando também desktop grande
  static T valueWithLarge<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
    T? largeDesktop,
  }) {
    return valueDetailed(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // ==================== ESPAÇAMENTO E PADDING ====================

  /// Retorna padding responsivo
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.all(
      valueDetailed(
        context,
        mobile: 8.0,
        smallTablet: 12.0,
        tablet: 16.0,
        desktop: 16.0,
      ),
    );
  }

  /// Retorna padding horizontal responsivo
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: valueDetailed(
        context,
        mobile: 8.0,
        smallTablet: 12.0,
        tablet: 16.0,
        desktop: 16.0,
      ),
    );
  }

  /// Retorna padding vertical responsivo
  static EdgeInsets verticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      vertical: valueDetailed(
        context,
        mobile: 8.0,
        smallTablet: 12.0,
        tablet: 16.0,
        desktop: 16.0,
      ),
    );
  }

  /// Retorna espaçamento responsivo entre elementos
  static double spacing(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 8.0,
      smallTablet: 12.0,
      tablet: 16.0,
      desktop: 16.0,
    );
  }

  /// Retorna espaçamento grande responsivo entre seções
  static double largeSpacing(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 16.0,
      smallTablet: 20.0,
      tablet: 24.0,
      desktop: 24.0,
    );
  }

  /// Retorna espaçamento pequeno para layouts compactos
  static double smallSpacing(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 4.0,
      smallTablet: 6.0,
      tablet: 8.0,
      desktop: 8.0,
    );
  }

  // ==================== TIPOGRAFIA ====================

  /// Retorna tamanho de fonte responsivo para títulos
  static double headerFontSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 18.0,
      smallTablet: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );
  }

  /// Retorna tamanho de fonte responsivo para subtítulos
  static double subHeaderFontSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 14.0,
      smallTablet: 16.0,
      tablet: 17.0,
      desktop: 18.0,
    );
  }

  /// Retorna tamanho de fonte responsivo para corpo de texto
  static double bodyFontSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 12.0,
      smallTablet: 13.0,
      tablet: 13.0,
      desktop: 14.0,
    );
  }

  /// Retorna tamanho de fonte responsivo para texto pequeno
  static double smallFontSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 10.0,
      smallTablet: 11.0,
      tablet: 11.0,
      desktop: 12.0,
    );
  }

  /// Retorna tamanho de fonte responsivo para texto grande
  static double largeFontSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 14.0,
      smallTablet: 15.0,
      tablet: 15.0,
      desktop: 16.0,
    );
  }

  // ==================== TAMANHOS DE ÍCONES ====================

  /// Retorna tamanho de ícone responsivo (padrão)
  static double iconSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 18.0,
      smallTablet: 19.0,
      tablet: 20.0,
      desktop: 20.0,
    );
  }

  /// Retorna tamanho de ícone responsivo (pequeno)
  static double smallIconSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 14.0,
      smallTablet: 15.0,
      tablet: 16.0,
      desktop: 16.0,
    );
  }

  /// Retorna tamanho de ícone responsivo (grande)
  static double largeIconSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 24.0,
      smallTablet: 28.0,
      tablet: 30.0,
      desktop: 32.0,
    );
  }

  // ==================== DIMENSÕES DE BOTÕES ====================

  /// Retorna altura do botão responsiva
  static double buttonHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 40.0,
      smallTablet: 44.0,
      tablet: 46.0,
      desktop: 48.0,
    );
  }

  /// Retorna padding dos botões responsivo
  static EdgeInsets buttonPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: valueDetailed(
        context,
        mobile: 12.0,
        smallTablet: 14.0,
        tablet: 16.0,
        desktop: 16.0,
      ),
      vertical: valueDetailed(
        context,
        mobile: 8.0,
        smallTablet: 10.0,
        tablet: 12.0,
        desktop: 12.0,
      ),
    );
  }

  /// Retorna constraints responsivas para botões de ícone
  static BoxConstraints iconButtonConstraints(BuildContext context) {
    final size = valueDetailed(
      context,
      mobile: 32.0,
      smallTablet: 36.0,
      tablet: 38.0,
      desktop: 40.0,
    );
    return BoxConstraints(minWidth: size, minHeight: size);
  }

  /// Retorna constraints compactas para botões de ícone
  static BoxConstraints compactIconButtonConstraints(BuildContext context) {
    final size = valueDetailed(
      context,
      mobile: 24.0,
      smallTablet: 28.0,
      tablet: 30.0,
      desktop: 32.0,
    );
    return BoxConstraints(minWidth: size, minHeight: size);
  }

  // ==================== DIMENSÕES DE CARTÕES E CONTÊINERES ====================

  /// Retorna raio de borda responsivo
  static double borderRadius(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 8.0,
      smallTablet: 10.0,
      tablet: 12.0,
      desktop: 12.0,
    );
  }

  /// Retorna elevação do cartão responsiva
  static double cardElevation(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 1.0,
      smallTablet: 1.5,
      tablet: 2.0,
      desktop: 2.0,
    );
  }

  /// Retorna largura da sidebar responsiva
  static double sidebarWidth(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 240.0,
      smallTablet: 260.0,
      tablet: 280.0,
      desktop: 280.0,
    );
  }

  /// Retorna altura do appbar responsiva
  static double appBarHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 56.0,
      smallTablet: 60.0,
      tablet: 64.0,
      desktop: 64.0,
    );
  }

  // ==================== GRADE & LISTAS ====================

  /// Retorna número de colunas da grade conforme o ponto de corte
  static int gridCrossAxisCount(
    BuildContext context, {
    int mobileCount = 2,
    int? smallTabletCount,
    int? tabletCount,
    int desktopCount = 4,
  }) {
    return valueDetailed(
      context,
      mobile: mobileCount,
      smallTablet: smallTabletCount ?? mobileCount,
      tablet: tabletCount ?? (smallTabletCount ?? mobileCount),
      desktop: desktopCount,
    );
  }

  /// Contagem inteligente de colunas que se adapta à largura disponível
  static int smartGridCrossAxisCount(
    BuildContext context, {
    double minItemWidth = 200.0,
    int maxColumns = 6,
    int minColumns = 1,
  }) {
    final width = MediaQuery.of(context).size.width;
    final availableWidth = width - (padding(context).horizontal);
    final columns = (availableWidth / minItemWidth).floor();
    return columns.clamp(minColumns, maxColumns);
  }

  /// Retorna espaçamento da grade responsivo
  static double gridSpacing(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 8.0,
      smallTablet: 12.0,
      tablet: 16.0,
      desktop: 16.0,
    );
  }

  /// Retorna altura responsiva dos itens de lista
  static double listItemHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 60.0,
      smallTablet: 66.0,
      tablet: 70.0,
      desktop: 72.0,
    );
  }

  // ==================== DIRETIVAS DA SIDEBAR ====================

  /// Indica se o botão de alternar da sidebar deve ser exibido
  static bool shouldShowSidebarToggle(BuildContext context) {
    return !isMobile(context) && !isSmallTablet(context);
  }

  /// Indica se a sidebar deve estar estendida por padrão
  static bool shouldExtendSidebar(BuildContext context) {
    return isDesktop(context) || isLargeDesktop(context);
  }

  /// Indica se a sidebar deve colapsar automaticamente após navegação
  static bool shouldAutoCollapseSidebar(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Indica se deve usar um drawer em vez da sidebar
  static bool shouldUseDrawer(BuildContext context) {
    return isMobile(context);
  }

  // ==================== DIRETIVAS DE FORMULÁRIO ====================

  /// Indica se os rótulos dos botões do formulário devem ser exibidos
  static bool shouldShowButtonLabels(BuildContext context) {
    return !isMobile(context);
  }

  /// Indica se deve usar layout compacto no formulário
  static bool shouldUseCompactForm(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Indica se campos do formulário devem ser empilhados verticalmente
  static bool shouldStackFormFields(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  // ==================== DIRETIVAS DE NAVEGAÇÃO ====================

  /// Indica se a navegação deve usar apenas ícones
  static bool shouldUseIconOnlyNavigation(BuildContext context) {
    return isMobile(context);
  }

  /// Indica se os rótulos da navegação devem ser exibidos
  static bool shouldShowNavigationLabels(BuildContext context) {
    return isDesktop(context) || isLargeDesktop(context);
  }

  /// Indica se deve usar navegação inferior em vez de sidebar
  static bool shouldUseBottomNavigation(BuildContext context) {
    return isMobile(context);
  }

  // ==================== DIRETIVAS DE TABELAS E LISTAS ====================

  static bool shouldUseSingleRowActions(BuildContext context) {
    return true; // Sempre usar única linha; ajustar tamanho no móvel
  }

  /// Indica se a paginação deve mostrar somente ícones
  static bool shouldUseIconOnlyPagination(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Indica se os itens da lista devem ser compactos
  static bool shouldUseDenseListItems(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Retorna a largura da tela
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retorna a altura da tela
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Retorna a orientação da tela
  static Orientation orientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Retorna true se a tela estiver em modo landscape
  static bool isLandscape(BuildContext context) {
    return orientation(context) == Orientation.landscape;
  }

  /// Retorna true se a tela estiver em modo portrait
  static bool isPortrait(BuildContext context) {
    return orientation(context) == Orientation.portrait;
  }

  /// Retorna padding da área segura
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Retorna a razão de pixels do dispositivo
  static double pixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Retorna o nome do breakpoint atual (para depuração)
  static String currentBreakpoint(BuildContext context) {
    if (isMobile(context)) return 'Mobile';
    if (isSmallTablet(context)) return 'Small Tablet';
    if (isTablet(context)) return 'Tablet';
    if (isDesktop(context)) return 'Desktop';
    if (isLargeDesktop(context)) return 'Large Desktop';
    return 'Unknown';
  }
}

/// Extensão de BuildContext para acesso rápido às utilidades responsivas
extension ResponsiveExtension on BuildContext {
  /// Acesso rápido às utilidades responsivas
  bool get isMobile => Responsive.isMobile(this);
  bool get isSmallTablet => Responsive.isSmallTablet(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isSmallScreen => Responsive.isSmallScreen(this);
  bool get isAnyTablet => Responsive.isAnyTablet(this);

  /// Acesso rápido a valores responsivos
  double get spacing => Responsive.spacing(this);
  double get largeSpacing => Responsive.largeSpacing(this);
  double get smallSpacing => Responsive.smallSpacing(this);

  /// Acesso rápido a tamanhos de fonte responsivos
  double get headerFontSize => Responsive.headerFontSize(this);
  double get bodyFontSize => Responsive.bodyFontSize(this);
  double get smallFontSize => Responsive.smallFontSize(this);

  /// Acesso rápido a tamanhos de ícone responsivos
  double get iconSize => Responsive.iconSize(this);
  double get smallIconSize => Responsive.smallIconSize(this);
  double get largeIconSize => Responsive.largeIconSize(this);

  /// Acesso rápido ao breakpoint atual
  String get breakpoint => Responsive.currentBreakpoint(this);
}
