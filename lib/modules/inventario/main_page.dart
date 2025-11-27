import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system.dart';
import '../../helpers/database_helper_inventario.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';
import '../../core/visuals/snackbar.dart';

// Importar páginas existentes
import 'widgets/sidebar.dart';
import 'dashboard.dart';
import 'smart_form.dart';
import 'list.dart'; // Lista v2

// Importar páginas de visualização
import 'widgets/list/view.dart';
import 'widgets/list/nota_fiscal_view.dart';
import 'trash.dart';

// Importar configuração de busca
import 'search_config.dart';
import '../../core/utilities/search/generic_search_page.dart';

class InventarioMainPage extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const InventarioMainPage({super.key, this.initialFilters});

  @override
  State<InventarioMainPage> createState() => _InventarioMainPageState();
}

class _InventarioMainPageState extends State<InventarioMainPage> {
  final _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    String _lastViewSource =
      'list'; // 'list', 'search', 'dashboard', 'notaFiscal' ou 'trash'
  Map<String, dynamic> _lastSearchFilters = {}; // armazena filtros de busca

  // Estado compartilhado entre páginas
  List<NotaFiscal> _notasFiscais = [];
  List<Inventario> _inventarios = [];
  NotaFiscal? _selectedNota;
  Inventario? _selectedInventario;
  Inventario? _editingInventario; // item em edição
  NotaFiscal? _editingNotaFiscal; // NotaFiscal pai ao editar
  Map<String, dynamic> _listFilters = {};
  int _selectedIndex =
      0; // índices: 0=Dashboard, 1=Lista, 2=Pesquisar, 3=Lixeira, 4=Item(Form), 5=View, 6=Smart Form

  // Breakpoint para drawer responsivo
  static const double _drawerBreakpoint = 768.0;

