import 'package:sqflite/sqflite.dart';

/// Progresso do aluno: exercícios concluídos, agregados por capítulo.
/// Isolado por [userId] — cada conta só enxerga o próprio progresso.
class ProgressRepository {
  final Database db;
  String userId;

  ProgressRepository(this.db, {required this.userId});

  Future<void> markCompleted(String chapterId, String exerciseId) async {
    await db.insert('progress', {
      'user_id': userId,
      'exercise_id': exerciseId,
      'chapter_id': chapterId,
      'completed_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> completedExercises() async {
    final rows = await db.query(
      'progress',
      columns: ['exercise_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return {for (final r in rows) r['exercise_id'] as String};
  }

  /// {chapterId: quantidade de exercícios concluídos}
  Future<Map<String, int>> completedByChapter() async {
    final rows = await db.rawQuery(
      'SELECT chapter_id, COUNT(*) AS total FROM progress WHERE user_id = ? GROUP BY chapter_id',
      [userId],
    );
    return {for (final r in rows) r['chapter_id'] as String: r['total'] as int};
  }

  /// Uma data por exercício concluído — usada para calcular a sequência
  /// (streak) de dias seguidos estudando.
  Future<List<DateTime>> completionDates() async {
    final rows = await db.query(
      'progress',
      columns: ['completed_at'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return [for (final r in rows) DateTime.parse(r['completed_at'] as String)];
  }

  /// Todas as linhas de progresso da conta (usado na migração/sync).
  Future<List<Map<String, Object?>>> all() async {
    return db.query('progress', where: 'user_id = ?', whereArgs: [userId]);
  }
}
