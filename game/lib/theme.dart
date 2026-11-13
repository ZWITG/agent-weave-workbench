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

/// Gilded: once you are in the upper echelon. Black lacquer, molten-gold
/// lines and accents, ivory text.
const gildedLook = NFPalette(
  bg: Color(0xFF090806),
  surface: Color(0xFF13110C),
  surface2: Color(0xFF1C1810),
  card: Color(0xFF16130D),
  nav: Color(0xFF050403),
  border: Color(0xFF4A3B1C),
  borderStrong: Color(0xFFB8913F),
  text: Color(0xFFF3EBD8),
  muted: Color(0xFFA39577),
  soft: Color(0xFFCFC2A2),
  blue: Color(0xFFE8C877),
  orange: Color(0xFFD4AF5A),
);

/// Sunset Strip: while the Real estate page is open. A beach-town dusk:
/// violet sky, neon pink and pool cyan, warm white text.
const sunsetStrip = NFPalette(
  bg: Color(0xFF160D2E),
  surface: Color(0xFF231442),
  surface2: Color(0xFF2E1B55),
  card: Color(0xFF2A184C),
  nav: Color(0xFF110924),
  border: Color(0xFF4B2C72),
  borderStrong: Color(0xFFB4428E),
  text: Color(0xFFFFF3E8),
  muted: Color(0xFFC7A9D8),
  soft: Color(0xFFE8D3EC),
  blue: Color(0xFF5EF0EE),
  orange: Color(0xFFFF6FB0),
);

/// Back Alley: while Activities › Crime is open, and for crime scenes. A
/// rain-soaked alley at midnight: wet-asphalt black, sodium-lamp amber,
/// police red and blue in the glows.
const backAlley = NFPalette(
  bg: Color(0xFF0B0D10),
  surface: Color(0xFF15181D),
  surface2: Color(0xFF1E2228),
  card: Color(0xFF181B21),
  nav: Color(0xFF07080A),
  border: Color(0xFF2B3038),
  borderStrong: Color(0xFF8A6A2E),
  text: Color(0xFFECE8E1),
  muted: Color(0xFF9A9A98),
  soft: Color(0xFFC9C5BD),
  blue: Color(0xFF6FA8FF),
  orange: Color(0xFFFFB547),
);

/// A special career's look: the whole game changes colour while you work
/// in it (career_curtain.dart plays the change).
class CareerLook {
  const CareerLook(this.name, this.tagline, this.icon, this.palette);
  final String name, tagline;
  final IconData icon;
  final NFPalette palette;
}

