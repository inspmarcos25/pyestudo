import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'db_factory_native.dart'
    if (dart.library.js_interop) 'db_factory_web.dart'
    as impl;

/// Abre (e migra) o banco SQLite do app.
///
/// Tabelas:
///  - snippets: códigos do aluno (o "seletor de arquivos" do editor)
///  - progress: exercícios concluídos por capítulo
class AppDatabase {
  static const _dbName = 'pyestudo.db';
  static const _version = 1;

  static Future<Database> open({String? path}) async {
    final dbPath = path ?? p.join(await impl.databasesPath(), _dbName);
    return impl.dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE snippets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            code TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
          await db.execute('''
          CREATE TABLE progress (
            exercise_id TEXT PRIMARY KEY,
            chapter_id TEXT NOT NULL,
            completed_at TEXT NOT NULL
          )
        ''');
        },
      ),
    );
  }
}
