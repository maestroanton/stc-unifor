import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../services/user_role.dart';
import '../core/visuals/dialogue.dart'; // Usando o sistema de diálogo

// Atualizado para usar UserRoleService
Future<bool> isAdmin([String? email]) async {
  if (email != null) {
    // Verifica e-mail específico (funcionalidade admin)
    final userRoleService = UserRoleService();
    final role = await userRoleService.getUserRoleByEmail(email);
    return role?.isAdmin == true && role?.active == true;
  }

  // Verifica o usuário atual
  final userRoleService = UserRoleService();
  return await userRoleService.isCurrentUserAdmin();
}

// Versão síncrona legada para compatibilidade retroativa (deprecada)
@Deprecated('Use async isAdmin() instead')
bool isAdminSync(String? email) {
  // Retorno para verificação legada hardcoded para compatibilidade imediata
  return email == 'ce@gistc.com' || email == 'sp@gistc.com';
}

Future<String?> promptForUserPassword(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email ?? '';
  final controller = TextEditingController();
  String? password;

  await DialogUtils.showConfirmationDialog(
    context: context,
    title: 'Confirme sua senha',
    customContent: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conta: $email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppDesignSystem.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    ),
    confirmText: 'Confirmar',
    confirmColor: AppDesignSystem.primary,
    onConfirm: () {
      password = controller.text;
    },
  );

  return password;
}

Future<bool> reauthenticateUserWithPassword(String password) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return false;
  final cred = EmailAuthProvider.credential(
    email: user.email!,
    password: password,
  );
  try {
    await user.reauthenticateWithCredential(cred);
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool?> confirmPermanentDeleteDialog(
  BuildContext context,
  String itemLabel,
) async {
  // Usa o sistema DialogUtils da pasta visuals
  bool? result;
  await DialogUtils.showConfirmationDialog(
    context: context,
    title: 'Confirmar exclusão',
    content: 'Excluir permanentemente $itemLabel?',
    confirmText: 'Confirmar',
    confirmColor: Colors.red.shade600,
    onConfirm: () {
      result = true;
    },
  );
  return result;
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
  Color? confirmColor,
}) async {
  // Usa o sistema DialogUtils da pasta visuals
  bool result = false;
  await DialogUtils.showConfirmationDialog(
    context: context,
    title: title,
    content: content,
    confirmText: confirmLabel,
    confirmColor: confirmColor ?? Colors.blue.shade600,
    onConfirm: () {
      result = true;
    },
  );
  return result;
}
