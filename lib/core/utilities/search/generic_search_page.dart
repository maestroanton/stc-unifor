// Página genérica de busca
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:async';

import '../../design_system.dart';
import '../../base_page.dart';
import '../dashboard/pagination.dart';
import '../../utilities/shared/responsive.dart';
import '../../visuals/snackbar.dart';
import '../../../helpers/uf_helper.dart';
import '../date_picker_helper.dart';

/// Classe de configuração que define como a busca funciona para cada modelo
abstract class SearchConfig<T> {
  // Configuração da página
  String get pageTitle;
  IconData get pageIcon;
  String get emptyMessage;
  String get quickSearchHint;
  bool get showExcelExport => true; // Padrão true, pode ser sobrescrito

  // Configuração de paginação
  int get pageSize => 10; // Tamanho de página padrão, pode ser sobrescrito

  // Configuração dos campos
  List<SearchField> get searchFields;
  List<TableColumn> get tableColumns;

  // Operações de dados
  Future<List<T>> getAllItems();
  List<T> performQuickSearch(List<T> items, String query);
  List<T> applyAdvancedFilters(List<T> items, Map<String, dynamic> filters);

  // Construção das linhas da tabela
  AppTableRow buildTableRow(T item, VoidCallback onTap);
  Widget buildMobileCard(T item, VoidCallback onTap);

  // Exportação para Excel - opcional, implemente se necessário
  Future<void> exportToExcel(BuildContext context, List<T> items) async {
    // Implementação padrão: sem ação
    // Sobrescrever em configs específicas para exportar Excel
  }
}

/// Define a configuração de campo de busca
class SearchField {
  final String key;
  final String label;
  final SearchFieldType type;
  final String? hint;
  final List<String>? options; // Para dropdowns
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final int? flex; // Para layouts responsivos

  const SearchField({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.options,
    this.formatters,
    this.keyboardType,
    this.flex = 1,
  });
}

enum SearchFieldType {
  text,
  number,
  dropdown,
  date,
  range, // Para campos min/max
}

class TableColumn {
  final String title;
  final int flex;

  const TableColumn({required this.title, this.flex = 1});
}

/// Página genérica de busca que funciona com qualquer tipo de modelo T
class GenericSearchPage<T> extends SplitViewTemplate {
  final SearchConfig<T> config;
  final Function(T, Map<String, dynamic>) onViewItem;
  final String? initialSearchQuery;
  final Map<String, dynamic>? preservedFilters;

  // Instância de estado única compartilhada
  late final GenericSearchState<T> _searchState;

  GenericSearchPage({
    super.key,
    required this.config,
    required this.onViewItem,
    this.initialSearchQuery,
    this.preservedFilters,
  }) {
    _searchState = GenericSearchState<T>();
    _searchState.initializePageSize(config.pageSize);
  }

  @override
  String get pageTitle => config.pageTitle;

  @override
  IconData get pageIcon => config.pageIcon;

  @override
  List<Widget>? get headerActions =>
      config.showExcelExport ? [_ExcelExportButton<T>(config: config)] : null;

  @override
  Widget buildLeftPanel(BuildContext context) {
    return _GenericSearchFiltersPanel<T>(
      config: config,
      initialSearchQuery: initialSearchQuery,
      preservedFilters: preservedFilters,
      searchState: _searchState,
    );
  }

  @override
  Widget buildRightPanel(BuildContext context) {
    return _GenericSearchResultsPanel<T>(
      config: config,
      onViewItem: onViewItem,
      searchState: _searchState,
    );
  }

  // Sobrescreve buildContent para adicionar comportamento responsivo
  @override
  Widget buildContent(BuildContext context) {
    // Em telas pequenas, usar layout móvel
    if (Responsive.isSmallScreen(context)) {
      return _MobileSearchLayout<T>(
        config: config,
        onViewItem: onViewItem,
        initialSearchQuery: initialSearchQuery,
        preservedFilters: preservedFilters,
        searchState: _searchState,
      );
    }

    // Em telas maiores, usar o split view padrão
    return super.buildContent(context);
  }
}

/// Estado global de busca para qualquer tipo de modelo T
class GenericSearchState<T> extends ChangeNotifier {
  static final Map<Type, GenericSearchState> _instances = {};

  // Construtor factory fixo com tratamento de tipo apropriado
  factory GenericSearchState() {
    if (_instances.containsKey(T)) {
      return _instances[T]! as GenericSearchState<T>;
    } else {
      final instance = GenericSearchState<T>._internal();
      _instances[T] = instance;
      return instance;
    }
  }

  GenericSearchState._internal() {
    // Escuta alterações no estado de paginação e as propaga
    _paginationState.addListener(() {
      notifyListeners();
    });
  }

  // Resto da implementação da classe
  Map<String, dynamic> currentFilters = {};
  bool hasSearched = false;
  List<T> searchResults = [];
  bool isLoading = false;

  final PaginationState _paginationState = PaginationState();
  PaginationState get paginationState => _paginationState;

  void initializePageSize(int pageSize) {
    _paginationState.setPageSize(pageSize);
  }

  void updatePageSize(int pageSize) {
    _paginationState.setPageSize(pageSize);
    // Atualiza novamente o total de itens para acionar o recálculo da paginação
    _paginationState.updateTotalItems(searchResults.length);
    notifyListeners();
  }

  void updateFilters(Map<String, dynamic> filters) {
    currentFilters = Map.from(filters);
    notifyListeners();
  }

