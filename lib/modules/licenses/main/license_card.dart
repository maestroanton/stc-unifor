import 'package:flutter/material.dart';
import '../../../models/license.dart';
import '../../shared/license/license_card_shared.dart';

class LicenseCard extends StatelessWidget {
  final License license;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final bool isReadOnly;

  const LicenseCard({
    super.key,
    required this.license,
    this.onTap,
    this.onRefresh,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return LicenseCardShared(
      license: license,
      onTap: onTap,
      fileStatusText: 'Arquivo anexado',
    );
  }
}
