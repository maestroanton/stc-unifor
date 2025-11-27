// Página genérica de formulários
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import '../../design_system.dart';
import '../../visuals/snackbar.dart'; // Sistema de snackbar
import '../shared/responsive.dart';
import '../date_picker_helper.dart';

/// Configuração que define como o formulário funciona para cada modelo
abstract class FormConfig<T> {
  // Configuração da página
  String get pageTitle;
  IconData get pageIcon;
  String get submitButtonText;
  String get cancelButtonText;

  // Configuração do formulário
  List<FormSectionConfig> get formSections;

  // Operações de dados
  T? get initialData; // Para editar itens existentes
  Future<void> saveItem(T item);
  Future<T> buildItemFromForm(Map<String, dynamic> formData);

  // Manipulação de arquivos - obtém arquivos enviados pelo formulário
  Map<String, PlatformFile?> getFileData(Map<String, dynamic> formData) => {};

  // Validação
  String? validateForm(Map<String, dynamic> formData);

  // Métodos específicos do formulário
  void onFormFieldChanged(
    String fieldKey,
    dynamic value,
    Map<String, dynamic> formData,
  ) {}
  Widget? buildCustomField(
    FormFieldConfig field,
    Map<String, dynamic> formData,
  ) => null;

  // Inicialização
  Future<void> initializeForm(Map<String, dynamic> formData) async {}
}

/// Define uma seção do formulário (ex.: "Informações Básicas", "Detalhes")
class FormSectionConfig {
  final String title;
  final List<FormFieldConfig> fields;
  final bool isLeftColumn; // Para layout com duas colunas

  const FormSectionConfig({
    required this.title,
    required this.fields,
    this.isLeftColumn = true,
  });
}

/// Define a configuração de um campo do formulário
class FormFieldConfig {
  final String key;
  final String label;
  final FormFieldType type;
  final String? hint;
  final bool isRequired;
  final List<String>? options; // Para dropdowns
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final String? initialValue;
  final int? maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onTap; // Para campos só-leitura com ação customizada
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final double? flex; // Para layouts em linha
  final bool isDateField; // Tratamento especial para datas
  final bool isCurrencyField; // Tratamento especial para moeda
  final bool isReadOnly; // Para campos apenas leitura
  final List<String>? allowedExtensions; // Para uploads de arquivo
  final int? maxFileSizeMB; // Tamanho máximo do arquivo em MB

  const FormFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.isRequired = false,
    this.options,
    this.formatters,
    this.keyboardType,
    this.initialValue,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.flex = 1,
    this.isDateField = false,
    this.isCurrencyField = false,
    this.isReadOnly = false,
    this.allowedExtensions,
    this.maxFileSizeMB = 10,
  });
}

enum FormFieldType {
  text,
  number,
  dropdown,
  date,
  multiline,
  currency,
  row, // Para campos lado a lado
  custom, // Para campos totalmente customizados
  file, // Para uploads de arquivo (imagens, PDFs, etc.)
}

/// Página genérica de formulário que funciona com qualquer tipo T
class GenericFormPage<T> extends StatefulWidget {
  final FormConfig<T> config;
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  final T? editingItem;

  const GenericFormPage({
    super.key,
    required this.config,
    required this.onSaved,
    required this.onCancel,
    this.editingItem,
  });

  @override
  State<GenericFormPage<T>> createState() => _GenericFormPageState<T>();
}