  void updateResults({
    required bool hasSearched,
    required List<T> results,
    bool isLoading = false,
    bool resetPagination = true,
  }) {
    this.hasSearched = hasSearched;
    searchResults = results;
    this.isLoading = isLoading;

    // Atualiza o estado de paginação com a nova contagem total de itens
    _paginationState.updateTotalItems(results.length);

    if (resetPagination) {
      _paginationState.goToPage(1);
    }

    notifyListeners();
  }

  void clear() {
    hasSearched = false;
    searchResults = [];
    isLoading = false;
    _paginationState.reset();
    notifyListeners();
  }

  // Obtém resultados paginados - use o mesmo método que o dashboard
  List<T> getPaginatedResults() {
    return _paginationState.getPaginatedItems(searchResults);
  }
}

/// Layout móvel de busca com navegação entre filtros e resultados
class _MobileSearchLayout<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final Function(T, Map<String, dynamic>) onViewItem;
  final String? initialSearchQuery;
  final Map<String, dynamic>? preservedFilters;
  final GenericSearchState<T> searchState;

  const _MobileSearchLayout({
    super.key,
    required this.config,
    required this.onViewItem,
    this.initialSearchQuery,
    this.preservedFilters,
    required this.searchState,
  });

  @override
  State<_MobileSearchLayout<T>> createState() => _MobileSearchLayoutState<T>();
}

class _MobileSearchLayoutState<T> extends State<_MobileSearchLayout<T>> {
  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    widget.searchState.addListener(_onSearchStateChanged);

    // Se tivermos filtros preservados ou uma busca inicial, mostrar resultados automaticamente
    if ((widget.preservedFilters != null &&
            widget.preservedFilters!.isNotEmpty) ||
        (widget.initialSearchQuery != null &&
            widget.initialSearchQuery!.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showingResults = true);
      });
    }
  }

  @override
  void dispose() {
    widget.searchState.removeListener(_onSearchStateChanged);
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showResults() {
    setState(() => _showingResults = true);
  }

  void _showFilters() {
    setState(() => _showingResults = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho móvel com navegação
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          decoration: const BoxDecoration(
            color: AppDesignSystem.surface,
            border: Border(
              bottom: BorderSide(color: AppDesignSystem.neutral200),
            ),
          ),
          child: Row(
            children: [
              // Título e status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showingResults ? 'Resultados' : 'Filtros de Pesquisa',
                      style: AppDesignSystem.h3,
                    ),
                    if (_showingResults && widget.searchState.hasSearched) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.searchState.searchResults.length} ${widget.searchState.searchResults.length == 1 ? 'item encontrado' : 'itens encontrados'}',
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: AppDesignSystem.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botão de exportação para Excel (à esquerda dos botões de alternância) - somente se habilitado
              if (widget.config.showExcelExport) ...[
                _MobileExcelExportButton<T>(config: widget.config),
              ],

              // Adiciona espaçamento entre botão de exportação e botões de alternância
              if (widget.config.showExcelExport &&
                  widget.searchState.hasSearched) ...[
                const SizedBox(width: AppDesignSystem.spacing8),
              ],

              // Botões de alternância para navegação
              if (_showingResults) ...[
                // Botão Voltar para filtros
                Container(
                  decoration: BoxDecoration(
                    color: AppDesignSystem.primary,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusM,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.tune),
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    tooltip: 'Ver Filtros',
                  ),
                ),
              ] else if (widget.searchState.hasSearched) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppDesignSystem.primary,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusM,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _showResults,
                    icon: const Icon(Icons.list_alt),
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    tooltip: 'Ver Resultados',
                  ),
                ),
              ],
            ],
          ),
        ),

        // Área de conteúdo
        Expanded(
          child: _showingResults
              ? _MobileSearchResults<T>(
                  config: widget.config,
                  onViewItem: widget.onViewItem,
                  onBackToFilters: _showFilters,
                  searchState: widget.searchState,
                )
              : _MobileSearchFilters<T>(
                  config: widget.config,
                  initialSearchQuery: widget.initialSearchQuery,
                  preservedFilters: widget.preservedFilters,
                  onSearchPerformed: _showResults,
                  searchState: widget.searchState,
                ),
        ),
      ],
    );
  }
}

/// Filtros de busca otimizados para mobile
class _MobileSearchFilters<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final String? initialSearchQuery;
  final Map<String, dynamic>? preservedFilters;
  final VoidCallback onSearchPerformed;
  final GenericSearchState<T> searchState;

  const _MobileSearchFilters({
    super.key,
    required this.config,
    this.initialSearchQuery,
    this.preservedFilters,
    required this.onSearchPerformed,
    required this.searchState,
  });

  @override
  State<_MobileSearchFilters<T>> createState() =>
      _MobileSearchFiltersState<T>();
}

class _MobileSearchFiltersState<T> extends State<_MobileSearchFilters<T>> {
  final _formKey = GlobalKey<FormState>();

