import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';

class UserRoleService {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final CollectionReference _userRolesCollection = FirebaseFirestore.instance
      .collection('user_roles');

  // Cache do papel do usuário para evitar chamadas repetidas
  UserRole? _cachedUserRole;
  String? _cachedUserEmail;

  /// Obtém o papel do usuário atual com cache
  Future<UserRole?> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return null;

    // Retorna papel em cache se for mesmo usuário
    if (_cachedUserRole != null && _cachedUserEmail == user!.email) {
      return _cachedUserRole;
    }

    try {
      final doc = await _userRolesCollection.doc(user!.email).get();

      if (doc.exists && doc.data() != null) {
        _cachedUserRole = UserRole.fromMap(
          doc.data() as Map<String, dynamic>,
          user.email!,
        );
        _cachedUserEmail = user.email;
        return _cachedUserRole;
      }

      // Email de admin legado; fornece compatibilidade retroativa
      if (user.email == 'ce@gistc.com' || user.email == 'sp@gistc.com') {
        final legacyRole = UserRole(
          email: user.email!,
          uf: user.email == 'ce@gistc.com' ? 'CE' : 'SP',
          isAdmin: true,
          isOperator: true, // Admins legados também operadores
          active: true,
          testAccess: false, // Admins legados sem acesso de teste
          reportAccess: true, // Admins legados com acesso a relatórios
          displayName: 'Legacy Admin',
        );

        // Não cria documento automaticamente; papéis gerenciados manualmente

        _cachedUserRole = legacyRole;
        _cachedUserEmail = user.email;
        return legacyRole;
      }

      return null;
    } catch (e) {
      // Erro ao obter papel do usuário
      return null;
    }
  }

  /// Obtém papel do usuário por email (apenas exibição)
  Future<UserRole?> getUserRoleByEmail(String email) async {
    try {
      final doc = await _userRolesCollection.doc(email).get();

      if (doc.exists && doc.data() != null) {
        return UserRole.fromMap(doc.data() as Map<String, dynamic>, email);
      }
      return null;
    } catch (e) {
      // Erro ao obter papel do usuário
      return null;
    }
  }

  /// Obtém todos papéis de usuário (apenas admin - exibição)
  Future<List<UserRole>> getAllUserRoles() async {
    try {
      final querySnapshot = await _userRolesCollection.get();

      return querySnapshot.docs
          .map(
            (doc) =>
                UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      // Erro ao obter papéis de usuário
      return [];
    }
  }

  /// Verifica se usuário atual é admin
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role?.isAdmin == true && role?.active == true;
  }

  /// Verifica se usuário atual é operador
  Future<bool> isCurrentUserOperator() async {
    final role = await getCurrentUserRole();
    return (role?.isOperator == true || role?.isAdmin == true) &&
        role?.active == true;
  }

  /// Verifica se usuário atual tem acesso de teste
  Future<bool> hasTestAccess() async {
    final role = await getCurrentUserRole();
    return role?.testAccess == true && role?.active == true;
  }

  /// Verifica se usuário atual tem acesso a relatórios
  Future<bool> hasReportAccess() async {
    final role = await getCurrentUserRole();
    if (role == null || !role.active) return false;
    return role.reportAccess || role.isAdmin;
  }

  /// Obtém UF do usuário atual
  Future<String?> getCurrentUserUf() async {
    final role = await getCurrentUserRole();
    return role?.active == true ? role?.uf : null;
  }

  /// Verifica se usuário atual tem acesso a UF específica
  Future<bool> hasUfAccess(String uf) async {
    final role = await getCurrentUserRole();
    if (role == null || !role.active) return false;

    // Admins têm acesso a todas UFs
    if (role.isAdmin) return true;

    // Usuários normais acessam apenas sua UF
    return role.uf == uf;
  }

  /// Obtém usuários com acesso de teste (apenas admin)
  Future<List<UserRole>> getUsersWithTestAccess() async {
    try {
      final querySnapshot = await _userRolesCollection
          .where('testAccess', isEqualTo: true)
          .where('active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      // Erro ao obter usuários com acesso de teste
      return [];
    }
  }

  /// Obtém usuários com acesso de operador (apenas admin)
  Future<List<UserRole>> getUsersWithOperatorAccess() async {
    try {
      final querySnapshot = await _userRolesCollection
          .where('active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where((role) => role.isOperator || role.isAdmin)
          .toList();
    } catch (e) {
      // Erro ao obter usuários com acesso de operador
      return [];
    }
  }

  /// Obtém usuários por nível de permissão (apenas admin)
  Future<List<UserRole>> getUsersByPermissionLevel(String level) async {
    try {
      final querySnapshot = await _userRolesCollection
          .where('active', isEqualTo: true)
          .get();

      final allUsers = querySnapshot.docs
          .map(
            (doc) =>
                UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      switch (level.toLowerCase()) {
        case 'admin':
        case 'administrador':
          return allUsers.where((role) => role.isAdmin).toList();
        case 'operator':
        case 'operador':
          return allUsers
              .where((role) => role.isOperator && !role.isAdmin)
              .toList();
        case 'user':
        case 'usuario':
        case 'usuário':
          return allUsers
              .where((role) => !role.isOperator && !role.isAdmin)
              .toList();
        default:
          return allUsers;
      }
    } catch (e) {
      // Erro ao obter usuários por nível
      return [];
    }
  }

  /// Verifica se usuário específico tem acesso de teste (apenas admin)
  Future<bool> userHasTestAccess(String email) async {
    try {
      final role = await getUserRoleByEmail(email);
      return role?.testAccess == true && role?.active == true;
    } catch (e) {
      // Erro ao verificar acesso de teste
      return false;
    }
  }

  /// Verifica se usuário específico tem acesso de operador (apenas admin)
  Future<bool> userHasOperatorAccess(String email) async {
    try {
      final role = await getUserRoleByEmail(email);
      return (role?.isOperator == true || role?.isAdmin == true) &&
          role?.active == true;
    } catch (e) {
      // Erro ao verificar acesso de operador
      return false;
    }
  }

  /// Limpa cache (útil ao deslogar)
  void clearCache() {
    _cachedUserRole = null;
    _cachedUserEmail = null;
  }

  /// Stream do papel do usuário (atualizações em tempo real)
  Stream<UserRole?> getCurrentUserRoleStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      return Stream.value(null);
    }

    return _userRolesCollection.doc(user!.email).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final role = UserRole.fromMap(
          doc.data() as Map<String, dynamic>,
          user.email!,
        );

        // Atualiza cache
        _cachedUserRole = role;
        _cachedUserEmail = user.email;

        return role;
      }
      return null;
    });
  }

  /// Stream de usuários com acesso de teste (tempo real para admin)
  Stream<List<UserRole>> getTestUsersStream() {
    return _userRolesCollection
        .where('testAccess', isEqualTo: true)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserRole.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Stream de usuários com acesso de operador (tempo real para admin)
  Stream<List<UserRole>> getOperatorUsersStream() {
    return _userRolesCollection
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserRole.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .where((role) => role.isOperator || role.isAdmin)
              .toList(),
        );
  }

  /// Stream de todos usuários ativos (tempo real para admin)
  Stream<List<UserRole>> getAllActiveUsersStream() {
    return _userRolesCollection
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserRole.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Obtém estatísticas de usuários para o painel de admin
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final querySnapshot = await _userRolesCollection
          .where('active', isEqualTo: true)
          .get();

      final users = querySnapshot.docs
          .map(
            (doc) =>
                UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      return {
        'total': users.length,
        'admins': users.where((user) => user.isAdmin).length,
        'operators': users
            .where((user) => user.isOperator && !user.isAdmin)
            .length,
        'regular': users
            .where((user) => !user.isOperator && !user.isAdmin)
            .length,
        'testAccess': users.where((user) => user.testAccess).length,
      };
    } catch (e) {
      // Erro ao obter estatísticas de usuários
      return {
        'total': 0,
        'admins': 0,
        'operators': 0,
        'regular': 0,
        'testAccess': 0,
      };
    }
  }

  // MÉTODOS REMOVIDOS (papéis gerenciados manualmente)
  // - createOrUpdateUserRole()
  // - deleteUserRole()
  // - updateUserTestAccess()
  // - updateUserOperatorAccess()

  // Se necessário gerenciar papéis no futuro, atualize regras de segurança
}
