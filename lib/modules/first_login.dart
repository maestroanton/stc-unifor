import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log.dart';
import '../../services/first_login.dart';
import '../core/design_system.dart';
import '../core/utilities/shared/responsive.dart';
import '../core/visuals/snackbar.dart';

class FirstLoginPasswordChangeScreen extends StatefulWidget {
  const FirstLoginPasswordChangeScreen({super.key});

  @override
  State<FirstLoginPasswordChangeScreen> createState() =>
      _FirstLoginPasswordChangeScreenState();
}

class _FirstLoginPasswordChangeScreenState
    extends State<FirstLoginPasswordChangeScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuditLogService _auditService = AuditLogService();
  final FirstLoginService _firstLoginService = FirstLoginService();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validação de senha
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Digite uma nova senha';
    }

    final password = value.trim();

    if (password.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }

    if (password == _currentPasswordController.text.trim()) {
      return 'A nova senha deve ser diferente da atual';
    }

    // Verifica pelo menos uma letra maiúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'A senha deve conter pelo menos uma letra maiúscula';
    }

    // Verifica pelo menos uma letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'A senha deve conter pelo menos uma letra minúscula';
    }

    // Verifica pelo menos um número
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'A senha deve conter pelo menos um número';
    }

    return null;
  }

  // Avalia força da senha
  PasswordStrength _getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (password.length >= 16) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 5) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não autenticado');
      }

      // Reautentica usuário com a senha atual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Atualiza senha
      await user.updatePassword(_newPasswordController.text.trim());

      // Marca primeiro login como concluído
      await _markFirstLoginComplete();

      // Registra alteração de senha
      await _auditService.logAction(
        action: LogAction.update,
        module: LogModule.user,
        description: 'Senha alterada no primeiro login',
        metadata: {'isFirstLogin': true, 'email': user.email},
      );

      if (!mounted) return;

      // Exibe mensagem de sucesso
      SnackBarUtils.showSuccess(context, 'Senha alterada com sucesso!');

      // Navega para a tela inicial
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Senha atual incorreta.';
          break;
        case 'weak-password':
          message = 'A nova senha é muito fraca.';
          break;
        case 'requires-recent-login':
          message = 'Por favor, faça login novamente.';
          break;
        default:
          message = 'Erro ao alterar senha: ${e.message}';
      }

      if (mounted) {
        SnackBarUtils.showAuth(context, message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro inesperado: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markFirstLoginComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      // Marca primeiro login como concluído via serviço
      await _firstLoginService.markFirstLoginComplete(user!.email!);
    } catch (e) {
      // Erro ao marcar primeiro login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: Container(
              width: Responsive.value(
                context,
                mobile: MediaQuery.of(context).size.width * 0.9,
                tablet: 500,
                desktop: 500,
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho
                    const Column(
                      children: [
                        Icon(
                          Icons.sync_lock,
                          size: 48,
                          color: AppDesignSystem.neutral700,
                        ),
                        SizedBox(height: AppDesignSystem.spacing16),
                        Text('Altere sua senha', style: AppDesignSystem.h1),
                        SizedBox(height: AppDesignSystem.spacing8),
                        Text(
                          'Por segurança, altere sua senha padrão',
                          style: AppDesignSystem.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDesignSystem.spacing32),

                    // Senha atual
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: 'Senha Atual',
                      hintText: 'Digite sua senha atual',
                      obscureText: _obscureCurrentPassword,
                      onToggleVisibility: () => setState(
                        () =>
                            _obscureCurrentPassword = !_obscureCurrentPassword,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite sua senha atual';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDesignSystem.spacing16),

                    // Nova senha
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'Nova Senha',
                      hintText: 'Digite sua nova senha',
                      obscureText: _obscureNewPassword,
                      onToggleVisibility: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                      validator: _validatePassword,
                      showStrength: true,
                    ),

                    const SizedBox(height: AppDesignSystem.spacing16),

                    // Confirmar nova senha
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Nova Senha',
                      hintText: 'Digite novamente a nova senha',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Confirme sua nova senha';
                        }
                        if (value != _newPasswordController.text.trim()) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDesignSystem.spacing24),

                    // Requisitos da senha
                    Container(
                      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.infoLight,
                        borderRadius: BorderRadius.circular(
                          AppDesignSystem.radiusM,
                        ),
                        border: Border.all(
                          color: AppDesignSystem.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requisitos da senha:',
                            style: AppDesignSystem.labelLarge.copyWith(
                              color: AppDesignSystem.neutral900,
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spacing8),
                          _buildRequirement('Mínimo de 8 caracteres'),
                          _buildRequirement(
                            'Pelo menos 1 letra maiúscula (A-Z)',
                          ),
                          _buildRequirement(
                            'Pelo menos 1 letra minúscula (a-z)',
                          ),
                          _buildRequirement('Pelo menos 1 número (0-9)'),
                          _buildRequirement('Diferente da senha atual'),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDesignSystem.spacing32),

                    // Botão alterar senha
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: AppDesignSystem.primaryButton.copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.disabled)
                                ? AppDesignSystem.neutral400
                                : AppDesignSystem.primary,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppDesignSystem.surface,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ALTERAR SENHA',
                                style: TextStyle(
                                  letterSpacing: 1.5,
                                  color: AppDesignSystem.surface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppDesignSystem.info),
          const SizedBox(width: AppDesignSystem.spacing8),
          Expanded(
            child: Text(
              text,
              style: AppDesignSystem.bodySmall.copyWith(
                color: AppDesignSystem.neutral900,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    bool showStrength = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppDesignSystem.labelMedium),
        const SizedBox(height: AppDesignSystem.spacing6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: AppDesignSystem.bodyMedium,
          onChanged: showStrength ? (value) => setState(() {}) : null,
          decoration:
              AppDesignSystem.inputDecoration(
                hint: hintText,
                hasError: false,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: AppDesignSystem.neutral500,
                  ),
                  onPressed: onToggleVisibility,
                ),
              ),
        ),
        if (showStrength && controller.text.isNotEmpty) ...[
          const SizedBox(height: AppDesignSystem.spacing8),
          _buildPasswordStrengthIndicator(controller.text),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    final strength = _getPasswordStrength(password);
    Color color;
    String text;
    double progress;

    switch (strength) {
      case PasswordStrength.weak:
        color = AppDesignSystem.error;
        text = 'Fraca';
        progress = 0.25;
        break;
      case PasswordStrength.medium:
        color = AppDesignSystem.warning;
        text = 'Média';
        progress = 0.5;
        break;
      case PasswordStrength.strong:
        color = AppDesignSystem.info;
        text = 'Forte';
        progress = 0.75;
        break;
      case PasswordStrength.veryStrong:
        color = AppDesignSystem.success;
        text = 'Muito Forte';
        progress = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppDesignSystem.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing8),
            Text(
              text,
              style: AppDesignSystem.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum PasswordStrength { weak, medium, strong, veryStrong }
