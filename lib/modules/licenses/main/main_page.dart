import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../helpers/database_helper_license.dart';
import '../../../core/utilities/shared/responsive.dart';
import '../../../core/design_system.dart';
import '../../../core/visuals/snackbar.dart';
import '../../../models/license.dart';
import '../../../helpers/uf_helper.dart';
import 'license_card.dart';
import 'license_edit_dialog.dart';

class LicenseMainPage extends StatefulWidget {
  const LicenseMainPage({super.key});

  @override
  State<LicenseMainPage> createState() => _LicenseMainPageState();
}

class _LicenseMainPageState extends State<LicenseMainPage> {
  final DatabaseHelperLicense _dbHelper = DatabaseHelperLicense();
  List<License> _licenses = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserPermissions();
    await _dbHelper.initializePredefinedLicenses();
    await _loadLicenses();
  }

  Future<void> _checkUserPermissions() async {
    final isAdmin = await UfHelper.isAdmin();

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _loadLicenses() async {
    setState(() => _isLoading = true);

    try {
      final licenses = await _dbHelper.getLicenses();

      if (mounted) {
        setState(() {
          _licenses = licenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, 'Erro ao carregar licenças: $e');
      }
    }
  }

  List<License> _getLicensesByUf(String uf) {
    return _licenses.where((license) => license.uf == uf).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Widget _buildUfColumn(String uf, String flagAsset) {
    final ufLicenses = _getLicensesByUf(uf);
    final canEdit = _isAdmin;

    // Contar licenças por status
    final validCount = ufLicenses
        .where((l) => l.status == LicenseStatus.valida)
        .length;
    final expiringCount = ufLicenses
        .where((l) => l.status == LicenseStatus.proximoVencimento)
        .length;
    final expiredCount = ufLicenses
        .where((l) => l.status == LicenseStatus.vencida)
        .length;
    final withFileCount = ufLicenses.where((l) => l.arquivoUrl != null).length;

    return Container(
      margin: Responsive.isSmallScreen(context)
          ? EdgeInsets.only(bottom: Responsive.spacing(context))
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppDesignSystem.surface,
        borderRadius: Responsive.isSmallScreen(context)
            ? BorderRadius.circular(AppDesignSystem.radiusL)
            : BorderRadius.zero,
        border: Responsive.isSmallScreen(context)
            ? Border.all(color: AppDesignSystem.neutral200)
            : Border(
                right: uf == 'CE'
                    ? const BorderSide(color: AppDesignSystem.neutral200)
                    : BorderSide.none,
              ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context)),
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral50,
              borderRadius: Responsive.isSmallScreen(context)
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(AppDesignSystem.radiusL),
                      topRight: Radius.circular(AppDesignSystem.radiusL),
                    )
                  : const BorderRadius.all(Radius.circular(0)),
              border: const Border(
                bottom: BorderSide(color: AppDesignSystem.neutral200),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: Responsive.valueDetailed(
                    context,
                    mobile: 60.0,
                    smallTablet: 70.0,
                    tablet: 80.0,
                    desktop: 80.0,
                  ),
                  height: Responsive.valueDetailed(
                    context,
                    mobile: 45.0,
                    smallTablet: 52.0,
                    tablet: 60.0,
                    desktop: 60.0,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppDesignSystem.radiusM),
                    ),
                    child: SvgPicture.asset(flagAsset, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context)),
                Text(uf, style: AppDesignSystem.h2),
                SizedBox(height: Responsive.spacing(context)),
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing12),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.surface,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppDesignSystem.radiusM),
                    ),
                    border: Border.all(color: AppDesignSystem.neutral200),
                  ),
                  child: Responsive.isSmallScreen(context)
                      ? Column(
                          children: [
                            Row(
                              children: [
                                _buildStatItem(
                                  'Em Uso',
                                  validCount.toString(),
                                  AppDesignSystem.success,
                                ),
                                const SizedBox(width: AppDesignSystem.spacing8),
                                _buildStatItem(
                                  'Com Arquivo',
                                  withFileCount.toString(),
                                  AppDesignSystem.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDesignSystem.spacing8),
                            Row(
                              children: [
                                _buildStatItem(
                                  'Próx. Venc.',
                                  expiringCount.toString(),
                                  AppDesignSystem.warning,
                                ),
                                const SizedBox(width: AppDesignSystem.spacing8),
                                _buildStatItem(
                                  'Vencidas',
                                  expiredCount.toString(),
                                  AppDesignSystem.error,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                _buildStatItem(
                                  'Em Uso',
                                  validCount.toString(),
                                  AppDesignSystem.success,
                                ),
                                const SizedBox(
                                  width: AppDesignSystem.spacing16,
                                ),
                                _buildStatItem(
                                  'Com Arquivo',
                                  withFileCount.toString(),
                                  AppDesignSystem.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDesignSystem.spacing12),
                            Row(
                              children: [
                                _buildStatItem(
                                  'Próx. Venc.',
                                  expiringCount.toString(),
                                  AppDesignSystem.warning,
                                ),
                                const SizedBox(
                                  width: AppDesignSystem.spacing16,
                                ),
                                _buildStatItem(
                                  'Vencidas',
                                  expiredCount.toString(),
                                  AppDesignSystem.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ufLicenses.isEmpty
                ? _buildEmptyState(uf)
                : ListView.builder(
                    padding: EdgeInsets.all(Responsive.spacing(context)),
                    itemCount: ufLicenses.length,
                    itemBuilder: (context, index) {
                      final license = ufLicenses[index];
                      return LicenseCard(
                        license: license,
                        onTap: canEdit ? () => _editLicense(license) : null,
                        onRefresh: _loadLicenses,
                        isReadOnly: !canEdit,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Para layout desktop - atualizar método _buildStatItem
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: Responsive.smallSpacing(context) * 2),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontSize: context.isSmallScreen ? 11 : 12,
                    color: const Color(0xFF757575),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.isSmallScreen ? 11 : 12,
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Para layout móvel compacto - atualizar método _buildCompactStat
  Widget _buildCompactStat(String label, int value, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF212121),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String uf) {
    return AppDesignSystem.emptyState(
      icon: Icons.folder_open_outlined,
      title: 'Nenhuma licença encontrada',
      subtitle: 'As licenças para $uf serão\ncarregadas automaticamente',
    );
  }

  Future<void> _editLicense(License license) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => LicenseEditDialog(license: license),
    );

    if (result == true) {
      await _loadLicenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isSmallScreen(context)) {
      return AppScaffold(
        body: Column(
          children: [
            AppDesignSystem.pageHeader(
              icon: Icons.verified_user_outlined,
              title: 'Gestão de Licenças',
              onBack: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            Expanded(
              child: _isLoading
                  ? AppDesignSystem.loadingState()
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            color: AppDesignSystem.surface,
                            child: Column(
                              children: [
                                TabBar(
                                  labelColor: AppDesignSystem.neutral800,
                                  unselectedLabelColor:
                                      AppDesignSystem.neutral500,
                                  indicatorColor: AppDesignSystem.primary,
                                  labelStyle: AppDesignSystem.labelMedium,
                                  tabs: [
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 18,
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(
                                                      AppDesignSystem.radiusXS,
                                                    ),
                                                  ),
                                              child: SvgPicture.asset(
                                                'assets/flag_ce.svg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDesignSystem.spacing8,
                                          ),
                                          const Text('CE'),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 18,
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(
                                                      AppDesignSystem.radiusXS,
                                                    ),
                                                  ),
                                              child: SvgPicture.asset(
                                                'assets/flag_sp.svg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDesignSystem.spacing8,
                                          ),
                                          const Text('SP'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 1,
                                  color: AppDesignSystem.neutral200,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildCompactUfView('CE'),
                                _buildCompactUfView('SP'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    } else {
      // Para telas maiores, manter layout original de duas colunas
      return AppScaffold(
        body: Column(
          children: [
            AppDesignSystem.pageHeader(
              icon: Icons.verified_user_outlined,
              title: 'Gestão de Licenças',
              onBack: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            Expanded(
              child: _isLoading
                  ? AppDesignSystem.loadingState()
                  : Row(
                      children: [
                        Expanded(
                          child: _buildUfColumn('CE', 'assets/flag_ce.svg'),
                        ),
                        Expanded(
                          child: _buildUfColumn('SP', 'assets/flag_sp.svg'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCompactUfView(String uf) {
    final ufLicenses = _getLicensesByUf(uf);
    final canEdit = _isAdmin;

    // Contar licenças por status
    final validCount = ufLicenses
        .where((l) => l.status == LicenseStatus.valida)
        .length;
    final expiringCount = ufLicenses
        .where((l) => l.status == LicenseStatus.proximoVencimento)
        .length;
    final expiredCount = ufLicenses
        .where((l) => l.status == LicenseStatus.vencida)
        .length;
    final withFileCount = ufLicenses.where((l) => l.arquivoUrl != null).length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Responsive.spacing(context)),
          color: AppDesignSystem.neutral50,
          child: Row(
            children: [
              _buildCompactStat('Em Uso', validCount, AppDesignSystem.success),
              _buildCompactStat(
                'Próx. Venc.',
                expiringCount,
                AppDesignSystem.warning,
              ),
              _buildCompactStat(
                'Vencidas',
                expiredCount,
                AppDesignSystem.error,
              ),
              _buildCompactStat(
                'Com Arquivo',
                withFileCount,
                AppDesignSystem.info,
              ),
            ],
          ),
        ),
        Expanded(
          child: ufLicenses.isEmpty
              ? _buildCompactEmptyState(uf)
              : ListView.builder(
                  padding: EdgeInsets.all(Responsive.spacing(context)),
                  itemCount: ufLicenses.length,
                  itemBuilder: (context, index) {
                    final license = ufLicenses[index];
                    return LicenseCard(
                      license: license,
                      onTap: canEdit ? () => _editLicense(license) : null,
                      onRefresh: _loadLicenses,
                      isReadOnly: !canEdit,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCompactEmptyState(String uf) {
    return AppDesignSystem.emptyState(
      icon: Icons.folder_open_outlined,
      title: 'Nenhuma licença encontrada',
      subtitle: 'As licenças para $uf serão carregadas automaticamente',
    );
  }
}
