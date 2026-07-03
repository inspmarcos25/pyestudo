import 'package:flutter/material.dart';

/// Tema estilo IDE (claro ou escuro), com contraste AA e alvos de toque
/// >= 44px.
ThemeData buildIdeTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final background = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
  final surface = isDark ? const Color(0xFF252526) : const Color(0xFFFFFFFF);
  final accent = isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0277BD);
  final error = isDark ? const Color(0xFFFF6E6E) : const Color(0xFFB3261E);

  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      surface: surface,
      error: error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      height: 64, // alvos de toque confortáveis
      indicatorColor: accent.withValues(alpha: 0.2),
    ),
    // Alvo mínimo de 44x44 em botões de ícone (acessibilidade)
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
  );
}

/// Cores do editor/console que não vêm do ColorScheme (fundo do código,
/// banner de erro etc.) — variam com o brilho para manter contraste AA.
class IdeColors {
  final Color codeBackground;
  final Color consoleBackground;
  final Color consoleHeaderBackground;
  final Color consoleText;
  final Color errorBannerBackground;
  final Color errorBannerText;
  final Color successColor;

  const IdeColors({
    required this.codeBackground,
    required this.consoleBackground,
    required this.consoleHeaderBackground,
    required this.consoleText,
    required this.errorBannerBackground,
    required this.errorBannerText,
    required this.successColor,
  });

  static const dark = IdeColors(
    codeBackground: Color(0xFF181818),
    consoleBackground: Color(0xFF181818),
    consoleHeaderBackground: Color(0xFF252526),
    consoleText: Color(0xFFCCCCCC),
    errorBannerBackground: Color(0xFF5A1D1D),
    errorBannerText: Color(0xFFFFB4B4),
    successColor: Color(0xFF6FCF6F),
  );

  static const light = IdeColors(
    codeBackground: Color(0xFFF3F3F3),
    consoleBackground: Color(0xFFF3F3F3),
    consoleHeaderBackground: Color(0xFFE8E8E8),
    consoleText: Color(0xFF1E1E1E),
    errorBannerBackground: Color(0xFFFBE2E1),
    errorBannerText: Color(0xFF8C1D18),
    successColor: Color(0xFF1B8A3E),
  );

  static IdeColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Estilo monoespaçado do editor e do console (escala com a fonte do sistema).
const codeTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 16,
  height: 1.4,
);
