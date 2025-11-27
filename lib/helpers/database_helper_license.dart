import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';

import '../models/audit_log.dart';
import '../models/license.dart';
import '../services/audit_log.dart';

class DatabaseHelperLicense {
  static final DatabaseHelperLicense _instance =
      DatabaseHelperLicense._internal();
  factory DatabaseHelperLicense() => _instance;
  DatabaseHelperLicense._internal();

  final Logger _logger = Logger();

  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'licenses',
  );
  final CollectionReference _backupCollection = FirebaseFirestore.instance
      .collection('licenses_backup');
  final AuditLogService _auditService = AuditLogService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Licenças predefinidas para cada UF
  static const Map<String, List<String>> predefinedLicenses = {
    'CE': [
      'ANTT',
      'Alvará de Funcionamento',
      'Apólice de Seguro RCF-DC',
      'Autorização Ambiental para Transporte de Produtos Perigosos',
      'Certificado de Regularidade do IBAMA',
      'Isenção de Registro Sanitário',
      'Licença do Corpo de Bombeiros',
      'Licença da Polícia Federal',
    ],
    'SP': [
      'ANTT',
      'Alvará de Funcionamento',
      'Apólice de Seguro RCTR-C',
      'Certificado de Regularidade',
      'Licença da Polícia Civil',
      'Licença da Polícia Federal',
      'Licença do Corpo de Bombeiros',
      'Licença do Exército',
    ],
  };

  /// Inicializa licenças predefinidas caso não existam
  Future<void> initializePredefinedLicenses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      for (final uf in predefinedLicenses.keys) {
        for (final licenseName in predefinedLicenses[uf]!) {
          // Verifica se a licença já existe
          final existingQuery = await _collection
              .where('nome', isEqualTo: licenseName)
              .where('uf', isEqualTo: uf)
              .limit(1)
              .get();

          if (existingQuery.docs.isEmpty) {
            // Cria licença padrão com datas vazias
            final defaultLicense = License(
              nome: licenseName,
              uf: uf,
              status: LicenseStatus.vencida,
              dataInicio: '',
              dataVencimento: '',
              ultimoAtualizadoPor: user.email,
              ultimaAtualizacao: DateTime.now(),
            );

            await _collection.add(defaultLicense.toMap());
          }
        }
      }
    } catch (e) {
      _logger.e('Error initializing predefined licenses: $e');
    }
  }

  /// Obter todas as licenças
  Future<List<License>> getLicenses() async {
    try {
      final querySnapshot = await _collection.orderBy('nome').get();
      final licenses = querySnapshot.docs
          .map(
            (doc) =>
                License.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Atualiza o status com base nas datas atuais
      final updatedLicenses = <License>[];
      for (final license in licenses) {
        if (license.dataVencimento.isNotEmpty) {
          final calculatedStatus = License.calculateStatus(
            license.dataVencimento,
          );
          if (calculatedStatus != license.status) {
            // Atualiza o status no banco de dados
            final updatedLicense = license.copyWith(status: calculatedStatus);
            await updateLicense(updatedLicense);
            updatedLicenses.add(updatedLicense);
          } else {
            updatedLicenses.add(license);
          }
        } else {
          updatedLicenses.add(license);
        }
      }

      return updatedLicenses;
    } catch (e) {
      _logger.e('Error getting licenses: $e');
      return [];
    }
  }

  /// Obter licenças por UF
  Future<List<License>> getLicensesByUf(String uf) async {
    try {
      final querySnapshot = await _collection
          .where('uf', isEqualTo: uf)
          .orderBy('nome')
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                License.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      _logger.e('Error getting licenses by UF: $e');
      return [];
    }
  }

  /// Obter licença por ID
  Future<License?> getLicenseById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;

      final license = License.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      // Registra a visualização
      await _auditService.logAction(
        action: LogAction.view,
        module:
            LogModule.system, // Você pode querer adicionar LogModule.license
        recordId: license.id!,
        recordIdentifier: '${license.uf} - ${license.nome}',
        description: 'Licença visualizada - ${license.uf}: ${license.nome}',
      );

      return license;
    } catch (e) {
      _logger.e('Error getting license by ID: $e');
      return null;
    }
  }

  /// Atualizar licença
  Future<void> updateLicense(
    License license, {
    bool skipAuditLog = false,
  }) async {
    if (license.id == null) {
      throw Exception('Cannot update License without an ID');
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Obtém os dados antigos para registro
      final oldDoc = await _collection.doc(license.id).get();
      final oldData = oldDoc.exists
          ? oldDoc.data() as Map<String, dynamic>
          : null;

      // Atualiza com usuário atual e timestamp
      final updatedLicense = license.copyWith(
        ultimoAtualizadoPor: user?.email,
        ultimaAtualizacao: DateTime.now(),
        status: license.dataVencimento.isNotEmpty
            ? License.calculateStatus(license.dataVencimento)
            : license.status,
      );

      await _collection.doc(license.id).update(updatedLicense.toMap());

      // Registra a atualização apenas se não for ignorada
      if (!skipAuditLog) {
        await _auditService.logAction(
          action: LogAction.update,
          module:
              LogModule.system, // Você pode querer adicionar LogModule.license
          recordId: license.id!,
          recordIdentifier: '${license.uf} - ${license.nome}',
          oldData: oldData ?? {},
          newData: updatedLicense.toMap(),
          description: 'Licença atualizada - ${license.uf}: ${license.nome}',
        );
      }
    } catch (e) {
      _logger.e('Error updating license: $e');
      rethrow;
    }
  }

  /// Envia arquivo e atualiza licença
  Future<void> uploadLicenseFile(
    String licenseId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Obtém a licença atual
      final license = await getLicenseById(licenseId);
      if (license == null) throw Exception('License not found');

      // Remove arquivo antigo, se existir
      if (license.arquivoUrl != null) {
        try {
          await _storage.refFromURL(license.arquivoUrl!).delete();
        } catch (e) {
          _logger.w('Warning: Could not delete old file: $e');
        }
      }

      final ref = _storage.ref().child(
        'licenses/${license.uf}/${license.nome}/$fileName',
      );
      final uploadTask = await ref.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'uploadedBy': user.email!,
            'licenseName': license.nome,
            'licenseUf': license.uf,
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Atualiza licença com informações do novo arquivo
      final updatedLicense = license.copyWith(
        arquivoUrl: downloadUrl,
        arquivoNome: fileName,
        arquivoUploadData: DateTime.now(),
        ultimoAtualizadoPor: user.email,
        ultimaAtualizacao: DateTime.now(),
      );

      await updateLicense(updatedLicense, skipAuditLog: true);

      // Registra no log o envio do arquivo
      await _auditService.logAction(
        action: LogAction.update,
        module: LogModule.system,
        recordId: licenseId,
        recordIdentifier: '${license.uf} - ${license.nome}',
        description:
            'Arquivo de licença enviado - ${license.uf}: ${license.nome}',
        metadata: {
          'fileName': fileName,
          'fileSize': fileBytes.length,
          'action': 'file_upload',
        },
      );
    } catch (e) {
      _logger.e('Error uploading license file: $e');
      rethrow;
    }
  }

  /// Excluir arquivo da licença
  Future<void> deleteLicenseFile(String licenseId) async {
    try {
      final license = await getLicenseById(licenseId);
      if (license == null) throw Exception('License not found');

      if (license.arquivoUrl != null) {
        // Exclui arquivo do storage
        await _storage.refFromURL(license.arquivoUrl!).delete();

        // Atualiza licença para remover informações do arquivo
        final updatedLicense = license.copyWith(
          arquivoUrl: null,
          arquivoNome: null,
          arquivoUploadData: null,
          ultimoAtualizadoPor: FirebaseAuth.instance.currentUser?.email,
          ultimaAtualizacao: DateTime.now(),
        );

        await updateLicense(updatedLicense, skipAuditLog: true);

        // Registra no log a exclusão do arquivo
        await _auditService.logAction(
          action: LogAction.delete,
          module: LogModule.system,
          recordId: licenseId,
          recordIdentifier: '${license.uf} - ${license.nome}',
          description:
              'Arquivo de licença removido - ${license.uf}: ${license.nome}',
          metadata: {
            'deletedFileName': license.arquivoNome,
            'action': 'file_delete',
          },
        );
      }
    } catch (e) {
      _logger.e('Error deleting license file: $e');
      rethrow;
    }
  }

  /// Obter estatísticas de licenças
  Future<Map<String, dynamic>> getLicenseStatistics() async {
    try {
      final licenses = await getLicenses();

      final stats = {
        'total': licenses.length,
        'validas': 0,
        'vencidas': 0,
        'proximoVencimento': 0,
        'comArquivo': 0,
        'semArquivo': 0,
        'porUf': <String, Map<String, int>>{},
      };

      for (final license in licenses) {
        // Atualiza contagem de status
        switch (license.status) {
          case LicenseStatus.valida:
            stats['validas'] = (stats['validas'] as int) + 1;
            break;
          case LicenseStatus.vencida:
            stats['vencidas'] = (stats['vencidas'] as int) + 1;
            break;
          case LicenseStatus.proximoVencimento:
            stats['proximoVencimento'] =
                (stats['proximoVencimento'] as int) + 1;
            break;
        }

        // Atualiza contagem de arquivos
        if (license.arquivoUrl != null) {
          stats['comArquivo'] = (stats['comArquivo'] as int) + 1;
        } else {
          stats['semArquivo'] = (stats['semArquivo'] as int) + 1;
        }

        // Atualiza estatísticas por UF
        final ufStats = (stats['porUf'] as Map<String, Map<String, int>>);
        if (!ufStats.containsKey(license.uf)) {
          ufStats[license.uf] = {
            'total': 0,
            'validas': 0,
            'vencidas': 0,
            'proximoVencimento': 0,
          };
        }
        ufStats[license.uf]!['total'] = ufStats[license.uf]!['total']! + 1;
        ufStats[license.uf]![license.status.name] =
            (ufStats[license.uf]![license.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      _logger.e('Error getting license statistics: $e');
      return {};
    }
  }

  /// Obter licenças expiradas e próximas do vencimento
  Future<List<License>> getExpiredAndExpiringLicenses() async {
    try {
      final licenses = await getLicenses();
      return licenses
          .where(
            (license) =>
                license.status == LicenseStatus.vencida ||
                license.status == LicenseStatus.proximoVencimento,
          )
          .toList();
    } catch (e) {
      _logger.e('Error getting expired/expiring licenses: $e');
      return [];
    }
  }

  /// Backup e exclusão de licença (apenas admin)
  Future<void> backupAndDeleteLicense(License license) async {
    if (license.id == null) return;

    try {
      final backupData = {
        ...license.toMap(),
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': FirebaseAuth.instance.currentUser?.email,
      };

      await _backupCollection.doc(license.id).set(backupData);
      await _collection.doc(license.id).delete();

      // Exclui arquivo associado, se existir
      if (license.arquivoUrl != null) {
        try {
          await _storage.refFromURL(license.arquivoUrl!).delete();
        } catch (e) {
          _logger.w('Warning: Could not delete file during backup: $e');
        }
      }

      // Registra no log a ação de backup
      await _auditService.logAction(
        action: LogAction.backup,
        module: LogModule.system,
        recordId: license.id!,
        recordIdentifier: '${license.uf} - ${license.nome}',
        oldData: license.toMap(),
        description:
            'Licença movida para backup - ${license.uf}: ${license.nome}',
      );
    } catch (e) {
      _logger.e('Error backing up and deleting license: $e');
      rethrow;
    }
  }
}
