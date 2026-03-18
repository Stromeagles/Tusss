/// Claude API yapılandırması.
/// API anahtarınızı buraya girin veya ortam değişkeninden okuyun.
/// UYARI: Gerçek anahtarı kaynak koduna gömmeyin; .env veya güvenli depolama kullanın.
class ApiConfig {
  /// Anthropic Console'dan aldığınız API anahtarını buraya yapıştırın:
  /// https://console.anthropic.com/settings/keys
  static const String anthropicApiKey = 'YOUR_API_KEY_HERE';

  static const String claudeModel = 'claude-haiku-4-5-20251001';
  static const String anthropicVersion = '2023-06-01';
  static const String anthropicBaseUrl =
      'https://api.anthropic.com/v1/messages';

  static bool get isConfigured =>
      anthropicApiKey.isNotEmpty && anthropicApiKey != 'YOUR_API_KEY_HERE';
}
