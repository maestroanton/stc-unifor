import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilitário para operações de arquivo em diálogos
class DialogFileUtils {
  /// Formata tamanho do arquivo para formato legível
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Retorna ícone apropriado para a extensão do arquivo
  static String getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image';
      case 'doc':
      case 'docx':
        return 'description';
      case 'xls':
      case 'xlsx':
        return 'table_chart';
      default:
        return 'insert_drive_file';
    }
  }

  /// Valida extensão do arquivo
  static bool isValidExtension(
    String fileName,
    List<String> allowedExtensions,
  ) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Valida tamanho do arquivo
  static bool isValidSize(int fileSize, int maxSizeMB) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSize <= maxSizeBytes;
  }

  /// Abre URL do arquivo
  static Future<void> openFile(String url) async {
    try {
      final isPdf = url.toLowerCase().contains('.pdf');

      final viewUrl = isPdf
          ? 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}'
          : url;

      if (await canLaunchUrl(Uri.parse(viewUrl))) {
        await launchUrl(
          Uri.parse(viewUrl),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        throw 'Não foi possível abrir o arquivo';
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Seleciona arquivo com validação
  static Future<PlatformFile?> pickFile({
    required List<String> allowedExtensions,
    required int maxSizeMB,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Valida o tamanho do arquivo
        if (!isValidSize(file.size, maxSizeMB)) {
          throw 'Arquivo muito grande. Tamanho máximo: ${maxSizeMB}MB';
        }

        // Valida a extensão
        if (!isValidExtension(file.name, allowedExtensions)) {
          throw 'Tipo de arquivo não permitido. Permitidos: ${allowedExtensions.join(', ')}';
        }

        return file;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Obtém extensão do arquivo a partir do nome
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Verifica se o arquivo é uma imagem
  static bool isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    return imageExtensions.contains(getFileExtension(fileName));
  }

  /// Verifica se o arquivo é um PDF
  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  /// Retorna o tipo MIME do arquivo
  static String getMimeType(String fileName) {
    final extension = getFileExtension(fileName);
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
