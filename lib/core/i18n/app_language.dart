import 'dart:ui' show PlatformDispatcher;

/// Idiomas suportados pelo app. O [code] é usado tanto na preferência salva
/// quanto para montar o `Locale` do MaterialApp e escolher o conjunto de
/// conteúdo (pasta assets/content/chapters/<code>/).
enum AppLanguage {
  pt('pt', 'Português', '🇧🇷'),
  en('en', 'English', '🇺🇸');

  const AppLanguage(this.code, this.label, this.flag);

  final String code;
  final String label;
  final String flag;

  static AppLanguage? fromCode(String? code) {
    for (final lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return null;
  }

  /// Idioma inicial quando o usuário ainda não escolheu: segue o idioma do
  /// aparelho, caindo em português (público original do app) se não for
  /// claramente inglês.
  static AppLanguage deviceDefault() {
    final device = PlatformDispatcher.instance.locale.languageCode;
    return device == 'en' ? AppLanguage.en : AppLanguage.pt;
  }
}
