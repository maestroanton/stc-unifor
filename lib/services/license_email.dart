// lib/services/license_email_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/license.dart';
import '../models/email_log.dart';
import 'email_log.dart';

class LicenseEmailService {
  static const String _serviceId = 'service_gkr2xu7';
  static const String _templateIdWarning = 'template_ydzo3gj';
  static const String _templateIdExpired = 'template_ydzo3gj';
  static const String _publicKey = 'IbAJxit6WycaHDf2W';
  static const String _emailJsUrl =
      'https://api.emailjs.com/api/v1.0/email/send';
  static const String _recipientEmail = 'antongmsob@gmail.com';
  static const String _fromEmail = 'glasseredita@outlook.com';

  static final EmailLogService _logService = EmailLogService();

  /// Verifica se uma License está dentro de um número de dias especificado para expirar
  static bool isWithinDaysOfExpiring(License license, int days) {
    // Verifica apenas licenças que ainda não estão vencidas
    if (license.status == LicenseStatus.vencida) return false;
    if (license.dataVencimento.isEmpty) return false;

    try {
      final parts = license.dataVencimento.split('-');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final vencimento = DateTime(year, month, day);
      final now = DateTime.now();
      final daysUntilExpiry = vencimento.difference(now).inDays;

      return daysUntilExpiry <= days && daysUntilExpiry > 0;
    } catch (e) {
      debugPrint('Error parsing date for License ${license.id}: $e');
      return false;
    }
  }

  static bool isExpired(License license) {
    // Já marcada como vencida
    if (license.status == LicenseStatus.vencida) return true;

    // Verifica apenas licenças com status válidos ou próximas do vencimento
    if (license.status != LicenseStatus.valida &&
        license.status != LicenseStatus.proximoVencimento) {
      return false;
    }

    if (license.dataVencimento.isEmpty) return false;

    try {
      final parts = license.dataVencimento.split('-');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final vencimento = DateTime(year, month, day);
      final now = DateTime.now();
      return now.isAfter(vencimento);
    } catch (e) {
      return false;
    }
  }

