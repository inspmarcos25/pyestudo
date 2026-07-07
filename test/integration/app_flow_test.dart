import 'dart:async';
import 'dart:io';

import 'package:app_python/app.dart';
import 'package:app_python/app_state.dart';
import 'package:app_python/core/auth/auth_service.dart';
import 'package:app_python/core/i18n/app_language.dart';
import 'package:app_python/core/i18n/locale_controller.dart';
import 'package:app_python/core/runtime/execution_result.dart';
import 'package:app_python/core/theme/brightness_controller.dart';
import 'package:app_python/core/runtime/python_runtime.dart';
import 'package:app_python/core/storage/code_repository.dart';
import 'package:app_python/core/storage/database.dart';
import 'package:app_python/core/storage/progress_repository.dart';
import 'package:app_python/core/sync/firestore_sync_service.dart';
import 'package:app_python/data/content_loader.dart';
import 'package:app_python/features/exercises/exercises_screen.dart';
import 'package:app_python/features/learn/learn_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _testUserId = 'test-user';

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
    'estuda uma aula, resolve um exercício e vê o progresso refletido',
    (tester) async {
      // Fixa o idioma em português: este teste verifica textos em PT-BR
      // ('Exercícios', 'Verificar', 'Exercício concluído!'). Sem isso, o
      // locale do ambiente de teste (en) escolheria o inglês por padrão.
      SharedPreferences.setMockInitialValues({'app_language': 'pt'});
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final chaptersByLanguage = await ContentLoader().loadAllLanguages();
      final chapters = chaptersByLanguage[AppLanguage.pt]!;

      // Usuário "logado" via mock: o AuthGate pula a tela de login e vai
      // direto para o HomeShell, como aconteceria com um usuário real.
      final authService = AuthService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: _testUserId),
        ),
      );

      await tester.pumpWidget(
        PyEstudoApp(
          runtime: _AlwaysPassRuntime(),
          db: db,
          chaptersByLanguage: chaptersByLanguage,
          prefs: await SharedPreferences.getInstance(),
          authService: authService,
          firestore: FakeFirebaseFirestore(),
        ),
      );
      await tester.pumpAndSettle();

      final codeRepository = CodeRepository(db, userId: _testUserId);
      final progressRepository = ProgressRepository(db, userId: _testUserId);
      final firstChapter = chapters.first;
      final firstExercise = firstChapter.exercises.first;
      final firstLesson = firstChapter.lessons.first;

      // Editor é a aba inicial; vai para Aprenda e estuda a primeira lição.
      // (Reaproveita o mesmo app/banco já montado neste teste: abrir um
      // segundo AppDatabase independente com databaseFactoryFfiNoIsolate
      // trava o processo de teste — por isso um único app por teste aqui.)
      await tester.tap(find.text('Aprenda'));
      await tester.pumpAndSettle();

      final learnList = find.descendant(
        of: find.byType(LearnScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(firstLesson.title),
        200,
        scrollable: learnList.first,
      );
      await tester.ensureVisible(find.text(firstLesson.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(firstLesson.title));
      await tester.pumpAndSettle();

      expect(find.text(firstLesson.body), findsOneWidget);

      await tester.tap(find.text('Abrir no editor'));
      await tester.pumpAndSettle();

      // Volta pra aba Editor com o exemplo da lição carregado.
      final firstLineOfExample = firstLesson.example.split('\n').first;
      expect(find.textContaining(firstLineOfExample), findsWidgets);

      // Agora vai para Exercícios treinar valendo progresso.
      await tester.tap(find.text('Exercícios'));
      await tester.pumpAndSettle();

      // A trilha mostra todos os nós do capítulo; rola até o primeiro
      // exercício e abre.
      expect(
        await progressRepository.completedExercises(),
        isNot(contains(firstExercise.id)),
      );

      final exercisesList = find.descendant(
        of: find.byType(ExercisesScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(firstExercise.title),
        200,
        scrollable: exercisesList.first,
      );
      await tester.ensureVisible(find.text(firstExercise.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(firstExercise.title));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(find.text('Exercício concluído!'), findsOneWidget);
      expect(
        await progressRepository.completedExercises(),
        contains(firstExercise.id),
      );

      // Volta e confere que a aba Progresso reflete a conclusão.
      // (Usa o BackButton por tipo em vez de tester.pageBack(): com o app
      // em português, o tooltip do botão é "Voltar", e pageBack() procura
      // fixo por "Back".)
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progresso'));
      await tester.pumpAndSettle();

      final totalExercises = chapters.fold<int>(
        0,
        (s, c) => s + c.exercises.length,
      );
      expect(find.text('1 / $totalExercises'), findsOneWidget);

      // codeRepository não usado diretamente neste teste além de confirmar
      // que o isolamento por usuário não quebra a listagem de arquivos.
      expect(await codeRepository.list(), isA<List<Snippet>>());

      await db.close();
    },
  );

  test('progresso persiste depois de fechar e reabrir o app', () async {
    final path =
        '${Directory.systemTemp.createTempSync('pyestudo_test').path}/app.db';
    SharedPreferences.setMockInitialValues({});

    // "Sessão 1": resolve um exercício e fecha o banco.
    var db = await AppDatabase.open(path: path);
    final progressRepo = ProgressRepository(db, userId: _testUserId);
    await progressRepo.markCompleted('cap01', 'cap01_e1');
    await db.close();

    // "Sessão 2": reabre do zero, como se o app tivesse sido reiniciado.
    db = await AppDatabase.open(path: path);
    final prefs = await SharedPreferences.getInstance();
    final state = await AppState.load(
      runtime: _AlwaysPassRuntime(),
      codeRepository: CodeRepository(db, userId: _testUserId),
      progressRepository: ProgressRepository(db, userId: _testUserId),
      chaptersByLanguage: const {},
      locale: LocaleController(prefs),
      brightnessController: BrightnessController(prefs),
      prefs: prefs,
      authService: AuthService(auth: MockFirebaseAuth()),
      syncService: FirestoreSyncService(
        _testUserId,
        firestore: FakeFirebaseFirestore(),
      ),
    );

    expect(state.completed, contains('cap01_e1'));
    expect(state.streak, 1);

    await db.close();
    File(path).parent.deleteSync(recursive: true);
  });
}
