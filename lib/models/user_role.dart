class UserRole {
  final String email;
  final String uf;
  final bool isAdmin;
  final bool isOperator; // Permissões de operador
  final bool active;
  final bool testAccess;
  final bool requestAccess; // Permissão para solicitar acesso
  final bool reportAccess; // Permissão para exportar relatórios
  final String displayName;

  UserRole({
    required this.email,
    required this.uf,
    this.isAdmin = false,
    this.isOperator = false, // Padrão: false
    this.active = true,
    this.testAccess = false,
    this.requestAccess = false, // Padrão: false
    this.reportAccess = false, // Padrão: false
    required this.displayName,
  });

  factory UserRole.fromMap(Map<String, dynamic> map, String email) {
    return UserRole(
      email: email,
      uf: map['uf'] ?? '',
      isAdmin: map['isAdmin'] == true, // Verifica se é true
      isOperator: map['isOperator'] == true, // Verifica se é true
      active: map['active'] ?? true, // Padrão: true
      testAccess: map['testAccess'] == true, // Verifica se é true
      requestAccess: map['requestAccess'] == true, // Verifica se é true
      reportAccess: map['reportAccess'] == true, // Verifica se é true
      displayName: map['displayName'] ?? email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uf': uf,
      'isAdmin': isAdmin,
      'isOperator': isOperator, // Inclui isOperator no mapa
      'active': active,
      'testAccess': testAccess,
      'requestAccess': requestAccess, // Inclui requestAccess no mapa
      'reportAccess': reportAccess, // Inclui reportAccess no mapa
      'displayName': displayName,
    };
  }

  /// Retorna true se o usuário for operador ou administrador
  bool get hasOperatorAccess => isOperator || isAdmin;

  /// Retorna true se o usuário for administrador
  bool get hasAdminAccess => isAdmin;

  /// Retorna true se o usuário tem acesso de teste e está ativo
  bool get hasTestAccess => testAccess && active;

  /// Retorna true se pode exportar relatórios (admin tem acesso total)
  bool get hasReportAccess => (reportAccess || isAdmin) && active;

  /// Nível de permissão do usuário (exibição)
  String get permissionLevel {
    if (isAdmin) return 'Administrador';
    if (isOperator) return 'Operador';
    return 'Usuário';
  }

  /// Descrição das permissões do usuário
  String get permissionDescription {
    if (isAdmin) {
      return 'Acesso completo ao sistema, incluindo relatórios e configurações';
    }
    if (isOperator) {
      return 'Acesso aos módulos Avaria, Inventário e Licenças';
    }
    return 'Acesso básico ao sistema';
  }

  @override
  String toString() {
    return 'UserRole{email: $email, uf: $uf, isAdmin: $isAdmin, isOperator: $isOperator, active: $active, testAccess: $testAccess, requestAccess: $requestAccess, reportAccess: $reportAccess, displayName: $displayName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRole &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          uf == other.uf &&
          isAdmin == other.isAdmin &&
          isOperator == other.isOperator &&
          active == other.active &&
          testAccess == other.testAccess &&
          requestAccess == other.requestAccess &&
          reportAccess == other.reportAccess &&
          displayName == other.displayName;

  @override
  int get hashCode =>
      email.hashCode ^
      uf.hashCode ^
      isAdmin.hashCode ^
      isOperator.hashCode ^
      active.hashCode ^
      testAccess.hashCode ^
      requestAccess.hashCode ^
      reportAccess.hashCode ^
      displayName.hashCode;

  UserRole copyWith({
    String? email,
    String? uf,
    bool? isAdmin,
    bool? isOperator,
    bool? active,
    bool? testAccess,
    bool? requestAccess,
    bool? reportAccess,
    String? displayName,
  }) {
    return UserRole(
      email: email ?? this.email,
      uf: uf ?? this.uf,
      isAdmin: isAdmin ?? this.isAdmin,
      isOperator: isOperator ?? this.isOperator,
      active: active ?? this.active,
      testAccess: testAccess ?? this.testAccess,
      requestAccess: requestAccess ?? this.requestAccess,
      reportAccess: reportAccess ?? this.reportAccess,
      displayName: displayName ?? this.displayName,
    );
  }
}
