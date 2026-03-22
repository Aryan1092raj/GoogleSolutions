class DashboardConstants { 
  static const String backendBaseUrl = String.fromEnvironment( 
    'BACKEND_BASE_URL', 
    defaultValue: 'https://resqlink-backend-xxxx-uc.a.run.app', 
  ); 
 
  static const String firebaseRtdbUrl = 'https://resqlink-prod-default-rtdb.firebaseio.com'; 
}
