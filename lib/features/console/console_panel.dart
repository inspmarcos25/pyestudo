import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/runtime/execution_result.dart';
import '../../core/theme/ide_theme.dart';

/// Painel de console: stdout da execução, banner de erro com linha clicável
/// e, quando o programa pede input(), um campo de digitação inline —
/// tudo acontece no console, como num terminal.
class ConsolePanel extends StatefulWidget {
  final ExecutionResult? result;
  final bool isRunning;
  final VoidCallback onStop;

  /// Chamado quando o aluno toca no erro; leva o cursor à linha no editor.
  final ValueChanged<int>? onErrorTap;

  /// Chamado quando o aluno responde a um input() pendente.
  final ValueChanged<String>? onSubmitInput;

  const ConsolePanel({
    super.key,
    required this.result,
    required this.isRunning,
    required this.onStop,
    this.onErrorTap,
    this.onSubmitInput,
  });

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollController = ScrollController();

  bool get _awaitingInput =>
      !widget.isRunning && (widget.result?.needsInput ?? false);

  @override
  void didUpdateWidget(covariant ConsolePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_awaitingInput) {
      // foca o campo assim que o programa parar num input()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _awaitingInput) _inputFocus.requestFocus();
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _submit() {
    final text = _inputController.text;
    _inputController.clear();
    widget.onSubmitInput?.call(text);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final error = result?.error;
    final colors = IdeColors.of(context);
    final strings = AppStrings.of(LocaleScope.languageOf(context));
    return Container(
      color: colors.consoleBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: colors.consoleHeaderBackground,
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 18),
                const SizedBox(width: 8),
                const Text('Console'),
                const Spacer(),
                if (widget.isRunning)
                  IconButton(
                    tooltip: strings.stopExecution,
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: widget.onStop,
                  ),
              ],
            ),
          ),
          if (error != null)
            Semantics(
              liveRegion: true, // anunciado pelo leitor de tela
              button: error.line != null,
              child: Material(
                color: colors.errorBannerBackground,
                child: InkWell(
                  onTap: error.line != null
                      ? () => widget.onErrorTap?.call(error.line!)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error.display,
                            style: codeTextStyle.copyWith(
                              color: colors.errorBannerText,
                            ),
                          ),
                        ),
                        if (error.line != null)
                          const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      widget.isRunning
                          ? '${result?.stdout ?? ''}${strings.running}'
                          : (result?.stdout.isNotEmpty ?? false)
                          ? result!.stdout
                          : (result == null
                                ? strings.consoleEmptyHint
                                : _awaitingInput
                                ? ''
                                : strings.noOutput),
                      style: codeTextStyle.copyWith(
                        color: colors.consoleText,
                        fontSize: 14,
                      ),
                    ),
                    if (_awaitingInput)
                      Semantics(
                        label: strings.inputSemantics,
                        textField: true,
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_right,
                              color: colors.successColor,
                              size: 20,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                focusNode: _inputFocus,
                                onSubmitted: (_) => _submit(),
                                style: codeTextStyle.copyWith(
                                  color: colors.successColor,
                                  fontSize: 14,
                                ),
                                cursorColor: colors.successColor,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: strings.inputHint,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: strings.sendAnswer,
                              icon: Icon(
                                Icons.keyboard_return,
                                size: 20,
                                color: colors.successColor,
                              ),
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
