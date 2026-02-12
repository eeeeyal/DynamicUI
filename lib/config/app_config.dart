/// App configuration constants
class AppConfig {
  // Default ZIP URL (can be overridden)
  static const String defaultZipUrl = 'https://your-server.com/api/app/config.zip';
  
  // Cache settings
  static const Duration cacheExpiration = Duration(days: 7);
  
  // Network settings
  static const Duration requestTimeout = Duration(seconds: 30);
}


