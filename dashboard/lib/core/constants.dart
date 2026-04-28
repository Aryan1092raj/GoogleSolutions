import 'package:flutter/foundation.dart';

class DashboardConstants {
  static String get backendBaseUrl {
    const configured = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    final base = Uri.base;
    final host = base.host;

    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:8080';
    }

    if (kIsWeb) {
      return '${base.scheme}://${base.authority}';
    }

    return '';
  }
}
