import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/theme/editor_syntax_theme.dart';
import '../../core/theme/ide_theme.dart';

/// Editor de código com destaque de sintaxe Python e números de linha.
/// Sem autocomplete — nenhum popup de sugestão é habilitado.
class CodeEditorWidget extends StatefulWidget {
  final String code;
  final ValueChanged<String> onChanged;

  const CodeEditorWidget({
    super.key,
    required this.code,
    required this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => CodeEditorWidgetState();
}

class CodeEditorWidgetState extends State<CodeEditorWidget> {
  late final CodeController controller;

  @override
  void initState() {
    super.initState();
    controller = CodeController(text: widget.code, language: python);
    controller.addListener(() => widget.onChanged(controller.fullText));
  }

  @override
  void didUpdateWidget(covariant CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != oldWidget.code && widget.code != controller.fullText) {
      controller.fullText = widget.code;
    }
  }

  /// Posiciona o cursor no início da linha [line] (1-based) e foca o editor.
  void moveCursorToLine(int line) {
    final lines = controller.fullText.split('\n');
    final target = line.clamp(1, lines.length);
    final offset = lines
        .take(target - 1)
        .fold<int>(0, (sum, l) => sum + l.length + 1);
    controller.selection = TextSelection.collapsed(offset: offset);
    FocusScope.of(context).requestFocus();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.of(LocaleScope.languageOf(context)).codeEditorSemantics,
      textField: true,
      child: CodeTheme(
        data: CodeThemeData(
          styles: vsCodeThemeFor(Theme.of(context).brightness),
        ),
        child: SingleChildScrollView(
          child: CodeField(
            controller: controller,
            textStyle: codeTextStyle,
            gutterStyle: const GutterStyle(
              showLineNumbers: true,
              showErrors: false,
              showFoldingHandles: false,
            ),
          ),
        ),
      ),
    );
  }
}
