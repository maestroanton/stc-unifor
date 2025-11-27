// Barra lateral da Administração
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system.dart';
import '../../../helpers/uf_helper.dart';

class AdminSidebar extends StatefulWidget {
  final Function(int) onNavigate;
  final int selectedIndex;

  const AdminSidebar({
    super.key,
    required this.onNavigate,
    this.selectedIndex = 0,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  // Informações do usuário
  String? userEmail;
  String? userUf;
  bool isAdmin = false;
  bool _userInfoLoaded = false;

  static const double _collapsedWidth = 70.0;
  static const double _expandedWidth = 280.0;

  final List<SidebarItem> _menuItems = [
    const SidebarItem(icon: Icons.history, label: 'Auditoria', index: 0),
    const SidebarItem(icon: Icons.email_outlined, label: 'E-mail', index: 1),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDesignSystem.animationStandard,
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: _collapsedWidth, end: _expandedWidth)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: AppDesignSystem.animationCurve,
          ),
        );
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final uf = await UfHelper.getCurrentUserUf();
    final admin = await UfHelper.isAdmin();

    if (mounted) {
      setState(() {
        userEmail = user?.email;
        userUf = uf;
        isAdmin = admin;
        _userInfoLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _handleItemTap(SidebarItem item) {
    widget.onNavigate(item.index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          margin: const EdgeInsets.all(AppDesignSystem.spacing12),
          decoration: BoxDecoration(
            color: AppDesignSystem.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          ),
          child: Column(
            children: [
              // Cabeçalho com logo
              _buildHeader(),

              // Separador
              const Divider(
                color: AppDesignSystem.neutral300,
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
                    return _buildMenuItem(_menuItems[index]);
                  },
                ),
              ),

              // Seção de perfil do usuário
              _buildUserProfile(),

              // Rodapé: separador e botão de alternância
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(SidebarItem item) {
    final isSelected = widget.selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        child: InkWell(
          onTap: () => _handleItemTap(item),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          hoverColor: AppDesignSystem.neutral100,
          child: AnimatedContainer(
            duration: AppDesignSystem.animationFast,
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
                      color: AppDesignSystem.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Ícone
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? AppDesignSystem.primary
                      : AppDesignSystem.neutral600,
                ),

                // Rótulo (visível quando expandido)
                if (_isExpanded) ...[
                  const SizedBox(width: AppDesignSystem.spacing20),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: isSelected
                            ? AppDesignSystem.primary
                            : AppDesignSystem.neutral800,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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

  Widget _buildUserProfile() {
    if (!_userInfoLoaded) {
      return Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing12),
        child: _isExpanded
            ? Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppDesignSystem.neutral300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: AppDesignSystem.surface,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Text(
                      'Carregando...',
                      style: AppDesignSystem.labelSmall.copyWith(
                        color: AppDesignSystem.neutral500,
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
                  color: AppDesignSystem.neutral300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: AppDesignSystem.surface,
                ),
              ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing8,
        vertical: AppDesignSystem.spacing4,
      ),
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: _isExpanded
          ? _buildExpandedUserProfile()
          : _buildCollapsedUserProfile(),
    );
  }

  Widget _buildExpandedUserProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar com indicação de administrador
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppDesignSystem.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppDesignSystem.warning.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 18,
                color: AppDesignSystem.warning,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail ?? 'Admin',
                    style: AppDesignSystem.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.neutral800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesignSystem.spacing2),
                  Row(
                    children: [
                      // Badge do Administrador
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing6,
                          vertical: AppDesignSystem.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusS,
                          ),
                        ),
                        child: Text(
                          'Administrador',
                          style: AppDesignSystem.labelSmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppDesignSystem.warning,
                          ),
                        ),
                      ),
                      if (userUf != null) ...[
                        const SizedBox(width: AppDesignSystem.spacing6),
                        // Badge da UF
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesignSystem.spacing6,
                            vertical: AppDesignSystem.spacing2,
                          ),
                          decoration: BoxDecoration(
                            color: userUf == 'CE'
                                ? AppDesignSystem.success.withValues(alpha: 0.1)
                                : AppDesignSystem.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.radiusS,
                            ),
                          ),
                          child: Text(
                            userUf!,
                            style: AppDesignSystem.labelSmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: userUf == 'CE'
                                  ? AppDesignSystem.success
                                  : AppDesignSystem.info,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          color: AppDesignSystem.warning.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppDesignSystem.warning.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: AppDesignSystem.warning,
              ),
            ),
            // Indicador pequeno de UF
            if (userUf != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: userUf == 'CE'
                        ? AppDesignSystem.success
                        : AppDesignSystem.info,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppDesignSystem.surface,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      userUf!,
                      style: const TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.surface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Separador
        const Divider(
          color: AppDesignSystem.neutral300,
          height: 1,
          indent: AppDesignSystem.spacing12,
          endIndent: AppDesignSystem.spacing12,
        ),

        // Botão alternar
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            child: InkWell(
              onTap: _toggleSidebar,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              hoverColor: AppDesignSystem.neutral100,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacing12,
                  vertical: AppDesignSystem.spacing12,
                ),
                child: Row(
                  mainAxisAlignment: _isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                      size: 20,
                      color: AppDesignSystem.neutral600,
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: AppDesignSystem.spacing20),
                      Expanded(
                        child: Text(
                          'Recolher',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppDesignSystem.neutral800,
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
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Center(
        child: _isExpanded
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 24,
                    color: AppDesignSystem.warning,
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Text(
                    'Administração',
                    style: AppDesignSystem.h3.copyWith(
                      color: AppDesignSystem.warning,
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.admin_panel_settings,
                size: 24,
                color: AppDesignSystem.warning,
              ),
      ),
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
