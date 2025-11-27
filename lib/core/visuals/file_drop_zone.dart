import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/design_system.dart';

class FileDropZone extends StatefulWidget {
  final Function(PlatformFile file) onFileSelected;
  final List<String> allowedExtensions;
  final String? existingFileName;
  final bool isProcessing;
  final String processingMessage;
  final bool enabled;

  const FileDropZone({
    super.key,
    required this.onFileSelected,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.existingFileName,
    this.isProcessing = false,
    this.processingMessage = 'Processando...',
    this.enabled = true,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragOver = false;
  bool _hasError = false;
  String _errorMessage = '';

  /// Verifica se o dropzone é suportado na plataforma atual
  bool get _isDropzoneSupported {
    // Desabilita o dropzone por enquanto para evitar problemas de compatibilidade com plataforma
    // O seletor manual de arquivos funciona bem e é mais confiável
    return false;

    // Descomente abaixo se quiser habilitar dropzone para plataformas específicas:
    // if (!kIsWeb) return false;
    //
    // try {
    //   // Habilitar apenas em plataformas web específicas que suportam totalmente
    //   // Você pode customizar essa lógica com base em seus testes
    //   return kIsWeb;
    // } catch (e) {
    //   return false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(
          color: _getBorderColor(),
          width: _isDragOver ? 2 : 1,
          style: BorderStyle
              .solid, // Use sólido por enquanto, pois tracejado é complexo no Flutter
        ),
      ),
      child: _isDropzoneSupported
          ? _buildDropzoneContent()
          : _buildSimpleContent(),
    );
  }

  Widget _buildDropzoneContent() {
    return Stack(
      children: [
        // Dropzone (somente web)
        DropzoneView(
          onDropFile: _handleFileDrop,
          onHover: () {
            setState(() => _isDragOver = true);
          },
          onLeave: () {
            setState(() => _isDragOver = false);
          },
          onError: (error) {
            _showError('Erro ao processar arquivo: $error');
          },
        ),

        // Sobreposição de conteúdo
        Positioned.fill(
          child: InkWell(
            onTap: (widget.isProcessing || !widget.enabled) ? null : _pickFile,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            child: Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              child: _buildContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleContent() {
    return InkWell(
      onTap: (widget.isProcessing || !widget.enabled) ? null : _pickFile,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!widget.enabled) ...[
          const Icon(
            Icons.lock_outline,
            color: AppDesignSystem.neutral400,
            size: 24,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          const Text(
            'Preencha o campo acima para continuar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppDesignSystem.neutral500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (widget.isProcessing) ...[
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppDesignSystem.primary,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            widget.processingMessage,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppDesignSystem.neutral600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_hasError) ...[
          const Icon(
            Icons.error_outline,
            color: AppDesignSystem.error,
            size: 24,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppDesignSystem.error,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else if (widget.existingFileName != null) ...[
          Icon(
            _getFileIcon(widget.existingFileName!),
            color: AppDesignSystem.primary,
            size: 24,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            widget.existingFileName!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppDesignSystem.neutral700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'Clique ou arraste para substituir',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppDesignSystem.neutral500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
            'Formatos aceitos: ${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppDesignSystem.neutral500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Color _getBackgroundColor() {
    if (!widget.enabled) {
      return AppDesignSystem.neutral100;
    }
    if (widget.isProcessing) {
      return AppDesignSystem.neutral50;
    }
    if (_hasError) {
      return AppDesignSystem.error.withValues(alpha: 0.05);
    }
    if (_isDragOver) {
      return AppDesignSystem.primary.withValues(alpha: 0.05);
    }
    return AppDesignSystem.surface;
  }

  Color _getBorderColor() {
    if (!widget.enabled) {
      return AppDesignSystem.neutral300;
    }
    if (_hasError) {
      return AppDesignSystem.error;
    }
    if (_isDragOver) {
      return AppDesignSystem.primary;
    }
    return AppDesignSystem.neutral200;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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

  Future<void> _handleFileDrop(dynamic file) async {
    try {
      setState(() {
        _isDragOver = false;
        _hasError = false;
        _errorMessage = '';
      });

      // Somente processa arrastos na plataforma web
      if (!kIsWeb) {
        return;
      }

      // Obter informações do arquivo
      final name = file.name;
      final bytes = await file.getFileData();

      // Validar extensão do arquivo
      final extension = name.split('.').last.toLowerCase();
      if (!widget.allowedExtensions.contains(extension)) {
        _showError(
          'Formato de arquivo não suportado. Use: ${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')}',
        );
        return;
      }

      // Criar objeto PlatformFile
      final platformFile = PlatformFile(
        name: name,
        size: bytes.length,
        bytes: bytes,
        path: null, // Web não possui path
      );

      widget.onFileSelected(platformFile);
    } catch (e) {
      _showError('Erro ao processar arquivo: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        widget.onFileSelected(result.files.single);
      }
    } catch (e) {
      _showError('Erro ao selecionar arquivo: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    // Limpa o erro após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });
  }
}
