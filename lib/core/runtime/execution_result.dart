/// Resultado de uma execução de código Python do aluno.
class ExecutionResult {
  final bool ok;
  final String stdout;
  final PyError? error; // null quando ok == true

  /// O programa parou num input() aguardando resposta: o stdout termina no
  /// prompt e o console deve exibir um campo de digitação inline.
  final bool needsInput;

  const ExecutionResult({
    required this.ok,
    required this.stdout,
    this.error,
    this.needsInput = false,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      ok: json['ok'] as bool,
      stdout: (json['stdout'] as String?) ?? '',
      needsInput: (json['needInput'] as bool?) ?? false,
      error: json['error'] == null
          ? null
          : PyError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }
}

/// Erro de execução Python, sempre com tipo, mensagem e (quando possível)
/// a linha correspondente no código do aluno (1-based).
class PyError {
  final String type; // "NameError", "SyntaxError", ...
  final String message; // "name 'x' is not defined"
  final int? line; // linha no código do aluno
  final String traceback; // texto completo para o modo "detalhes"

  const PyError({
    required this.type,
    required this.message,
    required this.traceback,
    this.line,
  });

  factory PyError.fromJson(Map<String, dynamic> json) {
    return PyError(
      type: json['type'] as String,
      message: (json['message'] as String?) ?? '',
      line: json['line'] as int?,
      traceback: (json['traceback'] as String?) ?? '',
    );
  }

  /// Mensagem curta exibida no banner do console.
  String get display =>
      line != null ? '$type na linha $line: $message' : '$type: $message';
}

/// Resultado de um teste de exercício.
class TestResult {
  final String name;
  final bool passed;
  final String message;

  const TestResult({
    required this.name,
    required this.passed,
    this.message = '',
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      name: json['name'] as String,
      passed: json['passed'] as bool,
      message: (json['message'] as String?) ?? '',
    );
  }
}
