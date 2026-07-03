import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/runtime/execution_result.dart';
import '../../core/theme/ide_theme.dart';
import '../../data/models/models.dart';
import '../editor/code_editor_widget.dart';

/// Tela de um exercício: enunciado, editor com starter code, botão Verificar
/// e feedback teste a teste.
class ExerciseScreen extends StatefulWidget {
  final AppState state;
  final Chapter chapter;
  final Exercise exercise;

  const ExerciseScreen({
    super.key,
    required this.state,
    required this.chapter,
    required this.exercise,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late String _code = widget.exercise.starterCode;
  List<TestResult>? _results;
  bool _checking = false;
  int _hintsShown = 0;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final results = await widget.state.checkExercise(
        widget.chapter,
        widget.exercise,
        _code,
      );
      setState(() => _results = results);
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final allPassed = _results != null && _results!.every((r) => r.passed);
    final colors = IdeColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                exercise.prompt,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (_hintsShown > 0)
            for (final hint in exercise.hints.take(_hintsShown))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(hint)),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: CodeEditorWidget(
              code: exercise.starterCode,
              onChanged: (code) => _code = code,
            ),
          ),
          if (_results != null)
            Expanded(
              flex: 2,
              child: Semantics(
                liveRegion: true,
                child: ListView(
                  children: [
                    if (allPassed)
                      ListTile(
                        leading: Icon(
                          Icons.celebration,
                          color: colors.successColor,
                        ),
                        title: const Text('Exercício concluído!'),
                      ),
                    for (final r in _results!)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          r.passed ? Icons.check_circle : Icons.cancel,
                          color: r.passed
                              ? colors.successColor
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: Text(r.name),
                        subtitle: r.message.isNotEmpty ? Text(r.message) : null,
                      ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_hintsShown < exercise.hints.length)
                    TextButton.icon(
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Dica'),
                      onPressed: () => setState(() => _hintsShown++),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Verificar'),
                    onPressed: _checking ? null : _check,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
