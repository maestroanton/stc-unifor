enum LicenseStatus {
  valida,
  vencida,
  proximoVencimento, // Até 30 dias antes do vencimento
}

extension LicenseStatusExtension on LicenseStatus {
  String get displayName {
    switch (this) {
      case LicenseStatus.valida:
        return 'Válida';
      case LicenseStatus.vencida:
        return 'Vencida';
      case LicenseStatus.proximoVencimento:
        return 'Próximo Vencimento';
    }
  }

  String get name {
    switch (this) {
      case LicenseStatus.valida:
        return 'valida';
      case LicenseStatus.vencida:
        return 'vencida';
      case LicenseStatus.proximoVencimento:
        return 'proximoVencimento';
    }
  }

  static LicenseStatus fromString(String status) {
    switch (status) {
      case 'valida':
        return LicenseStatus.valida;
      case 'vencida':
        return LicenseStatus.vencida;
      case 'proximoVencimento':
        return LicenseStatus.proximoVencimento;
      default:
        return LicenseStatus.vencida;
    }
  }
}

class License {
  final String? id;
  final String nome;
  final String uf; // 'CE' ou 'SP'
  final LicenseStatus status;
  final String dataInicio;
  final String dataVencimento;
  final String? arquivoUrl; // URL do PDF no Firebase Storage
  final String? arquivoNome; // Nome do arquivo
  final DateTime? arquivoUploadData; // Data do upload
  final String? ultimoAtualizadoPor; // E-mail do último atualizador
  final DateTime? ultimaAtualizacao;

  License({
    this.id,
    required this.nome,
    required this.uf,
    required this.status,
    required this.dataInicio,
    required this.dataVencimento,
    this.arquivoUrl,
    this.arquivoNome,
    this.arquivoUploadData,
    this.ultimoAtualizadoPor,
    this.ultimaAtualizacao,
  });

  // Calcula status a partir da data de vencimento
  static LicenseStatus calculateStatus(String dataVencimento) {
    try {
      final parts = dataVencimento.split('-');
      if (parts.length != 3) return LicenseStatus.vencida;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final vencimento = DateTime(year, month, day);
      final hoje = DateTime.now();
      final diferenca = vencimento.difference(hoje).inDays;

      if (diferenca < 0) {
        return LicenseStatus.vencida;
      } else if (diferenca <= 30) {
        return LicenseStatus.proximoVencimento;
      } else {
        return LicenseStatus.valida;
      }
    } catch (e) {
      return LicenseStatus.vencida;
    }
  }

  License copyWith({
    String? id,
    String? nome,
    String? uf,
    LicenseStatus? status,
    String? dataInicio,
    String? dataVencimento,
    String? arquivoUrl,
    String? arquivoNome,
    DateTime? arquivoUploadData,
    String? ultimoAtualizadoPor,
    DateTime? ultimaAtualizacao,
  }) {
    return License(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      uf: uf ?? this.uf,
      status: status ?? this.status,
      dataInicio: dataInicio ?? this.dataInicio,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      arquivoUrl: arquivoUrl ?? this.arquivoUrl,
      arquivoNome: arquivoNome ?? this.arquivoNome,
      arquivoUploadData: arquivoUploadData ?? this.arquivoUploadData,
      ultimoAtualizadoPor: ultimoAtualizadoPor ?? this.ultimoAtualizadoPor,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'uf': uf,
      'status': status.name,
      'dataInicio': dataInicio,
      'dataVencimento': dataVencimento,
      'arquivoUrl': arquivoUrl,
      'arquivoNome': arquivoNome,
      'arquivoUploadData': arquivoUploadData?.toIso8601String(),
      'ultimoAtualizadoPor': ultimoAtualizadoPor,
      'ultimaAtualizacao': ultimaAtualizacao?.toIso8601String(),
    };
  }

  factory License.fromMap(Map<String, dynamic> map, String id) {
    return License(
      id: id,
      nome: map['nome'] ?? '',
      uf: map['uf'] ?? '',
      status: LicenseStatusExtension.fromString(map['status'] ?? 'vencida'),
      dataInicio: map['dataInicio'] ?? '',
      dataVencimento: map['dataVencimento'] ?? '',
      arquivoUrl: map['arquivoUrl'],
      arquivoNome: map['arquivoNome'],
      arquivoUploadData:
          map['arquivoUploadData'] != null
              ? DateTime.parse(map['arquivoUploadData'])
              : null,
      ultimoAtualizadoPor: map['ultimoAtualizadoPor'],
      ultimaAtualizacao:
          map['ultimaAtualizacao'] != null
              ? DateTime.parse(map['ultimaAtualizacao'])
              : null,
    );
  }

  // Retorna true se estiver próximo do vencimento
  bool get isExpiringSoon {
    return status == LicenseStatus.proximoVencimento;
  }

  // Retorna true se estiver vencida
  bool get isExpired {
    return status == LicenseStatus.vencida;
  }

  // Dias até o vencimento (negativo se expirado)
  int get daysUntilExpiry {
    try {
      final parts = dataVencimento.split('-');
      if (parts.length != 3) return -999;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final vencimento = DateTime(year, month, day);
      final hoje = DateTime.now();
      return vencimento.difference(hoje).inDays;
    } catch (e) {
      return -999;
    }
  }
}
