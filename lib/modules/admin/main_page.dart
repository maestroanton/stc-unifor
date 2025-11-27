// Página principal da Administração
import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'widgets/sidebar.dart';
import 'auditoria.dart';
import 'email.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const AuditLogsPageContent();
      case 1:
        return const EmailManagementPage();
      case 2:
        return _buildPlaceholderPage('Gerenciamento de Avarias');
      case 20:
        return _buildPlaceholderPage('Gerenciar Avarias');
      case 21:
        return _buildPlaceholderPage('Relatórios de Avarias');
      case 22:
        return _buildPlaceholderPage('Configurações de Avarias');
      case 3:
        return _buildPlaceholderPage('Gerenciamento de Inventário');
      case 30:
        return _buildPlaceholderPage('Gerenciar Items do Inventário');
      case 31:
        return _buildPlaceholderPage('Controle de Estoque');
      case 32:
        return _buildPlaceholderPage('Movimentações de Inventário');
      default:
        return _buildPlaceholderPage('Página em desenvolvimento');
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: AppDesignSystem.neutral400,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            Text(
              title,
              style: AppDesignSystem.h3.copyWith(
                color: AppDesignSystem.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              'Esta funcionalidade será implementada em breve.',
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            ElevatedButton.icon(
              onPressed: () => _onNavigate(0),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar aos Logs'),
              style: AppDesignSystem.primaryButton,
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Auditoria';
      case 1:
        return 'Gerenciamento de Emails';
      case 2:
        return 'Gerenciamento de Avarias';
      case 20:
        return 'Gerenciar Avarias';
      case 21:
        return 'Relatórios de Avarias';
      case 22:
        return 'Configurações de Avarias';
      case 3:
        return 'Gerenciamento de Inventário';
      case 30:
        return 'Gerenciar Items do Inventário';
      case 31:
        return 'Controle de Estoque';
      case 32:
        return 'Movimentações de Inventário';
      default:
        return 'Administração';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar ao Início',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        title: Text(
          _getPageTitle(),
          style: AppDesignSystem.h3.copyWith(color: AppDesignSystem.neutral900),
        ),
        foregroundColor: AppDesignSystem.neutral900,
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        actions: [
          // Indicador de submenu para subpáginas
          if (_selectedIndex >= 20)
            Container(
              margin: const EdgeInsets.only(right: AppDesignSystem.spacing16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing8,
                    vertical: AppDesignSystem.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusS,
                    ),
                  ),
                  child: Text(
                    'Submenu',
                    style: AppDesignSystem.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Barra lateral
          AdminSidebar(onNavigate: _onNavigate, selectedIndex: _selectedIndex),

          // Conteúdo principal
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDesignSystem.animationStandard,
              child: _getSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }
}
