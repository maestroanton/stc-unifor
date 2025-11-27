// Utilitário de arquivos
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/core/design_system.dart';

class FileHandler {
  /// Regex para prefixos de timestamp em nomes de arquivo (ex.: "1234567890_")
  static final RegExp timestampPattern = RegExp(r'^\d+_');

  /// Retorna ícone conforme extensão
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive_outlined;
      case 'txt':
      case 'md':
        return Icons.text_snippet_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_outlined;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Retorna cor conforme extensão
  static Color getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE53E3E);
      case 'doc':
      case 'docx':
        return const Color(0xFF1976D2);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF388E3C);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return const Color(0xFF7B1FA2);
      case 'mp3':
      case 'wav':
      case 'flac':
        return const Color(0xFFFF9800);
      case 'mp4':
      case 'avi':
      case 'mov':
        return const Color(0xFF4CAF50);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFF795548);
      case 'txt':
      case 'md':
        return AppDesignSystem.neutral600;
      default:
        return AppDesignSystem.neutral400;
    }
  }

  /// Extrai nome de arquivo a partir da URL do Firebase Storage
  static String extractFilenameFromFirebaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Método 1: extrai de segmentos do path após 'o'
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final encodedPath = pathSegments[oIndex + 1];

        try {
          // Decodifica caminho codificado na URL
          final decodedPath = Uri.decodeComponent(encodedPath);

          // Extrai nome do arquivo do caminho
          String filename = _extractFilenameFromPath(decodedPath);

          if (filename.isNotEmpty && filename != 'unknown') {
            return filename;
          }
        } catch (e) {
          // Ignora erros de decodificação
        }
      }

      // Método 2: tenta parâmetros de consulta como 'token'
      final queryParams = uri.queryParameters;
      if (queryParams.containsKey('token')) {
        // Às vezes o nome do arquivo está embutido no token ou em query params
        for (final key in queryParams.keys) {
          final value = queryParams[key]!;
          if (value.contains('/')) {
            String filename = _extractFilenameFromPath(value);
            if (filename.isNotEmpty && filename != 'unknown') {
              return filename;
            }
          }
        }
      }

      // Método 3: tenta extrair do caminho completo da URL
      try {
        String fullPath = uri.path;
        if (fullPath.contains('/o/')) {
          String afterO = fullPath.split('/o/')[1];
          String decodedAfterO = Uri.decodeComponent(afterO);
          String filename = _extractFilenameFromPath(decodedAfterO);

          if (filename.isNotEmpty && filename != 'unknown') {
            return filename;
          }
        }
      } catch (e) {
        // Ignora erros
      }

      // Fallback: retorna nome genérico
      return 'arquivo_anexo.pdf';
    } catch (e) {
      return 'arquivo_anexo.pdf';
    }
  }

  /// Extrai apenas o nome do arquivo a partir de um caminho completo
  static String _extractFilenameFromPath(String fullPath) {
    try {
      final pathParts = fullPath.split('/');
      if (pathParts.isEmpty) return 'unknown';

      String potentialFilename = pathParts.last;

      // Remove parâmetros de query se estiverem misturados
      if (potentialFilename.contains('?')) {
        potentialFilename = potentialFilename.split('?')[0];
      }

      // Remove prefixo de timestamp se presente (ex.: "123_filename.pdf" -> "filename.pdf")
      if (FileHandler.timestampPattern.hasMatch(potentialFilename)) {
        potentialFilename = potentialFilename.replaceFirst(
          FileHandler.timestampPattern,
          '',
        );
      }

      // Valida se parece um nome de arquivo válido
      if (potentialFilename.isEmpty) {
        return 'unknown';
      }

      // Se não tiver extensão, adiciona padrão '.pdf'
      if (!potentialFilename.contains('.')) {
        potentialFilename += '.pdf'; // extensão padrão
      }

      return potentialFilename;
    } catch (e) {
      return 'unknown';
    }
  }

  /// Retorna a extensão do arquivo a partir do nome
  static String getFileExtensionFromFileName(String fileName) {
    try {
      if (fileName.contains('.')) {
        final parts = fileName.split('.');
        if (parts.length > 1) {
          return parts.last.toLowerCase();
        }
      }
      return 'file';
    } catch (e) {
      return 'file';
    }
  }

  /// Cria um nome de arquivo seguro para geração de ID único
  static String createSafeFilename(String originalUrl) {
    try {
      String filename = extractFilenameFromFirebaseUrl(originalUrl);

      // Substitui caracteres que podem causar problemas em IDs únicos
      filename = filename.replaceAll(RegExp(r'[^\w\.-]'), '_');

      // Garante que o nome não seja muito longo
      if (filename.length > 100) {
        final extension = getFileExtensionFromFileName(filename);
        filename = '${filename.substring(0, 90)}_shortened.$extension';
      }

      return filename;
    } catch (e) {
      return 'safe_filename.pdf';
    }
  }

  /// Método de debug para analisar a estrutura da URL do Firebase
  static Map<String, String> debugFirebaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final debug = <String, String>{
        'host': uri.host,
        'path': uri.path,
        'pathSegments': uri.pathSegments.join(' | '),
        'queryParameters': uri.queryParameters.entries
            .map((e) => '$e.key=$e.value')
            .join(' & '),
      };

      final oIndex = uri.pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < uri.pathSegments.length) {
        final encodedPath = uri.pathSegments[oIndex + 1];
        try {
          debug['decodedOPath'] = Uri.decodeComponent(encodedPath);
        } catch (e) {
          debug['decodedOPath'] = 'DECODE_ERROR: $e';
        }
      }

      return debug;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Utilitários adicionais

  /// Limpa nome do arquivo removendo timestamps e artefatos
  static String getCleanFilename(String rawFilename) {
    try {
      String cleaned = rawFilename;

      // Remove prefixos de timestamp (p.ex.: "1234567890_filename.pdf" -> "filename.pdf")
      if (FileHandler.timestampPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(FileHandler.timestampPattern, '');
      }

      // Se começar com "request_" ou conter padrão de requestId, extrai o nome real
      if (cleaned.startsWith('request_')) {
        // Padrão: request_{requestId}_{nomeDoArquivo}
        final parts = cleaned.split('_');
        if (parts.length >= 3) {
          cleaned = parts.sublist(2).join('_');
        }
      }

      // Remove artefatos remanescentes como "anexo_qtga6a_"
      final anexoPattern = RegExp(r'^anexo_[a-zA-Z0-9]+_');
      if (anexoPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(anexoPattern, '');
      }

      // Garante nome válido com extensão
      if (cleaned.isEmpty || !cleaned.contains('.')) {
        cleaned = rawFilename; // Retorna ao nome original se limpeza falhar
      }

      return cleaned;
    } catch (e) {
      return rawFilename; // Retorna o nome original em caso de erro
    }
  }

  /// Sugere extensão com base em padrões da URL
  static String guessExtensionFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('pdf')) return 'pdf';
    if (lowerUrl.contains('doc')) return 'docx';
    if (lowerUrl.contains('xls')) return 'xlsx';
    if (lowerUrl.contains('jpg') || lowerUrl.contains('jpeg')) return 'jpg';
    if (lowerUrl.contains('png')) return 'png';
    return 'pdf';
  }

  /// Estima tamanho do arquivo com base na URL
  static int estimateFileSize(String url) {
    final fileName = url.split('/').last.split('?').first.toLowerCase();
    if (fileName.endsWith('.pdf')) return 150000;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return 100000;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) return 250000;
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) return 80000;
    return 120000;
  }

  /// Formata tamanho do arquivo para exibição
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Color getProcessingStateColor(String state) {
    if (state.toLowerCase().contains('negado') ||
        state.toLowerCase().contains('denied')) {
      return AppDesignSystem.error;
    }
    if (state.toLowerCase().contains('pendente') ||
        state.toLowerCase().contains('pending')) {
      return AppDesignSystem.warning;
    }
    if (state.toLowerCase().contains('sanitizado') ||
        state.toLowerCase().contains('sanitized')) {
      return AppDesignSystem.info;
    }
    if (state.toLowerCase().contains('análise') ||
        state.toLowerCase().contains('review')) {
      return AppDesignSystem.info;
    }
    if (state.toLowerCase().contains('disponível') ||
        state.toLowerCase().contains('available') ||
        state.toLowerCase().contains('comentário')) {
      return AppDesignSystem.success;
    }
    return AppDesignSystem.neutral600;
  }
}

