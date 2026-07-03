import 'package:app_python/core/runtime/simulated_python_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SimulatedPythonRuntime runtime;

  setUp(() => runtime = SimulatedPythonRuntime());
  tearDown(() => runtime.dispose());

  test('print de literal vai para o stdout', () async {
    final result = await runtime.run("print('Olá, mundo!')");
    expect(result.ok, isTrue);
    expect(result.stdout, 'Olá, mundo!\n');
  });

  test('f-string interpola variável atribuída', () async {
    final result = await runtime.run("nome = 'Ana'\nprint(f'Olá, {nome}!')");
    expect(result.ok, isTrue);
    expect(result.stdout, 'Olá, Ana!\n');
  });

  test('nome indefinido gera NameError com a linha correta', () async {
    // linha 1: comentário, linha 2: print ok, linha 3: erro
    final result = await runtime.run(
      "# comentário\nprint('ok')\nvariavel_inexistente",
    );
    expect(result.ok, isFalse);
    expect(result.error!.type, 'NameError');
    expect(result.error!.line, 3);
    expect(result.error!.message, contains('variavel_inexistente'));
    // a saída anterior ao erro é preservada, como no CPython
    expect(result.stdout, 'ok\n');
  });

  test('linhas em branco e comentários não deslocam a linha do erro', () async {
    final result = await runtime.run('\n\n# só comentário\n\nx');
    expect(result.error!.line, 5);
  });

  test(
    'runTests sem runtime real reporta testes como não verificáveis',
    () async {
      final results = await runtime.runTests("print('oi')", [
        (name: 't1', code: 'assert True'),
      ]);
      expect(results, hasLength(1));
      expect(results.single.passed, isFalse);
      expect(results.single.message, contains('fetch_pyodide'));
    },
  );
}
