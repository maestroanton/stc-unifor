import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../helpers/database_helper_inventario.dart';
import '../../helpers/database_reauth.dart';
import '../../core/utilities/shared/responsive.dart';
import '../../core/visuals/dialogue.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';
import '../../core/design_system.dart';
import '../../core/base_page.dart';

import '../../core/visuals/snackbar.dart';
import 'widgets/list/view.dart';

class InventarioTrashPage extends BasePageTemplate {
  final VoidCallback? onItemRestored; // chama quando item é restaurado
  final VoidCallback?
  onItemDeleted; // chama quando item é excluído permanentemente
  final Function(Inventario)?
  onViewInventario; // callback para abrir item na página principal

  const InventarioTrashPage({
    super.key,
    this.onItemRestored,
    this.onItemDeleted,
    this.onViewInventario,
  });

  @override
  String get pageTitle => 'Inventário Excluído';

  @override
  IconData get pageIcon => Icons.delete_sweep_outlined;

  @override
  bool get hasBackButton => true;

  @override
  VoidCallback? get onBack => onItemRestored;

  @override
  List<Widget>? get headerActions => [
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Atualizar lista',
      onPressed: () {
        // Atualizar é responsabilidade do widget de conteúdo
      },
      style: AppDesignSystem.secondaryButton.copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) {
    return _InventarioTrashContent(
      onItemRestored: onItemRestored,
      onItemDeleted: onItemDeleted,
      onViewInventario: onViewInventario,
    );
  }
}

class _InventarioTrashContent extends StatefulWidget {
  final VoidCallback? onItemRestored;
  final VoidCallback? onItemDeleted;
  final Function(Inventario)? onViewInventario;

  const _InventarioTrashContent({
    this.onItemRestored,
    this.onItemDeleted,
    this.onViewInventario,
  });

  @override
  State<_InventarioTrashContent> createState() =>
      _InventarioTrashContentState();
}

class _InventarioTrashContentState extends State<_InventarioTrashContent> {
  List<Inventario> _deletedItems = [];
    Map<String, NotaFiscal> _notasFiscaisMap =
      {}; // cache de NotaFiscal por ID
  bool _isLoading = true;
  String _sortBy = 'Data de Exclusão (recente)';
  final Set<String> _expandedNotas = {};
  final _backupRef = FirebaseFirestore.instance.collection(
    'inventarios_backup',
  );
  final _notasFiscaisBackupRef = FirebaseFirestore.instance.collection(
    'notas_fiscais_backup',
  );

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Carregar inventários excluídos
      final snapshot = await _backupRef
          .orderBy('deletedAt', descending: true)
          .get();
      if (!mounted) return;

      final deletedItems = snapshot.docs
          .map((doc) => Inventario.fromMap(doc.data(), doc.id))
          .toList();

      // Carregar Notas Fiscais relacionadas do backup
      final notaFiscalIds = deletedItems
          .map((item) => item.notaFiscalId)
          .toSet();
      final notasFiscaisMap = <String, NotaFiscal>{};

      for (final notaFiscalId in notaFiscalIds) {
        final notaDoc = await _notasFiscaisBackupRef.doc(notaFiscalId).get();
        if (notaDoc.exists) {
          notasFiscaisMap[notaFiscalId] = NotaFiscal.fromMap(
            notaDoc.data()!,
            notaDoc.id,
          );
        }
      }

      setState(() {
        _deletedItems = deletedItems;
        _notasFiscaisMap = notasFiscaisMap;
        _applySorting();
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao carregar itens excluídos: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Estado (A-Z)':
        _deletedItems.sort((a, b) => a.estado.compareTo(b.estado));
        break;
      case 'Estado (Z-A)':
        _deletedItems.sort((a, b) => b.estado.compareTo(a.estado));
        break;
      case 'Produto (A-Z)':
        _deletedItems.sort((a, b) => a.produto.compareTo(b.produto));
        break;
      case 'Produto (Z-A)':
        _deletedItems.sort((a, b) => b.produto.compareTo(a.produto));
        break;
      case 'Valor (maior)':
        _deletedItems.sort((a, b) => b.valor.compareTo(a.valor));
        break;
      case 'Valor (menor)':
        _deletedItems.sort((a, b) => a.valor.compareTo(b.valor));
        break;
      case 'UF (A-Z)':
        _deletedItems.sort((a, b) => a.uf.compareTo(b.uf));
        break;
      case 'UF (Z-A)':
        _deletedItems.sort((a, b) => b.uf.compareTo(a.uf));
        break;
      case 'Data de Exclusão (recente)':
        _deletedItems = _deletedItems.toList();
        break;
      case 'Data de Exclusão (antigo)':
        _deletedItems = _deletedItems.reversed.toList();
        break;
      default:
        // Já ordenado por deletedAt (consulta do Firestore)
        break;
    }
  }

