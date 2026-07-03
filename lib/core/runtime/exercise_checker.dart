import '../../data/models/models.dart';
import 'execution_result.dart';
import 'python_runtime.dart';

/// Roda os testes de um exercício sobre o código do aluno.
class ExerciseChecker {
  final PythonRuntime runtime;

  ExerciseChecker(this.runtime);

  Future<List<TestResult>> check(Exercise exercise, String studentCode) {
    return runtime.runTests(studentCode, [
      for (final t in exercise.tests) (name: t.name, code: t.code),
    ]);
  }

  static bool allPassed(List<TestResult> results) =>
      results.isNotEmpty && results.every((r) => r.passed);
}
