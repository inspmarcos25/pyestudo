import 'package:flutter/material.dart';

/// Dados usados para decidir quais conquistas já foram desbloqueadas.
class AchievementProgress {
  final int completedCount;
  final int chaptersCompleted;
  final int totalChapters;
  final int streak;

  const AchievementProgress({
    required this.completedCount,
    required this.chaptersCompleted,
    required this.totalChapters,
    required this.streak,
  });
}

/// Uma conquista. Os textos (título/descrição) não ficam aqui: são
/// buscados por [id] no AppStrings, para respeitarem o idioma escolhido.
class Achievement {
  final String id;
  final IconData icon;
  final bool Function(AchievementProgress progress) isUnlocked;

  const Achievement({
    required this.id,
    required this.icon,
    required this.isUnlocked,
  });
}

/// Conquistas do app, derivadas do progresso — sem tabela própria no banco.
const achievements = <Achievement>[
  Achievement(
    id: 'first_exercise',
    icon: Icons.flag_outlined,
    isUnlocked: _atLeast1Exercise,
  ),
  Achievement(
    id: 'five_exercises',
    icon: Icons.trending_up,
    isUnlocked: _atLeast5Exercises,
  ),
  Achievement(
    id: 'ten_exercises',
    icon: Icons.local_fire_department_outlined,
    isUnlocked: _atLeast10Exercises,
  ),
  Achievement(
    id: 'twenty_exercises',
    icon: Icons.military_tech_outlined,
    isUnlocked: _atLeast20Exercises,
  ),
  Achievement(
    id: 'one_chapter',
    icon: Icons.menu_book_outlined,
    isUnlocked: _atLeast1Chapter,
  ),
  Achievement(
    id: 'all_chapters',
    icon: Icons.emoji_events_outlined,
    isUnlocked: _allChapters,
  ),
  Achievement(
    id: 'streak_3',
    icon: Icons.whatshot_outlined,
    isUnlocked: _streak3,
  ),
  Achievement(
    id: 'streak_7',
    icon: Icons.whatshot,
    isUnlocked: _streak7,
  ),
];

bool _atLeast1Exercise(AchievementProgress p) => p.completedCount >= 1;
bool _atLeast5Exercises(AchievementProgress p) => p.completedCount >= 5;
bool _atLeast10Exercises(AchievementProgress p) => p.completedCount >= 10;
bool _atLeast20Exercises(AchievementProgress p) => p.completedCount >= 20;
bool _atLeast1Chapter(AchievementProgress p) => p.chaptersCompleted >= 1;
bool _allChapters(AchievementProgress p) =>
    p.totalChapters > 0 && p.chaptersCompleted >= p.totalChapters;
bool _streak3(AchievementProgress p) => p.streak >= 3;
bool _streak7(AchievementProgress p) => p.streak >= 7;