class FirebaseStorageUtils {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Verifica se a URL é visualizável (possui parâmetros para visualização direta)
  static bool isUrlViewable(String url) {
    try {
      final uri = Uri.parse(url);

      // Verifica parâmetros necessários para URLs visualizáveis
      final hasToken = uri.queryParameters.containsKey('token');
      final hasAltMedia = uri.queryParameters['alt'] == 'media';

      return hasToken && hasAltMedia;
    } catch (e) {
      return false;
    }
  }

  /// Torna uma URL visualizável garantindo os parâmetros necessários
  static String makeUrlViewable(String url) {
    try {
      final uri = Uri.parse(url);

      // Se já for visualizável, retorna como está
      if (isUrlViewable(url)) {
        return url;
      }

      // Adiciona ou atualiza parâmetros de query para torná-la visualizável
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['alt'] = 'media';

      // Se não houver token, pode ser necessário obter uma URL nova do Firebase
      if (!queryParams.containsKey('token')) {}

      final newUri = uri.replace(queryParameters: queryParams);
      return newUri.toString();
    } catch (e) {
      return url; // Retorna a URL original se o processamento falhar
    }
  }

  /// Extrai o caminho do arquivo a partir da URL do Firebase Storage
  static String? extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Trata vários formatos de URL do Firebase Storage
      if (uri.host.contains('googleapis.com')) {
        // Exemplo de formato: https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile?...
        final pathSegments = uri.pathSegments;
        final oIndex = pathSegments.indexOf('o');

        if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
          final encodedPath = pathSegments[oIndex + 1];
          return Uri.decodeComponent(encodedPath);
        }
      } else if (uri.host.contains('firebaseapp.com')) {
        // Trata formatos alternativos de URL do Firebase Storage
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          return pathSegments.join('/');
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtém uma download URL atualizada para um caminho de arquivo
  static Future<String> getFreshDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to generate fresh download URL: $e');
    }
  }

  /// Testa se uma URL é acessível
  static Future<Map<String, dynamic>> testUrlAccess(String url) async {
    try {
      // Teste básico; em um app real, pode ser necessária uma requisição HTTP
      final uri = Uri.parse(url);

      final result = {
        'url': url,
        'scheme': uri.scheme,
        'host': uri.host,
        'hasToken': uri.queryParameters.containsKey('token'),
        'hasAltMedia': uri.queryParameters['alt'] == 'media',
        'isValid': uri.isAbsolute && uri.scheme.startsWith('http'),
        'error': null,
      };

      if (!(result['isValid'] as bool)) {
        result['error'] = 'Invalid URL format';
      }

      return result;
    } catch (e) {
      return {'url': url, 'error': e.toString(), 'isValid': false};
    }
  }

  /// Extração de nome de arquivo com tratamento de erros aprimorado
  static String extractFilenameFromUrl(String url) {
    try {
      // Primeiro, tenta a extração padrão
      final result = _standardFilenameExtraction(url);
      if (result != null && result.isNotEmpty && result != 'unknown') {
        return result;
      }

      // Fallback: usa o método alternativo
      return _alternativeFilenameExtraction(url);
    } catch (e) {
      return 'unknown_file';
    }
  }

  /// Método padrão de extração de nome de arquivo
  static String? _standardFilenameExtraction(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Trata URLs do Firebase Storage
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final encodedPath = pathSegments[oIndex + 1];
        final decodedPath = Uri.decodeComponent(encodedPath);
        final pathParts = decodedPath.split('/');

        if (pathParts.isNotEmpty) {
          String fileName = pathParts.last;

          // Remove prefixo de timestamp, se presente
          if (FileHandler.timestampPattern.hasMatch(fileName)) {
            fileName = fileName.replaceFirst(FileHandler.timestampPattern, '');
          }

          return fileName.isNotEmpty ? fileName : null;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Método alternativo de extração de nome de arquivo
  static String _alternativeFilenameExtraction(String url) {
    try {
      // Remove parâmetros de query
      final baseUrl = url.split('?')[0];

      // Tenta diferentes formas de decodificação
      String decodedUrl;
      try {
        decodedUrl = Uri.decodeFull(baseUrl);
      } catch (e) {
        // Se a decodificação completa falhar, tenta decodificar componentes
        try {
          decodedUrl = Uri.decodeComponent(baseUrl);
        } catch (e2) {
          // Se ambas as decodificações falharem, usa a URL original
          decodedUrl = baseUrl;
        }
      }

      // Extrai o nome do arquivo a partir do caminho
      final pathParts = decodedUrl.split('/');
      if (pathParts.isNotEmpty) {
        String filename = pathParts.last;

        // Trata separadores de caminho codificados
        if (filename.contains('%2F')) {
          final parts = filename.split('%2F');
          filename = parts.last;
        }

        // Remove prefixos de timestamp
        if (FileHandler.timestampPattern.hasMatch(filename)) {
          filename = filename.replaceFirst(FileHandler.timestampPattern, '');
        }

        // Garante que temos um nome de arquivo válido
        if (filename.isNotEmpty && filename != 'o') {
          return filename;
        }
      }

      // Último recurso: tenta extrair de parâmetros de query
      final uri = Uri.parse(url);
      final pathParam = uri.queryParameters['path'];
      if (pathParam != null && pathParam.contains('/')) {
        return pathParam.split('/').last;
      }

      return 'unknown_file';
    } catch (e) {
      return 'unknown_file';
    }
  }

  /// Decodifica com segurança um componente codificado da URL
  static String safeDecodeComponent(String encoded) {
    try {
      return Uri.decodeComponent(encoded);
    } catch (e) {
      // Tenta decodificação manual para casos comuns
      return encoded
          .replaceAll('%20', ' ')
          .replaceAll('%2F', '/')
          .replaceAll('%2B', '+')
          .replaceAll('%26', '&')
          .replaceAll('%3D', '=');
    }
  }

  /// Retorna a extensão do arquivo a partir da URL do Firebase Storage
  static String getFileExtensionFromUrl(String url) {
    try {
      final filename = extractFilenameFromUrl(url);

      if (filename.contains('.')) {
        return filename.split('.').last.toLowerCase();
      }

      // Fallback: tenta inferir a extensão pela URL
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.contains('pdf')) return 'pdf';
      if (lowerUrl.contains('doc')) return 'docx';
      if (lowerUrl.contains('xls')) return 'xlsx';
      if (lowerUrl.contains('jpg') || lowerUrl.contains('jpeg')) return 'jpg';
      if (lowerUrl.contains('png')) return 'png';

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Normaliza um nome de arquivo para fins de comparação
  static String normalizeFilename(String filename) {
    return filename
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_') // Substitui espaços por underscores
        .replaceAll(
          RegExp(r'[^\w\-_\.]'),
          '',
        ) // Remove caracteres especiais exceto traço, underscore e ponto
        .replaceAll(RegExp(r'_+'), '_') // Agrupa múltiplos underscores
        .replaceAll(RegExp(r'^_+|_+$'), ''); // Remove underscores no início/fim
  }

  /// Verifica se dois nomes de arquivo são equivalentes (considerando diferenças de codificação)
  static bool areFilenamesEquivalent(String filename1, String filename2) {
    try {
      // Comparação direta
      if (filename1 == filename2) return true;

      // Comparação normalizada
      final norm1 = normalizeFilename(filename1);
      final norm2 = normalizeFilename(filename2);
      if (norm1 == norm2) return true;

      // Compara sem extensões
      final base1 = filename1.split('.').first;
      final base2 = filename2.split('.').first;
      if (normalizeFilename(base1) == normalizeFilename(base2)) return true;

      // Compara após decodificação de URL
      try {
        final decoded1 = Uri.decodeComponent(filename1);
        final decoded2 = Uri.decodeComponent(filename2);
        if (normalizeFilename(decoded1) == normalizeFilename(decoded2)) {
          return true;
        }
      } catch (e) {
        // Ignora erros de decodificação
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Métodos de extensão de `Reference` para obter URLs visualizáveis
extension ReferenceExtensions on Reference {
  /// Retorna uma download URL adequada para visualização no navegador
  Future<String> getViewableDownloadURL() async {
    try {
      final url = await getDownloadURL();
      return FirebaseStorageUtils.makeUrlViewable(url);
    } catch (e) {
      rethrow;
    }
  }
}
