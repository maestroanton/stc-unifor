import '../services/user_role.dart';

enum UfType { ce, sp }

class UfHelper {
  static final _userRoleService = UserRoleService();

  static Future<String?> getCurrentUserUf() async {
    return await _userRoleService.getCurrentUserUf();
  }

  static Future<UfType?> getCurrentUserUfType() async {
    final uf = await getCurrentUserUf();
    if (uf == 'CE') return UfType.ce;
    if (uf == 'SP') return UfType.sp;
    return null;
  }

  static Future<bool> isUserFromCe() async {
    final uf = await getCurrentUserUf();
    return uf == 'CE';
  }

  static Future<bool> isUserFromSp() async {
    final uf = await getCurrentUserUf();
    return uf == 'SP';
  }

  static Future<bool> hasUfAccess(String uf) async {
    return await _userRoleService.hasUfAccess(uf);
  }

  static Future<bool> isAdmin() async {
    return await _userRoleService.isCurrentUserAdmin();
  }

  static Future<bool> isOperator() async {
    return await _userRoleService.isCurrentUserOperator();
  }

  static Future<bool> hasReportAccess() async {
    return await _userRoleService.hasReportAccess();
  }
}
