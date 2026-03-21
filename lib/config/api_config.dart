/// Claude API yapılandırması.
/// API anahtarı build zamanında --dart-define ile enjekte edilir:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///   flutter build web --dart-define=ANTHROPIC_API_KEY=sk-ant-...
class ApiConfig {
  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  static const String claudeModel = 'claude-haiku-4-5-20251001';
  static const String anthropicVersion = '2023-06-01';
  static const String anthropicBaseUrl =
      'https://api.anthropic.com/v1/messages';

  static bool get isConfigured => anthropicApiKey.isNotEmpty;
}
