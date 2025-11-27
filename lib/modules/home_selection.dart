// lib/pages/home_selection.dart (ATUALIZADO: acesso a botões baseado em permissões)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utilities/shared/responsive.dart';
import '../../core/design_system.dart';
import '../../core/visuals/snackbar.dart';
import '../../core/visuals/dialogue.dart';
import '../../helpers/uf_helper.dart';
import '../../services/user_role.dart'; // Adicionado para verificação de permissões
import '../../models/user_role.dart'; // Adicionado para o modelo UserRole

class HomeSelectionScreen extends StatefulWidget {
  const HomeSelectionScreen({super.key});

  @override
  State<HomeSelectionScreen> createState() => _HomeSelectionScreenState();
}

class _HomeSelectionScreenState extends State<HomeSelectionScreen> {
  bool isAdmin = false;
  bool isLoading = true;
  bool isDisconnecting = false;

  // Adicionado para verificação de permissões
  final UserRoleService _userRoleService = UserRoleService();
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserPermissions(); // Atualizado para verificar permissões completas
  }

  // Método atualizado para verificar todas as permissões do usuário
  Future<void> _checkUserPermissions() async {
    try {
      final admin = await UfHelper.isAdmin();
      final userRole = await _userRoleService.getCurrentUserRole();

      if (mounted) {
        setState(() {
          isAdmin = admin;
          _userRole = userRole;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isAdmin = false;
          _userRole = null;
          isLoading = false;
        });
      }
    }
  }

  // Métodos de verificação de permissão - Corrigidos para checar explicitamente valores true
  bool _hasOperatorAccess() {
    // Deve ser explicitamente true; null ou false significa sem acesso
    final hasOperator = _userRole?.isOperator == true;
    final hasAdmin = _userRole?.isAdmin == true || isAdmin;
    return hasOperator || hasAdmin;
  }

  bool _hasAdminAccess() {
    // Deve ser explicitamente true; null ou false significa sem acesso
    return _userRole?.isAdmin == true || isAdmin;
  }

  Future<void> _disconnect() async {
    // Exibir diálogo de confirmação usando o DialogUtils padronizado
    await DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Desconectar',
      content: 'Você tem certeza que deseja sair? Sua sessão será encerrada.',
      confirmText: 'Sair',
      confirmColor: AppDesignSystem.error,
      onConfirm: () async {
        setState(() => isDisconnecting = true);
        try {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            SnackBarUtils.showSuccess(
              context,
              'Desconectado com sucesso',
              duration: const Duration(seconds: 2),
            );
            // Navegar para a tela de login ou outro destino apropriado
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          setState(() => isDisconnecting = false);
          if (mounted) {
            SnackBarUtils.showError(context, 'Erro ao desconectar: $e');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppDesignSystem.background,
        body: Center(
          child: CircularProgressIndicator(color: AppDesignSystem.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Botão de desconexão no canto superior direito
            Positioned(
              top: AppDesignSystem.spacing16,
              right: AppDesignSystem.spacing16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppDesignSystem.surface,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                  boxShadow: AppDesignSystem.shadowSM,
                ),
                child: IconButton(
                  onPressed: isDisconnecting ? null : _disconnect,
                  icon: isDisconnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.logout,
                          color: AppDesignSystem.error,
                          size: 20,
                        ),
                  tooltip: 'Desconectar',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ),

            // Conteúdo principal
            Center(
              child: Container(
                width: Responsive.value(
                  context,
                  mobile: 280.0,
                  tablet: _hasAdminAccess()
                      ? 450.0
                      : 360.0, // Atualizado para usar verificação de permissões
                  desktop: _hasAdminAccess()
                      ? 520.0
                      : 400.0, // Atualizado para usar verificação de permissões
                ),
                padding: EdgeInsets.all(
                  Responsive.value(
                    context,
                    mobile: AppDesignSystem.spacing24,
                    tablet: AppDesignSystem.spacing32,
                    desktop: AppDesignSystem.spacing32,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppDesignSystem.surface,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXL),
                  boxShadow: AppDesignSystem.shadowMD,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppDesignSystem.spacing8),

                    // Título
                    Text(
                      'Escolha um módulo',
                      style: TextStyle(
                        fontSize: Responsive.value(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    // Indicador de permissão - Atualizado para mostrar o nível de permissão real
                    if (_userRole != null) ...[
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getBadgeIcon(),
                              size: 16,
                              color: _getBadgeTextColor(),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _userRole!.permissionLevel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getBadgeTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(
                      height: Responsive.value(
                        context,
                        mobile: 24.0,
                        tablet: 28.0,
                        desktop: 32.0,
                      ),
                    ),

                    // Opções - Atualizado para usar layout baseado em permissões
                    _buildPermissionBasedLayout(),

                    const SizedBox(height: AppDesignSystem.spacing16),

                    // Texto de versão - pequeno e sutil
                    const Text(
                      'v0.1',
                      style: TextStyle(
                        fontSize: 9.0,
                        color: AppDesignSystem.neutral400,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para estilizar o crachá
  Color _getBadgeColor() {
    if (_userRole?.isAdmin == true) return Colors.orange[100]!;
    if (_userRole?.isOperator == true) return AppDesignSystem.infoLight;
    return AppDesignSystem.neutral100;
  }

  IconData _getBadgeIcon() {
    if (_userRole?.isAdmin == true) return Icons.badge;
    if (_userRole?.isOperator == true) return Icons.engineering;
    return Icons.person;
  }

  Color _getBadgeTextColor() {
    if (_userRole?.isAdmin == true) return Colors.orange[700]!;
    if (_userRole?.isOperator == true) return AppDesignSystem.info;
    return AppDesignSystem.neutral700;
  }

  // Método de layout atualizado que respeita permissões
  Widget _buildPermissionBasedLayout() {
    List<Widget> availableOptions = [];

    // Módulos nível operador (requer acesso operador ou admin)
    if (_hasOperatorAccess()) {
      availableOptions.addAll([
        _OptionTile(
          icon: Icons.warehouse_outlined,
          iconColor: const Color(0xFF66BB6A),
          iconBackgroundColor: const Color(0xFFE8F5E8),
          label: 'Inventário',
          onTap: () => Navigator.pushReplacementNamed(context, '/inventario'),
        ),
        _OptionTile(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFFFF7043),
          iconBackgroundColor: const Color(0xFFFFF3E0),
          label: 'Licenças',
          onTap: () => Navigator.pushReplacementNamed(context, '/licenca'),
        ),
      ]);
    }

    // Módulo de solicitação de acesso (requer permissão requestAccess)
    // Removido conforme requisitos

    // Módulo somente admin (requer acesso admin)
    if (_hasAdminAccess()) {
      availableOptions.add(
        _OptionTile(
          icon: Icons.admin_panel_settings_outlined,
          iconColor: const Color(0xFF9C27B0),
          iconBackgroundColor: const Color(0xFFF3E5F5),
          label: 'Auditoria',
          onTap: () => Navigator.pushReplacementNamed(context, '/auditoria'),
        ),
      );
    }

    // Se sem permissões, mostrar mensagem
    if (availableOptions.isEmpty) {
      return Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: AppDesignSystem.neutral400,
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Text(
            'Nenhum módulo disponível',
            style: AppDesignSystem.bodyLarge.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            'Entre em contato com o administrador para solicitar acesso',
            style: AppDesignSystem.bodySmall.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Organizar as opções disponíveis
    return _buildOptionsLayout(availableOptions);
  }

  Widget _buildOptionsLayout(List<Widget> options) {
    if (Responsive.isMobile(context)) {
      // Móvel: 2 colunas, empilhar linhas verticalmente
      List<Widget> rows = [];
      for (int i = 0; i < options.length; i += 2) {
        if (i + 1 < options.length) {
          // Dois itens nesta linha
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [options[i], options[i + 1]],
            ),
          );
        } else {
          // Item único nesta linha - centralizar
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [options[i]],
            ),
          );
        }

        if (i + 2 < options.length) {
          rows.add(const SizedBox(height: AppDesignSystem.spacing16));
        }
      }
      return Column(children: rows);
    } else {
      // Tablet/Desktop: 3 colunas para módulos de operador, 2 colunas para a última linha
      List<Widget> rows = [];

      // Primeira linha: até 2 itens (módulos de operador)
      int operatorModules = _hasOperatorAccess() ? 2 : 0;
      if (operatorModules > 0 && options.length >= operatorModules) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.take(2).toList(),
          ),
        );

        if (options.length > 2) {
          rows.add(const SizedBox(height: AppDesignSystem.spacing16));
        }
      }

      // Segunda linha: itens restantes (admin)
      if (options.length > 2) {
        List<Widget> secondRowItems = options.skip(2).toList();
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: secondRowItems,
          ),
        );
      } else if (operatorModules == 0) {
        // Se sem acesso operador, mostrar itens disponíveis em linhas de 2
        for (int i = 0; i < options.length; i += 2) {
          if (i + 1 < options.length) {
            // Dois itens nesta linha
            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [options[i], options[i + 1]],
              ),
            );
          } else {
            // Item único nesta linha - centralizar
            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [options[i]],
              ),
            );
          }

          if (i + 2 < options.length) {
            rows.add(const SizedBox(height: AppDesignSystem.spacing16));
          }
        }
      }

      return Column(children: rows);
    }
  }
}

// Mantenha o _OptionTile original inalterado
class _OptionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.label,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: AppDesignSystem.animationStandard,
          curve: AppDesignSystem.animationCurve,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDesignSystem.spacing16,
              horizontal: AppDesignSystem.spacing12,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppDesignSystem.neutral50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container do ícone
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    color: widget.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusL,
                    ),
                  ),
                  child: Icon(widget.icon, size: 28.0, color: widget.iconColor),
                ),

                const SizedBox(height: AppDesignSystem.spacing12),

                // Rótulo
                Text(
                  widget.label,
                  style: AppDesignSystem.labelMedium.copyWith(fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
