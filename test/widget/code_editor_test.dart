import 'package:app_python/features/editor/code_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('editor exibe o código e propaga alterações', (tester) async {
    String? changed;
    final key = GlobalKey<CodeEditorWidgetState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            key: key,
            code: "print('oi')\nx = 1\n",
            onChanged: (code) => changed = code,
          ),
        ),
      ),
    );

    expect(find.textContaining("print('oi')"), findsWidgets);

    // moveCursorToLine posiciona o cursor no início da linha 2
    key.currentState!.moveCursorToLine(2);
    final selection = key.currentState!.controller.selection;
    expect(selection.baseOffset, "print('oi')\n".length);

    // alteração via controller dispara onChanged
    key.currentState!.controller.fullText = "print('novo')";
    expect(changed, "print('novo')");
  });
}
