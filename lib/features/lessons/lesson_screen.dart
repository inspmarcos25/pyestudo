import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/theme/duo_theme.dart';
import '../../core/theme/editor_syntax_theme.dart';
import '../../core/theme/ide_theme.dart';
import '../../data/models/models.dart';

/// Lição na linguagem visual Duo: cabeçalho na cor da unidade, texto com
/// tipografia de leitura confortável e exemplo com destaque de sintaxe real
/// (o mesmo do editor, em modo somente leitura).
class LessonScreen extends StatelessWidget {
  final Lesson lesson;
  final Chapter chapter;
  final VoidCallback onOpenExample;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.chapter,
    required this.onOpenExample,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final unit = duoUnitColorFor(chapter.order);
    final strings = AppStrings.of(LocaleScope.of(context).language);
    return Scaffold(
      backgroundColor: duo.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: duo.muted,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.lessonWordUpper} · '
                          '${strings.chapterWordUpper} ${chapter.order}',
                          style: DuoText.eyebrow.copyWith(color: unit.main),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DuoText.title.copyWith(color: duo.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: duo.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: duo.border, width: 2),
                    ),
                    child: Text(
                      lesson.body,
                      style: DuoText.body.copyWith(
                        color: duo.text,
                        fontSize: 16,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ExampleCode(code: lesson.example),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DuoButton3D(
                color: unit.main,
                shadowColor: unit.shadow,
                depth: 5,
                onTap: () {
                  Navigator.pop(context);
                  onOpenExample();
                },
                semanticsLabel: strings.openInEditor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.openInEditor.toUpperCase(),
                        style: DuoText.eyebrow.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemplo comentado com o mesmo destaque de sintaxe do editor, somente
/// leitura (seleção/cópia continuam funcionando).
class _ExampleCode extends StatefulWidget {
  final String code;

  const _ExampleCode({required this.code});

  @override
  State<_ExampleCode> createState() => _ExampleCodeState();
}

class _ExampleCodeState extends State<_ExampleCode> {
  late final CodeController _controller = CodeController(
    text: widget.code,
    language: python,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: IdeColors.of(context).codeBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: duo.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: CodeTheme(
        data: CodeThemeData(
          styles: vsCodeThemeFor(Theme.of(context).brightness),
        ),
        child: CodeField(
          controller: _controller,
          readOnly: true,
          textStyle: codeTextStyle.copyWith(fontSize: 14),
          gutterStyle: const GutterStyle(
            showLineNumbers: false,
            showErrors: false,
            showFoldingHandles: false,
          ),
        ),
      ),
    );
  }
}
