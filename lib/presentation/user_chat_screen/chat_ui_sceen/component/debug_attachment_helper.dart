import 'dart:io';
import 'package:flutter/foundation.dart';

class DebugAttachmentHelper {
  static void logFileInfo(File file, String context) {
    if (kDebugMode) {
      try {
        debugPrint('=== $context ===');
        debugPrint('File path: ${file.path}');

        bool exists = false;
        try {
          exists = file.existsSync();
        } catch (e) {
          debugPrint('Error checking if file exists: $e');
        }

        debugPrint('File exists: $exists');

        if (exists) {
          try {
            final stats = file.statSync();
            debugPrint('File size: ${stats.size} bytes');
            debugPrint('Modified: ${stats.modified}');
            debugPrint('Type: ${stats.type.toString()}');
          } catch (e) {
            debugPrint('Error getting file stats: $e');
          }
        }
        debugPrint('===============');
      } catch (e) {
        debugPrint('=== ERROR LOGGING FILE INFO ===');
        debugPrint('Error: $e');
        debugPrint('=============================');
      }
    }
  }

  static void logImageError(dynamic error, StackTrace? stackTrace, String context) {
    if (kDebugMode) {
      debugPrint('=== IMAGE ERROR: $context ===');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      debugPrint('==============================');
    }
  }

  static void logAttachmentFlow(String step, Map<String, dynamic> data) {
    if (kDebugMode) {
      try {
        debugPrint('🔗 ATTACHMENT FLOW: $step');
        data.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      } catch (e) {
        debugPrint('Error logging attachment flow: $e');
      }
    }
  }
}
