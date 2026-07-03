import 'package:flutter/material.dart';

import '../../core/theme/ide_theme.dart';
import '../../data/models/models.dart';

/// Lição: texto explicativo + exemplo comentado, com opção de abrir no editor.
class LessonScreen extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onOpenExample;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.onOpenExample,
  });

  @override
  Widget build(BuildContext context) {
    final colors = IdeColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(lesson.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.codeBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              lesson.example,
              style: codeTextStyle.copyWith(
                fontSize: 14,
                color: colors.consoleText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Abrir no editor'),
            onPressed: () {
              Navigator.pop(context);
              onOpenExample();
            },
          ),
        ],
      ),
    );
  }
}
