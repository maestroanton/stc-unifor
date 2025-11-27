// Nota: Agendamento de email movido para Firebase Functions
// Este gerenciador de serviços agora apenas lida com limpeza de auditoria se necessário localmente
import 'package:flutter/foundation.dart';

/// Gerencia serviços de background restantes para a aplicação
/// Notificações por email agora são tratadas por Firebase Functions
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  // Email scheduler removido - agora tratado por Firebase Functions

  bool _isInitialized = false;

  /// Inicializa serviços de background restantes
  /// Nota: Agendamento de email movido para Firebase Functions
  Future<void> initializeAllServices() async {
    if (_isInitialized) return;

    try {
      // Agendamento de email tratado por Firebase Functions

      // Limpeza de auditoria também pode ser movida para Firebase Functions se necessário

      _isInitialized = true;
      debugPrint(
        '✓ Gerenciador de serviços inicializado (serviços de email movidos para Firebase Functions)',
      );
    } catch (e) {
      debugPrint('✗ Erro ao inicializar serviços: $e');
      rethrow;
    }
  }

  /// Para os serviços de background restantes
  void stopAllServices() {
    try {
      // Scheduler de email parado - agora tratado por Firebase Functions

      _isInitialized = false;
      debugPrint(
        '✓ Serviços parados (serviços de email movidos para Firebase Functions)',
      );
    } catch (e) {
      debugPrint('✗ Erro ao parar serviços: $e');
    }
  }

  /// Scheduler de email removido - agora tratado por Firebase Functions

  /// Limpeza de auditoria removida - agora tratada por Firebase Functions

  /// Verifica se os serviços foram inicializados
  bool get isInitialized => _isInitialized;

  /// Obtém status de todos os serviços
  Map<String, bool> getServicesStatus() {
    return {
      'email_scheduler': false, // Agora tratado por Firebase Functions
      'audit_cleanup': false, // Agora tratado por Firebase Functions
      'manager_initialized': _isInitialized,
    };
  }
}
