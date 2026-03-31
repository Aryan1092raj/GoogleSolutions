import 'package:flutter/foundation.dart';

class DashboardConstants {
  static String get backendBaseUrl {
    const configured = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8080';
      }
    }

    return 'https://resqlink-backend-xxxx-uc.a.run.app';
  }

  static const String firebaseRtdbUrl = 'https://resqlink-prod-default-rtdb.firebaseio.com';
}