  // Agrupa itens por notaFiscalId
  List<MapEntry<String, List<Inventario>>> get _groupedItems {
    final groups = <String, List<Inventario>>{};
    for (final item in _deletedItems) {
      groups.putIfAbsent(item.notaFiscalId, () => []).add(item);
    }
    return groups.entries.toList();
  }

  Widget _buildSortButton(
    BuildContext context, {
    required String title,
    required String sortKey,
    TextAlign alignment = TextAlign.start,
  }) {
    // Mapeia chaves para opções de ordenação
    String getNextSortOption(String currentSort, String key) {
      switch (key) {
        case 'estado':
          return currentSort == 'Estado (A-Z)'
              ? 'Estado (Z-A)'
              : 'Estado (A-Z)';
        case 'dataDeCompra':
          return currentSort == 'Data de Exclusão (recente)'
              ? 'Data de Exclusão (antigo)'
              : 'Data de Exclusão (recente)';
        case 'produto':
          return currentSort == 'Produto (A-Z)'
              ? 'Produto (Z-A)'
              : 'Produto (A-Z)';
        case 'valor':
          return currentSort == 'Valor (maior)'
              ? 'Valor (menor)'
              : 'Valor (maior)';
        case 'uf':
          return currentSort == 'UF (A-Z)' ? 'UF (Z-A)' : 'UF (A-Z)';
        default:
          return 'Data de Exclusão (recente)';
      }
    }

    final isActive = _sortBy.contains(
      title == 'Data Exclusão' ? 'Data de Exclusão' : title,
    );

    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = getNextSortOption(_sortBy, sortKey);
          _applySorting();
        });
      },
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing4,
          vertical: AppDesignSystem.spacing8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment == TextAlign.end
              ? MainAxisAlignment.end
              : alignment == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context),
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? AppDesignSystem.primary
                      : AppDesignSystem.neutral600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: alignment,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing4),
            Icon(
              isActive ? Icons.keyboard_arrow_down : Icons.unfold_more,
              size: Responsive.smallIconSize(context),
              color: isActive
                  ? AppDesignSystem.primary
                  : AppDesignSystem.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: AppDesignSystem.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Responsive.isMobile(context)
          ? _buildMobileHeader(context)
          : _buildDesktopTableHeader(context),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSortButton(
            context,
            title: 'Produto',
            sortKey: 'produto',
            alignment: TextAlign.start,
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing8),
        _buildSortButton(
          context,
          title: 'Status',
          sortKey: 'estado',
          alignment: TextAlign.start,
        ),
        const SizedBox(width: AppDesignSystem.spacing8),
        _buildSortButton(
          context,
          title: 'Preço',
          sortKey: 'valor',
          alignment: TextAlign.start,
        ),
        const SizedBox(width: AppDesignSystem.spacing8),
        _buildSortButton(
          context,
          title: 'UF',
          sortKey: 'uf',
          alignment: TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildDesktopTableHeader(BuildContext context) {
    const double statusWidth = 80.0;
    const double dateWidth = 120.0;
    const double priceWidth = 120.0;
    const double ufWidth = 50.0;
    const double actionsWidth = 120.0;
    const double spacing = AppDesignSystem.spacing16;

    return Row(
      children: [
        // Coluna: status
        SizedBox(
          width: statusWidth,
          child: _buildSortButton(
            context,
            title: 'Status',
            sortKey: 'estado',
            alignment: TextAlign.start,
          ),
        ),
        const SizedBox(width: spacing),

        // Coluna: data
        SizedBox(
          width: dateWidth,
          child: _buildSortButton(
            context,
            title: 'Data Exclusão',
            sortKey: 'dataDeCompra',
            alignment: TextAlign.start,
          ),
        ),

        // Coluna: produto (flexível)
        Expanded(
          child: _buildSortButton(
            context,
            title: 'Produto',
            sortKey: 'produto',
            alignment: TextAlign.start,
          ),
        ),

        // Coluna: preço
        SizedBox(
          width: priceWidth,
          child: _buildSortButton(
            context,
            title: 'Preço',
            sortKey: 'valor',
            alignment: TextAlign.end,
          ),
        ),
        const SizedBox(width: spacing),

        // Coluna: UF
        SizedBox(
          width: ufWidth,
          child: _buildSortButton(
            context,
            title: 'UF',
            sortKey: 'uf',
            alignment: TextAlign.center,
          ),
        ),
        const SizedBox(width: spacing),

        // Coluna: ações
        SizedBox(
          width: actionsWidth,
          child: Text(
            'Ações',
            style: TextStyle(
              fontSize: Responsive.smallFontSize(context),
              fontWeight: FontWeight.w500,
              color: AppDesignSystem.neutral600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _permanentlyDelete(BuildContext context, Inventario item) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !(await isAdmin(user.email))) {
      if (context.mounted) {
        SnackBarUtils.showAdmin(
          context,
          'Apenas administradores podem realizar esta operação.',
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Obter dados da Nota Fiscal para exibir
    final notaFiscal = _notasFiscaisMap[item.notaFiscalId];
    final notaDisplay = notaFiscal?.numeroNota ?? 'Desconhecida';

    // 1) Solicitar senha
    final password = await promptForUserPassword(context);
    if (password == null || password.isEmpty) return;

    // 2) Reautenticar usuário
    final reauthSuccess = await reauthenticateUserWithPassword(password);
    if (!reauthSuccess) {
      if (context.mounted) {
        SnackBarUtils.showAuth(
          context,
          'Senha incorreta. A operação foi cancelada.',
        );
      }
      return;
    }

    if (!context.mounted) return;

    // 3) Confirmar exclusão permanente
    final confirm = await confirmPermanentDeleteDialog(
      context,
      'o item da nota "$notaDisplay"',
    );
    if (confirm != true) return;

    try {
      await _backupRef.doc(item.id).delete();
      // Após excluir backup, verificar se a NotaFiscal pai ainda tem inventários
      final helper = DatabaseHelperInventario();
      final remainingInventarios = await helper.getInventariosByNotaFiscalId(
        item.notaFiscalId,
      );

      // Verificar outros backups dessa nota fiscal
      final remainingBackups = await _backupRef
          .where('notaFiscalId', isEqualTo: item.notaFiscalId)
          .get();

      if (remainingInventarios.isEmpty && remainingBackups.docs.isEmpty) {
        // Sem inventários ativos ou backups: excluir NotaFiscal e backup
        // Excluir NotaFiscal do backup (se existir)
        final backupExists = await helper.notaFiscalBackupExists(
          item.notaFiscalId,
        );
        if (backupExists) {
          await helper.permanentlyDeleteNotaFiscalBackup(item.notaFiscalId);
        }

        // Excluir NotaFiscal da coleção ativa (se existir)
        final notaExists = await helper.getNotaFiscalById(item.notaFiscalId);
        if (notaExists != null) {
          await helper.deleteNotaFiscal(item.notaFiscalId);
        }
      }

      if (!context.mounted) return;
      // Snackbar de sucesso removido (preferência do usuário)

      await _loadDeletedItems();
      widget.onItemDeleted?.call();
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Erro ao excluir permanentemente: $e');
      }
    }
  }

  // Função de restauração atualizada
  Future<void> _restoreItem(Inventario item) async {
    // Obter dados da Nota Fiscal para exibir
    final notaFiscal = _notasFiscaisMap[item.notaFiscalId];
    final notaDisplay = notaFiscal?.numeroNota ?? 'Desconhecida';

    // Usar DialogUtils (visuals)
    await DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Confirmar restauração',
      content: 'Deseja restaurar o item da nota "$notaDisplay"?',
      confirmText: 'Restaurar',
      confirmColor: AppDesignSystem.primary,
      onConfirm: () async {
        try {
          // Verifica se NotaFiscal existe; se não, tenta restaurar do backup
          final helper = DatabaseHelperInventario();
          var notaFiscal = await helper.getNotaFiscalById(item.notaFiscalId);

          if (notaFiscal == null) {
            // Tentar restaurar NotaFiscal do backup
            final backupExists = await helper.notaFiscalBackupExists(
              item.notaFiscalId,
            );
            if (backupExists) {
              // Restaurar NotaFiscal do backup
              await helper.restoreNotaFiscal(item.notaFiscalId);
              // Recarregar NotaFiscal
              notaFiscal = await helper.getNotaFiscalById(item.notaFiscalId);
            } else {
              if (mounted) {
                SnackBarUtils.showError(
                  context,
                  'Não foi possível restaurar: a Nota Fiscal não existe e não foi encontrada no backup. Crie a nota fiscal novamente antes de restaurar o item.',
                );
              }
              return;
            }
          }

          await helper.restoreInventario(item);

          if (mounted) {
            SnackBarUtils.showRestore(
              context,
              'Item da NF $notaDisplay restaurado.',
            );

            await _loadDeletedItems();
            widget.onItemRestored?.call(); // notifica componente pai
          }
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showError(context, 'Erro ao restaurar item: $e');
          }
        }
      },
    );
  }

  void _viewItem(Inventario item) {
    if (widget.onViewInventario != null) {
      // Usa callback para integrar com a página principal
      widget.onViewInventario!(item);
    } else {
      // Se não houver callback, volta para comportamento antigo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Detalhes do Item')),
            body: InventarioViewPage(inventario: item),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppDesignSystem.loadingState();
    }

    return Container(
      color: AppDesignSystem.neutral50,
      child: Padding(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho mobile — só em telas pequenas
            if (Responsive.isSmallScreen(context)) _buildMobilePageHeader(),
            if (Responsive.isSmallScreen(context))
              SizedBox(height: Responsive.spacing(context)),

            // Conteúdo
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Lixeira',
            style: TextStyle(
              fontSize: Responsive.headerFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_deletedItems.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista',
            onPressed: _loadDeletedItems,
            style: AppDesignSystem.secondaryButton.copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_deletedItems.isEmpty) {
      return SizedBox(
        height: 400,
        child: AppDesignSystem.emptyState(
          icon: Icons.delete_sweep,
          title: 'Nenhum item excluído',
          subtitle: 'Os itens excluídos aparecerão aqui',
        ),
      );
    }

    return Column(
      children: [
        // Cabeçalho da tabela
        _buildTableHeader(context),
        const SizedBox(height: AppDesignSystem.spacing8),

        // Lista — expande dentro do pai
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDeletedItems,
            child: ListView.builder(
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final entry = _groupedItems[index];
                final notaFiscalId = entry.key;
                final items = entry.value;
                final isExpanded = _expandedNotas.contains(notaFiscalId);

                return _buildInventarioGroup(
                  context,
                  notaFiscalId,
                  items,
                  isExpanded,
                  index,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventarioGroup(
    BuildContext context,
    String notaFiscalId,
    List<Inventario> items,
    bool isExpanded,
    int groupIndex,
  ) {
    final backgroundColor = groupIndex.isEven
        ? AppDesignSystem.surface
        : AppDesignSystem.neutral50;

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing2),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)),
        side: BorderSide(color: AppDesignSystem.neutral200, width: 1),
      ),
      child: Column(
        children: [
          // Cabeçalho do grupo
          _buildGroupHeader(context, notaFiscalId, items, isExpanded),
          // Itens expandidos
          if (isExpanded)
            ...items.map((item) => _buildInventarioItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    String notaFiscalId,
    List<Inventario> items,
    bool isExpanded,
  ) {
    final totalValue = items.fold<double>(0, (total, i) => total + i.valor);
    final notaFiscal = _notasFiscaisMap[notaFiscalId];
    final numeroNota = notaFiscal?.numeroNota ?? 'Desconhecida';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: AppDesignSystem.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.surface,
        border: Border.all(color: AppDesignSystem.neutral200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedNotas.remove(notaFiscalId);
              } else {
                _expandedNotas.add(notaFiscalId);
              }
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing8,
              vertical: AppDesignSystem.spacing4,
            ),
            child: Responsive.isMobile(context)
                ? _buildMobileGroupHeader(
                    context,
                    numeroNota,
                    items,
                    totalValue,
                    isExpanded,
                  )
                : _buildDesktopGroupHeader(
                    context,
                    numeroNota,
                    items,
                    totalValue,
                    isExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileGroupHeader(
    BuildContext context,
    String numeroNota,
    List<Inventario> items,
    double totalValue,
    bool isExpanded,
  ) {
    return Row(
      children: [
        // Ícone de exclusão — fundo vermelho suave
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppDesignSystem.errorLight,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: AppDesignSystem.error, width: 1),
          ),
          child: const Icon(
            Icons.delete_outline,
            size: 16,
            color: AppDesignSystem.error,
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Nº. $numeroNota',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.bodyFontSize(context),
                      color: AppDesignSystem.neutral800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignSystem.spacing2),
              Row(
                children: [
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: AppDesignSystem.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Text(
                    'R\$ ${totalValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: AppDesignSystem.neutral800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Ícone de chevron
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: AppDesignSystem.neutral600,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildDesktopGroupHeader(
    BuildContext context,
    String numeroNota,
    List<Inventario> items,
    double totalValue,
    bool isExpanded,
  ) {
    const double statusWidth = 80.0;
    const double dateWidth = 120.0;
    const double priceWidth = 120.0;
    const double ufWidth = 50.0;
    const double actionsWidth = 120.0;
    const double spacing = 16.0;

    return Row(
      children: [
        // Seção status com ícone de exclusão
        SizedBox(
          width: statusWidth,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppDesignSystem.errorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  border: Border.all(color: AppDesignSystem.error, width: 1),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppDesignSystem.error,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                'Excluído',
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context),
                  color: AppDesignSystem.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: spacing),

        // Quantidade de itens
        SizedBox(
          width: dateWidth,
          child: Text(
            '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
            style: TextStyle(
              fontSize: Responsive.smallFontSize(context),
              color: AppDesignSystem.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Número da nota
        Expanded(
          child: Text(
            'Nº. $numeroNota',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: Responsive.bodyFontSize(context),
              color: AppDesignSystem.neutral800,
            ),
          ),
        ),

        // Valor total
        SizedBox(
          width: priceWidth,
          child: Text(
            'R\$ ${totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: AppDesignSystem.neutral800,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: spacing),

        // Espaço vazio para coluna UF
        const SizedBox(width: ufWidth),
        const SizedBox(width: spacing),

        // Ícone expandir/colapsar
        SizedBox(
          width: actionsWidth,
          child: Center(
            child: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppDesignSystem.neutral600,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventarioItem(BuildContext context, Inventario item) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: AppDesignSystem.spacing12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppDesignSystem.neutral200, width: 1),
        ),
      ),
      child: Responsive.isMobile(context)
          ? _buildMobileInventarioItem(context, item)
          : _buildDesktopInventarioItem(context, item),
    );
  }

  Widget _buildMobileInventarioItem(BuildContext context, Inventario item) {
    final statusColor = _getStatusColor(item.estado);
    final notaFiscal = _notasFiscaisMap[item.notaFiscalId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: status e ações
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Status
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                ),
                const SizedBox(width: AppDesignSystem.spacing8),
                Text(
                  item.estado,
                  style: TextStyle(
                    fontSize: Responsive.smallFontSize(context),
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Ações
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  onPressed: () => _viewItem(item),
                  tooltip: 'Visualizar',
                ),
                _buildActionButton(
                  icon: Icons.restore,
                  onPressed: () => _restoreItem(item),
                  tooltip: 'Restaurar',
                  isRestore: true,
                ),
                _buildActionButton(
                  icon: Icons.delete_forever_outlined,
                  onPressed: () => _permanentlyDelete(context, item),
                  tooltip: 'Excluir permanentemente',
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppDesignSystem.spacing8),

        // Nome do produto
        Text(
          item.produto,
          style: TextStyle(
            fontSize: Responsive.largeFontSize(context),
            fontWeight: FontWeight.w600,
            color: AppDesignSystem.neutral800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppDesignSystem.spacing8),

        // Linha inferior: data, preço, UF e descrição
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notaFiscal != null)
                    Text(
                      'Compra: ${notaFiscal.dataCompra.day.toString().padLeft(2, '0')}/${notaFiscal.dataCompra.month.toString().padLeft(2, '0')}/${notaFiscal.dataCompra.year}',
                      style: TextStyle(
                        fontSize: Responsive.smallFontSize(context),
                        color: AppDesignSystem.neutral500,
                      ),
                    ),
                  if (item.numeroDeSerie != null &&
                      item.numeroDeSerie!.isNotEmpty)
                    Text(
                      'S/N: ${item.numeroDeSerie}',
                      style: TextStyle(
                        fontSize: Responsive.smallFontSize(context),
                        color: AppDesignSystem.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Row(
              children: [
                // Badge de UF
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing8,
                    vertical: AppDesignSystem.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: item.uf == 'CE'
                        ? AppDesignSystem.successLight
                        : AppDesignSystem.neutral100,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Text(
                    item.uf,
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: item.uf == 'CE'
                          ? AppDesignSystem.success
                          : AppDesignSystem.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacing8),
                // Preço
                Text(
                  'R\$ ${item.valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: Responsive.bodyFontSize(context),
                    color: AppDesignSystem.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopInventarioItem(BuildContext context, Inventario item) {
    const double statusWidth = 80.0;
    const double dateWidth = 120.0;
    const double priceWidth = 120.0;
    const double ufWidth = 50.0;
    const double actionsWidth = 120.0;
    const double spacing = AppDesignSystem.spacing16;

    final notaFiscal = _notasFiscaisMap[item.notaFiscalId];

    return Row(
      children: [
        // Coluna: status
        SizedBox(width: statusWidth, child: _buildStatusCell(item)),
        const SizedBox(width: spacing),

        // Coluna: data
        SizedBox(
          width: dateWidth,
          child: Text(
            notaFiscal != null
                ? '${notaFiscal.dataCompra.day.toString().padLeft(2, '0')}/${notaFiscal.dataCompra.month.toString().padLeft(2, '0')}/${notaFiscal.dataCompra.year}'
                : 'N/A',
            style: TextStyle(
              fontSize: Responsive.smallFontSize(context),
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),

        // Coluna: produto (flexível)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.produto,
                style: TextStyle(
                  fontSize: Responsive.largeFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppDesignSystem.neutral800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (item.numeroDeSerie != null && item.numeroDeSerie!.isNotEmpty)
                Text(
                  'S/N: ${item.numeroDeSerie}',
                  style: TextStyle(
                    fontSize: Responsive.smallFontSize(context),
                    color: AppDesignSystem.neutral500,
                  ),
                ),
            ],
          ),
        ),

        // Coluna: preço
        SizedBox(
          width: priceWidth,
          child: Text(
            'R\$ ${item.valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: AppDesignSystem.neutral600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: spacing),

        // Coluna: UF
        SizedBox(
          width: ufWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing8,
              vertical: AppDesignSystem.spacing4,
            ),
            decoration: BoxDecoration(
              color: item.uf == 'CE'
                  ? AppDesignSystem.successLight
                  : AppDesignSystem.neutral100,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: Text(
              item.uf,
              style: TextStyle(
                fontSize: Responsive.smallFontSize(context),
                color: item.uf == 'CE'
                    ? AppDesignSystem.success
                    : AppDesignSystem.neutral600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: spacing),

        // Coluna: ações
        SizedBox(
          width: actionsWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.visibility_outlined,
                onPressed: () => _viewItem(item),
                tooltip: 'Visualizar',
              ),
              _buildActionButton(
                icon: Icons.restore,
                onPressed: () => _restoreItem(item),
                tooltip: 'Restaurar',
                isRestore: true,
              ),
              _buildActionButton(
                icon: Icons.delete_forever_outlined,
                onPressed: () => _permanentlyDelete(context, item),
                tooltip: 'Excluir permanentemente',
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCell(Inventario item) {
    final statusColor = _getStatusColor(item.estado);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDesignSystem.spacing4),
        Expanded(
          child: Text(
            item.estado,
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isDestructive = false,
    bool isRestore = false,
  }) {
    Color iconColor = AppDesignSystem.neutral600;
    if (isDestructive) iconColor = AppDesignSystem.error;
    if (isRestore) iconColor = AppDesignSystem.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Presente':
        return AppDesignSystem.success;
      case 'Ausente':
        return AppDesignSystem.error;
      default:
        return AppDesignSystem.neutral400;
    }
  }
}