  // Controladores e valores
  final _quickSearchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};

  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Inicializa controllers para todos os campos
    for (final field in widget.config.searchFields) {
      if (field.type != SearchFieldType.dropdown) {
        _controllers[field.key] = TextEditingController();
      }
    }

    // Carrega filtros preservados, se houver
    if (widget.preservedFilters != null) {
      _loadPreservedFilters(widget.preservedFilters!);
      // Não faz busca automática; usuário aciona manualmente
    } else if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _quickSearchController.text = widget.initialSearchQuery!;
      // Busca automática quando query inicial é fornecida pela navegação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }

    // Adiciona debounce na busca rápida — somente para mudanças manuais
    _quickSearchController.addListener(_onQuickSearchChanged);
  }

  void _onQuickSearchChanged() {
    _searchDebounceTimer?.cancel();

    final currentText = _quickSearchController.text.trim();

    // Só busca se:
    // 1. Texto não está vazio
    // 2. Texto possui pelo menos 3 caracteres
    // 3. Usuário ficou inativo por 3 segundos
    if (currentText.isNotEmpty && currentText.length >= 3) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted &&
            _quickSearchController.text.trim() == currentText &&
            currentText.isNotEmpty &&
            currentText.length >= 3) {
          _performSearch();
        }
      });
    }
  }

  void _loadPreservedFilters(Map<String, dynamic> filters) {
    _quickSearchController.text = filters['quickSearch'] ?? '';

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        _dropdownValues[field.key] = filters[field.key];
      } else {
        _controllers[field.key]?.text = filters[field.key] ?? '';
      }
    }
  }

  Map<String, dynamic> _buildCurrentFilters() {
    final filters = <String, dynamic>{
      'quickSearch': _quickSearchController.text.trim(),
    };

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) {
          filters[field.key] = _dropdownValues[field.key];
        }
      } else {
        final value = _controllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          filters[field.key] = value;
        }
      }
    }

    return filters;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _quickSearchController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca rápida - em destaque no mobile
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              decoration: BoxDecoration(
                color: AppDesignSystem.surface,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
                border: Border.all(color: AppDesignSystem.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesquisa Rápida',
                    style: AppDesignSystem.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacing8),
                  TextFormField(
                    controller: _quickSearchController,
                    decoration: AppDesignSystem.inputDecoration(
                      hint: widget.config.quickSearchHint,
                      prefixIcon: const Icon(
                        Icons.search_outlined,
                        color: AppDesignSystem.neutral500,
                      ),
                      suffixIcon: _quickSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppDesignSystem.neutral400,
                                size: 20,
                              ),
                              onPressed: () {
                                _quickSearchController.clear();
                                widget.searchState.clear();
                              },
                            )
                          : null,
                    ),
                    onFieldSubmitted: (_) => _performSearch(),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDesignSystem.spacing24),

            // Advanced Filters Section
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              decoration: BoxDecoration(
                color: AppDesignSystem.surface,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
                border: Border.all(color: AppDesignSystem.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: AppDesignSystem.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppDesignSystem.spacing8),
                      Text(
                        'Filtros Avançados',
                        style: AppDesignSystem.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignSystem.spacing16),

                  // Cria todos os campos de busca
                  ...widget.config.searchFields.map((field) {
                    return Column(
                      children: [
                        _buildSearchField(field),
                        const SizedBox(height: AppDesignSystem.spacing16),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppDesignSystem.spacing24),

            // Botões de ação - largura completa no mobile
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSearching ? null : _clearForm,
                    style: AppDesignSystem.secondaryButton,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.clear),
                        SizedBox(width: 8),
                        Text('Limpar'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: AppDesignSystem.primaryButton,
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search),
                              SizedBox(width: 8),
                              Text(
                                'Pesquisar',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            // Adiciona espaçamento inferior para mobile
            const SizedBox(height: AppDesignSystem.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(SearchField field) {
    switch (field.type) {
      case SearchFieldType.dropdown:
        return AppFormField(
          label: field.label,
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _dropdownValues[field.key],
              isExpanded: true,
              hint: Text(
                field.hint ?? 'Selecione ${field.label.toLowerCase()}',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppDesignSystem.neutral400,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos', style: TextStyle(color: Colors.grey)),
                ),
                ...?field.options?.map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: AppDesignSystem.bodyMedium),
                  ),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _dropdownValues[field.key] = value),
              buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppDesignSystem.neutral300),
                  color: AppDesignSystem.surface,
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppDesignSystem.neutral600,
                ),
                iconSize: 24,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppDesignSystem.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                scrollbarTheme: ScrollbarThemeData(
                  radius: const Radius.circular(40),
                  thickness: WidgetStateProperty.all(6),
                  thumbVisibility: WidgetStateProperty.all(true),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        );

      case SearchFieldType.date:
        return AppFormField(
          label: field.label,
          child: TextFormField(
            controller: _controllers[field.key],
            decoration: AppDesignSystem.inputDecoration(
              hint: field.hint ?? 'dd/mm/aaaa',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _selectDate(context, _controllers[field.key]!),
                tooltip: 'Selecionar data',
              ),
            ),
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              MaskTextInputFormatter(
                mask: '##/##/####',
                filter: {"#": RegExp(r'[0-9]')},
              ),
            ],
            onFieldSubmitted: (_) => _performSearch(),
          ),
        );

      default:
        return AppFormField(
          label: field.label,
          child: TextFormField(
            controller: _controllers[field.key],
            decoration: AppDesignSystem.inputDecoration(
              hint: field.hint ?? field.label,
            ),
            keyboardType: field.keyboardType,
            inputFormatters: field.formatters,
            onFieldSubmitted: (_) => _performSearch(),
          ),
        );
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    // Parse current date if any
    DateTime? initialDate;
    if (controller.text.isNotEmpty) {
      initialDate = DatePickerHelper.parseDate(controller.text);
    }

    final DateTime? picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.text = DatePickerHelper.formatDate(picked);
    }
  }

  void _clearForm() {
    _searchDebounceTimer?.cancel();
    _quickSearchController.clear();

    for (final controller in _controllers.values) {
      controller.clear();
    }

    setState(() {
      _dropdownValues.clear();
    });

    widget.searchState.clear();
  }

  Future<void> _performSearch() async {
    final hasQuickSearch = _quickSearchController.text.trim().isNotEmpty;
    final hasAdvancedFilters = _hasAdvancedFilters();

    final currentFilters = _buildCurrentFilters();
    widget.searchState.updateFilters(currentFilters);

    // Permite buscar tudo quando nenhum critério for fornecido
    // if (!hasQuickSearch && !hasAdvancedFilters) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: const Text(
    //         'Digite algo para pesquisar ou use os filtros avançados',
    //       ),
    //       backgroundColor: AppDesignSystem.warning,
    //     ),
    //   );
    //   return;
    // }

    setState(() => _isSearching = true);
    widget.searchState.updateResults(
      hasSearched: true,
      results: [],
      isLoading: true,
    );

    try {
      final allItems = await widget.config.getAllItems();
      List<T> filteredResults;

      if (hasQuickSearch) {
        filteredResults = widget.config.performQuickSearch(
          allItems,
          _quickSearchController.text.trim(),
        );

        if (hasAdvancedFilters) {
          final advancedFilters = _buildAdvancedFilters();
          filteredResults = widget.config.applyAdvancedFilters(
            filteredResults,
            advancedFilters,
          );
        }
      } else {
        final filters = _buildAdvancedFilters();
        filteredResults = widget.config.applyAdvancedFilters(allItems, filters);
      }

      widget.searchState.updateResults(
        hasSearched: true,
        results: filteredResults,
        isLoading: false,
      );

      // Mostrar resultados após a busca no mobile
      widget.onSearchPerformed();
    } catch (e) {
      widget.searchState.updateResults(
        hasSearched: true,
        results: [],
        isLoading: false,
      );

      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao pesquisar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  bool _hasAdvancedFilters() {
    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) return true;
      } else {
        if (_controllers[field.key]?.text.trim().isNotEmpty == true) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, dynamic> _buildAdvancedFilters() {
    final filters = <String, dynamic>{};

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) {
          filters[field.key] = _dropdownValues[field.key];
        }
      } else {
        final value = _controllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          filters[field.key] = value;
        }
      }
    }

    return filters;
  }
}

