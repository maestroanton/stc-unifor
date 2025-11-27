// Detalhes do log de auditoria
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log.dart';
import '../../core/visuals/snackbar.dart';
import '../../core/visuals/dialogue.dart';
import '../../core/design_system.dart';

class AuditLogDetailPage extends StatefulWidget {
  final AuditLog log;

  const AuditLogDetailPage({super.key, required this.log});

  @override
  State<AuditLogDetailPage> createState() => _AuditLogDetailPageState();
}

class _AuditLogDetailPageState extends State<AuditLogDetailPage> {
  final AuditLogService _auditService = AuditLogService();
  bool _isReverting = false;
  bool _hasBeenReverted = false;
  bool _isCheckingRevertStatus = true;

  @override
  void initState() {
    super.initState();
    _checkIfReverted();
  }

  Future<void> _checkIfReverted() async {
    if (_canRevert()) {
      final reverted = await _auditService.hasBeenReverted(widget.log.id!);
      setState(() {
        _hasBeenReverted = reverted;
        _isCheckingRevertStatus = false;
      });
    } else {
      setState(() {
        _isCheckingRevertStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        title: const Text('Detalhes da Auditoria'),
        backgroundColor: AppDesignSystem.primary,
        foregroundColor: AppDesignSystem.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showRawDataDialog(context),
            icon: const Icon(Icons.code),
            tooltip: 'Ver dados brutos',
          ),
          if (_canRevert() &&
              !_hasBeenReverted &&
              !_isCheckingRevertStatus) ...[
            IconButton(
              onPressed: _isReverting ? null : () => _showRevertDialog(context),
              icon: _isReverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppDesignSystem.surface,
                        ),
                      ),
                    )
                  : const Icon(Icons.undo),
              tooltip: 'Reverter alteração',
            ),
          ],
        ],
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignSystem.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogHeader(context),
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildUserInfo(context),
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildActionDetails(context),
              if (_hasDataChanges()) ...[
                const SizedBox(height: AppDesignSystem.spacing16),
                _buildDataComparison(context),
              ],
              if (widget.log.metadata != null &&
                  widget.log.metadata!.isNotEmpty) ...[
                const SizedBox(height: AppDesignSystem.spacing16),
                _buildMetadata(context),
              ],
              if (_canRevert()) ...[
                const SizedBox(height: AppDesignSystem.spacing16),
                _hasBeenReverted
                    ? _buildRevertedStatus(context)
                    : _buildRevertInformation(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canRevert() {
    // Reverte UPDATE (restaura dados antigos)
    // Reverte DELETE (recria registro)
    return (widget.log.action == LogAction.update ||
            widget.log.action == LogAction.delete) &&
        widget.log.oldData != null &&
        widget.log.oldData!.isNotEmpty &&
        widget.log.recordId != null;
  }

  Widget _buildLogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.log.actionColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.log.actionDisplayName} • ${widget.log.moduleDisplayName}',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_canRevert() &&
                        !_hasBeenReverted &&
                        !_isCheckingRevertStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing8,
                          vertical: AppDesignSystem.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.warningLight,
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Text(
                          'Reversível',
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: AppDesignSystem.warning,
                          ),
                        ),
                      ),
                    if (_hasBeenReverted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing8,
                          vertical: AppDesignSystem.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.neutral100,
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Text(
                          'Revertido',
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: AppDesignSystem.neutral600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  DateFormat(
                    'dd/MM/yyyy • HH:mm:ss',
                  ).format(widget.log.timestamp),
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral500,
                  ),
                ),
                if (widget.log.recordIdentifier != null) ...[
                  const SizedBox(height: AppDesignSystem.spacing4),
                  Text(
                    'Registro: ${widget.log.recordIdentifier}',
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: AppDesignSystem.neutral500,
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

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: SizedBox(
        width: double.infinity,
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Informações do Usuário\n\n',
                style: AppDesignSystem.labelLarge.copyWith(
                  color: AppDesignSystem.neutral700,
                ),
              ),
              TextSpan(
                text: 'Usuário: ',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
              TextSpan(
                text: widget.log.userDisplayName ?? widget.log.userEmail,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral900,
                ),
              ),
              if (widget.log.isAdmin)
                TextSpan(
                  text: ' (Admin)',
                  style: AppDesignSystem.labelSmall.copyWith(
                    color: AppDesignSystem.warning,
                  ),
                ),
              const TextSpan(text: '\n'),
              TextSpan(
                text: 'Email: ',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
              TextSpan(
                text: '${widget.log.userEmail}\n',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral900,
                ),
              ),
              TextSpan(
                text: 'UF: ',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
              TextSpan(
                text: widget.log.uf,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral900,
                ),
              ),
              TextSpan(
                text: ' (${widget.log.uf})',
                style: AppDesignSystem.labelSmall.copyWith(
                  color: widget.log.uf == 'CE'
                      ? AppDesignSystem.success
                      : AppDesignSystem.info,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionDetails(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: SizedBox(
        width: double.infinity,
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Detalhes da Ação\n\n',
                style: AppDesignSystem.labelLarge.copyWith(
                  color: AppDesignSystem.neutral700,
                ),
              ),
              TextSpan(
                text: 'Ação: ',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
              TextSpan(
                text: '${widget.log.actionDisplayName}\n',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral900,
                ),
              ),
              TextSpan(
                text: 'Módulo: ',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral600,
                ),
              ),
              TextSpan(
                text: '${widget.log.moduleDisplayName}\n',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.neutral900,
                ),
              ),
              if (widget.log.recordId != null) ...[
                TextSpan(
                  text: 'ID do Registro: ',
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral600,
                  ),
                ),
                TextSpan(
                  text: '${widget.log.recordId!}\n',
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral900,
                  ),
                ),
              ],
              if (widget.log.description != null) ...[
                TextSpan(
                  text: 'Descrição: ',
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral600,
                  ),
                ),
                TextSpan(
                  text: widget.log.description!,
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.neutral900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasDataChanges() {
    return (widget.log.oldData != null && widget.log.oldData!.isNotEmpty) ||
        (widget.log.newData != null && widget.log.newData!.isNotEmpty);
  }

  Widget _buildDataComparison(BuildContext context) {
    if (!_hasDataChanges()) return const SizedBox.shrink();

    return Container(
      decoration: AppDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: const BoxDecoration(
              color: AppDesignSystem.neutral50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDesignSystem.radiusS),
                topRight: Radius.circular(AppDesignSystem.radiusS),
              ),
              border: Border(
                bottom: BorderSide(color: AppDesignSystem.neutral200),
              ),
            ),
            child: Text(
              'Alterações nos Dados',
              style: AppDesignSystem.labelLarge.copyWith(
                color: AppDesignSystem.neutral700,
              ),
            ),
          ),
          // Lista de alterações
          _buildChangesList(),
        ],
      ),
    );
  }

  Widget _buildChangesList() {
    final changes = _getFieldChanges();

    return Column(
      children: changes.asMap().entries.map((entry) {
        final index = entry.key;
        final change = entry.value;
        final isEven = index.isEven;

        return Container(
          color: isEven ? AppDesignSystem.surface : AppDesignSystem.neutral50,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing12,
          ),
          child: Row(
            children: [
              // Indicador do tipo de alteração
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getChangeColor(change.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),

              // Nome do campo
              SizedBox(
                width: 120,
                child: Text(
                  _formatFieldName(change.field),
                  style: AppDesignSystem.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppDesignSystem.neutral900,
                  ),
                ),
              ),

              // Valor antigo
              Expanded(
                child: change.oldValue != null
                    ? Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        margin: const EdgeInsets.only(
                          right: AppDesignSystem.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.errorLight,
                          border: Border.all(
                            color: AppDesignSystem.error.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Text(
                          _formatValue(change.oldValue),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.error,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        margin: const EdgeInsets.only(
                          right: AppDesignSystem.spacing8,
                        ),
                        child: Text(
                          '(vazio)',
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
              ),

              // Seta
              const Icon(
                Icons.arrow_forward,
                size: 12,
                color: AppDesignSystem.neutral400,
              ),
              const SizedBox(width: AppDesignSystem.spacing8),

              // Valor novo
              Expanded(
                child: change.newValue != null
                    ? Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.successLight,
                          border: Border.all(
                            color: AppDesignSystem.success.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Text(
                          _formatValue(change.newValue),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.success,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        child: Text(
                          '(vazio)',
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
              ),

              // Badge do tipo de alteração
              const SizedBox(width: AppDesignSystem.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacing4,
                  vertical: AppDesignSystem.spacing2,
                ),
                decoration: BoxDecoration(
                  color: _getChangeColor(change.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: Text(
                  _getChangeTypeLabel(change.type),
                  style: AppDesignSystem.labelSmall.copyWith(
                    color: _getChangeColor(change.type),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    if (widget.log.metadata == null || widget.log.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<TextSpan> spans = [
      TextSpan(
        text: 'Metadados\n\n',
        style: AppDesignSystem.labelLarge.copyWith(
          color: AppDesignSystem.neutral700,
        ),
      ),
    ];

    for (final entry in widget.log.metadata!.entries) {
      spans.add(
        TextSpan(
          text: '${_formatFieldName(entry.key)}: ',
          style: AppDesignSystem.bodySmall.copyWith(
            color: AppDesignSystem.neutral600,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: '${_formatValue(entry.value)}\n',
          style: AppDesignSystem.bodySmall.copyWith(
            color: AppDesignSystem.neutral900,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration,
      child: SizedBox(
        width: double.infinity,
        child: SelectableText.rich(TextSpan(children: spans)),
      ),
    );
  }

  Widget _buildRevertedStatus(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration.copyWith(
        color: AppDesignSystem.successLight,
        border: Border.all(
          color: AppDesignSystem.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppDesignSystem.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppDesignSystem.success,
              size: 18,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alteração Revertida',
                  style: AppDesignSystem.labelMedium.copyWith(
                    color: AppDesignSystem.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  'Esta alteração já foi revertida com sucesso.',
                  style: AppDesignSystem.bodySmall.copyWith(
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

  Widget _buildRevertInformation(BuildContext context) {
    final isDelete = widget.log.action == LogAction.delete;
    final title = isDelete ? 'Exclusão Reversível' : 'Alteração Reversível';
    final buttonLabel = isDelete ? 'Recuperar Registro' : 'Reverter Alteração';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: AppDesignSystem.cardDecoration.copyWith(
        color: AppDesignSystem.warningLight,
        border: Border.all(
          color: AppDesignSystem.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppDesignSystem.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppDesignSystem.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                title,
                style: AppDesignSystem.labelMedium.copyWith(
                  color: AppDesignSystem.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isReverting ? null : () => _showRevertDialog(context),
              icon: _isReverting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppDesignSystem.surface,
                        ),
                      ),
                    )
                  : const Icon(Icons.redo, size: 18),
              label: Text(
                _isReverting ? 'Processando...' : buttonLabel,
                style: AppDesignSystem.labelMedium.copyWith(
                  color: AppDesignSystem.surface,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.warning,
                foregroundColor: AppDesignSystem.surface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacing16,
                  vertical: AppDesignSystem.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRevertDialog(BuildContext context) {
    final isDelete = widget.log.action == LogAction.delete;
    final title = isDelete ? 'Confirmar Recuperação' : 'Confirmar Reversão';
    final message = isDelete
        ? 'Você tem certeza que deseja recuperar este registro deletado? O registro será recriado com os dados anteriores e esta ação criará um novo registro de auditoria.'
        : 'Você tem certeza que deseja reverter esta alteração? Esta ação restaurará os dados anteriores e criará um novo registro de auditoria.';
    final buttonLabel = isDelete ? 'Recuperar' : 'Reverter';

    DialogUtils.showConfirmationDialog(
      context: context,
      title: title,
      content: message,
      confirmText: buttonLabel,
      confirmColor: AppDesignSystem.warning,
      onConfirm: _performRevert,
    );
  }

  Future<void> _performRevert() async {
    setState(() => _isReverting = true);

    try {
      await _auditService.revertChange(
        recordId: widget.log.recordId!,
        module: widget.log.module,
        targetLogId: widget.log.id!,
        oldData: widget.log.oldData!,
        originalAction: widget.log.action,
      );

      if (mounted) {
        setState(() {
          _hasBeenReverted = true;
          _isReverting = false;
        });

        final message = widget.log.action == LogAction.delete
            ? 'Exclusão revertida! O registro foi recriado com sucesso.'
            : 'Alteração revertida com sucesso!';

        SnackBarUtils.showSuccess(context, message);

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isReverting = false);

      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao reverter alteração: $e');
      }
    }
  }

  List<FieldChange> _getFieldChanges() {
    final changes = <FieldChange>[];
    final allFields = <String>{};

    if (widget.log.oldData != null) allFields.addAll(widget.log.oldData!.keys);
    if (widget.log.newData != null) allFields.addAll(widget.log.newData!.keys);

    for (final field in allFields) {
      final oldValue = widget.log.oldData?[field];
      final newValue = widget.log.newData?[field];

      ChangeType type;
      if (oldValue == null && newValue != null) {
        type = ChangeType.added;
      } else if (oldValue != null && newValue == null) {
        type = ChangeType.removed;
      } else if (oldValue != newValue) {
        type = ChangeType.modified;
      } else {
        continue;
      }

      changes.add(
        FieldChange(
          field: field,
          oldValue: oldValue,
          newValue: newValue,
          type: type,
        ),
      );
    }

    return changes;
  }

  Color _getChangeColor(ChangeType type) {
    switch (type) {
      case ChangeType.added:
        return AppDesignSystem.success;
      case ChangeType.removed:
        return AppDesignSystem.error;
      case ChangeType.modified:
        return AppDesignSystem.warning;
    }
  }

  String _getChangeTypeLabel(ChangeType type) {
    switch (type) {
      case ChangeType.added:
        return 'NOVO';
      case ChangeType.removed:
        return 'REM';
      case ChangeType.modified:
        return 'ALT';
    }
  }

  String _formatFieldName(String field) {
    final fieldNames = {
      'nota': 'Número da Nota',
      'danfe': 'DANFE',
      'manifesto': 'Manifesto',
      'produto': 'Produto',
      'tipo': 'Tipo',
      'utilidade': 'Utilidade',
      'fornecedor': 'Fornecedor',
      'remetente': 'Remetente',
      'destinatario': 'Destinatário',
      'uf': 'UF',
      'valorTotal': 'Valor Total',
      'pesoTotal': 'Peso Total',
      'emEstoque': 'Em Estoque',
      'dataAvaria': 'Data da Avaria',
      'estado': 'Estado',
      'localDeAvaria': 'Local de Avaria',
      'descricao': 'Descrição',
      'valorAvaria': 'Valor da Avaria',
      'pesoAvaria': 'Peso da Avaria',
      'unidadesAvariadas': 'Unidades Avariadas',
      'valorPorQuilo': 'Valor por Quilo',
      'valorUnitario': 'Valor Unitário',
      'conferente': 'Conferente',
      'tratador': 'Tratador',
      'metodoDeRessarcimento': 'Método de Ressarcimento',
      'meioDeContato': 'Meio de Contato',
      'contato': 'Contato',
      'pendenteDePagamento': 'Pendente de Pagamento',
      'pendenteDeDesconto': 'Pendente de Desconto',
      'valor': 'Valor',
      'dataDeCompra': 'Data de Compra',
      'dataDeGarantia': 'Data de Garantia',
      'numeroDeSerie': 'Número de Série',
      'localizacao': 'Localização',
    };

    return fieldNames[field] ?? field;
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
      builder: (context) => Dialog(
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          side: const BorderSide(color: AppDesignSystem.neutral200),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing24),
          constraints: const BoxConstraints(maxWidth: 700),
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
                          'Dados Brutos',
                          style: AppDesignSystem.h3.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppDesignSystem.spacing4),
                        Text(
                          'Visualização completa dos dados',
                          style: AppDesignSystem.bodySmall.copyWith(
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
              SelectionArea(
                child: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.log.oldData != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.data_object,
                                color: AppDesignSystem.error,
                                size: 16,
                              ),
                              const SizedBox(width: AppDesignSystem.spacing8),
                              Text(
                                'Dados Anteriores',
                                style: AppDesignSystem.labelMedium.copyWith(
                                  color: AppDesignSystem.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesignSystem.spacing8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                              AppDesignSystem.spacing12,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.errorLight,
                              borderRadius: BorderRadius.circular(
                                AppDesignSystem.radiusM,
                              ),
                              border: Border.all(
                                color: AppDesignSystem.error.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Text(
                              widget.log.oldData.toString(),
                              style: AppDesignSystem.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: AppDesignSystem.neutral700,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spacing16),
                        ],
                        if (widget.log.newData != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.data_object,
                                color: AppDesignSystem.success,
                                size: 16,
                              ),
                              const SizedBox(width: AppDesignSystem.spacing8),
                              Text(
                                'Dados Novos',
                                style: AppDesignSystem.labelMedium.copyWith(
                                  color: AppDesignSystem.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesignSystem.spacing8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                              AppDesignSystem.spacing12,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.successLight,
                              borderRadius: BorderRadius.circular(
                                AppDesignSystem.radiusM,
                              ),
                              border: Border.all(
                                color: AppDesignSystem.success.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Text(
                              widget.log.newData.toString(),
                              style: AppDesignSystem.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: AppDesignSystem.neutral700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
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
                        backgroundColor: AppDesignSystem.surface,
                        foregroundColor: AppDesignSystem.neutral600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                          side: const BorderSide(color: AppDesignSystem.neutral200),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing16,
                        ),
                      ),
                      child: Text(
                        'Fechar',
                        style: AppDesignSystem.labelMedium.copyWith(
                          fontWeight: FontWeight.w500,
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
}

enum ChangeType { added, removed, modified }

class FieldChange {
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final ChangeType type;

  FieldChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.type,
  });
}
