import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/runtime/execution_result.dart';
import '../../core/theme/duo_theme.dart';
import '../../core/theme/ide_theme.dart';
import '../../data/models/models.dart';
import '../editor/code_editor_widget.dart';

/// Tela de um exercício na linguagem visual Duo (mesma da trilha que leva
/// até aqui): cabeçalho com a cor da unidade, enunciado em card, dicas
/// douradas, editor emoldurado e verificação com feedback celebrado —
/// botão "VERIFICAR" vira "CONTINUAR" quando todos os testes passam.
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
    final duo = DuoColors.of(context);
    final unit = duoUnitColorFor(widget.chapter.order);
    final allPassed = _results != null && _results!.every((r) => r.passed);
    final strings = widget.state.strings;
    return Scaffold(
      backgroundColor: duo.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              exercise: exercise,
              chapter: widget.chapter,
              unit: unit,
              strings: strings,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _PromptCard(prompt: exercise.prompt),
                    for (final hint in exercise.hints.take(_hintsShown))
                      _HintCard(hint: hint),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 3,
                      child: _EditorFrame(
                        code: exercise.starterCode,
                        onChanged: (c) => _code = c,
                      ),
                    ),
                    if (_results != null)
                      Expanded(
                        flex: 2,
                        child: _ResultsPanel(
                          results: _results!,
                          allPassed: allPassed,
                          strings: strings,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _Footer(
              strings: strings,
              checking: _checking,
              allPassed: allPassed,
              unit: unit,
              hasHint: !allPassed && _hintsShown < exercise.hints.length,
              onHint: () => setState(() => _hintsShown++),
              onCheck: _check,
              onContinue: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho Duo: botão fechar + rótulo em caixa alta na cor da unidade +
/// título do exercício.
class _Header extends StatelessWidget {
  final Exercise exercise;
  final Chapter chapter;
  final DuoUnitColor unit;
  final AppStrings strings;

  const _Header({
    required this.exercise,
    required this.chapter,
    required this.unit,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(Icons.close_rounded, color: duo.muted, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strings.exerciseWordUpper} · '
                  '${strings.chapterWordUpper} ${chapter.order}',
                  style: DuoText.eyebrow.copyWith(color: unit.main),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DuoText.title.copyWith(color: duo.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enunciado num card de superfície com a borda padrão da linguagem Duo.
class _PromptCard extends StatelessWidget {
  final String prompt;

  const _PromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: duo.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: duo.border, width: 2),
      ),
      child: Text(prompt, style: DuoText.body.copyWith(color: duo.text)),
    );
  }
}

/// Dica revelada: card dourado com lâmpada.
class _HintCard extends StatelessWidget {
  final String hint;

  const _HintCard({required this.hint});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DuoPalette.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DuoPalette.gold.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, size: 18, color: DuoPalette.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(hint, style: DuoText.body.copyWith(color: duo.text)),
          ),
        ],
      ),
    );
  }
}

/// Editor de código emoldurado como as demais superfícies Duo, mantendo o
/// fundo de código do mundo IDE por dentro.
class _EditorFrame extends StatelessWidget {
  final String code;
  final ValueChanged<String> onChanged;

  const _EditorFrame({required this.code, required this.onChanged});

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
      child: CodeEditorWidget(code: code, onChanged: onChanged),
    );
  }
}

/// Painel de resultados teste a teste: verde celebrando quando tudo passa,
/// vermelho encorajando quando algo falha.
class _ResultsPanel extends StatelessWidget {
  final List<TestResult> results;
  final bool allPassed;
  final AppStrings strings;

  const _ResultsPanel({
    required this.results,
    required this.allPassed,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final tone = allPassed ? DuoPalette.green : DuoPalette.red;
    final passed = results.where((r) => r.passed).length;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tone.withValues(alpha: 0.45), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Icon(
                    allPassed ? Icons.celebration_rounded : Icons.flag_rounded,
                    size: 22,
                    color: tone,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allPassed
                          ? strings.exerciseComplete
                          : strings.almostThere,
                      style: DuoText.bold.copyWith(
                        color: tone,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    strings.testsPassedCount(passed, results.length),
                    style: DuoText.small.copyWith(color: duo.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                children: [for (final r in results) _TestRow(result: r)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final TestResult result;

  const _TestRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final tone = result.passed ? DuoPalette.green : DuoPalette.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: DuoText.bold.copyWith(color: duo.text),
                ),
                if (result.message.isNotEmpty)
                  Text(
                    result.message,
                    style: DuoText.small.copyWith(color: duo.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de ações: "DICA" (secundário) + "VERIFICAR"/"CONTINUAR" (primário,
/// relevo 3D verde no padrão Duo).
class _Footer extends StatelessWidget {
  final AppStrings strings;
  final bool checking;
  final bool allPassed;
  final bool hasHint;
  final DuoUnitColor unit;
  final VoidCallback onHint;
  final VoidCallback onCheck;
  final VoidCallback onContinue;

  const _Footer({
    required this.strings,
    required this.checking,
    required this.allPassed,
    required this.hasHint,
    required this.unit,
    required this.onHint,
    required this.onCheck,
    required this.onContinue,
  });

  static const _labelStyle = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final Widget primaryChild;
    if (checking) {
      primaryChild = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else {
      primaryChild = Text(
        (allPassed ? strings.continueLabel : strings.check).toUpperCase(),
        style: _labelStyle.copyWith(color: Colors.white),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          if (hasHint) ...[
            Expanded(
              child: DuoButton3D(
                color: duo.surface,
                shadowColor: duo.lockedShadow,
                border: Border.all(color: duo.border, width: 2),
                depth: 4,
                onTap: onHint,
                semanticsLabel: strings.hint,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      strings.hint.toUpperCase(),
                      style: _labelStyle.copyWith(color: unit.main),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: DuoButton3D(
              color: checking ? duo.locked : DuoPalette.green,
              shadowColor: checking ? duo.lockedShadow : DuoPalette.greenShadow,
              depth: 5,
              onTap: checking ? null : (allPassed ? onContinue : onCheck),
              semanticsLabel: allPassed ? strings.continueLabel : strings.check,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(child: primaryChild),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
