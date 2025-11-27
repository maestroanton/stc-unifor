import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../helpers/uf_helper.dart';
import '../../core/design_system.dart';
import '../../core/visuals/status_indicator.dart';

class SharedSidebar extends StatefulWidget {
  final Function(int) onNavigate;
  final int selectedIndex;
  final List<SidebarItem> Function(
    String? userUf,
    bool isAdmin,
    bool hasReportAccess,
  )
  getMenuItems;

  const SharedSidebar({
    super.key,
    required this.onNavigate,
    this.selectedIndex = 0,
    required this.getMenuItems,
  });

  @override
  State<SharedSidebar> createState() => _SharedSidebarState();
}

class _SharedSidebarState extends State<SharedSidebar>
    with SingleTickerProviderStateMixin {
  // Informações do usuário
  String? userEmail;
  String? userUf;
  bool isAdmin = false;
  bool hasReportAccess = false;
  bool _userInfoLoaded = false;
  late List<SidebarItem> _menuItems;

  static const double _drawerBreakpoint = 768.0;

  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  static const double _collapsedWidth = 70.0;
  static const double _expandedWidth = 280.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDesignSystem.animationFast,
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: _collapsedWidth, end: _expandedWidth)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _menuItems = widget.getMenuItems(null, false, false);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uf = await UfHelper.getCurrentUserUf();
      final admin = await UfHelper.isAdmin();
      final reportAccess = await UfHelper.hasReportAccess();

      if (mounted) {
        setState(() {
          userEmail = user?.email;
          userUf = uf;
          isAdmin = admin;
          hasReportAccess = reportAccess;
          _userInfoLoaded = true;
          _menuItems = widget.getMenuItems(userUf, isAdmin, hasReportAccess);
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading user info: $e');
        setState(() {
          _userInfoLoaded = true;
          _menuItems = widget.getMenuItems(null, false, false);
        });
      }
    }
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= _drawerBreakpoint;
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleItemTap(BuildContext context, SidebarItem item) {
    widget.onNavigate(item.index);

    // Fechar menu lateral em dispositivos móveis após navegação
    if (!_isLargeScreen(context) && Scaffold.of(context).hasDrawer) {
      Navigator.of(context).pop();
    }
  }

  // Navegar para a tela inicial
  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (Route<dynamic> route) => false, // Remover todas as rotas anteriores
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    // Em dispositivos móveis, menu lateral com largura total
    if (!isLarge) {
      return Container(
        width: _expandedWidth, // Largura total em dispositivos móveis
        color: AppDesignSystem.surface, // Fundo
        child: _buildSidebarContent(isExpanded: true),
      );
    }

    // Em desktop, barra lateral colapsável animada
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: AppDesignSystem.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          ),
          child: _buildSidebarContent(isExpanded: _isExpanded),
        );
      },
    );
  }

  Widget _buildSidebarContent({required bool isExpanded}) {
    return Column(
      children: [
        // Cabeçalho com logotipo
        _buildHeader(),

        // Divisor com cores do design system
        const Divider(
          color: AppDesignSystem.neutral200,
          height: 1,
          indent: AppDesignSystem.spacing12,
          endIndent: AppDesignSystem.spacing12,
        ),

        // Itens do menu
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing8,
              vertical: AppDesignSystem.spacing12,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              return _buildMenuItem(context, _menuItems[index], isExpanded);
            },
          ),
        ),

        // Seção do perfil
        _buildUserProfile(isExpanded),

        // Rodapé com botão de alternância (desktop)
        if (_isLargeScreen(context)) _buildFooter(isExpanded),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Center(
        child: AnimatedScale(
          scale: _isExpanded ? 2 : 1.5,
          duration: AppDesignSystem.animationFast, // Animação do logotipo
          curve: Curves.easeOut,
          child: SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(
              'assets/logo.svg',
              fit: BoxFit.contain,
              semanticsLabel: 'Logo',
              placeholderBuilder: (context) => Container(
                decoration: BoxDecoration(
                  color: AppDesignSystem.neutral100,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: AppDesignSystem.neutral400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    SidebarItem item,
    bool isExpanded,
  ) {
    final isSelected = widget.selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing2),
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        child: InkWell(
          onTap: () => _handleItemTap(context, item),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          hoverColor: AppDesignSystem.neutral50,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 100,
            ), // Atualização rápida dos itens do menu
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing12,
              vertical: AppDesignSystem.spacing12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppDesignSystem.primaryLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: isSelected
                  ? Border.all(
                      color: AppDesignSystem.primary.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? AppDesignSystem.primary
                      : AppDesignSystem.neutral600,
                ),

                // Rótulo
                if (isExpanded) ...[
                  const SizedBox(width: AppDesignSystem.spacing20),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: isSelected
                            ? AppDesignSystem.primary
                            : AppDesignSystem.neutral700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isExpanded) {
    if (!_userInfoLoaded) {
      return Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing12),
        child: isExpanded
            ? Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppDesignSystem.neutral200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: AppDesignSystem.neutral400,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Text(
                      'Carregando...',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.neutral400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppDesignSystem.neutral200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: AppDesignSystem.neutral400,
                ),
              ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing8,
        vertical: AppDesignSystem.spacing4,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral100),
      ),
      child: isExpanded
          ? _buildExpandedUserProfile()
          : _buildCollapsedUserProfile(),
    );
  }

  Widget _buildExpandedUserProfile() {
    return Row(
      children: [
        // Avatar com indicação admin/usuário
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isAdmin
                ? AppDesignSystem.infoLight
                : AppDesignSystem.successLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isAdmin ? AppDesignSystem.info : AppDesignSystem.success,
              width: 2,
            ),
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 18,
            color: isAdmin ? AppDesignSystem.info : AppDesignSystem.success,
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userEmail ?? 'Usuário',
                style: AppDesignSystem.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: AppDesignSystem.spacing2),
              Row(
                children: [
                  // Indicador de função com DotIndicators
                  DotIndicators.standard(
                    text: isAdmin ? 'Admin' : 'Usuário',
                    dotColor: isAdmin
                        ? AppDesignSystem.info
                        : AppDesignSystem.success,
                  ),
                  if (userUf != null) ...[
                    const SizedBox(width: AppDesignSystem.spacing8),
                    // Indicador de UF com DotIndicators
                    DotIndicators.standard(
                      text: userUf!,
                      dotColor: userUf == 'CE'
                          ? AppDesignSystem.warning
                          : AppDesignSystem.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Botão inicial
        const SizedBox(width: AppDesignSystem.spacing8),
        AppDesignSystem.hoverAnimation(
          onTap: () => _navigateToHome(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral100,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral200),
            ),
            child: const Icon(
              Icons.home_outlined,
              size: 18,
              color: AppDesignSystem.neutral600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedUserProfile() {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isAdmin
              ? AppDesignSystem.infoLight
              : AppDesignSystem.successLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: isAdmin ? AppDesignSystem.info : AppDesignSystem.success,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 16,
                color: isAdmin ? AppDesignSystem.info : AppDesignSystem.success,
              ),
            ),
            if (userUf != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: userUf == 'CE'
                        ? AppDesignSystem.warning
                        : AppDesignSystem.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppDesignSystem.surface,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      userUf!,
                      style: AppDesignSystem.labelSmall.copyWith(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.surface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isExpanded) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divisor com cores do design system
        const Divider(
          color: AppDesignSystem.neutral200,
          height: 1,
          indent: AppDesignSystem.spacing12,
          endIndent: AppDesignSystem.spacing12,
        ),

        // Botão de alternância com efeito ao passar o mouse
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing8),
          child: AppDesignSystem.hoverAnimation(
            onTap: _toggleSidebar,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacing12,
                vertical: AppDesignSystem.spacing12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    size: 20,
                    color: AppDesignSystem.neutral600,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: AppDesignSystem.spacing20),
                    Expanded(
                      child: Text(
                        'Recolher',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
