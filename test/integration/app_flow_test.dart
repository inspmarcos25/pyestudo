import 'dart:async';
import 'dart:io';

import 'package:app_python/app.dart';
import 'package:app_python/app_state.dart';
import 'package:app_python/core/runtime/execution_result.dart';
import 'package:app_python/core/runtime/python_runtime.dart';
import 'package:app_python/core/storage/code_repository.dart';
import 'package:app_python/core/storage/database.dart';
import 'package:app_python/core/storage/progress_repository.dart';
import 'package:app_python/data/content_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Runtime de teste que sempre aprova, para exercitar o fluxo de UI de
/// ponta a ponta sem depender de um interpretador Python de verdade
/// (isso já é coberto pelos testes do runner.py e do SimulatedPythonRuntime).
class _AlwaysPassRuntime implements PythonRuntime {
  final _stdoutController = StreamController<String>.broadcast();

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> interrupt() async {}

  @override
  Future<ExecutionResult> run(
    String code, {
    String stdinText = '',
    Duration timeout = const Duration(seconds: 10),
  }) async => const ExecutionResult(ok: true, stdout: 'ok\n');

  @override
  Future<List<TestResult>> runTests(
    String code,
    List<({String name, String code})> tests, {
    Duration timeout = const Duration(seconds: 10),
  }) async => [for (final t in tests) TestResult(name: t.name, passed: true)];

  @override
  void dispose() => _stdoutController.close();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // Sem isolate: as chamadas ao SQLite resolvem no mesmo isolate/zona da
    // UI. Necessário aqui porque testWidgets roda em fake-async — a
    // variante com isolate (databaseFactoryFfi) trava esperando o relógio
    // real do event loop, que pumpAndSettle não fornece.
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  testWidgets(
    'resolver um exercício atualiza o progresso e reflete na aba Progresso',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final chapters = await ContentLoader().loadChapters();
      final state = await AppState.load(
        runtime: _AlwaysPassRuntime(),
        codeRepository: CodeRepository(db),
        progressRepository: ProgressRepository(db),
        chapters: chapters,
        prefs: await SharedPreferences.getInstance(),
      );
      final firstChapter = chapters.first;
      final firstExercise = firstChapter.exercises.first;

      await tester.pumpWidget(PyEstudoApp(state: state));
      await tester.pumpAndSettle();

      // Editor é a aba inicial; vai para Exercícios.
      await tester.tap(find.text('Exercícios'));
      await tester.pumpAndSettle();

      // Expande o primeiro capítulo e abre o primeiro exercício.
      await tester.tap(
        find.text('${firstChapter.order}. ${firstChapter.title}'),
      );
      await tester.pumpAndSettle();
      expect(state.completed.contains(firstExercise.id), isFalse);

      await tester.tap(find.text(firstExercise.title));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(find.text('Exercício concluído!'), findsOneWidget);
      expect(state.completed.contains(firstExercise.id), isTrue);

      // Volta e confere que a aba Progresso reflete a conclusão.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progresso'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / '), findsOneWidget);
      expect(state.streak, greaterThanOrEqualTo(1));

      await db.close();
    },
  );

  test('progresso persiste depois de fechar e reabrir o app', () async {
    final path =
        '${Directory.systemTemp.createTempSync('pyestudo_test').path}/app.db';
    SharedPreferences.setMockInitialValues({});

    // "Sessão 1": resolve um exercício e fecha o banco.
    var db = await AppDatabase.open(path: path);
    final progressRepo = ProgressRepository(db);
    await progressRepo.markCompleted('cap01', 'cap01_e1');
    await db.close();

    // "Sessão 2": reabre do zero, como se o app tivesse sido reiniciado.
    db = await AppDatabase.open(path: path);
    final state = await AppState.load(
      runtime: _AlwaysPassRuntime(),
      codeRepository: CodeRepository(db),
      progressRepository: ProgressRepository(db),
      chapters: const [],
      prefs: await SharedPreferences.getInstance(),
    );

    expect(state.completed, contains('cap01_e1'));
    expect(state.streak, 1);

    await db.close();
    File(path).parent.deleteSync(recursive: true);
  });
}
