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

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(AchievementProgress progress) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

/// Conquistas do app, derivadas do progresso — sem tabela própria no banco.
const achievements = <Achievement>[
  Achievement(
    id: 'first_exercise',
    title: 'Primeiro passo',
    description: 'Complete seu primeiro exercício',
    icon: Icons.flag_outlined,
    isUnlocked: _atLeast1Exercise,
  ),
  Achievement(
    id: 'five_exercises',
    title: 'Pegando o jeito',
    description: 'Complete 5 exercícios',
    icon: Icons.trending_up,
    isUnlocked: _atLeast5Exercises,
  ),
  Achievement(
    id: 'ten_exercises',
    title: 'Dedicado',
    description: 'Complete 10 exercícios',
    icon: Icons.local_fire_department_outlined,
    isUnlocked: _atLeast10Exercises,
  ),
  Achievement(
    id: 'twenty_exercises',
    title: 'Persistente',
    description: 'Complete 20 exercícios',
    icon: Icons.military_tech_outlined,
    isUnlocked: _atLeast20Exercises,
  ),
  Achievement(
    id: 'one_chapter',
    title: 'Capítulo concluído',
    description: 'Termine um capítulo inteiro',
    icon: Icons.menu_book_outlined,
    isUnlocked: _atLeast1Chapter,
  ),
  Achievement(
    id: 'all_chapters',
    title: 'Mestre em Python',
    description: 'Termine todos os capítulos',
    icon: Icons.emoji_events_outlined,
    isUnlocked: _allChapters,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Sequência de 3 dias',
    description: 'Estude 3 dias seguidos',
    icon: Icons.whatshot_outlined,
    isUnlocked: _streak3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Sequência de 7 dias',
    description: 'Estude 7 dias seguidos',
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
