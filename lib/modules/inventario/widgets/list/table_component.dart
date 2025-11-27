// Componentes da tabela da lista (v2)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/database_helper_inventario.dart';
import '../../../../core/utilities/shared/responsive.dart';
import '../../../../models/inventario.dart';
import '../../../../models/nota_fiscal.dart';
import '../../../../core/visuals/snackbar.dart';
import 'copy_action.dart';

class InventarioTableComponents {
  static const double statusWidth = 80.0;
  static const double dateWidth = 120.0;
  static const double priceWidth = 120.0;
  static const double ufWidth = 50.0;
  static const double actionsWidth = 120.0;
  static const double spacing = 16.0;

  static final _dateFormat = DateFormat('dd-MM-yyyy');

  static final Map<String, Color> _statusColorCache = {
    'Presente': Colors.green,
    'Ausente': Colors.red,
  };

  // Construir cabeçalho da tabela
  static Widget buildTableHeader(
    BuildContext context,
    Function(String, String, TextAlign) buildSortButton,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context).horizontal,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Responsive.isMobile(context)
          ? buildMobileHeader(buildSortButton)
          : buildDesktopTableRow(
              context: context,
              isHeader: true,
              buildSortButton: buildSortButton,
            ),
    );
  }

  static Widget buildMobileHeader(
    Function(String, String, TextAlign) buildSortButton,
  ) {
    return Row(
      children: [
        Expanded(child: buildSortButton('Produto', 'produto', TextAlign.start)),
        const SizedBox(width: 8.0),
        buildSortButton('Status', 'estado', TextAlign.start),
        const SizedBox(width: 8.0),
        buildSortButton('Preço', 'valor', TextAlign.start),
        const SizedBox(width: 8.0),
        buildSortButton('UF', 'uf', TextAlign.start),
      ],
    );
  }

  // Construir linha da tabela (desktop) - cabeçalho ou dados
  static Widget buildDesktopTableRow({
    required BuildContext context,
    bool isHeader = false,
    Inventario? inventario,
    NotaFiscal? notaFiscal,
    Function(String, String, TextAlign)? buildSortButton,
    Function(Inventario)? onViewInventario,
    Function(Inventario)? onEditInventario,
    Function(String, String)? onDeleteInventario,
    VoidCallback? onDataChanged,
    String? userUf,
    bool isAdmin = false,
  }) {
    return Row(
      children: [
        // Coluna: status
        SizedBox(
          width: statusWidth,
          child: isHeader
              ? buildSortButton!('Status', 'estado', TextAlign.start)
              : buildStatusCell(inventario!),
        ),
        const SizedBox(width: spacing),

        // Coluna: data
        SizedBox(
          width: dateWidth,
          child: isHeader
              ? buildSortButton!(
                  'Data da compra',
                  'dataDeCompra',
                  TextAlign.start,
                )
              : buildDateCell(notaFiscal),
        ),

        // Coluna: produto (flexível)
        Expanded(
          child: isHeader
              ? buildSortButton!('Produto', 'produto', TextAlign.start)
              : buildProductCell(inventario!),
        ),

        // Coluna: preço
        SizedBox(
          width: priceWidth,
          child: isHeader
              ? buildSortButton!('Preço', 'valor', TextAlign.end)
              : buildPriceCell(inventario!),
        ),
        const SizedBox(width: spacing),

        // Coluna: UF
        SizedBox(
          width: ufWidth,
          child: isHeader
              ? buildSortButton!('UF', 'uf', TextAlign.center)
              : buildUfCell(inventario!),
        ),
        const SizedBox(width: spacing),

        // Coluna: ações
        SizedBox(
          width: actionsWidth,
          child: isHeader
              ? Text(
                  'Ações',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                )
              : buildActionsCell(
                  context,
                  inventario!,
                  onViewInventario,
                  onEditInventario,
                  onDeleteInventario,
                  onDataChanged,
                  userUf: userUf,
                  isAdmin: isAdmin,
                ),
        ),
      ],
    );
  }

  static Widget buildStatusCell(Inventario inventario) {
    final statusColor = getStatusColor(inventario.estado);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            inventario.estado,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget buildDateCell(NotaFiscal? notaFiscal) {
    final dateText = notaFiscal != null
        ? _dateFormat.format(notaFiscal.dataCompra)
        : 'N/A';
    return Text(
      dateText,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
    );
  }

  static Widget buildProductCell(Inventario inventario) {
    return Text(
      inventario.produto,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget buildPriceCell(Inventario inventario) {
    return Text(
      'R\$ ${inventario.valor.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.end,
    );
  }

  static Widget buildUfCell(Inventario inventario) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget buildActionsCell(
    BuildContext context,
    Inventario inventario,
    Function(Inventario)? onViewInventario,
    Function(Inventario)? onEditInventario,
    Function(String, String)? onDeleteInventario,
    VoidCallback? onDataChanged, {
    String? userUf,
    bool isAdmin = false,
  }) {
    // Permissões: admin edita tudo; usuário edita apenas sua UF
    final canEdit = isAdmin || (userUf == inventario.uf);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildActionButton(
          icon: Icons.visibility_outlined,
          onPressed: () => onViewInventario?.call(inventario),
          tooltip: 'Visualizar',
        ),
        if (canEdit) ...[
          buildActionButton(
            icon: Icons.edit_outlined,
            onPressed: () => onEditInventario?.call(inventario),
            tooltip: 'Editar',
          ),
          buildActionButton(
            icon: Icons.delete_outline,
            onPressed: () => onDeleteInventario?.call(
              inventario.id!,
              inventario.notaFiscalId,
            ),
            tooltip: 'Excluir',
            isDestructive: true,
          ),
          buildActionButton(
            icon: Icons.plagiarism_outlined,
            onPressed: () async {
              final copied = await showDialog<Inventario>(
                context: context,
                builder: (_) => CopyInventarioDialog(original: inventario),
              );
              if (copied != null) {
                await DatabaseHelperInventario().insertInventario(copied);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(
                    context,
                    'Item duplicado com sucesso!',
                  );
                  onDataChanged?.call();
                }
              }
            },
            tooltip: 'Duplicar',
          ),
        ],
      ],
    );
  }

  static Widget buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  static Color getStatusColor(String estado) {
    return _statusColorCache[estado] ?? Colors.grey;
  }
}
