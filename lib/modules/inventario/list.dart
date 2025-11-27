// lib/modules/inventario_v2/list.dart
import 'package:flutter/material.dart';
import '../../helpers/database_helper_inventario.dart';
import '../../core/utilities/shared/responsive.dart';
import '../../core/utilities/dashboard/pagination.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';
import '../../helpers/uf_helper.dart';

import '../../core/visuals/snackbar.dart';
import '../../core/visuals/dialogue.dart';
import '../../core/design_system.dart';
import 'widgets/list/table_component.dart';
import 'widgets/list/group_component.dart';
import 'widgets/list/action_component.dart';
import 'services/filter_service.dart';
import 'dialogs/csv_import_dialog.dart';

class InventarioListPage extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final VoidCallback? onDataChanged;
  final Function(Inventario)? onViewInventario;
  final Function(Inventario)? onEditInventario;
  final VoidCallback? onCreateNew;
  final String? initialExpandedNotaId;

  const InventarioListPage({
    super.key,
    required this.activeFilters,
    this.onDataChanged,
    this.onViewInventario,
    this.onEditInventario,
    this.onCreateNew,
    this.initialExpandedNotaId,
  });

  @override
  State<InventarioListPage> createState() => _InventarioListPageState();
}

class _InventarioListPageState extends State<InventarioListPage> {
  Map<String, dynamic> _activeFilters = {};
  List<Inventario> _inventarios = [];
  List<Inventario> _filteredInventarios = [];
  Map<String, NotaFiscal> _notaFiscalCache = {}; // cache de NotaFiscal

  String _sortBy = 'Data de Compra (recente)';
  final Set<String> _expandedNotas = {};
  final Set<String> _loadingNotas = {};
  bool _isLoading = true;

  late final PaginationState _paginationState;

  String? userUf;
  bool isAdmin = false;

  // Agrupa inventários por NotaFiscal (para paginação)
  List<MapEntry<String, List<Inventario>>> get _groupedInventarios =>
      InventarioFilterService.groupInventariosByNotaFiscalId(
        _filteredInventarios,
        _notaFiscalCache,
      );

  // Grupos paginados
  List<MapEntry<String, List<Inventario>>> get _paginatedGroupedInventarios {
    final allGroups = _groupedInventarios;
    return _paginationState.getPaginatedItems(allGroups);
  }

  @override
  void initState() {
    super.initState();
    _activeFilters = widget.activeFilters;

    // Inicializa paginação: 10 grupos por página
    _paginationState = PaginationState();
    _paginationState.setPageSize(10); // 10 grupos por página
    _paginationState.addListener(_onPaginationChanged);

    _loadUserInfo();
    _loadInventarios();
  }

  @override
  void dispose() {
    // Limpa estado de paginação
    _paginationState.removeListener(_onPaginationChanged);
    _paginationState.dispose();
    super.dispose();
  }

