// lib/modules/inventario_v2/dialogs/csv_import_dialog.dart
// ignore_for_file: sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/design_system.dart';
import '../../../models/inventario.dart';
import '../../../models/nota_fiscal.dart';
import '../../../services/csv_import_service.dart';
import '../../../helpers/database_helper_inventario.dart';
import '../../../helpers/uf_helper.dart';
import '../../../core/visuals/snackbar.dart';
import '../../../core/utilities/shared/responsive.dart';
import '../../../core/visuals/file_drop_zone.dart';

/// Diálogo de pré-visualização de importação CSV (NotaFiscal + Inventários)
class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({super.key});

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  NotaFiscal? _notaFiscal;
  List<Inventario>? _previewItems;
  Map<String, dynamic>? _importSummary;
  bool _isProcessingCsv = false;
  bool _isImporting = false;
  String _notaPrefix = '';
  String? _currentUserUf;
  PlatformFile? _selectedFile;
  String? _errorMessage;

  final TextEditingController _notaPrefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notaPrefixController.text = _notaPrefix;
    _loadUserUf();
  }

  @override
  void dispose() {
    _notaPrefixController.dispose();
    super.dispose();
  }

  /// Carregar UF do usuário atual
  Future<void> _loadUserUf() async {
    final uf = await UfHelper.getCurrentUserUf();
    if (mounted) {
      setState(() {
        _currentUserUf = uf ?? 'SP';
      });
    }
  }

  /// Mostrar mensagem de erro
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  /// Processar CSV selecionado e gerar pré-visualização
  Future<void> _processCsvFile(PlatformFile file) async {
    setState(() {
      _isProcessingCsv = true;
      _previewItems = null;
      _notaFiscal = null;
      _importSummary = null;
      _errorMessage = null;
    });

    try {
      if (_notaPrefix.trim().isEmpty) {
        throw Exception(
          'Por favor, preencha o nome da importação antes de processar o arquivo',
        );
      }

      if (_currentUserUf == null) {
        throw Exception('Não foi possível determinar sua UF. Tente novamente.');
      }

      // Validar arquivo
      final validationError = CsvImportServiceV2.validateCsvFile(
        file.name,
        file.size,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }

      if (file.bytes == null) {
        throw Exception('Não foi possível ler o arquivo');
      }

      // Processar CSV - retorna ImportResult com NotaFiscal + Inventários
      final result = await CsvImportServiceV2.processCsvData(
        file.bytes!,
        file.name,
        notaPrefix: _notaPrefix,
        uf: _currentUserUf!,
      );

      // Gerar resumo da importação
      final summary = CsvImportServiceV2.getImportSummary(
        result.notaFiscal,
        result.inventarios,
      );

      if (mounted) {
        setState(() {
          _notaFiscal = result.notaFiscal;
          _previewItems = result.inventarios;
          _importSummary = summary;
          _isProcessingCsv = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingCsv = false;
          _previewItems = null;
          _notaFiscal = null;
          _importSummary = null;
        });
        _showError(e.toString());
      }
    }
  }

  /// Atualizar prefixo e reprocessar se houver arquivo
  void _updateNotaPrefix(String newPrefix) {
    setState(() {
      _notaPrefix = newPrefix;
    });

    if (_selectedFile != null) {
      _processCsvFile(_selectedFile!);
    }
  }

  /// Executa a importação com createNotaFiscalWithInventarios
  Future<void> _performImport() async {
    if (_notaFiscal == null ||
        _previewItems == null ||
        _previewItems!.isEmpty) {
      _showError('Nenhum item para importar. Selecione um arquivo CSV válido.');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelperInventario();

      // Operação atômica: criar NotaFiscal com todos os Inventários
      await dbHelper.createNotaFiscalWithInventarios(
        _notaFiscal!,
        _previewItems!,
      );

      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        SnackBarUtils.showSuccess(
          context,
          'Importação concluída! ${_previewItems!.length} itens adicionados ao inventário.',
        );

        Navigator.of(context).pop(true); // retorna true em caso de sucesso
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        _showError('Erro durante a importação: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppDesignSystem.radiusL),
        ),
      ),
      child: Container(
        width: Responsive.valueDetailed(
          context,
          mobile: MediaQuery.of(context).size.width * 0.95,
          tablet: 700.0,
          desktop: 700.0,
        ),
        constraints: BoxConstraints(
          maxHeight: Responsive.valueDetailed(
            context,
            mobile: MediaQuery.of(context).size.height * 0.9,
            tablet: 600.0,
            desktop: 600.0,
          ),
        ),
        decoration: AppDesignSystem.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignSystem.spacing24),
                child: Form(key: _formKey, child: _buildFormContent()),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Construir cabeçalho do diálogo
  Widget _buildHeader() {
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
            child: const Icon(
              Icons.upload_file,
              color: AppDesignSystem.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Importar Inventário', style: AppDesignSystem.h3),
                Text(
                  'Selecione um arquivo CSV para importar itens em lote',
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

  /// Construir conteúdo do formulário
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruções
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: AppDesignSystem.neutral50,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDesignSystem.radiusM),
            ),
            border: Border.all(color: AppDesignSystem.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppDesignSystem.neutral600,
                    size: 18,
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Text(
                    'Formato esperado do CSV',
                    style: AppDesignSystem.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignSystem.spacing8),
              Text(
                '• Dados iniciam na linha 2 (linha 1 pode conter cabeçalho)\n'
                '• Coluna C: Descrição do produto\n'
                '• Coluna D: Modelo (opcional)\n'
                '• Coluna E: Departamento\n'
                '• Coluna F: Quantidade\n'
                '• Coluna G: Valor unitário\n'
                '• Coluna I: UF de origem (SP/CE)',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDesignSystem.spacing20),

        AppFormField(
          label: 'Nome da Importação',
          child: TextFormField(
            controller: _notaPrefixController,
            decoration: AppDesignSystem.inputDecoration(
              hint: 'Ex: Importação SPO',
              prefixIcon: const Icon(
                Icons.receipt,
                color: AppDesignSystem.neutral500,
              ),
            ),
            onChanged: _updateNotaPrefix,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nome da importação é obrigatório';
              }
              return null;
            },
            style: AppDesignSystem.bodyMedium,
          ),
        ),

        const SizedBox(height: AppDesignSystem.spacing20),

        // Seção de upload de arquivo
        _buildFileUploadSection(),

        // Mensagem de erro
        if (_errorMessage != null) ...[
          const SizedBox(height: AppDesignSystem.spacing12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignSystem.spacing12),
            decoration: BoxDecoration(
              color: AppDesignSystem.error.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDesignSystem.radiusM),
              ),
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
                    _errorMessage!,
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: AppDesignSystem.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Seção de pré-visualização
        if (_previewItems != null && _importSummary != null) ...[
          const SizedBox(height: AppDesignSystem.spacing24),
          _buildPreviewSection(),
        ],
      ],
    );
  }

  /// Construir seção de upload de arquivo
  Widget _buildFileUploadSection() {
    return AppFormField(
      label: 'Arquivo CSV',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileDropZone(
            onFileSelected: (file) {
              setState(() {
                _selectedFile = file;
                _errorMessage = null;
              });
              _processCsvFile(file);
            },
            allowedExtensions: const ['csv'],
            existingFileName: _selectedFile?.name,
            isProcessing: _isProcessingCsv,
            processingMessage: 'Processando arquivo CSV...',
            enabled: _notaPrefix.trim().isNotEmpty,
          ),

          // Detalhes do arquivo selecionado
          if (_selectedFile != null) ...[
            const SizedBox(height: AppDesignSystem.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              decoration: BoxDecoration(
                color: AppDesignSystem.neutral50,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppDesignSystem.radiusM),
                ),
                border: Border.all(color: AppDesignSystem.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppDesignSystem.radiusS),
                      ),
                    ),
                    child: const Icon(
                      Icons.table_chart,
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
                          _selectedFile!.name,
                          style: AppDesignSystem.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _previewItems = null;
                        _notaFiscal = null;
                        _importSummary = null;
                        _errorMessage = null;
                      });
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

          // Informação de limite de tamanho
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            'Formato: CSV • Tamanho máximo: 5MB',
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de pré-visualização com resumo e itens
  Widget _buildPreviewSection() {
    final summary = _importSummary!;
    final items = _previewItems!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do resumo
        Row(
          children: [
            const Icon(
              Icons.preview,
              color: AppDesignSystem.neutral600,
              size: 20,
            ),
            const SizedBox(width: AppDesignSystem.spacing8),
            Text(
              'Pré-visualização da Importação',
              style: AppDesignSystem.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDesignSystem.spacing12),

        // Texto de resumo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesignSystem.spacing12),
          decoration: BoxDecoration(
            color: AppDesignSystem.neutral50,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDesignSystem.radiusM),
            ),
            border: Border.all(color: AppDesignSystem.neutral200),
          ),
          child: Text(
            '${summary['totalItems']} itens serão importados • '
            'Valor total: R\$ ${(summary['totalValue'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
            style: AppDesignSystem.bodyMedium,
          ),
        ),

        const SizedBox(height: AppDesignSystem.spacing16),

        // Pré-visualização dos inventários que serão criados
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            border: Border.all(color: AppDesignSystem.neutral200),
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDesignSystem.radiusM),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDesignSystem.spacing12),
                decoration: const BoxDecoration(
                  color: AppDesignSystem.neutral50,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDesignSystem.radiusM),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      child: const Text(
                        '#',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Produto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Descrição',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: const Text(
                        'Valor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      child: const Text(
                        'UF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Localização',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      child: const Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista - exibe todos os inventários
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDesignSystem.spacing4,
                      ),
                      child: Row(
                        children: [
                          // Número da linha
                          Container(
                            width: 30,
                            child: Text(
                              '${index + 1}',
                              style: AppDesignSystem.bodySmall.copyWith(
                                color: AppDesignSystem.neutral500,
                              ),
                            ),
                          ),
                          // Produto
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.produto,
                              style: AppDesignSystem.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Descrição (com quantidade)
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.descricao,
                              style: AppDesignSystem.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Valor (valor total)
                          Container(
                            width: 80,
                            child: Text(
                              'R\$ ${item.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: AppDesignSystem.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // UF
                          Container(
                            width: 30,
                            child: Text(
                              item.uf,
                              style: AppDesignSystem.labelSmall,
                            ),
                          ),
                          // Localização
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.localizacao ?? 'N/A',
                              style: AppDesignSystem.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Estado
                          Container(
                            width: 60,
                            child: Text(
                              item.estado,
                              style: AppDesignSystem.bodySmall.copyWith(
                                color: AppDesignSystem.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir botões de ação
  Widget _buildActionButtons() {
    final bool hasPreview = _previewItems != null && _previewItems!.isNotEmpty;
    final bool canImport = hasPreview && !_isProcessingCsv && !_isImporting;
    final bool isProcessing = _isProcessingCsv || _isImporting;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: !isProcessing ? () => Navigator.pop(context) : null,
            style: AppDesignSystem.secondaryButton,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          ElevatedButton(
            onPressed: canImport ? _performImport : null,
            style: AppDesignSystem.primaryButton,
            child: isProcessing
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
                      Text(_isImporting ? 'Importando...' : 'Processando...'),
                    ],
                  )
                : Text(
                    hasPreview
                        ? 'Importar ${_previewItems!.length} Itens'
                        : 'Selecione um arquivo CSV',
                  ),
          ),
        ],
      ),
    );
  }
}
