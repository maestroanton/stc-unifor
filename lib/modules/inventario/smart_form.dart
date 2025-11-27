// lib/modules/inventario/smart_form.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/design_system.dart';
import '../../core/utilities/shared/object_uppercase.dart';
import '../../core/utilities/shared/responsive.dart';
import '../../core/utilities/date_picker_helper.dart';
import '../../core/visuals/snackbar.dart';
import '../../models/inventario.dart';
import '../../models/nota_fiscal.dart';
import '../../helpers/database_helper_inventario.dart';
import '../../services/user_role.dart';

class InventoryItemData {
  final TextEditingController produtoController;
  final TextEditingController descricaoController;
  final TextEditingController valorController;
  final TextEditingController quantidadeController;
  final TextEditingController numeroDeSerieController;
  final TextEditingController dataDeGarantiaController;
  String? estado;
  String? tipo;
  String? localizacao;

  InventoryItemData({
    String produto = '',
    String descricao = '',
    String valor = '',
    String quantidade = '1',
    String numeroDeSerie = '',
    String dataDeGarantia = '',
    this.estado,
    this.tipo,
    this.localizacao,
  }) : produtoController = TextEditingController(text: produto),
       descricaoController = TextEditingController(text: descricao),
       valorController = TextEditingController(text: valor),
       quantidadeController = TextEditingController(text: quantidade),
       numeroDeSerieController = TextEditingController(text: numeroDeSerie),
       dataDeGarantiaController = TextEditingController(text: dataDeGarantia);

  void dispose() {
    produtoController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    quantidadeController.dispose();
    numeroDeSerieController.dispose();
    dataDeGarantiaController.dispose();
  }

  void updateFromMap(Map<String, dynamic> data) {
    produtoController.text = data['produto']?.toString() ?? '';
    descricaoController.text = data['descricao']?.toString() ?? '';
    valorController.text = data['valor']?.toString() ?? '';
    quantidadeController.text = data['quantidade']?.toString() ?? '1';
    numeroDeSerieController.text = data['numeroDeSerie']?.toString() ?? '';
    dataDeGarantiaController.text = data['dataDeGarantia']?.toString() ?? '';
  }
}

class SmartInventarioFormPage extends StatefulWidget {
  final VoidCallback? onItemSaved;
  final VoidCallback? onCancel;
  final String? editingNotaFiscalId; // NotaFiscal ID para edição
  final Inventario? editingItem; // Inventário único em edição
  final bool
  isEditingNotaFiscal; // true ao editar NotaFiscal para adicionar itens

  const SmartInventarioFormPage({
    super.key,
    this.onItemSaved,
    this.onCancel,
    this.editingNotaFiscalId,
    this.editingItem,
    this.isEditingNotaFiscal = false,
  });

  @override
  State<SmartInventarioFormPage> createState() =>
      _SmartInventarioFormPageState();
}