class _GenericFormPageState<T> extends State<GenericFormPage<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, dynamic> _formData = {};
  final Map<String, PlatformFile?> _fileData = {}; // Para uploads de arquivo

  bool _isSaving = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    // Inicializa todos os controllers e valores
    for (final section in widget.config.formSections) {
      for (final field in section.fields) {
        if (field.type == FormFieldType.row) {
          // Trata campos em linha separadamente — contêm subcampos
          continue;
        }

        if (field.type == FormFieldType.dropdown) {
          _dropdownValues[field.key] = field.initialValue;
          _formData[field.key] = field.initialValue;
        } else {
          _controllers[field.key] = TextEditingController(
            text: field.initialValue ?? '',
          );
          _formData[field.key] = field.initialValue ?? '';
        }
      }
    }

    // Adiciona listeners a todos os controllers
    for (final entry in _controllers.entries) {
      entry.value.addListener(() {
        _formData[entry.key] = entry.value.text;
        widget.config.onFormFieldChanged(
          entry.key,
          entry.value.text,
          _formData,
        );
      });
    }

    // Permite que a config faça inicialização customizada
    await widget.config.initializeForm(_formData);

    // Atualiza valores de dropdown a partir do formData após inicialização
    // Garante que valores setados em initializeForm (ex.: UF) reflitam na UI
    for (final entry in _formData.entries) {
      if (_dropdownValues.containsKey(entry.key)) {
        _dropdownValues[entry.key] = entry.value as String?;
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();

    for (final controller in _controllers.values) {
      controller.clear();
    }

    setState(() {
      _dropdownValues.clear();
      _formData.clear();
    });

    // Re-inicializa com valores padrão
    _initializeForm();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      // Usa o sistema SnackBarUtils
      SnackBarUtils.showError(context, 'Preencha todos os campos obrigatórios');
      return;
    }

    // Validação personalizada
    final validationError = widget.config.validateForm(_formData);
    if (validationError != null) {
      // Usa o sistema SnackBarUtils
      SnackBarUtils.showError(context, validationError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Adiciona dados de arquivo ao formData para configs que precisam
      _formData['_fileData'] = _fileData;

      final item = await widget.config.buildItemFromForm(_formData);
      await widget.config.saveItem(item);

      if (mounted) {
        // Usa o sistema SnackBarUtils
        SnackBarUtils.showSuccess(
          context,
          widget.editingItem != null
              ? '${widget.config.pageTitle} atualizado com sucesso!'
              : '${widget.config.pageTitle} criado com sucesso!',
        );

        _clearForm();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        // Usa o sistema SnackBarUtils
        SnackBarUtils.showError(context, 'Erro ao salvar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String fieldKey) async {
    // Analisa data atual, se houver
    DateTime? initialDate;
    final currentText = _controllers[fieldKey]?.text ?? '';
    if (currentText.isNotEmpty) {
      try {
        final parts = currentText.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          initialDate = DateTime(year, month, day);
        }
      } catch (e) {
        // Se parsing falhar, usa data atual
      }
    }

    final DateTime? picked = await DatePickerHelper.showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formattedDate =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      _controllers[fieldKey]?.text = formattedDate;
      _formData[fieldKey] = formattedDate;
      widget.config.onFormFieldChanged(fieldKey, formattedDate, _formData);
    }
  }

  /// Cria uma lista ordenada de campos para navegação por tab
  Map<String, int> _getFieldTabOrder() {
    final Map<String, int> tabOrderMap = {};
    int currentOrder = 1;

    // Primeiro, adicione todos os campos das seções da coluna esquerda (Documento & Produto)
    final leftSections = widget.config.formSections
        .where((s) => s.isLeftColumn)
        .toList();

    for (final section in leftSections) {
      for (final field in section.fields) {
        if (field.type != FormFieldType.row) {
          tabOrderMap[field.key] = currentOrder++;
        }
      }
    }

    // Em seguida, adicione todos os campos das seções da coluna direita (Detalhes da Avaria)
    final rightSections = widget.config.formSections
        .where((s) => !s.isLeftColumn)
        .toList();

    for (final section in rightSections) {
      for (final field in section.fields) {
        if (field.type != FormFieldType.row) {
          tabOrderMap[field.key] = currentOrder++;
        }
      }
    }

    return tabOrderMap;
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
        // Barra superior
        AppDesignSystem.pageHeader(
          icon: widget.editingItem == null
              ? Icons.add_outlined
              : Icons.edit_outlined,
          title: widget.editingItem == null ? 'Novo Item' : 'Editar Item',
        ),

        // Conteúdo principal do formulário
        Expanded(
          child: Container(
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
              padding: Responsive.padding(context),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Form(
                  key: _formKey,
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
                          // Título do cartão
                          Text(
                            widget.editingItem == null
                                ? 'NOVO ITEM '
                                : 'EDITAR ITEM',
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
                          // Conteúdo do formulário (layout responsivo)
                          Responsive.isSmallScreen(context)
                              ? _buildSingleColumnLayout()
                              : _buildTwoColumnLayout(),

                          SizedBox(
                            height: Responsive.largeSpacing(context) * 1.5,
                          ),

                          // Botões de ação
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    List<Widget> allFields = [];
    final tabOrderMap = _getFieldTabOrder();

    for (final section in widget.config.formSections) {
      // Cabeçalho da seção
      allFields.add(_buildSectionHeader(section.title));
      allFields.add(SizedBox(height: Responsive.spacing(context)));

      // Campos da seção
      for (int i = 0; i < section.fields.length; i++) {
        final field = section.fields[i];

        // Tratamento especial para mobile — alguns campos ficam em linha
        if (i + 1 < section.fields.length) {
          final nextField = section.fields[i + 1];

          bool shouldMakeRow = false;

          // Emparelhamentos de linhas do Inventário - mantenha valor+uf juntos, mas datas podem ser empilhadas
          if (field.key == 'valor' && nextField.key == 'uf') {
            shouldMakeRow = true;
          }

          // Para datas de Inventário, empilha no mobile para melhor UX
          if (field.key == 'dataDeCompra' &&
              nextField.key == 'dataDeGarantia') {
            if (Responsive.isMobile(context)) {
              // Empilhe verticalmente no mobile
              allFields.add(
                _buildFormFieldWithTabOrder(field, tabOrderMap[field.key] ?? 1),
              );
              allFields.add(SizedBox(height: Responsive.spacing(context)));
              allFields.add(
                _buildFormFieldWithTabOrder(
                  nextField,
                  tabOrderMap[nextField.key] ?? 1,
                ),
              );
              i++; // Pula o próximo campo
              if (i < section.fields.length - 1) {
                allFields.add(SizedBox(height: Responsive.spacing(context)));
              }
              continue;
            } else {
              // Lado a lado em telas maiores
              shouldMakeRow = true;
            }
          }

          // Emparelhamentos de linhas da Avaria - mantenha todas as linhas juntas mesmo no mobile
          if ((field.key == 'manifesto' && nextField.key == 'nota') ||
              (field.key == 'produto' && nextField.key == 'utilidade') ||
              (field.key == 'tipo' && nextField.key == 'uf') ||
              (field.key == 'remetente' && nextField.key == 'destinatario') ||
              (field.key == 'valorTotal' && nextField.key == 'pesoTotal') ||
              (field.key == 'estado' && nextField.key == 'localDeAvaria') ||
              (field.key == 'valorAvaria' &&
                  nextField.key == 'valorUnitario') ||
              (field.key == 'pesoAvaria' &&
                  nextField.key == 'unidadesAvariadas') ||
              (field.key == 'conferente' && nextField.key == 'tratador') ||
              (field.key == 'meioDeContato' && nextField.key == 'contato')) {
            shouldMakeRow = true;
          }

          if (shouldMakeRow) {
            allFields.add(
              _buildFieldRowWithTabOrder([field, nextField], tabOrderMap),
            );
            i++; // Pula o próximo campo
            if (i < section.fields.length - 1) {
              allFields.add(SizedBox(height: Responsive.spacing(context)));
            }
            continue;
          }
        }

        // Campo único padrão
        allFields.add(
          _buildFormFieldWithTabOrder(field, tabOrderMap[field.key] ?? 1),
        );
        if (i < section.fields.length - 1) {
          allFields.add(SizedBox(height: Responsive.spacing(context)));
        }
      }

      // Adiciona espaçamento entre seções
      allFields.add(SizedBox(height: Responsive.largeSpacing(context)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allFields,
    );
  }

  Widget _buildTwoColumnLayout() {
    // Divide seções em colunas esquerda e direita
    final leftSections = widget.config.formSections
        .where((s) => s.isLeftColumn)
        .toList();
    final rightSections = widget.config.formSections
        .where((s) => !s.isLeftColumn)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna esquerda
        Expanded(
          child: _buildColumnWithTabOrder(leftSections, isLeftColumn: true),
        ),

        SizedBox(
          width: Responsive.valueDetailed(
            context,
            mobile: AppDesignSystem.spacing16,
            tablet: AppDesignSystem.spacing32,
            desktop: AppDesignSystem.spacing40,
          ),
        ),

        // Coluna direita
        Expanded(
          child: _buildColumnWithTabOrder(rightSections, isLeftColumn: false),
        ),
      ],
    );
  }

  Widget _buildColumnWithTabOrder(
    List<FormSectionConfig> sections, {
    required bool isLeftColumn,
  }) {
    List<Widget> columnWidgets = [];
    final tabOrderMap = _getFieldTabOrder();

    for (final section in sections) {
      // Cabeçalho da seção
      columnWidgets.add(_buildSectionHeader(section.title));

      // Campos da seção
      for (int i = 0; i < section.fields.length; i++) {
        final field = section.fields[i];

        // Verifica se este campo deve estar em layout em linha
        if (i + 1 < section.fields.length) {
          final nextField = section.fields[i + 1];

          // Define emparelhamentos de campos em linha para formulários distintos
          bool shouldMakeRow = false;

          // Emparelhamentos de linhas do Inventário
          if ((field.key == 'valor' && nextField.key == 'uf') ||
              (field.key == 'dataDeCompra' &&
                  nextField.key == 'dataDeGarantia')) {
            shouldMakeRow = true;
          }

          // Emparelhamentos de linhas da Avaria
          if ((field.key == 'manifesto' && nextField.key == 'nota') ||
              (field.key == 'produto' && nextField.key == 'utilidade') ||
              (field.key == 'tipo' && nextField.key == 'uf') ||
              (field.key == 'remetente' && nextField.key == 'destinatario') ||
              (field.key == 'valorTotal' && nextField.key == 'pesoTotal') ||
              (field.key == 'estado' && nextField.key == 'localDeAvaria') ||
              (field.key == 'valorAvaria' &&
                  nextField.key == 'valorUnitario') ||
              (field.key == 'pesoAvaria' &&
                  nextField.key == 'unidadesAvariadas') ||
              (field.key == 'conferente' && nextField.key == 'tratador') ||
              (field.key == 'meioDeContato' && nextField.key == 'contato')) {
            shouldMakeRow = true;
          }

          if (shouldMakeRow) {
            // Constrói linha com esses dois campos
            columnWidgets.add(
              _buildFieldRowWithTabOrder([field, nextField], tabOrderMap),
            );
            i++; // Pula o próximo campo pois já foi tratado
            if (i < section.fields.length - 1) {
              columnWidgets.add(SizedBox(height: Responsive.spacing(context)));
            }
            continue;
          }
        }

        // Campo único padrão
        columnWidgets.add(
          _buildFormFieldWithTabOrder(field, tabOrderMap[field.key] ?? 1),
        );
        if (i < section.fields.length - 1) {
          columnWidgets.add(SizedBox(height: Responsive.spacing(context)));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnWidgets,
    );
  }

  Widget _buildFieldRowWithTabOrder(
    List<FormFieldConfig> fields,
    Map<String, int> tabOrderMap,
  ) {
    return Row(
      children: [
        Expanded(
          flex: fields[0].flex?.toInt() ?? 1,
          child: _buildSingleFieldWithTabOrder(
            fields[0],
            tabOrderMap[fields[0].key] ?? 1,
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        Expanded(
          flex: fields[1].flex?.toInt() ?? 1,
          child: _buildSingleFieldWithTabOrder(
            fields[1],
            tabOrderMap[fields[1].key] ?? 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFieldWithTabOrder(FormFieldConfig field, int tabOrder) {
    // Verifica se a config fornece um campo customizado
    final customField = widget.config.buildCustomField(field, _formData);
    if (customField != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: Responsive.spacing(context)),
        child: FocusTraversalOrder(
          order: NumericFocusOrder(tabOrder.toDouble()),
          child: customField,
        ),
      );
    }

    // Trata campos em linha (campos lado a lado)
    if (field.type == FormFieldType.row) {
      return _buildRowField(field);
    }

    // Campo único padrão
    return _buildSingleFieldWithTabOrder(field, tabOrder);
  }

  Widget _buildRowField(FormFieldConfig rowField) {
    // Para campos em linha, 'options' contém chaves reais para exibir lado a lado
    if (rowField.options == null || rowField.options!.length < 2) {
      return const SizedBox.shrink();
    }

    final leftFieldKey = rowField.options![0];
    final rightFieldKey = rowField.options![1];

    // Encontra as configurações reais dos campos
    FormFieldConfig? leftField;
    FormFieldConfig? rightField;

    for (final section in widget.config.formSections) {
      for (final field in section.fields) {
        if (field.key == leftFieldKey) leftField = field;
        if (field.key == rightFieldKey) rightField = field;
      }
    }

    if (leftField == null || rightField == null) {
      return const SizedBox.shrink();
    }

    final tabOrderMap = _getFieldTabOrder();

    return Row(
      children: [
        Expanded(
          flex: leftField.flex?.toInt() ?? 1,
          child: _buildSingleFieldWithTabOrder(
            leftField,
            tabOrderMap[leftField.key] ?? 1,
          ),
        ),
        SizedBox(width: Responsive.spacing(context)),
        Expanded(
          flex: rightField.flex?.toInt() ?? 1,
          child: _buildSingleFieldWithTabOrder(
            rightField,
            tabOrderMap[rightField.key] ?? 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleFieldWithTabOrder(FormFieldConfig field, int tabOrder) {
    // Verifica se a config fornece um campo customizado
    final customField = widget.config.buildCustomField(field, _formData);
    if (customField != null) {
      return FocusTraversalOrder(
        order: NumericFocusOrder(tabOrder.toDouble()),
        child: customField,
      );
    }

    return _buildFormFieldWrapper(
      label: field.label,
      isRequired: field.isRequired,
      child: FocusTraversalOrder(
        order: NumericFocusOrder(tabOrder.toDouble()),
        child: _buildFieldInput(field),
      ),
    );
  }

  Widget _buildFieldInput(FormFieldConfig field) {
    switch (field.type) {
      case FormFieldType.dropdown:
        return DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            value: _dropdownValues[field.key],
            isExpanded: true,
            hint: Text(
              field.hint ?? 'Selecione',
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.neutral400,
              ),
            ),
            items: field.options
                ?.map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: AppDesignSystem.bodyMedium),
                  ),
                )
                .toList(),
            onChanged: field.enabled
                ? (value) {
                    setState(() {
                      _dropdownValues[field.key] = value;
                      _formData[field.key] = value;
                    });
                    widget.config.onFormFieldChanged(
                      field.key,
                      value,
                      _formData,
                    );
                  }
                : null,
            buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppDesignSystem.neutral300),
                color: field.enabled
                    ? AppDesignSystem.surface
                    : AppDesignSystem.neutral50,
              ),
            ),
            iconStyleData: IconStyleData(
              icon: Icon(
                Icons.arrow_drop_down,
                color: field.enabled
                    ? AppDesignSystem.neutral600
                    : AppDesignSystem.neutral400,
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
                    color: Colors.black.withValues(alpha: 0.1),
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
        );

      case FormFieldType.date:
        return TextFormField(
          controller: _controllers[field.key],
          decoration:
              AppDesignSystem.inputDecoration(
                hint: field.hint ?? 'dd-mm-aaaa',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(context, field.key),
                ),
                prefixIcon: field.prefixIcon,
              ),
          keyboardType: field.keyboardType,
          inputFormatters: field.formatters,
          enabled: field.enabled,
          readOnly: field.isReadOnly,
          onTap: field.onTap,
          validator:
              field.validator ??
              (field.isRequired
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return '${field.label} é obrigatório';
                      }
                      return null;
                    }
                  : null),
        );

      case FormFieldType.multiline:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: AppDesignSystem.inputDecoration(
            hint: field.hint ?? field.label,
            prefixIcon: field.prefixIcon,
            suffixIcon: field.suffixIcon,
          ),
          maxLines: field.maxLines ?? 3,
          keyboardType: TextInputType.multiline,
          inputFormatters: field.formatters,
          enabled: field.enabled,
          readOnly: field.isReadOnly,
          onTap: field.onTap,
          validator:
              field.validator ??
              (field.isRequired
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return '${field.label} é obrigatório';
                      }
                      return null;
                    }
                  : null),
        );

      case FormFieldType.file:
        return _buildFilePickerField(field);

      default: // texto, número, moeda
        return TextFormField(
          controller: _controllers[field.key],
          decoration:
              AppDesignSystem.inputDecoration(
                hint: field.hint ?? field.label,
                prefixIcon: field.prefixIcon,
                suffixIcon: field.suffixIcon,
              ).copyWith(
                filled: field.isReadOnly,
                fillColor: field.isReadOnly ? AppDesignSystem.neutral50 : null,
              ),
          keyboardType: field.keyboardType ?? TextInputType.text,
          inputFormatters: field.formatters,
          enabled: field.enabled,
          readOnly: field.isReadOnly,
          onTap: field.onTap,
          validator:
              field.validator ??
              (field.isRequired
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return '${field.label} é obrigatório';
                      }
                      return null;
                    }
                  : null),
        );
    }
  }

  Widget _buildActionButtons() {
    if (Responsive.isSmallScreen(context)) {
      // Empilha botões verticalmente em telas pequenas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : _clearForm,
            style: AppDesignSystem.secondaryButton,
            child: const Text('Limpar Formulário'),
          ),
          SizedBox(height: Responsive.spacing(context)),
          OutlinedButton(
            onPressed: _isSaving ? null : widget.onCancel,
            style: AppDesignSystem.secondaryButton,
            child: Text(widget.config.cancelButtonText),
          ),
          SizedBox(height: Responsive.spacing(context)),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveForm,
            style: AppDesignSystem.primaryButton.copyWith(
              textStyle: WidgetStateProperty.all(
                AppDesignSystem.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppDesignSystem.surface,
                ),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.config.submitButtonText),
          ),
        ],
      );
    }

    // Layout horizontal para telas maiores
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : _clearForm,
          style: AppDesignSystem.secondaryButton,
          child: const Text('Limpar Formulário'),
        ),
        SizedBox(width: Responsive.spacing(context)),
        OutlinedButton(
          onPressed: _isSaving ? null : widget.onCancel,
          style: AppDesignSystem.secondaryButton,
          child: Text(widget.config.cancelButtonText),
        ),
        SizedBox(width: Responsive.spacing(context)),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveForm,
          style: AppDesignSystem.primaryButton.copyWith(
            textStyle: WidgetStateProperty.all(
              AppDesignSystem.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.surface,
              ),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.config.submitButtonText),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context)),
      child: Row(
        children: [
          Container(
            width: 3,
            height: Responsive.valueDetailed(
              context,
              mobile: 16,
              smallTablet: 18,
              tablet: 20,
              desktop: 20,
            ),
            decoration: BoxDecoration(
              color: AppDesignSystem.primary,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXS),
            ),
          ),
          SizedBox(width: Responsive.spacing(context)),
          Text(
            title,
            style: AppDesignSystem.h3.copyWith(
              fontSize: Responsive.headerFontSize(context),
            ),
          ),
        ],
      ),
    );
  }

  // Construtor de campo do seletor de arquivos
  Widget _buildFilePickerField(FormFieldConfig field) {
    final currentFile = _fileData[field.key];
    final hasExistingFile =
        field.initialValue != null && field.initialValue!.isNotEmpty;

    // Determina o texto de fallback quando nenhum arquivo está selecionado
    final fallbackText = hasExistingFile
        ? 'Arquivo anexado'
        : field.hint ?? 'Clique para selecionar arquivo';

    // Determina o texto a ser exibido
    final displayText = currentFile != null ? currentFile.name : fallbackText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: field.enabled ? () => _pickFile(field) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppDesignSystem.neutral300, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: field.enabled
                  ? AppDesignSystem.surface
                  : AppDesignSystem.neutral50,
            ),
            child: Row(
              children: [
                Icon(
                  currentFile != null || hasExistingFile
                      ? Icons.check_circle_outline
                      : Icons.upload_file_outlined,
                  color: currentFile != null || hasExistingFile
                      ? AppDesignSystem.success
                      : AppDesignSystem.neutral600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: currentFile != null || hasExistingFile
                              ? AppDesignSystem.neutral900
                              : AppDesignSystem.neutral600,
                          fontWeight: currentFile != null || hasExistingFile
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (currentFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(currentFile.size),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (currentFile != null || hasExistingFile)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: field.enabled
                        ? () => _removeFile(field.key)
                        : null,
                    color: AppDesignSystem.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
        // Texto de ajuda
        if (field.allowedExtensions != null &&
            field.allowedExtensions!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Formatos aceitos: ${field.allowedExtensions!.join(", ").toUpperCase()}',
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ],
        if (field.maxFileSizeMB != null) ...[
          const SizedBox(height: 4),
          Text(
            'Tamanho máximo: ${field.maxFileSizeMB}MB',
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.neutral500,
            ),
          ),
        ],
      ],
    );
  }

  // Handler de seleção de arquivo
  Future<void> _pickFile(FormFieldConfig field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type:
            field.allowedExtensions != null &&
                field.allowedExtensions!.isNotEmpty
            ? FileType.custom
            : FileType.any,
        allowedExtensions: field.allowedExtensions,
        withData: true, // Importante para compatibilidade web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Verifica o tamanho do arquivo
        final maxSizeBytes = (field.maxFileSizeMB ?? 10) * 1024 * 1024;
        if (file.size > maxSizeBytes) {
          if (mounted) {
            SnackBarUtils.showWarning(
              context,
              'Arquivo muito grande (máximo ${field.maxFileSizeMB}MB)',
            );
          }
          return;
        }

        // Verifica se os bytes estão disponíveis
        if (file.bytes == null && file.path == null) {
          if (mounted) {
            SnackBarUtils.showWarning(context, 'Erro ao processar arquivo');
          }
          return;
        }

        setState(() {
          _fileData[field.key] = file;
          _formData[field.key] =
              file.name; // Armazena o nome do arquivo em formData
        });

        widget.config.onFormFieldChanged(field.key, file, _formData);
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

  // Remove file handler
  void _removeFile(String fieldKey) {
    setState(() {
      _fileData.remove(fieldKey);
      _formData.remove(fieldKey);
    });

    widget.config.onFormFieldChanged(fieldKey, null, _formData);
  }

  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Método auxiliar para campos com estilo responsivo
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
                fontSize: Responsive.bodyFontSize(context),
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.neutral700,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: Responsive.smallSpacing(context)),
              Text(
                '*',
                style: AppDesignSystem.labelMedium.copyWith(
                  fontSize: Responsive.bodyFontSize(context),
                  color: AppDesignSystem.error,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: Responsive.smallSpacing(context)),
        child,
      ],
    );
  }
}
