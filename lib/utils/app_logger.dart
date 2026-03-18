// Basit structured logger — sadece debug modda çıktı verir
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String tag, String message) {
    if (kDebugMode) debugPrint('ℹ️ [$tag] $message');
  }

  static void warning(String tag, String message) {
    if (kDebugMode) debugPrint('⚠️ [$tag] $message');
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [$tag] $message');
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }
}
