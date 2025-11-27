import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../design_system.dart';
import '../../visuals/file_drop_zone.dart';
import '../shared/responsive.dart';
import '../date_picker_helper.dart';
import 'dialog_file_utils.dart';

/// Configuração base para diálogos de edição
class DialogConfig {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final bool isEdit;
  final double? customWidth;
  final double? customHeight;
  final List<String> allowedFileExtensions;
  final int maxFileSizeMB;
  final bool barrierDismissible;

  const DialogConfig({
    required this.title,
    required this.subtitle,
    this.headerIcon = Icons.edit,
    this.isEdit = false,
    this.customWidth,
    this.customHeight,
    this.allowedFileExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFileSizeMB = 10,
    this.barrierDismissible = false,
  });
}

/// Estado base para operações em diálogo
class DialogState {
  final bool isLoading;
  final bool isUploading;
  final bool isProcessing;
  final String statusMessage;
  final PlatformFile? selectedFile;
  final String? errorMessage;

  const DialogState({
    this.isLoading = false,
    this.isUploading = false,
    this.isProcessing = false,
    this.statusMessage = '',
    this.selectedFile,
    this.errorMessage,
  });

  DialogState copyWith({
    bool? isLoading,
    bool? isUploading,
    bool? isProcessing,
    String? statusMessage,
    PlatformFile? selectedFile,
    String? errorMessage,
    bool clearFile = false,
    bool clearError = false,
  }) {
    return DialogState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasAnyOperation => isLoading || isUploading || isProcessing;
}

/// Classe base abstrata para diálogos de edição com funcionalidades comuns
abstract class BaseEditDialog<T> extends StatefulWidget {
  final DialogConfig config;
  final T? item;
  final Function(T) onSave;

  const BaseEditDialog({
    super.key,
    required this.config,
    this.item,
    required this.onSave,
  });
}

/// Classe de estado abstrata com funcionalidades comuns para diálogos
abstract class BaseEditDialogState<T, D extends BaseEditDialog<T>>
    extends State<D> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late DialogState dialogState;

  // Formatador de máscara para datas
  static final MaskTextInputFormatter dateMaskFormatter =
      MaskTextInputFormatter(
        mask: '##-##-####',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy,
      );

  @override
  void initState() {
    super.initState();
    dialogState = const DialogState();
    initializeForm();
  }

  /// Inicializa campos do formulário — implementar nas subclasses
  void initializeForm();

  /// Constrói o conteúdo do formulário — implementar nas subclasses
  Widget buildFormContent();

  /// Valida e salva o formulário — implementar nas subclasses
  Future<void> saveForm();

  /// Atualiza o estado do diálogo
  void updateDialogState(DialogState newState) {
    if (mounted) {
      setState(() {
        dialogState = newState;
      });
    }
  }

  /// Exibe estado de carregamento
  void showLoading(String message) {
    updateDialogState(
      dialogState.copyWith(
        isLoading: true,
        statusMessage: message,
        clearError: true,
      ),
    );
  }

  /// Exibe estado de upload
  void showUploading(String message) {
    updateDialogState(
      dialogState.copyWith(
        isUploading: true,
        statusMessage: message,
        clearError: true,
      ),
    );
  }

  /// Exibe estado de processamento
  void showProcessing(String message) {
    updateDialogState(
      dialogState.copyWith(
        isProcessing: true,
        statusMessage: message,
        clearError: true,
      ),
    );
  }

  /// Limpa todos os estados
  void clearStates() {
    updateDialogState(
      dialogState.copyWith(
        isLoading: false,
        isUploading: false,
        isProcessing: false,
        statusMessage: '',
        clearError: true,
      ),
    );
  }

  /// Exibe erro
  void showError(String error) {
    updateDialogState(
      dialogState.copyWith(
        isLoading: false,
        isUploading: false,
        isProcessing: false,
        statusMessage: '',
        errorMessage: error,
      ),
    );
  }

  /// Seleciona arquivo com validação
  Future<void> pickFile() async {
    try {
      final file = await DialogFileUtils.pickFile(
        allowedExtensions: widget.config.allowedFileExtensions,
        maxSizeMB: widget.config.maxFileSizeMB,
      );

      if (file != null) {
        updateDialogState(
          dialogState.copyWith(selectedFile: file, clearError: true),
        );

        // Chama o hook da subclasse ao selecionar arquivo
        onFileSelected(file);
      }
    } catch (e) {
      showError('Erro ao selecionar arquivo: $e');
    }
  }

  /// Hook quando arquivo é selecionado - pode ser sobrescrito por subclasses
  void onFileSelected(PlatformFile file) {}

