import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show showDialog;
import 'package:file_picker/file_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../design_system.dart';
import '../../visuals/file_drop_zone.dart';
import '../shared/responsive.dart';
import '../date_picker_helper.dart';
import 'dialog_file_utils.dart';

mixin DialogUtilities {
  bool get isLoading;
  bool get isUploading;
  bool get isProcessing;
  String get statusMessage;
  PlatformFile? get selectedFile;
  String? get errorMessage;

  void setLoading(bool loading, [String message = '']);
  void setUploading(bool uploading, [String message = '']);
  void setProcessing(bool processing, [String message = '']);
  void setError(String? error);
  void setSelectedFile(PlatformFile? file);

  static final MaskTextInputFormatter dateMaskFormatter =
      MaskTextInputFormatter(
        mask: '##-##-####',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy,
      );

  Future<void> pickFileWithValidation({
    required List<String> allowedExtensions,
    required int maxSizeMB,
    Function(PlatformFile)? onFileSelected,
  }) async {
    try {
      final file = await DialogFileUtils.pickFile(
        allowedExtensions: allowedExtensions,
        maxSizeMB: maxSizeMB,
      );

      if (file != null) {
        setSelectedFile(file);
        setError(null);
        onFileSelected?.call(file);
      }
    } catch (e) {
      setError('Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> selectDateForController(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? initialDate;

    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  String? validateDateInput(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length != 10) {
      return 'Use o formato DD-MM-AAAA';
    }

    final dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Use o formato DD-MM-AAAA';
    }

    try {
      final parts = value.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
        throw Exception('Invalid date');
      }

      final date = DateTime(year, month, day);

      if (date.day != day || date.month != month || date.year != year) {
        throw Exception('Invalid date');
      }

      return null;
    } catch (e) {
      return 'Data inválida';
    }
  }

  Widget buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return AppFormField(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [dateMaskFormatter],
        decoration: AppDesignSystem.inputDecoration(
          hint: 'DD-MM-AAAA',
          prefixIcon: Icon(icon, color: AppDesignSystem.neutral500),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: AppDesignSystem.neutral500,
            ),
            onPressed: () => selectDateForController(context, controller),
          ),
        ),
        validator: validator ?? validateDateInput,
        style: AppDesignSystem.bodyMedium,
      ),
    );
  }

  Widget buildFileUploadSection({
    required String label,
    required List<String> allowedExtensions,
    required int maxSizeMB,
    String? existingFileUrl,
    String? existingFileName,
    Widget? additionalContent,
    Function(PlatformFile)? onFileSelected,
  }) {
    return AppFormField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (existingFileUrl != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              decoration: BoxDecoration(
                color: AppDesignSystem.neutral50,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(color: AppDesignSystem.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusS,
                      ),
                    ),
                    child: Icon(
                      _getFileIconFromName(existingFileName ?? ''),
                      color: AppDesignSystem.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arquivo atual',
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral600,
                          ),
                        ),
                        Text(
                          existingFileName ?? 'arquivo.pdf',
                          style: AppDesignSystem.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openFileUrl(existingFileUrl),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: AppDesignSystem.neutral600,
                      size: 18,
                    ),
                    tooltip: 'Abrir arquivo',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
          ],

          FileDropZone(
            onFileSelected: (file) {
              setSelectedFile(file);
              setError(null);
              onFileSelected?.call(file);
            },
            allowedExtensions: allowedExtensions,
          ),

          if (selectedFile != null) ...[
            const SizedBox(height: AppDesignSystem.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              decoration: BoxDecoration(
                color: AppDesignSystem.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(
                  color: AppDesignSystem.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusS,
                      ),
                    ),
                    child: Icon(
                      _getFileIconFromName(selectedFile!.name),
                      color: AppDesignSystem.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFile!.name,
                          style: AppDesignSystem.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DialogFileUtils.formatFileSize(selectedFile!.size),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setSelectedFile(null);
                      setError(null);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppDesignSystem.neutral600,
                      size: 18,
                    ),
                    tooltip: 'Remover arquivo',
                  ),
                ],
              ),
            ),
          ],

          if (additionalContent != null) ...[
            const SizedBox(height: AppDesignSystem.spacing12),
            additionalContent,
          ],

          if (errorMessage != null) ...[
            const SizedBox(height: AppDesignSystem.spacing8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              decoration: BoxDecoration(
                color: AppDesignSystem.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(
                  color: AppDesignSystem.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppDesignSystem.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      decoration: const BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignSystem.radiusL),
        ),
        border: Border(bottom: BorderSide(color: AppDesignSystem.neutral200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing8),
            decoration: BoxDecoration(
              color: AppDesignSystem.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(icon, color: AppDesignSystem.primary, size: 20),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppDesignSystem.h3),
                Text(
                  subtitle,
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons({
    required BuildContext context,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String saveText,
    bool showLoadingIndicator = false,
  }) {
    final bool hasAnyOperation = isLoading || isUploading || isProcessing;
    final bool canSave = !hasAnyOperation;

    // Extrai expressões ternárias aninhadas para clareza
    final String displayMessage = statusMessage.isNotEmpty
        ? statusMessage
        : 'Processando...';

    final VoidCallback? smallScreenSaveButtonOnPressed = canSave
        ? onSave
        : null;
    final VoidCallback? smallScreenCancelButtonOnPressed = canSave
        ? onCancel
        : null;

    final Widget smallScreenSaveButtonChild = hasAnyOperation
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppDesignSystem.surface,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(displayMessage),
            ],
          )
        : Text(saveText);

    final VoidCallback? largeScreenCancelButtonOnPressed = canSave
        ? onCancel
        : null;
    final VoidCallback? largeScreenSaveButtonOnPressed = canSave
        ? onSave
        : null;

    final Widget largeScreenSaveButtonChild = hasAnyOperation
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppDesignSystem.surface,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(displayMessage),
            ],
          )
        : Text(saveText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      decoration: const BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDesignSystem.radiusL),
        ),
        border: Border(top: BorderSide(color: AppDesignSystem.neutral200)),
      ),
      child: Responsive.isSmallScreen(context)
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: smallScreenSaveButtonOnPressed,
                    style: AppDesignSystem.primaryButton,
                    child: smallScreenSaveButtonChild,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: smallScreenCancelButtonOnPressed,
                    style: AppDesignSystem.secondaryButton,
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: largeScreenCancelButtonOnPressed,
                  style: AppDesignSystem.secondaryButton,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                ElevatedButton(
                  onPressed: largeScreenSaveButtonOnPressed,
                  style: AppDesignSystem.primaryButton,
                  child: largeScreenSaveButtonChild,
                ),
              ],
            ),
    );
  }

  IconData _getFileIconFromName(String fileName) {
    final iconName = DialogFileUtils.getFileIcon(fileName);
    switch (iconName) {
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'description':
        return Icons.description;
      case 'table_chart':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openFileUrl(String url) async {
    try {
      await DialogFileUtils.openFile(url);
    } catch (e) {
      setError('Erro ao abrir arquivo: $e');
    }
  }

  static Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget child,
    bool Function()? shouldAllowDismiss,
  }) {
    return material.showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          _DialogWrapper(shouldAllowDismiss: shouldAllowDismiss, child: child),
    );
  }

  Widget buildDialog({required Widget child, VoidCallback? onWillPop}) {
    return PopScope(
      canPop: !(isLoading || isUploading || isProcessing),
      child: child,
    );
  }
}

class _DialogWrapper extends StatelessWidget {
  final Widget child;
  final bool Function()? shouldAllowDismiss;

  const _DialogWrapper({required this.child, this.shouldAllowDismiss});

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: shouldAllowDismiss?.call() ?? true, child: child);
  }
}
