import 'package:app_python/app_state.dart';
import 'package:app_python/core/auth/auth_service.dart';
import 'package:app_python/core/i18n/locale_controller.dart';
import 'package:app_python/core/storage/code_repository.dart';
import 'package:app_python/core/storage/database.dart';
import 'package:app_python/core/storage/progress_repository.dart';
import 'package:app_python/core/runtime/simulated_python_runtime.dart';
import 'package:app_python/core/sync/firestore_sync_service.dart';
import 'package:app_python/core/theme/brightness_controller.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _testUserId = 'test-user';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<AppState> buildState() async {
    SharedPreferences.setMockInitialValues({});
    final db = await AppDatabase.open(path: inMemoryDatabasePath);
    final prefs = await SharedPreferences.getInstance();
    return AppState.load(
      runtime: SimulatedPythonRuntime(),
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
  }

  test('tema começa escuro por padrão e alterna persistindo', () async {
    final state = await buildState();
    expect(state.brightness, Brightness.dark);

    await state.toggleBrightness();
    expect(state.brightness, Brightness.light);
    expect(state.prefs.getBool('dark_mode'), isFalse);

    await state.toggleBrightness();
    expect(state.brightness, Brightness.dark);
    expect(state.prefs.getBool('dark_mode'), isTrue);
  });

  test('tema salvo é restaurado ao recarregar o AppState', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});
    final db = await AppDatabase.open(path: inMemoryDatabasePath);
    final prefs = await SharedPreferences.getInstance();
    final state = await AppState.load(
      runtime: SimulatedPythonRuntime(),
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
    expect(state.brightness, Brightness.light);
  });

  test('apagar o arquivo aberto volta para o arquivo padrão', () async {
    final state = await buildState();
    await state.createFile('rascunho.py');
    expect(state.currentFileName, 'rascunho.py');

    await state.deleteFile('rascunho.py');
    expect(state.currentFileName, AppState.defaultFileName);
    expect(await state.codeRepository.load('rascunho.py'), isNull);
  });

  test('apagar um arquivo que não é o aberto não afeta o atual', () async {
    final state = await buildState();
    await state.codeRepository.save('outro.py', 'x = 1');
    final before = state.currentFileName;

    await state.deleteFile('outro.py');
    expect(state.currentFileName, before);
  });

  test('renomear o arquivo aberto atualiza o nome corrente', () async {
    final state = await buildState();
    await state.createFile('antigo.py');

    await state.renameFile('antigo.py', 'novo.py');
    expect(state.currentFileName, 'novo.py');
    expect(await state.codeRepository.load('antigo.py'), isNull);
    expect(await state.codeRepository.load('novo.py'), isNotNull);
  });

  test('renomear para nome existente propaga o erro', () async {
    final state = await buildState();
    await state.codeRepository.save('a.py', '1');
    await state.codeRepository.save('b.py', '2');

    expect(() => state.renameFile('a.py', 'b.py'), throwsStateError);
  });
}
