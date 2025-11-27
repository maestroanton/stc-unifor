# Documentação de API

## Firebase

**Projeto:** gastc-47718

**Serviços:**
- Authentication (email/senha)
- Firestore (NoSQL)
- Storage (arquivos)
- Functions (serverless)

### Coleções Firestore

**inventarios**
- internalId, notaFiscalId, produto, descricao, valor, numeroDeSerie, dataDeGarantia, estado, tipo, uf, localizacao, observacoes

**notas_fiscais**
- numeroNota, fornecedor, dataCompra, valorTotal, notaFiscalUrl, chaveAcesso, uf, createdAt, createdBy
- Restrição: uf + numeroNota único

**licenses**
- nome, uf (CE/SP), status (valida/vencida/proximoVencimento), dataInicio, dataVencimento, arquivoUrl, arquivoNome, arquivoUploadData, ultimoAtualizadoPor, ultimaAtualizacao

**user_roles**
- email, uf, isAdmin, isOperator, active, testAccess, requestAccess, reportAccess, displayName

**audit_logs**
- userId, userEmail, userDisplayName, uf, isAdmin, action, module, recordId, recordIdentifier, oldData, newData, description, timestamp, metadata
- Retenção: 1 ano

**email_logs**
- type (warning/expired), recipient, status (sent/failed), sentAt, licenseData, error

**user_first_login**
- email, completedAt, version

**internal_counters**
- inventario_internal_id/current

**Backup:**
- inventarios_backup, notas_fiscais_backup, licenses_backup

### Storage

```
licenses/{UF}/{nome_licenca}/{arquivo}
inventarios/{notaFiscalId}/{arquivo}
```

Limite: 10MB. Formatos: PDF, JPG, PNG, WEBP

## Serviços

### AuditLogService
`lib/services/audit_log.dart`

```dart
Future<void> logAction({
  required LogAction action,
  required LogModule module,
  String? recordId,
  String? recordIdentifier,
  Map<String, dynamic>? oldData,
  Map<String, dynamic>? newData,
  String? description,
  Map<String, dynamic>? metadata,
})

Future<void> revertChange({
  required String recordId,
  required LogModule module,
  required String targetLogId,
  required Map<String, dynamic> oldData,
  LogAction? originalAction,
})

Future<List<AuditLog>> getLogs({
  DateTime? startDate,
  DateTime? endDate,
  String? userEmail,
  LogAction? action,
  LogModule? module,
  String? uf,
  int limit = 25,
})
```

### UserRoleService
`lib/services/user_role.dart`

```dart
Future<UserRole?> getCurrentUserRole()
Future<bool> isCurrentUserAdmin()
Future<bool> isCurrentUserOperator()
Future<bool> hasTestAccess()
Future<bool> hasReportAccess()
Future<String?> getCurrentUserUf()
Future<bool> hasUfAccess(String uf)
Future<UserRole?> getUserRoleByEmail(String email)
Future<List<UserRole>> getAllUserRoles()
```

Cache: Mantém UserRole em memória

### FirstLoginService
`lib/services/first_login.dart`

```dart
Future<bool> isFirstLogin()
Future<void> markFirstLoginComplete(String email)
Future<void> resetFirstLoginStatus(String email)
Future<bool> hasUserCompletedFirstLogin(String email)
Future<void> forceFirstLogin(String email)
```

### LicenseEmailService
`lib/services/license_email.dart`

```dart
static Future<bool> sendWarningEmail(List<License> allLicenses)
static Future<bool> sendExpiredEmail(List<License> allLicenses)
static bool isWithinDaysOfExpiring(License license, int days)
static bool isExpired(License license)
static int getRemainingDays(License license)
```

EmailJS: service_gkr2xu7, template_ydzo3gj

### ActivityTracker
`lib/services/activity_tracker.dart`

```dart
Future<void> initializeTracking()
Future<void> recordActivity()
Future<void> stopTracking()
```

