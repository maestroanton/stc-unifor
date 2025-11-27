import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audit_log.dart';
import '../services/audit_log.dart';
import '../core/visuals/dialogue.dart';

class ActivityTracker {
  static final ActivityTracker _instance = ActivityTracker._internal();
  factory ActivityTracker() => _instance;
  ActivityTracker._internal();

  static const int _inactivityTimeoutMinutes = 2 * 60;
  static const String _lastActivityKey = 'last_activity_timestamp';
  static const String _sessionStartKey = 'session_start_timestamp';

  Timer? _inactivityTimer;
  Timer? _periodicCheckTimer;
  DateTime? _lastActivityTime;
  bool _isTrackingActive = false;
  final AuditLogService _auditService = AuditLogService();

  /// Inicializa rastreamento de atividade
  Future<void> initializeTracking() async {
    if (_isTrackingActive) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Verifica timestamps salvos para restaurar estado de inatividade
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);
      final sessionStartString = prefs.getString(_sessionStartKey);

      if (lastActivityString != null) {
        // Restaura timestamp anterior; faz logout se expirado
        final persisted = DateTime.parse(lastActivityString);
        final now = DateTime.now();
        final inactiveMinutes = now.difference(persisted).inMinutes;

        if (inactiveMinutes >= _inactivityTimeoutMinutes) {
          // Sessão expirou enquanto app estava fechado; efetua logout
          await _performAutoLogout(inactiveMinutes);
          return;
        }

        _lastActivityTime = persisted;

        // Define início da sessão se não existir
        if (sessionStartString == null) {
          await _saveSessionStart(DateTime.now());
        }

        _isTrackingActive = true;
        _startPeriodicCheck();

        // Agenda timer com minutos restantes
        final remainingMinutes = _inactivityTimeoutMinutes - inactiveMinutes;
        _resetInactivityTimer(remainingMinutes);
      } else {
        // Inicia nova sessão
        _lastActivityTime = DateTime.now();
        await _saveActivityTimestamp(_lastActivityTime!);
        await _saveSessionStart(_lastActivityTime!);

        _startPeriodicCheck();
        _isTrackingActive = true;
      }

