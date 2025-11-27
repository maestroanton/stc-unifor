// lib/modules/inventario_v2/services/filter_service.dart
import 'package:intl/intl.dart';
import '../../../models/inventario.dart';
import '../../../models/nota_fiscal.dart';

class InventarioFilterService {
  static final format = DateFormat('dd-MM-yyyy');

  static List<Inventario> applyFilters(
    List<Inventario> list,
    Map<String, dynamic> filters,
    Map<String, NotaFiscal> notasFiscaisMap,
  ) {
    return list.where((inv) {
      // Obter NotaFiscal associada
      final notaFiscal = notasFiscaisMap[inv.notaFiscalId];
      if (notaFiscal == null) return false; // ignora se não encontrada

      final nota = filters['nota']?.toLowerCase() ?? '';
      final produto = filters['produto']?.toLowerCase() ?? '';
      final descricao = filters['descricao']?.toLowerCase() ?? '';
      final fornecedor = filters['fornecedor']?.toLowerCase() ?? '';
      final numeroDeSerie = filters['numeroDeSerie']?.toLowerCase() ?? '';
      final internalIdStr = filters['internalId']?.trim() ?? '';

      final notaMatches =
          nota.isEmpty || notaFiscal.numeroNota.toLowerCase().contains(nota);
      final produtoMatches =
          produto.isEmpty || inv.produto.toLowerCase().contains(produto);
      final descricaoMatches =
          descricao.isEmpty || inv.descricao.toLowerCase().contains(descricao);
      final fornecedorMatches =
          fornecedor.isEmpty ||
          notaFiscal.fornecedor.toLowerCase().contains(fornecedor);
      final numeroDeSerieMatches =
          numeroDeSerie.isEmpty ||
          (inv.numeroDeSerie?.toLowerCase().contains(numeroDeSerie) ?? false);
      final internalIdMatches =
          internalIdStr.isEmpty ||
          (int.tryParse(internalIdStr) != null &&
              inv.internalId == int.tryParse(internalIdStr));

      final valor = inv.valor;
      final valorMin =
          double.tryParse(filters['valorMin'] ?? '') ?? double.negativeInfinity;
      final valorMax =
          double.tryParse(filters['valorMax'] ?? '') ?? double.infinity;
      final valorMatches = valor >= valorMin && valor <= valorMax;

      final estadoMatches =
          filters['estado'] == null ||
          inv.estado.toLowerCase() == filters['estado'].toLowerCase();
      final tipoMatches =
          filters['tipo'] == null ||
          inv.tipo.toLowerCase() == filters['tipo'].toLowerCase();

      final dateField = filters['dateField'] ?? 'Data de Compra';
      DateTime? data;

      if (dateField == 'Data de Garantia') {
        if (inv.dataDeGarantia == null || inv.dataDeGarantia!.isEmpty) {
          return false;
        }
        try {
          data = format.parse(inv.dataDeGarantia!);
        } catch (_) {
          return false;
        }
      } else {
          // Usa dataCompra da nota fiscal
        data = notaFiscal.dataCompra;
      }

      final startDate = filters['startDate'] as DateTime?;
      final endDate = filters['endDate'] as DateTime?;
      final dateMatches =
          (startDate == null ||
              data.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null ||
              data.isBefore(endDate.add(const Duration(days: 1))));

      final ufMatches =
          filters['uf'] == null ||
          inv.uf.trim().toUpperCase() ==
              filters['uf'].toString().trim().toUpperCase();

      return notaMatches &&
          produtoMatches &&
          descricaoMatches &&
          valorMatches &&
          estadoMatches &&
          tipoMatches &&
          dateMatches &&
          ufMatches &&
          fornecedorMatches &&
          numeroDeSerieMatches &&
          internalIdMatches;
    }).toList();
  }

  static void applySorting(
    List<Inventario> inventarios,
    String sortBy,
    Map<String, NotaFiscal> notasFiscaisMap,
  ) {
    switch (sortBy) {
      case 'Data de Compra (recente)':
        inventarios.sort((a, b) {
          final notaA = notasFiscaisMap[a.notaFiscalId];
          final notaB = notasFiscaisMap[b.notaFiscalId];
          if (notaA == null || notaB == null) return 0;
          return notaB.dataCompra.compareTo(notaA.dataCompra);
        });
        break;
      case 'Data de Compra (antigo)':
        inventarios.sort((a, b) {
          final notaA = notasFiscaisMap[a.notaFiscalId];
          final notaB = notasFiscaisMap[b.notaFiscalId];
          if (notaA == null || notaB == null) return 0;
          return notaA.dataCompra.compareTo(notaB.dataCompra);
        });
        break;
      case 'Valor (maior)':
        inventarios.sort((a, b) => b.valor.compareTo(a.valor));
        break;
      case 'Valor (menor)':
        inventarios.sort((a, b) => a.valor.compareTo(b.valor));
        break;
      case 'Estado (A-Z)':
        inventarios.sort(
          (a, b) => a.estado.toLowerCase().compareTo(b.estado.toLowerCase()),
        );
        break;
      case 'Estado (Z-A)':
        inventarios.sort(
          (a, b) => b.estado.toLowerCase().compareTo(a.estado.toLowerCase()),
        );
        break;
      case 'Produto (A-Z)':
        inventarios.sort(
          (a, b) => a.produto.toLowerCase().compareTo(b.produto.toLowerCase()),
        );
        break;
      case 'Produto (Z-A)':
        inventarios.sort(
          (a, b) => b.produto.toLowerCase().compareTo(a.produto.toLowerCase()),
        );
        break;
      case 'UF (A-Z)':
        inventarios.sort(
          (a, b) => a.uf.toLowerCase().compareTo(b.uf.toLowerCase()),
        );
        break;
      case 'UF (Z-A)':
        inventarios.sort(
          (a, b) => b.uf.toLowerCase().compareTo(a.uf.toLowerCase()),
        );
        break;
      default:
        // Padrão: ordenar por dataCompra mais recente
        inventarios.sort((a, b) {
          final notaA = notasFiscaisMap[a.notaFiscalId];
          final notaB = notasFiscaisMap[b.notaFiscalId];
          if (notaA == null || notaB == null) return 0;
          return notaB.dataCompra.compareTo(notaA.dataCompra);
        });
        break;
    }
  }

  static List<MapEntry<String, List<Inventario>>>
  groupInventariosByNotaFiscalId(
    List<Inventario> inventarios,
    Map<String, NotaFiscal> notasFiscaisMap,
  ) {
    final Map<String, List<Inventario>> grouped = {};
    for (final i in inventarios) {
      grouped.putIfAbsent(i.notaFiscalId, () => []).add(i);
    }

    // Ordena grupos por dataCompra (mais recente primeiro)
    final sorted = grouped.entries.toList()
      ..sort((a, b) {
        final notaA = notasFiscaisMap[a.key];
        final notaB = notasFiscaisMap[b.key];
        if (notaA == null || notaB == null) return 0;
        return notaB.dataCompra.compareTo(notaA.dataCompra);
      });
    return sorted;
  }

  static List<MapEntry<String, List<Inventario>>> paginateGroups(
    List<MapEntry<String, List<Inventario>>> groups,
    int currentPage,
    int groupsPerPage,
  ) {
    final start = currentPage * groupsPerPage;
    final end = (currentPage + 1) * groupsPerPage;
    return groups.sublist(start, end > groups.length ? groups.length : end);
  }

  static int getTotalPages(
    List<MapEntry<String, List<Inventario>>> groups,
    int groupsPerPage,
  ) {
    return (groups.length / groupsPerPage).ceil();
  }
}
