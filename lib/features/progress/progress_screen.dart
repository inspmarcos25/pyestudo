import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/progress/achievements.dart';

/// Visão geral do progresso: sequência de dias, conquistas e % por capítulo.
class ProgressScreen extends StatelessWidget {
  final AppState state;

  const ProgressScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final total = state.chapters.fold<int>(
          0,
          (s, c) => s + c.exercises.length,
        );
        final done = state.completed.length;
        final progress = AchievementProgress(
          completedCount: done,
          chaptersCompleted: state.chaptersFullyCompleted,
          totalChapters: state.chapters
              .where((c) => c.exercises.isNotEmpty)
              .length,
          streak: state.streak,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Progresso')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Progresso geral: $done de $total exercícios',
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '$done / $total',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const Text('exercícios'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: state.streak > 0
                          ? 'Sequência de ${state.streak} dias estudando'
                          : 'Sem sequência ativa hoje',
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: state.streak > 0
                                        ? Colors.deepOrange
                                        : Theme.of(context).disabledColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${state.streak}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                ],
                              ),
                              const Text('dias seguidos'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Conquistas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: [
                  for (final a in achievements)
                    _AchievementChip(
                      achievement: a,
                      unlocked: a.isUnlocked(progress),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Capítulos', style: Theme.of(context).textTheme.titleMedium),
              for (final chapter in state.chapters)
                ListTile(
                  title: Text('${chapter.order}. ${chapter.title}'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: state.chapterProgress(chapter),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  trailing: Text(
                    '${(state.chapterProgress(chapter) * 100).round()}%',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementChip({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = unlocked ? theme.colorScheme.primary : theme.disabledColor;
    return Semantics(
      label:
          '${achievement.title}: ${achievement.description}'
          '${unlocked ? ' (desbloqueada)' : ' (bloqueada)'}',
      child: Card(
        color: unlocked
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(achievement.icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: theme.textTheme.labelLarge?.copyWith(color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      achievement.description,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
