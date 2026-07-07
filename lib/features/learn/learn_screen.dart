import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/duo_theme.dart';
import '../../data/models/models.dart';
import '../lessons/lesson_screen.dart';

/// Tela "Aprenda": lista os capítulos com suas lições, para o aluno estudar
/// antes de treinar em Exercícios. Cada lição abre a LessonScreen já
/// existente (corpo + exemplo comentado + "Abrir no editor").
class LearnScreen extends StatelessWidget {
  final AppState state;

  /// Chamado quando um exemplo é aberto no editor (troca para a aba Editor).
  final VoidCallback onOpenInEditor;

  const LearnScreen({
    super.key,
    required this.state,
    required this.onOpenInEditor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final duo = DuoColors.of(context);
        final strings = state.strings;
        return Scaffold(
          backgroundColor: duo.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    strings.learnTitle,
                    style: DuoText.display.copyWith(color: duo.text),
                  ),
                ),
                for (final chapter in state.chapters) ...[
                  const SizedBox(height: 16),
                  _ChapterCard(
                    chapter: chapter,
                    progress: state.chapterProgress(chapter),
                    strings: strings,
                    onOpenInEditor: onOpenInEditor,
                    state: state,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card de um capítulo: banner colorido (mesma linguagem visual do banner
/// de unidade em Exercícios) + lista das lições dentro dele.
class _ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final double progress;
  final AppStrings strings;
  final VoidCallback onOpenInEditor;
  final AppState state;

  const _ChapterCard({
    required this.chapter,
    required this.progress,
    required this.strings,
    required this.onOpenInEditor,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final unit = duoUnitColorFor(chapter.order);
    final percent = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: strings.chapterSemantics(
            chapter.order,
            chapter.title,
            chapter.difficulty,
            percent,
          ),
          child: DuoButton3D(
            color: unit.main,
            shadowColor: unit.shadow,
            borderRadius: BorderRadius.circular(18),
            depth: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.chapterWordUpper} ${chapter.order} · '
                          '${chapter.difficulty.toUpperCase()}',
                          style: DuoText.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chapter.title,
                          style: DuoText.title.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.lessonsCount(chapter.lessons.length),
                          style: DuoText.small.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final lesson in chapter.lessons)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LessonRow(
              lesson: lesson,
              unit: unit,
              strings: strings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonScreen(
                    lesson: lesson,
                    onOpenExample: () {
                      state.openExample(lesson);
                      onOpenInEditor();
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Uma lição na lista: ícone, título e seta — visual mais leve que os nós
/// da trilha de exercícios, já que aqui é uma lista de leitura, não um jogo.
class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final DuoUnitColor unit;
  final AppStrings strings;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.unit,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Semantics(
      label: strings.lessonSemantics(lesson.title),
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: duo.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: duo.border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: unit.main.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: unit.main,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lesson.title,
                    style: DuoText.bold.copyWith(color: duo.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: duo.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
