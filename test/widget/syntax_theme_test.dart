import 'package:app_python/features/editor/code_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleCode =
    'def soma(a, b):\n'
    '    # comentário\n'
    '    return a + 10\n'
    "print(soma(1, 2), 'fim')\n";

/// Renderiza o editor sob o [theme] dado e devolve a cor de cada trecho
/// de texto (por substring) tal como o highlight.js realmente aplicou.
Future<Color? Function(String)> _renderAndCollectColors(
  WidgetTester tester,
  ThemeData theme,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: CodeEditorWidget(code: _sampleCode, onChanged: (_) {}),
      ),
    ),
  );
  await tester.pump();

  final colorsByText = <String, Color?>{};
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null && span.text!.trim().isNotEmpty) {
        colorsByText[span.text!.trim()] = span.style?.color;
      }
      span.children?.forEach(walk);
    }
  }

  for (final editable in tester.widgetList<EditableText>(
    find.byType(EditableText),
  )) {
    final state = tester.state<EditableTextState>(find.byWidget(editable));
    walk(state.buildTextSpan());
  }

  return (String needle) => colorsByText.entries
      .firstWhere(
        (e) => e.key.contains(needle),
        orElse: () => const MapEntry('', null),
      )
      .value;
}

void main() {
  testWidgets('editor aplica as cores do tema VS Code Dark+ no tema escuro', (
    tester,
  ) async {
    final colorOf = await _renderAndCollectColors(
      tester,
      ThemeData(brightness: Brightness.dark),
    );

    expect(
      colorOf('def'),
      const Color(0xFFC586C0),
      reason: 'palavra-chave rosa',
    );
    expect(
      colorOf('soma'),
      const Color(0xFFDCDCAA),
      reason: 'nome de função amarelo',
    );
    expect(
      colorOf('comentário'),
      const Color(0xFF6A9955),
      reason: 'comentário verde',
    );
    expect(
      colorOf('10'),
      const Color(0xFFB5CEA8),
      reason: 'número verde-claro',
    );
    expect(colorOf("'fim'"), const Color(0xFFCE9178), reason: 'string laranja');
  });

  testWidgets('editor aplica as cores do tema VS Code Light+ no tema claro', (
    tester,
  ) async {
    final colorOf = await _renderAndCollectColors(
      tester,
      ThemeData(brightness: Brightness.light),
    );

    expect(
      colorOf('def'),
      const Color(0xFFAF00DB),
      reason: 'palavra-chave roxa (claro)',
    );
    expect(
      colorOf('soma'),
      const Color(0xFF795E26),
      reason: 'nome de função marrom (claro)',
    );
    expect(
      colorOf('comentário'),
      const Color(0xFF008000),
      reason: 'comentário verde (claro)',
    );
    expect(
      colorOf('10'),
      const Color(0xFF098658),
      reason: 'número verde (claro)',
    );
    expect(
      colorOf("'fim'"),
      const Color(0xFFA31515),
      reason: 'string vermelha (claro)',
    );
  });
}
