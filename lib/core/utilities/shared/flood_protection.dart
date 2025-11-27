// Utilitário de proteção contra envios duplicados
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Proteção contra flood para evitar envios duplicados
class FloodProtection {
  static final FloodProtection _instance = FloodProtection._internal();
  factory FloodProtection() => _instance;
  FloodProtection._internal();

  // Registra envios recentes por usuário e hash do conteúdo
  final Map<String, List<_SubmissionRecord>> _userSubmissions = {};

  // Registra envios ativos/em andamento
  final Set<String> _activeSubmissions = {};

  // Configuração
  static const Duration _duplicateWindow = Duration(minutes: 5);
  static const Duration _rapidSubmissionCooldown = Duration(seconds: 30);
  static const int _maxSubmissionsPerHour = 10;
  static const int _maxRapidSubmissions = 3;

  /// Verifica se o envio de uma requisição deve ser permitido
  Future<FloodProtectionResult> canSubmitRequest({
    required String toEmail,
    required String subject,
    required String description,
    String? justification,
    String? department,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      return FloodProtectionResult.denied('Usuário não autenticado');
    }

    final userEmail = user!.email!;
    final contentHash = _generateContentHash(
      toEmail: toEmail,
      subject: subject,
      description: description,
      justification: justification,
      department: department,
    );

    // Verifica se este envio exato está em andamento
    final activeKey = '${userEmail}_$contentHash';
    if (_activeSubmissions.contains(activeKey)) {
      return FloodProtectionResult.denied(
        'Esta requisição já está sendo processada. Por favor, aguarde.',
      );
    }

    // Remove registros antigos primeiro
    _cleanupOldRecords(userEmail);

    final userRecords = _userSubmissions[userEmail] ?? [];
    final now = DateTime.now();

    // Verifica duplicatas idênticas dentro do período recente
    final recentDuplicate = userRecords.where((record) {
      return record.contentHash == contentHash &&
          now.difference(record.timestamp) < _duplicateWindow;
    }).isNotEmpty;

    if (recentDuplicate) {
      return FloodProtectionResult.denied(
        'Requisição idêntica enviada recentemente. Aguarde ${_duplicateWindow.inMinutes} minutos antes de tentar novamente.',
      );
    }

    // Verifica envios rápidos (vários em curto período)
    final recentSubmissions = userRecords.where((record) {
      return now.difference(record.timestamp) < _rapidSubmissionCooldown;
    }).length;

    if (recentSubmissions >= _maxRapidSubmissions) {
      return FloodProtectionResult.denied(
        'Muitas requisições enviadas rapidamente. Aguarde ${_rapidSubmissionCooldown.inSeconds} segundos.',
      );
    }

    // Verifica limite de envios por hora
    final hourlySubmissions = userRecords.where((record) {
      return now.difference(record.timestamp) < const Duration(hours: 1);
    }).length;

    if (hourlySubmissions >= _maxSubmissionsPerHour) {
      return FloodProtectionResult.denied(
        'Limite de $_maxSubmissionsPerHour requisições por hora atingido. Tente novamente mais tarde.',
      );
    }

    // Todas as verificações passaram
    return FloodProtectionResult.allowed();
  }

