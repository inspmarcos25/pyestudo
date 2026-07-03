import 'package:sqflite/sqflite.dart';

/// Um arquivo de código do aluno.
class Snippet {
  final int? id;
  final String name;
  final String code;

  const Snippet({this.id, required this.name, required this.code});
}

/// CRUD dos códigos salvos (gaveta de arquivos do editor).
class CodeRepository {
  final Database db;

  CodeRepository(this.db);

  Future<List<Snippet>> list() async {
    final rows = await db.query('snippets', orderBy: 'updated_at DESC');
    return [
      for (final r in rows)
        Snippet(
          id: r['id'] as int,
          name: r['name'] as String,
          code: r['code'] as String,
        ),
    ];
  }

  Future<void> save(String name, String code) async {
    await db.insert('snippets', {
      'name': name,
      'code': code,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Snippet?> load(String name) async {
    final rows = await db.query(
      'snippets',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Snippet(
      id: r['id'] as int,
      name: r['name'] as String,
      code: r['code'] as String,
    );
  }

  Future<void> delete(String name) async {
    await db.delete('snippets', where: 'name = ?', whereArgs: [name]);
  }

  /// Renomeia um arquivo salvo. Lança [StateError] se [newName] já existir.
  Future<void> rename(String oldName, String newName) async {
    final clash = await load(newName);
    if (clash != null) {
      throw StateError('já existe um arquivo chamado "$newName"');
    }
    await db.update(
      'snippets',
      {'name': newName, 'updated_at': DateTime.now().toIso8601String()},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }
}
