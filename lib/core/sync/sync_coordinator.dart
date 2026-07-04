import '../storage/code_repository.dart';
import '../storage/database.dart' show localOnlyUserId;
import '../storage/progress_repository.dart';
import 'firestore_sync_service.dart';

/// Roda uma vez a cada login: decide se puxa dados do Firestore (conta já
/// tem dados salvos) ou se sobe os dados locais legados (`_local`) para a
/// conta que está logando pela primeira vez neste dispositivo/navegador.
class SyncCoordinator {
  final CodeRepository codeRepository;
  final ProgressRepository progressRepository;
  final FirestoreSyncService sync;

  SyncCoordinator({
    required this.codeRepository,
    required this.progressRepository,
    required this.sync,
  });

  Future<void> hydrateAndMigrate(String uid) async {
    final remoteSnippets = await sync.fetchAllSnippets();
    final remoteProgress = await sync.fetchAllProgress();

    if (remoteSnippets.isNotEmpty || remoteProgress.isNotEmpty) {
      // Conta já tem dados na nuvem: eles são a fonte da verdade.
      for (final s in remoteSnippets) {
        await codeRepository.save(s['name'] as String, s['code'] as String);
      }
      for (final p in remoteProgress) {
        await progressRepository.markCompleted(
          p['chapterId'] as String,
          p['exerciseId'] as String,
        );
      }
      return;
    }

    // Conta nova na nuvem: se existirem dados legados (de antes do login
    // existir) neste dispositivo, migra para a conta uma única vez.
    final legacyCode = CodeRepository(
      codeRepository.db,
      userId: localOnlyUserId,
    );
    final legacyProgress = ProgressRepository(
      progressRepository.db,
      userId: localOnlyUserId,
    );
    final legacySnippets = await legacyCode.list();
    final legacyProgressRows = await legacyProgress.all();
    if (legacySnippets.isEmpty && legacyProgressRows.isEmpty) return;

    for (final s in legacySnippets) {
      await codeRepository.save(s.name, s.code);
      await sync.pushSnippet(s.name, s.code, s.updatedAt);
    }
    for (final row in legacyProgressRows) {
      final chapterId = row['chapter_id'] as String;
      final exerciseId = row['exercise_id'] as String;
      await progressRepository.markCompleted(chapterId, exerciseId);
      await sync.pushProgress(
        chapterId,
        exerciseId,
        DateTime.parse(row['completed_at'] as String),
      );
    }
  }
}