/// Resultados da busca otimizados para mobile
class _MobileSearchResults<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final Function(T, Map<String, dynamic>) onViewItem;
  final VoidCallback onBackToFilters;
  final GenericSearchState<T> searchState;

  const _MobileSearchResults({
    super.key,
    required this.config,
    required this.onViewItem,
    required this.onBackToFilters,
    required this.searchState,
  });

  @override
  State<_MobileSearchResults<T>> createState() =>
      _MobileSearchResultsState<T>();
}

class _MobileSearchResultsState<T> extends State<_MobileSearchResults<T>> {
  @override
  void initState() {
    super.initState();
    widget.searchState.addListener(_onSearchStateChanged);
  }

  @override
  void dispose() {
    widget.searchState.removeListener(_onSearchStateChanged);
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.searchState.hasSearched) {
      return Container(
        decoration: const BoxDecoration(color: AppDesignSystem.background),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_outlined,
                size: 64,
                color: AppDesignSystem.neutral300,
              ),
              const SizedBox(height: AppDesignSystem.spacing16),
              const Text(
                'Nenhuma pesquisa realizada',
                style: TextStyle(color: AppDesignSystem.neutral500),
              ),
              const SizedBox(height: AppDesignSystem.spacing8),
              Text(
                'Use os filtros para encontrar itens',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppDesignSystem.neutral400,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacing24),
              ElevatedButton.icon(
                onPressed: widget.onBackToFilters,
                icon: const Icon(Icons.tune),
                label: const Text('Ir para Filtros'),
                style: AppDesignSystem.primaryButton,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.searchState.isLoading) {
      return Container(
        decoration: const BoxDecoration(color: AppDesignSystem.background),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.searchState.searchResults.isEmpty) {
      return Container(
        decoration: const BoxDecoration(color: AppDesignSystem.background),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off_outlined,
                  size: 64,
                  color: AppDesignSystem.neutral300,
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                Text(
                  widget.config.emptyMessage,
                  style: AppDesignSystem.bodyLarge.copyWith(
                    color: AppDesignSystem.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                Text(
                  'Tente termos diferentes ou menos específicos',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.neutral400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignSystem.spacing24),
                ElevatedButton.icon(
                  onPressed: widget.onBackToFilters,
                  icon: const Icon(Icons.tune),
                  label: const Text('Ajustar Filtros'),
                  style: AppDesignSystem.primaryButton,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Aplica paginação exatamente como o dashboard faz
    final paginatedResults = widget.searchState.paginationState
        .getPaginatedItems(widget.searchState.searchResults);

    return Container(
      decoration: const BoxDecoration(color: AppDesignSystem.background),
      child: Column(
        children: [
          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDesignSystem.spacing16),
              itemCount: paginatedResults.length,
              itemBuilder: (context, index) {
                final item = paginatedResults[index];
                return widget.config.buildMobileCard(item, () {
                  final currentFilters = widget.searchState.currentFilters;
                  widget.onViewItem(item, currentFilters);
                });
              },
            ),
          ),

          // Pagination footer - same as dashboard
          _SearchPaginationFooter<T>(searchState: widget.searchState),
        ],
      ),
    );
  }
}

/// Painel esquerdo para desktop com filtros de busca
class _GenericSearchFiltersPanel<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final String? initialSearchQuery;
  final Map<String, dynamic>? preservedFilters;
  final GenericSearchState<T> searchState;

  const _GenericSearchFiltersPanel({
    super.key,
    required this.config,
    this.initialSearchQuery,
    this.preservedFilters,
    required this.searchState,
  });

  @override
  State<_GenericSearchFiltersPanel<T>> createState() =>
      _GenericSearchFiltersPanelState<T>();
}

class _GenericSearchFiltersPanelState<T>
    extends State<_GenericSearchFiltersPanel<T>> {
  final _formKey = GlobalKey<FormState>();

  // Controladores e valores
  final _quickSearchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};

  // Nós de foco para ordem de tabulação correta
  final _quickSearchFocusNode = FocusNode();
  final Map<String, FocusNode> _focusNodes = {};
  final _clearButtonFocusNode = FocusNode();
  final _searchButtonFocusNode = FocusNode();

  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Inicializa controllers e nós de foco para todos os campos
    for (final field in widget.config.searchFields) {
      if (field.type != SearchFieldType.dropdown) {
        _controllers[field.key] = TextEditingController();
      }
      _focusNodes[field.key] = FocusNode();

      // Para campos de intervalo, cria nós de foco adicionais
      if (field.type == SearchFieldType.range) {
        _focusNodes['${field.key}Min'] = FocusNode();
        _focusNodes['${field.key}Max'] = FocusNode();
      }
    }

    // Carrega filtros preservados, se houver
    if (widget.preservedFilters != null) {
      _loadPreservedFilters(widget.preservedFilters!);
      // Não realize busca automática; deixe o usuário acionar manualmente
    } else if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _quickSearchController.text = widget.initialSearchQuery!;
      // Busca automática quando uma query inicial for fornecida pela navegação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }

    // Adiciona debounce na busca rápida — apenas para mudanças manuais
    _quickSearchController.addListener(_onQuickSearchChanged);
  }

