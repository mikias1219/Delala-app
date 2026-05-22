class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
  });

  /// Override with `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1` for Android emulator.
  static const AppConfig development = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    ),
  );

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