  /// Retorna dias restantes até o vencimento (retorna negativo se já expirado)
  static int getRemainingDays(License license) {
    if (license.dataVencimento.isEmpty) return 0;

    try {
      final parts = license.dataVencimento.split('-');
      if (parts.length != 3) return 0;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final vencimento = DateTime(year, month, day);
      final now = DateTime.now();
      return vencimento.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Envia email de aviso para licenças que expirarão dentro de 30 dias
  static Future<bool> sendWarningEmail(List<License> allLicenses) async {
    try {
      final warningLicenses = allLicenses
          .where((l) => isWithinDaysOfExpiring(l, 30))
          .toList();

      if (warningLicenses.isEmpty) {
        await _logService.logEmailSent(
          type: EmailType
              .licenseWarning, // CORRIGIDO: Usa o tipo específico para license
          status: EmailStatus.failed,
          recipientEmail: _recipientEmail,
          subject: 'Aviso: Nenhuma licença próxima do vencimento',
          avariaCount: 0,
          avariaIds: [],
          errorMessage: 'Nenhuma licença encontrada para enviar aviso',
          metadata: {'reason': 'no_licenses_found', 'module': 'licenses'},
        );
        return false;
      }

      final templateParams = {
        'from_name': 'Sistema de Licenças GISTC',
        'to_email': _recipientEmail,
        'from_email': _fromEmail,
        'subject':
            'Aviso: ${warningLicenses.length} licença${warningLicenses.length != 1 ? 's' : ''} próxima${warningLicenses.length != 1 ? 's' : ''} do vencimento',
        'total_count': warningLicenses.length.toString(),
        'licenses_list': _createWarningLicensesList(warningLicenses),
        'current_date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      };

      final success = await _sendEmail(templateParams, _templateIdWarning);

      await _logService.logEmailSent(
        type: EmailType.licenseWarning,
        status: success ? EmailStatus.sent : EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: templateParams['subject']!,
        licenseCount: warningLicenses.length,
        licenseIds: warningLicenses.map((l) => l.id!).toList(),
        errorMessage: success ? null : 'Falha ao enviar email via EmailJS',
        metadata: {
          'template_id': _templateIdWarning,
          'days_threshold': 30,
          'module': 'licenses',
        },
      );

      return success;
    } catch (e) {
      await _logService.logEmailSent(
        type: EmailType.licenseWarning,
        status: EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: 'Erro ao processar aviso de licenças',
        licenseCount: 0,
        licenseIds: [],
        errorMessage: e.toString(),
        metadata: {'module': 'licenses'},
      );
      return false;
    }
  }

  /// Envia email de aviso para licenças que já estão vencidas
  static Future<bool> sendExpiredEmail(List<License> allLicenses) async {
    try {
      final expiredLicenses = allLicenses.where((l) => isExpired(l)).toList();

      if (expiredLicenses.isEmpty) {
        await _logService.logEmailSent(
          type: EmailType
              .licenseExpired, // CORRIGIDO: Usa o tipo específico para license
          status: EmailStatus.failed,
          recipientEmail: _recipientEmail,
          subject: 'Aviso: Nenhuma licença vencida',
          avariaCount: 0,
          avariaIds: [],
          errorMessage: 'Nenhuma licença vencida encontrada',
          metadata: {'reason': 'no_expired_licenses', 'module': 'licenses'},
        );
        return false;
      }

      final maxDaysExpired = expiredLicenses
          .map((l) => -getRemainingDays(l))
          .reduce((a, b) => a > b ? a : b);

      final templateParams = {
        'from_name': 'Sistema de Licenças GISTC',
        'to_email': _recipientEmail,
        'from_email': _fromEmail,
        'subject':
            'URGENTE: ${expiredLicenses.length} licença${expiredLicenses.length != 1 ? 's' : ''} vencida${expiredLicenses.length != 1 ? 's' : ''}',
        'total_count': expiredLicenses.length.toString(),
        'max_days_expired': maxDaysExpired.toString(),
        'licenses_list': _createExpiredLicensesList(expiredLicenses),
        'current_date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      };

      final success = await _sendEmail(templateParams, _templateIdExpired);

      await _logService.logEmailSent(
        type: EmailType.licenseExpired,
        status: success ? EmailStatus.sent : EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: templateParams['subject']!,
        licenseCount: expiredLicenses.length,
        licenseIds: expiredLicenses.map((l) => l.id!).toList(),
        errorMessage: success ? null : 'Falha ao enviar email via EmailJS',
        metadata: {
          'template_id': _templateIdExpired,
          'max_days_expired': maxDaysExpired,
          'module': 'licenses',
        },
      );

      return success;
    } catch (e) {
      await _logService.logEmailSent(
        type: EmailType.licenseExpired,
        status: EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: 'Erro ao processar licenças vencidas',
        licenseCount: 0,
        licenseIds: [],
        errorMessage: e.toString(),
        metadata: {'module': 'licenses'},
      );
      return false;
    }
  }

  /// Envia email de teste para o sistema de licenças
  static Future<bool> sendTestEmail() async {
    try {
      final templateParams = {
        'from_name': 'Sistema de Licenças GISTC',
        'to_email': _recipientEmail,
        'from_email': _fromEmail,
        'subject': 'Teste - Sistema de Emails de Licenças',
        'message':
            'Este é um email de teste do sistema de gerenciamento de licenças.',
        'current_date': DateFormat(
          'dd/MM/yyyy HH:mm:ss',
        ).format(DateTime.now()),
      };

      // Usa o template de aviso para teste (você pode criar um template específico para teste)
      final success = await _sendEmail(templateParams, _templateIdWarning);

      await _logService.logEmailSent(
        type: EmailType.licenseTest,
        status: success ? EmailStatus.sent : EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: templateParams['subject']!,
        licenseCount: 0,
        licenseIds: [],
        errorMessage: success ? null : 'Falha ao enviar email de teste',
        metadata: {'is_test': true, 'module': 'licenses'},
      );

      return success;
    } catch (e) {
      await _logService.logEmailSent(
        type: EmailType.licenseTest,
        status: EmailStatus.failed,
        recipientEmail: _recipientEmail,
        subject: 'Erro no teste de email de licenças',
        licenseCount: 0,
        licenseIds: [],
        errorMessage: e.toString(),
        metadata: {'module': 'licenses'},
      );
      return false;
    }
  }

  /// Envia todas as notificações aplicáveis de license
  static Future<Map<String, bool>> sendAllNotifications(
    List<License> allLicenses,
  ) async {
    return {
      'warning': await sendWarningEmail(allLicenses),
      'expired': await sendExpiredEmail(allLicenses),
    };
  }

  // Métodos auxiliares privados
  static String _createWarningLicensesList(List<License> licenses) {
    // Limitar às primeiras 20 licenças para evitar problemas de payload no EmailJS
    final limitedLicenses = licenses.take(20).toList();
    final list = limitedLicenses
        .map((license) {
          final remainingDays = getRemainingDays(license);
          final statusText = remainingDays > 1
              ? '$remainingDays dias restantes'
              : '$remainingDays dia restante';
          return '${license.nome} - UF: ${license.uf} ($statusText)';
        })
        .join('\n');

    if (licenses.length > 20) {
      return '$list\n\n... e mais ${licenses.length - 20} licença(s)';
    }
    return list;
  }

  static String _createExpiredLicensesList(List<License> licenses) {
    // Limitar às primeiras 20 licenças para evitar problemas de payload no EmailJS
    final limitedLicenses = licenses.take(20).toList();
    final list = limitedLicenses
        .map((license) {
          final daysExpired = -getRemainingDays(license);
          final statusText = daysExpired > 1
              ? '$daysExpired dias vencida'
              : '$daysExpired dia vencida';
          return '${license.nome} - UF: ${license.uf} ($statusText)';
        })
        .join('\n');

    if (licenses.length > 20) {
      return '$list\n\n... e mais ${licenses.length - 20} licença(s)';
    }
    return list;
  }

  static Future<bool> _sendEmail(
    Map<String, dynamic> templateParams,
    String templateId,
  ) async {
    try {
      final requestBody = {
        'service_id': _serviceId,
        'template_id': templateId,
        'user_id': _publicKey,
        'template_params': templateParams,
      };

      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint(
          'License email sent successfully with template: $templateId',
        );
        return true;
      } else {
        debugPrint(
          'Failed to send license email: ${response.statusCode} - ${response.body}',
        );
        debugPrint('Request body: ${jsonEncode(requestBody)}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending license email: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
