import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Espelha snippets/progresso no Firestore (`users/{uid}/...`).
///
/// Toda escrita é best-effort: falhas (offline, quota etc.) nunca sobem
/// para quem chamou — o SQLite local continua sendo a fonte imediata dos
/// dados, o Firestore é só o backup/sincronização entre dispositivos.
class FirestoreSyncService {
  final FirebaseFirestore _db;
  final String userId;

  FirestoreSyncService(this.userId, {FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _snippets =>
      _db.collection('users').doc(userId).collection('snippets');

  CollectionReference<Map<String, dynamic>> get _progress =>
      _db.collection('users').doc(userId).collection('progress');

  Future<void> pushSnippet(String name, String code, DateTime updatedAt) =>
      _guard(
        () => _snippets.doc(name).set({
          'code': code,
          'updatedAt': updatedAt.toIso8601String(),
        }),
      );

  Future<void> deleteSnippet(String name) =>
      _guard(() => _snippets.doc(name).delete());

  Future<void> renameSnippet(
    String oldName,
    String newName,
    String code,
    DateTime updatedAt,
  ) => _guard(() async {
    await _snippets.doc(newName).set({
      'code': code,
      'updatedAt': updatedAt.toIso8601String(),
    });
    await _snippets.doc(oldName).delete();
  });

  Future<void> pushProgress(
    String chapterId,
    String exerciseId,
    DateTime completedAt,
  ) => _guard(
    () => _progress.doc(exerciseId).set({
      'chapterId': chapterId,
      'completedAt': completedAt.toIso8601String(),
    }),
  );

  Future<List<Map<String, dynamic>>> fetchAllSnippets() async {
    final snap = await _snippets.get();
    return [
      for (final d in snap.docs) {'name': d.id, ...d.data()},
    ];
  }

  Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    final snap = await _progress.get();
    return [
      for (final d in snap.docs) {'exerciseId': d.id, ...d.data()},
    ];
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('firestore sync falhou (ignorado, segue local): $e');
    }
  }
}
