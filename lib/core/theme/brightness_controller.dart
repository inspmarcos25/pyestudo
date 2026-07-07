import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de tema (claro/escuro), compartilhada por toda a árvore do
/// app. Precisa viver no MaterialApp (não só num Theme dentro do HomeShell)
/// porque rotas empurradas via Navigator.push (exercício, lição, diálogos)
/// ficam acima do HomeShell na árvore e não herdariam um Theme aplicado
/// só ali dentro.
class BrightnessController extends ChangeNotifier {
  final SharedPreferences prefs;
  static const _key = 'dark_mode';

  Brightness _brightness;

  BrightnessController(this.prefs)
    : _brightness = (prefs.getBool(_key) ?? true)
          ? Brightness.dark
          : Brightness.light;

  Brightness get brightness => _brightness;

  Future<void> toggle() async {
    _brightness = _brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    await prefs.setBool(_key, _brightness == Brightness.dark);
    notifyListeners();
  }
}
