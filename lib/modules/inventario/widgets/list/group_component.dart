// Componentes de grupo da lista (v2)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/database_helper_inventario.dart';
import '../../../../core/utilities/shared/responsive.dart';
import '../../../../models/inventario.dart';
import '../../../../models/nota_fiscal.dart';

import '../../../../core/visuals/snackbar.dart';
import 'table_component.dart';

class InventarioGroupComponents {
  static final _dateFormat = DateFormat('dd-MM-yyyy');

  static Widget buildInventarioGroup(
    BuildContext context,
    String notaFiscalId,
    NotaFiscal? notaFiscal,
    List<Inventario> items,
    bool isExpanded,
    bool isLoading,
    int groupIndex,
    VoidCallback onToggleExpansion,
    Function(Inventario)? onViewInventario,
    Function(Inventario)? onEditInventario,
    Function(String, String)? onDeleteInventario,
    VoidCallback? onDataChanged, {
    String? userUf,
    bool isAdmin = false,
    bool useAlternatingColors = true,
  }) {
    final backgroundColor = useAlternatingColors
        ? (groupIndex.isEven ? Colors.white : const Color(0xFFF5F5F7))
        : Colors.white;

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide.none,
      ),
      child: Column(
        children: [
          buildGroupHeader(
            context,
            notaFiscalId,
            notaFiscal,
            items,
            isExpanded,
            onToggleExpansion,
            backgroundColor,
          ),
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Carregando ${items.length} ${items.length == 1 ? 'item' : 'itens'}...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isExpanded)
            ...items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;

              final itemBackgroundColor = itemIndex.isEven
                  ? backgroundColor
                  : (backgroundColor == Colors.white
                        ? const Color(0xFFF9F9F9)
                        : const Color(0xFFF1F1F3));

              return RepaintBoundary(
                key: ValueKey('item_${item.id}'),
                child: buildInventarioItem(
                  context,
                  item,
                  notaFiscal,
                  onViewInventario,
                  onEditInventario,
                  onDeleteInventario,
                  onDataChanged,
                  userUf: userUf,
                  isAdmin: isAdmin,
                  backgroundColor: itemBackgroundColor,
                ),
              );
            }),
        ],
      ),
    );
  }

  static Widget buildGroupHeader(
    BuildContext context,
    String notaFiscalId,
    NotaFiscal? notaFiscal,
    List<Inventario> items,
    bool isExpanded,
    VoidCallback onToggleExpansion,
    Color backgroundColor,
  ) {
    final totalValue = items.fold<double>(0, (sum, i) => sum + i.valor);
    final numeroNota = notaFiscal?.numeroNota ?? 'NF não encontrada';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: 14.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleExpansion,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Responsive.isMobile(context)
                ? buildMobileGroupHeader(
                    context,
                    numeroNota,
                    notaFiscal,
                    items,
                    totalValue,
                    isExpanded,
                  )
                : buildDesktopGroupHeader(
                    context,
                    numeroNota,
                    notaFiscal,
                    items,
                    totalValue,
                    isExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  static Widget buildMobileGroupHeader(
    BuildContext context,
    String numeroNota,
    NotaFiscal? notaFiscal,
    List<Inventario> items,
    double totalValue,
    bool isExpanded,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: const Icon(
            Icons.folder_outlined,
            size: 16,
            color: Color(0xFF1E5EA4),
          ),
        ),
        const SizedBox(width: 12),
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
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R\$ ${totalValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey.shade600,
          size: 20,
        ),
      ],
    );
  }

  static Widget buildDesktopGroupHeader(
    BuildContext context,
    String numeroNota,
    NotaFiscal? notaFiscal,
    List<Inventario> items,
    double totalValue,
    bool isExpanded,
  ) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 16,
                color: Color(0xFF1E5EA4),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nº. $numeroNota',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.bodyFontSize(context),
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        const SizedBox(width: InventarioTableComponents.spacing),

        SizedBox(
          width: InventarioTableComponents.dateWidth,
          child: Text(
            '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
            style: TextStyle(
              fontSize: Responsive.smallFontSize(context),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Expanded(child: Container()),

        SizedBox(
          width: InventarioTableComponents.priceWidth,
          child: Text(
            'R\$ ${totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),

        const SizedBox(width: InventarioTableComponents.spacing),

        const SizedBox(width: InventarioTableComponents.ufWidth),

        const SizedBox(width: InventarioTableComponents.spacing),

        SizedBox(
          width: InventarioTableComponents.actionsWidth,
          child: Center(
            child: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildInventarioItem(
    BuildContext context,
    Inventario inventario,
    NotaFiscal? notaFiscal,
    Function(Inventario)? onViewInventario,
    Function(Inventario)? onEditInventario,
    Function(String, String)? onDeleteInventario,
    VoidCallback? onDataChanged, {
    String? userUf,
    bool isAdmin = false,
    Color? backgroundColor,
  }) {
    final statusColor = InventarioTableComponents.getStatusColor(
      inventario.estado,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Responsive.isMobile(context)
          ? buildMobileInventarioItem(
              context,
              inventario,
              notaFiscal,
              statusColor,
              onViewInventario,
              onEditInventario,
              onDeleteInventario,
              onDataChanged,
              userUf: userUf,
              isAdmin: isAdmin,
            )
          : InventarioTableComponents.buildDesktopTableRow(
              context: context,
              inventario: inventario,
              notaFiscal: notaFiscal,
              onViewInventario: onViewInventario,
              onEditInventario: onEditInventario,
              onDeleteInventario: onDeleteInventario,
              onDataChanged: onDataChanged,
              userUf: userUf,
              isAdmin: isAdmin,
            ),
    );
  }

  static Widget buildMobileInventarioItem(
    BuildContext context,
    Inventario inventario,
    NotaFiscal? notaFiscal,
    Color statusColor,
    Function(Inventario)? onViewInventario,
    Function(Inventario)? onEditInventario,
    Function(String, String)? onDeleteInventario,
    VoidCallback? onDataChanged, {
    String? userUf,
    bool isAdmin = false,
  }) {
    // Permissões: admin edita tudo; usuário só edita pela sua UF
    final canEdit = isAdmin || (userUf == inventario.uf);
    final dataCompra = notaFiscal != null
        ? _dateFormat.format(notaFiscal.dataCompra)
        : 'Data não disponível';

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
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  inventario.estado,
                  style: TextStyle(
                    fontSize: 12,
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
                InventarioTableComponents.buildActionButton(
                  icon: Icons.visibility_outlined,
                  onPressed: () => onViewInventario?.call(inventario),
                  tooltip: 'Visualizar',
                ),
                if (canEdit) ...[
                  InventarioTableComponents.buildActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: () => onEditInventario?.call(inventario),
                    tooltip: 'Editar',
                  ),
                  InventarioTableComponents.buildActionButton(
                    icon: Icons.delete_outline,
                    onPressed: () => onDeleteInventario?.call(
                      inventario.id!,
                      inventario.notaFiscalId,
                    ),
                    tooltip: 'Excluir',
                    isDestructive: true,
                  ),
                  InventarioTableComponents.buildActionButton(
                    icon: Icons.content_copy_outlined,
                    onPressed: () => _duplicateInventario(
                      context,
                      inventario,
                      onDataChanged,
                    ),
                    tooltip: 'Duplicar',
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Nome do produto
        Text(
          inventario.produto,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Linha inferior: data, preço, UF e descrição
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compra: $dataCompra',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (inventario.descricao.isNotEmpty)
                    Text(
                      inventario.descricao,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: inventario.uf == 'CE'
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    inventario.uf,
                    style: TextStyle(
                      fontSize: 12,
                      color: inventario.uf == 'CE'
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Preço
                Text(
                  'R\$ ${inventario.valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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

  // Função auxiliar: duplicar inventário
  static void _duplicateInventario(
    BuildContext context,
    Inventario inventario,
    VoidCallback? onDataChanged,
  ) async {
    try {
      // Usa duplicateInventario do helper de BD
      final dbHelper = DatabaseHelperInventario();
      await dbHelper.duplicateInventario(inventario);

      // Mostrar mensagem de sucesso
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'Item duplicado com sucesso!');
      }

      // Atualizar dados
      onDataChanged?.call();
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Erro ao duplicar item: $e');
      }
    }
  }
}
