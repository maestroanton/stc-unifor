class Inventario {
  String? id;
  int? internalId;
  String notaFiscalId; // ID da nota fiscal (obrigatório)

  // Campos específicos do item de inventário
  double valor;
  String? dataDeGarantia;
  String produto;
  String descricao;
  String estado;
  String tipo;
  String uf;
  String? numeroDeSerie;
  String? localizacao;
  String? observacoes;

  Inventario({
    this.id,
    this.internalId,
    required this.notaFiscalId, // Obrigatório
    required this.valor,
    this.dataDeGarantia,
    required this.produto,
    required this.descricao,
    required this.estado,
    required this.tipo,
    required this.uf,
    this.numeroDeSerie,
    this.localizacao,
    this.observacoes,
  });

  factory Inventario.fromMap(Map<String, dynamic> map, String id) {
    return Inventario(
      id: id,
      internalId: map['internalId'],
      notaFiscalId: map['notaFiscalId'], // ID da nota fiscal
      valor: (map['valor'] ?? 0).toDouble(),
      dataDeGarantia: map['dataDeGarantia'],
      produto: map['produto'] ?? '',
      descricao: map['descricao'] ?? '',
      estado: map['estado'] ?? '',
      tipo: map['tipo'] ?? '',
      uf: map['uf'] ?? '',
      numeroDeSerie: map['numeroDeSerie'],
      localizacao: map['localizacao'],
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (internalId != null) 'internalId': internalId,
      'notaFiscalId': notaFiscalId, // Incluído sempre
      'valor': valor,
      if (dataDeGarantia != null) 'dataDeGarantia': dataDeGarantia,
      'produto': produto,
      'descricao': descricao,
      'estado': estado,
      'tipo': tipo,
      'uf': uf,
      if (numeroDeSerie != null) 'numeroDeSerie': numeroDeSerie,
      if (localizacao != null) 'localizacao': localizacao,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}
