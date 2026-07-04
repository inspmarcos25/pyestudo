import 'package:sqflite/sqflite.dart';

/// Um arquivo de código do aluno.
class Snippet {
  final int? id;
  final String name;
  final String code;
  final DateTime updatedAt;

  const Snippet({
    this.id,
    required this.name,
    required this.code,
    required this.updatedAt,
  });
}

/// CRUD dos códigos salvos (gaveta de arquivos do editor), isolado por
/// [userId] — cada conta só enxerga os próprios arquivos.
class CodeRepository {
  final Database db;
  String userId;

  CodeRepository(this.db, {required this.userId});

  Future<List<Snippet>> list() async {
    final rows = await db.query(
      'snippets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return [for (final r in rows) _fromRow(r)];
  }

  Future<void> save(String name, String code) async {
    await db.insert('snippets', {
      'user_id': userId,
      'name': name,
      'code': code,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Snippet?> load(String name) async {
    final rows = await db.query(
      'snippets',
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, name],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> delete(String name) async {
    await db.delete(
      'snippets',
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, name],
    );
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
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, oldName],
    );
  }

  Snippet _fromRow(Map<String, Object?> r) => Snippet(
    id: r['id'] as int,
    name: r['name'] as String,
    code: r['code'] as String,
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );
}
