// lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system.dart';

class DialogUtils {
  /// Exibe diálogo de confirmação com estilo personalizado
  static Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? content,
    Widget? customContent,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              Navigator.pop(context);
              onConfirm();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: confirmColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getDialogIcon(confirmText),
                        color: confirmColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confirme sua ação',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Conteúdo
                if (content != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            content,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Conteúdo personalizado (para diálogo de comentário)
                if (customContent != null) customContent,

                const SizedBox(height: 24),

                // Ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botão Cancelar
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Botão Confirmar
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Exibe diálogo de entrada de comentário
  static Future<void> showCommentDialog({
    required BuildContext context,
    required Function(String) onCommentAdded,
  }) {
    final commentController = TextEditingController();

    return showConfirmationDialog(
      context: context,
      title: 'Adicionar Comentário',
      content: null,
      confirmText: 'Adicionar',
      confirmColor: const Color(0xFF4F46E5),
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
            Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Digite seu comentário abaixo:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Digite seu comentário...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.grey.shade500,
                ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF4F46E5),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      onConfirm: () {
        if (commentController.text.trim().isNotEmpty) {
          onCommentAdded(commentController.text.trim());
        }
      },
    );
  }

  /// Exibe diálogo de confirmação de ação (aprovar, rejeitar, solicitar info)
  static Future<void> showActionDialog({
    required BuildContext context,
    required String action,
    required VoidCallback onConfirm,
  }) {
    String title = '';
    String content = '';
    String confirmText = '';
    Color confirmColor = const Color(0xFF374151);

    switch (action) {
      case 'aprovar':
        title = 'Aprovar Requisição';
        content = 'Tem certeza que deseja aprovar esta requisição?';
        confirmText = 'Aprovar';
        confirmColor = const Color(0xFF22C55E);
        break;
      case 'rejeitar':
        title = 'Rejeitar Requisição';
        content = 'Tem certeza que deseja rejeitar esta requisição?';
        confirmText = 'Rejeitar';
        confirmColor = const Color(0xFFEF4444);
        break;
      case 'solicitar_info':
        title = 'Solicitar Informações';
        content = 'Solicitar informações adicionais ao solicitante?';
        confirmText = 'Solicitar';
        confirmColor = const Color(0xFF3B82F6);
        break;
    }

    return showConfirmationDialog(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText,
      confirmColor: confirmColor,
      onConfirm: onConfirm,
    );
  }

  /// Exibe diálogo de aviso de inatividade com opções continuar/logout
  static Future<void> showInactivityWarningDialog({
    required BuildContext context,
    required int remainingMinutes,
    required VoidCallback onContinue,
    required VoidCallback onLogout,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              Navigator.pop(context);
              onContinue();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
              onLogout();
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sessão Expirando',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF374151),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ação necessária para continuar',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Conteúdo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sua sessão expirará em $remainingMinutes minutos devido à inatividade. Clique em "Continuar" para manter a sessão ativa.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botão Logout
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Sair Agora',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Botão Continuar
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onContinue();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Continuar Sessão',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Exibe diálogo de seleção de contato com opções
  static Future<void> showContactDialog({
    required BuildContext context,
    required List<String> options,
    required Future<void> Function(String) onOptionSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.contact_phone_outlined,
                      color: Color(0xFF22C55E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contate-nos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nossos contatos comerciais:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Opções
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await onOptionSelected(option);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.grey.shade50,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF22C55E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão Cancelar
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe diálogo de informações genérico
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget Function(void Function(void Function()) setState)
    contentBuilder,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onAddPressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onAddPressed != null)
                      IconButton(
                        icon: const Icon(
                          Icons.add_box_outlined,
                          color: AppDesignSystem.neutral700,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppDesignSystem.neutral200,
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: onAddPressed,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Conteúdo com scroll
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(child: contentBuilder(setState)),
                ),
                const SizedBox(height: 24),
                // Ações
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showBulkVolumeDialog({
    required BuildContext context,
    required String measureUnit,
    required Function(String length, String width, String height, int quantity)
    onConfirm,
  }) {
    final lengthController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    final quantityController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (lengthController.text.isNotEmpty &&
                  widthController.text.isNotEmpty &&
                  heightController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity > 0) {
                  Navigator.pop(context);
                  onConfirm(
                    lengthController.text,
                    widthController.text,
                    heightController.text,
                    quantity,
                  );
                }
              }
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_box_outlined,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adicionar Volumes',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Preencha as dimensões',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Conteúdo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dimensões do volume:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Comprimento
                      TextField(
                        controller: lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Comprimento ($measureUnit)',
                          hintText: 'Digite o comprimento',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
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
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Largura
                      TextField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Largura ($measureUnit)',
                          hintText: 'Digite a largura',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
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
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Altura
                      TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Altura ($measureUnit)',
                          hintText: 'Digite a altura',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
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
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quantidade
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Volumes',
                          hintText: 'Quantidade de volumes',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
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
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botão Cancelar
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botão Confirmar
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          if (lengthController.text.isNotEmpty &&
                              widthController.text.isNotEmpty &&
                              heightController.text.isNotEmpty &&
                              quantityController.text.isNotEmpty) {
                            final quantity =
                                int.tryParse(quantityController.text) ?? 0;
                            if (quantity > 0) {
                              Navigator.pop(context);
                              onConfirm(
                                lengthController.text,
                                widthController.text,
                                heightController.text,
                                quantity,
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Adicionar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Obtém ícone apropriado para ações de diálogo
  static IconData _getDialogIcon(String actionText) {
    switch (actionText.toLowerCase()) {
      case 'aprovar':
        return Icons.check_circle_outline;
      case 'rejeitar':
        return Icons.cancel_outlined;
      case 'solicitar':
        return Icons.help_outline;
      case 'adicionar':
        return Icons.add_comment_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