  void _onQuickSearchChanged() {
    _searchDebounceTimer?.cancel();

    final currentText = _quickSearchController.text.trim();

    // Só busca se:
    // 1. Texto não está vazio
    // 2. Texto tem pelo menos 3 caracteres
    // 3. Usuário ficou inativo por 3 segundos
    if (currentText.isNotEmpty && currentText.length >= 3) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted &&
            _quickSearchController.text.trim() == currentText &&
            currentText.isNotEmpty &&
            currentText.length >= 3) {
          _performSearch();
        }
      });
    }
  }

  void _loadPreservedFilters(Map<String, dynamic> filters) {
    _quickSearchController.text = filters['quickSearch'] ?? '';

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        _dropdownValues[field.key] = filters[field.key];
      } else {
        _controllers[field.key]?.text = filters[field.key] ?? '';
      }
    }

    setState(() {});
  }

  Map<String, dynamic> _buildCurrentFilters() {
    final filters = <String, dynamic>{
      'quickSearch': _quickSearchController.text.trim(),
    };

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) {
          filters[field.key] = _dropdownValues[field.key];
        }
      } else {
        final value = _controllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          filters[field.key] = value;
        }
      }
    }

    return filters;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _quickSearchController.dispose();
    _quickSearchFocusNode.dispose();
    _clearButtonFocusNode.dispose();
    _searchButtonFocusNode.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacing24),
        child: AppCard(
          title: 'Filtros de Pesquisa',
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Campo de busca rápida (mais utilizado)
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1.0),
                  child: AppFormField(
                    label: 'Pesquisa Rápida',
                    child: TextFormField(
                      controller: _quickSearchController,
                      focusNode: _quickSearchFocusNode,
                      decoration: AppDesignSystem.inputDecoration(
                        hint: widget.config.quickSearchHint,
                        prefixIcon: const Icon(
                          Icons.search_outlined,
                          color: AppDesignSystem.neutral500,
                        ),
                        suffixIcon: _quickSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppDesignSystem.neutral400,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _quickSearchController.clear();
                                  widget.searchState.clear();
                                },
                              )
                            : null,
                      ),
                      onFieldSubmitted: (_) => _performSearch(),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),

                const SizedBox(height: AppDesignSystem.spacing16),

                // Cria todos os campos de busca com ordem de tabulação sequencial
                ...widget.config.searchFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  return Column(
                    children: [
                      FocusTraversalOrder(
                        order: NumericFocusOrder(2.0 + index),
                        child: _buildSearchField(field),
                      ),
                      const SizedBox(height: AppDesignSystem.spacing16),
                    ],
                  );
                }),

                const SizedBox(height: AppDesignSystem.spacing16),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: FocusTraversalOrder(
                        order: NumericFocusOrder(
                          100.0 + widget.config.searchFields.length,
                        ),
                        child: OutlinedButton(
                          focusNode: _clearButtonFocusNode,
                          onPressed: _isSearching ? null : _clearForm,
                          style: AppDesignSystem.secondaryButton,
                          child: const Text('Limpar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing12),
                    Expanded(
                      child: FocusTraversalOrder(
                        order: NumericFocusOrder(
                          101.0 + widget.config.searchFields.length,
                        ),
                        child: ElevatedButton(
                          focusNode: _searchButtonFocusNode,
                          onPressed: _isSearching ? null : _performSearch,
                          style: AppDesignSystem.primaryButton,
                          child: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Pesquisar',
                                  style: TextStyle(fontWeight: FontWeight.w500),
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
      ),
    );
  }

  Widget _buildSearchField(SearchField field) {
    switch (field.type) {
      case SearchFieldType.dropdown:
        return AppFormField(
          label: field.label,
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _dropdownValues[field.key],
              isExpanded: true,
              hint: Text(
                field.hint ?? 'Selecione ${field.label.toLowerCase()}',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppDesignSystem.neutral400,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos', style: TextStyle(color: Colors.grey)),
                ),
                ...?field.options?.map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: AppDesignSystem.bodyMedium),
                  ),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _dropdownValues[field.key] = value),
              buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppDesignSystem.neutral300),
                  color: AppDesignSystem.surface,
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppDesignSystem.neutral600,
                ),
                iconSize: 24,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppDesignSystem.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                scrollbarTheme: ScrollbarThemeData(
                  radius: const Radius.circular(40),
                  thickness: WidgetStateProperty.all(6),
                  thumbVisibility: WidgetStateProperty.all(true),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        );

      case SearchFieldType.date:
        return AppFormField(
          label: field.label,
          child: TextFormField(
            controller: _controllers[field.key],
            focusNode: _focusNodes[field.key],
            decoration: AppDesignSystem.inputDecoration(
              hint: field.hint ?? 'dd/mm/aaaa',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _selectDate(context, _controllers[field.key]!),
                tooltip: 'Selecionar data',
              ),
            ),
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              MaskTextInputFormatter(
                mask: '##/##/####',
                filter: {"#": RegExp(r'[0-9]')},
              ),
            ],
            onFieldSubmitted: (_) => _performSearch(),
          ),
        );

      case SearchFieldType.range:
        // Para campos de intervalo, criaremos dois campos lado a lado
        final minKey = '${field.key}Min';
        final maxKey = '${field.key}Max';

        // Garante que controllers existam para campos de intervalo
        if (!_controllers.containsKey(minKey)) {
          _controllers[minKey] = TextEditingController();
        }
        if (!_controllers.containsKey(maxKey)) {
          _controllers[maxKey] = TextEditingController();
        }

        return Row(
          children: [
            Expanded(
              child: AppFormField(
                label: '${field.label} Mínimo',
                child: TextFormField(
                  controller: _controllers[minKey],
                  focusNode: _focusNodes[minKey],
                  decoration: AppDesignSystem.inputDecoration(
                    hint: field.hint ?? 'Mínimo',
                  ),
                  keyboardType: field.keyboardType,
                  inputFormatters: field.formatters,
                  onFieldSubmitted: (_) => _performSearch(),
                ),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing16),
            Expanded(
              child: AppFormField(
                label: '${field.label} Máximo',
                child: TextFormField(
                  controller: _controllers[maxKey],
                  focusNode: _focusNodes[maxKey],
                  decoration: AppDesignSystem.inputDecoration(
                    hint: field.hint ?? 'Máximo',
                  ),
                  keyboardType: field.keyboardType,
                  inputFormatters: field.formatters,
                  onFieldSubmitted: (_) => _performSearch(),
                ),
              ),
            ),
          ],
        );

      default:
        return AppFormField(
          label: field.label,
          child: TextFormField(
            controller: _controllers[field.key],
            focusNode: _focusNodes[field.key],
            decoration: AppDesignSystem.inputDecoration(
              hint: field.hint ?? field.label,
            ),
            keyboardType: field.keyboardType,
            inputFormatters: field.formatters,
            onFieldSubmitted: (_) => _performSearch(),
          ),
        );
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    // Parse current date if any
    DateTime? initialDate;
    if (controller.text.isNotEmpty) {
      initialDate = DatePickerHelper.parseDate(controller.text);
    }

    final DateTime? picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.text = DatePickerHelper.formatDate(picked);
    }
  }

  void _clearForm() {
    _searchDebounceTimer?.cancel();
    _quickSearchController.clear();

    for (final controller in _controllers.values) {
      controller.clear();
    }

    setState(() {
      _dropdownValues.clear();
    });

    widget.searchState.clear();
  }

  Future<void> _performSearch() async {
    final hasQuickSearch = _quickSearchController.text.trim().isNotEmpty;
    final hasAdvancedFilters = _hasAdvancedFilters();

    final currentFilters = _buildCurrentFilters();
    widget.searchState.updateFilters(currentFilters);

    // Permite buscar tudo quando nenhum critério for fornecido
    // if (!hasQuickSearch && !hasAdvancedFilters) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: const Text(
    //         'Digite algo para pesquisar ou use os filtros avançados',
    //       ),
    //       backgroundColor: AppDesignSystem.warning,
    //     ),
    //   );
    //   return;
    // }

    setState(() => _isSearching = true);
    widget.searchState.updateResults(
      hasSearched: true,
      results: [],
      isLoading: true,
    );

    try {
      final allItems = await widget.config.getAllItems();
      List<T> filteredResults;

      if (hasQuickSearch) {
        filteredResults = widget.config.performQuickSearch(
          allItems,
          _quickSearchController.text.trim(),
        );

        if (hasAdvancedFilters) {
          final advancedFilters = _buildAdvancedFilters();
          filteredResults = widget.config.applyAdvancedFilters(
            filteredResults,
            advancedFilters,
          );
        }
      } else {
        final filters = _buildAdvancedFilters();
        filteredResults = widget.config.applyAdvancedFilters(allItems, filters);
      }

      widget.searchState.updateResults(
        hasSearched: true,
        results: filteredResults,
        isLoading: false,
      );
    } catch (e) {
      widget.searchState.updateResults(
        hasSearched: true,
        results: [],
        isLoading: false,
      );

      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao pesquisar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  bool _hasAdvancedFilters() {
    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) return true;
      } else if (field.type == SearchFieldType.range) {
        final minKey = '${field.key}Min';
        final maxKey = '${field.key}Max';
        if (_controllers[minKey]?.text.trim().isNotEmpty == true ||
            _controllers[maxKey]?.text.trim().isNotEmpty == true) {
          return true;
        }
      } else {
        if (_controllers[field.key]?.text.trim().isNotEmpty == true) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, dynamic> _buildAdvancedFilters() {
    final filters = <String, dynamic>{};

    for (final field in widget.config.searchFields) {
      if (field.type == SearchFieldType.dropdown) {
        if (_dropdownValues[field.key] != null) {
          filters[field.key] = _dropdownValues[field.key];
        }
      } else if (field.type == SearchFieldType.range) {
        final minKey = '${field.key}Min';
        final maxKey = '${field.key}Max';
        final minValue = _controllers[minKey]?.text.trim() ?? '';
        final maxValue = _controllers[maxKey]?.text.trim() ?? '';
        if (minValue.isNotEmpty) filters[minKey] = minValue;
        if (maxValue.isNotEmpty) filters[maxKey] = maxValue;
      } else {
        final value = _controllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          filters[field.key] = value;
        }
      }
    }

    return filters;
  }
}

