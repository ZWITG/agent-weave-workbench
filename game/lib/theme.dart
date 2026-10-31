import 'package:flutter/material.dart';

/// Night Feed design tokens (design B, chosen 2026-10-26).
/// One set of colours for the whole game.
class NFPalette {
  const NFPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.card,
    required this.nav,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.muted,
    required this.soft,
    required this.blue,
    required this.orange,
  });
  final Color bg, surface, surface2, card, nav, border, borderStrong;
  final Color text, muted, soft, blue, orange;
}

/// Night Feed: the everyday look.
const nightFeed = NFPalette(
  bg: Color(0xFF0F1220),
  surface: Color(0xFF1B2033),
  surface2: Color(0xFF262C44),
  card: Color(0xFF232A45),
  nav: Color(0xFF151A2C),
  border: Color(0xFF343B5C),
  borderStrong: Color(0xFF4A5378),
  text: Color(0xFFEEF1FA),
  muted: Color(0xFFA9B0C7),
  soft: Color(0xFFC5CBDD),
  blue: Color(0xFF7C9CFF),
  orange: Color(0xFFFFB86B),
);

/// Yard Time: institutional green with chalk-mint accents, while you are
/// in prison.
const yardTime = NFPalette(
  bg: Color(0xFF121C19),
  surface: Color(0xFF1A2924),
  surface2: Color(0xFF223630),
  card: Color(0xFF1C2C27),
  nav: Color(0xFF0D1512),
  border: Color(0xFF2C433B),
  borderStrong: Color(0xFF4D7A69),
  text: Color(0xFFE5EFEA),
  muted: Color(0xFF93A89F),
  soft: Color(0xFFB5C7BF),
  blue: Color(0xFF8DB4E8),
  orange: Color(0xFF9FE0C1),
);

/// Night Feed design tokens (design B, chosen 2026-10-26). The colours
/// follow the active palette, so the whole game changes look in prison.
class NF {
  static NFPalette _p = nightFeed;

  /// In prison the game wears Yard Time; outside, Night Feed.
  static bool get prison => identical(_p, yardTime);
  static set prison(bool on) => _p = on ? yardTime : nightFeed;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surface2 => _p.surface2;
  static Color get card => _p.card;
  static Color get nav => _p.nav;
  static Color get border => _p.border;
  static Color get borderStrong => _p.borderStrong;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get soft => _p.soft;
  static Color get blue => _p.blue;
  static Color get orange => _p.orange;
  static const danger = Color(0xFFFF8A8A);

  /// The chalk handwriting and stencil faces used for prison decals.
  static TextStyle chalk(double size, {Color? color}) => TextStyle(
    fontFamily: 'Caveat',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color ?? text,
    height: 1.05,
  );
  static TextStyle stencil(double size, {Color? color}) => TextStyle(
    fontFamily: 'StardosStencil',
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: size * 0.12,
    color: color ?? text,
  );

  static TextStyle sora(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: 'Sora',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color ?? text,
    height: height,
  );

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Sora',
      // Plain ripple: avoids loading the ink_sparkle shader on the web.
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.dark(
        primary: blue,
        secondary: orange,
        surface: surface,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: text,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
        fontFamily: 'Sora',
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nav,
        indicatorColor: surface2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => sora(
            12,
            weight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? orange : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? orange : muted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: sora(14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
