import 'package:app_python/core/runtime/execution_result.dart';
import 'package:app_python/features/console/console_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('mostra o stdout da execução', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConsolePanel(
          result: const ExecutionResult(ok: true, stdout: 'Olá, mundo!\n'),
          isRunning: false,
          onStop: () {},
        ),
      ),
    );
    expect(find.textContaining('Olá, mundo!'), findsOneWidget);
  });

  testWidgets('erro exibe tipo e linha; toque leva à linha', (tester) async {
    int? tappedLine;
    await tester.pumpWidget(
      wrap(
        ConsolePanel(
          result: const ExecutionResult(
            ok: false,
            stdout: '',
            error: PyError(
              type: 'NameError',
              message: "name 'x' is not defined",
              line: 3,
              traceback: '...',
            ),
          ),
          isRunning: false,
          onStop: () {},
          onErrorTap: (line) => tappedLine = line,
        ),
      ),
    );

    expect(find.textContaining('NameError na linha 3'), findsOneWidget);

    await tester.tap(find.textContaining('NameError na linha 3'));
    expect(tappedLine, 3);
  });

  testWidgets('input() pendente mostra campo inline e envia a resposta', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      wrap(
        ConsolePanel(
          result: const ExecutionResult(
            ok: false,
            stdout: 'Digite seu nome: ',
            needsInput: true,
          ),
          isRunning: false,
          onStop: () {},
          onSubmitInput: (line) => submitted = line,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Digite seu nome:'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Alexandre');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'Alexandre');
  });

  testWidgets('sem resultado mostra instrução inicial', (tester) async {
    await tester.pumpWidget(
      wrap(ConsolePanel(result: null, isRunning: false, onStop: () {})),
    );
    expect(find.textContaining('Toque em ▶'), findsOneWidget);
  });
}