/// Painel direito para desktop com resultados de busca e paginação
class _GenericSearchResultsPanel<T> extends StatefulWidget {
  final SearchConfig<T> config;
  final Function(T, Map<String, dynamic>) onViewItem;
  final GenericSearchState<T> searchState;

  const _GenericSearchResultsPanel({
    super.key,
    required this.config,
    required this.onViewItem,
    required this.searchState,
  });

  @override
  State<_GenericSearchResultsPanel<T>> createState() =>
      _GenericSearchResultsPanelState<T>();
}

class _GenericSearchResultsPanelState<T>
    extends State<_GenericSearchResultsPanel<T>> {
  @override
  void initState() {
    super.initState();
    widget.searchState.addListener(_onSearchStateChanged);
  }

  @override
  void dispose() {
    widget.searchState.removeListener(_onSearchStateChanged);
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.searchState.hasSearched) {
      return AppDesignSystem.emptyState(
        icon: Icons.search_outlined,
        title: 'Preencha os filtros e clique em "Pesquisar"',
        subtitle: 'Use os campos à esquerda para filtrar os itens',
      );
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Container(
        color: AppDesignSystem.surface,
        child: Column(
          children: [
            // Cabeçalho de resultados com informações de paginação
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppDesignSystem.neutral200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.config.pageIcon,
                    color: AppDesignSystem.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  const Text(
                    'Resultados da Pesquisa',
                    style: AppDesignSystem.h3,
                  ),
                  const Spacer(),
                  PaginationResultsCount(
                    paginationState: widget.searchState.paginationState,
                    emptyMessage: widget.config.emptyMessage,
                  ),
                ],
              ),
            ),

            // Tabela de resultados com paginação
            Expanded(
              child: Column(
                children: [
                  // Table
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(
                        1000.0,
                      ), // Número alto de ordem para resultados
                      child: AppDataTable(
                        isLoading: widget.searchState.isLoading,
                        emptyMessage:
                            '${widget.config.emptyMessage}\nTente termos diferentes ou menos específicos',
                        emptyIcon: Icons.search_off_outlined,
                        columns: widget.config.tableColumns
                            .map(
                              (col) => AppTableColumn(
                                title: col.title,
                                flex: col.flex,
                              ),
                            )
                            .toList(),
                        rows: widget.searchState
                            .getPaginatedResults()
                            .map(
                              (item) => widget.config.buildTableRow(item, () {
                                final currentFilters =
                                    widget.searchState.currentFilters;
                                widget.onViewItem(item, currentFilters);
                              }),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  // Pagination footer
                  if (widget.searchState.searchResults.isNotEmpty)
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1001.0), // After results
                      child: _SearchPaginationFooter<T>(
                        searchState: widget.searchState,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de exportação para Excel com verificação de acesso a relatórios
class _ExcelExportButton<T> extends StatefulWidget {
  final SearchConfig<T> config;

  const _ExcelExportButton({super.key, required this.config});

  @override
  State<_ExcelExportButton<T>> createState() => _ExcelExportButtonState<T>();
}

class _ExcelExportButtonState<T> extends State<_ExcelExportButton<T>> {
  bool _hasReportAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReportAccess();
  }

  Future<void> _checkReportAccess() async {
    try {
      final hasAccess = await UfHelper.hasReportAccess();
      if (mounted) {
        setState(() {
          _hasReportAccess = hasAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasReportAccess = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExport() async {
    if (!_hasReportAccess) return;

    try {
      // Obtém o estado da busca para acessar os resultados atuais
      final searchState = GenericSearchState<T>();

      // Exportar apenas o que está atualmente exibido na tela
      if (!searchState.hasSearched || searchState.searchResults.isEmpty) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            'Nenhum resultado para exportar. Execute uma pesquisa primeiro.',
          );
        }
        return;
      }

      // Exportar apenas os resultados atuais da busca
      await widget.config.exportToExcel(context, searchState.searchResults);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao exportar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostrar botão se estiver carregando ou não tiver acesso ao relatório
    if (_isLoading || !_hasReportAccess) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.file_download_outlined),
      tooltip: 'Exportar para Excel',
      onPressed: _handleExport,
      style: AppDesignSystem.secondaryButton,
    );
  }
}

/// Botão de exportação para Excel no mobile com estilo de botão secundário
class _MobileExcelExportButton<T> extends StatefulWidget {
  final SearchConfig<T> config;

  const _MobileExcelExportButton({super.key, required this.config});

  @override
  State<_MobileExcelExportButton<T>> createState() =>
      _MobileExcelExportButtonState<T>();
}

class _MobileExcelExportButtonState<T>
    extends State<_MobileExcelExportButton<T>> {
  bool _hasReportAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReportAccess();
  }

  Future<void> _checkReportAccess() async {
    try {
      final hasAccess = await UfHelper.hasReportAccess();
      if (mounted) {
        setState(() {
          _hasReportAccess = hasAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasReportAccess = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExport() async {
    if (!_hasReportAccess) return;

    try {
      // Obtém o estado da busca para acessar os resultados atuais
      final searchState = GenericSearchState<T>();

      // Exportar apenas o que está atualmente exibido na tela
      if (!searchState.hasSearched || searchState.searchResults.isEmpty) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            'Nenhum resultado para exportar. Execute uma pesquisa primeiro.',
          );
        }
        return;
      }

      // Exportar apenas os resultados atuais da busca
      await widget.config.exportToExcel(context, searchState.searchResults);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao exportar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostrar botão se estiver carregando ou não tiver acesso ao relatório
    if (_isLoading || !_hasReportAccess) {
      return const SizedBox.shrink();
    }

    // Obtém o estado da busca para verificar se há resultados
    final searchState = GenericSearchState<T>();
    final hasResults =
        searchState.hasSearched && searchState.searchResults.isNotEmpty;

    return AnimatedOpacity(
      opacity: hasResults ? 1.0 : 0.5,
      duration: AppDesignSystem.animationFast,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppDesignSystem.neutral300),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        ),
        child: IconButton(
          onPressed: hasResults ? _handleExport : null,
          icon: const Icon(Icons.file_download_outlined),
          tooltip: hasResults
              ? 'Exportar para Excel'
              : 'Execute uma pesquisa para exportar',
          style: IconButton.styleFrom(
            foregroundColor: hasResults
                ? AppDesignSystem.neutral600
                : AppDesignSystem.neutral400,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}

/// Rodapé de paginação customizado para busca que lida corretamente com atualizações de estado
class _SearchPaginationFooter<T> extends StatelessWidget {
  final GenericSearchState<T> searchState;
  final bool showPageSizeSelector;
  final List<int> pageSizeOptions;

  const _SearchPaginationFooter({
    super.key,
    required this.searchState,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [10, 15, 25, 50],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: searchState,
      builder: (context, _) {
        if (searchState.paginationState.totalItems == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing12,
          ),
          decoration: const BoxDecoration(
            color: AppDesignSystem.surface,
            border: Border(top: BorderSide(color: AppDesignSystem.neutral200)),
          ),
          child: Row(
            children: [
              if (showPageSizeSelector) ...[
                _buildPageSizeSelector(),
                const SizedBox(width: AppDesignSystem.spacing16),
              ],

              const Spacer(),

              // Controles de navegação
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão anterior
                  _buildPaginationButton(
                    icon: Icons.chevron_left,
                    onPressed: searchState.paginationState.hasPreviousPage
                        ? () => searchState.paginationState.previousPage()
                        : null,
                    tooltip: 'Página anterior',
                  ),

                  const SizedBox(width: AppDesignSystem.spacing4),

                  // Page number indicator
                  Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${searchState.paginationState.currentPage}',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDesignSystem.spacing4),

                  // Botão Próximo
                  _buildPaginationButton(
                    icon: Icons.chevron_right,
                    onPressed: searchState.paginationState.hasNextPage
                        ? () => searchState.paginationState.nextPage()
                        : null,
                    tooltip: 'Próxima página',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing8,
        vertical: AppDesignSystem.spacing6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppDesignSystem.neutral200),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        color: AppDesignSystem.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.view_list,
            size: 14,
            color: AppDesignSystem.neutral500,
          ),
          const SizedBox(width: AppDesignSystem.spacing4),
          DropdownButton<int>(
            value: searchState.paginationState.pageSize,
            underline: const SizedBox(),
            isDense: true,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral600,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: AppDesignSystem.neutral400,
            ),
            items: pageSizeOptions
                .map(
                  (size) => DropdownMenuItem(value: size, child: Text('$size')),
                )
                .toList(),
            onChanged: (value) {
              // Use o método personalizado updatePageSize em vez de setPageSize
              searchState.updatePageSize(value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      iconSize: 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? AppDesignSystem.neutral700
            : AppDesignSystem.neutral300,
        backgroundColor: onPressed != null
            ? AppDesignSystem.neutral50
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        ),
      ),
    );
  }
}
