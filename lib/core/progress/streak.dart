/// Calcula a sequência (streak) de dias consecutivos com pelo menos um
/// exercício concluído, contando até hoje ou ontem (para não zerar antes
/// da meia-noite do dia em que o aluno ainda vai estudar).
///
/// Função pura — nada de banco de dados aqui, só a regra de negócio,
/// testável isoladamente.
int calculateStreak(List<DateTime> completionDays, {DateTime? now}) {
  if (completionDays.isEmpty) return 0;

  DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  final days = completionDays.map(dayOnly).toSet().toList()
    ..sort((a, b) => b.compareTo(a)); // mais recente primeiro

  final today = dayOnly(now ?? DateTime.now());
  final gapFromToday = today.difference(days.first).inDays;
  if (gapFromToday > 1) return 0; // sequência quebrada: nem hoje, nem ontem

  var streak = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i - 1].difference(days[i]).inDays;
    if (gap == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
