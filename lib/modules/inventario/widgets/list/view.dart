import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../models/inventario.dart';
import '../../../../models/nota_fiscal.dart';
import '../../../../helpers/database_helper_inventario.dart';
import '../../../../core/utilities/files/file_handler.dart';
import '../../../../core/design_system.dart';

class InventarioViewPage extends StatefulWidget {
  final Inventario inventario;
  final VoidCallback? onBackToList;
  final VoidCallback? onEdit;
  final Function(String notaFiscalId)? onAddItemsToNotaFiscal;

  const InventarioViewPage({
    super.key,
    required this.inventario,
    this.onBackToList,
    this.onEdit,
    this.onAddItemsToNotaFiscal,
  });

  @override
  State<InventarioViewPage> createState() => _InventarioViewPageState();
}

class _InventarioViewPageState extends State<InventarioViewPage> {
  final _dateFormat = DateFormat('dd-MM-yyyy');
  NotaFiscal? _notaFiscal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotaFiscal();
  }

  Future<void> _loadNotaFiscal() async {
    try {
      final helper = DatabaseHelperInventario();
      final nota = await helper.getNotaFiscalById(
        widget.inventario.notaFiscalId,
      );
      if (mounted) {
        setState(() {
          _notaFiscal = nota;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildInfoCell(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool addTrailingNewline = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppDesignSystem.neutral600),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppDesignSystem.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppDesignSystem.labelMedium.copyWith(
                      color: AppDesignSystem.neutral600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: valueColor ?? AppDesignSystem.neutral800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (addTrailingNewline)
                    const TextSpan(
                      text: '\n',
                    ), // quebra de linha oculta para copiar formato
                ],
              ),
              style: const TextStyle(height: 0.8), // reduzir altura da linha
            ),
          ),
        ],
      ),
    );
  }

  void _openNotaFiscal(String url) async {
    try {
      final viewableUrl = FirebaseStorageUtils.makeUrlViewable(url);

      if (await canLaunchUrl(Uri.parse(viewableUrl))) {
        await launchUrl(
          Uri.parse(viewableUrl),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        throw 'Não foi possível abrir o arquivo';
      }
    } catch (e) {
      // Erro ao abrir arquivo
    }
  }

  Widget buildGridSection(List<Widget> cells, {int columns = 2}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int colCount = constraints.maxWidth > 600 ? columns : 1;
        double itemWidth =
            (constraints.maxWidth -
                (colCount - 1) * AppDesignSystem.spacing24) /
            colCount;

        return Wrap(
          spacing: AppDesignSystem.spacing24,
          children: cells
              .map((cell) => SizedBox(width: itemWidth, child: cell))
              .toList(),
        );
      },
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
      child: Text(
        title,
        style: AppDesignSystem.h3.copyWith(
          fontSize: 16,
          color: AppDesignSystem.neutral800,
        ),
      ),
    );
  }

  Widget buildInventarioContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDesignSystem.spacing24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Formatar data de compra da NotaFiscal
    final dataCompra = _notaFiscal != null
        ? _dateFormat.format(_notaFiscal!.dataCompra)
        : 'N/A';

    final identificacaoCells = [
      if (widget.inventario.internalId != null)
        buildInfoCell(
          Icons.confirmation_number_outlined,
          'ID Interno',
          widget.inventario.internalId.toString(),
        ),
      if (_notaFiscal != null)
        buildInfoCell(
          Icons.receipt_outlined,
          'Nota Fiscal',
          _notaFiscal!.numeroNota,
        ),
      buildInfoCell(
        Icons.precision_manufacturing_outlined,
        'Produto',
        widget.inventario.produto,
      ),
      buildInfoCell(Icons.category_outlined, 'Tipo', widget.inventario.tipo),
    ];

    final fornecedorLocalizacaoCells = [
      if (_notaFiscal != null)
        buildInfoCell(
          Icons.shopping_bag_outlined,
          'Fornecedor',
          _notaFiscal!.fornecedor,
        ),
      buildInfoCell(
        Icons.map_outlined,
        'UF',
        widget.inventario.uf,
        valueColor: widget.inventario.uf == 'CE'
            ? AppDesignSystem.success
            : AppDesignSystem.neutral500,
      ),
      buildInfoCell(
        Icons.location_on_outlined,
        'Localização',
        widget.inventario.localizacao ?? '',
      ),
      buildInfoCell(
        Icons.flag_outlined,
        'Estado',
        widget.inventario.estado,
        valueColor: widget.inventario.estado == 'Presente'
            ? AppDesignSystem.success
            : AppDesignSystem.error,
      ),
    ];

    final detalhesFinanceirosCells = [
      buildInfoCell(
        Icons.attach_money_outlined,
        'Valor',
        'R\$ ${widget.inventario.valor.toStringAsFixed(2)}',
      ),
      // Mostra data de compra da NotaFiscal
      buildInfoCell(
        Icons.calendar_today_outlined,
        'Data de Compra',
        dataCompra,
      ),
      if (widget.inventario.dataDeGarantia != null &&
          widget.inventario.dataDeGarantia!.isNotEmpty)
        buildInfoCell(
          Icons.event_available_outlined,
          'Data de Garantia',
          widget.inventario.dataDeGarantia!,
        ),
      if (widget.inventario.numeroDeSerie != null &&
          widget.inventario.numeroDeSerie!.isNotEmpty)
        buildInfoCell(
          Icons.numbers_outlined,
          'Nº de Série',
          widget.inventario.numeroDeSerie!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_notaFiscal != null) ...[
          _buildSubsectionTitle('Informações da Nota Fiscal'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignSystem.spacing12),
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral50,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral200),
            ),
            child: Column(
              children: [
                if (_notaFiscal!.chaveAcesso != null &&
                    _notaFiscal!.chaveAcesso!.isNotEmpty)
                  buildInfoCell(
                    Icons.key_outlined,
                    'Chave de Acesso',
                    _notaFiscal!.chaveAcesso!,
                  ),
                buildInfoCell(
                  Icons.attach_money_outlined,
                  'Valor Total da NF',
                  'R\$ ${_notaFiscal!.valorTotal.toStringAsFixed(2)}',
                ),
                if (_notaFiscal!.createdBy != null)
                  buildInfoCell(
                    Icons.person_outlined,
                    'Criado por',
                    _notaFiscal!.createdBy!,
                  ),
                buildInfoCell(
                  Icons.schedule_outlined,
                  'Data de Criação',
                  _dateFormat.format(_notaFiscal!.createdAt),
                  addTrailingNewline: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing4),
        ],

        if (_notaFiscal != null &&
            _notaFiscal!.notaFiscalUrl != null &&
            _notaFiscal!.notaFiscalUrl!.isNotEmpty) ...[
          const SizedBox(height: AppDesignSystem.spacing24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSubsectionTitle('Nota Fiscal'),
              const SizedBox(width: AppDesignSystem.spacing8),
              IconButton(
                onPressed: () => _openNotaFiscal(_notaFiscal!.notaFiscalUrl!),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                tooltip: 'Abrir em nova janela',
                style: IconButton.styleFrom(
                  backgroundColor: AppDesignSystem.surface,
                  foregroundColor: AppDesignSystem.neutral600,
                  side: const BorderSide(color: AppDesignSystem.neutral200),
                  padding: const EdgeInsets.all(AppDesignSystem.spacing6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppDesignSystem.spacing24),

        _buildSubsectionTitle('Identificação'),
        buildGridSection(identificacaoCells),
        const SizedBox(height: AppDesignSystem.spacing20),

        _buildSubsectionTitle('Fornecedor e Localização'),
        buildGridSection(fornecedorLocalizacaoCells),
        const SizedBox(height: AppDesignSystem.spacing20),

        _buildSubsectionTitle('Detalhes Financeiros'),
        buildGridSection(detalhesFinanceirosCells),
        const SizedBox(height: AppDesignSystem.spacing24),

        _buildSubsectionTitle('Descrição'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: AppDesignSystem.neutral50,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            border: Border.all(color: AppDesignSystem.neutral200),
          ),
          child: Text(
            widget.inventario.descricao,
            style: AppDesignSystem.bodyMedium.copyWith(
              height: 1.5,
              color: AppDesignSystem.neutral700,
            ),
          ),
        ),

        // Mostrar observações, se houver
        if (widget.inventario.observacoes != null &&
            widget.inventario.observacoes!.isNotEmpty) ...[
          const SizedBox(height: AppDesignSystem.spacing16),
          _buildSubsectionTitle('Observações'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral50,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral200),
            ),
            child: Text(
              widget.inventario.observacoes!,
              style: AppDesignSystem.bodyMedium.copyWith(
                height: 1.5,
                color: AppDesignSystem.neutral700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      body: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBackToList,
                        icon: const Icon(Icons.arrow_back_outlined, size: 20),
                        tooltip: 'Voltar à Lista',
                        style: IconButton.styleFrom(
                          backgroundColor: AppDesignSystem.surface,
                          foregroundColor: AppDesignSystem.neutral700,
                          side: const BorderSide(
                            color: AppDesignSystem.neutral200,
                          ),
                          padding: const EdgeInsets.all(
                            AppDesignSystem.spacing12,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDesignSystem.spacing16),
                      const Text(
                        'Detalhes do Inventário',
                        style: AppDesignSystem.h1,
                      ),
                    ],
                  ),
                  // Linha de botões de ação
                  Row(
                    children: [
                      // Botão Editar
                      if (widget.onEdit != null)
                        IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Editar',
                          style: IconButton.styleFrom(
                            backgroundColor: AppDesignSystem.surface,
                            foregroundColor: AppDesignSystem.primary,
                            side: BorderSide(
                              color: AppDesignSystem.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            padding: const EdgeInsets.all(
                              AppDesignSystem.spacing12,
                            ),
                          ),
                        ),
                      if (widget.onEdit != null)
                        const SizedBox(width: AppDesignSystem.spacing8),
                      // Botão Adicionar itens à Nota Fiscal
                      if (widget.onAddItemsToNotaFiscal != null)
                        IconButton(
                          onPressed: () {
                            widget.onAddItemsToNotaFiscal!(
                              widget.inventario.notaFiscalId,
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          tooltip: 'Adicionar Itens à Nota Fiscal',
                          style: IconButton.styleFrom(
                            backgroundColor: AppDesignSystem.surface,
                            foregroundColor: AppDesignSystem.success,
                            side: BorderSide(
                              color: AppDesignSystem.success.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            padding: const EdgeInsets.all(
                              AppDesignSystem.spacing12,
                            ),
                          ),
                        ),
                      if (widget.onAddItemsToNotaFiscal != null)
                        const SizedBox(width: AppDesignSystem.spacing8),
                      IconButton(
                        onPressed: () {
                          _loadNotaFiscal();
                        },
                        icon: const Icon(Icons.refresh_outlined, size: 20),
                        tooltip: 'Atualizar',
                        style: IconButton.styleFrom(
                          backgroundColor: AppDesignSystem.surface,
                          foregroundColor: AppDesignSystem.neutral700,
                          side: const BorderSide(
                            color: AppDesignSystem.neutral200,
                          ),
                          padding: const EdgeInsets.all(
                            AppDesignSystem.spacing12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDesignSystem.spacing24),

              // Conteúdo
              Expanded(
                child: Card(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusL,
                    ),
                    side: const BorderSide(color: AppDesignSystem.neutral200),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDesignSystem.spacing24),
                    child: SingleChildScrollView(
                      child: buildInventarioContent(),
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
}
