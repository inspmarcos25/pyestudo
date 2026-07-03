import 'package:app_python/core/progress/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 10, 15, 30); // sexta-feira, meio da tarde

  test('sem datas, sequência é 0', () {
    expect(calculateStreak([], now: now), 0);
  });

  test('só hoje conta como sequência de 1', () {
    expect(calculateStreak([DateTime(2026, 7, 10, 9)], now: now), 1);
  });

  test('só ontem ainda conta (não zera antes do fim do dia)', () {
    expect(calculateStreak([DateTime(2026, 7, 9, 22)], now: now), 1);
  });

  test('anteontem sem nada entre — sequência quebrada', () {
    expect(calculateStreak([DateTime(2026, 7, 8)], now: now), 0);
  });

  test('3 dias consecutivos terminando hoje', () {
    final days = [
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 9),
      DateTime(2026, 7, 8),
    ];
    expect(calculateStreak(days, now: now), 3);
  });

  test('gap no meio interrompe a contagem', () {
    final days = [
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 9),
      // sem dia 8
      DateTime(2026, 7, 7),
    ];
    expect(calculateStreak(days, now: now), 2);
  });

  test('múltiplos exercícios no mesmo dia contam uma vez só', () {
    final days = [
      DateTime(2026, 7, 10, 8),
      DateTime(2026, 7, 10, 9),
      DateTime(2026, 7, 10, 20),
    ];
    expect(calculateStreak(days, now: now), 1);
  });

  test('ordem de entrada não importa', () {
    final days = [
      DateTime(2026, 7, 8),
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 9),
    ];
    expect(calculateStreak(days, now: now), 3);
  });
}