/// One look for each special career (and the police). Prison, the Crime
/// and Real estate pages and the upper echelon still win over these.
const careerLooks = <String, CareerLook>{
  'actor': CareerLook(
    'Marquee',
    'Velvet curtains and a row of bulbs with your name under them',
    Icons.theater_comedy,
    NFPalette(
      bg: Color(0xFF170A0E),
      surface: Color(0xFF24111A),
      surface2: Color(0xFF311722),
      card: Color(0xFF2A141E),
      nav: Color(0xFF10060A),
      border: Color(0xFF4E2333),
      borderStrong: Color(0xFFC9A04A),
      text: Color(0xFFFFF1E6),
      muted: Color(0xFFC7A3A8),
      soft: Color(0xFFE6CCCB),
      blue: Color(0xFFFFD27A),
      orange: Color(0xFFFF7A7A),
    ),
  ),
  'musician': CareerLook(
    'Backstage',
    'Stage haze, magenta lights and a teal mixing desk',
    Icons.graphic_eq,
    NFPalette(
      bg: Color(0xFF0E0A1C),
      surface: Color(0xFF1A1230),
      surface2: Color(0xFF241942),
      card: Color(0xFF1E1538),
      nav: Color(0xFF080614),
      border: Color(0xFF3A2A63),
      borderStrong: Color(0xFF8A5CFF),
      text: Color(0xFFF3EEFF),
      muted: Color(0xFFA99CC9),
      soft: Color(0xFFCEC4E8),
      blue: Color(0xFF4FF0D0),
      orange: Color(0xFFFF5FDC),
    ),
  ),
  'athlete': CareerLook(
    'Floodlights',
    'A night match: stadium lights, lime lines and a burning orange ball',
    Icons.sports,
    NFPalette(
      bg: Color(0xFF0A0E14),
      surface: Color(0xFF141B26),
      surface2: Color(0xFF1C2533),
      card: Color(0xFF18202C),
      nav: Color(0xFF06090E),
      border: Color(0xFF2C3746),
      borderStrong: Color(0xFF9BE33C),
      text: Color(0xFFF2F6F0),
      muted: Color(0xFF9EA9B4),
      soft: Color(0xFFC7D0D6),
      blue: Color(0xFFC6FF4D),
      orange: Color(0xFFFF8A3D),
    ),
  ),
  'model': CareerLook(
    'Runway',
    'Black and white, a blush of pink and the flash of cameras',
    Icons.camera_alt,
    NFPalette(
      bg: Color(0xFF0C0C0D),
      surface: Color(0xFF18181A),
      surface2: Color(0xFF232326),
      card: Color(0xFF1C1C1F),
      nav: Color(0xFF060607),
      border: Color(0xFF36363C),
      borderStrong: Color(0xFFE8B4C8),
      text: Color(0xFFFAFAFA),
      muted: Color(0xFFA6A6AB),
      soft: Color(0xFFD2D2D6),
      blue: Color(0xFFF4B8CF),
      orange: Color(0xFFEFE3CF),
    ),
  ),
  'politician': CareerLook(
    'Chamber',
    'Oxford navy, parchment and a crimson ribbon on the ballot box',
    Icons.account_balance,
    NFPalette(
      bg: Color(0xFF0B1020),
      surface: Color(0xFF141C33),
      surface2: Color(0xFF1C2742),
      card: Color(0xFF17213A),
      nav: Color(0xFF070A16),
      border: Color(0xFF2E3A5A),
      borderStrong: Color(0xFFC8A86A),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFADA791),
      soft: Color(0xFFD9D1BB),
      blue: Color(0xFFE0C27A),
      orange: Color(0xFFFF7680),
    ),
  ),
  'military': CareerLook(
    'Field Kit',
    'Olive drab, khaki webbing and signal orange',
    Icons.military_tech,
    NFPalette(
      bg: Color(0xFF12140D),
      surface: Color(0xFF1C2015),
      surface2: Color(0xFF262B1C),
      card: Color(0xFF202418),
      nav: Color(0xFF0B0D08),
      border: Color(0xFF3A4229),
      borderStrong: Color(0xFF8C9A5B),
      text: Color(0xFFEEEEDF),
      muted: Color(0xFFA6A88E),
      soft: Color(0xFFCBCDB5),
      blue: Color(0xFFD4C48F),
      orange: Color(0xFFFF9A3C),
    ),
  ),
  'lawyer': CareerLook(
    'Mahogany',
    'Panelled chambers, brass fittings and a green banker\'s lamp',
    Icons.gavel,
    NFPalette(
      bg: Color(0xFF160E0A),
      surface: Color(0xFF231711),
      surface2: Color(0xFF2F1F17),
      card: Color(0xFF291B14),
      nav: Color(0xFF0E0806),
      border: Color(0xFF4A3125),
      borderStrong: Color(0xFFB98A4E),
      text: Color(0xFFF6EDE0),
      muted: Color(0xFFB9A38F),
      soft: Color(0xFFDDCCB8),
      blue: Color(0xFFE0B66E),
      orange: Color(0xFF7FD4A6),
    ),
  ),
  'doctor': CareerLook(
    'Night Shift',
    'Scrubs teal, clean white light and the monitor\'s glow',
    Icons.monitor_heart,
    NFPalette(
      bg: Color(0xFF08161A),
      surface: Color(0xFF0F2328),
      surface2: Color(0xFF163036),
      card: Color(0xFF122A30),
      nav: Color(0xFF051014),
      border: Color(0xFF21434A),
      borderStrong: Color(0xFF3FC1C9),
      text: Color(0xFFEAF7F8),
      muted: Color(0xFF93B3B7),
      soft: Color(0xFFBFD8DB),
      blue: Color(0xFF5CE1E6),
      orange: Color(0xFFFF8A96),
    ),
  ),
  'pilot': CareerLook(
    'Flight Deck',
    'A dark cockpit, amber dials and the cyan of the head-up display',
    Icons.flight,
    NFPalette(
      bg: Color(0xFF0D1114),
      surface: Color(0xFF161C21),
      surface2: Color(0xFF1F272E),
      card: Color(0xFF1A2127),
      nav: Color(0xFF080B0D),
      border: Color(0xFF2F3A43),
      borderStrong: Color(0xFF6E8796),
      text: Color(0xFFEDF2F5),
      muted: Color(0xFF9AA6AE),
      soft: Color(0xFFC5CED4),
      blue: Color(0xFF5FD3FF),
      orange: Color(0xFFFFB000),
    ),
  ),
  'vet': CareerLook(
    'Meadow',
    'Warm earth, sage green and a field of sunflowers',
    Icons.pets,
    NFPalette(
      bg: Color(0xFF15100C),
      surface: Color(0xFF211913),
      surface2: Color(0xFF2C221A),
      card: Color(0xFF261D16),
      nav: Color(0xFF0D0A07),
      border: Color(0xFF45372A),
      borderStrong: Color(0xFF9DB66A),
      text: Color(0xFFF6F1E6),
      muted: Color(0xFFB2A693),
      soft: Color(0xFFD7CDB9),
      blue: Color(0xFFB3DB7C),
      orange: Color(0xFFFFC94D),
    ),
  ),
  'hustler': CareerLook(
    'Market Day',
    'Warm concrete, chalked prices and spray-paint yellow',
    Icons.storefront,
    NFPalette(
      bg: Color(0xFF141210),
      surface: Color(0xFF201D19),
      surface2: Color(0xFF2B2722),
      card: Color(0xFF25211C),
      nav: Color(0xFF0C0B09),
      border: Color(0xFF3F3A32),
      borderStrong: Color(0xFFD9A62E),
      text: Color(0xFFF5F0E8),
      muted: Color(0xFFACA59A),
      soft: Color(0xFFD3CCC0),
      blue: Color(0xFFFFD23F),
      orange: Color(0xFFFF7B4D),
    ),
  ),
  'police': CareerLook(
    'Blue Line',
    'Midnight blue, badge silver and the red and blue of the lights',
    Icons.local_police,
    NFPalette(
      bg: Color(0xFF0A0F1C),
      surface: Color(0xFF121A2E),
      surface2: Color(0xFF1A2540),
      card: Color(0xFF16203A),
      nav: Color(0xFF070B15),
      border: Color(0xFF2A3A5E),
      borderStrong: Color(0xFFB8C4D9),
      text: Color(0xFFEEF2FA),
      muted: Color(0xFF9DAAC6),
      soft: Color(0xFFC3CDE2),
      blue: Color(0xFF5C9BFF),
      orange: Color(0xFFFF6B70),
    ),
  ),
  'astronaut': CareerLook(
    'Orbit',
    'Deep-space navy, the cyan glow of Earth and mission orange',
    Icons.rocket_launch,
    NFPalette(
      bg: Color(0xFF05070F),
      surface: Color(0xFF0E1220),
      surface2: Color(0xFF161C30),
      card: Color(0xFF121729),
      nav: Color(0xFF03040A),
      border: Color(0xFF262E4A),
      borderStrong: Color(0xFFE7EEF8),
      text: Color(0xFFF2F5FF),
      muted: Color(0xFF9AA3C0),
      soft: Color(0xFFC8CEE4),
      blue: Color(0xFF7FD3FF),
      orange: Color(0xFFFF8A3D),
    ),
  ),
  'fighter': CareerLook(
    'Fight Night',
    'Ring lights in the dark, red gloves and a gold title belt',
    Icons.sports_mma,
    NFPalette(
      bg: Color(0xFF120808),
      surface: Color(0xFF1E0F0F),
      surface2: Color(0xFF2A1515),
      card: Color(0xFF241212),
      nav: Color(0xFF0A0404),
      border: Color(0xFF4A2424),
      borderStrong: Color(0xFFE8C14A),
      text: Color(0xFFFFF2EC),
      muted: Color(0xFFC4A39C),
      soft: Color(0xFFE6CFC9),
      blue: Color(0xFFFFD34D),
      orange: Color(0xFFFF5252),
    ),
  ),
};

