import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/theme/ide_theme.dart';
import '../../data/models/models.dart';
import '../lessons/lesson_screen.dart';
import 'exercise_screen.dart';

/// Lista de capítulos com suas lições e exercícios.
class ExercisesScreen extends StatelessWidget {
  final AppState state;

  /// Chamado quando um exemplo é aberto no editor (troca para a aba Editor).
  final VoidCallback onOpenInEditor;

  const ExercisesScreen({
    super.key,
    required this.state,
    required this.onOpenInEditor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Exercícios')),
          body: ListView(
            children: [
              for (final chapter in state.chapters)
                _ChapterTile(
                  chapter: chapter,
                  state: state,
                  onOpenInEditor: onOpenInEditor,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final AppState state;
  final VoidCallback onOpenInEditor;

  const _ChapterTile({
    required this.chapter,
    required this.state,
    required this.onOpenInEditor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = state.chapterProgress(chapter);
    return ExpansionTile(
      title: Text('${chapter.order}. ${chapter.title}'),
      subtitle: Text(
        '${chapter.difficulty} · ${(progress * 100).round()}% concluído',
      ),
      children: [
        for (final lesson in chapter.lessons)
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(lesson.title),
            subtitle: const Text('Lição com exemplo comentado'),
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
        for (final exercise in chapter.exercises)
          ListTile(
            leading: Icon(
              state.completed.contains(exercise.id)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: state.completed.contains(exercise.id)
                  ? IdeColors.of(context).successColor
                  : null,
            ),
            title: Text(exercise.title),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseScreen(
                  state: state,
                  chapter: chapter,
                  exercise: exercise,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