Logout automático: 2 horas (120 minutos)

### EmailLogService
`lib/services/email_log.dart`

```dart
Future<void> logEmail({
  required String type,
  required String recipient,
  required String status,
  required Map<String, dynamic> licenseData,
  String? error,
})

Future<List<EmailLog>> getEmailLogs({
  DateTime? startDate,
  DateTime? endDate,
  String? type,
  String? status,
  int limit = 50,
})
```

### CsvImportService
`lib/services/csv_import_service.dart`

```dart
Future<CsvImportResult> importFromCsv(String csvContent)
```

## Helpers

### DatabaseHelperInventario
`lib/helpers/database_helper_inventario.dart`

```dart
// NotaFiscal
Future<bool> notaFiscalExists(String uf, String numeroNota)
Future<String> createNotaFiscal(NotaFiscal notaFiscal)
Future<NotaFiscal?> getNotaFiscalById(String id)
Future<NotaFiscal?> getNotaFiscalByUfAndNumero(String uf, String numeroNota)
Future<List<NotaFiscal>> getAllNotasFiscais()
Future<void> updateNotaFiscal(NotaFiscal notaFiscal)
Future<void> deleteNotaFiscal(String id)

// Inventario
Future<String> createInventario(Inventario inventario)
Future<List<Inventario>> getInventarios()
Future<Inventario?> getInventarioById(String id)
Future<List<Inventario>> getInventariosByNotaFiscalId(String notaFiscalId)
Future<void> updateInventario(Inventario inventario)
Future<void> deleteInventario(String id)

// Composto
Future<String> createNotaFiscalWithInventarios({
  required NotaFiscal notaFiscal,
  required List<Inventario> inventarios,
})

// Arquivo
Future<String> uploadNotaFiscalImage({
  required String notaFiscalId,
  required Uint8List fileBytes,
  required String fileName,
})
Future<void> deleteNotaFiscalImage(String imageUrl)

// Lixeira
Future<List<Inventario>> getDeletedInventarios()
Future<void> restoreInventario(String backupId, String originalId)
Future<void> permanentlyDeleteInventario(String backupId)
```

### DatabaseHelperLicense
`lib/helpers/database_helper_license.dart`

```dart
Future<void> initializePredefinedLicenses()
Future<List<License>> getLicenses()
Future<List<License>> getLicensesByUf(String uf)
Future<License?> getLicenseById(String id)
Future<void> updateLicense(License license)
Future<void> deleteLicense(String id)

Future<String> uploadLicenseFile({
  required String licenseId,
  required String uf,
  required String licenseName,
  required Uint8List fileBytes,
  required String fileName,
})
Future<void> deleteLicenseFile(String fileUrl)

Future<List<License>> getDeletedLicenses()
Future<void> restoreLicense(String backupId, String originalId)
Future<void> permanentlyDeleteLicense(String backupId)
```

Licenças predefinidas: 8 para CE, 8 para SP

### Outros Helpers

**database_id_interno.dart**
```dart
Future<int> getNextInventarioInternalId()
```
Usa transação Firestore para IDs únicos

**database_reauth.dart**
Diálogo de reautenticação para operações sensíveis

**uf_helper.dart**
Utilitários para UFs brasileiras

## Modelos

### Inventario
`lib/models/inventario.dart`

```dart
class Inventario {
  String? id;
  int? internalId;
  String notaFiscalId;
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
}
```

### NotaFiscal
`lib/models/nota_fiscal.dart`

```dart
class NotaFiscal {
  String? id;
  String numeroNota;
  String fornecedor;
  DateTime dataCompra;
  double valorTotal;
  String? notaFiscalUrl;
  String? chaveAcesso;
  String uf;
  DateTime createdAt;
  String? createdBy;
}
```

### License
`lib/models/license.dart`

