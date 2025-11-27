import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum EmailType {
  warning,
  overdue,
  test,
  licenseWarning,
  licenseExpired,
  licenseTest,
}

enum EmailStatus { sent, failed, pending }

class EmailLog {
  final String? id;
  final EmailType type;
  final EmailStatus status;
  final DateTime timestamp;
  final String recipientEmail;
  final String subject;
  final int avariaCount; // Pode ser usado também para a contagem de licenças
  final List<String> avariaIds; // Também pode ser usado para os IDs de licença
  final String? errorMessage;
  final String? userEmail;
  final String? uf;
  final Map<String, dynamic>? metadata;

  EmailLog({
    this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.recipientEmail,
    required this.subject,
    required this.avariaCount,
    required this.avariaIds,
    this.errorMessage,
    this.userEmail,
    this.uf,
    this.metadata,
  });

  String get typeDisplayName {
    switch (type) {
      case EmailType.warning:
        return 'Aviso Avaria';
      case EmailType.overdue:
        return 'Avaria Atrasada';
      case EmailType.test:
        return 'Teste Avaria';
      case EmailType.licenseWarning:
        return 'Aviso Licença';
      case EmailType.licenseExpired:
        return 'Licença Vencida';
      case EmailType.licenseTest:
        return 'Teste Licença';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EmailStatus.sent:
        return 'Enviado';
      case EmailStatus.failed:
        return 'Falhou';
      case EmailStatus.pending:
        return 'Pendente';
    }
  }

  Color get statusColor {
    switch (status) {
      case EmailStatus.sent:
        return Colors.green;
      case EmailStatus.failed:
        return Colors.red;
      case EmailStatus.pending:
        return Colors.orange;
    }
  }

  Color get typeColor {
    switch (type) {
      case EmailType.warning:
        return Colors.orange;
      case EmailType.overdue:
        return Colors.red;
      case EmailType.test:
        return Colors.blue;
      case EmailType.licenseWarning:
        return Colors.purple;
      case EmailType.licenseExpired:
        return Colors.deepOrange;
      case EmailType.licenseTest:
        return Colors.indigo;
    }
  }

  // Método auxiliar para verificar se este e-mail está relacionado a uma licença
  bool get isLicenseEmail {
    return type == EmailType.licenseWarning ||
        type == EmailType.licenseExpired ||
        type == EmailType.licenseTest;
  }

  // Método auxiliar para verificar se este e-mail está relacionado a uma avaria
  bool get isAvariaEmail {
    return type == EmailType.warning ||
        type == EmailType.overdue ||
        type == EmailType.test;
  }

  // Obtém o módulo ao qual este e-mail pertence
  String get module {
    return isLicenseEmail ? 'licenses' : 'avarias';
  }

  Map<String, dynamic> toMap() {
    // Use nomes de campo apropriados com base no tipo de e-mail
    final countFieldName = isLicenseEmail ? 'licenseCount' : 'avariaCount';
    final idsFieldName = isLicenseEmail ? 'licenseIds' : 'avariaIds';

    return {
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'recipientEmail': recipientEmail,
      'subject': subject,
      countFieldName: avariaCount,
      idsFieldName: avariaIds,
      'errorMessage': errorMessage,
      'userEmail': userEmail,
      'uf': uf,
      'metadata': metadata,
    };
  }

  factory EmailLog.fromMap(Map<String, dynamic> map, String id) {
    // Suporta tanto a convenção de nomes de campo antiga quanto a nova
    final count = map['licenseCount'] ?? map['avariaCount'] ?? 0;
    final ids = List<String>.from(map['licenseIds'] ?? map['avariaIds'] ?? []);

    return EmailLog(
      id: id,
      type: EmailType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => EmailType.test,
      ),
      status: EmailStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => EmailStatus.pending,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      recipientEmail: map['recipientEmail'] ?? '',
      subject: map['subject'] ?? '',
      avariaCount: count,
      avariaIds: ids,
      errorMessage: map['errorMessage'],
      userEmail: map['userEmail'],
      uf: map['uf'],
      metadata: map['metadata'],
    );
  }
}
