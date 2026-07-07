import 'package:app_python/data/content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega os 7 capítulos dos assets com lições e exercícios', () async {
    final chapters = await ContentLoader().loadChapters();

    expect(chapters, hasLength(7));
    expect(chapters.map((c) => c.order), [1, 2, 3, 4, 5, 6, 7]);
    for (final chapter in chapters) {
      expect(
        chapter.lessons,
        isNotEmpty,
        reason: '${chapter.id} deve ter lições',
      );
      expect(
        chapter.exercises,
        isNotEmpty,
        reason: '${chapter.id} deve ter exercícios',
      );
      for (final e in chapter.exercises) {
        expect(
          e.tests,
          isNotEmpty,
          reason: 'exercício ${e.id} deve ter testes',
        );
        expect(e.starterCode, isNotEmpty);
      }
    }
  });
}
