// Utilitários do dashboard de Inventário
import 'package:intl/intl.dart';

import '../../../models/inventario.dart';
import '../../../models/nota_fiscal.dart';

class InventarioDashboardUtils {
  /// Cria filtros para os tipos de cartão ao clicar
  static Map<String, dynamic> createFilterForCardType(String cardType) {
    switch (cardType) {
      case 'total':
        return {}; // Sem filtro - mostra todos os itens
      case 'totalNotas':
        return {}; // Sem filtro - mostra todas as notas fiscais
      case 'presente':
        return {'estado': 'Presente'};
      case 'ausente':
        return {'estado': 'Ausente'};
      case 'valorTotal':
        return {}; // Sem filtro - mostra todos os itens (valor total)
      case 'valorAlto':
        return {'valorMin': '1000'}; // Itens de alto valor
      case 'semSerie':
        return {
          'valorMin': '1000',
          'hasInvalidSerial': true,
        }; // Sem número de série
      case 'garantiaVencendo':
        return {'garantiaExpiringSoon': true};
      default:
        return {};
    }
  }

  /// Calcula crescimento mensal para Notas Fiscais
  static Map<String, dynamic> calculateMonthlyGrowth(
    List<NotaFiscal> notasFiscais,
  ) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    final currentMonthNotas = notasFiscais.where((nf) {
      return nf.dataCompra.year == currentMonth.year &&
          nf.dataCompra.month == currentMonth.month;
    }).length;

    final previousMonthNotas = notasFiscais.where((nf) {
      return nf.dataCompra.year == previousMonth.year &&
          nf.dataCompra.month == previousMonth.month;
    }).length;

    final absoluteChange = currentMonthNotas - previousMonthNotas;
    final innerPercentage = currentMonthNotas > 0 ? 100.0 : 0.0;
    final percentageChange = previousMonthNotas == 0
        ? innerPercentage
        : (absoluteChange / previousMonthNotas) * 100;

    return {
      'currentMonth': currentMonthNotas,
      'previousMonth': previousMonthNotas,
      'absoluteChange': absoluteChange,
      'percentageChange': percentageChange,
      'isPositive': absoluteChange > 0,
    };
  }

  /// Retorna itens com garantia expirada em até 30 dias
  static List<Inventario> getItemsWithExpiringWarranty(
    List<Inventario> inventarios,
  ) {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    return inventarios.where((inv) {
      if (inv.dataDeGarantia == null || inv.dataDeGarantia!.isEmpty) {
        return false;
      }

      try {
        final warrantyDate = _parseDate(inv.dataDeGarantia!);
        return warrantyDate.isBefore(thirtyDaysFromNow) &&
            warrantyDate.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Itens de alto valor sem número de série válido
  static List<Inventario> getHighValueItemsWithoutSerial(
    List<Inventario> inventarios,
  ) {
    return inventarios.where((inv) {
      final isHighValue = inv.valor >= 1000;
      final hasInvalidSerial =
          inv.numeroDeSerie == null ||
          inv.numeroDeSerie!.trim().isEmpty ||
          inv.numeroDeSerie!.trim().toLowerCase() == 'n/a' ||
          inv.numeroDeSerie!.trim().toLowerCase() == 'não aplicável';
      return isHighValue && hasInvalidSerial;
    }).toList();
  }

  /// Distribuição de itens por tipo
  static Map<String, int> getItemsByType(List<Inventario> inventarios) {
    final Map<String, int> typeCount = {};

    for (final inv in inventarios) {
      typeCount[inv.tipo] = (typeCount[inv.tipo] ?? 0) + 1;
    }

    return typeCount;
  }

  /// Distribuição de itens por UF
  static Map<String, int> getItemsByUF(List<Inventario> inventarios) {
    final Map<String, int> ufCount = {};

    for (final inv in inventarios) {
      ufCount[inv.uf] = (ufCount[inv.uf] ?? 0) + 1;
    }

    return ufCount;
  }

  /// Formata valores monetários para exibição
  static String formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  /// Retorna nome do mês em português
  static String getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  /// Analisa strings de data (vários formatos)
  static DateTime _parseDate(String dateStr) {
    try {
      // Tenta formato ISO primeiro (yyyy-MM-dd)
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Tenta dd-MM-yyyy
        return DateFormat('dd-MM-yyyy').parse(dateStr);
      } catch (_) {
        // Retorna data atual como fallback
        return DateTime.now();
      }
    }
  }

  /// Parse de data público
  static DateTime parseDate(String dateStr) => _parseDate(dateStr);

  /// Retorna principais fornecedores por número de Notas Fiscais
  static Map<String, int> getTopSuppliers(
    List<NotaFiscal> notasFiscais, {
    int limit = 5,
  }) {
    final Map<String, int> supplierCount = {};

    for (final nf in notasFiscais) {
      supplierCount[nf.fornecedor] = (supplierCount[nf.fornecedor] ?? 0) + 1;
    }

    // Ordena por quantidade e retorna os N principais
    final sortedEntries = supplierCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(limit));
  }

  /// Retorna valor total por fornecedor
  static Map<String, double> getValueBySupplier(List<NotaFiscal> notasFiscais) {
    final Map<String, double> supplierValue = {};

    for (final nf in notasFiscais) {
      supplierValue[nf.fornecedor] =
          (supplierValue[nf.fornecedor] ?? 0) + nf.valorTotal;
    }

    return supplierValue;
  }

  /// Retorna a NotaFiscal com mais itens
  static NotaFiscal? getNotaWithMostItems(
    List<NotaFiscal> notasFiscais,
    Map<String, int> notaItemCounts,
  ) {
    if (notasFiscais.isEmpty) return null;

    String? maxNotaId;
    int maxCount = 0;

    notaItemCounts.forEach((notaId, count) {
      if (count > maxCount) {
        maxCount = count;
        maxNotaId = notaId;
      }
    });

    if (maxNotaId == null) return null;

    return notasFiscais.firstWhere(
      (nf) => nf.id == maxNotaId,
      orElse: () => notasFiscais.first,
    );
  }

  /// Formata data para exibição
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formata data curta para exibição
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }
}
