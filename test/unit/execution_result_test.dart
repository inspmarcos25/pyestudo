import 'dart:convert';

import 'package:app_python/core/runtime/execution_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExecutionResult.fromJson', () {
    test('sucesso: stdout preenchido e sem erro', () {
      final result = ExecutionResult.fromJson(
        jsonDecode('{"ok": true, "stdout": "olá\\n", "error": null}'),
      );
      expect(result.ok, isTrue);
      expect(result.stdout, 'olá\n');
      expect(result.error, isNull);
    });

    test('NameError traz tipo, mensagem e linha', () {
      final result = ExecutionResult.fromJson(
        jsonDecode('''
        {"ok": false, "stdout": "", "error": {
          "type": "NameError", "message": "name 'x' is not defined",
          "line": 3, "traceback": "Traceback..."}}
      '''),
      );
      expect(result.ok, isFalse);
      expect(result.error!.type, 'NameError');
      expect(result.error!.line, 3);
      expect(
        result.error!.display,
        'NameError na linha 3: '
        "name 'x' is not defined",
      );
    });

    test('needInput: programa parado num input() pendente', () {
      final result = ExecutionResult.fromJson(
        jsonDecode(
          '{"ok": false, "needInput": true, "stdout": "Digite seu nome: ", "error": null}',
        ),
      );
      expect(result.needsInput, isTrue);
      expect(result.stdout, 'Digite seu nome: ');
      expect(result.error, isNull);
    });

    test('erro sem linha exibe só tipo e mensagem', () {
      const error = PyError(
        type: 'TimeoutError',
        message: 'interrompido',
        traceback: '',
      );
      expect(error.display, 'TimeoutError: interrompido');
    });
  });

  group('TestResult.fromJson', () {
    test('teste reprovado carrega mensagem', () {
      final r = TestResult.fromJson(
        jsonDecode(
          '{"name": "soma(2,3)", "passed": false, "message": "esperado 5"}',
        ),
      );
      expect(r.passed, isFalse);
      expect(r.message, 'esperado 5');
    });
  });
}
