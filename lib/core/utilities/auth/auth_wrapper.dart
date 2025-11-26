import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:logger/logger.dart';

import '../../../modules/first_login.dart';
import '../../../modules/login_page.dart';
import '../../../services/first_login.dart';
import '../../../services/user_role.dart';

enum AuthRequirement {
  auth, // Autenticação básica — requer apenas login
  operator, // Requer permissões de operador (Avaria, Inventário, Licença)
  admin, // Requer permissões de administrador (exceto módulos de desenvolvimento)
  testAccess, // Requer acesso de teste para módulos de desenvolvimento
  requestAccess, // Requer acesso para módulo de solicitações/comunicação
  firstLogin, // Verifica primeiro login (aplica-se a telas não de login)
}

class AuthWrapper extends StatefulWidget {
  final Widget child;
  final Set<AuthRequirement> requirements;
  final Widget? unauthorizedWidget;
  final Widget? loadingWidget;

  const AuthWrapper({
    super.key,
    required this.child,
    this.requirements = const {AuthRequirement.auth},
    this.unauthorizedWidget,
    this.loadingWidget,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirstLoginService _firstLoginService = FirstLoginService();
  final UserRoleService _userRoleService = UserRoleService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isFirstLogin = false;
  bool _isAdmin = false;
  bool _isOperator = false;
  bool _hasTestAccess = false;
  bool _hasRequestAccess = false;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAllRequirements();

    // Escuta alterações no estado de autenticação
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkAllRequirements();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAllRequirements() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    _isAuthenticated = user != null;

    // Se não autenticado, não verifica outros requisitos
    if (!_isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    // Verifica primeiro login se for requerido
    if (widget.requirements.contains(AuthRequirement.firstLogin)) {
      try {
        _isFirstLogin = await _firstLoginService.isFirstLogin();
      } catch (e) {
        _logger.e('Error checking first login: $e');
        _isFirstLogin = false;
      }
    }

    // Obtém papel e permissões do usuário se houver requisitos por função
    if (widget.requirements.contains(AuthRequirement.admin) ||
        widget.requirements.contains(AuthRequirement.operator) ||
        widget.requirements.contains(AuthRequirement.testAccess) ||
        widget.requirements.contains(AuthRequirement.requestAccess)) {
      try {
        final userRole = await _userRoleService.getCurrentUserRole();

        // Ajusta permissões com base no papel do usuário
        _isAdmin = userRole?.isAdmin == true;
        _isOperator =
            userRole?.isOperator == true; // Campo a ser adicionado, se necessário
        _hasTestAccess = userRole?.testAccess == true;
        _hasRequestAccess = userRole?.requestAccess == true;

        _logger.i(
          'User permissions - Admin: $_isAdmin, Operator: $_isOperator, TestAccess: $_hasTestAccess, RequestAccess: $_hasRequestAccess',
        );
      } catch (e) {
        _logger.e('Error checking user permissions: $e');
        _isAdmin = false;
        _isOperator = false;
        _hasTestAccess = false;
        _hasRequestAccess = false;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUnauthorizedWidget() {
    // Em vez de mostrar tela 'não autorizado', redireciona para a home
    // A home mostrará botões conforme as permissões
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4F46E5)),
            SizedBox(height: 16),
            Text(
              'Redirecionando...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Exibe indicador de carregamento
    if (_isLoading) {
      return widget.loadingWidget ??
          const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 16),
                  Text(
                    'Verificando permissões...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          );
    }

    // Trata estado não autenticado
    if (!_isAuthenticated &&
        widget.requirements.contains(AuthRequirement.auth)) {
      return widget.unauthorizedWidget ?? const LoginScreen();
    }

    // Trata requisito de primeiro login
    if (_isFirstLogin &&
        widget.requirements.contains(AuthRequirement.firstLogin)) {
      return const PopScope(
        canPop: false,
        child: FirstLoginPasswordChangeScreen(),
      );
    }

    // Trata requisito de admin — redireciona para a home
    if (!_isAdmin && widget.requirements.contains(AuthRequirement.admin)) {
      return _buildUnauthorizedWidget();
    }

    // Trata requisito de operador — redireciona para a home
    if (!_isOperator &&
        !_isAdmin &&
        widget.requirements.contains(AuthRequirement.operator)) {
      return _buildUnauthorizedWidget();
    }

    // Trata requisito de acesso de teste — redireciona para a home
    if (!_hasTestAccess &&
        widget.requirements.contains(AuthRequirement.testAccess)) {
      return _buildUnauthorizedWidget();
    }

    // Trata requisito de acesso a solicitações — redireciona para a home
    if (!_hasRequestAccess &&
        widget.requirements.contains(AuthRequirement.requestAccess)) {
      return _buildUnauthorizedWidget();
    }

    // Se todas as verificações passarem, exibe o widget filho
    return widget.child;
  }
}
