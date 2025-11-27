// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utilities/shared/responsive.dart';
import '../services/audit_log.dart';
import '../services/user_role.dart';
import '../services/first_login.dart';
import '../core/visuals/snackbar.dart';
import 'home_selection.dart';
import 'first_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuditLogService _auditService = AuditLogService();
  final FirstLoginService _firstLoginService = FirstLoginService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {

      // Autentica usuário
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Registra login bem-sucedido
      await _auditService.logLogin();

      if (!mounted) return;

      // Aguarda para garantir que o usuário do Firebase esteja pronto
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Verifica se é o primeiro acesso do usuário
      final isFirstLogin = await _firstLoginService.isFirstLogin();

      if (!mounted) return;

      // Exibe mensagem de sucesso
      SnackBarUtils.showSuccess(
        context,
        isFirstLogin
            ? 'Login realizado! Altere sua senha para continuar.'
            : 'Login realizado com sucesso!',
      );

      if (!mounted) return;

      // Aguarda exibição do snackbar
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (isFirstLogin) {
        // Redireciona para alteração de senha
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const FirstLoginPasswordChangeScreen(),
          ),
        );
      } else {
        // Fluxo de login normal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuário não encontrado.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta.';
          break;
        case 'invalid-email':
          message = 'Email inválido.';
          break;
        case 'user-disabled':
          message = 'Usuário desabilitado.';
          break;
        case 'too-many-requests':
          message = 'Muitas tentativas. Tente novamente mais tarde.';
          break;
        default:
          message = 'Erro de autenticação: ${e.message}';
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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.shouldStackFormFields(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E5EA4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: Container(
              padding: Responsive.valueDetailed(
                context,
                    mobile: const EdgeInsets.all(32),
                smallTablet: const EdgeInsets.all(32),
                tablet: const EdgeInsets.all(40),
                desktop: const EdgeInsets.all(40),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.borderRadius(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: Responsive.valueDetailed(
                  context,
                  mobile: MediaQuery.of(context).size.width * 0.9,
                  smallTablet: 500,
                  tablet: 600,
                  desktop: 650,
                ),
                maxHeight: Responsive.valueDetailed(
                  context,
                  mobile: double.infinity,
                  smallTablet: 500,
                  tablet: 600,
                  desktop: 500,
                ),
              ),
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _buildCompactLogoSection()),
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.largeSpacing(context),
          ),
          child: Divider(
            thickness: 1,
            color: const Color(0x1F000000),
            height: Responsive.spacing(context),
          ),
        ),
        Flexible(child: _buildLoginForm()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(child: _buildLogoSection()),
        VerticalDivider(
          width: Responsive.valueDetailed(
            context,
            mobile: 24,
            smallTablet: 32,
            tablet: 48,
            desktop: 48,
          ),
          thickness: 1,
          color: const Color(0x1F000000),
        ),
        Expanded(child: _buildLoginForm()),
      ],
    );
  }

  Widget _buildCompactLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GISTC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.valueDetailed(
              context,
                  mobile: 24.0,
              smallTablet: 20.0,
              tablet: 22.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E5EA4),
          ),
        ),
        SizedBox(height: Responsive.spacing(context)),
        Image.asset(
          'assets/logo.png',
          height: Responsive.valueDetailed(
            context,
                mobile: 80,
            smallTablet: 70,
            tablet: 80,
            desktop: 80,
          ),
          errorBuilder: (context, error, stackTrace) {
            final size = Responsive.valueDetailed(
              context,
              mobile: 80.0,
              smallTablet: 70.0,
              tablet: 80.0,
              desktop: 80.0,
            );
            return Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(
                  Responsive.borderRadius(context),
                ),
              ),
              child: Icon(Icons.business, size: size * 0.4),
            );
          },
        ),
        SizedBox(height: Responsive.largeSpacing(context)),
        Text(
          "STC\nMatriz\nGerenciador Interno",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.valueDetailed(
              context,
              mobile: 12.0,
              smallTablet: 13.0,
              tablet: 14.0,
              desktop: 14.0,
            ),
            color: const Color.fromARGB(255, 155, 155, 155),
            fontWeight: FontWeight.w100,
            height: 1.2,
          ),
        ),
        SizedBox(height: Responsive.smallSpacing(context)),
            // Texto da versão
        const Text(
          'v0.1',
          style: TextStyle(
            fontSize: 9.0,
            color: Color.fromARGB(255, 200, 200, 200),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'GISTC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.valueDetailed(
              context,
              mobile: 20.0,
              smallTablet: 22.0,
              tablet: 24.0,
              desktop: 24.0,
            ),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E5EA4),
          ),
        ),
        SizedBox(height: Responsive.spacing(context) * 0.5),
        Image.asset(
          'assets/logo.png',
          height: Responsive.valueDetailed(
            context,
            mobile: 80,
            smallTablet: 90,
            tablet: 100,
            desktop: 100,
          ),
          errorBuilder: (context, error, stackTrace) {
            final size = Responsive.valueDetailed(
              context,
              mobile: 80.0,
              smallTablet: 90.0,
              tablet: 100.0,
              desktop: 100.0,
            );
            return Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(
                  Responsive.borderRadius(context),
                ),
              ),
              child: Icon(
                Icons.business,
                size: Responsive.valueDetailed(
                  context,
                  mobile: 35.0,
                  smallTablet: 40.0,
                  tablet: 45.0,
                  desktop: 45.0,
                ),
              ),
            );
          },
        ),
        SizedBox(height: Responsive.smallSpacing(context) * 2),
        Text(
          "STC\nMatriz\nGerenciador Interno",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.valueDetailed(
              context,
              mobile: 12.0,
              smallTablet: 13.0,
              tablet: 14.0,
              desktop: 14.0,
            ),
            color: const Color.fromARGB(255, 155, 155, 155),
            fontWeight: FontWeight.w100,
            height: 1.2,
          ),
        ),
        SizedBox(height: Responsive.smallSpacing(context)),
        // Texto da versão
        const Text(
          'v0.1',
          style: TextStyle(
            fontSize: 9.0,
            color: Color.fromARGB(255, 200, 200, 200),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formulário central
        AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputField(
                hintText: 'E-mail',
                icon: Icons.person,
                controller: _emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
              ),
              SizedBox(
                height: (Responsive.isMobile(context)
                    ? Responsive.spacing(context)
                    : Responsive.spacing(context) * 0.5),
              ),
              _buildInputField(
                hintText: 'Senha',
                icon: Icons.lock,
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                obscureText: _obscurePassword,
                isPassword: true,
                onSubmitted: () => _login(context),
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
              ),
              SizedBox(
                height: (Responsive.isMobile(context)
                    ? Responsive.spacing(context)
                    : Responsive.spacing(context) * 0.5),
              ),
              SizedBox(
                width: double.infinity,
                height: Responsive.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87.withValues(
                      alpha: _isLoading ? 0.5 : 1,
                    ),
                    padding: Responsive.buttonPadding(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: Responsive.valueDetailed(
                            context,
                            mobile: 20.0,
                            smallTablet: 20.0,
                            tablet: 22.0,
                            desktop: 22.0,
                          ),
                          width: Responsive.valueDetailed(
                            context,
                            mobile: 20.0,
                            smallTablet: 20.0,
                            tablet: 22.0,
                            desktop: 22.0,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'ENTRAR',
                          style: TextStyle(
                            letterSpacing: 2,
                            color: Colors.white,
                            fontSize: Responsive.valueDetailed(
                              context,
                              mobile: 15.0,
                              smallTablet: 15.0,
                              tablet: 16.0,
                              desktop: 16.0,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        /* // Link comentado (não afeta centralização)
        SizedBox(height: Responsive.smallSpacing(context)),
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/visitante');
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              'Acesso às licenças',
              style: TextStyle(
                fontSize: Responsive.valueDetailed(
                  context,
                  mobile: 11.0,
                  smallTablet: 10.0,
                  tablet: 11.0,
                  desktop: 12.0,
                ),
                color: const Color.fromARGB(255, 155, 155, 155),
                fontWeight: FontWeight.w100,
                decoration: TextDecoration.underline,
                decorationColor: const Color.fromARGB(255, 155, 155, 155),
              ),
            ),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required TextInputAction textInputAction,
    VoidCallback? onSubmitted,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool? autocorrect,
    bool? enableSuggestions,
    Iterable<String>? autofillHints,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: (_) => onSubmitted?.call(),
      keyboardType: keyboardType,
      autocorrect: autocorrect ?? true,
      enableSuggestions: enableSuggestions ?? true,
      autofillHints: autofillHints,
      style: TextStyle(
        fontSize: Responsive.valueDetailed(
          context,
              mobile: 15.0,
          smallTablet: 13.0,
          tablet: 13.0,
          desktop: 14.0,
        ),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: Responsive.valueDetailed(
            context,
                mobile: 15.0,
            smallTablet: 13.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        prefixIcon: Icon(
          icon,
          size: Responsive.valueDetailed(
            context,
                mobile: 22.0,
            smallTablet: 19.0,
            tablet: 20.0,
            desktop: 20.0,
          ),
          color: Colors.grey.shade600,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  size: Responsive.valueDetailed(
                    context,
                        mobile: 22.0,
                    smallTablet: 19.0,
                    tablet: 20.0,
                    desktop: 20.0,
                  ),
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF1E5EA4), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: Responsive.valueDetailed(
          context,
          mobile: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          smallTablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// Auxiliar de logout acessível de qualquer parte do app
class LogoutHelper {
  static final AuditLogService _auditService = AuditLogService();

  static Future<void> logout(BuildContext context) async {
    try {
      // Registra logout antes de encerrar sessão
      await _auditService.logLogout();

      // Encerra sessão no Firebase
      await FirebaseAuth.instance.signOut();

      // Limpa cache de papéis do usuário
      UserRoleService().clearCache();

      // Navega para a tela de login
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Erro ao fazer logout: $e');
      }
    }
  }
}
