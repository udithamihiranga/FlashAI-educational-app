import 'dart:io';

/// PDFService handles PDF file operations.
class PDFService {
  static Future<String> extractText(String filePath) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return 'PDF text extraction is only available on Android and iOS devices.';
    }
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found');
      }
      return 'PDF text extraction requires integration with a PDF parsing library.';
    } catch (e) {
      throw Exception('Failed to process PDF: ');
    }
  }

  static Future<Map<String, dynamic>> getPDFInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'error': 'File not found'};
      }
      final stat = await file.stat();
      return {
        'fileName': filePath.split(Platform.pathSeparator).last,
        'fileSize': stat.size,
        'lastModified': stat.modified.toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static bool isPDF(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return extension == 'pdf';
  }
}
