/// Runtime/environment configuration, per the integration guide's rule that
/// the API base URL must not be hard-coded and must be changeable without
/// touching application logic. Flutter's equivalent of a Vite `.env` value
/// is a compile-time `--dart-define`, supplied at build/run time:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
///               --dart-define=API_PATH=/api/analyze
///
/// See ../README.md for how to set this in Android Studio run configs too.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String apiPath = String.fromEnvironment(
    'API_PATH',
    defaultValue: '/webhook/api/v1/analyze',
  );

  static bool get isConfigured => apiBaseUrl.trim().isNotEmpty;
}
