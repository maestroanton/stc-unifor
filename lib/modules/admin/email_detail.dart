// Detalhes do log de email
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../core/visuals/status_indicator.dart';
import '../../models/email_log.dart';

class EmailLogDetailPage extends StatefulWidget {
  final EmailLog emailLog;

  const EmailLogDetailPage({super.key, required this.emailLog});

  @override
  State<EmailLogDetailPage> createState() => _EmailLogDetailPageState();
}

class _EmailLogDetailPageState extends State<EmailLogDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        title: const Text('Detalhes do Email'),
        backgroundColor: AppDesignSystem.primary,
        foregroundColor: AppDesignSystem.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showRawDataDialog(context),
            icon: const Icon(Icons.code),
            tooltip: 'Ver dados brutos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmailHeader(context),
            const SizedBox(height: AppDesignSystem.spacing16),
            _buildEmailDetails(context),
            const SizedBox(height: AppDesignSystem.spacing16),
            _buildRecipientInfo(context),
            if (widget.emailLog.avariaCount > 0) ...[
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildAvariaInfo(context),
            ],
            if (widget.emailLog.errorMessage != null) ...[
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildErrorInfo(context),
            ],
            if (widget.emailLog.metadata != null &&
                widget.emailLog.metadata!.isNotEmpty) ...[
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildMetadata(context),
            ],
            const SizedBox(height: AppDesignSystem.spacing16),
            _buildTimestamp(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Row(
        children: [
          DotIndicators.large(
            text: widget.emailLog.statusDisplayName,
            dotColor: widget.emailLog.statusColor,
            emphasizeText: true,
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        '${widget.emailLog.typeDisplayName} • ${widget.emailLog.statusDisplayName}',
                        style: AppDesignSystem.h3.copyWith(
                          color: AppDesignSystem.neutral800,
                        ),
                      ),
                    ),
                    DotIndicators.emphasized(
                      text: widget.emailLog.typeDisplayName,
                      color: widget.emailLog.typeColor,
                    ),
                    const SizedBox(width: AppDesignSystem.spacing8),
                    DotIndicators.emphasized(
                      text: widget.emailLog.statusDisplayName,
                      color: widget.emailLog.statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                SelectableText(
                  widget.emailLog.subject,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppDesignSystem.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes do Email',
            style: AppDesignSystem.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.neutral700,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          _buildSimpleInfoRow('Tipo', widget.emailLog.typeDisplayName),
          _buildSimpleInfoRow('Status', widget.emailLog.statusDisplayName),
          _buildSimpleInfoRow('Assunto', widget.emailLog.subject),
          if (widget.emailLog.avariaCount > 0)
            _buildSimpleInfoRow(
              'Avarias Incluídas',
              '${widget.emailLog.avariaCount} avaria${widget.emailLog.avariaCount != 1 ? 's' : ''}',
            ),
        ],
      ),
    );
  }

  Widget _buildRecipientInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Destinatário',
            style: AppDesignSystem.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.neutral700,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          _buildSimpleInfoRow(
            'Email do Destinatário',
            widget.emailLog.recipientEmail,
          ),
          if (widget.emailLog.userEmail != null)
            _buildSimpleInfoRow('Enviado por', widget.emailLog.userEmail!),
          if (widget.emailLog.uf != null)
            _buildSimpleInfoRow(
              'UF',
              widget.emailLog.uf!,
              badge: widget.emailLog.uf!,
              badgeColor: widget.emailLog.uf == 'CE'
                  ? AppDesignSystem.success
                  : AppDesignSystem.info,
            ),
        ],
      ),
    );
  }

  Widget _buildAvariaInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avarias Relacionadas',
            style: AppDesignSystem.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.neutral700,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          _buildSimpleInfoRow(
            'Quantidade',
            '${widget.emailLog.avariaCount} avaria${widget.emailLog.avariaCount != 1 ? 's' : ''}',
          ),
          if (widget.emailLog.avariaIds.isNotEmpty) ...[
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              'IDs das Avarias:',
              style: AppDesignSystem.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.neutral600,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              decoration: BoxDecoration(
                color: AppDesignSystem.neutral50,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                border: Border.all(color: AppDesignSystem.neutral200),
              ),
              child: Wrap(
                spacing: AppDesignSystem.spacing8,
                runSpacing: AppDesignSystem.spacing4,
                children: widget.emailLog.avariaIds.map((id) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacing6,
                      vertical: AppDesignSystem.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusXS,
                      ),
                      border: Border.all(
                        color: AppDesignSystem.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectableText(
                      id,
                      style: AppDesignSystem.labelSmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppDesignSystem.info,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: AppDesignSystem.errorLight,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        border: Border.all(color: AppDesignSystem.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppDesignSystem.error,
                size: 16,
              ),
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                'Informações do Erro',
                style: AppDesignSystem.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppDesignSystem.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignSystem.spacing12),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              border: Border.all(
                color: AppDesignSystem.error.withValues(alpha: 0.3),
              ),
            ),
            child: SelectableText(
              widget.emailLog.errorMessage!,
              style: AppDesignSystem.bodySmall.copyWith(
                color: AppDesignSystem.error,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadados',
            style: AppDesignSystem.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.neutral700,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          ...widget.emailLog.metadata!.entries.map(
            (entry) => _buildSimpleInfoRow(
              _formatFieldName(entry.key),
              _formatValue(entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de Timestamp',
            style: AppDesignSystem.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.neutral700,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          _buildSimpleInfoRow(
            'Data e Hora',
            DateFormat(
              'dd/MM/yyyy • HH:mm:ss',
            ).format(widget.emailLog.timestamp),
          ),
          _buildSimpleInfoRow(
            'Data Completa',
            DateFormat('dd/MM/yyyy').format(widget.emailLog.timestamp),
          ),
          _buildSimpleInfoRow(
            'Timestamp Unix',
            widget.emailLog.timestamp.millisecondsSinceEpoch.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow(
    String label,
    String value, {
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppDesignSystem.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: AppDesignSystem.labelMedium.copyWith(
                      color: AppDesignSystem.neutral800,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacing6,
                      vertical: AppDesignSystem.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          badgeColor?.withValues(alpha: 0.1) ??
                          AppDesignSystem.neutral100,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusS,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: AppDesignSystem.labelSmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: badgeColor ?? AppDesignSystem.neutral600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFieldName(String field) {
    final fieldNames = {
      'template_id': 'Template ID',
      'days_threshold': 'Limite de Dias',
      'max_days_overdue': 'Máximo de Dias Atrasado',
      'reason': 'Motivo',
      'is_test': 'É Teste',
      'updated_count': 'Quantidade Atualizada',
      'service_id': 'Service ID',
      'user_id': 'User ID',
    };

    return fieldNames[field] ??
        field
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '(vazio)';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (value is String && value.isEmpty) return '(vazio)';
    if (value is num) {
      if (value is double) {
        return value.toStringAsFixed(2);
      }
      return value.toString();
    }
    return value.toString();
  }

  void _showRawDataDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          side: const BorderSide(color: AppDesignSystem.neutral200),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing24),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusM,
                      ),
                    ),
                    child: const Icon(
                      Icons.code,
                      color: AppDesignSystem.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dados Brutos do Email',
                          style: AppDesignSystem.h3.copyWith(
                            color: AppDesignSystem.neutral800,
                          ),
                        ),
                        const SizedBox(height: AppDesignSystem.spacing4),
                        Text(
                          'Informações técnicas completas',
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: AppDesignSystem.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignSystem.spacing20),
              // Conteúdo
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.neutral50,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusM,
                      ),
                      border: Border.all(color: AppDesignSystem.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppDesignSystem.neutral600,
                              size: 16,
                            ),
                            const SizedBox(width: AppDesignSystem.spacing8),
                            Text(
                              'Dados Completos do Email Log:',
                              style: AppDesignSystem.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppDesignSystem.neutral700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDesignSystem.spacing12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppDesignSystem.spacing12,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesignSystem.surface,
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.radiusS,
                            ),
                            border: Border.all(
                              color: AppDesignSystem.neutral200,
                            ),
                          ),
                          child: SelectableText(
                            _formatEmailLogData(),
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              color: AppDesignSystem.neutral700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacing24),
              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: AppDesignSystem.primary,
                        foregroundColor: AppDesignSystem.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing16,
                        ),
                      ),
                      child: Text(
                        'Fechar',
                        style: AppDesignSystem.labelMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppDesignSystem.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEmailLogData() {
    final buffer = StringBuffer();
    buffer.writeln('ID: ${widget.emailLog.id ?? 'N/A'}');
    buffer.writeln('Tipo: ${widget.emailLog.type}');
    buffer.writeln('Status: ${widget.emailLog.status}');
    buffer.writeln('Timestamp: ${widget.emailLog.timestamp.toIso8601String()}');
    buffer.writeln('Email Destinatário: ${widget.emailLog.recipientEmail}');
    buffer.writeln('Assunto: ${widget.emailLog.subject}');
    buffer.writeln('Quantidade de Avarias: ${widget.emailLog.avariaCount}');
    buffer.writeln('IDs das Avarias: ${widget.emailLog.avariaIds}');
    buffer.writeln(
      'Mensagem de Erro: ${widget.emailLog.errorMessage ?? 'N/A'}',
    );
    buffer.writeln('Email do Usuário: ${widget.emailLog.userEmail ?? 'N/A'}');
    buffer.writeln('UF: ${widget.emailLog.uf ?? 'N/A'}');
    buffer.writeln('Metadados: ${widget.emailLog.metadata ?? 'N/A'}');
    return buffer.toString();
  }
}
