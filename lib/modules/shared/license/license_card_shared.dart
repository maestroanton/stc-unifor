import 'package:flutter/material.dart';
import '../../../core/design_system.dart';
import '../../../models/license.dart';

class LicenseCardShared extends StatelessWidget {
  final License license;
  final VoidCallback? onTap;
  final String fileStatusText;

  const LicenseCardShared({
    super.key,
    required this.license,
    this.onTap,
    required this.fileStatusText,
  });

  Color get _statusColor {
    switch (license.status) {
      case LicenseStatus.valida:
        return AppDesignSystem.success;
      case LicenseStatus.proximoVencimento:
        return AppDesignSystem.warning;
      case LicenseStatus.vencida:
        return AppDesignSystem.error;
    }
  }

  String get _statusText {
    switch (license.status) {
      case LicenseStatus.valida:
        return 'Válida';
      case LicenseStatus.proximoVencimento:
        return 'Próx. Venc.';
      case LicenseStatus.vencida:
        return 'Vencida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDesignSystem.hoverAnimation(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
        decoration: BoxDecoration(
          color: AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          border: Border.all(color: AppDesignSystem.neutral200),
          boxShadow: AppDesignSystem.shadowSM,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacing12),
              child: Row(
                children: [
                  // Indicador de status
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusXS,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  // Informações da licença
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          license.nome,
                          style: AppDesignSystem.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDesignSystem.spacing4),
                        Row(
                          children: [
                            Icon(
                              license.arquivoUrl != null
                                  ? Icons.check_circle_outline
                                  : Icons.cloud_upload_outlined,
                              size: 16,
                              color: license.arquivoUrl != null
                                  ? AppDesignSystem.success
                                  : AppDesignSystem.neutral500,
                            ),
                            const SizedBox(width: AppDesignSystem.spacing4),
                            Text(
                              license.arquivoUrl != null
                                  ? fileStatusText
                                  : 'Sem arquivo',
                              style: AppDesignSystem.bodySmall.copyWith(
                                color: AppDesignSystem.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Data e status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Indicador de status padrão
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing8,
                          vertical: AppDesignSystem.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusL,
                          ),
                        ),
                        child: Text(
                          _statusText,
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (license.dataVencimento.isNotEmpty) ...[
                        const SizedBox(height: AppDesignSystem.spacing4),
                        Text(
                          license.dataVencimento,
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: AppDesignSystem.neutral500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}