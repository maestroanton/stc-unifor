// lib/services/email_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/email_log.dart';
import '../helpers/uf_helper.dart';

class EmailLogService {
  static final EmailLogService _instance = EmailLogService._internal();
  factory EmailLogService() => _instance;
  EmailLogService._internal();

  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'email_logs',
  );

  /// Registra tentativa de envio de email
  /// Suporta parâmetros tanto de avaria quanto de license para compatibilidade retroativa
  Future<void> logEmailSent({
    required EmailType type,
    required EmailStatus status,
    required String recipientEmail,
    required String subject,
    int? avariaCount,
    List<String>? avariaIds,
    int? licenseCount,
    List<String>? licenseIds,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userUf = await UfHelper.getCurrentUserUf();

      // Usa parâmetros de license se fornecidos, caso contrário usa parâmetros de avaria
      final count = licenseCount ?? avariaCount ?? 0;
      final ids = licenseIds ?? avariaIds ?? [];

      final emailLog = EmailLog(
        type: type,
        status: status,
        timestamp: DateTime.now(),
        recipientEmail: recipientEmail,
        subject: subject,
        avariaCount: count,
        avariaIds: ids,
        errorMessage: errorMessage,
        userEmail: user?.email,
        uf: userUf,
        metadata: metadata,
      );

      await _collection.add(emailLog.toMap());
    } catch (e) {
      debugPrint('Error logging email: $e');
    }
  }

  /// Obtém registros de email com filtragem opcional
  Future<List<EmailLog>> getEmailLogs({
    EmailType? type,
    EmailStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _collection.orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
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

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) =>
                EmailLog.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting email logs: $e');
      return [];
    }
  }

  /// Obtém estatísticas de email
  Future<Map<String, int>> getEmailStatistics() async {
    try {
      final snapshot = await _collection.get();
      final logs = snapshot.docs
          .map(
            (doc) =>
                EmailLog.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      return {
        'total': logs.length,
        'sent': logs.where((log) => log.status == EmailStatus.sent).length,
        'failed': logs.where((log) => log.status == EmailStatus.failed).length,
        'warning': logs.where((log) => log.type == EmailType.warning).length,
        'overdue': logs.where((log) => log.type == EmailType.overdue).length,
        'test': logs.where((log) => log.type == EmailType.test).length,
      };
    } catch (e) {
      debugPrint('Error getting email statistics: $e');
      return {};
    }
  }

  /// Obtém atividade recente de email (últimos 7 dias)
  Future<List<EmailLog>> getRecentActivity() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return getEmailLogs(startDate: sevenDaysAgo, limit: 20);
  }

  /// Verifica se emails foram enviados hoje
  Future<bool> wereEmailsSentToday(EmailType type) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logs = await getEmailLogs(
      type: type,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return logs.where((log) => log.status == EmailStatus.sent).isNotEmpty;
  }
}
