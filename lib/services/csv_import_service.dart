// lib/services/csv_import_service_v2.dart
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/inventario.dart';
import '../models/nota_fiscal.dart';
import '../helpers/database_helper_inventario.dart';

/// Resultado do processamento CSV
class ImportResult {
  final NotaFiscal notaFiscal;
  final List<Inventario> inventarios;

  ImportResult({required this.notaFiscal, required this.inventarios});
}

/// Serviço para processar arquivos CSV e convertê-los em NotaFiscal + itens de Inventario (v2)
class CsvImportServiceV2 {
  static const List<String> allowedExtensions = ['csv'];
  static const int maxFileSizeMB = 5;

  /// Processa dados CSV e retorna uma NotaFiscal com seus Inventarios
  static Future<ImportResult> processCsvData(
    Uint8List fileBytes,
    String fileName, {
    required String notaPrefix,
    required String uf,
  }) async {
    try {
      // Validações de segurança
      _validateFileSize(fileBytes.length);
      _validateFileName(fileName);
      _validateNotaPrefix(notaPrefix);

      // Converte bytes para string com limite de tamanho
      final csvString = utf8.decode(fileBytes);

      _validateCsvContent(csvString);

      debugPrint(
        'CSV sample: ${csvString.substring(0, csvString.length > 100 ? 100 : csvString.length)}',
      );

      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvString);

      if (csvData.isEmpty) {
        throw Exception('Arquivo CSV está vazio');
      }

      final List<Inventario> items = [];
      final DateTime now = DateTime.now();

      const String defaultEstado = 'Presente';
      const String defaultTipo = 'Equipamento';
      const String defaultFornecedor = 'Importação';

      // Usa o prefixo de nota fornecido como número da nota fiscal
      final String numeroNota = notaPrefix;

      // Verifica se o número da nota fiscal já existe
      final helper = DatabaseHelperInventario();
      final exists = await helper.notaFiscalExists(uf, numeroNota);
      if (exists) {
        throw Exception(
          'Já existe uma Nota Fiscal com o número $numeroNota para o UF $uf',
        );
      }

      double totalValue = 0.0;
      bool headerSkipped = false;

      for (int rowIndex = 1; rowIndex < csvData.length; rowIndex++) {
        final List<dynamic> row = csvData[rowIndex];

        if (row.length < 8) {
          continue;
        }

        final String item = _sanitizeString(_cleanString(row[0].toString()));
        final String codigo = _sanitizeString(_cleanString(row[1].toString()));
        final String descricao = _sanitizeString(
          _cleanString(row[2].toString()),
        );
        final String modelo = _sanitizeString(_cleanString(row[3].toString()));
        final String departamento = _sanitizeString(
          _cleanString(row[4].toString()),
        );
        final String quantidadeStr = _sanitizeString(
          _cleanString(row[5].toString()),
        );
        final String valorUnitStr = _sanitizeString(
          _cleanString(row[6].toString()),
        );
        final String origemUf = _sanitizeString(
          _cleanString(row.length > 8 ? row[8].toString() : uf),
        );

        if (!headerSkipped) {
          final itemLower = item.toLowerCase();

          final isHeaderRow = (itemLower.contains('item'));

          if (isHeaderRow) {
            headerSkipped = true;
            continue;
          }
        }

        if (codigo.isEmpty && descricao.isEmpty && valorUnitStr.isEmpty) {
          continue;
        }

        int quantidade = 1;
        try {
          if (quantidadeStr.isNotEmpty && !quantidadeStr.contains('#')) {
            quantidade = int.parse(
              quantidadeStr.replaceAll(RegExp(r'[^0-9]'), ''),
            );
            if (quantidade <= 0) quantidade = 1;
          }
        } catch (e) {
          quantidade = 1;
        }

        double valorUnitario = 0.0;
        try {
          if (valorUnitStr.contains('#')) {
            valorUnitario = 0.0;
          } else {
            final cleanValue = valorUnitStr
                .trim()
                .replaceAll('R\$', '')
                .replaceAll(' ', '')
                .replaceAll('.', '')
                .replaceAll(',', '.');

            valorUnitario = cleanValue.isNotEmpty
                ? double.parse(cleanValue)
                : 0.0;
          }
        } catch (e) {
          valorUnitario = 0.0;
        }

        final String produto = descricao.isNotEmpty
            ? descricao
            : 'Item não identificado';

        final String descricaoFinal;
        if (modelo.isNotEmpty) {
          if (quantidade > 1) {
            descricaoFinal = '$modelo ($quantidade unidades)';
          } else {
            descricaoFinal = '$modelo (1 unidade)';
          }
        } else {
          if (quantidade > 1) {
            descricaoFinal = 'Modelo não informado ($quantidade unidades)';
          } else {
            descricaoFinal = 'Modelo não informado (1 unidade)';
          }
        }

        final double valorTotal = valorUnitario * quantidade;
        totalValue += valorTotal;

        // Cria Inventario sem notaFiscalId (será definido após criação da NotaFiscal)
        items.add(
          Inventario(
            notaFiscalId: '', // Temporário - será definido no diálogo
            valor: valorTotal,
            dataDeGarantia: null,
            produto: produto,
            descricao: descricaoFinal,
            estado: defaultEstado,
            tipo: defaultTipo,
            uf: _normalizeUF(origemUf),
            numeroDeSerie: '',
            localizacao: _normalizeLocation(departamento),
          ),
        );
      }

      debugPrint('Total items processed: ${items.length}');
      if (items.isEmpty) {
        throw Exception('Nenhum item válido encontrado no arquivo CSV.');
      }

      // Cria objeto pai NotaFiscal
      final notaFiscal = NotaFiscal(
        numeroNota: numeroNota,
        fornecedor: defaultFornecedor,
        dataCompra: now,
        valorTotal: totalValue,
        uf: uf,
      );

      return ImportResult(notaFiscal: notaFiscal, inventarios: items);
    } catch (e) {
      debugPrint('CSV Processing Error: ${e.toString()}');
      throw Exception('Erro ao processar CSV: ${e.toString()}');
    }
  }

  /// Valida o arquivo CSV antes do processamento
  static String? validateCsvFile(String fileName, int fileSizeBytes) {
    if (!fileName.toLowerCase().endsWith('.csv')) {
      return 'Apenas arquivos CSV são aceitos';
    }

    if (fileSizeBytes > maxFileSizeMB * 1024 * 1024) {
      return 'Arquivo muito grande. Limite: ${maxFileSizeMB}MB';
    }

    return null;
  }

  /// Retorna estatísticas resumidas da importação
  static Map<String, dynamic> getImportSummary(
    NotaFiscal notaFiscal,
    List<Inventario> items,
  ) {
    if (items.isEmpty) {
      return {
        'totalItems': 0,
        'ufDistribution': {},
        'totalValue': 0.0,
        'averageValue': 0.0,
        'notaFiscal': notaFiscal,
      };
    }

    final Map<String, int> ufDistribution = {};
    double totalValue = 0.0;

    for (final item in items) {
      ufDistribution[item.uf] = (ufDistribution[item.uf] ?? 0) + 1;
      totalValue += item.valor;
    }

    return {
      'totalItems': items.length,
      'ufDistribution': ufDistribution,
      'totalValue': totalValue,
      'averageValue': totalValue / items.length,
      'notaFiscal': notaFiscal,
    };
  }

  /// Método auxiliar para limpar strings
  static String _cleanString(String input) {
    return input.trim();
  }

  /// Método auxiliar para normalizar UF
  static String _normalizeUF(String uf) {
    final String cleanUf = uf.toUpperCase().trim();

    if (cleanUf.contains('SP') ||
        cleanUf.contains('SÃO PAULO') ||
        cleanUf.contains('SAO PAULO') ||
        cleanUf.contains('FILIAL')) {
      return 'SP';
    }

    if (cleanUf.contains('CE') ||
        cleanUf.contains('CEARÁ') ||
        cleanUf.contains('CEARA') ||
        cleanUf.contains('FORTALEZA') ||
        cleanUf.contains('MATRIZ')) {
      return 'CE';
    }

    return 'SP';
  }

  /// Método auxiliar para normalizar nomes de localização (apenas formatação)
  static String _normalizeLocation(String location) {
    if (location.isEmpty) return 'A definir';

    String cleaned = location.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[-_\s]+|[-_\s]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';

          final upperWord = word.toUpperCase();
          if (upperWord == 'TI' ||
              upperWord == 'RH' ||
              upperWord == 'CPD' ||
              upperWord == 'CEO' ||
              upperWord == 'CFO' ||
              upperWord == 'CTO') {
            return upperWord;
          }

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static void _validateFileSize(int sizeInBytes) {
    const maxSizeBytes = maxFileSizeMB * 1024 * 1024;
    if (sizeInBytes > maxSizeBytes) {
      throw Exception(
        'Arquivo muito grande. Máximo permitido: ${maxFileSizeMB}MB',
      );
    }
  }

  static void _validateFileName(String fileName) {
    if (fileName.isEmpty) {
      throw Exception('Nome do arquivo inválido');
    }

    final dangerousPatterns = [
      '../',
      '..\\',
      '/',
      '\\',
      '<',
      '>',
      ':',
      '"',
      '|',
      '?',
      '*',
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
    ];

    final upperFileName = fileName.toUpperCase();
    for (final pattern in dangerousPatterns) {
      if (upperFileName.contains(pattern.toUpperCase())) {
        throw Exception('Nome do arquivo contém caracteres não permitidos');
      }
    }

    if (!fileName.toLowerCase().endsWith('.csv')) {
      throw Exception('Apenas arquivos CSV são permitidos');
    }
  }

  static void _validateNotaPrefix(String notaPrefix) {
    if (notaPrefix.trim().isEmpty) {
      throw Exception('Nome da importação é obrigatório');
    }

    if (notaPrefix.length > 100) {
      throw Exception('Nome da importação muito longo (máximo 100 caracteres)');
    }

    if (!RegExp(
      r'^[a-zA-Z0-9àáâãäçèéêëìíîïñòóôõöùúûüýÿ\s\-_.,()]+$',
    ).hasMatch(notaPrefix)) {
      throw Exception(
        'Nome da importação contém caracteres não permitidos. Use apenas letras, números, espaços e pontuação básica',
      );
    }
  }

  static void _validateCsvContent(String csvContent) {
    if (csvContent.isEmpty) {
      throw Exception('Arquivo CSV está vazio');
    }

    if (csvContent.length > 10 * 1024 * 1024) {
      throw Exception('Conteúdo do arquivo muito grande');
    }

    if (!RegExp(
      '^[a-zA-Z0-9áàâãçéêíóôõúüÁÀÂÃÇÉÊÍÓÔÕÚÜ\\s;,.\\-()R\$\\r\\n"/:_%#+=&\'\u201C\u201D\u2018\u2019\u2013]*\$',
    ).hasMatch(csvContent)) {
      throw Exception('Arquivo contém caracteres não permitidos');
    }

    final lines = csvContent.split('\n');
    if (lines.length > 10000) {
      throw Exception('Arquivo tem muitas linhas (máximo 10.000)');
    }
  }

  static String _sanitizeString(String input) {
    if (input.isEmpty) return input;

    String sanitized = input
        .replaceAll(
          RegExp(
            '[^a-zA-Z0-9áàâãçéêíóôõúüÁÀÂÃÇÉÊÍÓÔÕÚÜ\\s,.()R\$\\-"/:_%#\u201C\u201D\u2018\u2019\u2013]',
          ),
          '',
        )
        .trim();

    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }

    return sanitized;
  }
}
