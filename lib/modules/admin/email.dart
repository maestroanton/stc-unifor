// Gerenciamento de e-mails
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../helpers/database_helper_license.dart';
import '../../models/email_log.dart';
import '../../services/email_log.dart';
import '../../services/license_email.dart';

import '../../core/visuals/snackbar.dart';
import '../../core/visuals/status_indicator.dart';
import 'email_detail.dart';

class EmailManagementPage extends StatefulWidget {
  const EmailManagementPage({super.key});

  @override
  State<EmailManagementPage> createState() => _EmailManagementPageState();
}

class _EmailManagementPageState extends State<EmailManagementPage> {
  final EmailLogService _emailLogService = EmailLogService();
  final DatabaseHelperLicense _licenseHelper = DatabaseHelperLicense();

  List<EmailLog> _emailLogs = [];
  bool _isLoading = true;
  bool _isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sendManualLicenseEmail(EmailType type) async {
    setState(() => _isSendingEmail = true);

    try {
      final licenses = await _licenseHelper.getLicenses();
      bool success = false;
      String message = '';

      switch (type) {
        case EmailType.licenseWarning:
          success = await LicenseEmailService.sendWarningEmail(licenses);
          message = success
              ? 'Email de aviso de licenças enviado com sucesso!'
              : 'Nenhuma licença próxima do vencimento encontrada';
          break;
        case EmailType.licenseExpired:
          success = await LicenseEmailService.sendExpiredEmail(licenses);
          message = success
              ? 'Email de licenças vencidas enviado com sucesso!'
              : 'Nenhuma licença vencida encontrada';
          break;
        case EmailType.licenseTest:
          success = await LicenseEmailService.sendTestEmail();
          message = success
              ? 'Email de teste de licenças enviado com sucesso!'
              : 'Falha ao enviar email de teste de licenças';
          break;
        default:
          break;
      }

      // Atualiza exibição do SnackBar
      if (success) {
        if (mounted) SnackBarUtils.showSuccess(context, message);
      } else {
        if (mounted) SnackBarUtils.showWarning(context, message);
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao enviar email de licença: $e');
      }
    } finally {
      setState(() => _isSendingEmail = false);
    }
  }

  // Atualiza tratamento de erros em _loadData
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _emailLogService.getEmailLogs(limit: 100);

