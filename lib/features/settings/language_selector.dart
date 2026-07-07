import 'package:flutter/material.dart';

import '../../core/i18n/app_language.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';

/// Botão que mostra o idioma atual (bandeira) e abre um menu para trocar.
/// Lê e escreve no [LocaleController] do contexto, então funciona tanto na
/// tela de login quanto dentro do app.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final strings = AppStrings.of(controller.language);
    return PopupMenuButton<AppLanguage>(
      tooltip: strings.chooseLanguage,
      initialValue: controller.language,
      onSelected: controller.setLanguage,
      itemBuilder: (context) => [
        for (final lang in AppLanguage.values)
          PopupMenuItem(
            value: lang,
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(lang.label),
                if (lang == controller.language) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.language.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
