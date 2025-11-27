import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:excel/excel.dart' as excel show Border, BorderStyle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../../models/inventario.dart';
import '../../../models/nota_fiscal.dart';
import '../../visuals/snackbar.dart';

final CellStyle titleHeaderStyle = CellStyle(
  bold: true,
  fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
  backgroundColorHex: ExcelColor.fromHexString("#1E5EA4"),
  fontFamily: 'Bahnschrift',
  fontSize: 16,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Center,
);

final CellStyle defaultStyle = CellStyle(
  fontFamily: 'Bahnschrift',
  fontSize: 10,
  horizontalAlign: HorizontalAlign.Left,
);

final CellStyle headerStyle = CellStyle(
  bold: true,
  fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
  backgroundColorHex: ExcelColor.fromHexString("#1E5EA4"),
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Center,
  fontFamily: 'Bahnschrift',
  fontSize: 10,
);

final CellStyle borderedDataStyle = CellStyle(
  fontFamily: 'Bahnschrift',
  fontSize: 10,
  backgroundColorHex: ExcelColor.fromHexString("#DDEBF7"),
  horizontalAlign: HorizontalAlign.Left,
  leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
);

final CellStyle currencyDataStyle = CellStyle(
  fontFamily: 'Bahnschrift',
  fontSize: 10,
  backgroundColorHex: ExcelColor.fromHexString("#DDEBF7"),
  horizontalAlign: HorizontalAlign.Left,
  leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
  bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
);

String _safeDate(String? input) {
  try {
    if (input == null) return '';
    final parts = input.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return '$day/$month/$year';
      }
    }
    return input;
  } catch (_) {
    return '';
  }
}

String _formatDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

void _optimizeInventarioColumnWidths(Sheet sheet) {
  const columnWidths = [
    15.0, // Nota
    12.0, // Valor
    15.0, // Data de compra
    15.0, // Data de garantia
    25.0, // Produto
    30.0, // Descrição
    15.0, // Estado
    20.0, // Fornecedor
    15.0, // Tipo
    20.0, // Localização
    8.0, // UF
  ];

  for (int col = 0; col < columnWidths.length; col++) {
    sheet.setColumnWidth(col, columnWidths[col]);
  }
}

int _addTitleHeader(Sheet sheet, String title, int startRow, int totalColumns) {
  final currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final fullTitle = '$title $currentDate';

  sheet.setRowHeight(startRow, 50);

  final titleCell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow),
  );
  titleCell
    ..value = TextCellValue(fullTitle)
    ..cellStyle = titleHeaderStyle;

  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow),
    CellIndex.indexByColumnRow(
      columnIndex: totalColumns - 1,
      rowIndex: startRow,
    ),
  );

  return startRow + 2;
}

void _applyDefaultStyling(Sheet sheet, int maxRows, int maxCols) {
  for (int row = 0; row < maxRows; row++) {
    for (int col = 0; col < maxCols; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      if (cell.cellStyle == null && (cell.value != null || row <= maxRows)) {
        cell.cellStyle = defaultStyle;
      }
    }
  }
}

Future<void> handleInventarioV2Export(
  BuildContext context,
  List<Inventario> items,
  Map<String, NotaFiscal> notasFiscaisMap,
) async {
  if (kIsWeb) {
    await exportInventariosV2ToExcelWeb(items, notasFiscaisMap);
    if (context.mounted) {
      SnackBarUtils.showSuccess(context, 'Exportado para arquivo.');
    }
  } else {
    final path = await exportInventariosV2ToExcel(items, notasFiscaisMap);
    if (context.mounted) {
      SnackBarUtils.showSuccess(context, 'Exportado para: $path');
    }
  }
}

