class AppConfig {
  static const String springBootBaseUrl = 'http://192.168.1.13:8080';
  static const String fastApiBaseUrl = 'http://192.168.1.13:8000';

  //10.0.2.2
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String tokenStorageKey = 'glumate_access_token';
  static const String userStorageKey = 'glumate_user_data';
}
