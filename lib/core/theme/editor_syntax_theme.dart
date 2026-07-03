import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Brightness;

/// Tema de destaque de sintaxe no estilo VS Code Dark+ (Dark Modern).
///
/// Mapeia os escopos do highlight.js para as cores clássicas do VS Code:
/// palavras-chave rosa, funções amarelas, strings laranja, tipos teal,
/// números verde-claro e comentários verdes.
const vsCodeDarkPlusTheme = <String, TextStyle>{
  'root': TextStyle(
    backgroundColor: Color(0xFF1E1E1E),
    color: Color(0xFFD4D4D4),
  ),
  // import, def, return, if, for, in, as, not...
  'keyword': TextStyle(color: Color(0xFFC586C0)),
  // print, int, str, len, range...
  'built_in': TextStyle(color: Color(0xFF4EC9B0)),
  'type': TextStyle(color: Color(0xFF4EC9B0)),
  'class': TextStyle(color: Color(0xFF4EC9B0)),
  // True, False, None
  'literal': TextStyle(color: Color(0xFF569CD6)),
  'number': TextStyle(color: Color(0xFFB5CEA8)),
  'string': TextStyle(color: Color(0xFFCE9178)),
  // interpolação dentro de f-strings: {nome}
  'subst': TextStyle(color: Color(0xFF9CDCFE)),
  'comment': TextStyle(color: Color(0xFF6A9955)),
  // nome de função/classe logo após def/class
  'title': TextStyle(color: Color(0xFFDCDCAA)),
  'function': TextStyle(color: Color(0xFFDCDCAA)),
  // parâmetros de função
  'params': TextStyle(color: Color(0xFF9CDCFE)),
  'attr': TextStyle(color: Color(0xFF9CDCFE)),
  'variable': TextStyle(color: Color(0xFF9CDCFE)),
  'meta': TextStyle(color: Color(0xFF569CD6)),
  'operator': TextStyle(color: Color(0xFFD4D4D4)),
  'punctuation': TextStyle(color: Color(0xFFD4D4D4)),
};

/// Tema de destaque de sintaxe no estilo VS Code Light+ (mesmo mapeamento
/// de escopos, cores ajustadas para fundo claro mantendo contraste AA).
const vsCodeLightPlusTheme = <String, TextStyle>{
  'root': TextStyle(
    backgroundColor: Color(0xFFF3F3F3),
    color: Color(0xFF1E1E1E),
  ),
  'keyword': TextStyle(color: Color(0xFFAF00DB)),
  'built_in': TextStyle(color: Color(0xFF267F99)),
  'type': TextStyle(color: Color(0xFF267F99)),
  'class': TextStyle(color: Color(0xFF267F99)),
  'literal': TextStyle(color: Color(0xFF0000FF)),
  'number': TextStyle(color: Color(0xFF098658)),
  'string': TextStyle(color: Color(0xFFA31515)),
  'subst': TextStyle(color: Color(0xFF001080)),
  'comment': TextStyle(color: Color(0xFF008000)),
  'title': TextStyle(color: Color(0xFF795E26)),
  'function': TextStyle(color: Color(0xFF795E26)),
  'params': TextStyle(color: Color(0xFF001080)),
  'attr': TextStyle(color: Color(0xFF001080)),
  'variable': TextStyle(color: Color(0xFF001080)),
  'meta': TextStyle(color: Color(0xFF0000FF)),
  'operator': TextStyle(color: Color(0xFF1E1E1E)),
  'punctuation': TextStyle(color: Color(0xFF1E1E1E)),
};

Map<String, TextStyle> vsCodeThemeFor(Brightness brightness) =>
    brightness == Brightness.dark ? vsCodeDarkPlusTheme : vsCodeLightPlusTheme;
