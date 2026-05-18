/// إعدادات التطبيق — تُمرَّر عند البناء عبر --dart-define
class AppConfig {
  /// عنوان خادم Flask (مثال إنتاج: https://yusr-api.onrender.com)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  static const String appName = 'يُسر';
}
