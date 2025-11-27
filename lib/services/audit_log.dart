import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log.dart';
import 'user_role.dart';

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final CollectionReference _logsCollection = FirebaseFirestore.instance
      .collection('audit_logs');

  final UserRoleService _userRoleService = UserRoleService();

  /// Reverte alteração restaurando o registro ao estado anterior
  /// Suporta operações UPDATE (restaurar dados) e DELETE (recriar registro)
  Future<void> revertChange({
    required String recordId,
    required LogModule module,
    required String targetLogId,
    required Map<String, dynamic> oldData,
    LogAction? originalAction,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userRole = await _userRoleService.getCurrentUserRole();
      if (userRole == null) {
        throw Exception('User role not found');
      }

      // Determina o nome da coleção de acordo com o módulo
      String collectionName;
      switch (module) {
        case LogModule.avaria:
          collectionName = 'avarias';
          break;
        case LogModule.inventario:
          collectionName = 'inventarios'; // Deve estar no plural
          break;
        case LogModule.user:
          collectionName = 'user_roles'; // Baseado nas regras de segurança
          break;
        case LogModule.system:
          throw Exception('System records cannot be reverted');
      }

      // Obtém o estado atual do registro
      final recordRef = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(recordId);

      final recordSnapshot = await recordRef.get();
      Map<String, dynamic>? currentData;

      if (recordSnapshot.exists) {
        // Registro existe - reversão de atualização
        currentData = recordSnapshot.data() as Map<String, dynamic>;

        // Atualiza o registro com os dados antigos
        await recordRef.update(oldData);
      } else {
        // Registro não existe - reversão de exclusão
        // Recria o registro com os dados antigos
        await recordRef.set(oldData);
        currentData = null; // Nenhum dado atual pois o registro foi excluído
      }

      // Registra a ação de reversão
      await logAction(
        action: LogAction.restore,
        module: module,
        recordId: recordId,
        recordIdentifier: _extractRecordIdentifier(oldData, module),
        oldData: currentData,
        newData: oldData,
        description: originalAction == LogAction.delete
            ? 'Registro deletado foi recriado (reversão de exclusão)'
            : 'Registro revertido para estado anterior',
        metadata: {
          'revertedFromLogId': targetLogId,
          'revertedAt': DateTime.now().toIso8601String(),
          'originalAction': originalAction?.toString(),
        },
      );
    } catch (e) {
      throw Exception('Erro ao reverter alteração: $e');
    }
  }

  /// Extrai identificador do registro de acordo com o tipo de módulo
  String? _extractRecordIdentifier(
    Map<String, dynamic> data,
    LogModule module,
  ) {
    switch (module) {
      case LogModule.avaria:
      case LogModule.inventario:
        return data['nota']?.toString();
      case LogModule.user:
        return data['email']?.toString() ?? data['displayName']?.toString();
      case LogModule.system:
        return null;
    }
  }

  /// Registra uma ação do usuário atual
  Future<void> logAction({
    required LogAction action,
    required LogModule module,
    String? recordId,
    String? recordIdentifier,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRole = await _userRoleService.getCurrentUserRole();
      if (userRole == null) return;

      // Remove dados sensíveis dos registros
      final cleanOldData = _cleanSensitiveData(oldData);
      final cleanNewData = _cleanSensitiveData(newData);

      final log = AuditLog(
        userId: user.uid,
        userEmail: user.email!,
        userDisplayName: userRole.displayName,
        uf: userRole.uf,
        isAdmin: userRole.isAdmin,
        action: action,
        module: module,
        recordId: recordId,
        recordIdentifier: recordIdentifier,
        oldData: cleanOldData,
        newData: cleanNewData,
        description: description,
        timestamp: DateTime.now(),
        metadata: {...?metadata, 'appVersion': '1.0.0', 'platform': 'flutter'},
      );

      await _logsCollection.add(log.toMap());
    } catch (e) {
      // Não lança exceção - registro de auditoria não deve quebrar o app
    }
  }

  /// Registra login do usuário
  Future<void> logLogin() async {
    await logAction(
      action: LogAction.login,
      module: LogModule.user,
      description: 'Usuário fez login no sistema',
    );
  }

  /// Registra logout do usuário
  Future<void> logLogout() async {
    await logAction(
      action: LogAction.logout,
      module: LogModule.user,
      description: 'Usuário fez logout do sistema',
    );
  }

  /// Registra ações de avaria
  Future<void> logAvariaCreate(
    String recordId,
    String nota,
    Map<String, dynamic> data,
  ) async {
    await logAction(
      action: LogAction.create,
      module: LogModule.avaria,
      recordId: recordId,
      recordIdentifier: nota,
      newData: data,
      description: 'Nova avaria criada - Nota: $nota',
    );
  }

  Future<void> logAvariaUpdate(
    String recordId,
    String nota,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) async {
    await logAction(
      action: LogAction.update,
      module: LogModule.avaria,
      recordId: recordId,
      recordIdentifier: nota,
      oldData: oldData,
      newData: newData,
      description: 'Avaria editada - Nota: $nota',
    );
  }

  Future<void> logAvariaDelete(
    String recordId,
    String nota,
    Map<String, dynamic> data,
  ) async {
    await logAction(
      action: LogAction.delete,
      module: LogModule.avaria,
      recordId: recordId,
      recordIdentifier: nota,
      oldData: data,
      description: 'Avaria excluída - Nota: $nota',
    );
  }

  Future<void> logAvariaView(String recordId, String nota) async {
    await logAction(
      action: LogAction.view,
      module: LogModule.avaria,
      recordId: recordId,
      recordIdentifier: nota,
      description: 'Avaria visualizada - Nota: $nota',
    );
  }

  /// Registra ações de inventário
  Future<void> logInventarioCreate(
    String recordId,
    String nota,
    Map<String, dynamic> data,
  ) async {
    await logAction(
      action: LogAction.create,
      module: LogModule.inventario,
      recordId: recordId,
      recordIdentifier: nota,
      newData: data,
      description: 'Novo item de inventário criado - Nota: $nota',
    );
  }

  Future<void> logInventarioUpdate(
    String recordId,
    String nota,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) async {
    await logAction(
      action: LogAction.update,
      module: LogModule.inventario,
      recordId: recordId,
      recordIdentifier: nota,
      oldData: oldData,
      newData: newData,
      description: 'Item de inventário editado - Nota: $nota',
    );
  }

  Future<void> logInventarioDelete(
    String recordId,
    String nota,
    Map<String, dynamic> data,
  ) async {
    await logAction(
      action: LogAction.delete,
      module: LogModule.inventario,
      recordId: recordId,
      recordIdentifier: nota,
      oldData: data,
      description: 'Item de inventário excluído - Nota: $nota',
    );
  }

  Future<void> logInventarioView(String recordId, String nota) async {
    await logAction(
      action: LogAction.view,
      module: LogModule.inventario,
      recordId: recordId,
      recordIdentifier: nota,
      description: 'Item de inventário visualizado - Nota: $nota',
    );
  }

  Future<void> logInventarioDuplicate(
    String originalId,
    String newId,
    String nota,
  ) async {
    await logAction(
      action: LogAction.duplicate,
      module: LogModule.inventario,
      recordId: newId,
      recordIdentifier: nota,
      description: 'Item de inventário duplicado - Nota: $nota',
      metadata: {'originalRecordId': originalId},
    );
  }

  /// Registra ações de exportação
  Future<void> logExport(
    LogModule module,
    int recordCount, {
    String? filterInfo,
  }) async {
    await logAction(
      action: LogAction.export,
      module: module,
      description: 'Exportação de ${module.name} ($recordCount registros)',
      metadata: {
        'recordCount': recordCount,
        if (filterInfo != null) 'filters': filterInfo,
      },
    );
  }

  /// Obtém registros de auditoria com filtros e paginação
  Future<List<AuditLog>> getLogs({
    LogModule? module,
    LogAction? action,
    String? userId,
    String? uf,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _logsCollection.orderBy('timestamp', descending: true);

      // Aplica filtros
      if (module != null) {
        query = query.where('module', isEqualTo: module.name);
      }
      if (action != null) {
        query = query.where('action', isEqualTo: action.name);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (uf != null) {
        query = query.where('uf', isEqualTo: uf);
      }
      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Paginação
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) =>
                AuditLog.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtém registros recentes para o painel
  Future<List<AuditLog>> getRecentLogs({int limit = 10}) async {
    return getLogs(limit: limit);
  }

  /// Obtém registros de um registro específico
  Future<List<AuditLog>> getRecordHistory({
    required LogModule module,
    required String recordId,
  }) async {
    try {
      final querySnapshot = await _logsCollection
          .where('module', isEqualTo: module.name)
          .where('recordId', isEqualTo: recordId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                AuditLog.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtém estatísticas de atividade
  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? uf,
  }) async {
    try {
      Query query = _logsCollection;

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }
      if (uf != null) {
        query = query.where('uf', isEqualTo: uf);
      }

      final querySnapshot = await query.get();
      final logs = querySnapshot.docs
          .map(
            (doc) =>
                AuditLog.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Calcula estatísticas
      final actionCounts = <String, int>{};
      final moduleCounts = <String, int>{};
      final userCounts = <String, int>{};
      final dailyActivity = <String, int>{};

      for (final log in logs) {
        // Contagem de ações
        actionCounts[log.action.name] =
            (actionCounts[log.action.name] ?? 0) + 1;

        // Contagem de módulos
        moduleCounts[log.module.name] =
            (moduleCounts[log.module.name] ?? 0) + 1;

        // Contagem de usuários
        userCounts[log.userEmail] = (userCounts[log.userEmail] ?? 0) + 1;

        // Atividade diária
        final dateKey =
            '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
        dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
      }

      return {
        'totalLogs': logs.length,
        'actionCounts': actionCounts,
        'moduleCounts': moduleCounts,
        'userCounts': userCounts,
        'dailyActivity': dailyActivity,
        'mostActiveUser': userCounts.isNotEmpty
            ? userCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'mostCommonAction': actionCounts.isNotEmpty
            ? actionCounts.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
            : null,
      };
    } catch (e) {
      return {};
    }
  }

  /// Remove dados sensíveis dos registros
  Map<String, dynamic>? _cleanSensitiveData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final cleaned = Map<String, dynamic>.from(data);

    // Remove ou mascara campos sensíveis
    final sensitiveFields = ['password', 'token', 'secret', 'key'];
    for (final field in sensitiveFields) {
      if (cleaned.containsKey(field)) {
        cleaned[field] = '***';
      }
    }

    // Trunca campos de texto muito longos
    cleaned.forEach((key, value) {
      if (value is String && value.length > 500) {
        cleaned[key] = '${value.substring(0, 497)}...';
      }
    });

    return cleaned;
  }

  /// Remove registros antigos
  Future<void> cleanupOldLogs({int daysToKeep = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final query = _logsCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500); // Processa em lotes

      final querySnapshot = await query.get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Erro ao remover registros antigos
    }
  }

  /// Verifica se um registro já foi revertido
  Future<bool> hasBeenReverted(String logId) async {
    try {
      final querySnapshot = await _logsCollection
          .where('action', isEqualTo: LogAction.restore.name)
          .where('metadata.revertedFromLogId', isEqualTo: logId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false; // Se não conseguir verificar, assume que não foi revertido
    }
  }
}
