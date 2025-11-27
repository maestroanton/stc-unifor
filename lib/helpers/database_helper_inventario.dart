import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';

import '../models/audit_log.dart';
import '../models/inventario.dart';
import '../models/nota_fiscal.dart';
import '../services/audit_log.dart';

class DatabaseHelperInventario {
  static final DatabaseHelperInventario _instance =
      DatabaseHelperInventario._internal();
  factory DatabaseHelperInventario() => _instance;
  DatabaseHelperInventario._internal();

  final Logger _logger = Logger();

  final CollectionReference _inventarioCollection = FirebaseFirestore.instance
      .collection('inventarios');

  final CollectionReference _notaFiscalCollection = FirebaseFirestore.instance
      .collection('notas_fiscais');

  final CollectionReference _backupCollection = FirebaseFirestore.instance
      .collection('inventarios_backup');

  final CollectionReference _notaFiscalBackupCollection = FirebaseFirestore
      .instance
      .collection('notas_fiscais_backup');

  final AuditLogService _auditService = AuditLogService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============ Operações de NotaFiscal ============

  /// Verifica se uma NotaFiscal já existe com o mesmo UF e numeroNota
  Future<bool> notaFiscalExists(String uf, String numeroNota) async {
    final querySnapshot = await _notaFiscalCollection
        .where('uf', isEqualTo: uf)
        .where('numeroNota', isEqualTo: numeroNota)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// Obter NotaFiscal existente por UF e numeroNota
  Future<NotaFiscal?> getNotaFiscalByUfAndNumero(
    String uf,
    String numeroNota,
  ) async {
    final querySnapshot = await _notaFiscalCollection
        .where('uf', isEqualTo: uf)
        .where('numeroNota', isEqualTo: numeroNota)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    return NotaFiscal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Cria a NotaFiscal e retorna seu ID
  /// OBS: Normalmente isso deve ser seguido da criação de pelo menos um Inventario.
  /// Considere usar createNotaFiscalWithInventarios() para garantir a integridade dos dados.
  Future<String> createNotaFiscal(NotaFiscal notaFiscal) async {
    // Verifica duplicata UF + numeroNota
    final exists = await notaFiscalExists(notaFiscal.uf, notaFiscal.numeroNota);
    if (exists) {
      throw Exception(
        'Já existe uma Nota Fiscal com o número ${notaFiscal.numeroNota} para o UF ${notaFiscal.uf}',
      );
    }

    final docRef = await _notaFiscalCollection.add(notaFiscal.toMap());

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
    final doc = await _notaFiscalCollection.doc(id).get();
    if (!doc.exists) return null;
    return NotaFiscal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Obter todas as NotasFiscais
  Future<List<NotaFiscal>> getAllNotasFiscais() async {
    final querySnapshot = await _notaFiscalCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              NotaFiscal.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Atualizar NotaFiscal
  Future<void> updateNotaFiscal(NotaFiscal notaFiscal) async {
    if (notaFiscal.id == null) {
      throw Exception('Cannot update NotaFiscal without an ID');
    }

    // Verifica se a atualização criaria uma duplicata (UF + numeroNota)
    final existing = await getNotaFiscalByUfAndNumero(
      notaFiscal.uf,
      notaFiscal.numeroNota,
    );
    if (existing != null && existing.id != notaFiscal.id) {
      throw Exception(
        'Já existe uma Nota Fiscal com o número ${notaFiscal.numeroNota} para o UF ${notaFiscal.uf}',
      );
    }

    final oldDoc = await _notaFiscalCollection.doc(notaFiscal.id).get();
    final oldData = oldDoc.exists
        ? oldDoc.data() as Map<String, dynamic>
        : null;

    await _notaFiscalCollection.doc(notaFiscal.id).update(notaFiscal.toMap());

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

  /// Excluir NotaFiscal (e opcionalmente excluir em cascata seus inventarios)
  Future<void> deleteNotaFiscal(String id) async {
    final doc = await _notaFiscalCollection.doc(id).get();
    final data = doc.exists ? doc.data() as Map<String, dynamic> : null;
    final numeroNota = data?['numeroNota'] ?? 'Desconhecido';

    if (data?['notaFiscalUrl'] != null) {
      try {
        await _storage.refFromURL(data!['notaFiscalUrl'] as String).delete();
      } catch (e) {
        _logger.w('Warning: Could not delete nota fiscal file: $e');
      }
    }

    // Exclui todos os inventarios vinculados a esta nota fiscal
    final inventarios = await getInventariosByNotaFiscalId(id);
    for (final inv in inventarios) {
      await deleteInventario(inv.id!);
    }

    await _notaFiscalCollection.doc(id).delete();

    await _auditService.logAction(
      action: LogAction.delete,
      module: LogModule.inventario,
      recordId: id,
      recordIdentifier: numeroNota,
      oldData: data ?? {},
      description: 'Nota Fiscal deletada: $numeroNota',
    );
  }

  Future<void> uploadNotaFiscalFile(
    String notaFiscalId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Obtém a nota fiscal atual
      final notaFiscal = await getNotaFiscalById(notaFiscalId);
      if (notaFiscal == null) throw Exception('NotaFiscal not found');

      // Exclui arquivo antigo se existir
      if (notaFiscal.notaFiscalUrl != null) {
        try {
          await _storage.refFromURL(notaFiscal.notaFiscalUrl!).delete();
        } catch (e) {
          _logger.w('Warning: Could not delete old file: $e');
        }
      }

      // Envia novo arquivo
      final ref = _storage.ref().child(
        'notas_fiscais/${notaFiscal.numeroNota}/$fileName',
      );
      final uploadTask = await ref.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'uploadedBy': user.email!,
            'numeroNota': notaFiscal.numeroNota,
            'fornecedor': notaFiscal.fornecedor,
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Atualiza a nota fiscal com o novo URL do arquivo
      final updatedNotaFiscal = NotaFiscal(
        id: notaFiscal.id,
        numeroNota: notaFiscal.numeroNota,
        fornecedor: notaFiscal.fornecedor,
        dataCompra: notaFiscal.dataCompra,
        valorTotal: notaFiscal.valorTotal,
        notaFiscalUrl: downloadUrl,
        chaveAcesso: notaFiscal.chaveAcesso,
        uf: notaFiscal.uf,
        createdAt: notaFiscal.createdAt,
        createdBy: notaFiscal.createdBy,
      );

      await updateNotaFiscal(updatedNotaFiscal);

      // Registra no audit log o envio do arquivo
      await _auditService.logAction(
        action: LogAction.update,
        module: LogModule.inventario,
        recordId: notaFiscalId,
        recordIdentifier: notaFiscal.numeroNota,
        description:
            'Arquivo de nota fiscal enviado - NF: ${notaFiscal.numeroNota}',
        metadata: {
          'fileName': fileName,
          'fileSize': fileBytes.length,
          'action': 'file_upload',
        },
      );
    } catch (e) {
      _logger.e('Error uploading nota fiscal file: $e');
      rethrow;
    }
  }

  /// Excluir arquivo da nota fiscal
  Future<void> deleteNotaFiscalFile(String notaFiscalId) async {
    try {
      final notaFiscal = await getNotaFiscalById(notaFiscalId);
      if (notaFiscal == null) throw Exception('NotaFiscal not found');

      if (notaFiscal.notaFiscalUrl != null) {
        // Exclui arquivo do storage
        await _storage.refFromURL(notaFiscal.notaFiscalUrl!).delete();

        // Atualiza nota fiscal para remover URL do arquivo
        final updatedNotaFiscal = NotaFiscal(
          id: notaFiscal.id,
          numeroNota: notaFiscal.numeroNota,
          fornecedor: notaFiscal.fornecedor,
          dataCompra: notaFiscal.dataCompra,
          valorTotal: notaFiscal.valorTotal,
          notaFiscalUrl: null,
          chaveAcesso: notaFiscal.chaveAcesso,
          uf: notaFiscal.uf,
          createdAt: notaFiscal.createdAt,
          createdBy: notaFiscal.createdBy,
        );

        await updateNotaFiscal(updatedNotaFiscal);

        // Registra no audit log a exclusão do arquivo
        await _auditService.logAction(
          action: LogAction.delete,
          module: LogModule.inventario,
          recordId: notaFiscalId,
          recordIdentifier: notaFiscal.numeroNota,
          description:
              'Arquivo de nota fiscal removido - NF: ${notaFiscal.numeroNota}',
          metadata: {'action': 'file_delete'},
        );
      }
    } catch (e) {
      _logger.e('Error deleting nota fiscal file: $e');
      rethrow;
    }
  }

  // ============ Operações de Inventario ============

  /// Cria Inventario (deve possuir notaFiscalId)
  Future<void> insertInventario(Inventario inventario) async {
    // Verifica se a NotaFiscal existe
    final notaFiscal = await getNotaFiscalById(inventario.notaFiscalId);
    if (notaFiscal == null) {
      throw Exception(
        'NotaFiscal with ID ${inventario.notaFiscalId} does not exist',
      );
    }

    final docRef = await _inventarioCollection.add(inventario.toMap());

    await _auditService.logInventarioCreate(
      docRef.id,
      '${inventario.produto} (NF: ${notaFiscal.numeroNota})',
      inventario.toMap(),
    );
  }

  /// Ler todos os inventarios
  Future<List<Inventario>> getInventarios() async {
    final querySnapshot = await _inventarioCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              Inventario.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Obter inventarios por notaFiscalId (consulta mais importante)
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

  /// Obter inventario por ID com registro de visualização
  Future<Inventario?> getInventarioById(String id) async {
    final doc = await _inventarioCollection.doc(id).get();
    if (!doc.exists) return null;

    final inventario = Inventario.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );

    await _auditService.logInventarioView(inventario.id!, inventario.produto);

    return inventario;
  }

  /// Atualizar inventario
  Future<void> updateInventario(Inventario inventario) async {
    if (inventario.id == null) {
      throw Exception('Cannot update Inventario without an ID');
    }

    // Verifica se a NotaFiscal existe
    final notaFiscal = await getNotaFiscalById(inventario.notaFiscalId);
    if (notaFiscal == null) {
      throw Exception(
        'NotaFiscal with ID ${inventario.notaFiscalId} does not exist',
      );
    }

    final oldDoc = await _inventarioCollection.doc(inventario.id).get();
    final oldData = oldDoc.exists
        ? oldDoc.data() as Map<String, dynamic>
        : null;

    await _inventarioCollection.doc(inventario.id).update(inventario.toMap());

    await _auditService.logInventarioUpdate(
      inventario.id!,
      inventario.produto,
      oldData ?? {},
      inventario.toMap(),
    );
  }

  /// Excluir inventario
  /// Aviso: se este for o último inventario para uma NotaFiscal,
  /// a NotaFiscal ficará sem itens associados.
  /// Considere excluir a NotaFiscal se não houver inventarios restantes.
  Future<void> deleteInventario(String id) async {
    final doc = await _inventarioCollection.doc(id).get();
    final data = doc.exists ? doc.data() as Map<String, dynamic> : null;
    final produto = data?['produto'] ?? 'Desconhecido';
    final notaFiscalId = data?['notaFiscalId'];

    await _inventarioCollection.doc(id).delete();

    if (data != null) {
      await _auditService.logInventarioDelete(id, produto, data);
    }

    // Opcional: Verifica se este foi o último inventario para a NotaFiscal
    // e registra um aviso caso a NotaFiscal fique vazia
    if (notaFiscalId != null) {
      final remainingInventarios = await getInventariosByNotaFiscalId(
        notaFiscalId as String,
      );
      if (remainingInventarios.isEmpty) {
        await _auditService.logAction(
          action: LogAction.update,
          module: LogModule.inventario,
          recordId: notaFiscalId,
          recordIdentifier: 'NotaFiscal órfã',
          description:
              'AVISO: NotaFiscal $notaFiscalId não possui mais itens de inventário associados',
        );
      }
    }
  }

  /// Backup e exclusão do inventario
  Future<void> backupAndDeleteInventario(Inventario inventario) async {
    if (inventario.id == null) return;

    final backupData = {
      ...inventario.toMap(),
      'deletedAt': FieldValue.serverTimestamp(),
    };

    await _backupCollection.doc(inventario.id).set(backupData);
    await _inventarioCollection.doc(inventario.id).delete();

    await _auditService.logAction(
      action: LogAction.backup,
      module: LogModule.inventario,
      recordId: inventario.id!,
      recordIdentifier: inventario.produto,
      oldData: inventario.toMap(),
      description:
          'Item de inventário movido para backup - Produto: ${inventario.produto}',
    );

    // Verifica se este foi o último inventario para a NotaFiscal
    final remainingInventarios = await getInventariosByNotaFiscalId(
      inventario.notaFiscalId,
    );
    if (remainingInventarios.isEmpty) {
      // Este foi o último item - faz backup e exclui a NotaFiscal
      final notaFiscal = await getNotaFiscalById(inventario.notaFiscalId);
      if (notaFiscal != null) {
        await backupNotaFiscal(notaFiscal);
        await deleteNotaFiscal(inventario.notaFiscalId);
      }
    }
  }

  /// Restaurar a partir do backup
  Future<void> restoreInventario(Inventario inventario) async {
    final docRef = await _inventarioCollection.add(inventario.toMap());
    await _backupCollection.doc(inventario.id).delete();

    await _auditService.logAction(
      action: LogAction.restore,
      module: LogModule.inventario,
      recordId: docRef.id,
      recordIdentifier: inventario.produto,
      newData: inventario.toMap(),
      description:
          'Item de inventário restaurado do backup - Produto: ${inventario.produto}',
    );
  }

  /// Duplicar inventario (mantém a mesma referência notaFiscalId)
  Future<void> duplicateInventario(Inventario original) async {
    if (original.id == null) return;

    final duplicated = Inventario(
      notaFiscalId: original.notaFiscalId,
      valor: original.valor,
      dataDeGarantia: original.dataDeGarantia,
      produto: original.produto,
      descricao: '${original.descricao} (Cópia)',
      estado: original.estado,
      tipo: original.tipo,
      uf: original.uf,
      numeroDeSerie: original.numeroDeSerie,
      localizacao: original.localizacao,
      observacoes: original.observacoes,
    );

    final docRef = await _inventarioCollection.add(duplicated.toMap());

    await _auditService.logInventarioDuplicate(
      original.id!,
      docRef.id,
      duplicated.produto,
    );
  }

  // ============ Métodos de Validação e Utilitários ============

  /// Verifica se uma NotaFiscal possui inventarios associados
  Future<bool> notaFiscalHasInventarios(String notaFiscalId) async {
    final inventarios = await getInventariosByNotaFiscalId(notaFiscalId);
    return inventarios.isNotEmpty;
  }

  /// Exclusão segura: se deletar o último inventario, também excluir a NotaFiscal
  Future<void> deleteInventarioAndOrphanedNotaFiscal(
    String inventarioId,
  ) async {
    final inventario = await _inventarioCollection.doc(inventarioId).get();
    if (!inventario.exists) {
      throw Exception('Inventario not found');
    }

    final data = inventario.data() as Map<String, dynamic>;
    final notaFiscalId = data['notaFiscalId'] as String;

    // Verifica quantos inventarios existem para esta NotaFiscal
    final inventarios = await getInventariosByNotaFiscalId(notaFiscalId);

    if (inventarios.length == 1) {
      // Este é o último inventario - excluir ambos
      await deleteNotaFiscal(
        notaFiscalId,
      ); // Isto provocará a exclusão em cascata do inventario
    } else {
      // Existem outros inventarios - apenas exclua este
      await deleteInventario(inventarioId);
    }
  }

  // ============ Operações Compostas ============

  /// Obter NotaFiscal com todos os seus inventarios
  Future<Map<String, dynamic>?> getNotaFiscalWithInventarios(
    String notaFiscalId,
  ) async {
    final notaFiscal = await getNotaFiscalById(notaFiscalId);
    if (notaFiscal == null) return null;

    final inventarios = await getInventariosByNotaFiscalId(notaFiscalId);

    return {'notaFiscal': notaFiscal, 'inventarios': inventarios};
  }

  /// Criação em lote: criar NotaFiscal e múltiplos inventarios de uma vez
  Future<String> createNotaFiscalWithInventarios(
    NotaFiscal notaFiscal,
    List<Inventario> inventarios,
  ) async {
    final exists = await notaFiscalExists(notaFiscal.uf, notaFiscal.numeroNota);
    if (exists) {
      throw Exception(
        'Já existe uma Nota Fiscal com o número ${notaFiscal.numeroNota} para o UF ${notaFiscal.uf}',
      );
    }

    // Cria a nota fiscal primeiro
    final notaFiscalId = await createNotaFiscal(notaFiscal);

    // Cria todos os inventarios com o ID da nota fiscal
    for (final inventario in inventarios) {
      final inventarioWithFK = Inventario(
        notaFiscalId: notaFiscalId,
        valor: inventario.valor,
        dataDeGarantia: inventario.dataDeGarantia,
        produto: inventario.produto,
        descricao: inventario.descricao,
        estado: inventario.estado,
        tipo: inventario.tipo,
        uf: inventario.uf,
        numeroDeSerie: inventario.numeroDeSerie,
        localizacao: inventario.localizacao,
        observacoes: inventario.observacoes,
      );
      await insertInventario(inventarioWithFK);
    }

    return notaFiscalId;
  }

  // ============ Operações de Backup e Restauração de NotaFiscal ============

  /// Backup da NotaFiscal (usado ao excluir o último inventario)
  Future<void> backupNotaFiscal(NotaFiscal notaFiscal) async {
    if (notaFiscal.id == null) {
      throw Exception('Cannot backup NotaFiscal without an ID');
    }

    final backupData = {
      ...notaFiscal.toMap(),
      'deletedAt': FieldValue.serverTimestamp(),
    };

    await _notaFiscalBackupCollection.doc(notaFiscal.id).set(backupData);

    await _auditService.logAction(
      action: LogAction.backup,
      module: LogModule.inventario,
      recordId: notaFiscal.id!,
      recordIdentifier: notaFiscal.numeroNota,
      oldData: notaFiscal.toMap(),
      description:
          'Nota Fiscal movida para backup - NF: ${notaFiscal.numeroNota}',
    );
  }

  /// Restaurar NotaFiscal do backup
  Future<void> restoreNotaFiscal(String notaFiscalId) async {
    final backupDoc = await _notaFiscalBackupCollection.doc(notaFiscalId).get();
    if (!backupDoc.exists) {
      throw Exception('NotaFiscal backup not found');
    }

    final data = backupDoc.data() as Map<String, dynamic>;
    // Remove o timestamp deletedAt antes de restaurar
    data.remove('deletedAt');

    await _notaFiscalCollection.doc(notaFiscalId).set(data);
    await _notaFiscalBackupCollection.doc(notaFiscalId).delete();

    final numeroNota = data['numeroNota'] ?? 'Desconhecido';
    await _auditService.logAction(
      action: LogAction.restore,
      module: LogModule.inventario,
      recordId: notaFiscalId,
      recordIdentifier: numeroNota,
      newData: data,
      description: 'Nota Fiscal restaurada do backup - NF: $numeroNota',
    );
  }

  /// Verifica se existe backup da NotaFiscal
  Future<bool> notaFiscalBackupExists(String notaFiscalId) async {
    final doc = await _notaFiscalBackupCollection.doc(notaFiscalId).get();
    return doc.exists;
  }

  /// Obter NotaFiscal do backup
  Future<NotaFiscal?> getNotaFiscalFromBackup(String notaFiscalId) async {
    final doc = await _notaFiscalBackupCollection.doc(notaFiscalId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data.remove('deletedAt');
    return NotaFiscal.fromMap(data, doc.id);
  }

  /// Excluir permanentemente o backup da NotaFiscal
  Future<void> permanentlyDeleteNotaFiscalBackup(String notaFiscalId) async {
    await _notaFiscalBackupCollection.doc(notaFiscalId).delete();

    await _auditService.logAction(
      action: LogAction.delete,
      module: LogModule.inventario,
      recordId: notaFiscalId,
      recordIdentifier: 'NotaFiscal backup',
      description:
          'Nota Fiscal backup permanentemente deletada - ID: $notaFiscalId',
    );
  }
}