      setState(() {
        _emailLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar dados: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing12,
          vertical: AppDesignSystem.spacing24,
        ),
        padding: const EdgeInsets.all(AppDesignSystem.spacing24),
        decoration: BoxDecoration(
          color: AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          boxShadow: AppDesignSystem.shadowMD,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDesignSystem.spacing24),
            Expanded(
              child: _buildLicenseEmailTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.email_outlined,
          size: 24,
          color: AppDesignSystem.neutral900,
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Text(
          'Gerenciamento de Emails',
          style: AppDesignSystem.h2.copyWith(color: AppDesignSystem.neutral900),
        ),
        const Spacer(),
        IconButton(
          onPressed: _isLoading ? null : _loadData,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppDesignSystem.primary,
                  ),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  Widget _buildLicenseEmailTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLicenseEmailControls(),
              const SizedBox(height: AppDesignSystem.spacing24),
            ],
          ),
        ),
        Expanded(child: _buildEmailLogsList(isLicense: true)),
      ],
    );
  }

  Widget _buildLicenseEmailControls() {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing20),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacing6),
                decoration: BoxDecoration(
                  color: AppDesignSystem.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: const Icon(
                  Icons.card_membership_outlined,
                  size: 16,
                  color: AppDesignSystem.info,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                'Envio Manual de Emails - Licenças',
                style: AppDesignSystem.labelLarge.copyWith(
                  color: AppDesignSystem.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing20),
          Wrap(
            spacing: AppDesignSystem.spacing16,
            runSpacing: AppDesignSystem.spacing12,
            children: [
              _buildEmailButton(
                'Enviar Avisos',
                'Licenças próximas do vencimento (30 dias)',
                Icons.card_membership,
                AppDesignSystem.info,
                () => _sendManualLicenseEmail(EmailType.licenseWarning),
              ),
              _buildEmailButton(
                'Enviar Vencidas',
                'Licenças que já estão vencidas',
                Icons.schedule,
                AppDesignSystem.error,
                () => _sendManualLicenseEmail(EmailType.licenseExpired),
              ),
              _buildEmailButton(
                'Teste Licença',
                'Enviar email de teste',
                Icons.science,
                AppDesignSystem.primary,
                () => _sendManualLicenseEmail(EmailType.licenseTest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 240,
      height: 70,
      child: OutlinedButton(
        onPressed: _isSendingEmail ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppDesignSystem.neutral300, width: 1),
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          backgroundColor: AppDesignSystem.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
              child: Center(child: Icon(icon, color: color, size: 16)),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppDesignSystem.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppDesignSystem.neutral700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesignSystem.spacing2),
                  Text(
                    subtitle,
                    style: AppDesignSystem.labelSmall.copyWith(
                      color: AppDesignSystem.neutral500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailLogsList({required bool isLicense}) {
    final filteredLogs = _emailLogs.where((log) {
      if (isLicense) {
        return log.isLicenseEmail;
      } else {
        return log.isAvariaEmail;
      }
    }).toList();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppDesignSystem.primary),
      );
    }

    if (filteredLogs.isEmpty) {
      return _buildEmptyState(isLicense);
    }

    return Column(
      children: [
        _buildTableHeader(),
        const SizedBox(height: AppDesignSystem.spacing8),
        Expanded(
          child: ListView.builder(
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              return _buildEmailLogItem(filteredLogs[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isLicense) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLicense ? Icons.card_membership_outlined : Icons.email_outlined,
            size: 64,
            color: AppDesignSystem.neutral400,
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Text(
            'Nenhum email ${isLicense ? 'de licença' : 'de avaria'} encontrado',
            style: AppDesignSystem.h3.copyWith(
              color: AppDesignSystem.neutral600,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            'Envie alguns emails para vê-los listados aqui',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Tipo',
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          SizedBox(
            width: 100,
            child: Text(
              'Status',
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          SizedBox(
            width: 120,
            child: Text(
              'Data & Hora',
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Text(
              'Assunto',
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Itens',
              textAlign: TextAlign.center,
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLogItem(EmailLog log, int index) {
    final backgroundColor = index.isEven
        ? AppDesignSystem.surface
        : AppDesignSystem.neutral50;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToEmailDetail(log),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing12,
          ),
          child: Row(
            children: [
              // Coluna Tipo (DotIndicators.standard)
              SizedBox(
                width: 100,
                child: DotIndicators.standard(
                  text: _getShortTypeDisplayName(log.type),
                  dotColor: log.typeColor,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              // Coluna Status (DotIndicators.standard)
              SizedBox(
                width: 100,
                child: DotIndicators.standard(
                  text: _getShortStatusDisplayName(log.status),
                  dotColor: log.statusColor,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              // Coluna Data e Hora
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(log.timestamp),
                      style: AppDesignSystem.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(log.timestamp),
                      style: AppDesignSystem.labelSmall.copyWith(
                        color: AppDesignSystem.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              // Coluna Assunto (fonte reduzida)
              Expanded(
                child: Text(
                  log.subject,
                  style: AppDesignSystem.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              // Coluna Quantidade de itens
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacing8,
                      vertical: AppDesignSystem.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.neutral100,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusL,
                      ),
                    ),
                    child: Text(
                      log.avariaCount.toString(),
                      style: AppDesignSystem.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEmailDetail(EmailLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailLogDetailPage(emailLog: log),
      ),
    );
  }

  String _getShortTypeDisplayName(EmailType type) {
    switch (type) {
      case EmailType.warning:
        return 'Aviso';
      case EmailType.overdue:
        return 'Atrasada';
      case EmailType.test:
        return 'Teste';
      case EmailType.licenseWarning:
        return 'Aviso';
      case EmailType.licenseExpired:
        return 'Vencida';
      case EmailType.licenseTest:
        return 'Teste';
    }
  }

  String _getShortStatusDisplayName(EmailStatus status) {
    switch (status) {
      case EmailStatus.sent:
        return 'Enviado';
      case EmailStatus.failed:
        return 'Falhou';
      case EmailStatus.pending:
        return 'Pendente';
    }
  }
}
