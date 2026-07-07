import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// Guarda o idioma escolhido e o persiste. Fica no topo da árvore (acima do
/// login), então tanto a tela de login quanto as telas logadas leem daqui.
class LocaleController extends ChangeNotifier {
  final SharedPreferences prefs;
  static const _key = 'app_language';

  AppLanguage _language;

  LocaleController(this.prefs)
    : _language =
          AppLanguage.fromCode(prefs.getString(_key)) ??
          AppLanguage.deviceDefault();

  AppLanguage get language => _language;

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    await prefs.setString(_key, language.code);
    notifyListeners();
  }
}

/// Disponibiliza o [LocaleController] para toda a subárvore. Widgets que
/// leem via [LocaleScope.of] são reconstruídos quando o idioma muda.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'Nenhum LocaleScope encontrado no contexto');
    return scope!.notifier!;
  }

  /// Idioma atual, com fallback para português quando não há [LocaleScope]
  /// no contexto (ex.: widgets montados isoladamente em testes).
  static AppLanguage languageOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleScope>();
    return scope?.notifier?.language ?? AppLanguage.pt;
  }
}
