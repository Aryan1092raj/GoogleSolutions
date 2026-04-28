class AppConstants {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String firebaseAppCheckWebSiteKey = String.fromEnvironment(
    'FIREBASE_APP_CHECK_WEB_SITE_KEY',
    defaultValue: '',
  );

  static String get wsUrl {
    const configured = String.fromEnvironment('WS_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    final backendUri = Uri.parse(backendBaseUrl);
    final wsScheme = backendUri.scheme == 'https' ? 'wss' : 'ws';
    return backendUri.replace(
      scheme: wsScheme,
      path: '/ws',
      queryParameters: null,
    ).toString();
  }

  static const int videoWidthPx = 640;
  static const int videoHeightPx = 480;
  static const int videoFps = 15;
  static const int audioSampleRate = 16000;
  static const int mediaChunkIntervalMs = 500;
}
