import 'dart:async';

import 'execution_result.dart';

/// Fachada única de execução de Python local.
///
/// Implementações: [PyodideRuntime] (CPython real em WASM, nos devices) e
/// [SimulatedPythonRuntime] (subconjunto em Dart puro, usado em testes e
/// como fallback quando os assets do Pyodide não foram baixados).
abstract class PythonRuntime {
  /// Carrega o runtime (uma vez por sessão). Idempotente.
  Future<void> initialize();

  /// Executa o código do aluno. Nunca lança — erros vêm em [ExecutionResult].
  ///
  /// [stdinText] alimenta o input(): uma linha por chamada.
  Future<ExecutionResult> run(
    String code, {
    String stdinText = '',
    Duration timeout = const Duration(seconds: 10),
  });

  /// Executa o código do aluno seguido dos testes de um exercício.
  Future<List<TestResult>> runTests(
    String code,
    List<({String name, String code})> tests, {
    Duration timeout = const Duration(seconds: 10),
  });

  /// Linhas de stdout em tempo real (para o console).
  Stream<String> get stdout;

  /// Interrompe uma execução em andamento (botão Parar / timeout).
  Future<void> interrupt();

  void dispose() {}
}