Future<void> exportInventariosV2ToExcelWeb(
  List<Inventario> inventarios,
  Map<String, NotaFiscal> notasFiscaisMap,
) async {
  final excel = Excel.createExcel();
  final sheet = excel['Inventário'];

  int currentRow = _addTitleHeader(sheet, 'Relatório de Inventário', 0, 11);

  final header = [
    'Nota',
    'Valor',
    'Data de Compra',
    'Data de Garantia',
    'Produto',
    'Descrição',
    'Estado',
    'Fornecedor',
    'Tipo',
    'Localização',
    'UF',
  ];

  for (int col = 0; col < header.length; col++) {
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow),
      )
      ..value = TextCellValue(header[col])
      ..cellStyle = headerStyle;
  }

  currentRow++;

  _optimizeInventarioColumnWidths(sheet);

  for (int i = 0; i < inventarios.length; i++) {
    final inv = inventarios[i];
    final notaFiscal = notasFiscaisMap[inv.notaFiscalId];
    final row = currentRow + i;

    // Número da nota (proveniente da NotaFiscal)
    final notaNumber = notaFiscal?.numeroNota ?? 'N/A';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(notaNumber)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(
        'R\$ ${inv.valor.toStringAsFixed(2).replaceAll('.', ',')}',
      )
      ..cellStyle = currencyDataStyle;

    // Data de compra (proveniente da NotaFiscal)
    final dataCompra = notaFiscal != null
        ? _formatDateTime(notaFiscal.dataCompra)
        : '';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = TextCellValue(dataCompra)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
      ..value = TextCellValue(_safeDate(inv.dataDeGarantia))
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
      ..value = TextCellValue(inv.produto)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
      ..value = TextCellValue(inv.descricao)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
      ..value = TextCellValue(inv.estado)
      ..cellStyle = borderedDataStyle;

    // Fornecedor (proveniente da NotaFiscal)
    final fornecedor = notaFiscal?.fornecedor ?? '';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
      ..value = TextCellValue(fornecedor)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
      ..value = TextCellValue(inv.tipo)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
      ..value = TextCellValue(inv.localizacao ?? '')
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
      ..value = TextCellValue(inv.uf)
      ..cellStyle = borderedDataStyle;
  }

  final totalRow = currentRow + inventarios.length;
  final totalValue = inventarios.fold<double>(0, (sum, inv) => sum + inv.valor);
  final totalStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString("#000000"),
    backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    fontFamily: 'Bahnschrift',
    fontSize: 10,
  );

  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
    ..value = TextCellValue('TOTAL')
    ..cellStyle = totalStyle;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow))
    ..value = TextCellValue(
      'R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
    )
    ..cellStyle = totalStyle;

  final maxRows = totalRow + 10;
  _applyDefaultStyling(sheet, maxRows, header.length + 5);

  try {
    excel.delete('Sheet1');
  } catch (_) {}

  final excelBytes = excel.encode();

  final blob = html.Blob([
    Uint8List.fromList(excelBytes!),
  ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  final url = html.Url.createObjectUrlFromBlob(blob);

  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final filename = 'inventario_planilha_$timestamp.xlsx';

  html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<String> exportInventariosV2ToExcel(
  List<Inventario> inventarios,
  Map<String, NotaFiscal> notasFiscaisMap,
) async {
  final excel = Excel.createExcel();
  final sheet = excel['Inventário'];

  int currentRow = _addTitleHeader(sheet, 'Relatório de Inventário', 0, 11);

  final header = [
    'Nota',
    'Valor',
    'Data de Compra',
    'Data de Garantia',
    'Produto',
    'Descrição',
    'Estado',
    'Fornecedor',
    'Tipo',
    'Localização',
    'UF',
  ];

  for (int col = 0; col < header.length; col++) {
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow),
      )
      ..value = TextCellValue(header[col])
      ..cellStyle = headerStyle;
  }

  currentRow++;

  _optimizeInventarioColumnWidths(sheet);

  for (int i = 0; i < inventarios.length; i++) {
    final inv = inventarios[i];
    final notaFiscal = notasFiscaisMap[inv.notaFiscalId];
    final row = currentRow + i;

    // Número da nota (proveniente da NotaFiscal)
    final notaNumber = notaFiscal?.numeroNota ?? 'N/A';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(notaNumber)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(
        'R\$ ${inv.valor.toStringAsFixed(2).replaceAll('.', ',')}',
      )
      ..cellStyle = currencyDataStyle;

    // Data de compra (proveniente da NotaFiscal)
    final dataCompra = notaFiscal != null
        ? _formatDateTime(notaFiscal.dataCompra)
        : '';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = TextCellValue(dataCompra)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
      ..value = TextCellValue(_safeDate(inv.dataDeGarantia))
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
      ..value = TextCellValue(inv.produto)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
      ..value = TextCellValue(inv.descricao)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
      ..value = TextCellValue(inv.estado)
      ..cellStyle = borderedDataStyle;

    // Fornecedor (proveniente da NotaFiscal)
    final fornecedor = notaFiscal?.fornecedor ?? '';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
      ..value = TextCellValue(fornecedor)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
      ..value = TextCellValue(inv.tipo)
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
      ..value = TextCellValue(inv.localizacao ?? '')
      ..cellStyle = borderedDataStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
      ..value = TextCellValue(inv.uf)
      ..cellStyle = borderedDataStyle;
  }

  final totalRow = currentRow + inventarios.length;
  final totalValue = inventarios.fold<double>(0, (sum, inv) => sum + inv.valor);
  final totalStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString("#000000"),
    backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    fontFamily: 'Bahnschrift',
    fontSize: 10,
  );

  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
    ..value = TextCellValue('TOTAL')
    ..cellStyle = totalStyle;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow))
    ..value = TextCellValue(
      'R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
    )
    ..cellStyle = totalStyle;

  final maxRows = totalRow + 10;
  _applyDefaultStyling(sheet, maxRows, header.length + 5);

  try {
    excel.delete('Sheet1');
  } catch (_) {}

  final dir = await getApplicationDocumentsDirectory();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final filePath = '${dir.path}/inventario_$timestamp.xlsx';
  final fileBytes = excel.encode();

  final file = File(filePath)..createSync(recursive: true);

  await file.writeAsBytes(fileBytes!);

  return filePath;
}
