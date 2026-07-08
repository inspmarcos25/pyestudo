import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/i18n/app_language.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/theme/duo_theme.dart';

/// Ajustes do app num lugar só (idioma, tema, sair da conta) — antes essas
/// ações viviam espalhadas pelo toolbar do editor.
class SettingsScreen extends StatelessWidget {
  final AppState state;

  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final duo = DuoColors.of(context);
        final strings = state.strings;
        final isDark = state.brightness == Brightness.dark;
        final locale = LocaleScope.of(context);
        return Scaffold(
          backgroundColor: duo.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: duo.muted,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        strings.settingsTitle,
                        style: DuoText.title.copyWith(color: duo.text),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _LanguageRow(locale: locale, strings: strings),
                      const SizedBox(height: 10),
                      _SettingsRow(
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        iconColor: DuoPalette.blue,
                        label: isDark ? strings.lightTheme : strings.darkTheme,
                        onTap: state.toggleBrightness,
                      ),
                      const SizedBox(height: 10),
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        iconColor: DuoPalette.red,
                        label: strings.signOut,
                        labelColor: DuoPalette.red,
                        onTap: () {
                          Navigator.pop(context);
                          state.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Linha padrão dos ajustes: ícone em quadradinho tintado + rótulo + seta.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: duo.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: duo.border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: DuoText.bold.copyWith(color: labelColor ?? duo.text),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: duo.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Idioma: mesma linha padrão, mas abre o menu de opções de idioma.
class _LanguageRow extends StatelessWidget {
  final LocaleController locale;
  final AppStrings strings;

  const _LanguageRow({required this.locale, required this.strings});

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    return PopupMenuButton<AppLanguage>(
      tooltip: strings.chooseLanguage,
      initialValue: locale.language,
      onSelected: locale.setLanguage,
      itemBuilder: (context) => [
        for (final lang in AppLanguage.values)
          PopupMenuItem(
            value: lang,
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(lang.label),
                if (lang == locale.language) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: duo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duo.border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DuoPalette.teal.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: DuoPalette.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.chooseLanguage,
                style: DuoText.bold.copyWith(color: duo.text),
              ),
            ),
            Text(locale.language.flag, style: const TextStyle(fontSize: 20)),
            Icon(Icons.chevron_right_rounded, color: duo.muted),
          ],
        ),
      ),
    );
  }
}
