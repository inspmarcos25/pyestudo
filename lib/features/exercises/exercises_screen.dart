import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/duo_theme.dart';
import '../../data/models/models.dart';
import '../lessons/lesson_screen.dart';
import 'exercise_screen.dart';

/// Trilha de aprendizado no estilo Duolingo: cada capítulo é uma "unidade"
/// com banner colorido e um caminho serpenteante de nós (lições e
/// exercícios). Tudo continua acessível — o visual indica progresso, não
/// bloqueia conteúdo.
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
        final duo = DuoColors.of(context);
        final strings = state.strings;
        // Primeiro exercício ainda não resolvido: ganha o balão "COMEÇAR".
        String? nextExerciseId;
        for (final chapter in state.chapters) {
          for (final exercise in chapter.exercises) {
            if (!state.completed.contains(exercise.id)) {
              nextExerciseId = exercise.id;
              break;
            }
          }
          if (nextExerciseId != null) break;
        }
        return Scaffold(
          backgroundColor: duo.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _ScreenHeader(streak: state.streak, strings: strings),
                for (final chapter in state.chapters) ...[
                  const SizedBox(height: 20),
                  _UnitBanner(
                    chapter: chapter,
                    progress: state.chapterProgress(chapter),
                    strings: strings,
                  ),
                  _UnitPath(
                    chapter: chapter,
                    state: state,
                    nextExerciseId: nextExerciseId,
                    onOpenInEditor: onOpenInEditor,
                    strings: strings,
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

/// Título da tela + chip de ofensiva (dias seguidos).
class _ScreenHeader extends StatelessWidget {
  final int streak;
  final AppStrings strings;

  const _ScreenHeader({required this.streak, required this.strings});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final active = streak > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PyEstudo',
              style: DuoText.display.copyWith(color: DuoPalette.green),
            ),
          ),
          Semantics(
            label: strings.streakSemantics(streak),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: duo.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: duo.border, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 22,
                    color: active ? DuoPalette.orange : duo.lockedIcon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: DuoText.bold.copyWith(
                      color: active ? DuoPalette.orange : duo.muted,
                      fontSize: 17,
                    ),
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

/// Banner da unidade: cor própria do capítulo, título grande e progresso.
class _UnitBanner extends StatelessWidget {
  final Chapter chapter;
  final double progress;
  final AppStrings strings;

  const _UnitBanner({
    required this.chapter,
    required this.progress,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final unit = duoUnitColorFor(chapter.order);
    final percent = (progress * 100).round();
    return Semantics(
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DuoProgressBar(
                            value: progress,
                            color: Colors.white,
                            height: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: DuoText.small.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (percent == 100) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Um item da trilha (lição ou exercício) já com seus dados de exibição.
class _PathEntry {
  final IconData icon;
  final String title;
  final String semantics;
  final bool completedLook; // dourado com check
  final bool coloredLook; // cor da unidade
  final bool isNext; // recebe o balão "COMEÇAR"
  final VoidCallback onTap;

  const _PathEntry({
    required this.icon,
    required this.title,
    required this.semantics,
    required this.completedLook,
    required this.coloredLook,
    required this.isNext,
    required this.onTap,
  });
}

/// Caminho serpenteante de nós da unidade.
class _UnitPath extends StatelessWidget {
  final Chapter chapter;
  final AppState state;
  final String? nextExerciseId;
  final VoidCallback onOpenInEditor;
  final AppStrings strings;

  const _UnitPath({
    required this.chapter,
    required this.state,
    required this.nextExerciseId,
    required this.onOpenInEditor,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final unit = duoUnitColorFor(chapter.order);
    final entries = <_PathEntry>[
      for (final lesson in chapter.lessons)
        _PathEntry(
          icon: Icons.menu_book_rounded,
          title: lesson.title,
          semantics: strings.lessonSemantics(lesson.title),
          completedLook: false,
          coloredLook: true,
          isNext: false,
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
        _PathEntry(
          icon: state.completed.contains(exercise.id)
              ? Icons.check_rounded
              : Icons.star_rounded,
          title: exercise.title,
          semantics: state.completed.contains(exercise.id)
              ? strings.exerciseDoneSemantics(exercise.title)
              : strings.exerciseSemantics(exercise.title),
          completedLook: state.completed.contains(exercise.id),
          coloredLook: exercise.id == nextExerciseId,
          isNext: exercise.id == nextExerciseId,
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
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _PathNode(
              entry: entries[i],
              unit: unit,
              offset: _dx(i, context),
              strings: strings,
            ),
        ],
      ),
    );
  }

  /// Deslocamento horizontal do nó `i`: onda senoide, período de 8 nós.
  double _dx(int i, BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final amplitude = math.min(88.0, (width - 220) / 2);
    return -math.sin(i * math.pi / 4) * amplitude;
  }
}

class _PathNode extends StatelessWidget {
  final _PathEntry entry;
  final DuoUnitColor unit;
  final double offset;
  final AppStrings strings;

  const _PathNode({
    required this.entry,
    required this.unit,
    required this.offset,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);

    final Color fill;
    final Color shadow;
    final Color iconColor;
    if (entry.completedLook) {
      fill = DuoPalette.gold;
      shadow = DuoPalette.goldShadow;
      iconColor = Colors.white;
    } else if (entry.coloredLook) {
      fill = unit.main;
      shadow = unit.shadow;
      iconColor = Colors.white;
    } else {
      fill = duo.locked;
      shadow = duo.lockedShadow;
      iconColor = duo.lockedIcon;
    }

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.isNext)
              _StartBubble(color: unit.main, label: strings.startBubble),
            Semantics(
              label: entry.semantics,
              button: true,
              child: DuoButton3D(
                color: fill,
                shadowColor: shadow,
                borderRadius: BorderRadius.circular(999),
                depth: 6,
                onTap: entry.onTap,
                child: SizedBox(
                  width: 68,
                  height: 60,
                  child: Icon(entry.icon, size: 34, color: iconColor),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // O rótulo também abre o item, como o nó acima.
            ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: entry.onTap,
                child: SizedBox(
                  width: 150,
                  child: Text(
                    entry.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.small.copyWith(color: duo.muted),
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

/// Balão "COMEÇAR" flutuando sobre o próximo exercício, com leve quicar.
class _StartBubble extends StatefulWidget {
  final Color color;
  final String label;

  const _StartBubble({required this.color, required this.label});

  @override
  State<_StartBubble> createState() => _StartBubbleState();
}

class _StartBubbleState extends State<_StartBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quicar finito: chama atenção sem rodar para sempre (e respeita
    // a preferência de reduzir animações do sistema).
    if (!_started && !MediaQuery.of(context).disableAnimations) {
      _started = true;
      _controller.repeat(reverse: true, count: 6);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 * _controller.value),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: duo.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: duo.border, width: 2),
              ),
              child: Text(
                widget.label,
                style: DuoText.eyebrow.copyWith(color: widget.color),
              ),
            ),
            // Seta do balão apontando para o nó.
            CustomPaint(
              size: const Size(16, 8),
              painter: _BubbleArrowPainter(
                fill: duo.surface,
                border: duo.border,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  final Color fill;
  final Color border;

  const _BubbleArrowPainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = border);
    final inner = Path()
      ..moveTo(2.5, 0)
      ..lineTo(size.width - 2.5, 0)
      ..lineTo(size.width / 2, size.height - 2.5)
      ..close();
    canvas.drawPath(inner, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_BubbleArrowPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}
