class NotaFiscal {
  String? id; // ID do documento no Firestore
  String numeroNota;
  String fornecedor;
  DateTime dataCompra;
  double valorTotal;
  String? notaFiscalUrl;
  String? chaveAcesso;
  String uf; // Obrigatório para regras de segurança do Firebase
  DateTime createdAt;
  String? createdBy;

  NotaFiscal({
    this.id,
    required this.numeroNota,
    required this.fornecedor,
    required this.dataCompra,
    required this.valorTotal,
    this.notaFiscalUrl,
    this.chaveAcesso,
    required this.uf,
    DateTime? createdAt,
    this.createdBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotaFiscal.fromMap(Map<String, dynamic> map, String id) {
    return NotaFiscal(
      id: id,
      numeroNota: map['numeroNota'] ?? '',
      fornecedor: map['fornecedor'] ?? '',
      dataCompra: map['dataCompra'] != null
          ? DateTime.parse(map['dataCompra'])
          : DateTime.now(),
      valorTotal: (map['valorTotal'] ?? 0).toDouble(),
      notaFiscalUrl: map['notaFiscalUrl'],
      chaveAcesso: map['chaveAcesso'],
      uf: map['uf'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroNota': numeroNota,
      'fornecedor': fornecedor,
      'dataCompra': dataCompra.toIso8601String(),
      'valorTotal': valorTotal,
      if (notaFiscalUrl != null) 'notaFiscalUrl': notaFiscalUrl,
      if (chaveAcesso != null) 'chaveAcesso': chaveAcesso,
      'uf': uf,
      'createdAt': createdAt.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }
}