      // Log de login criado em login_page.dart; aqui apenas inicializa rastreamento
    } catch (e) {
      // Erro ao inicializar rastreamento
    }
  }

  /// Registra atividade do usuário
  Future<void> recordActivity() async {
    if (!_isTrackingActive) return;

    try {
      _lastActivityTime = DateTime.now();
      await _saveActivityTimestamp(_lastActivityTime!);
      _resetInactivityTimer();
    } catch (e) {
      // Erro ao registrar atividade
    }
  }

  /// Inicia verificação periódica de inatividade
  void _startPeriodicCheck() {
    // Verifica inatividade a cada minuto
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForInactivity();
    });
  }

  /// Verifica se usuário está inativo por tempo excessivo
  Future<void> _checkForInactivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        stopTracking();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);

      if (lastActivityString == null) {
          // Sem registro, inicia novo
        await recordActivity();
        return;
      }

      final lastActivity = DateTime.parse(lastActivityString);
      final now = DateTime.now();
      final inactiveMinutes = now.difference(lastActivity).inMinutes;

      // Aviso em 7,5 horas (450 minutos)
      if (inactiveMinutes >= 60 &&
          inactiveMinutes < _inactivityTimeoutMinutes) {
        _showInactivityWarning(inactiveMinutes);
      }

      // Logout automático em 8 horas (480 minutos)
      if (inactiveMinutes >= _inactivityTimeoutMinutes) {
        await _performAutoLogout(inactiveMinutes);
      }
    } catch (e) {
      // Erro ao verificar inatividade
    }
  }

  /// Exibe diálogo de aviso antes do logout automático
  void _showInactivityWarning(int inactiveMinutes) {
    final context = _getCurrentContext();
    if (context == null) return;

    final remainingMinutes = _inactivityTimeoutMinutes - inactiveMinutes;

    DialogUtils.showInactivityWarningDialog(
      context: context,
      remainingMinutes: remainingMinutes,
      onContinue: () async {
        await recordActivity(); // Reinicia timer
      },
      onLogout: () async {
        await _performAutoLogout(inactiveMinutes);
      },
    );
  }

  /// Executa logout automático
  Future<void> _performAutoLogout(int inactiveMinutes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Registra logout automático
      await _auditService.logAction(
        action: LogAction.logout,
        module: LogModule.system,
        description:
            'Logout automático por inatividade ($inactiveMinutes minutos)',
        metadata: {
          'reason': 'auto_logout_inactivity',
          'inactive_minutes': inactiveMinutes,
          'timeout_minutes': _inactivityTimeoutMinutes,
        },
      );

      // Para rastreamento
      stopTracking();

      // Limpa dados da sessão
      await _clearSessionData();

      // Encerra sessão no Firebase
      await FirebaseAuth.instance.signOut();

      // Exibe notificação de logout
      _showLogoutNotification(inactiveMinutes);

      // Logout automático executado após inatividade
    } catch (e) {
      // Erro ao executar logout automático
    }
  }

  /// Exibe notificação de logout
  void _showLogoutNotification(int inactiveMinutes) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.logout, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sessão encerrada por inatividade (${(inactiveMinutes / 60).toStringAsFixed(1)}h)',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );

    // Navega para tela de login
    Future.delayed(const Duration(seconds: 2), () {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    });
  }

  /// Reinicia timer de inatividade com tempo restante fornecido
  void _resetInactivityTimer([int? remainingMinutes]) {
    _inactivityTimer?.cancel();
    final minutes = remainingMinutes ?? _inactivityTimeoutMinutes;
    _inactivityTimer = Timer(
      Duration(minutes: minutes),
      () => _checkForInactivity(),
    );
  }

  /// Auxiliar público para tratar verificação de inatividade na inicialização
  /// do app. Útil chamar após serviços estarem prontos.
  Future<void> handleStartupInactivity() async {
    // Nada a fazer se rastreamento está ativo
    if (_isTrackingActive) return;

    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);

    if (lastActivityString == null) return;

    final persisted = DateTime.parse(lastActivityString);
    final now = DateTime.now();
    final inactiveMinutes = now.difference(persisted).inMinutes;

    if (inactiveMinutes >= _inactivityTimeoutMinutes) {
      await _performAutoLogout(inactiveMinutes);
      return;
    }

    // Restaura estado e inicia timers
    _lastActivityTime = persisted;
    _isTrackingActive = true;
    _startPeriodicCheck();
    final remainingMinutes = _inactivityTimeoutMinutes - inactiveMinutes;
    _resetInactivityTimer(remainingMinutes);
  }

  /// Para o rastreamento de atividade
  void stopTracking() {
    _inactivityTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _inactivityTimer = null;
    _periodicCheckTimer = null;
    _isTrackingActive = false;
    _lastActivityTime = null;
  }

  /// Salva timestamp de atividade
  Future<void> _saveActivityTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivityKey, timestamp.toIso8601String());
    } catch (e) {
      // Erro ao salvar timestamp
    }
  }

  /// Salva timestamp de início da sessão
  Future<void> _saveSessionStart(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStartKey, timestamp.toIso8601String());
    } catch (e) {
      // Erro ao salvar início da sessão
    }
  }

  /// Limpa os dados da sessão
  Future<void> _clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
      await prefs.remove(_sessionStartKey);
    } catch (e) {
      // Erro ao limpar dados da sessão
    }
  }

  /// Obtém contexto atual
  BuildContext? _getCurrentContext() {
    // Abordagem simplificada; prefira chave global do Navigator em produção
    return navigatorKey.currentContext;
  }

  /// Obtém informações da sessão para exibição
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);
      final sessionStartString = prefs.getString(_sessionStartKey);

      if (lastActivityString == null || sessionStartString == null) {
        return {'active': false};
      }

      final lastActivity = DateTime.parse(lastActivityString);
      final sessionStart = DateTime.parse(sessionStartString);
      final now = DateTime.now();

      final inactiveMinutes = now.difference(lastActivity).inMinutes;
      final sessionDurationMinutes = now.difference(sessionStart).inMinutes;
      final remainingMinutes = _inactivityTimeoutMinutes - inactiveMinutes;

      return {
        'active': _isTrackingActive,
        'lastActivity': lastActivity,
        'sessionStart': sessionStart,
        'inactiveMinutes': inactiveMinutes,
        'sessionDurationMinutes': sessionDurationMinutes,
        'remainingMinutes': remainingMinutes.clamp(
          0,
          _inactivityTimeoutMinutes,
        ),
        'timeoutMinutes': _inactivityTimeoutMinutes,
        'isNearTimeout': inactiveMinutes >= 450, // 7,5 horas
      };
    } catch (e) {
      // Erro ao obter informações da sessão
      return {'active': false, 'error': e.toString()};
    }
  }

  /// Estende sessão manualmente
  Future<void> extendSession() async {
    await recordActivity();

    await _auditService.logAction(
      action: LogAction.update,
      module: LogModule.system,
      description: 'Sessão estendida manualmente',
      metadata: {
        'action': 'session_extension',
        'extended_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Verifica validade da sessão
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);

      if (lastActivityString == null) return false;

      final lastActivity = DateTime.parse(lastActivityString);
      final now = DateTime.now();
      final inactiveMinutes = now.difference(lastActivity).inMinutes;

      return inactiveMinutes < _inactivityTimeoutMinutes;
    } catch (e) {
      // Erro ao verificar validade da sessão
      return false;
    }
  }

  /// Força logout
  Future<void> forceLogout({String? reason}) async {
    await _auditService.logAction(
      action: LogAction.logout,
      module: LogModule.system,
      description: 'Logout forçado${reason != null ? ': $reason' : ''}',
      metadata: {
        'reason': 'force_logout',
        'details': reason ?? 'manual_force_logout',
      },
    );

    stopTracking();
    await _clearSessionData();
    await FirebaseAuth.instance.signOut();
  }

  // Getters
  bool get isActive => _isTrackingActive;
  DateTime? get lastActivity => _lastActivityTime;
  int get timeoutMinutes => _inactivityTimeoutMinutes;
}

// Chave global do Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
