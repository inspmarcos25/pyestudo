import 'package:app_python/core/storage/code_repository.dart';
import 'package:app_python/core/storage/database.dart';
import 'package:app_python/core/storage/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // SQLite em memória no host, sem device
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CodeRepository', () {
    test('salva, lista e recarrega um snippet', () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final repo = CodeRepository(db);

      await repo.save('principal.py', "print('oi')");
      final loaded = await repo.load('principal.py');
      expect(loaded!.code, "print('oi')");

      await repo.save('principal.py', "print('atualizado')");
      expect((await repo.load('principal.py'))!.code, "print('atualizado')");
      expect(await repo.list(), hasLength(1)); // replace, não duplica

      await db.close();
    });

    test('renomeia um snippet preservando o código', () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final repo = CodeRepository(db);

      await repo.save('rascunho.py', "print('x')");
      await repo.rename('rascunho.py', 'final.py');

      expect(await repo.load('rascunho.py'), isNull);
      expect((await repo.load('final.py'))!.code, "print('x')");

      await db.close();
    });

    test('renomear para um nome já existente falha', () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final repo = CodeRepository(db);

      await repo.save('a.py', '1');
      await repo.save('b.py', '2');

      expect(() => repo.rename('a.py', 'b.py'), throwsStateError);
      // nada mudou
      expect((await repo.load('a.py'))!.code, '1');
      expect((await repo.load('b.py'))!.code, '2');

      await db.close();
    });

    test('apaga um snippet', () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final repo = CodeRepository(db);

      await repo.save('temp.py', 'x = 1');
      await repo.delete('temp.py');

      expect(await repo.load('temp.py'), isNull);
      await db.close();
    });
  });

  group('ProgressRepository', () {
    test('marca exercícios e agrega por capítulo', () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final repo = ProgressRepository(db);

      await repo.markCompleted('cap01', 'cap01_e1');
      await repo.markCompleted('cap01', 'cap01_e2');
      await repo.markCompleted('cap01', 'cap01_e2'); // repetido: ignorado
      await repo.markCompleted('cap02', 'cap02_e1');

      expect(await repo.completedExercises(), {
        'cap01_e1',
        'cap01_e2',
        'cap02_e1',
      });
      expect(await repo.completedByChapter(), {'cap01': 2, 'cap02': 1});

      await db.close();
    });
  });
}
