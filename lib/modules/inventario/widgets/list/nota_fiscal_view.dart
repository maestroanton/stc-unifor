import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/nota_fiscal.dart';
import '../../../../models/inventario.dart';
import '../../../../helpers/database_helper_inventario.dart';
import '../../../../core/utilities/files/file_handler.dart';
import '../../../../core/design_system.dart';
import '../../../../core/visuals/snackbar.dart';
import '../../../../core/visuals/status_indicator.dart';

class NotaFiscalViewPage extends StatefulWidget {
  final NotaFiscal notaFiscal;
  final VoidCallback? onBackToList;
  final Function(String notaFiscalId)? onAddItemsToNotaFiscal;
  final Function(Inventario item)? onViewItem;

  const NotaFiscalViewPage({
    super.key,
    required this.notaFiscal,
    this.onBackToList,
    this.onAddItemsToNotaFiscal,
    this.onViewItem,
  });

  @override
  State<NotaFiscalViewPage> createState() => _NotaFiscalViewPageState();
}

class _NotaFiscalViewPageState extends State<NotaFiscalViewPage> {
  final _dateFormat = DateFormat('dd-MM-yyyy');
  List<Inventario> _items = [];
  List<Inventario> _displayedItems = [];
  bool _isLoading = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  bool get _hasMoreItems => _displayedItems.length < _items.length;

  void _loadMoreItems() {
    setState(() {
      _currentPage++;
      final endIndex = (_currentPage * _itemsPerPage).clamp(0, _items.length);
      _displayedItems = _items.sublist(0, endIndex);
    });
  }

  Future<void> _loadItems() async {
    try {
      final helper = DatabaseHelperInventario();
      final allItems = await helper.getInventarios();
      final filteredItems = allItems
          .where((item) => item.notaFiscalId == widget.notaFiscal.id)
          .toList();

      if (mounted) {
        setState(() {
          _items = filteredItems;
          _currentPage = 1;
          final endIndex = (_itemsPerPage).clamp(0, _items.length);
          _displayedItems = _items.sublist(0, endIndex);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Erro ao carregar itens: $e');
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
                  if (addTrailingNewline) const TextSpan(text: '\n'),
                ],
              ),
              style: const TextStyle(height: 0.8),
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
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao abrir arquivo: $e');
      }
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

  Widget _buildInfoSection(List<Widget> cells) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: buildGridSection(cells),
    );
  }

  Widget _buildItemCard(Inventario item) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing8),
      decoration: BoxDecoration(
        color: AppDesignSystem.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.produto,
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing4),
                    DotIndicators.standard(
                      text: '',
                      dotColor: item.estado == 'Presente'
                          ? AppDesignSystem.success
                          : AppDesignSystem.error,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onViewItem != null
                    ? () => widget.onViewItem!(item)
                    : null,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                padding: const EdgeInsets.all(AppDesignSystem.spacing4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: AppDesignSystem.surface,
                  foregroundColor: AppDesignSystem.neutral600,
                  side: const BorderSide(color: AppDesignSystem.neutral200),
                  minimumSize: const Size(24, 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildNotaFiscalContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDesignSystem.spacing24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dataCompra = _dateFormat.format(widget.notaFiscal.dataCompra);
    final createdAt = _dateFormat.format(widget.notaFiscal.createdAt);

    final notaInfoCells = [
      buildInfoCell(
        Icons.receipt_outlined,
        'Número da Nota',
        widget.notaFiscal.numeroNota,
        addTrailingNewline: false,
      ),
      buildInfoCell(
        Icons.calendar_today_outlined,
        'Data de Compra',
        dataCompra,
        addTrailingNewline: false,
      ),
      buildInfoCell(
        Icons.shopping_bag_outlined,
        'Fornecedor',
        widget.notaFiscal.fornecedor,
        addTrailingNewline: false,
      ),
      buildInfoCell(
        Icons.attach_money_outlined,
        'Valor Total da NF',
        'R\$ ${widget.notaFiscal.valorTotal.toStringAsFixed(2)}',
        addTrailingNewline: false,
      ),
    ];

    final additionalInfoCells = [
      if (widget.notaFiscal.chaveAcesso != null &&
          widget.notaFiscal.chaveAcesso!.isNotEmpty)
        buildInfoCell(
          Icons.key_outlined,
          'Chave de Acesso',
          widget.notaFiscal.chaveAcesso!,
          addTrailingNewline: false,
        ),
      if (widget.notaFiscal.createdBy != null)
        buildInfoCell(
          Icons.person_outlined,
          'Criado por',
          widget.notaFiscal.createdBy!,
          addTrailingNewline: false,
        ),
      buildInfoCell(
        Icons.schedule_outlined,
        'Data de Criação',
        createdAt,
        addTrailingNewline: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionTitle('Informações da Nota Fiscal'),
        _buildInfoSection(notaInfoCells),
        const SizedBox(height: AppDesignSystem.spacing20),

        if (additionalInfoCells.isNotEmpty) ...[
          _buildSubsectionTitle('Informações Adicionais'),
          _buildInfoSection(additionalInfoCells),
          const SizedBox(height: AppDesignSystem.spacing20),
        ],

        if (widget.notaFiscal.notaFiscalUrl != null &&
            widget.notaFiscal.notaFiscalUrl!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSubsectionTitle('Nota Fiscal'),
              const SizedBox(width: AppDesignSystem.spacing8),
              IconButton(
                onPressed: () =>
                    _openNotaFiscal(widget.notaFiscal.notaFiscalUrl!),
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
          const SizedBox(height: AppDesignSystem.spacing4),
        ],

        const SizedBox(height: AppDesignSystem.spacing24),

        if (_items.isEmpty)
          AppDesignSystem.emptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum item encontrado',
            subtitle: 'Esta nota fiscal não possui itens cadastrados',
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 10
                  : MediaQuery.of(context).size.width > 900
                  ? 6
                  : MediaQuery.of(context).size.width > 600
                  ? 4
                  : 3,
              crossAxisSpacing: AppDesignSystem.spacing8,
              mainAxisSpacing: AppDesignSystem.spacing8,
              childAspectRatio: 3.0,
            ),
            itemCount: _displayedItems.length,
            itemBuilder: (context, index) =>
                _buildItemCard(_displayedItems[index]),
          ),
          if (_hasMoreItems) ...[
            const SizedBox(height: AppDesignSystem.spacing16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadMoreItems,
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  'Carregar mais (${_items.length - _displayedItems.length} restantes)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppDesignSystem.primary,
                  side: BorderSide(
                    color: AppDesignSystem.primary.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing16,
                    vertical: AppDesignSystem.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusM,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                        'Detalhes da Nota Fiscal',
                        style: AppDesignSystem.h1,
                      ),
                    ],
                  ),
                  // Linha de botões de ação
                  Row(
                    children: [
                      // Botão 'Adicionar itens' à Nota Fiscal
                      if (widget.onAddItemsToNotaFiscal != null)
                        IconButton(
                          onPressed: () {
                            widget.onAddItemsToNotaFiscal!(
                              widget.notaFiscal.id!,
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
                          _loadItems();
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
                      child: buildNotaFiscalContent(),
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