  /// Remove arquivo selecionado
  void removeFile() {
    updateDialogState(dialogState.copyWith(clearFile: true, clearError: true));
  }

  /// Auxiliar para seleção de data
  Future<void> selectDate(TextEditingController controller) async {
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

  /// Validação de data
  String? validateDate(String? value) {
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

  /// Constrói campo de data
  Widget buildDateField({
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
            onPressed: () => selectDate(controller),
          ),
        ),
        validator: validator ?? validateDate,
        style: AppDesignSystem.bodyMedium,
      ),
    );
  }

  /// Constrói seção de upload de arquivo
  Widget buildFileUploadSection({
    required String label,
    String? existingFileUrl,
    String? existingFileName,
    Widget? additionalContent,
  }) {
    return AppFormField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mostra arquivo atual no modo edição
          if (widget.config.isEdit && existingFileUrl != null) ...[
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
                      _getFileIcon(existingFileName ?? ''),
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
                    onPressed: () => _openFile(existingFileUrl),
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

          // Área de upload de arquivo
          FileDropZone(
            onFileSelected: (file) => updateDialogState(
              dialogState.copyWith(selectedFile: file, clearError: true),
            ),
            allowedExtensions: widget.config.allowedFileExtensions,
          ),

          // Exibe arquivo selecionado
          if (dialogState.selectedFile != null) ...[
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
                      _getFileIcon(dialogState.selectedFile!.name),
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
                          dialogState.selectedFile!.name,
                          style: AppDesignSystem.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatFileSize(dialogState.selectedFile!.size),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: removeFile,
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

          // Conteúdo adicional (ex.: botão OCR)
          if (additionalContent != null) ...[
            const SizedBox(height: AppDesignSystem.spacing12),
            additionalContent,
          ],

          // Mensagem de erro
          if (dialogState.errorMessage != null) ...[
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
                      dialogState.errorMessage!,
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

  /// Trata operação de salvar
  Future<void> handleSave() async {
    if (!formKey.currentState!.validate()) return;

    try {
      await saveForm();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showError('Erro ao salvar: $e');
    }
  }

  /// Constrói botões de ação
  Widget buildActionButtons() {
    final bool canSave = !dialogState.hasAnyOperation;
    final String saveText = widget.config.isEdit
        ? 'Salvar Alterações'
        : 'Adicionar ${widget.config.title}';

    // Extrai operações ternárias para declarações independentes
    final VoidCallback? saveCallback = canSave ? handleSave : null;
    final VoidCallback? cancelCallback = canSave
        ? () => Navigator.pop(context)
        : null;
    final String statusText = dialogState.statusMessage.isNotEmpty
        ? dialogState.statusMessage
        : 'Processando...';

    final Widget mobileButtonChild = dialogState.hasAnyOperation
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
              Text(statusText),
            ],
          )
        : Text(saveText);

    final Widget desktopButtonChild = dialogState.hasAnyOperation
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
              Text(statusText),
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
                    onPressed: saveCallback,
                    style: AppDesignSystem.primaryButton,
                    child: mobileButtonChild,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: cancelCallback,
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
                  onPressed: cancelCallback,
                  style: AppDesignSystem.secondaryButton,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                ElevatedButton(
                  onPressed: saveCallback,
                  style: AppDesignSystem.primaryButton,
                  child: desktopButtonChild,
                ),
              ],
            ),
    );
  }

  /// Constrói cabeçalho do diálogo
  Widget buildHeader() {
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
            child: Icon(
              widget.config.headerIcon,
              color: AppDesignSystem.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.config.title, style: AppDesignSystem.h3),
                Text(
                  widget.config.subtitle,
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

  /// Obtém ícone por extensão
  IconData _getFileIcon(String fileName) {
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

  /// Formata tamanho do arquivo
  String _formatFileSize(int bytes) {
    return DialogFileUtils.formatFileSize(bytes);
  }

  /// Abre a URL do arquivo
  void _openFile(String url) async {
    try {
      await DialogFileUtils.openFile(url);
    } catch (e) {
      showError('Erro ao abrir arquivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      ),
      child: Container(
        width:
            widget.config.customWidth ??
            Responsive.valueDetailed(
              context,
              mobile: MediaQuery.of(context).size.width * 0.95,
              tablet: 520.0,
              desktop: 520.0,
            ),
        constraints: BoxConstraints(
          maxHeight:
              widget.config.customHeight ??
              Responsive.valueDetailed(
                context,
                mobile: MediaQuery.of(context).size.height * 0.9,
                tablet: 700.0,
                desktop: 700.0,
              ),
        ),
        decoration: AppDesignSystem.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignSystem.spacing24),
                child: Form(key: formKey, child: buildFormContent()),
              ),
            ),
            buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
