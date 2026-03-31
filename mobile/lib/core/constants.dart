class AppConstants { 
  static const String backendBaseUrl = String.fromEnvironment( 
    'BACKEND_BASE_URL', 
    defaultValue: 'http://localhost:8080', 
  ); 
 
  static const String wsUrl = String.fromEnvironment( 
    'WS_URL', 
    defaultValue: 'ws://localhost:8080/ws', 
  ); 
 
  static const int videoWidthPx = 640; 
  static const int videoHeightPx = 480; 
  static const int videoFps = 15; 
  static const int audioSampleRate = 16000; 
  static const int mediaChunkIntervalMs = 500; 
} 
