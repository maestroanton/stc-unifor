import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


enum LogAction {
  create,
  update,
  delete,
  restore,
  view,
  export,
  login,
  logout,
  duplicate,
  backup,
}

enum LogModule { avaria, inventario, user, system }

class AuditLog {
  final String? id;
  final String userId;
  final String userEmail;
  final String? userDisplayName;
  final String uf;
  final bool isAdmin;
  final LogAction action;
  final LogModule module;
  final String? recordId;
  final String? recordIdentifier; // Identificador do registro (nota, DANFE, etc.)
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLog({
    this.id,
    required this.userId,
    required this.userEmail,
    this.userDisplayName,
    required this.uf,
    this.isAdmin = false,
    required this.action,
    required this.module,
    this.recordId,
    this.recordIdentifier,
    this.oldData,
    this.newData,
    this.description,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.metadata,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    return AuditLog(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userDisplayName: map['userDisplayName'],
      uf: map['uf'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      action: _parseAction(map['action']),
      module: _parseModule(map['module']),
      recordId: map['recordId'],
      recordIdentifier: map['recordIdentifier'],
      oldData:
          map['oldData'] != null
              ? Map<String, dynamic>.from(map['oldData'])
              : null,
      newData:
          map['newData'] != null
              ? Map<String, dynamic>.from(map['newData'])
              : null,
      description: map['description'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata:
          map['metadata'] != null
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      if (userDisplayName != null) 'userDisplayName': userDisplayName,
      'uf': uf,
      'isAdmin': isAdmin,
      'action': action.name,
      'module': module.name,
      if (recordId != null) 'recordId': recordId,
      if (recordIdentifier != null) 'recordIdentifier': recordIdentifier,
      if (oldData != null) 'oldData': oldData,
      if (newData != null) 'newData': newData,
      if (description != null) 'description': description,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      'timestamp': Timestamp.fromDate(timestamp),
      if (metadata != null) 'metadata': metadata,
    };
  }

  static LogAction _parseAction(String? action) {
    switch (action?.toLowerCase()) {
      case 'create':
        return LogAction.create;
      case 'update':
        return LogAction.update;
      case 'delete':
        return LogAction.delete;
      case 'restore':
        return LogAction.restore;
      case 'view':
        return LogAction.view;
      case 'export':
        return LogAction.export;
      case 'login':
        return LogAction.login;
      case 'logout':
        return LogAction.logout;
      case 'duplicate':
        return LogAction.duplicate;
      case 'backup':
        return LogAction.backup;
      default:
        return LogAction.view;
    }
  }

  static LogModule _parseModule(String? module) {
    switch (module?.toLowerCase()) {
      case 'avaria':
        return LogModule.avaria;
      case 'inventario':
        return LogModule.inventario;
      case 'user':
        return LogModule.user;
      case 'system':
        return LogModule.system;
      default:
        return LogModule.system;
    }
  }

  String get actionDisplayName {
    switch (action) {
      case LogAction.create:
        return 'Criado';
      case LogAction.update:
        return 'Editado';
      case LogAction.delete:
        return 'Excluído';
      case LogAction.restore:
        return 'Restaurado';
      case LogAction.view:
        return 'Visualizado';
      case LogAction.export:
        return 'Exportado';
      case LogAction.login:
        return 'Login';
      case LogAction.logout:
        return 'Logout';
      case LogAction.duplicate:
        return 'Duplicado';
      case LogAction.backup:
        return 'Backup';
    }
  }

  String get moduleDisplayName {
    switch (module) {
      case LogModule.avaria:
        return 'Avaria';
      case LogModule.inventario:
        return 'Inventário';
      case LogModule.user:
        return 'Usuário';
      case LogModule.system:
        return 'Sistema';
    }
  }

  Color get actionColor {
    switch (action) {
      case LogAction.create:
      case LogAction.duplicate:
        return const Color(0xFF4CAF50); // Verde
      case LogAction.update:
        return const Color(0xFF2196F3); // Azul
      case LogAction.delete:
      case LogAction.backup:
        return const Color(0xFFE53E3E); // Vermelho
      case LogAction.restore:
        return const Color(0xFF9C27B0); // Roxo
      case LogAction.view:
        return const Color(0xFF757575); // Cinza
      case LogAction.export:
        return const Color(0xFFFF9800); // Laranja
      case LogAction.login:
        return const Color(0xFF4CAF50); // Verde
      case LogAction.logout:
        return const Color(0xFFFF5722); // Laranja escuro
    }
  }

  IconData get actionIcon {
    switch (action) {
      case LogAction.create:
        return Icons.add_circle_outline;
      case LogAction.update:
        return Icons.edit_outlined;
      case LogAction.delete:
        return Icons.delete_outline;
      case LogAction.restore:
        return Icons.restore_outlined;
      case LogAction.view:
        return Icons.visibility_outlined;
      case LogAction.export:
        return Icons.download_outlined;
      case LogAction.login:
        return Icons.login_outlined;
      case LogAction.logout:
        return Icons.logout_outlined;
      case LogAction.duplicate:
        return Icons.content_copy_outlined;
      case LogAction.backup:
        return Icons.backup_outlined;
    }
  }
}
