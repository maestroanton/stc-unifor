# Arquitetura do Sistema GISTC

## Visão Geral

Aplicação web Flutter com Firebase backend. Padrão de camadas: apresentação, lógica de negócio, persistência.

## Stack Tecnológico

**Frontend:** Flutter (Dart), StatefulWidget, Material Design

**Backend:** Firebase Authentication, Cloud Firestore, Firebase Storage, Cloud Functions (Node.js)

**Externo:** EmailJS

## Estrutura do Projeto

```
lib/
├── core/                  # Componentes centralizados
│   ├── design_system.dart
│   ├── utilities/auth/    # AuthWrapper, ActivityWrapper
│   ├── utilities/excel/   # Exportação
│   └── visuals/           # Diálogos, snackbar
├── helpers/               # Acesso a dados (CRUD)
│   ├── database_helper_inventario.dart
│   ├── database_helper_license.dart
│   └── database_id_interno.dart
├── models/                # Estruturas de dados
│   ├── inventario.dart
│   ├── license.dart
│   ├── nota_fiscal.dart
│   ├── user_role.dart
│   └── audit_log.dart
├── modules/               # Telas
│   ├── admin/
│   ├── inventario/
│   └── licenses/
└── services/              # Lógica de negócio
    ├── audit_log.dart
    ├── user_role.dart
    ├── first_login.dart
    ├── license_email.dart
    └── activity_tracker.dart

functions/                 # Cloud Functions
android/ios/web/          # Plataformas
```

## Camadas

**Apresentação (modules/):** UI, páginas, diálogos, formulários

**Lógica de Negócio (services/):** AuditLogService, UserRoleService, FirstLoginService, LicenseEmailService, ActivityTracker, CsvImportService

**Acesso a Dados (helpers/):** CRUD Firestore. Padrão Singleton:
```dart
class DatabaseHelperInventario {
  static final _instance = DatabaseHelperInventario._internal();
  factory DatabaseHelperInventario() => _instance;
  
  Future<List<Inventario>> getInventarios() { ... }
  Future<String> createInventario(Inventario item) { ... }
}
```

**Modelos (models/):** Inventario, NotaFiscal, License, UserRole, AuditLog, EmailLog

**Utilitários (core/):** AuthWrapper, ActivityWrapper, DesignSystem, SnackBarUtils, DialogUtils, ExcelExport

## Fluxo de Dados

**Autenticação:** LoginPage → Firebase Auth → AuthWrapper → FirstLoginService → FirstLoginScreen → HomeSelection

**CRUD:** Form → DatabaseHelper.create() → Firestore → AuditLogService.log() → audit_logs

**Busca:** ListPage → FilterService → DatabaseHelper.get() → local filter/sort → View

**Auditoria:** Ação → AuditLogService.logAction() → Firestore → CloudFunction cleanup (1 ano)

## Firestore

**inventarios:** internalId, notaFiscalId, produto, descricao, valor, dataDeGarantia, numeroDeSerie, estado, tipo, localizacao, uf, observacoes

**notas_fiscais:** numeroNota, uf, dataCompra, fornecedor, valorTotal, chaveAcesso, arquivoUrl

**licenses:** nome, uf, status (valida/proximoVencimento/vencida), dataInicio, dataVencimento, arquivoUrl, arquivoNome, ultimoAtualizadoPor

**user_roles:** email (ID), uf, displayName, isAdmin, isOperator, active, testAccess, requestAccess, reportAccess

**audit_logs:** userId, userEmail, uf, isAdmin, action, module, recordId, recordIdentifier, oldData, newData, timestamp, metadata (retenção: 1 ano)

**email_logs:** type, status (sent/failed), recipientEmail, timestamp

**Backup:** inventarios_backup, notas_fiscais_backup, licenses_backup (soft delete)

## Storage

```
licenses/{UF}/{nome_licenca}/
inventarios/{notaFiscalId}/
```

Tipos: PDF, JPG, JPEG, PNG, WEBP (limite 10MB)

## Cloud Functions

**cleanupAuditLogs:** Remove logs > 1 ano. Execução: domingo 2:00 AM (America/Fortaleza)

## Segurança

**Autenticação:** Firebase Auth (email/senha), sessão automática, primeiro login obrigatório

**Autorização:**
- Usuário Básico: acesso limitado
- Operador: inventário + licenças
- Administrador: acesso completo

AuthWrapper valida antes de renderizar

**Segregação UF:** Operadores veem apenas sua UF, admins cross-UF (UserRoleService.hasUfAccess)

**Proteção:** HTTPS, Security Rules, sanitização de dados sensíveis, validação de input

**Auditoria:** Registro automático, logs imutáveis, retenção 1 ano

## Performance

**Cache:** UserRoleService mantém papel em memória

**Índices:** Queries compostas com índices Firestore (ex: where('uf').orderBy('dataCompra'))

**Paginação:** 25 logs (auditoria), 10 grupos (inventário)

**Lazy Loading:** Dashboard carrega sob demanda

## Padrões de Código

**Singleton:**
```dart
class Service {
  static final _instance = Service._internal();
  factory Service() => _instance;
  Service._internal();
}
```

**Factory Constructor:**
```dart
factory Model.fromMap(Map<String, dynamic> map, String id) {
  return Model(id: id, field: map['field'] ?? '');
}
```

**Async/Await:**
```dart
Future<void> _load() async {
  final data = await Helper().get();
  setState(() => _data = data);
}
```

**StatefulWidget:** initState() + dispose()

## Nova Feature

1. Modelo em models/
2. Helper em helpers/ (CRUD)
3. Service em services/ (lógica)
4. Page em modules/
5. Registrar auditoria

## Dependências

firebase_core, firebase_auth, cloud_firestore, firebase_storage, intl, excel, file_picker, url_launcher, logger, mask_text_input_formatter, dropdown_button2, csv

## Notas

**Decisões:**
- OCR/DeepSeek descartados (complexidade vs benefício)
- Soft delete com backup
- Logs imutáveis
- Cache de papéis

**Limitações:**
- Sem offline-first
- Sem sync tempo real