/// Night Feed design tokens (design B, chosen 2026-10-26). The colours
/// follow the active palette, so the whole game changes look in prison
/// (Yard Time) and in the upper echelon (Gilded).
class NF {
  static NFPalette _p = nightFeed;

  /// In prison the game wears Yard Time; outside, Night Feed.
  static bool get prison => identical(_p, yardTime);
  static set prison(bool on) => _p = on ? yardTime : nightFeed;

  /// In the upper echelon (and not in prison) the game wears Gilded.
  static bool get gilded => identical(_p, gildedLook);

  /// On the Real estate page the game wears Sunset Strip.
  static bool get sunset => identical(_p, sunsetStrip);

  /// On the Crime page (and in crime scenes) the game wears Back Alley.
  static bool get alley => identical(_p, backAlley);

  /// The special career whose look the game wears, or null.
  static String? career;

  /// Picks the look: prison wins over everything, then the Crime page and
  /// the Real estate page (only while open), then riches, then a special
  /// career's look ([careerLooks]).
  static void look({
    required bool prison,
    required bool rich,
    bool sunset = false,
    bool alley = false,
    String? career,
  }) {
    final c = careerLooks[career];
    NF.career = prison || alley || sunset || rich || c == null ? null : career;
    _p = prison
        ? yardTime
        : alley
        ? backAlley
        : sunset
        ? sunsetStrip
        : rich
        ? gildedLook
        : c?.palette ?? nightFeed;
  }

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
        // Inside, the tab names are stencilled like cell-block signs.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => prison
              ? stencil(
                  10.5,
                  color: s.contains(WidgetState.selected) ? orange : muted,
                )
              : sora(
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
