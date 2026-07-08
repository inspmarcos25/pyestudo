import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/progress/achievements.dart';
import '../../core/theme/duo_theme.dart';
import '../settings/settings_screen.dart';
import '../shared/duo_screen_header.dart';

/// Visão geral do progresso no estilo Duolingo: card de ofensiva em
/// destaque, grid de estatísticas, medalhas de conquistas e barras por
/// capítulo.
class ProgressScreen extends StatelessWidget {
  final AppState state;

  const ProgressScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final duo = DuoColors.of(context);
        final strings = state.strings;
        final total = state.chapters.fold<int>(
          0,
          (s, c) => s + c.exercises.length,
        );
        final done = state.completed.length;
        final chaptersWithExercises = state.chapters
            .where((c) => c.exercises.isNotEmpty)
            .length;
        final progress = AchievementProgress(
          completedCount: done,
          chaptersCompleted: state.chaptersFullyCompleted,
          totalChapters: chaptersWithExercises,
          streak: state.streak,
        );
        final unlockedCount = achievements
            .where((a) => a.isUnlocked(progress))
            .length;
        return Scaffold(
          backgroundColor: duo.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                DuoScreenHeader(
                  title: strings.progressTitle,
                  streak: state.streak,
                  strings: strings,
                  onSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _StreakHero(streak: state.streak, strings: strings),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_rounded,
                        iconColor: DuoPalette.green,
                        value: '$done / $total',
                        label: strings.statExercises,
                        semantics: strings.overallProgressSemantics(
                          done,
                          total,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.auto_stories_rounded,
                        iconColor: DuoPalette.blue,
                        value:
                            '${state.chaptersFullyCompleted} / '
                            '$chaptersWithExercises',
                        label: strings.statChapters,
                        semantics: strings.chaptersDoneSemantics(
                          state.chaptersFullyCompleted,
                          chaptersWithExercises,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: DuoPalette.gold,
                        value: '$unlockedCount / ${achievements.length}',
                        label: strings.statAchievements,
                        semantics: strings.achievementsCountSemantics(
                          unlockedCount,
                          achievements.length,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.track_changes_rounded,
                        iconColor: DuoPalette.purple,
                        value: total == 0
                            ? '0%'
                            : '${(done / total * 100).round()}%',
                        label: strings.statCourse,
                        semantics: strings.courseSemantics(
                          total == 0 ? 0 : (done / total * 100).round(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(strings.achievementsSection),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 96,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, i) => _AchievementBadge(
                    achievement: achievements[i],
                    color: duoUnitColors[i % duoUnitColors.length],
                    unlocked: achievements[i].isUnlocked(progress),
                    strings: strings,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle(strings.chaptersSection),
                const SizedBox(height: 12),
                for (final chapter in state.chapters)
                  _ChapterProgressCard(
                    title: '${chapter.order}. ${chapter.title}',
                    unit: duoUnitColorFor(chapter.order),
                    value: state.chapterProgress(chapter),
                    strings: strings,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: DuoText.title.copyWith(color: duo.text)),
    );
  }
}

/// Card laranja em destaque com a chama e os dias seguidos.
class _StreakHero extends StatelessWidget {
  final int streak;
  final AppStrings strings;

  const _StreakHero({required this.streak, required this.strings});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final active = streak > 0;
    return Semantics(
      label: strings.streakSemantics(streak),
      child: DuoButton3D(
        color: active ? DuoPalette.orange : duo.surface,
        shadowColor: active ? DuoPalette.orangeShadow : duo.lockedShadow,
        borderRadius: BorderRadius.circular(20),
        depth: 5,
        border: active ? null : Border.all(color: duo.border, width: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 56,
                color: active ? Colors.white : duo.lockedIcon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.streakHeroTitle(streak),
                      style: DuoText.stat.copyWith(
                        color: active ? Colors.white : duo.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active
                          ? strings.streakBodyActive
                          : strings.streakBodyInactive,
                      style: DuoText.body.copyWith(
                        color: active
                            ? Colors.white.withValues(alpha: 0.9)
                            : duo.muted,
                      ),
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

/// Card de estatística com borda, ícone colorido e número grande.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String semantics;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.semantics,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: duo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duo.border, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.stat.copyWith(color: duo.text, fontSize: 20),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.small.copyWith(color: duo.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Medalha de conquista: quadradinho colorido quando desbloqueada,
/// acinzentado com cadeado quando ainda não.
class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final DuoUnitColor color;
  final bool unlocked;
  final AppStrings strings;

  const _AchievementBadge({
    required this.achievement,
    required this.color,
    required this.unlocked,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final title = strings.achievementTitle(achievement.id);
    final description = strings.achievementDescription(achievement.id);
    return Semantics(
      label: strings.achievementSemantics(title, description, unlocked),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: duo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? color.main.withValues(alpha: 0.55) : duo.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: unlocked ? color.main : duo.locked,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: unlocked ? color.shadow : duo.lockedShadow,
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                unlocked ? achievement.icon : Icons.lock_rounded,
                size: 24,
                color: unlocked ? Colors.white : duo.lockedIcon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.bold.copyWith(
                      fontSize: 14,
                      height: 1.15,
                      color: unlocked ? duo.text : duo.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.small.copyWith(
                      fontSize: 11.5,
                      color: duo.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de capítulo com barra de progresso gordinha na cor da unidade.
class _ChapterProgressCard extends StatelessWidget {
  final String title;
  final DuoUnitColor unit;
  final double value;
  final AppStrings strings;

  const _ChapterProgressCard({
    required this.title,
    required this.unit,
    required this.value,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final percent = (value * 100).round();
    return Semantics(
      label: strings.chapterProgressSemantics(title, percent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: duo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duo.border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.bold.copyWith(color: duo.text),
                  ),
                ),
                const SizedBox(width: 8),
                if (percent == 100)
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 20,
                    color: DuoPalette.gold,
                  )
                else
                  Text(
                    '$percent%',
                    style: DuoText.bold.copyWith(color: unit.main),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DuoProgressBar(value: value, color: unit.main),
          ],
        ),
      ),
    );
  }
}
