import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../helpers/database_helper_license.dart';
import '../../../core/utilities/shared/responsive.dart';
import '../../../core/utilities/date_picker_helper.dart';
import '../../../core/design_system.dart';
import '../../../core/visuals/snackbar.dart';
import '../../../models/license.dart';

class LicenseEditDialog extends StatefulWidget {
  final License license;

  const LicenseEditDialog({super.key, required this.license});

  @override
  State<LicenseEditDialog> createState() => _LicenseEditDialogState();
}

class _LicenseEditDialogState extends State<LicenseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dataInicioController = TextEditingController();
  final _dataVencimentoController = TextEditingController();
  final DatabaseHelperLicense _dbHelper = DatabaseHelperLicense();

  bool _isLoading = false;
  bool _isUploading = false;
  String _uploadStatus = '';
  PlatformFile? _selectedFile;

  // Estado do Drag & Drop
  DropzoneViewController? _controller;
  bool _isDragOver = false;
  bool _hasDropError = false;
  String _dropErrorMessage = '';

  bool get _isDropzoneSupported {

    return false;

    // Descomente abaixo para habilitar em plataformas específicas:
    // if (!kIsWeb) return false;
    //
    // try {
    //   // Habilitar apenas em plataformas web que suportam totalmente
    //   return kIsWeb;
    // } catch (e) {
    //   return false;
    // }
  }

  // Formatador de data
  static final MaskTextInputFormatter _dateMaskFormatter =
      MaskTextInputFormatter(
        mask: '##-##-####',
        filter: {"#": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy,
      );

  @override
  void initState() {
    super.initState();
    _dataInicioController.text = widget.license.dataInicio;
    _dataVencimentoController.text = widget.license.dataVencimento;
  }

  @override
  void dispose() {
    _dataInicioController.dispose();
    _dataVencimentoController.dispose();
    // Limpar estado do dropzone
    _controller = null;
    super.dispose();
  }

  /// Trata o drop de arquivo do drag & drop
  Future<void> _handleFileDrop(dynamic event) async {
    try {
      setState(() {
        _isDragOver = false;
        _hasDropError = false;
        _dropErrorMessage = '';
      });

      // Só trata drops na plataforma web
      if (!kIsWeb) return;

      if (_controller == null) return;

      final name = await _controller!.getFilename(event);
      final bytes = await _controller!.getFileData(event);

      // Validar extensão do arquivo
      final extension = name.split('.').last.toLowerCase();
      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

      if (!allowedExtensions.contains(extension)) {
        _showDropError(
          'Formato de arquivo não suportado. Use: ${allowedExtensions.map((e) => e.toUpperCase()).join(', ')}',
        );
        return;
      }

      // Validar tamanho do arquivo (limite 10MB)
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (bytes.length > maxSize) {
        _showDropError('Arquivo muito grande. Máximo 10MB permitido.');
        return;
      }

      // Criar objeto PlatformFile
      final file = PlatformFile(
        name: name,
        size: bytes.length,
        bytes: bytes,
        path: null, // Web não tem path
      );

      setState(() {
        _selectedFile = file;
      });

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Arquivo carregado: $name');
      }
    } catch (e) {
      _showDropError('Erro ao processar arquivo: $e');
    }
  }

  /// Exibir erro do drag & drop
  void _showDropError(String message) {
    setState(() {
      _hasDropError = true;
      _dropErrorMessage = message;
    });

    // Limpar erro após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hasDropError = false;
          _dropErrorMessage = '';
        });
      }
    });
  }

  /// Abrir PDF em nova aba/janela
  Future<void> _openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Não foi possível abrir o arquivo PDF',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao abrir arquivo: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ], // Permitir PDF e imagens
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validar tamanho do arquivo (limite 10MB)
        const maxSize = 10 * 1024 * 1024; // 10MB
        if (file.size > maxSize) {
          if (mounted) {
            SnackBarUtils.showError(
              context,
              'Arquivo muito grande. Máximo 10MB permitido.',
            );
          }
          return;
        }

        // Verificar se o arquivo tem dados
        if (file.bytes == null) {
          if (mounted) {
            SnackBarUtils.showError(
              context,
              'Erro ao ler o arquivo. Tente novamente.',
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      // Erro ao selecionar arquivo: $e
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao selecionar arquivo: $e');
      }
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    // Sempre iniciar com a data de hoje para melhor experiência
    final initialDate = DateTime.now();

    final picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Verificar se a entrada mascarada está completa
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

      // Validação básica de intervalo
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
        throw Exception('Invalid date');
      }

      // Tentar criar a data para validá-la
      final date = DateTime(year, month, day);

      // Verificar se a data criada corresponde à entrada
      if (date.day != day || date.month != month || date.year != year) {
        throw Exception('Invalid date');
      }

      return null;
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Salvando licença...';
    });

    try {
      // Primeiro atualizar os dados da licença
      final updatedLicense = widget.license.copyWith(
        dataInicio: _dataInicioController.text.trim(),
        dataVencimento: _dataVencimentoController.text.trim(),
      );

      await _dbHelper.updateLicense(updatedLicense);

      // Depois tratar upload do arquivo se houver
      if (_selectedFile != null && widget.license.id != null) {
        final extension = _selectedFile!.extension?.toLowerCase() ?? '';
        if (extension == 'pdf') {
          setState(() {
            _isUploading = true;
            _uploadStatus = 'Enviando arquivo...';
          });

          try {
            await _dbHelper.uploadLicenseFile(
              widget.license.id!,
              _selectedFile!.bytes!,
              _selectedFile!.name,
            );

            setState(() {
              _uploadStatus = 'Arquivo enviado com sucesso!';
            });
          } catch (uploadError) {
            // Erro no upload: $uploadError
            if (mounted) {
              SnackBarUtils.showWarning(
                context,
                'Licença atualizada, mas erro no upload: $uploadError',
              );
            }
          }
        }
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Licença atualizada com sucesso');
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Erro ao salvar: $e
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
          _uploadStatus = '';
        });
        SnackBarUtils.showError(context, 'Erro ao salvar: $e');
      }
    }
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return AppFormField(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [_dateMaskFormatter],
        decoration: AppDesignSystem.inputDecoration(
          hint: 'DD-MM-AAAA',
          prefixIcon: Icon(icon, color: AppDesignSystem.neutral500),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: AppDesignSystem.neutral500,
            ),
            onPressed: () => _selectDate(controller),
          ),
        ),
        validator: _validateDate,
        style: AppDesignSystem.bodyMedium,
      ),
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arquivo da Licença', style: AppDesignSystem.h3),
        const SizedBox(height: AppDesignSystem.spacing16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: AppDesignSystem.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDesignSystem.radiusM),
            ),
            border: Border.all(color: AppDesignSystem.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.license.arquivoUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.neutral50,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppDesignSystem.radiusM),
                    ),
                    border: Border.all(color: AppDesignSystem.neutral200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              AppDesignSystem.spacing8,
                            ),
                            decoration: const BoxDecoration(
                              color: AppDesignSystem.errorLight,
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppDesignSystem.radiusS),
                              ),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: AppDesignSystem.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppDesignSystem.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.license.arquivoNome ?? 'Arquivo atual',
                                  style: AppDesignSystem.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.license.arquivoUploadData != null)
                                  Text(
                                    'Enviado em ${DateFormat('dd/MM/yyyy HH:mm').format(widget.license.arquivoUploadData!)}',
                                    style: AppDesignSystem.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignSystem.spacing16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openPdf(widget.license.arquivoUrl!),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Visualizar'),
                          style: AppDesignSystem.secondaryButton,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
              ],

              if (_selectedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.surface,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppDesignSystem.radiusM),
                    ),
                    border: Border.all(
                      color: AppDesignSystem.neutral500.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.success.withAlpha(26),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppDesignSystem.radiusS),
                          ),
                        ),
                        child: Icon(
                          _getFileIcon(_selectedFile!.extension ?? ''),
                          color: AppDesignSystem.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDesignSystem.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arquivo selecionado',
                              style: AppDesignSystem.labelSmall.copyWith(
                                color: AppDesignSystem.neutral500,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _selectedFile!.name,
                              style: AppDesignSystem.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: AppDesignSystem.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppDesignSystem.neutral500,
                        ),
                        onPressed: _isUploading
                            ? null
                            : () => setState(() {
                                _selectedFile = null;
                              }),
                        tooltip: 'Remover arquivo',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
              ],

              _buildDropZone(),

              const SizedBox(height: AppDesignSystem.spacing8),
              Text(
                'PDF para armazenar (máx. 10MB)',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir zona de drag & drop
  Widget _buildDropZone() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: _getDropZoneBackgroundColor(),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDesignSystem.radiusM),
        ),
        border: Border.all(
          color: _getDropZoneBorderColor(),
          width: _isDragOver ? 2 : 1,
          style: BorderStyle.solid,
        ),
      ),
      child: _isDropzoneSupported
          ? _buildDropzoneContent()
          : _buildSimpleFilePickerContent(),
    );
  }

  /// Construir conteúdo do dropzone com suporte a drag & drop
  Widget _buildDropzoneContent() {
    return Stack(
      children: [
        // Dropzone (apenas web)
        DropzoneView(
          onCreated: (controller) {
            _controller = controller;
          },
          onDropFile: _handleFileDrop,
          onHover: () {
            setState(() => _isDragOver = true);
          },
          onLeave: () {
            setState(() => _isDragOver = false);
          },
          onError: (error) {
            _showDropError('Erro ao processar arquivo: $error');
          },
        ),

        // Sobreposição de conteúdo
        Positioned.fill(
          child: InkWell(
            onTap: _isUploading ? null : _pickFile,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDesignSystem.radiusM),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              child: _buildDropZoneContent(),
            ),
          ),
        ),
      ],
    );
  }

  /// Construir conteúdo simples do seletor de arquivo (fallback)
  Widget _buildSimpleFilePickerContent() {
    return InkWell(
      onTap: _isUploading ? null : _pickFile,
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDesignSystem.radiusM),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: _buildDropZoneContent(),
      ),
    );
  }

  /// Construir conteúdo dentro da zona de drop
  Widget _buildDropZoneContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_hasDropError) ...[
          const Icon(
            Icons.error_outline,
            color: AppDesignSystem.error,
            size: 24,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            _dropErrorMessage,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.error,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          Icon(
            _isDragOver ? Icons.file_upload : Icons.cloud_upload_outlined,
            color: _isDragOver
                ? AppDesignSystem.primary
                : AppDesignSystem.neutral500,
            size: 24,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            _isDragOver
                ? 'Solte o arquivo aqui'
                : _isDropzoneSupported
                ? 'Arraste um arquivo ou clique para selecionar'
                : 'Clique para selecionar arquivo',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: _isDragOver
                  ? AppDesignSystem.primary
                  : AppDesignSystem.neutral600,
              fontWeight: _isDragOver ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'PDF, JPG, JPEG, PNG',
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Obter cor de fundo para zona de drop
  Color _getDropZoneBackgroundColor() {
    if (_hasDropError) {
      return AppDesignSystem.error.withAlpha(13);
    }
    if (_isDragOver) {
      return AppDesignSystem.primary.withAlpha(13);
    }
    return AppDesignSystem.surface;
  }

  /// Obter cor da borda para zona de drop
  Color _getDropZoneBorderColor() {
    if (_hasDropError) {
      return AppDesignSystem.error;
    }
    if (_isDragOver) {
      return AppDesignSystem.primary;
    }
    return AppDesignSystem.neutral200;
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      ),
      child: Container(
        width: Responsive.valueDetailed(
          context,
          mobile: MediaQuery.of(context).size.width * 0.95,
          tablet: 520.0,
          desktop: 520.0,
        ),
        constraints: BoxConstraints(
          maxHeight: Responsive.valueDetailed(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing24),
              decoration: const BoxDecoration(
                color: AppDesignSystem.neutral50,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDesignSystem.radiusL),
                ),
                border: Border(
                  bottom: BorderSide(color: AppDesignSystem.neutral200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.surface,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusM,
                      ),
                      border: Border.all(color: AppDesignSystem.neutral200),
                    ),
                    child: const Icon(
                      Icons.edit_document,
                      color: AppDesignSystem.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Editar Licença', style: AppDesignSystem.h3),
                        Text(
                          '${widget.license.uf} - ${widget.license.nome}',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppDesignSystem.neutral500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignSystem.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datas da Licença', style: AppDesignSystem.h3),
                      const SizedBox(height: AppDesignSystem.spacing16),

                      _buildDateField(
                        controller: _dataInicioController,
                        label: 'Data de Início',
                        icon: Icons.calendar_today,
                      ),

                      const SizedBox(height: AppDesignSystem.spacing16),

                      _buildDateField(
                        controller: _dataVencimentoController,
                        label: 'Data de Vencimento',
                        icon: Icons.event,
                      ),

                      const SizedBox(height: AppDesignSystem.spacing24),

                      _buildFileSection(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing24),
              decoration: const BoxDecoration(
                color: AppDesignSystem.neutral50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppDesignSystem.radiusL),
                ),
                border: Border(
                  top: BorderSide(color: AppDesignSystem.neutral200),
                ),
              ),
              child: Responsive.isSmallScreen(context)
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isUploading)
                                ? null
                                : _save,
                            style: AppDesignSystem.primaryButton,
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppDesignSystem.surface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppDesignSystem.spacing8,
                                      ),
                                      Flexible(
                                        child: Text(
                                          _uploadStatus.isNotEmpty
                                              ? _uploadStatus
                                              : 'Salvando...',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text('Salvar'),
                          ),
                        ),
                        const SizedBox(height: AppDesignSystem.spacing8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: (_isLoading || _isUploading)
                                ? null
                                : () => Navigator.pop(context),
                            style: AppDesignSystem.secondaryButton,
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: (_isLoading || _isUploading)
                              ? null
                              : () => Navigator.pop(context),
                          style: AppDesignSystem.secondaryButton,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: AppDesignSystem.spacing12),
                        ElevatedButton(
                          onPressed: (_isLoading || _isUploading)
                              ? null
                              : _save,
                          style: AppDesignSystem.primaryButton,
                          child: _isLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppDesignSystem.surface,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppDesignSystem.spacing8,
                                    ),
                                    Flexible(
                                      child: Text(
                                        _uploadStatus.isNotEmpty
                                            ? _uploadStatus
                                            : 'Salvando...',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text('Salvar'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
