import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'db_factory_native.dart'
    if (dart.library.js_interop) 'db_factory_web.dart'
    as impl;

/// Marca dados salvos antes de existir login (ver [SyncCoordinator]).
const localOnlyUserId = '_local';

/// Abre (e migra) o banco SQLite do app.
///
/// Tabelas:
///  - snippets: códigos do aluno (o "seletor de arquivos" do editor)
///  - progress: exercícios concluídos por capítulo
///
/// Ambas têm `user_id` para isolar os dados de cada conta no mesmo
/// navegador/dispositivo (ver plano de login).
class AppDatabase {
  static const _dbName = 'pyestudo.db';
  static const _version = 2;

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
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            code TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(user_id, name)
          )
        ''');
          await db.execute('''
          CREATE TABLE progress (
            user_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            chapter_id TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            PRIMARY KEY (user_id, exercise_id)
          )
        ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Dados de antes do login existir: viram donos de
            // `localOnlyUserId` e são migrados para a conta no primeiro
            // login (ver SyncCoordinator.hydrateAndMigrate).
            await db.execute('ALTER TABLE snippets RENAME TO snippets_old');
            await db.execute('''
            CREATE TABLE snippets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              name TEXT NOT NULL,
              code TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              UNIQUE(user_id, name)
            )
          ''');
            await db.execute('''
            INSERT INTO snippets (id, user_id, name, code, updated_at)
            SELECT id, '$localOnlyUserId', name, code, updated_at FROM snippets_old
          ''');
            await db.execute('DROP TABLE snippets_old');

            await db.execute('ALTER TABLE progress RENAME TO progress_old');
            await db.execute('''
            CREATE TABLE progress (
              user_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              chapter_id TEXT NOT NULL,
              completed_at TEXT NOT NULL,
              PRIMARY KEY (user_id, exercise_id)
            )
          ''');
            await db.execute('''
            INSERT INTO progress (user_id, exercise_id, chapter_id, completed_at)
            SELECT '$localOnlyUserId', exercise_id, chapter_id, completed_at FROM progress_old
          ''');
            await db.execute('DROP TABLE progress_old');
          }
        },
      ),
    );
  }
}
