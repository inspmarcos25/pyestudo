import 'package:flutter/material.dart';

/// Tokens visuais das telas gamificadas (Exercícios e Progresso), no espírito
/// do Duolingo: cores saturadas, cantos generosos, tipografia arredondada
/// (Nunito) e relevo 3D nos elementos interativos. O restante do app segue
/// com o IdeTheme.
const duoFontFamily = 'Nunito';

/// Cores fixas da marca "gamificada" (iguais no claro e no escuro).
class DuoPalette {
  static const green = Color(0xFF58CC02);
  static const greenShadow = Color(0xFF46A302);
  static const blue = Color(0xFF1CB0F6);
  static const blueShadow = Color(0xFF1899D6);
  static const gold = Color(0xFFFFC800);
  static const goldShadow = Color(0xFFE5A600);
  static const orange = Color(0xFFFF9600);
  static const orangeShadow = Color(0xFFDD8000);
  static const purple = Color(0xFFCE82FF);
  static const purpleShadow = Color(0xFFAF66E0);
  static const teal = Color(0xFF00CD9C);
  static const tealShadow = Color(0xFF00A47D);
  static const pink = Color(0xFFFF7BC5);
  static const pinkShadow = Color(0xFFE060A4);
  static const red = Color(0xFFFF4B4B);
  static const redShadow = Color(0xFFD93B3B);
}

/// Par cor principal + cor de sombra 3D usado nos nós da trilha e banners.
class DuoUnitColor {
  final Color main;
  final Color shadow;

  const DuoUnitColor(this.main, this.shadow);
}

/// Cores por capítulo (cicla quando há mais capítulos que cores).
const duoUnitColors = <DuoUnitColor>[
  DuoUnitColor(DuoPalette.green, DuoPalette.greenShadow),
  DuoUnitColor(DuoPalette.blue, DuoPalette.blueShadow),
  DuoUnitColor(DuoPalette.purple, DuoPalette.purpleShadow),
  DuoUnitColor(DuoPalette.orange, DuoPalette.orangeShadow),
  DuoUnitColor(DuoPalette.teal, DuoPalette.tealShadow),
  DuoUnitColor(DuoPalette.pink, DuoPalette.pinkShadow),
];

DuoUnitColor duoUnitColorFor(int order) =>
    duoUnitColors[(order - 1).abs() % duoUnitColors.length];

/// Cores que variam com o brilho (fundo, superfícies, bordas, texto).
class DuoColors {
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color locked; // preenchimento de nós/badges ainda não alcançados
  final Color lockedShadow;
  final Color lockedIcon;

  const DuoColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.locked,
    required this.lockedShadow,
    required this.lockedIcon,
  });

  static const dark = DuoColors(
    background: Color(0xFF131F24),
    surface: Color(0xFF202F36),
    border: Color(0xFF37464F),
    text: Color(0xFFF1F7FB),
    muted: Color(0xFF9DB0B9),
    locked: Color(0xFF37464F),
    lockedShadow: Color(0xFF2B3A42),
    lockedIcon: Color(0xFF7C8F98),
  );

  static const light = DuoColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5E5),
    text: Color(0xFF3C3C3C),
    muted: Color(0xFF707070),
    locked: Color(0xFFE5E5E5),
    lockedShadow: Color(0xFFCFCFCF),
    lockedIcon: Color(0xFF9E9E9E),
  );

  static DuoColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Estilos de texto da linguagem gamificada.
class DuoText {
  static const display = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  static const stat = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  static const title = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const body = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const bold = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  /// Rótulo pequeno em caixa alta ("CAPÍTULO 1 · BÁSICO").
  static const eyebrow = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    height: 1.2,
  );

  static const small = TextStyle(
    fontFamily: duoFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
}

/// Bloco com relevo 3D no estilo Duolingo: sombra sólida (sem blur) embaixo
/// que "afunda" quando pressionado. Com [onTap] nulo vira um card estático
/// com o mesmo relevo.
class DuoButton3D extends StatefulWidget {
  final Color color;
  final Color shadowColor;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Widget child;
  final double depth;
  final BoxBorder? border;
  final String? semanticsLabel;

  const DuoButton3D({
    super.key,
    required this.color,
    required this.shadowColor,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.onTap,
    this.depth = 4,
    this.border,
    this.semanticsLabel,
  });

  @override
  State<DuoButton3D> createState() => _DuoButton3DState();
}

class _DuoButton3DState extends State<DuoButton3D> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final depth = widget.depth;
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: EdgeInsets.only(
          top: _pressed ? depth : 0,
          bottom: _pressed ? 0 : depth,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius,
          border: widget.border,
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, depth),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
    if (widget.semanticsLabel == null) return content;
    return Semantics(
      label: widget.semanticsLabel,
      button: widget.onTap != null,
      child: content,
    );
  }
}

/// Barra de progresso "gordinha" com brilho no topo, estilo Duolingo.
class DuoProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const DuoProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    final duo = DuoColors.of(context);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * clamped;
            return Stack(
              children: [
                Container(color: duo.locked),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  // Faixa de brilho no topo do preenchimento.
                  child: fillWidth < height
                      ? null
                      : Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: height * 0.32,
                            margin: EdgeInsets.symmetric(
                              horizontal: height * 0.55,
                              vertical: height * 0.22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(height),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
