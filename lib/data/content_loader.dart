import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'models/models.dart';

/// Carrega os capítulos dos JSON em assets/content/chapters/.
class ContentLoader {
  final AssetBundle bundle;

  ContentLoader({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  static const chapterFiles = [
    'assets/content/chapters/01_basico.json',
    'assets/content/chapters/02_controle.json',
    'assets/content/chapters/03_funcoes.json',
    'assets/content/chapters/04_bibliotecas.json',
  ];

  Future<List<Chapter>> loadChapters() async {
    final chapters = <Chapter>[];
    for (final path in chapterFiles) {
      final raw = await bundle.loadString(path);
      chapters.add(Chapter.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }
}
