import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/duo_theme.dart';

/// Cabeçalho padrão das abas gamificadas: título da tela + chip de ofensiva
/// (dias seguidos). Antes cada aba tinha um cabeçalho diferente — Exercícios
/// mostrava a marca, as outras só o título, sem chip.
class DuoScreenHeader extends StatelessWidget {
  final String title;
  final int streak;
  final AppStrings strings;

  /// Quando presente, mostra a engrenagem de Ajustes à direita do chip.
  final VoidCallback? onSettings;

  const DuoScreenHeader({
    super.key,
    required this.title,
    required this.streak,
    required this.strings,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final active = streak > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: DuoText.display.copyWith(color: duo.text),
            ),
          ),
          Semantics(
            label: strings.streakSemantics(streak),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: duo.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: duo.border, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 22,
                    color: active ? DuoPalette.orange : duo.lockedIcon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: DuoText.bold.copyWith(
                      color: active ? DuoPalette.orange : duo.muted,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onSettings != null)
            IconButton(
              tooltip: strings.settingsTitle,
              icon: Icon(Icons.settings_outlined, color: duo.muted),
              onPressed: onSettings,
            ),
        ],
      ),
    );
  }
}
