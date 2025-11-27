// lib/modules/inventario_v2/search_config.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/utilities/search/generic_search_page.dart';
import '../../core/design_system.dart';
import '../../core/base_page.dart';
import '../../helpers/database_helper_inventario.dart';
import '../../core/utilities/shared/object_uppercase.dart';
import '../../core/utilities/excel/inventario_excel.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';
import 'services/filter_service.dart';

class InventarioV2SearchConfig extends SearchConfig<Inventario> {
  // Cache estático de NotasFiscais (mantém o mapa ao voltar da view)
  static Map<String, NotaFiscal> _notasFiscaisMap = {};

  @override
  String get pageTitle => 'Pesquisar Inventário';

  @override
  IconData get pageIcon => Icons.inventory_2_outlined;

  @override
  String get emptyMessage => 'Nenhum item encontrado';

  @override
  String get quickSearchHint =>
      'Digite qualquer coisa: nota, produto, descrição, fornecedor...';

  @override
  List<SearchField> get searchFields => [
    SearchField(
      key: 'nota',
      label: 'Número da Nota',
      type: SearchFieldType.text,
      hint: 'Ex: 123.456.789',
      keyboardType: TextInputType.number,
      formatters: [
        MaskTextInputFormatter(
          mask: '###.###.###',
          filter: {"#": RegExp(r'[0-9]')},
        ),
      ],
    ),
    const SearchField(
      key: 'internalId',
      label: 'ID Interno',
      type: SearchFieldType.number,
      hint: 'ID interno do item',
      keyboardType: TextInputType.number,
    ),
    const SearchField(
      key: 'produto',
      label: 'Produto',
      type: SearchFieldType.text,
      hint: 'Nome do produto',
    ),
    SearchField(
      key: 'numeroDeSerie',
      label: 'Número de Série',
      type: SearchFieldType.text,
      hint: 'Número de série do produto',
      formatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
        UpperCaseTextFormatter(),
      ],
    ),
    const SearchField(
      key: 'descricao',
      label: 'Descrição',
      type: SearchFieldType.text,
      hint: 'Descrição do produto',
    ),
    const SearchField(
      key: 'valor',
      label: 'Valor',
      type: SearchFieldType.range,
      hint: 'R\$ 0,00',
      keyboardType: TextInputType.number,
    ),
    const SearchField(
      key: 'fornecedor',
      label: 'Fornecedor',
      type: SearchFieldType.text,
      hint: 'Nome do fornecedor',
    ),
    const SearchField(
      key: 'estado',
      label: 'Estado',
      type: SearchFieldType.dropdown,
      options: ['Presente', 'Ausente'],
    ),
    const SearchField(
      key: 'tipo',
      label: 'Tipo',
      type: SearchFieldType.dropdown,
      options: [
        'Equipamentos de Escritório',
        'Móveis, Eletrodomésticos e Estrutura',
        'Ferramentas Manuais',
        'Veículos e Transporte',
        'Componentes e Peças',
        'Material de Consumo',
        'Outros',
      ],
    ),
    const SearchField(
      key: 'uf',
      label: 'UF',
      type: SearchFieldType.dropdown,
      options: ['CE', 'SP'],
    ),
    const SearchField(
      key: 'dateField',
      label: 'Campo de Data',
      type: SearchFieldType.dropdown,
      options: ['Data de Compra', 'Data de Garantia'],
    ),
    const SearchField(
      key: 'dataInicio',
      label: 'Data Início',
      type: SearchFieldType.date,
    ),
    const SearchField(
      key: 'dataFim',
      label: 'Data Fim',
      type: SearchFieldType.date,
    ),
  ];

  @override
  List<TableColumn> get tableColumns => const [
    TableColumn(title: 'Nota', flex: 2),
    TableColumn(title: 'Produto', flex: 3),
    TableColumn(title: 'Estado', flex: 2),
    TableColumn(title: 'Valor', flex: 2),
    TableColumn(title: 'UF', flex: 1),
    TableColumn(title: 'Data Compra', flex: 2),
  ];

  @override
  Future<List<Inventario>> getAllItems() async {
    final dbHelper = DatabaseHelperInventario();

    // Carregar todos os inventários
    final inventarios = await dbHelper.getInventarios();

    // Carregar notas fiscais e montar mapa
    final notasFiscais = await dbHelper.getAllNotasFiscais();
    _notasFiscaisMap = {
      for (var nota in notasFiscais)
        if (nota.id != null) nota.id!: nota,
    };

    return inventarios;
  }

  @override
  List<Inventario> performQuickSearch(List<Inventario> items, String query) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();

    return items.where((inventario) {
      // Obter NotaFiscal associada para busca
      final notaFiscal = _notasFiscaisMap[inventario.notaFiscalId];

      final searchableText = [
        notaFiscal?.numeroNota ?? '',
        notaFiscal?.fornecedor ?? '',
        inventario.produto,
        inventario.descricao,
        inventario.numeroDeSerie ?? '',
        inventario.internalId?.toString() ?? '',
        inventario.estado,
        inventario.tipo,
        inventario.uf,
        inventario.localizacao ?? '',
        inventario.valor.toString(),
        notaFiscal != null
            ? DateFormat('dd/MM/yyyy').format(notaFiscal.dataCompra)
            : '',
        inventario.dataDeGarantia ?? '',
      ].join(' ').toLowerCase();

      return searchableText.contains(lowerQuery);
    }).toList();
  }

  // Parser para datas no formato dd/MM/yyyy
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) return null;

    try {
      // Trata o formato dd/MM/yyyy
      final parts = dateString.trim().split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          // Validação básica
          if (day >= 1 &&
              day <= 31 &&
              month >= 1 &&
              month <= 12 &&
              year >= 1900) {
            try {
              return DateTime(year, month, day);
            } catch (e) {
              // Data inválida (ex: 30/02)
              return null;
            }
          }
        }
      }

      // Caso contrário, tentar parse padrão
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Inventario> applyAdvancedFilters(
    List<Inventario> items,
    Map<String, dynamic> filters,
  ) {
    // Converte filtros de data (string) para DateTime, conforme InventarioFilterService
    final modifiedFilters = Map<String, dynamic>.from(filters);

    // dataInicio -> startDate
    if (filters.containsKey('dataInicio') &&
        filters['dataInicio'] != null &&
        filters['dataInicio'].toString().trim().isNotEmpty) {
      final startDate = _parseDate(filters['dataInicio'].toString());
      if (startDate != null) {
        modifiedFilters['startDate'] = startDate;
      }
    }

    // dataFim -> endDate
    if (filters.containsKey('dataFim') &&
        filters['dataFim'] != null &&
        filters['dataFim'].toString().trim().isNotEmpty) {
      final endDate = _parseDate(filters['dataFim'].toString());
      if (endDate != null) {
        modifiedFilters['endDate'] = endDate;
      }
    }

    return InventarioFilterService.applyFilters(
      items,
      modifiedFilters,
      _notasFiscaisMap,
    );
  }

  @override
  Future<void> exportToExcel(
    BuildContext context,
    List<Inventario> items,
  ) async {
    await handleInventarioV2Export(context, items, _notasFiscaisMap);
  }

  @override
  AppTableRow buildTableRow(Inventario inventario, VoidCallback onTap) {
    // Obter NotaFiscal associada
    final notaFiscal = _notasFiscaisMap[inventario.notaFiscalId];
    final notaNumber = notaFiscal?.numeroNota ?? 'N/A';
    final dataCompra = notaFiscal != null
        ? DateFormat('dd/MM/yyyy').format(notaFiscal.dataCompra)
        : '';

    return AppTableRow(
      onTap: onTap,
      cells: [
        // Nota com ícone
        Row(
          children: [
            const Icon(
              Icons.receipt_outlined,
              size: 18,
              color: AppDesignSystem.neutral500,
            ),
            const SizedBox(width: AppDesignSystem.spacing8),
            Text(
              notaNumber,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Produto
        Text(
          inventario.produto,
          style: AppDesignSystem.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Estado
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getStatusColor(inventario.estado),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing8),
            Text(
              inventario.estado,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.neutral700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),

        // Valor
        Text(
          'R\$ ${inventario.valor.toStringAsFixed(2)}',
          style: AppDesignSystem.bodyMedium.copyWith(
            color: AppDesignSystem.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),

        // UF
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: inventario.uf == 'CE'
                    ? AppDesignSystem.success.withValues(alpha: 0.1)
                    : AppDesignSystem.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                inventario.uf,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: inventario.uf == 'CE'
                      ? AppDesignSystem.success
                      : AppDesignSystem.neutral600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        // Data de Compra
        Text(
          dataCompra,
          style: AppDesignSystem.bodyMedium.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildMobileCard(Inventario inventario, VoidCallback onTap) {
    // Obter NotaFiscal associada
    final notaFiscal = _notasFiscaisMap[inventario.notaFiscalId];
    final notaNumber = notaFiscal?.numeroNota ?? 'N/A';
    final dataCompra = notaFiscal != null
        ? DateFormat('dd/MM/yyyy').format(notaFiscal.dataCompra)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
      decoration: BoxDecoration(
        color: AppDesignSystem.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing16,
              vertical: AppDesignSystem.spacing12,
            ),
            child: Column(
              children: [
                    // 1ª linha - corresponde às colunas do desktop
                Row(
                  children: [
                    // Nota com ícone (flex:2)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_outlined,
                            size: 14,
                            color: AppDesignSystem.neutral500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              notaNumber,
                              style: AppDesignSystem.bodyMedium.copyWith(
                                color: AppDesignSystem.info,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Estado (flex:2)
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _getStatusColor(inventario.estado),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            inventario.estado,
                            style: AppDesignSystem.bodyMedium.copyWith(
                              color: AppDesignSystem.neutral700,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // UF (flex:1)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: inventario.uf == 'CE'
                              ? AppDesignSystem.success.withValues(alpha: 0.1)
                              : AppDesignSystem.neutral200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          inventario.uf,
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: inventario.uf == 'CE'
                                ? AppDesignSystem.success
                                : AppDesignSystem.neutral600,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDesignSystem.spacing8),

                // 2ª linha - Produto (equiv. flex:3)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inventario.produto,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDesignSystem.spacing6),

                // 3ª linha - Valor e Data (flex:2 cada)
                Row(
                  children: [
                    // Valor (flex:2)
                    Expanded(
                      flex: 2,
                      child: Text(
                        'R\$ ${inventario.valor.toStringAsFixed(2)}',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral600,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Data de Compra (flex:2)
                    Expanded(
                      flex: 2,
                      child: Text(
                        dataCompra,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        return AppDesignSystem.neutral500;
    }
  }
}