  @override
  void initState() {
    super.initState();
    _listFilters = widget.initialFilters ?? {};

    // Se houver filtros iniciais, abrir a lista em vez do dashboard
    if (widget.initialFilters != null && widget.initialFilters!.isNotEmpty) {
      _selectedIndex = 1; // navegar para página de lista
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(1);
      });
    }

    _loadInventarios();
  }

  Future<void> _clearSavedSmartFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smart_form_nota');
      await prefs.remove('smart_form_data_compra');
      await prefs.remove('smart_form_fornecedor');
      await prefs.remove('smart_form_custom_prompt');
      await prefs.remove('smart_form_items');
      await prefs.remove('smart_form_show_custom_prompt');
      await prefs.remove('smart_form_image_path');
    } catch (e) {
      // Tratar erros silenciosamente
      debugPrint('Error clearing saved smart form data: $e');
    }
  }

  @override
  void dispose() {
    // Limpa dados do smart form ao sair do módulo
    _clearSavedSmartFormData();
    _pageController.dispose();
    super.dispose();
  }

  bool _isLargeScreen() {
    return MediaQuery.of(context).size.width >= _drawerBreakpoint;
  }

  Future<void> _loadInventarios() async {
    try {
      final helper = DatabaseHelperInventario();
      final notas = await helper.getAllNotasFiscais();
      final items = await helper.getInventarios();

      if (mounted) {
        setState(() {
          _notasFiscais = notas;
          _inventarios = items;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar dados: $e');
      }
    }
  }

  void _navigateToPage(int index) {
    // Evita navegar para a mesma página
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Usa jumpToPage para navegação instantânea sem animação
    _pageController.jumpToPage(index);
  }

  // Navega para lista com filtros do dashboard
  void _navigateToListWithFilters(Map<String, dynamic> filters) {
    if (!mounted) return;

    setState(() {
      _listFilters = filters;
    });

    // Mensagem breve sobre filtro se houver sourceCard
    if (filters.containsKey('sourceCard')) {
      final cardType = filters['sourceCard'];
      String filterMessage;

      switch (cardType) {
        case 'total':
          filterMessage = 'Mostrando todos os itens';
          break;
        case 'presente':
          filterMessage = 'Mostrando itens presentes';
          break;
        case 'ausente':
          filterMessage = 'Mostrando itens ausentes';
          break;
        case 'valorTotal':
          filterMessage = 'Mostrando todos os itens';
          break;
        case 'valorAlto':
          filterMessage = 'Mostrando itens de alto valor (R\$ 1.000+)';
          break;
        case 'garantiaVencendo':
          filterMessage = 'Mostrando itens com garantia vencendo';
          break;
        case 'semSerie':
          filterMessage = 'Mostrando itens de alto valor sem número de série';
          break;
        default:
          filterMessage = 'Filtro aplicado';
      }

      if (mounted) {
        SnackBarUtils.showNavigation(context, filterMessage);
      }
    }

    _navigateToPage(1); // navegar para lista (índice 1)
  }

  void _onDataChanged() {
    if (!mounted) return;
    _loadInventarios();
    setState(() {});
  }

  void _viewInventarioFromList(Inventario inventario) {
    if (!mounted) return;
    setState(() {
      _selectedInventario = inventario;
      _lastViewSource = 'list';
    });
    _navigateToPage(5); // abrir página de visualização
  }

  void _viewInventarioFromSearch(
    Inventario inventario,
    Map<String, dynamic> searchFilters,
  ) {
    if (!mounted) return;
    setState(() {
      _selectedInventario = inventario;
      _lastViewSource = 'search';
      _lastSearchFilters = searchFilters; // armazena filtros de busca
    });
    _navigateToPage(5); // abrir página de visualização
  }

  void _viewInventarioFromDashboard(Inventario inventario) {
    if (!mounted) return;
    setState(() {
      _selectedInventario = inventario;
      _lastViewSource = 'dashboard';
    });
    _navigateToPage(5); // abrir página de visualização
  }

  void _viewNotaFromDashboard(NotaFiscal nota) {
    if (!mounted) return;
    setState(() {
      _selectedNota = nota;
      _lastViewSource = 'dashboard';
    });
    _navigateToPage(5); // abrir view da NotaFiscal
  }

  void _viewInventarioFromTrash(Inventario inventario) {
    if (!mounted) return;
    setState(() {
      _selectedInventario = inventario;
      _lastViewSource = 'trash';
    });
    _navigateToPage(5); // abrir página de visualização
  }

  void _viewInventarioFromNotaFiscal(Inventario inventario) {
    if (!mounted) return;
    setState(() {
      _selectedInventario = inventario;
      _lastViewSource = 'notaFiscal';
    });
    _navigateToPage(5); // abrir página de visualização
  }

  // Navegação de volta com contexto desde a view
  void _navigateBackFromView() {
    if (!mounted) return;

    // Ao voltar para view de nota fiscal: mantém nota selecionada e limpa só inventario
    if (_lastViewSource == 'notaFiscal') {
      setState(() {
        _selectedInventario = null;
        // Mantém _selectedNota na view da nota fiscal
        _lastViewSource =
            'dashboard'; // Reinicia _lastViewSource ao retornar para nota
      });
      _navigateToPage(5); // mantém na view (exibe nota fiscal)
      return;
    }

    setState(() {
      _selectedInventario = null;
      _selectedNota = null;
    });

    if (_lastViewSource == 'search') {
      // Voltar para busca mantendo filtros
      _navigateToPage(2); // busca
    } else if (_lastViewSource == 'dashboard') {
      // Voltar para dashboard
      _navigateToPage(0); // dashboard
    } else if (_lastViewSource == 'trash') {
      // Voltar para lixeira
      _navigateToPage(3); // lixeira
    } else {
      // Voltar para lista (padrão)
      _navigateToPage(1); // lista
    }
  }

  void _editInventario(Inventario inventario) async {
    if (!mounted) return;

    // Localizar NotaFiscal correspondente
    final helper = DatabaseHelperInventario();
    final notaFiscal = await helper.getNotaFiscalById(inventario.notaFiscalId); // localizar NotaFiscal correspondente

    setState(() {
      _editingInventario = inventario;
      _editingNotaFiscal = notaFiscal;
    });
    _navigateToPage(4); // abrir formulário (índice 4)
  }

  void _createNewInventario() {
    if (!mounted) return;
    setState(() {
      _editingInventario = null; // Limpa estado de edição ao criar novo
      _editingNotaFiscal = null; // Limpa edição da NotaFiscal ao criar novo
    });
    _navigateToPage(4); // abrir formulário (novo item)
  }

  void _addItemsToNotaFiscal(String notaFiscalId) async {
    if (!mounted) return;

    // Procurar NotaFiscal
    final helper = DatabaseHelperInventario();
    final notaFiscal = await helper.getNotaFiscalById(notaFiscalId);

    setState(() {
      _editingInventario = null; // Limpa edição de item único
      _editingNotaFiscal = notaFiscal; // Define NotaFiscal para edição
    });
    _navigateToPage(4); // abrir formulário (adicionar itens)
  }

  // Limpa filtros ao voltar para a lista
  void _navigateToListClear() {
    if (!mounted) return;
    setState(() {
      _listFilters = {}; // limpa filtros existentes
    });
    _navigateToPage(1); // abrir lista
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        // Botão voltar em telas grandes, drawer em telas pequenas
        leading: isLarge
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar ao Início',
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (Route<dynamic> route) =>
                          false, // remover rotas anteriores
                  );
                },
              )
            : null, // usar ícone do drawer no mobile
        title: const Text('Inventário'),
        backgroundColor: const Color(0xFF1E5EA4),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Ações adicionais (opcionais)
          if (isLarge) ...[
            // Ações específicas para desktop (opcionais)
          ] else ...[
            // Ações específicas para mobile (opcionais)
          ],
        ],
      ),

      // Drawer apenas em telas pequenas
      drawer: isLarge
          ? null
          : Drawer(
              child: InventarioSidebar(
                selectedIndex: _selectedIndex,
                onNavigate: _navigateToPage,
              ),
            ),

      body: Row(
        children: [
          // Sidebar fixo apenas em telas grandes
          if (isLarge)
            Container(
              margin: const EdgeInsets.all(10),
              child: InventarioSidebar(
                selectedIndex: _selectedIndex,
                onNavigate: _navigateToPage,
              ),
            ),

          // Área principal de conteúdo
          Expanded(
            child: FocusScope(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDashboardPage(), // Página 0 - Dashboard
                  _buildListPage(), // Página 1 - Lista
                  _buildSearchPage(), // Página 2 - Pesquisar
                  _buildTrashPage(), // Página 3 - Lixeira
                  _buildSmartFormPage(), // Página 4 - Smart Form
                  _buildViewPage(), // Página 5 - View (oculta no sidebar)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return InventarioDashboardWidget(
      notasFiscais: _notasFiscais,
      inventarios: _inventarios,
      onRefresh: _loadInventarios,
      onNavigateToList: _navigateToListClear,
      onNavigateToSearch: () => _navigateToPage(2),
      onNavigateToForm: _createNewInventario,
      onNavigateToListWithFilters: _navigateToListWithFilters,
      onNavigateToView: _viewInventarioFromDashboard,
      onNavigateToNotaView: _viewNotaFromDashboard,
    );
  }

  Widget _buildListPage() {
    return InventarioListPage(
      activeFilters: _listFilters,
      onDataChanged: _onDataChanged,
      onViewInventario: _viewInventarioFromList,
      onEditInventario: _editInventario,
      onCreateNew: _createNewInventario,
    );
  }

  Widget _buildSearchPage() {
    return GenericSearchPage<Inventario>(
      config: InventarioV2SearchConfig(),
      onViewItem: (inventario, searchFilters) {
        _viewInventarioFromSearch(inventario, searchFilters);
      },
      initialSearchQuery: null,
      preservedFilters: _lastViewSource == 'search' ? _lastSearchFilters : null,
    );
  }

  Widget _buildTrashPage() {
    return InventarioTrashPage(
      onItemRestored: _onDataChanged,
      onItemDeleted: _onDataChanged,
      onViewInventario: _viewInventarioFromTrash,
    );
  }

  Widget _buildViewPage() {
    if (_selectedInventario == null && _selectedNota == null) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: Text(
            'Nenhum item selecionado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    // Se estiver vendo um inventario, mostrar a view do inventario (prioridade)
    if (_selectedInventario != null) {
      return InventarioViewPage(
        inventario: _selectedInventario!,
        onBackToList: _navigateBackFromView, // usa método de retorno com contexto
        onEdit: () => _editInventario(_selectedInventario!),
        onAddItemsToNotaFiscal: _lastViewSource != 'trash'
            ? _addItemsToNotaFiscal
            : null,
      );
    }

    // Se estiver vendo uma NotaFiscal, mostrar a view da nota
    return NotaFiscalViewPage(
      notaFiscal: _selectedNota!,
      onBackToList: _navigateBackFromView,
      onAddItemsToNotaFiscal: _addItemsToNotaFiscal,
      onViewItem: _viewInventarioFromNotaFiscal,
    );
  }

  // Página do formulário inteligente
  Widget _buildSmartFormPage() {
    // Verifica se estamos editando a NotaFiscal (adicionar itens) ou um Inventario
    final isEditingNotaFiscal =
        _editingNotaFiscal != null && _editingInventario == null;

    return SmartInventarioFormPage(
      editingNotaFiscalId: _editingNotaFiscal?.id,
      editingItem: _editingInventario,
      isEditingNotaFiscal: isEditingNotaFiscal,
      onItemSaved: () {
        if (mounted) {
          setState(() {
            _editingInventario = null; // Limpa estado de edição após salvar
            _editingNotaFiscal = null; // Limpa edição da NotaFiscal após salvar
          });
          _onDataChanged();
          _navigateToPage(1); // Voltar para lista
        }
      },
      onCancel: () {
        if (mounted) {
          setState(() {
            _editingInventario = null; // Limpa estado de edição ao cancelar
            _editingNotaFiscal = null; // Limpa edição da NotaFiscal ao cancelar
          });
          _navigateToPage(1); // Voltar para lista
        }
      },
    );
  }
}