class _SmartInventarioFormPageState extends State<SmartInventarioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // rolagem para erros

  late final TextEditingController _notaController = TextEditingController();
  late final TextEditingController _dataDeCompraController =
      TextEditingController();
  late final TextEditingController _fornecedorController =
      TextEditingController();
  late final TextEditingController _valorTotalController =
      TextEditingController();
  late final TextEditingController _chaveAcessoController =
      TextEditingController();

  String? _uf;

  final List<InventoryItemData> _items = [];

  bool _isSaving = false;
  bool _isInitializing = true;

  PlatformFile? _notaFiscalFile;
  String? _notaFiscalError; // estado de erro do campo Nota Fiscal
  final GlobalKey _notaFiscalKey =
      GlobalKey(); // key para rolar até campo Nota Fiscal

  final _notaFormatter = MaskTextInputFormatter(
    mask: '###.###.###',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##-##-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final List<String> _estadoOptions = ['Presente', 'Ausente'];
  final List<String> _tipoOptions = [
    'Equipamentos de Escritório',
    'Móveis, Eletrodomésticos e Estrutura',
    'Ferramentas Manuais',
    'Veículos e Transporte',
    'Componentes e Peças',
    'Material de Consumo',
    'Outros',
  ];
  final List<String> _localizacaoOptions = [
    'Diretoria',
    'Cobrança',
    'Despacho',
    'Financeiro',
    'Operacional',
    'Comercial',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // Carrega item em edição, NotaFiscal (se editando) ou dados salvos do form
    if (widget.editingItem != null) {
      _loadEditingItem();
    } else if (widget.isEditingNotaFiscal &&
        widget.editingNotaFiscalId != null) {
      _loadNotaFiscalForEditing();
    } else {
      _loadFormData();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final userRoleService = UserRoleService();
      final currentUf = await userRoleService.getCurrentUserUf();
      if (mounted) {
        setState(() {
          _uf = currentUf;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uf = 'CE'; // valor padrão
          _isInitializing = false;
        });
      }
    }
  }

  // Carrega dados da NotaFiscal para adicionar itens
  Future<void> _loadNotaFiscalForEditing() async {
    if (widget.editingNotaFiscalId == null) {
      return;
    }

    try {
      final dbHelper = DatabaseHelperInventario();
      final notaFiscal = await dbHelper.getNotaFiscalById(
        widget.editingNotaFiscalId!,
      );

      if (notaFiscal == null) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Nota Fiscal não encontrada');
        }
        return;
      }

      setState(() {
        // Carrega dados da NotaFiscal (somente leitura)
        _notaController.text = notaFiscal.numeroNota;
        _dataDeCompraController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(notaFiscal.dataCompra);
        _fornecedorController.text = notaFiscal.fornecedor;
        _valorTotalController.text = notaFiscal.valorTotal.toStringAsFixed(2);
        _chaveAcessoController.text = notaFiscal.chaveAcesso ?? '';
        _uf = notaFiscal.uf;

        // Limpa itens existentes e adiciona um item vazio
        for (final itemData in _items) {
          itemData.dispose();
        }
        _items.clear();
        _items.add(InventoryItemData());
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar Nota Fiscal: $e');
      }
    }
  }

  // Carrega NotaFiscal e Inventário para edição
  Future<void> _loadEditingItem() async {
    if (widget.editingNotaFiscalId == null || widget.editingItem == null) {
      return;
    }

    try {
      final dbHelper = DatabaseHelperInventario();
      final notaFiscal = await dbHelper.getNotaFiscalById(
        widget.editingNotaFiscalId!,
      );

      if (notaFiscal == null) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Nota Fiscal não encontrada');
        }
        return;
      }

      final item = widget.editingItem!;

      setState(() {
        // Carrega dados da NotaFiscal
        _notaController.text = notaFiscal.numeroNota;
        _dataDeCompraController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(notaFiscal.dataCompra);
        _fornecedorController.text = notaFiscal.fornecedor;
        _valorTotalController.text = notaFiscal.valorTotal.toStringAsFixed(2);
        _chaveAcessoController.text = notaFiscal.chaveAcesso ?? '';
        _uf = notaFiscal.uf;

        // Limpa itens existentes
        for (final itemData in _items) {
          itemData.dispose();
        }
        _items.clear();

        // Cria item único com dados em edição
        _items.add(
          InventoryItemData(
            produto: item.produto,
            descricao: item.descricao,
            valor: item.valor.toStringAsFixed(2),
            quantidade: '1', // sempre 1 ao editar item único
            numeroDeSerie: item.numeroDeSerie ?? '',
            dataDeGarantia: item.dataDeGarantia ?? '',
            estado: item.estado,
            tipo: item.tipo,
            localizacao: item.localizacao,
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar item: $e');
      }
    }
  }

  void _addNewItem() {
    setState(() {
      _items.add(InventoryItemData());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  void _duplicateItem(int index) {
    final originalItem = _items[index];
    setState(() {
      _items.insert(
        index + 1,
        InventoryItemData(
          produto: originalItem.produtoController.text,
          descricao: originalItem.descricaoController.text,
          valor: originalItem.valorController.text,
          quantidade: originalItem.quantidadeController.text,
          numeroDeSerie: '',
          dataDeGarantia: originalItem.dataDeGarantiaController.text,
          estado: originalItem.estado,
          tipo: originalItem.tipo,
          localizacao: originalItem.localizacao,
        ),
      );
    });
  }

  // Rola até o primeiro erro do formulário
  void _scrollToFirstError() {
    // Primeiro verifica erro da Nota Fiscal e rola até ele
    if (_notaFiscalError != null && _notaFiscalKey.currentContext != null) {
      // Executar após frame para garantir layout estável (ensureVisible confiável)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          Scrollable.ensureVisible(
            _notaFiscalKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.0, // alinha ao topo da viewport
          );
        } catch (_) {
          // Se ensureVisible falhar, animar ao topo
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    // Caso contrário, validar form e rolar para o primeiro campo inválido
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      // Rola ao topo, onde erros tendem a aparecer
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAllInventarios() async {
    // Limpar erros anteriores
    setState(() {
      _notaFiscalError = null;
    });

    // Validar Nota Fiscal ao criar novos itens (não ao editar)
    bool notaFiscalValid = true;
    if (!widget.isEditingNotaFiscal &&
        widget.editingItem == null &&
        _notaFiscalFile == null) {
      setState(() {
        _notaFiscalError = 'É obrigatório fazer upload da Nota Fiscal';
      });
      notaFiscalValid = false;
    }

    // Validar campos do formulário
    final formIsValid = _formKey.currentState!.validate();

    // Se falhar validação, rolar para erro e abortar
    if (!formIsValid || !notaFiscalValid) {
      _scrollToFirstError();
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Se editando NotaFiscal para adicionar itens
      if (widget.isEditingNotaFiscal && widget.editingNotaFiscalId != null) {
        await _addInventariosToNotaFiscal();
      }
      // Se editando item único, atualizar item e NotaFiscal
      else if (widget.editingItem != null &&
          widget.editingNotaFiscalId != null) {
        await _updateInventarioAndNotaFiscal();
      } else {
        // Caso contrário, criar nova NotaFiscal com itens
        await _createNotaFiscalWithInventarios();
      }
    } catch (e) {
      if (mounted) {
        // Extrair mensagem de erro e apresentar ao usuário
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceAll('Exception:', '').trim();
        }

        // Verificar erro de duplicidade e orientar usuário
        if (errorMessage.contains('Já existe uma Nota Fiscal')) {
          SnackBarUtils.showError(
            context,
            errorMessage,
            duration: const Duration(seconds: 5),
          );
        } else {
          SnackBarUtils.showError(context, 'Erro: $errorMessage');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Adiciona inventários a NotaFiscal existente
  Future<void> _addInventariosToNotaFiscal() async {
    List<String> errors = [];

    // Obter NotaFiscal atual
    final dbHelper = DatabaseHelperInventario();
    final currentNotaFiscal = await dbHelper.getNotaFiscalById(
      widget.editingNotaFiscalId!,
    );
    if (currentNotaFiscal == null) {
      throw Exception('Nota Fiscal não encontrada');
    }

    // Montar lista de inventários a criar
    final inventariosToCreate = <Inventario>[];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      if (item.produtoController.text.trim().isEmpty) {
        errors.add('Item ${i + 1}: Produto é obrigatório');
        continue;
      }

      try {
        final quantidade = int.tryParse(item.quantidadeController.text) ?? 1;
        final valorUnitario =
            double.tryParse(item.valorController.text.replaceAll(',', '.')) ??
            0.0;

        for (int q = 0; q < quantidade; q++) {
          final inventario = Inventario(
            notaFiscalId: widget.editingNotaFiscalId!,
            valor: valorUnitario,
            dataDeGarantia: item.dataDeGarantiaController.text.isEmpty
                ? null
                : item.dataDeGarantiaController.text,
            produto: item.produtoController.text,
            descricao:
                item.descricaoController.text +
                (quantidade > 1 ? ' (${q + 1}/$quantidade)' : ''),
            estado: item.estado ?? 'Presente',
            tipo: item.tipo ?? 'Outros',
            uf: _uf!,
            numeroDeSerie: item.numeroDeSerieController.text.isEmpty
                ? null
                : item.numeroDeSerieController.text +
                      (quantidade > 1 ? '-${q + 1}' : ''),
            localizacao: item.localizacao,
            observacoes: null,
          );

          inventariosToCreate.add(inventario);
        }
      } catch (e) {
        errors.add('Item ${i + 1}: Erro ao preparar - $e');
      }
    }

    // Criar os inventários
    if (inventariosToCreate.isNotEmpty) {
      try {
        for (final inventario in inventariosToCreate) {
          await dbHelper.insertInventario(inventario);
        }
      } catch (e) {
        throw Exception('Erro ao salvar itens: $e');
      }
    }

    if (mounted) {
      if (errors.isNotEmpty) {
        SnackBarUtils.showError(
          context,
          'Alguns itens não foram salvos:\n${errors.join('\n')}',
        );
      } else {
        _clearAllFields();
        widget.onItemSaved?.call();
      }
    }
  }

  // Atualizar inventário e opcionalmente NotaFiscal
  Future<void> _updateInventarioAndNotaFiscal() async {
    final item = _items.first; // apenas um item ao editar

    if (item.produtoController.text.trim().isEmpty) {
      throw Exception('Produto é obrigatório');
    }

    final dbHelper = DatabaseHelperInventario();

    // Obter NotaFiscal atual
    final currentNotaFiscal = await dbHelper.getNotaFiscalById(
      widget.editingNotaFiscalId!,
    );
    if (currentNotaFiscal == null) {
      throw Exception('Nota Fiscal não encontrada');
    }

    String? notaFiscalUrl = currentNotaFiscal.notaFiscalUrl;

    // Fazer upload do novo arquivo, se selecionado
    if (_notaFiscalFile != null) {
      try {
        notaFiscalUrl = await _uploadNotaFiscal(_notaFiscalFile!);
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Erro ao fazer upload da Nota Fiscal: $e',
          );
        }
        rethrow;
      }
    }

    // Converter data de compra
    DateTime dataCompra;
    try {
      dataCompra = DateFormat('dd-MM-yyyy').parse(_dataDeCompraController.text);
    } catch (e) {
      throw Exception('Data de compra inválida');
    }

    // Atualizar NotaFiscal
    final updatedNotaFiscal = NotaFiscal(
      id: widget.editingNotaFiscalId,
      numeroNota: _notaController.text,
      fornecedor: _fornecedorController.text,
      dataCompra: dataCompra,
      valorTotal:
          double.tryParse(_valorTotalController.text.replaceAll(',', '.')) ??
          0.0,
      notaFiscalUrl: notaFiscalUrl,
      chaveAcesso: _chaveAcessoController.text.isEmpty
          ? null
          : _chaveAcessoController.text,
      uf: _uf!,
      createdAt: currentNotaFiscal.createdAt,
      createdBy: currentNotaFiscal.createdBy,
    );

    await dbHelper.updateNotaFiscal(updatedNotaFiscal);

    // Atualizar inventário
    final valorUnitario =
        double.tryParse(item.valorController.text.replaceAll(',', '.')) ?? 0.0;

    final updatedInventario = Inventario(
      id: widget.editingItem!.id,
      internalId: widget.editingItem!.internalId,
      notaFiscalId: widget.editingNotaFiscalId!,
      valor: valorUnitario,
      dataDeGarantia: item.dataDeGarantiaController.text.isEmpty
          ? null
          : item.dataDeGarantiaController.text,
      produto: item.produtoController.text,
      descricao: item.descricaoController.text,
      estado: item.estado!,
      tipo: item.tipo!,
      uf: _uf!,
      numeroDeSerie: item.numeroDeSerieController.text.isEmpty
          ? null
          : item.numeroDeSerieController.text,
      localizacao: item.localizacao,
      observacoes: null,
    );

    await dbHelper.updateInventario(updatedInventario);

    if (mounted) {
      // Snackbar de sucesso removido (por preferência do usuário)
      _clearAllFields();
      widget.onItemSaved?.call();
    }
  }

  // Criar NotaFiscal com múltiplos inventários
  Future<void> _createNotaFiscalWithInventarios() async {
    // savedCount removido; snackbar de sucesso removido (por preferência do usuário)
    List<String> errors = [];

    // Upload do arquivo da Nota Fiscal
    String? notaFiscalUrl;
    if (_notaFiscalFile != null) {
      try {
        notaFiscalUrl = await _uploadNotaFiscal(_notaFiscalFile!);
      } catch (e) {
        throw Exception('Erro ao fazer upload da Nota Fiscal: $e');
      }
    }

    // Converter data de compra
    DateTime dataCompra;
    try {
      dataCompra = DateFormat('dd-MM-yyyy').parse(_dataDeCompraController.text);
    } catch (e) {
      throw Exception('Data de compra inválida');
    }

    // Criar NotaFiscal
    final notaFiscal = NotaFiscal(
      numeroNota: _notaController.text,
      fornecedor: _fornecedorController.text,
      dataCompra: dataCompra,
      valorTotal:
          double.tryParse(_valorTotalController.text.replaceAll(',', '.')) ??
          0.0,
      notaFiscalUrl: notaFiscalUrl,
      chaveAcesso: _chaveAcessoController.text.isEmpty
          ? null
          : _chaveAcessoController.text,
      uf: _uf!,
    );

    // Montar lista de inventários a criar
    final inventariosToCreate = <Inventario>[];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      if (item.produtoController.text.trim().isEmpty) {
        errors.add('Item ${i + 1}: Produto é obrigatório');
        continue;
      }

      try {
        final quantidade = int.tryParse(item.quantidadeController.text) ?? 1;
        final valorUnitario =
            double.tryParse(item.valorController.text.replaceAll(',', '.')) ??
            0.0;

        for (int q = 0; q < quantidade; q++) {
          final inventario = Inventario(
            notaFiscalId: '', // será definido pela criação
            valor: valorUnitario,
            dataDeGarantia: item.dataDeGarantiaController.text.isEmpty
                ? null
                : item.dataDeGarantiaController.text,
            produto: item.produtoController.text,
            descricao:
                item.descricaoController.text +
                (quantidade > 1 ? ' (${q + 1}/$quantidade)' : ''),
            estado: item.estado ?? 'Presente',
            tipo: item.tipo ?? 'Outros',
            uf: _uf!,
            numeroDeSerie: item.numeroDeSerieController.text.isEmpty
                ? null
                : item.numeroDeSerieController.text +
                      (quantidade > 1 ? '-${q + 1}' : ''),
            localizacao: item.localizacao,
            observacoes: null,
          );

          inventariosToCreate.add(inventario);
        }
      } catch (e) {
        errors.add('Item ${i + 1}: Erro ao preparar - $e');
      }
    }

    // Usa operação composta do helper de BD
    if (inventariosToCreate.isNotEmpty) {
      try {
        final dbHelper = DatabaseHelperInventario();
        await dbHelper.createNotaFiscalWithInventarios(
          notaFiscal,
          inventariosToCreate,
        );
      } catch (e) {
        throw Exception('Erro ao salvar itens: $e');
      }
    }

    if (mounted) {
      if (errors.isNotEmpty) {
        SnackBarUtils.showError(
          context,
          'Alguns itens não foram salvos:\n${errors.join('\n')}',
        );
      } else {
        // Snackbar de sucesso removido (por preferência do usuário)
        _clearAllFields();
        widget.onItemSaved?.call();
      }
    }
  }

  void _clearAllFields() {
    setState(() {
      _notaController.clear();
      _dataDeCompraController.clear();
      _fornecedorController.clear();
      _valorTotalController.clear();
      _chaveAcessoController.clear();
      for (final item in _items) {
        item.dispose();
      }
      _items.clear();
      _addNewItem();
      _notaFiscalFile = null;
    });
    _clearSavedFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final nota = prefs.getString('smart_form_nota') ?? '';
      final dataCompra = prefs.getString('smart_form_data_compra') ?? '';
      final fornecedor = prefs.getString('smart_form_fornecedor') ?? '';
      final valorTotal = prefs.getString('smart_form_valor_total') ?? '';
      final chaveAcesso = prefs.getString('smart_form_chave_acesso') ?? '';

      _notaController.text = nota;
      _dataDeCompraController.text = dataCompra;
      _fornecedorController.text = fornecedor;
      _valorTotalController.text = valorTotal;
      _chaveAcessoController.text = chaveAcesso;

      final itemsJson = prefs.getString('smart_form_items');
      if (itemsJson != null && itemsJson.isNotEmpty) {
        final itemsData = jsonDecode(itemsJson) as List<dynamic>;

        for (final item in _items) {
          item.dispose();
        }
        _items.clear();

        for (final itemData in itemsData) {
          final item = InventoryItemData(
            produto: itemData['produto'] ?? '',
            descricao: itemData['descricao'] ?? '',
            valor: itemData['valor'] ?? '',
            quantidade: itemData['quantidade'] ?? '1',
            numeroDeSerie: itemData['numeroSerie'] ?? '',
            dataDeGarantia: itemData['dataGarantia'] ?? '',
          );
          item.estado = itemData['estado'];
          item.tipo = itemData['tipo'];
          item.localizacao = itemData['localizacao'];
          _items.add(item);
        }

        if (_items.isEmpty) {
          _addNewItem();
        }
      }
    } catch (e) {
      /* Ignore */
    }

    if (_items.isEmpty) {
      _addNewItem();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearSavedFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smart_form_nota');
      await prefs.remove('smart_form_data_compra');
      await prefs.remove('smart_form_fornecedor');
      await prefs.remove('smart_form_valor_total');
      await prefs.remove('smart_form_chave_acesso');
      await prefs.remove('smart_form_custom_prompt');
      await prefs.remove('smart_form_items');
      await prefs.remove('smart_form_show_custom_prompt');
      await prefs.remove('smart_form_image_path');
    } catch (e) {
      // sem ação
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  String? requiredField(String? value, {int? min}) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    if (min != null && value.length < min) return 'Mínimo $min caracteres';
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose(); // liberar controlador de rolagem
    _notaController.dispose();
    _dataDeCompraController.dispose();
    _fornecedorController.dispose();
    _valorTotalController.dispose();
    _chaveAcessoController.dispose();

    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        color: AppDesignSystem.background,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        AppDesignSystem.pageHeader(
          icon: widget.editingItem != null
              ? Icons.edit_outlined
              : (widget.isEditingNotaFiscal
                    ? Icons.add_circle_outline
                    : Icons.auto_awesome_outlined),
          title: widget.editingItem != null
              ? 'Editar Item'
              : (widget.isEditingNotaFiscal
                    ? 'Adicionar Itens à Nota Fiscal'
                    : 'Novo Item'),
        ),

        Expanded(
          child: Container(
            color: AppDesignSystem.background,
            constraints: BoxConstraints(
              maxWidth: Responsive.valueDetailed(
                context,
                mobile: double.infinity,
                smallTablet: 800,
                tablet: 1000,
                desktop: 1000,
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController, // controller de rolagem
              padding: Responsive.padding(context),
              child: Container(
                decoration: AppDesignSystem.cardDecoration,
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.valueDetailed(
                      context,
                      mobile: AppDesignSystem.spacing16,
                      smallTablet: AppDesignSystem.spacing20,
                      tablet: AppDesignSystem.spacing24,
                      desktop: AppDesignSystem.spacing24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do card
                      Text(
                        'ALTERAR ITENS',
                        style: TextStyle(
                          fontSize: Responsive.valueDetailed(
                            context,
                            mobile: 9,
                            smallTablet: 10,
                            tablet: 10,
                            desktop: 10,
                          ),
                          fontWeight: FontWeight.w600,
                          color: AppDesignSystem.neutral500,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: Responsive.largeSpacing(context)),

                      // Seções principais - layout responsivo
                      // Oculta seção de imagem AI ao editar ou adicionar à NotaFiscal
                      if (widget.editingItem == null &&
                          !widget.isEditingNotaFiscal) ...[
                        if (Responsive.isSmallScreen(context))
                          // Celular: empilhar seções verticalmente - ordem 0,1
                          Column(
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(0.0),
                                child: FocusTraversalGroup(
                                  child: _buildImageSection(),
                                ),
                              ),
                              SizedBox(height: Responsive.spacing(context)),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1.0),
                                child: FocusTraversalGroup(
                                  child: _buildInvoiceInfoSection(),
                                ),
                              ),
                            ],
                          )
                        else
                          // Desktop: layout lado a lado; navegação: imagem -> nota
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(0.0),
                                  child: FocusTraversalGroup(
                                    child: _buildImageSection(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.valueDetailed(
                                  context,
                                  mobile: AppDesignSystem.spacing16,
                                  tablet: AppDesignSystem.spacing32,
                                  desktop: AppDesignSystem.spacing40,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.0),
                                  child: FocusTraversalGroup(
                                    child: _buildInvoiceInfoSection(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ] else
                        // Ao editar, mostrar primeiro a informação da nota (ordem 0)
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(0.0),
                          child: FocusTraversalGroup(
                            child: _buildInvoiceInfoSection(),
                          ),
                        ),

                      SizedBox(height: Responsive.largeSpacing(context) * 1.5),

                      // Seção de itens vem após informações da nota
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2.0),
                        child: FocusTraversalGroup(child: _buildItemsSection()),
                      ),

                      SizedBox(height: Responsive.largeSpacing(context) * 1.5),
                      // Botões de ação por último na navegação
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3.0),
                        child: FocusTraversalGroup(
                          child: _buildActionButtons(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isEditingSingleItem = widget.editingItem != null;
    final isAddingToNotaFiscal = widget.isEditingNotaFiscal;

    String buttonText;
    if (_isSaving) {
      if (isEditingSingleItem) {
        buttonText = 'Atualizando...';
      } else if (isAddingToNotaFiscal) {
        buttonText = 'Adicionando...';
      } else {
        buttonText = 'Salvando...';
      }
    } else {
      if (isEditingSingleItem) {
        buttonText = 'Atualizar Item';
      } else if (isAddingToNotaFiscal) {
        buttonText =
            'Adicionar ${_items.length} Item${_items.length == 1 ? '' : 's'}';
      } else {
        buttonText =
            'Salvar ${_items.length} Item${_items.length == 1 ? '' : 's'}';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _isSaving ? null : widget.onCancel,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancelar'),
          style: AppDesignSystem.secondaryButton,
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAllInventarios,
          icon: _isSaving
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
              : Icon(
                  isEditingSingleItem
                      ? Icons.check_outlined
                      : (isAddingToNotaFiscal
                            ? Icons.add_outlined
                            : Icons.save_outlined),
                  size: 18,
                ),
          label: Text(buttonText),
          style: AppDesignSystem.primaryButton,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final isEditingSingleItem = widget.editingItem != null;
    final isAddingToNotaFiscal = widget.isEditingNotaFiscal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          (isEditingSingleItem || isAddingToNotaFiscal)
              ? 'Nota Fiscal (Opcional)'
              : 'Nota Fiscal',
        ),

        const SizedBox(height: AppDesignSystem.spacing12),

        _buildFormFieldWrapper(
          label: 'Nota Fiscal',
          isRequired:
              !isEditingSingleItem &&
              !isAddingToNotaFiscal, // obrigatório só ao criar novo
          child: _buildFilePickerField(),
        ),

        const SizedBox(height: AppDesignSystem.spacing12),

        _buildFormFieldWrapper(
          label: 'Número da nota',
          isRequired: true,
          child: TextFormField(
            controller: _notaController,
            readOnly: widget.isEditingNotaFiscal,
            keyboardType: TextInputType.number,
            inputFormatters: [_notaFormatter],
            decoration:
                AppDesignSystem.inputDecoration(
                  hint: '000.000.000',
                  suffixIcon: widget.isEditingNotaFiscal
                      ? const Icon(Icons.lock_outline)
                      : null,
                ).copyWith(
                  filled: widget.isEditingNotaFiscal,
                  fillColor: widget.isEditingNotaFiscal
                      ? AppDesignSystem.neutral50
                      : null,
                ),
            style: widget.isEditingNotaFiscal
                ? AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.neutral600,
                  )
                : null,
            validator: (value) {
              final basic = requiredField(value);
              if (basic != null) return basic;
              if (!RegExp(r'^\d{3}\.\d{3}\.\d{3}').hasMatch(value!)) {
                return 'Formato inválido. Use 000.000.000';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: AppDesignSystem.spacing12),

        _buildFormFieldWrapper(
          label: 'Chave de Acesso',
          child: TextFormField(
            controller: _chaveAcessoController,
            readOnly: widget.isEditingNotaFiscal,
            keyboardType: TextInputType.number,
            maxLength: 44,
            decoration:
                AppDesignSystem.inputDecoration(
                  hint: 'Chave de acesso NFe (44 dígitos)',
                  suffixIcon: widget.isEditingNotaFiscal
                      ? const Icon(Icons.lock_outline)
                      : null,
                ).copyWith(
                  filled: widget.isEditingNotaFiscal,
                  fillColor: widget.isEditingNotaFiscal
                      ? AppDesignSystem.neutral50
                      : null,
                ),
            style: widget.isEditingNotaFiscal
                ? AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.neutral600,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informações da Nota'),

        const SizedBox(height: AppDesignSystem.spacing12),

        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormFieldWrapper(
                label: 'Fornecedor',
                isRequired: true,
                child: TextFormField(
                  controller: _fornecedorController,
                  readOnly: widget.isEditingNotaFiscal,
                  decoration:
                      AppDesignSystem.inputDecoration(
                        hint: 'Nome do fornecedor',
                        suffixIcon: widget.isEditingNotaFiscal
                            ? const Icon(Icons.lock_outline)
                            : null,
                      ).copyWith(
                        filled: widget.isEditingNotaFiscal,
                        fillColor: widget.isEditingNotaFiscal
                            ? AppDesignSystem.neutral50
                            : null,
                      ),
                  style: widget.isEditingNotaFiscal
                      ? AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral600,
                        )
                      : null,
                  validator: (value) => requiredField(value),
                ),
              ),

              const SizedBox(height: AppDesignSystem.spacing12),

              _buildFormFieldWrapper(
                label: 'Valor Total',
                child: TextFormField(
                  controller: _valorTotalController,
                  readOnly: widget.isEditingNotaFiscal,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      AppDesignSystem.inputDecoration(
                        hint: '0.00',
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          size: 18,
                        ),
                        suffixIcon: widget.isEditingNotaFiscal
                            ? const Icon(Icons.lock_outline)
                            : null,
                      ).copyWith(
                        filled: widget.isEditingNotaFiscal,
                        fillColor: widget.isEditingNotaFiscal
                            ? AppDesignSystem.neutral50
                            : null,
                      ),
                  style: widget.isEditingNotaFiscal
                      ? AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral600,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: AppDesignSystem.spacing12),

              Row(
                children: [
                  Expanded(
                    child: _buildFormFieldWrapper(
                      label: 'Data de compra',
                      isRequired: true,
                      child: TextFormField(
                        controller: _dataDeCompraController,
                        readOnly: widget.isEditingNotaFiscal,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_dateFormatter],
                        decoration: AppDesignSystem.inputDecoration(
                          hint: 'dd-mm-aaaa',
                          suffixIcon: widget.isEditingNotaFiscal
                              ? const Icon(Icons.lock_outline)
                              : IconButton(
                                  icon: const Icon(Icons.date_range),
                                  onPressed: () => _selectDate(
                                    context,
                                    _dataDeCompraController,
                                  ),
                                ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          try {
                            DateFormat('dd-MM-yyyy').parseStrict(value);
                          } catch (_) {
                            return 'Formato inválido. Use dd-MM-aaaa';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Expanded(
                    child: _buildFormFieldWrapper(
                      label: 'UF',
                      child: TextFormField(
                        initialValue: _uf ?? 'CE',
                        readOnly: true,
                        decoration:
                            AppDesignSystem.inputDecoration(
                              hint: 'Estado',
                              suffixIcon: const Icon(Icons.lock_outline),
                            ).copyWith(
                              fillColor: AppDesignSystem.neutral100,
                              filled: true,
                            ),
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    final isEditingSingleItem = widget.editingItem != null;
    final isAddingToNotaFiscal = widget.isEditingNotaFiscal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              isEditingSingleItem
                  ? 'Detalhes do Item'
                  : (isAddingToNotaFiscal
                        ? 'Novos Itens para Adicionar (${_items.length})'
                        : 'Itens do Inventário (${_items.length})'),
            ),
            // Ocultar botão "Adicionar item" ao editar item único
            if (!isEditingSingleItem)
              ElevatedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.success,
                  foregroundColor: AppDesignSystem.surface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing12,
                    vertical: AppDesignSystem.spacing8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusS,
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppDesignSystem.spacing16),

        ...List.generate(_items.length, (index) => _buildItemCard(index)),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing16),
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: AppDesignSystem.neutral200),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        color: AppDesignSystem.neutral50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primary,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusXS,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing8),
                  Text(
                    'Item ${index + 1}',
                    style: AppDesignSystem.h3.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Ocultar duplicar/remover ao editar item único
              if (widget.editingItem == null)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _duplicateItem(index),
                      icon: const Icon(Icons.plagiarism_outlined, size: 16),
                      tooltip: 'Duplicar item',
                      style: IconButton.styleFrom(
                        backgroundColor: AppDesignSystem.neutral200.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppDesignSystem.neutral400,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing8),
                    IconButton(
                      onPressed: _items.length > 1
                          ? () => _removeItem(index)
                          : null,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      tooltip: 'Remover item',
                      style: IconButton.styleFrom(
                        backgroundColor: _items.length > 1
                            ? AppDesignSystem.error.withValues(alpha: 0.1)
                            : AppDesignSystem.neutral200,
                        foregroundColor: _items.length > 1
                            ? AppDesignSystem.error
                            : AppDesignSystem.neutral400,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppDesignSystem.spacing16),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildFormFieldWrapper(
                  label: 'Produto',
                  isRequired: true,
                  child: TextFormField(
                    controller: item.produtoController,
                    decoration: AppDesignSystem.inputDecoration(
                      hint: 'Nome do produto',
                    ),
                    validator: (value) => requiredField(value),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Expanded(
                flex: 2,
                child: _buildFormFieldWrapper(
                  label: 'Nº Série',
                  child: TextFormField(
                    controller: item.numeroDeSerieController,
                    decoration: AppDesignSystem.inputDecoration(hint: 'Série'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      UpperCaseTextFormatter(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDesignSystem.spacing12),

          _buildFormFieldWrapper(
            label: 'Descrição',
            isRequired: true,
            child: TextFormField(
              controller: item.descricaoController,
              maxLines: 2,
              decoration: AppDesignSystem.inputDecoration(
                hint: 'Descrição do produto',
              ),
              validator: (value) => requiredField(value),
            ),
          ),

          const SizedBox(height: AppDesignSystem.spacing12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFormFieldWrapper(
                  label: 'Valor',
                  isRequired: true,
                  child: TextFormField(
                    controller: item.valorController,
                    keyboardType: TextInputType.number,
                    decoration: AppDesignSystem.inputDecoration(
                      hint: '0.00',
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                    ),
                    validator: (value) {
                      final basic = requiredField(value);
                      if (basic != null) return basic;
                      final doubleVal = double.tryParse(
                        value!.replaceAll(',', '.'),
                      );
                      if (doubleVal == null) return 'Valor inválido';
                      if (doubleVal <= 0) return 'Deve ser > 0';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              // Mostrar campo quantidade apenas se não estiver editando item único
              if (widget.editingItem == null) ...[
                Expanded(
                  flex: 1,
                  child: _buildFormFieldWrapper(
                    label: 'Quantidade',
                    isRequired: true,
                    child: TextFormField(
                      controller: item.quantidadeController,
                      keyboardType: TextInputType.number,
                      decoration: AppDesignSystem.inputDecoration(hint: '1'),
                      validator: (value) {
                        final basic = requiredField(value);
                        if (basic != null) return basic;
                        final intVal = int.tryParse(value!);
                        if (intVal == null) return 'Inválido';
                        if (intVal <= 0) return 'Deve ser > 0';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
              ],
              Expanded(
                flex: 2,
                child: _buildFormFieldWrapper(
                  label: 'Estado',
                  isRequired: true,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      value: item.estado,
                      isExpanded: true,
                      hint: Text(
                        'Selecione',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral400,
                        ),
                      ),
                      items: _estadoOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: AppDesignSystem.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => item.estado = value),
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
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppDesignSystem.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDesignSystem.spacing12),

          Row(
            children: [
              Expanded(
                child: _buildFormFieldWrapper(
                  label: 'Tipo',
                  isRequired: true,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      value: item.tipo,
                      isExpanded: true,
                      hint: Text(
                        'Selecione o tipo',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral400,
                        ),
                      ),
                      items: _tipoOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: AppDesignSystem.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => item.tipo = value),
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
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppDesignSystem.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Expanded(
                child: _buildFormFieldWrapper(
                  label: 'Localização',
                  isRequired: true,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      value: item.localizacao,
                      isExpanded: true,
                      hint: Text(
                        'Selecione a localização',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral400,
                        ),
                      ),
                      items: _localizacaoOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: AppDesignSystem.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => item.localizacao = value),
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
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppDesignSystem.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDesignSystem.spacing12),

          _buildFormFieldWrapper(
            label: 'Data de garantia (opcional)',
            child: TextFormField(
              controller: item.dataDeGarantiaController,
              keyboardType: TextInputType.number,
              inputFormatters: [_dateFormatter],
              decoration: AppDesignSystem.inputDecoration(
                hint: 'dd-mm-aaaa',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range, size: 18),
                  onPressed: () =>
                      _selectDate(context, item.dataDeGarantiaController),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  try {
                    DateFormat('dd-MM-yyyy').parseStrict(value);
                  } catch (_) {
                    return 'Data inválida. Use dd-MM-aaaa';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppDesignSystem.primary,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusXS),
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Text(
          title,
          style: AppDesignSystem.h3.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerField() {
    final isEditingSingleItem = widget.editingItem != null;
    final isAddingToNotaFiscal = widget.isEditingNotaFiscal;
    // Ao editar, verificar se NotaFiscal pai possui arquivo
    // Por ora, assume-se que arquivos podem ser atualizados na edição
    final hasExistingFile =
        (isEditingSingleItem || isAddingToNotaFiscal) &&
        widget.editingNotaFiscalId != null;
    final hasError = _notaFiscalError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar arquivo selecionado em container de sucesso
        if (_notaFiscalFile != null) ...[
          Container(
            key: _notaFiscalKey,
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: AppDesignSystem.success.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(
                color: AppDesignSystem.success.withAlpha(77),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.success.withAlpha(51),
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusS,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppDesignSystem.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arquivo selecionado',
                        style: AppDesignSystem.labelSmall.copyWith(
                          color: AppDesignSystem.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _notaFiscalFile!.name,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.neutral900,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(_notaFiscalFile!.size),
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: AppDesignSystem.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _removeFile,
                  color: AppDesignSystem.neutral500,
                  tooltip: 'Remover arquivo',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
        ],

        // Área do seletor de arquivo
        InkWell(
          key: _notaFiscalFile == null ? _notaFiscalKey : null,
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError
                    ? AppDesignSystem.error
                    : (_notaFiscalFile != null || hasExistingFile
                          ? AppDesignSystem.success.withAlpha(128)
                          : AppDesignSystem.neutral300),
                width: hasError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              color: AppDesignSystem.surface,
            ),
            child: Row(
              children: [
                Icon(
                  _notaFiscalFile != null || hasExistingFile
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  color: hasError
                      ? AppDesignSystem.error
                      : (_notaFiscalFile != null || hasExistingFile
                            ? AppDesignSystem.success
                            : AppDesignSystem.neutral600),
                  size: 24,
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _notaFiscalFile != null
                            ? 'Clique para substituir arquivo'
                            : hasExistingFile
                            ? 'Arquivo já enviado (clique para substituir)'
                            : (isEditingSingleItem || isAddingToNotaFiscal)
                            ? 'Clique para adicionar novo arquivo (opcional)'
                            : 'Clique para selecionar arquivo (obrigatório)',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: _notaFiscalFile != null || hasExistingFile
                              ? AppDesignSystem.neutral900
                              : AppDesignSystem.neutral600,
                          fontWeight: _notaFiscalFile != null || hasExistingFile
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (_notaFiscalFile == null && hasExistingFile) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Nota fiscal existente',
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Mostrar texto de erro abaixo do campo
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            _notaFiscalError!,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<String> _uploadNotaFiscal(PlatformFile file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'notas_fiscais/${_notaController.text}/$fileName',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Arquivo não contém dados (bytes nulos)');
        }
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(
            contentType: _getContentType(file.name),
            customMetadata: {
              'originalName': file.name,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        if (file.path == null) {
          throw Exception('Caminho do arquivo não disponível');
        }
        final fileToUpload = File(file.path!);
        if (!await fileToUpload.exists()) {
          throw Exception('Arquivo não encontrado no caminho especificado');
        }
        uploadTask = storageRef.putFile(
          fileToUpload,
          SettableMetadata(
            contentType: _getContentType(file.name),
            customMetadata: {
              'originalName': file.name,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        const maxSizeBytes = 10 * 1024 * 1024;
        if (file.size > maxSizeBytes) {
          if (mounted) {
            SnackBarUtils.showWarning(
              context,
              'Arquivo muito grande (máximo 10MB)',
            );
          }
          return;
        }

        setState(() {
          _notaFiscalFile = file;
          _notaFiscalError = null; // limpar erro ao selecionar arquivo
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao selecionar arquivo: ${e.toString()}',
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _notaFiscalFile = null;
      _notaFiscalError = null; // limpar erro ao remover arquivo
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildFormFieldWrapper({
    required String label,
    bool isRequired = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppDesignSystem.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.neutral700,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: AppDesignSystem.labelMedium.copyWith(
                  color: AppDesignSystem.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
