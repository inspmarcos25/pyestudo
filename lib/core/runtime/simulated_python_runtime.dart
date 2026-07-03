import 'dart:async';

import 'execution_result.dart';
import 'python_runtime.dart';

/// Interpreta um subconjunto mínimo de Python em Dart puro.
///
/// Serve para desenvolver a UI e rodar testes de widget sem o Pyodide, e como
/// fallback quando os assets do runtime real não foram baixados. Reconhece:
/// `print('texto')`, `print(f'...')` com variáveis simples, atribuições de
/// literais, comentários e linhas em branco. Qualquer outra linha gera
/// NameError/SyntaxError com a linha correta — o mesmo contrato do runtime
/// real.
class SimulatedPythonRuntime implements PythonRuntime {
  final _stdoutController = StreamController<String>.broadcast();

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> interrupt() async {}

  static final _printLiteral = RegExp(r'''^print\((['"])(.*)\1\)$''');
  static final _printFString = RegExp(r'''^print\(f(['"])(.*)\1\)$''');
  static final _printBare = RegExp(r'^print\((.+)\)$');
  static final _assignment = RegExp(
    r'''^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.+)$''',
  );
  static final _identifier = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*');

  @override
  Future<ExecutionResult> run(
    String code, {
    String stdinText = '',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final buffer = StringBuffer();
    final vars = <String, String>{};
    final lines = code.split('\n');

    void emit(String text) {
      buffer.writeln(text);
      _stdoutController.add('$text\n');
    }

    ExecutionResult fail(String type, String message, int line) {
      return ExecutionResult(
        ok: false,
        stdout: buffer.toString(),
        error: PyError(
          type: type,
          message: message,
          line: line,
          traceback:
              'Traceback (most recent call last):\n'
              '  File "<exercicio>", line $line, in <module>\n'
              '$type: $message',
        ),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final literal = _printLiteral.firstMatch(line);
      if (literal != null) {
        emit(literal.group(2)!);
        continue;
      }

      final fstring = _printFString.firstMatch(line);
      if (fstring != null) {
        var text = fstring.group(2)!;
        for (final entry in vars.entries) {
          text = text.replaceAll('{${entry.key}}', entry.value);
        }
        final unresolved = RegExp(
          r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}',
        ).firstMatch(text);
        if (unresolved != null) {
          return fail(
            'NameError',
            "name '${unresolved.group(1)}' is not defined",
            lineNo,
          );
        }
        emit(text);
        continue;
      }

      final bare = _printBare.firstMatch(line);
      if (bare != null) {
        final arg = bare.group(1)!.trim();
        if (vars.containsKey(arg)) {
          emit(vars[arg]!);
          continue;
        }
        if (double.tryParse(arg) != null) {
          emit(arg);
          continue;
        }
        return fail('NameError', "name '$arg' is not defined", lineNo);
      }

      final assign = _assignment.firstMatch(line);
      if (assign != null) {
        final value = assign.group(2)!.trim();
        final quoted = RegExp(r'''^(['"])(.*)\1$''').firstMatch(value);
        vars[assign.group(1)!] = quoted != null ? quoted.group(2)! : value;
        continue;
      }

      if (_identifier.hasMatch(line)) {
        final name = _identifier.firstMatch(line)!.group(0)!;
        return fail('NameError', "name '$name' is not defined", lineNo);
      }
      return fail('SyntaxError', 'invalid syntax', lineNo);
    }

    return ExecutionResult(ok: true, stdout: buffer.toString());
  }

  @override
  Future<List<TestResult>> runTests(
    String code,
    List<({String name, String code})> tests, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // O simulador não executa funções: sem o runtime real, os testes são
    // reportados como não verificáveis (falham com mensagem explicativa).
    final result = await run(code, timeout: timeout);
    return [
      for (final t in tests)
        TestResult(
          name: t.name,
          passed: false,
          message: result.ok
              ? 'runtime Python indisponível — rode scripts/fetch_pyodide.sh'
              : result.error!.display,
        ),
    ];
  }

  @override
  void dispose() {
    _stdoutController.close();
  }
}