  // Atualiza quando a paginação muda
  void _onPaginationChanged() {
    if (mounted) {
      setState(() {
        // Atualizar paginação quando o estado mudar
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final uf = await UfHelper.getCurrentUserUf();
    final admin = await UfHelper.isAdmin();
    if (mounted) {
      setState(() {
        userUf = uf;
        isAdmin = admin;
      });
    }
  }

  @override
  void didUpdateWidget(InventarioListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFilters != widget.activeFilters) {
      _activeFilters = widget.activeFilters;
      _applyCurrentFilters();
    }
  }

  Future<void> _loadInventarios() async {
    setState(() => _isLoading = true);

    try {
      final helper = DatabaseHelperInventario();

      // Carregar inventários e notas fiscais
      final inventariosList = await helper.getInventarios();
      final notaFiscalsList = await helper.getAllNotasFiscais();

      // Montar cache de NotaFiscal
      final cache = <String, NotaFiscal>{};
      for (final nf in notaFiscalsList) {
        if (nf.id != null) {
          cache[nf.id!] = nf;
        }
      }

      setState(() {
        _inventarios = inventariosList;
        _notaFiscalCache = cache;
        _filteredInventarios = InventarioFilterService.applyFilters(
          inventariosList,
          _activeFilters,
          _notaFiscalCache,
        );
        InventarioFilterService.applySorting(
          _filteredInventarios,
          _sortBy,
          _notaFiscalCache,
        );

        // Atualizar paginação com novos dados
        _updatePaginationData();
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar inventários: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyCurrentFilters() {
    setState(() {
      _filteredInventarios = InventarioFilterService.applyFilters(
        _inventarios,
        _activeFilters,
        _notaFiscalCache,
      );
      InventarioFilterService.applySorting(
        _filteredInventarios,
        _sortBy,
        _notaFiscalCache,
      );

      // Atualizar paginação e voltar para a página 1
      _updatePaginationData();
    });
  }

  // Atualiza estado de paginação com os dados atuais
  void _updatePaginationData() {
    final groupedData = _groupedInventarios;
    _paginationState.updateTotalItems(groupedData.length);
  }

  void _deleteInventario(String id, String notaFiscalId) async {
    final nota = _notaFiscalCache[notaFiscalId];
    final notaDisplay = nota?.numeroNota ?? notaFiscalId;

    await DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Confirmar exclusão',
      content:
          'Tem certeza que deseja excluir o inventário da nota "$notaDisplay"?',
      confirmText: 'Excluir',
      confirmColor: AppDesignSystem.error,
      onConfirm: () async {
        try {
          final item = _filteredInventarios.firstWhere((inv) => inv.id == id);
          await DatabaseHelperInventario().backupAndDeleteInventario(item);
        } catch (e) {
          if (!mounted) return;
          SnackBarUtils.showError(context, 'Erro ao excluir item: $e');
          return;
        }
        if (!mounted) return;
        await _loadInventarios();
        widget.onDataChanged?.call();
        // Snackbar de sucesso removido (por preferência do usuário)
      },
    );
  }

  /// Mostrar diálogo de importação CSV
  void _showImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CsvImportDialog(),
    ).then((_) {
      if (mounted) {
        _loadInventarios();
        widget.onDataChanged?.call();
      }
    });
  }

  Widget _buildSortButton(
    String title,
    String sortKey, [
    TextAlign alignment = TextAlign.start,
  ]) {
    return InventarioActionComponents.buildSortButton(
      title: title,
      sortKey: sortKey,
      currentSortBy: _sortBy,
      alignment: alignment,
      onTap: () {
        setState(() {
          // Mapeia chaves de ordenação para opções disponíveis
          switch (sortKey) {
            case 'estado':
              _sortBy = _sortBy == 'Estado (A-Z)'
                  ? 'Estado (Z-A)'
                  : 'Estado (A-Z)';
              break;
            case 'dataDeCompra':
              _sortBy = _sortBy == 'Data de Compra (recente)'
                  ? 'Data de Compra (antigo)'
                  : 'Data de Compra (recente)';
              break;
            case 'produto':
              _sortBy = _sortBy == 'Produto (A-Z)'
                  ? 'Produto (Z-A)'
                  : 'Produto (A-Z)';
              break;
            case 'valor':
              _sortBy = _sortBy == 'Valor (maior)'
                  ? 'Valor (menor)'
                  : 'Valor (maior)';
              break;
            case 'uf':
              _sortBy = _sortBy == 'UF (A-Z)' ? 'UF (Z-A)' : 'UF (A-Z)';
              break;
            default:
              _sortBy = 'Data de Compra (recente)';
          }

            // Voltar à página 1 ao alterar ordenação
          _paginationState.goToPage(1);
          InventarioFilterService.applySorting(
            _filteredInventarios,
            _sortBy,
            _notaFiscalCache,
          );
          _updatePaginationData();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.neutral50,
      body: Padding(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ações
            InventarioActionComponents.buildHeaderSection(
              context: context,
              onClearFilters: () {
                setState(() {
                  _activeFilters = {};
                  _applyCurrentFilters();
                });
              },
              onRefresh: _loadInventarios,
              onCreateNew: userUf != null ? widget.onCreateNew : null,
              onImportCsv: (userUf != null && isAdmin)
                  ? _showImportDialog
                  : null,
              onDataChanged: widget.onDataChanged,
              showCreateButton: userUf != null,
            ),
            SizedBox(height: Responsive.spacing(context)),

            // Conteúdo
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_groupedInventarios.isEmpty) {
      return InventarioActionComponents.buildEmptyState(context);
    }

    return Column(
      children: [
        // Cabeçalho da tabela (bordas tratadas pelo container)
        Container(
          margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
          child: InventarioTableComponents.buildTableHeader(
            context,
            _buildSortButton,
          ),
        ),

        // Container de conteúdo sem fundo branco
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInventarios,
                  child: ListView.builder(
                    itemCount: _paginatedGroupedInventarios.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: 100,
                    itemBuilder: (context, index) {
                      final entry = _paginatedGroupedInventarios[index];
                      final notaFiscalId = entry.key;
                      final items = entry.value;
                      final isExpanded = _expandedNotas.contains(notaFiscalId);
                      final isLoading = _loadingNotas.contains(notaFiscalId);

                      return RepaintBoundary(
                        key: ValueKey('group_$notaFiscalId'),
                        child: InventarioGroupComponents.buildInventarioGroup(
                          context,
                          notaFiscalId,
                          _notaFiscalCache[notaFiscalId],
                          items,
                          isExpanded,
                          isLoading,
                          index,
                          () async {
                            if (isExpanded) {
                              setState(() {
                                _expandedNotas.remove(notaFiscalId);
                                _loadingNotas.remove(notaFiscalId);
                              });
                            } else {
                              setState(() {
                                _loadingNotas.add(notaFiscalId);
                              });

                              // Pequeno delay para mostrar indicador de carregamento
                              await Future.delayed(
                                const Duration(milliseconds: 50),
                              );

                              if (mounted) {
                                setState(() {
                                  _expandedNotas.add(notaFiscalId);
                                  _loadingNotas.remove(notaFiscalId);
                                });
                              }
                            }
                          },
                          widget.onViewInventario,
                          widget.onEditInventario,
                          _deleteInventario,
                          widget.onDataChanged,
                          userUf: userUf,
                          isAdmin: isAdmin,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Rodapé da paginação (fundo branco apenas)
              if (_groupedInventarios.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppDesignSystem.surface,
                    border: Border.all(color: AppDesignSystem.neutral200),
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppDesignSystem.radiusM),
                    ),
                  ),
                  child: PaginationFooter(
                    paginationState: _paginationState,
                    showPageSizeSelector: true,
                    pageSizeOptions: const [5, 10, 15, 25, 50],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
