import 'package:flutter/material.dart';

import '../engine/legends.dart';
import '../engine/models.dart';
import '../theme.dart';

/// A Legend's own look (Legends plan §3.5, approved mockups): palette,
/// fonts, card frame, motif and nav icons. It is worn on every screen of
/// that life, including activities. Prison, the Crime and Real estate
/// pages and the upper echelon still win until their era versions come
/// (Phase 2).
class LegendLook {
  const LegendLook({
    required this.id,
    required this.name,
    required this.palette,
    required this.bodyFont,
    required this.handFont,
    required this.cardTop,
    required this.cardBottom,
    required this.ink,
    required this.accent,
    required this.motif,
    required this.nav,
    this.mirrorMotif = false,
  });

  final String id;

  /// The look's name ("Codex").
  final String name;
  final NFPalette palette;

  /// Body and title face, and the handwritten face for notes.
  final String bodyFont;
  final String handFont;

  /// The story card's paper.
  final Color cardTop;
  final Color cardBottom;

  /// Frame lines and accent (red chalk for Leonardo).
  final Color ink;
  final Color accent;

  /// A short line drawn under the stats (mirror writing for Leonardo).
  final String motif;
  final bool mirrorMotif;

  /// Nav icons, in tab order: Life, People, Path, Wealth, Me.
  final List<(IconData, IconData)> nav;
}

/// Leonardo's Codex: sepia parchment, iron-gall ink, red chalk.
const leonardoCodex = LegendLook(
  id: 'leonardo',
  name: 'Codex',
  palette: NFPalette(
    bg: Color(0xFFE6D5B0),
    surface: Color(0xFFF1E5C8),
    surface2: Color(0xFFE0CDA4),
    card: Color(0xFFF3E7CC),
    nav: Color(0xFFE0CDA4),
    border: Color(0x663D2614),
    borderStrong: Color(0xFF3D2614),
    text: Color(0xFF3D2614),
    muted: Color(0xFF7A5A3C),
    soft: Color(0xFF5A3B22),
    blue: Color(0xFFA4472F),
    orange: Color(0xFF8A3B22),
  ),
  bodyFont: 'IMFellDWPica',
  handFont: 'Caveat',
  cardTop: Color(0xFFF6EBD2),
  cardBottom: Color(0xFFEBDAB5),
  ink: Color(0xFF3D2614),
  accent: Color(0xFFA4472F),
  motif: 'uccello · ali · vento',
  mirrorMotif: true,
  nav: [
    (Icons.edit_note_outlined, Icons.edit_note),
    (Icons.groups_outlined, Icons.groups),
    (Icons.settings_outlined, Icons.settings),
    (Icons.toll_outlined, Icons.toll),
    (Icons.menu_book_outlined, Icons.menu_book),
  ],
);

const legendLooks = <String, LegendLook>{'leonardo': leonardoCodex};

/// The look of a Legend life, or null in any other life.
LegendLook? legendLookFor(Life? l) {
  final legend = legendRegistry[l?.legendId];
  return legend == null ? null : legendLooks[legend.look];
}

/// The look being worn right now (set with NF.look).
LegendLook? get activeLegendLook => legendLooks[NF.legend];

/// A Legend's card: paper with an ink rule and a second hairline frame
/// inside it, as in the mockups.
class LegendFrame extends StatelessWidget {
  const LegendFrame({
    super.key,
    required this.look,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final LegendLook look;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [look.cardTop, look.cardBottom],
      ),
      border: Border.all(color: look.ink, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: look.ink.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: look.ink.withValues(alpha: 0.33)),
              ),
            ),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

/// The motif line: for Leonardo, words in mirror writing.
class LegendMotif extends StatelessWidget {
  const LegendMotif({super.key, required this.look});
  final LegendLook look;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      look.motif,
      style: TextStyle(
        fontFamily: look.handFont,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: look.palette.muted,
      ),
    );
    return ExcludeSemantics(
      child: look.mirrorMotif
          ? Transform.flip(flipX: true, child: text)
          : text,
    );
  }
}

/// Handwritten notes in the Legend's hand (Caveat for Leonardo).
TextStyle legendHand(LegendLook look, double size, {Color? color}) =>
    TextStyle(
      fontFamily: look.handFont,
      fontWeight: FontWeight.w700,
      fontSize: size,
      color: color ?? look.accent,
      height: 1.1,
    );
