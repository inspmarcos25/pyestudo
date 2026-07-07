import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../core/i18n/app_language.dart';
import 'models/models.dart';

/// Carrega os capítulos dos JSON em `assets/content/chapters/<idioma>/`.
class ContentLoader {
  final AssetBundle bundle;

  ContentLoader({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  /// Nomes dos arquivos (iguais em todos os idiomas; muda só a pasta).
  static const _fileNames = [
    '01_basico.json',
    '02_controle.json',
    '03_funcoes.json',
    '04_bibliotecas.json',
    '05_dicionarios.json',
    '06_erros.json',
    '07_arquivos.json',
  ];

  /// Carrega os capítulos de um idioma.
  Future<List<Chapter>> loadChapters([
    AppLanguage language = AppLanguage.pt,
  ]) async {
    final chapters = <Chapter>[];
    for (final name in _fileNames) {
      final path = 'assets/content/chapters/${language.code}/$name';
      final raw = await bundle.loadString(path);
      chapters.add(Chapter.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }

  /// Carrega os capítulos de todos os idiomas suportados, para permitir a
  /// troca de idioma em tempo real sem reler os assets.
  Future<Map<AppLanguage, List<Chapter>>> loadAllLanguages() async {
    return {
      for (final language in AppLanguage.values)
        language: await loadChapters(language),
    };
  }
}