  /// Marca um envio como iniciado (para prevenir submissões concorrentes)
  void markSubmissionStarted({
    required String toEmail,
    required String subject,
    required String description,
    String? justification,
    String? department,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final contentHash = _generateContentHash(
      toEmail: toEmail,
      subject: subject,
      description: description,
      justification: justification,
      department: department,
    );

    final activeKey = '${user!.email!}_$contentHash';
    _activeSubmissions.add(activeKey);

    // Limpeza automática após 5 minutos (caso de crashes)
    Timer(const Duration(minutes: 5), () {
      _activeSubmissions.remove(activeKey);
    });
  }

  /// Marca um envio como concluído (sucesso ou falha)
  void markSubmissionCompleted({
    required String toEmail,
    required String subject,
    required String description,
    String? justification,
    String? department,
    required bool success,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final userEmail = user!.email!;
    final contentHash = _generateContentHash(
      toEmail: toEmail,
      subject: subject,
      description: description,
      justification: justification,
      department: department,
    );

    // Remove das submissões ativas
    final activeKey = '${userEmail}_$contentHash';
    _activeSubmissions.remove(activeKey);

    // Só registra envios bem-sucedidos para prevenção de duplicatas
    if (success) {
      final userRecords = _userSubmissions[userEmail] ?? [];
      userRecords.add(
        _SubmissionRecord(contentHash: contentHash, timestamp: DateTime.now()),
      );
      _userSubmissions[userEmail] = userRecords;
    }
  }

  /// Gera hash do conteúdo da requisição para detectar duplicatas
  String _generateContentHash({
    required String toEmail,
    required String subject,
    required String description,
    String? justification,
    String? department,
  }) {
    final content = {
      'to': toEmail.toLowerCase().trim(),
      'subject': subject.trim(),
      'description': description.trim(),
      'justification': justification?.trim() ?? '',
      'department': department?.trim() ?? '',
    };

    final contentString = json.encode(content);
    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Remove registros antigos para evitar vazamento de memória
  void _cleanupOldRecords(String userEmail) {
    final userRecords = _userSubmissions[userEmail];
    if (userRecords == null) return;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    // Mantém apenas registros das últimas 24 horas
    final filteredRecords = userRecords.where((record) {
      return record.timestamp.isAfter(cutoff);
    }).toList();

    if (filteredRecords.isEmpty) {
      _userSubmissions.remove(userEmail);
    } else {
      _userSubmissions[userEmail] = filteredRecords;
    }
  }

  /// Retorna estatísticas de envios do usuário (debug/admin)
  Map<String, dynamic> getUserStats(String userEmail) {
    final userRecords = _userSubmissions[userEmail] ?? [];
    final now = DateTime.now();

    return {
      'totalToday': userRecords
          .where((r) => now.difference(r.timestamp) < const Duration(hours: 24))
          .length,
      'totalThisHour': userRecords
          .where((r) => now.difference(r.timestamp) < const Duration(hours: 1))
          .length,
      'lastSubmission': userRecords.isNotEmpty
          ? userRecords.last.timestamp.toIso8601String()
          : null,
      'activeSubmissions': _activeSubmissions
          .where((key) => key.startsWith(userEmail))
          .length,
    };
  }

  /// Limpa todos os registros de um usuário (função admin)
  void clearUserRecords(String userEmail) {
    _userSubmissions.remove(userEmail);
    _activeSubmissions.removeWhere((key) => key.startsWith(userEmail));
  }

  /// Limpeza global a ser executada periodicamente
  void performGlobalCleanup() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    // Remove registros antigos
    _userSubmissions.removeWhere((userEmail, records) {
      records.removeWhere((record) => record.timestamp.isBefore(cutoff));
      return records.isEmpty;
    });

    // Remove submissões ativas obsoletas (mais de 10 minutos)
    _activeSubmissions
        .clear(); // Abordagem simples: limpa tudo, pois devem expirar
  }
}

/// Resultado da checagem de proteção contra flood
class FloodProtectionResult {
  final bool isAllowed;
  final String? reason;

  const FloodProtectionResult._(this.isAllowed, this.reason);

  factory FloodProtectionResult.allowed() =>
      const FloodProtectionResult._(true, null);
  factory FloodProtectionResult.denied(String reason) =>
      FloodProtectionResult._(false, reason);
}

/// Registro interno de um envio de usuário
class _SubmissionRecord {
  final String contentHash;
  final DateTime timestamp;

  const _SubmissionRecord({required this.contentHash, required this.timestamp});
}

/// Extensão para integração simples da proteção contra flood
extension FloodProtectionWidget on Widget {
  /// Envolve qualquer widget com proteção contra flood
  Widget withFloodProtection({
    required VoidCallback? onTap,
    required Map<String, String> contentData,
    String? customMessage,
  }) {
    return _FloodProtectedWidget(
      onTap: onTap,
      contentData: contentData,
      customMessage: customMessage,
      child: this,
    );
  }
}

class _FloodProtectedWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Map<String, String> contentData;
  final String? customMessage;

  const _FloodProtectedWidget({
    required this.child,
    required this.onTap,
    required this.contentData,
    this.customMessage,
  });

  @override
  State<_FloodProtectedWidget> createState() => _FloodProtectedWidgetState();
}

class _FloodProtectedWidgetState extends State<_FloodProtectedWidget> {
  final FloodProtection _floodProtection = FloodProtection();
  bool _isChecking = false;

  Future<void> _handleTap() async {
    if (_isChecking || widget.onTap == null) return;

    setState(() => _isChecking = true);

    try {
      final result = await _floodProtection.canSubmitRequest(
        toEmail: widget.contentData['toEmail'] ?? '',
        subject: widget.contentData['subject'] ?? '',
        description: widget.contentData['description'] ?? '',
        justification: widget.contentData['justification'],
        department: widget.contentData['department'],
      );

      if (result.isAllowed) {
        widget.onTap!();
      } else {
        // Mostra mensagem de proteção contra flood
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.customMessage ?? result.reason ?? 'Ação bloqueada',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: _isChecking
          ? Opacity(opacity: 0.6, child: widget.child)
          : widget.child,
    );
  }
}
