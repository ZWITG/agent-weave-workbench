import 'package:flutter/material.dart';

/// Night Feed design tokens (design B, chosen 2026-10-26).
class NF {
  static const bg = Color(0xFF0F1220);
  static const surface = Color(0xFF1B2033);
  static const surface2 = Color(0xFF262C44);
  static const card = Color(0xFF232A45);
  static const nav = Color(0xFF151A2C);
  static const border = Color(0xFF343B5C);
  static const borderStrong = Color(0xFF4A5378);
  static const text = Color(0xFFEEF1FA);
  static const muted = Color(0xFFA9B0C7);
  static const soft = Color(0xFFC5CBDD);
  static const blue = Color(0xFF7C9CFF);
  static const orange = Color(0xFFFFB86B);
  static const danger = Color(0xFFFF8A8A);

  static TextStyle sora(double size, {FontWeight weight = FontWeight.w400, Color color = text, double? height}) =>
      TextStyle(
        fontFamily: 'Sora',
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color,
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
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: orange,
        surface: surface,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: text,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text, fontFamily: 'Sora'),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nav,
        indicatorColor: surface2,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => sora(12,
            weight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? orange : muted)),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? orange : muted)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface, showDragHandle: true),
      dialogTheme: const DialogThemeData(backgroundColor: surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: sora(14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
