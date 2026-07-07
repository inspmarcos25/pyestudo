import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/duo_theme.dart';
import '../../data/models/models.dart';
import 'exercise_screen.dart';

/// Trilha de aprendizado no estilo Duolingo: cada capítulo é uma "unidade"
/// com banner colorido e um caminho serpenteante de nós de exercícios. As
/// lições ficam na aba Aprenda — aqui é só prática valendo progresso.
class ExercisesScreen extends StatelessWidget {
  final AppState state;

  const ExercisesScreen({super.key, required this.state});

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
  final AppStrings strings;

  const _UnitPath({
    required this.chapter,
    required this.state,
    required this.nextExerciseId,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final unit = duoUnitColorFor(chapter.order);
    // Só exercícios entram na trilha — as lições agora vivem na aba Aprenda.
    final entries = <_PathEntry>[
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

    if (entries.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final amp = math.min(92.0, (width - 210) / 2);
        // Nó i: posição vertical fixa (pitch) e horizontal em onda senoide.
        Offset center(int i) => Offset(
          width / 2 + math.sin(i * math.pi / 4) * amp,
          _topPad + _nodeSize / 2 + i * _pitch,
        );
        final centers = [
          for (var i = 0; i < entries.length; i++) center(i),
        ];
        final height = centers.last.dy + _nodeSize / 2 + 28;

        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Zona tintada da unidade: dá uma "faixa" com profundidade
                // (essencial no tema claro, que antes era branco chapado).
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: unit.main.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                // O caminho conectando os nós, desenhado atrás deles.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(
                      centers: centers,
                      color: unit.main.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                // Rótulos ao lado de cada nó (no espaço vazio, longe do
                // caminho central).
                for (var i = 0; i < entries.length; i++)
                  ..._label(width, centers[i], entries[i]),
                // Nós.
                for (var i = 0; i < entries.length; i++)
                  Positioned(
                    left: centers[i].dx - _nodeSize / 2,
                    top: centers[i].dy - _nodeSize / 2,
                    width: _nodeSize,
                    height: _nodeSize,
                    child: _PathNode(entry: entries[i], unit: unit),
                  ),
                // Balão "COMEÇAR" sobre o próximo item.
                for (var i = 0; i < entries.length; i++)
                  if (entries[i].isNext)
                    Positioned(
                      left: centers[i].dx - 70,
                      top: centers[i].dy - _nodeSize / 2 - 42,
                      width: 140,
                      child: Center(
                        child: _StartBubble(
                          color: unit.main,
                          label: strings.startBubble,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _nodeSize = 78.0;
  static const _pitch = 112.0;
  static const _topPad = 46.0;

  /// Rótulo posicionado no lado oposto ao deslocamento do nó (onde há espaço
  /// vazio), ou embaixo quando o nó está no centro.
  List<Widget> _label(double width, Offset c, _PathEntry entry) {
    const gap = 14.0;
    final onRight = c.dx > width / 2 + 12;
    final onLeft = c.dx < width / 2 - 12;
    if (!onRight && !onLeft) {
      // Nó centralizado: rótulo embaixo.
      return [
        Positioned(
          left: c.dx - 80,
          top: c.dy + _nodeSize / 2 + 6,
          width: 160,
          child: _PathLabel(entry: entry, align: TextAlign.center),
        ),
      ];
    }
    if (onRight) {
      // Nó à direita: rótulo à esquerda dele.
      final right = width - (c.dx - _nodeSize / 2 - gap);
      return [
        Positioned(
          right: right,
          top: c.dy - 18,
          left: 8,
          child: _PathLabel(entry: entry, align: TextAlign.right),
        ),
      ];
    }
    // Nó à esquerda: rótulo à direita dele.
    return [
      Positioned(
        left: c.dx + _nodeSize / 2 + gap,
        top: c.dy - 18,
        right: 8,
        child: _PathLabel(entry: entry, align: TextAlign.left),
      ),
    ];
  }
}

/// Rótulo curto de um nó da trilha (também abre o item ao tocar).
class _PathLabel extends StatelessWidget {
  final _PathEntry entry;
  final TextAlign align;

  const _PathLabel({required this.entry, required this.align});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: entry.onTap,
        child: Text(
          entry.title,
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DuoText.bold.copyWith(
            fontSize: 13.5,
            color: entry.completedLook || entry.coloredLook
                ? duo.text
                : duo.muted,
          ),
        ),
      ),
    );
  }
}

/// Desenha o caminho suave que conecta os centros dos nós.
class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final Color color;

  const _TrailPainter({required this.centers, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final prev = centers[i - 1];
      final cur = centers[i];
      // Curva em S suave passando exatamente pelos dois centros.
      final midY = (prev.dy + cur.dy) / 2;
      path.cubicTo(prev.dx, midY, cur.dx, midY, cur.dx, cur.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.color != color || old.centers != centers;
}

class _PathNode extends StatelessWidget {
  final _PathEntry entry;
  final DuoUnitColor unit;

  const _PathNode({required this.entry, required this.unit});

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

    return Semantics(
      label: entry.semantics,
      button: true,
      child: DuoButton3D(
        color: fill,
        shadowColor: shadow,
        borderRadius: BorderRadius.circular(999),
        depth: 6,
        onTap: entry.onTap,
        child: Center(child: Icon(entry.icon, size: 36, color: iconColor)),
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
