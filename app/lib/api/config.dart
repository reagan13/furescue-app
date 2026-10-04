/// Base URL of the FuRescue PHP server (no trailing slash).
///
/// Default is `adb reverse` (`http://127.0.0.1:8000`). For Wi-Fi:
/// `flutter run --dart-define=API_BASE_URL=http://<laptop-lan-ip>:8000`
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const ApiConfig current = ApiConfig(baseUrl: defaultBaseUrl);

  Uri resolve(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$suffix');
  }
}
