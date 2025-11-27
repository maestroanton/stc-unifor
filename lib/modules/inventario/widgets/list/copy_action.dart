// Diálogo: duplicar inventário (v2)
import 'package:flutter/material.dart';
import '../../../../helpers/database_id_interno.dart';
import '../../../../models/inventario.dart';

class CopyInventarioDialog extends StatefulWidget {
  final Inventario original;

  const CopyInventarioDialog({super.key, required this.original});

  @override
  State<CopyInventarioDialog> createState() => CopyInventarioDialogState();
}

class CopyInventarioDialogState extends State<CopyInventarioDialog> {
  late TextEditingController _valorController;
  late TextEditingController _produtoController;
  late TextEditingController _utilidadeController;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(
      text: widget.original.valor.toString(),
    );
    _produtoController = TextEditingController(text: widget.original.produto);
    _utilidadeController = TextEditingController(
      text: widget.original.descricao,
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _produtoController.dispose();
    _utilidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5EA4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.plagiarism_outlined,
                      color: Color(0xFF1E5EA4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duplicar Inventário',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nota Fiscal ID: ${widget.original.notaFiscalId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto informativo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade100, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ajuste os campos abaixo para criar uma cópia do item.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Campos do formulário
                  _buildFormField(
                    label: 'Valor',
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    icon: Icons.attach_money,
                  ),

                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Produto',
                    controller: _produtoController,
                    icon: Icons.precision_manufacturing_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Descrição',
                    controller: _utilidadeController,
                    icon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Ações
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botão Cancelar
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.pop(context, null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botão Duplicar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5EA4),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E5EA4).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          int? internalId = widget.original.internalId;
                          internalId = await getNextInventarioInternalId();
                          final valor =
                              double.tryParse(
                                _valorController.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          // mantém notaFiscalId original
                          final inventario = Inventario(
                            id: null,
                            notaFiscalId: widget.original.notaFiscalId,
                            valor: valor,
                            dataDeGarantia: widget.original.dataDeGarantia,
                            produto: _produtoController.text,
                            descricao: _utilidadeController.text,
                            estado: widget.original.estado,
                            tipo: widget.original.tipo,
                            uf: widget.original.uf,
                            internalId: internalId,
                            numeroDeSerie: widget.original.numeroDeSerie,
                            localizacao: widget.original.localizacao,
                            observacoes: widget.original.observacoes,
                          );
                          if (context.mounted) {
                            Navigator.pop(context, inventario);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.plagiarism_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Duplicar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
