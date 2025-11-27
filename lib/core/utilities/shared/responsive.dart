// Utilitário responsivo
import 'package:flutter/material.dart';

/// Utilitário responsivo para lidar com diferentes tamanhos de tela
/// e fornecer medidas e diretrizes consistentes pelo app
class Responsive {
  // Construtor privado para evitar instanciação
  Responsive._();

  // ==================== PONTOS DE CORTE ====================

  /// Ponto de corte para mobile — telas menores são consideradas móveis
  static const double mobileBreakpoint = 600.0; // Aumentado de 480

  /// Ponto de corte para small tablet — tablets pequenos e celulares grandes
  static const double smallTabletBreakpoint = 768.0;

  /// Ponto de corte para tablet — telas entre mobile e desktop
  static const double tabletBreakpoint =
      1024.0; // Padrão mais comum para tablet

  /// Ponto de corte para desktop — telas maiores são consideradas desktop
  static const double desktopBreakpoint = 1200.0;

  /// Ponto de corte para desktop grande — para telas muito grandes
  static const double largeDesktopBreakpoint = 1440.0;

  // ==================== DETECÇÃO DE TIPO DE TELA ====================

  /// Retorna true se a largura for considerada mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Retorna true se a largura for considerada small tablet
  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < smallTabletBreakpoint;
  }

  /// Retorna true se a largura for considerada tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallTabletBreakpoint && width < tabletBreakpoint;
  }

  /// Retorna true se a largura for considerada desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Retorna true se a largura for considerada desktop grande
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// Retorna true se a tela for mobile ou small tablet (telas bem pequenas)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < smallTabletBreakpoint;
  }

  /// Retorna true se a tela for qualquer tipo de tablet
  static bool isAnyTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // ==================== VALORES RESPONSIVOS ====================

  /// Retorna um valor baseado no tamanho da tela usando todos os pontos de corte
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

  /// Retorna um valor baseado no tamanho da tela (versão simplificada)
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

  /// Retorna um valor baseado no tamanho da tela com opção para desktop grande
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

  /// Retorna valores de padding responsivos
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

  /// Retorna espaçamento pequeno responsivo para layouts compactos
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

  /// Retorna tamanho de fonte responsivo para texto body
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

  // ==================== TAMANHOS DE ÍCONE ====================

  /// Retorna tamanho responsivo para ícones normais
  static double iconSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 18.0,
      smallTablet: 19.0,
      tablet: 20.0,
      desktop: 20.0,
    );
  }

  /// Retorna tamanho responsivo para ícones pequenos
  static double smallIconSize(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 14.0,
      smallTablet: 15.0,
      tablet: 16.0,
      desktop: 16.0,
    );
  }

  /// Retorna tamanho responsivo para ícones grandes
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

  /// Retorna altura responsiva do botão
  static double buttonHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 40.0,
      smallTablet: 44.0,
      tablet: 46.0,
      desktop: 48.0,
    );
  }

  /// Retorna padding responsivo para botões
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

  /// Retorna constraints responsivos para botões ícone
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

  /// Retorna constraints compactos responsivos para botões ícone
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

  /// Retorna border radius responsivo
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

  /// Retorna altura do appBar responsiva
  static double appBarHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 56.0,
      smallTablet: 60.0,
      tablet: 64.0,
      desktop: 64.0,
    );
  }

  // ==================== LAYOUTS DE GRID E LISTA ====================

  /// Retorna número de colunas do grid responsivo
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

  /// Número de colunas inteligente que se adapta à largura disponível
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

  /// Retorna espaçamento do grid responsivo
  static double gridSpacing(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 8.0,
      smallTablet: 12.0,
      tablet: 16.0,
      desktop: 16.0,
    );
  }

  /// Retorna altura do item da lista responsiva
  static double listItemHeight(BuildContext context) {
    return valueDetailed(
      context,
      mobile: 60.0,
      smallTablet: 66.0,
      tablet: 70.0,
      desktop: 72.0,
    );
  }

  // ==================== DIRETIVAS DE SIDEBAR ====================

  /// Retorna se a sidebar deve mostrar botão de alternância
  static bool shouldShowSidebarToggle(BuildContext context) {
    return !isMobile(context) && !isSmallTablet(context);
  }

  /// Retorna se a sidebar deve ficar estendida por padrão
  static bool shouldExtendSidebar(BuildContext context) {
    return isDesktop(context) || isLargeDesktop(context);
  }

  /// Retorna se a sidebar deve recolher automaticamente após navegação
  static bool shouldAutoCollapseSidebar(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Retorna se deve mostrar drawer ao invés da sidebar
  static bool shouldUseDrawer(BuildContext context) {
    return isMobile(context);
  }

  // ==================== DIRETIVAS DE FORMULÁRIO ====================

  /// Retorna se deve exibir labels ao lado dos botões do formulário
  static bool shouldShowButtonLabels(BuildContext context) {
    return !isMobile(context);
  }

  /// Retorna se deve usar layout compacto no formulário
  static bool shouldUseCompactForm(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Retorna se os campos do formulário devem ser empilhados verticalmente
  static bool shouldStackFormFields(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  // ==================== DIRETIVAS DE NAVEGAÇÃO ====================

  /// Retorna se deve mostrar botões de navegação somente com ícones
  static bool shouldUseIconOnlyNavigation(BuildContext context) {
    return isMobile(context);
  }

  /// Retorna se deve mostrar labels de navegação
  static bool shouldShowNavigationLabels(BuildContext context) {
    return isDesktop(context) || isLargeDesktop(context);
  }

  /// Retorna se deve usar bottom navigation em vez da sidebar
  static bool shouldUseBottomNavigation(BuildContext context) {
    return isMobile(context);
  }

  // ==================== DIRETIVAS DE TABELA E LISTA ====================

  /// Retorna se deve mostrar botões de ação em uma única linha
  static bool shouldUseSingleRowActions(BuildContext context) {
    return true; // Sempre usar única linha, mas reduzir botões em telas mobile
  }

  /// Retorna se a paginação deve ser apenas ícones
  static bool shouldUseIconOnlyPagination(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  /// Retorna se os itens da lista devem ser densos
  static bool shouldUseDenseListItems(BuildContext context) {
    return isMobile(context) || isSmallTablet(context);
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Retorna largura da tela
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retorna altura da tela
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Retorna a orientação da tela
  static Orientation orientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Retorna se a tela está em modo paisagem
  static bool isLandscape(BuildContext context) {
    return orientation(context) == Orientation.landscape;
  }

  /// Retorna se a tela está em modo retrato
  static bool isPortrait(BuildContext context) {
    return orientation(context) == Orientation.portrait;
  }

  /// Retorna padding da safe area
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Retorna device pixel ratio
  static double pixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Retorna nome do breakpoint atual (para debug)
  static String currentBreakpoint(BuildContext context) {
    if (isMobile(context)) return 'Mobile';
    if (isSmallTablet(context)) return 'Small Tablet';
    if (isTablet(context)) return 'Tablet';
    if (isDesktop(context)) return 'Desktop';
    if (isLargeDesktop(context)) return 'Large Desktop';
    return 'Unknown';
  }
}

/// Extensão em BuildContext para acesso às utilidades responsivas
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
