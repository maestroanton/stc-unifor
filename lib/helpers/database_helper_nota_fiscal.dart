import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/audit_log.dart';
import '../models/nota_fiscal.dart';
import '../models/inventario.dart';
import '../services/audit_log.dart';

class DatabaseHelperNotaFiscal {
  static final DatabaseHelperNotaFiscal _instance =
      DatabaseHelperNotaFiscal._internal();
  factory DatabaseHelperNotaFiscal() => _instance;
  DatabaseHelperNotaFiscal._internal();

  final CollectionReference _notasCollection = FirebaseFirestore.instance
      .collection('notas_fiscais');
  final CollectionReference _inventarioCollection = FirebaseFirestore.instance
      .collection('inventarios');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuditLogService _auditService = AuditLogService();

  // Auxiliar para obter o tipo de conteúdo
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Criar NotaFiscal
  Future<String> createNotaFiscal(NotaFiscal notaFiscal) async {
    final docRef = await _notasCollection.add(notaFiscal.toMap());

    await _auditService.logAction(
      action: LogAction.create,
      module: LogModule.inventario,
      recordId: docRef.id,
      recordIdentifier: notaFiscal.numeroNota,
      newData: notaFiscal.toMap(),
      description: 'Nota Fiscal criada: ${notaFiscal.numeroNota}',
    );

    return docRef.id;
  }

  /// Obter NotaFiscal por ID
  Future<NotaFiscal?> getNotaFiscalById(String id) async {
    final doc = await _notasCollection.doc(id).get();
    if (!doc.exists) return null;
    return NotaFiscal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Obter todas as NotasFiscais
  Future<List<NotaFiscal>> getAllNotasFiscais() async {
    final querySnapshot = await _notasCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              NotaFiscal.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Obter NotaFiscal por número
  Future<NotaFiscal?> getNotaFiscalByNumero(String numeroNota) async {
    final querySnapshot = await _notasCollection
        .where('numeroNota', isEqualTo: numeroNota)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return NotaFiscal.fromMap(
      querySnapshot.docs.first.data() as Map<String, dynamic>,
      querySnapshot.docs.first.id,
    );
  }

  /// Obter todos os Inventarios de uma NotaFiscal
  Future<List<Inventario>> getInventariosByNotaFiscalId(
    String notaFiscalId,
  ) async {
    final querySnapshot = await _inventarioCollection
        .where('notaFiscalId', isEqualTo: notaFiscalId)
        .get();

    return querySnapshot.docs
        .map(
          (doc) =>
              Inventario.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Atualizar NotaFiscal
  Future<void> updateNotaFiscal(NotaFiscal notaFiscal) async {
    if (notaFiscal.id == null) {
      throw Exception('Cannot update NotaFiscal without an ID');
    }

    final oldDoc = await _notasCollection.doc(notaFiscal.id).get();
    final oldData = oldDoc.exists
        ? oldDoc.data() as Map<String, dynamic>
        : null;

    await _notasCollection.doc(notaFiscal.id).update(notaFiscal.toMap());

    await _auditService.logAction(
      action: LogAction.update,
      module: LogModule.inventario,
      recordId: notaFiscal.id!,
      recordIdentifier: notaFiscal.numeroNota,
      oldData: oldData ?? {},
      newData: notaFiscal.toMap(),
      description: 'Nota Fiscal atualizada: ${notaFiscal.numeroNota}',
    );
  }

  /// Excluir NotaFiscal (com verificação de cascata)
  Future<void> deleteNotaFiscal(String id, {bool forceCascade = false}) async {
    final doc = await _notasCollection.doc(id).get();
    if (!doc.exists) return;

    final notaFiscal = NotaFiscal.fromMap(
      doc.data() as Map<String, dynamic>,
      id,
    );

    // Verifica inventarios relacionados
    final relatedInventarios = await getInventariosByNotaFiscalId(id);

    if (relatedInventarios.isNotEmpty && !forceCascade) {
      throw Exception(
        'Cannot delete NotaFiscal: ${relatedInventarios.length} inventario(s) still reference it. '
        'Delete those first or use forceCascade=true.',
      );
    }

    // Se forceCascade, excluir arquivo se existir
    if (notaFiscal.notaFiscalUrl != null &&
        notaFiscal.notaFiscalUrl!.isNotEmpty) {
      try {
        final ref = _storage.refFromURL(notaFiscal.notaFiscalUrl!);
        await ref.delete();
      } catch (e) {
        // O arquivo pode não existir; prosseguir
      }
    }

    await _notasCollection.doc(id).delete();

    await _auditService.logAction(
      action: LogAction.delete,
      module: LogModule.inventario,
      recordId: id,
      recordIdentifier: notaFiscal.numeroNota,
      oldData: notaFiscal.toMap(),
      description: 'Nota Fiscal deletada: ${notaFiscal.numeroNota}',
    );
  }

  /// Enviar arquivo de Nota Fiscal
  Future<String> uploadNotaFiscalFile(
    Uint8List fileBytes,
    String numeroNota,
    String fileName,
  ) async {
    try {
      final sanitizedNumero = numeroNota.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final ref = _storage.ref().child(
        'notas_fiscais/$sanitizedNumero/$fileName',
      );

      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'originalName': fileName,
          'numeroNota': numeroNota,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
        contentDisposition: 'inline; filename="$fileName"',
      );

      await ref.putData(fileBytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao enviar arquivo da nota fiscal: $e');
    }
  }

  /// Recalcular valorTotal de uma NotaFiscal com base em seus inventarios
  Future<void> recalculateValorTotal(String notaFiscalId) async {
    final inventarios = await getInventariosByNotaFiscalId(notaFiscalId);
    final total = inventarios.fold<double>(
      0.0,
      (acc, item) => acc + item.valor,
    );

    await _notasCollection.doc(notaFiscalId).update({'valorTotal': total});
  }

  /// Obter NotaFiscal com itens (método de conveniência)
  Future<Map<String, dynamic>?> getNotaFiscalWithItems(String id) async {
    final notaFiscal = await getNotaFiscalById(id);
    if (notaFiscal == null) return null;

    final items = await getInventariosByNotaFiscalId(id);

    return {'notaFiscal': notaFiscal, 'items': items};
  }
}