```dart
enum LicenseStatus { valida, vencida, proximoVencimento }

class License {
  final String? id;
  final String nome;
  final String uf;
  final LicenseStatus status;
  final String dataInicio;
  final String dataVencimento;
  final String? arquivoUrl;
  final String? arquivoNome;
  final DateTime? arquivoUploadData;
  final String? ultimoAtualizadoPor;
  final DateTime? ultimaAtualizacao;
  
  static LicenseStatus calculateStatus(String dataVencimento)
}
```

Formato de data: DD-MM-YYYY

### UserRole
`lib/models/user_role.dart`

```dart
class UserRole {
  final String email;
  final String uf;
  final bool isAdmin;
  final bool isOperator;
  final bool active;
  final bool testAccess;
  final bool requestAccess;
  final bool reportAccess;
  final String displayName;
}
```

### AuditLog
`lib/models/audit_log.dart`

```dart
enum LogAction {
  create, update, delete, restore, view,
  export, login, logout, duplicate, backup,
}

enum LogModule { avaria, inventario, user, system }

class AuditLog {
  final String? id;
  final String userId;
  final String userEmail;
  final String? userDisplayName;
  final String uf;
  final bool isAdmin;
  final LogAction action;
  final LogModule module;
  final String? recordId;
  final String? recordIdentifier;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
```

### EmailLog
`lib/models/email_log.dart`

```dart
class EmailLog {
  final String? id;
  final String type; // warning, expired
  final String recipient;
  final String status; // sent, failed
  final DateTime sentAt;
  final Map<String, dynamic> licenseData;
  final String? error;
}
```

## Utilitários

### AuthWrapper
`lib/core/utilities/auth/auth_wrapper.dart`

Valida requisitos de acesso: requireAdmin, requireOperator, requireTestAccess

### ActivityWrapper
`lib/core/utilities/auth/activity_wrapper.dart`

Rastreia atividade do usuário

### Design System
`lib/core/design_system.dart`

Tokens de design: cores, tipografia, espaçamentos, bordas, sombras

### Notificações

```dart
SnackBarUtils.showSuccess(context, message)
SnackBarUtils.showError(context, message)
SnackBarUtils.showInfo(context, message)
DialogUtils.showConfirmDialog(context, title, message)
```

### Exportação Excel
`lib/core/utilities/excel/inventario_excel.dart`

```dart
Future<void> handleInventarioV2Export({
  required BuildContext context,
  required List<Inventario> filteredItems,
  required Map<String, NotaFiscal> notaFiscalMap,
})
```

## Cloud Functions

**cleanupAuditLogs**
`functions/index.js`

Remove logs > 1 ano. Execução: domingo 2:00 AM (America/Sao_Paulo)

## Fluxos

**Primeiro Login:**
Login → isFirstLogin() → FirstLoginScreen → nova senha → markFirstLoginComplete() → auditoria → home

**Criação Inventário:**
Formulário → valida duplicata → gera internalId → createNotaFiscalWithInventarios() → upload imagem → auditoria

**Atualização Licença:**
Edição → upload arquivo → calculateStatus() → update Firestore → auditoria → email (se vencida)

**Reversão:**
Auditoria → seleciona log → revertChange() → restaura dados → auditoria reversão

## Segurança

**Permissões:**
- Validação via UserRoleService em toda ação
- Operadores: apenas sua UF
- Admins: todas UFs

**Inatividade:**
Logout após 2 horas via ActivityTracker

**Auditoria:**
- Registro automático de toda ação CRUD
- Collection imutável (apenas inserção)
- oldData/newData para rastreabilidade

**Backup:**
Soft delete em collections de backup antes de exclusão

## Performance

**Cache:** UserRoleService mantém papel em memória

**Paginação:** 25 logs (auditoria), lazy loading (inventário)

**Índices:** Firestore sugere índices para queries compostas

## Erros Comuns

```
Exception: Já existe uma Nota Fiscal com o número X para o UF Y
Exception: User does not have required permissions
Exception: File size exceeds 10MB limit
Exception: User session has expired due to inactivity
```
