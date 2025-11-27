import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../core/design_system.dart';
import '../../core/utilities/core_utilities_exports.dart';
import '../../core/utilities/date_picker_helper.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log.dart';
import '../../core/visuals/snackbar.dart' show SnackBarUtils;
import '../../core/visuals/status_indicator.dart';
import 'auditoria_diff.dart';

class AuditLogsPageContent extends StatefulWidget {
  const AuditLogsPageContent({super.key});

  @override
  State<AuditLogsPageContent> createState() => _AuditLogsPageContentState();
}

class _AuditLogsPageContentState extends State<AuditLogsPageContent> {
  final AuditLogService _auditService = AuditLogService();

  List<AuditLog> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Filtros multi-seleção
  // ignore: prefer_final_fields
  List<LogModule> _selectedModules = [];
  // ignore: prefer_final_fields
  List<LogAction> _selectedActions = [];
  // ignore: prefer_final_fields
  List<String> _selectedUfs = [];
  String _userEmailFilter = '';
  DateTimeRange? _dateRange;

  // Paginação
  final int _pageSize = 25;

  void _navigateToLogDetail(AuditLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuditLogDetailPage(log: log)),
    );
  }

  bool _hasViewableChanges(AuditLog log) {
    return (log.oldData != null && log.oldData!.isNotEmpty) ||
        (log.newData != null && log.newData!.isNotEmpty) ||
        log.action == LogAction.update ||
        log.action == LogAction.create ||
        log.action == LogAction.delete;
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _logs.clear();
        _isLoading = true;
      });
    }

    try {
      // Carrega logs e aplica filtro local para multi-seleção
      final logs = await _auditService.getLogs(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        limit: _pageSize * 4, // Aumentar para compensar filtragem
      );

      // Filtragem local
      List<AuditLog> filteredLogs = logs.where((log) {
        // Filtro de módulo
        if (_selectedModules.isNotEmpty &&
            !_selectedModules.contains(log.module)) {
          return false;
        }

        // Filtro de ação
        if (_selectedActions.isNotEmpty &&
            !_selectedActions.contains(log.action)) {
          return false;
        }

        // Filtro por UF
        if (_selectedUfs.isNotEmpty && !_selectedUfs.contains(log.uf)) {
          return false;
        }

        // Filtro por email do usuário
        if (_userEmailFilter.isNotEmpty &&
            !log.userEmail.toLowerCase().contains(
              _userEmailFilter.toLowerCase(),
            )) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        if (refresh) {
          _logs = filteredLogs;
        } else {
          _logs.addAll(filteredLogs);
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar logs: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.isSmallScreen) {
      // Em telas pequenas: layout rolável sem altura fixa
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context).horizontal / 2,
          vertical: Responsive.smallSpacing(context),
        ),
        child: Container(
          padding: Responsive.padding(context),
          decoration: BoxDecoration(
            color: AppDesignSystem.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            boxShadow: AppDesignSystem.shadowMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: Responsive.spacing(context)),
              _buildFilterBar(),
              SizedBox(height: Responsive.spacing(context)),
              _isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _logs.isEmpty
                  ? SizedBox(height: 200, child: _buildEmptyState())
                  : _buildLogsListMobile(),
            ],
          ),
        ),
      );
    } else {
      // Em telas maiores: layout com Expanded
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context).horizontal / 2,
            vertical: Responsive.largeSpacing(context),
          ),
          padding: Responsive.padding(context),
          decoration: BoxDecoration(
            color: AppDesignSystem.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            boxShadow: AppDesignSystem.shadowMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: Responsive.spacing(context)),
              _buildFilterBar(),
              SizedBox(height: Responsive.spacing(context)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _logs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.history,
          size: Responsive.iconSize(context),
          color: const Color.fromRGBO(30, 30, 30, 1),
        ),
        SizedBox(width: Responsive.smallSpacing(context) * 3),
        const Text(
          'Auditoria',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(30, 30, 30, 1),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _loadLogs(refresh: true),
          icon: Icon(Icons.refresh, size: Responsive.iconSize(context)),
          tooltip: 'Atualizar',
          constraints: Responsive.iconButtonConstraints(context),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: Responsive.padding(context),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: Column(
        children: [
          // Controles de filtro
          context.isSmallScreen
              ? Column(
                  children: [
                    _buildModuleFilter(),
                    SizedBox(height: Responsive.spacing(context)),
                    _buildActionFilter(),
                    SizedBox(height: Responsive.spacing(context)),
                    _buildUfFilter(),
                    SizedBox(height: Responsive.spacing(context)),
                    _buildUserEmailFilter(),
                    SizedBox(height: Responsive.spacing(context)),
                    _buildDateRangePicker(),
                  ],
                )
              : Wrap(
                  spacing: Responsive.spacing(context),
                  runSpacing: Responsive.spacing(context),
                  children: [
                    _buildModuleFilter(),
                    _buildActionFilter(),
                    _buildUfFilter(),
                    _buildUserEmailFilter(),
                    _buildDateRangePicker(),
                  ],
                ),

          // Botão limpar filtros e contador de filtros ativos
          SizedBox(height: Responsive.spacing(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador de filtros ativos
              if (_hasActiveFilters())
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.smallSpacing(context) * 2,
                    vertical: Responsive.smallSpacing(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.infoLight,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusM,
                    ),
                    border: Border.all(
                      color: AppDesignSystem.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_getActiveFiltersCount()} filtro(s) ativo(s)',
                    style: TextStyle(
                      fontSize: Responsive.smallFontSize(context),
                      color: AppDesignSystem.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Botão limpar filtros
              TextButton.icon(
                onPressed: _hasActiveFilters() ? _clearFilters : null,
                icon: Icon(
                  Icons.clear,
                  size: Responsive.smallIconSize(context),
                ),
                label: Text(
                  'Limpar Filtros',
                  style: TextStyle(fontSize: Responsive.smallFontSize(context)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.spacing(context),
                    vertical: Responsive.smallSpacing(context) * 1.5,
                  ),
                  minimumSize: Size(0, Responsive.buttonHeight(context) * 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleFilter() {
    return SizedBox(
      width: context.isSmallScreen
          ? double.infinity
          : Responsive.valueDetailed(
              context,
              mobile: double.infinity,
              smallTablet: 180.0,
              tablet: 200.0,
              desktop: 220.0,
            ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<LogModule>(
          isExpanded: true,
          hint: Text(
            _selectedModules.isEmpty
                ? "Módulos"
                : "Módulos (${_selectedModules.length})",
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: _selectedModules.isEmpty
                  ? AppDesignSystem.neutral600
                  : AppDesignSystem.neutral800,
            ),
          ),
          items: LogModule.values.map((module) {
            return DropdownMenuItem<LogModule>(
              value: module,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = _selectedModules.contains(module);
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        _selectedModules.remove(module);
                      } else {
                        _selectedModules.add(module);
                      }
                      setState(() {});
                      menuSetState(() {});
                      _loadLogs(refresh: true);
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_box_outlined)
                          else
                            const Icon(Icons.check_box_outline_blank),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getModuleDisplayName(module),
                              style: TextStyle(
                                fontSize: Responsive.bodyFontSize(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return LogModule.values.map((module) {
              return Container(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _selectedModules.isEmpty
                      ? "Módulos"
                      : "Módulos (${_selectedModules.length})",
                  style: TextStyle(
                    fontSize: Responsive.bodyFontSize(context),
                    color: _selectedModules.isEmpty
                        ? AppDesignSystem.neutral600
                        : AppDesignSystem.neutral800,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList();
          },
          buttonStyleData: ButtonStyleData(
            height: Responsive.buttonHeight(context),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral300),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppDesignSystem.neutral600,
            ),
          ),
          dropdownStyleData: const DropdownStyleData(maxHeight: 300),
          menuItemStyleData: MenuItemStyleData(
            height: Responsive.buttonHeight(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildActionFilter() {
    return SizedBox(
      width: context.isSmallScreen
          ? double.infinity
          : Responsive.valueDetailed(
              context,
              mobile: double.infinity,
              smallTablet: 180.0,
              tablet: 200.0,
              desktop: 220.0,
            ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<LogAction>(
          isExpanded: true,
          hint: Text(
            _selectedActions.isEmpty
                ? "Ações"
                : "Ações (${_selectedActions.length})",
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: _selectedActions.isEmpty
                  ? AppDesignSystem.neutral600
                  : AppDesignSystem.neutral800,
            ),
          ),
          items: LogAction.values.map((action) {
            return DropdownMenuItem<LogAction>(
              value: action,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = _selectedActions.contains(action);
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        _selectedActions.remove(action);
                      } else {
                        _selectedActions.add(action);
                      }
                      setState(() {});
                      menuSetState(() {});
                      _loadLogs(refresh: true);
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_box_outlined)
                          else
                            const Icon(Icons.check_box_outline_blank),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getActionDisplayName(action),
                              style: TextStyle(
                                fontSize: Responsive.bodyFontSize(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return LogAction.values.map((action) {
              return Container(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _selectedActions.isEmpty
                      ? "Ações"
                      : "Ações (${_selectedActions.length})",
                  style: TextStyle(
                    fontSize: Responsive.bodyFontSize(context),
                    color: _selectedActions.isEmpty
                        ? AppDesignSystem.neutral600
                        : AppDesignSystem.neutral800,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList();
          },
          buttonStyleData: ButtonStyleData(
            height: Responsive.buttonHeight(context),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral300),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppDesignSystem.neutral600,
            ),
          ),
          dropdownStyleData: const DropdownStyleData(maxHeight: 300),
          menuItemStyleData: MenuItemStyleData(
            height: Responsive.buttonHeight(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildUfFilter() {
    final List<String> ufs = ['CE', 'SP'];

    return SizedBox(
      width: context.isSmallScreen
          ? double.infinity
          : Responsive.valueDetailed(
              context,
              mobile: double.infinity,
              smallTablet: 140.0,
              tablet: 150.0,
              desktop: 160.0,
            ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            _selectedUfs.isEmpty ? "UFs" : "UFs (${_selectedUfs.length})",
            style: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: _selectedUfs.isEmpty
                  ? AppDesignSystem.neutral600
                  : AppDesignSystem.neutral800,
            ),
          ),
          items: ufs.map((uf) {
            return DropdownMenuItem<String>(
              value: uf,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = _selectedUfs.contains(uf);
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        _selectedUfs.remove(uf);
                      } else {
                        _selectedUfs.add(uf);
                      }
                      setState(() {});
                      menuSetState(() {});
                      _loadLogs(refresh: true);
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_box_outlined)
                          else
                            const Icon(Icons.check_box_outline_blank),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              uf,
                              style: TextStyle(
                                fontSize: Responsive.bodyFontSize(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return ufs.map((uf) {
              return Container(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _selectedUfs.isEmpty ? "UFs" : "UFs (${_selectedUfs.length})",
                  style: TextStyle(
                    fontSize: Responsive.bodyFontSize(context),
                    color: _selectedUfs.isEmpty
                        ? AppDesignSystem.neutral600
                        : AppDesignSystem.neutral800,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList();
          },
          buttonStyleData: ButtonStyleData(
            height: Responsive.buttonHeight(context),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(color: AppDesignSystem.neutral300),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppDesignSystem.neutral600,
            ),
          ),
          dropdownStyleData: const DropdownStyleData(maxHeight: 300),
          menuItemStyleData: MenuItemStyleData(
            height: Responsive.buttonHeight(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildUserEmailFilter() {
    return SizedBox(
      width: context.isSmallScreen
          ? double.infinity
          : Responsive.valueDetailed(
              context,
              mobile: double.infinity,
              smallTablet: 200.0,
              tablet: 220.0,
              desktop: 250.0,
            ),
      height: Responsive.buttonHeight(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          border: Border.all(color: AppDesignSystem.neutral300),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() => _userEmailFilter = value);
            // Pequeno atraso para evitar chamadas em excesso ao digitar
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_userEmailFilter == value) {
                _loadLogs(refresh: true);
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'Filtrar por email...',
            hintStyle: TextStyle(
              fontSize: Responsive.bodyFontSize(context),
              color: AppDesignSystem.neutral600,
            ),
            prefixIcon: Icon(
              Icons.person_search,
              size: Responsive.smallIconSize(context),
              color: AppDesignSystem.neutral600,
            ),
            suffixIcon: _userEmailFilter.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: Responsive.smallIconSize(context),
                      color: AppDesignSystem.neutral600,
                    ),
                    onPressed: () {
                      setState(() => _userEmailFilter = '');
                      _loadLogs(refresh: true);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(context),
              vertical: Responsive.spacing(context),
            ),
          ),
          style: TextStyle(fontSize: Responsive.bodyFontSize(context)),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return SizedBox(
      width: context.isSmallScreen
          ? double.infinity
          : Responsive.valueDetailed(
              context,
              mobile: double.infinity,
              smallTablet: 160.0,
              tablet: 180.0,
              desktop: 200.0,
            ),
      height: Responsive.buttonHeight(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          border: Border.all(color: AppDesignSystem.neutral300),
        ),
        child: OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: Icon(Icons.date_range, size: Responsive.smallIconSize(context)),
          label: Text(
            _dateRange != null
                ? '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'
                : 'Período',
            style: TextStyle(fontSize: Responsive.bodyFontSize(context)),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            padding: Responsive.buttonPadding(context),
            minimumSize: Size(0, Responsive.buttonHeight(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedModules.isNotEmpty ||
        _selectedActions.isNotEmpty ||
        _selectedUfs.isNotEmpty ||
        _userEmailFilter.isNotEmpty ||
        _dateRange != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedModules.isNotEmpty) count++;
    if (_selectedActions.isNotEmpty) count++;
    if (_selectedUfs.isNotEmpty) count++;
    if (_userEmailFilter.isNotEmpty) count++;
    if (_dateRange != null) count++;
    return count;
  }

  Future<void> _selectDateRange() async {
    final range = await DatePickerHelper.showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialRange: _dateRange,
    );

    if (range != null) {
      setState(() => _dateRange = range);
      _loadLogs(refresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedModules.clear();
      _selectedActions.clear();
      _selectedUfs.clear();
      _userEmailFilter = '';
      _dateRange = null;
    });
    _loadLogs(refresh: true);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: Responsive.largeIconSize(context) * 2,
            color: AppDesignSystem.neutral400,
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Text(
            'Nenhum registro de auditoria encontrado',
            style: AppDesignSystem.h3.copyWith(
              color: AppDesignSystem.neutral600,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            'Tente ajustar os filtros ou aguarde atividade no sistema',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    return Column(
      children: [
        _buildTableHeader(),
        SizedBox(height: Responsive.smallSpacing(context) * 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadLogs(refresh: true),
            child: SelectionArea(
              child: ListView.builder(
                itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _logs.length) {
                    return Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context)),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final log = _logs[index];
                  return _buildLogItem(log, index);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsListMobile() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTableHeader(),
        SizedBox(height: Responsive.smallSpacing(context) * 2),
        // Usar Column em mobile para rolagem correta
        SelectionArea(
          child: Column(
            children: _logs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              return _buildLogItem(log, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context),
        vertical: Responsive.spacing(context),
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(color: AppDesignSystem.neutral200),
      ),
      child: context.isSmallScreen
          ? _buildMobileHeader()
          : _buildDesktopHeader(),
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      children: [
        Text(
          'Usuário',
          style: AppDesignSystem.labelMedium.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        Expanded(
          child: Text(
            'Ação',
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
        Text(
          'Data & Hora',
          style: AppDesignSystem.labelMedium.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            'Usuário',
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        SizedBox(
          width: 100,
          child: Text(
            'Ação',
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        SizedBox(
          width: 120,
          child: Text(
            'Data & Hora',
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
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
            'UF',
            textAlign: TextAlign.center,
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        SizedBox(
          width: 80,
          child: Text(
            'Ações',
            textAlign: TextAlign.center,
            style: AppDesignSystem.labelMedium.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(AuditLog log, int index) {
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
        onTap: _hasViewableChanges(log)
            ? () => _navigateToLogDetail(log)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(context),
            vertical: Responsive.spacing(context),
          ),
          child: context.isSmallScreen
              ? _buildMobileLogItem(log)
              : _buildDesktopLogItem(log),
        ),
      ),
    );
  }

  Widget _buildMobileLogItem(AuditLog log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: usuário e ação
        Row(
          children: [
            // Indicador de ação (DotIndicators.standard)
            DotIndicators.standard(
              text: log.actionDisplayName,
              dotColor: log.actionColor,
            ),
            
            const Text(
              '\t',
              style: TextStyle(fontSize: 1, color: Colors.transparent),
            ),
            const SizedBox(width: 6),
            // Hora
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
              style: const TextStyle(fontSize: 10, color: AppDesignSystem.neutral600),
            ),
          ],
        ),
        
        const Text(
          '\n',
          style: TextStyle(fontSize: 1, height: 0.1, color: Colors.transparent),
        ),

        const SizedBox(height: 6),

        // Informações do usuário
        Row(
          children: [
            Icon(
              log.isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 12,
              color: AppDesignSystem.neutral600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                log.userDisplayName ?? log.userEmail,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge do Administrador
            if (log.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(color: AppDesignSystem.warningLight),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppDesignSystem.warning,
                  ),
                ),
              ),
          ],
        ),
        
        const Text(
          '\n',
          style: TextStyle(fontSize: 1, height: 0.1, color: Colors.transparent),
        ),

        const SizedBox(height: 6),

        // Módulo e assunto
        Row(
          children: [
            Text(
              log.moduleDisplayName,
              style: const TextStyle(fontSize: 9, color: AppDesignSystem.neutral600),
            ),
            
            const Text(
              '\t• ',
              style: TextStyle(fontSize: 1, color: Colors.transparent),
            ),
            Expanded(
              child: Text(
                log.description ?? 'Sem descrição',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppDesignSystem.neutral800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Text(
              '\t',
              style: TextStyle(fontSize: 1, color: Colors.transparent),
            ),
            // Badge da UF
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: log.uf == 'CE'
                    ? AppDesignSystem.successLight
                    : AppDesignSystem.infoLight,
              ),
              child: Text(
                log.uf,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: log.uf == 'CE'
                      ? AppDesignSystem.success
                      : AppDesignSystem.info,
                ),
              ),
            ),
          ],
        ),

        // Botão Ver Detalhes
        if (_hasViewableChanges(log)) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppDesignSystem.infoLight,
                border: Border.all(color: AppDesignSystem.info),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 10, color: AppDesignSystem.info),
                  SizedBox(width: 3),
                  Text(
                    'Ver Detalhes',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppDesignSystem.info,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Separador para cópia (dupla quebra de linha)
        const Text(
          '\n\n',
          style: TextStyle(fontSize: 1, height: 0.1, color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildDesktopLogItem(AuditLog log) {
    return Row(
      children: [
        // Coluna Usuário
        SizedBox(
          width: 120,
          child: Row(
            children: [
              Icon(
                log.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 12,
                color: AppDesignSystem.neutral600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.userDisplayName ?? log.userEmail,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (log.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppDesignSystem.warningLight,
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: AppDesignSystem.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        
        const Text(
          '\t',
          style: TextStyle(fontSize: 1, color: Colors.transparent),
        ),

        SizedBox(width: Responsive.spacing(context)),

        // Coluna Ação
        SizedBox(
          width: 100,
          child: DotIndicators.standard(
            text: log.actionDisplayName,
            dotColor: log.actionColor,
          ),
        ),

        
        const Text(
          '\t',
          style: TextStyle(fontSize: 1, color: Colors.transparent),
        ),

        SizedBox(width: Responsive.spacing(context)),

        // Coluna Data e Hora
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(log.timestamp),
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(log.timestamp),
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context) - 1,
                  color: AppDesignSystem.neutral600,
                ),
              ),
            ],
          ),
        ),

        
        const Text(
          '\t',
          style: TextStyle(fontSize: 1, color: Colors.transparent),
        ),

        SizedBox(width: Responsive.spacing(context)),

        // Coluna Assunto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.description ?? 'Sem descrição',
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                log.moduleDisplayName,
                style: TextStyle(
                  fontSize: Responsive.smallFontSize(context),
                  color: AppDesignSystem.neutral600,
                ),
              ),
            ],
          ),
        ),

        
        const Text(
          '\t',
          style: TextStyle(fontSize: 1, color: Colors.transparent),
        ),

        // Coluna UF
        SizedBox(
          width: 80,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: log.uf == 'CE'
                    ? AppDesignSystem.successLight
                    : AppDesignSystem.infoLight,
              ),
              child: Text(
                log.uf,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: log.uf == 'CE'
                      ? AppDesignSystem.success
                      : AppDesignSystem.info,
                ),
              ),
            ),
          ),
        ),

        
        const Text(
          '\t',
          style: TextStyle(fontSize: 1, color: Colors.transparent),
        ),

        SizedBox(width: Responsive.spacing(context)),

        // Coluna Ações
        SizedBox(
          width: 80,
          child: Center(
            child: _hasViewableChanges(log)
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.visibility_outlined, size: 16)],
                    ),
                  )
                : Container(),
          ),
        ),

        
        const Text(
          '\n',
          style: TextStyle(fontSize: 1, height: 0.1, color: Colors.transparent),
        ),
      ],
    );
  }

  String _getModuleDisplayName(LogModule module) {
    switch (module) {
      case LogModule.avaria:
        return 'Avarias';
      case LogModule.inventario:
        return 'Inventário';
      case LogModule.user:
        return 'Usuários';
      case LogModule.system:
        return 'Sistema';
    }
  }

  String _getActionDisplayName(LogAction action) {
    switch (action) {
      case LogAction.create:
        return 'Criação';
      case LogAction.update:
        return 'Edição';
      case LogAction.delete:
        return 'Exclusão';
      case LogAction.restore:
        return 'Restauração';
      case LogAction.view:
        return 'Visualização';
      case LogAction.export:
        return 'Exportação';
      case LogAction.login:
        return 'Login';
      case LogAction.logout:
        return 'Logout';
      case LogAction.duplicate:
        return 'Duplicação';
      case LogAction.backup:
        return 'Backup';
    }
  }
}
