import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  Error: $error');
      if (stack != null) debugPrint('  Stack: $stack');
    }
  }

  static void sync(String message) {
    if (kDebugMode) debugPrint('[SYNC] $message');
  }
}
