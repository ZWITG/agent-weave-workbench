part of 'minigames.dart';

// Every activity's mini-games are dressed as that activity: its own
// colours, a scene painted behind the game (gym floor, chalkboard, shop
// shelves, a crowded street, still water, a yoga mat, green felt, a stage,
// a writing desk, an arcade grid, a road) and pieces that match it
// (piano keys, index cards, a traffic light, a CCTV camera...).

class MiniSkin {
  const MiniSkin({
    required this.top,
    required this.bottom,
    required this.panel,
    required this.accent,
    required this.zone,
    required this.scene,
    this.onAccent = const Color(0xFF14161C),
    this.pads = const [
      Color(0xFF7C9CFF),
      Color(0xFFFFB86B),
      Color(0xFF5EE6A8),
      Color(0xFFFF8FC7),
    ],
    this.padStyle = 'pads',
    this.marker,
    this.watcher = Icons.visibility_rounded,
    this.player = Icons.directions_car_filled_rounded,
    this.hazard = Icons.warning_rounded,
    this.target = Icons.star_rounded,
    this.decoy = Icons.block_rounded,
  });

  /// Background gradient.
  final Color top;
  final Color bottom;

  /// Wells, tracks and unlit pads.
  final Color panel;

  /// Buttons, the moving marker, highlights.
  final Color accent;
  final Color onAccent;

  /// The "good" zone, target ring, progress.
  final Color zone;

  /// Which scene the backdrop paints (see _ScenePainter).
  final String scene;
  final List<Color> pads;

  /// 'pads', 'keys' (piano) or 'cards' (index cards).
  final String padStyle;

  /// Drawn on the timing and balance marker.
  final IconData? marker;
  final IconData watcher;
  final IconData player;
  final IconData hazard;
  final IconData target;
  final IconData decoy;

  ButtonStyle button() => FilledButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: onAccent,
    minimumSize: const Size(120, 52),
    textStyle: NF.sora(17, weight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  ButtonStyle quiet() => FilledButton.styleFrom(
    backgroundColor: panel,
    foregroundColor: NF.text,
    minimumSize: const Size(120, 52),
    textStyle: NF.sora(17, weight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

const _plainSkin = MiniSkin(
  top: Color(0xFF1B1F2E),
  bottom: Color(0xFF0E1018),
  panel: Color(0xFF2A3045),
  accent: Color(0xFFFF9F43),
  zone: Color(0xFF5EE6A8),
  scene: 'plain',
);

const _skins = <String, MiniSkin>{
  // Rubber floor, plates on the rack, a loud orange.
  'gym': MiniSkin(
    top: Color(0xFF2B2F36),
    bottom: Color(0xFF131518),
    panel: Color(0xFF3A3F47),
    accent: Color(0xFFFF6B35),
    zone: Color(0xFFFFD23F),
    scene: 'gym',
    target: Icons.sports_mma_rounded,
    decoy: Icons.do_not_touch_rounded,
  ),
  // Chalk on a green board.
  'study': MiniSkin(
    top: Color(0xFF24473A),
    bottom: Color(0xFF132A21),
    panel: Color(0xFF2F5847),
    accent: Color(0xFFF4ECC9),
    zone: Color(0xFF9EE09E),
    scene: 'chalk',
  ),
  // Fluorescent aisles and a camera in the corner.
  'shoplift': MiniSkin(
    top: Color(0xFF203246),
    bottom: Color(0xFF0F1924),
    panel: Color(0xFF2C4259),
    accent: Color(0xFFFFC857),
    zone: Color(0xFF4ECDC4),
    scene: 'shop',
    marker: Icons.shopping_bag_rounded,
    watcher: Icons.videocam_rounded,
  ),
  // A busy street at dusk.
  'pickpocket': MiniSkin(
    top: Color(0xFF3B2C52),
    bottom: Color(0xFF181226),
    panel: Color(0xFF4A3A66),
    accent: Color(0xFFFF9F1C),
    zone: Color(0xFF9BE564),
    scene: 'street',
    marker: Icons.account_balance_wallet_rounded,
    watcher: Icons.person_search_rounded,
  ),
  // Still water at dawn.
  'reflect': MiniSkin(
    top: Color(0xFF2E3A62),
    bottom: Color(0xFF151B33),
    panel: Color(0xFF34436F),
    accent: Color(0xFFC3C8FF),
    zone: Color(0xFFA0E7E5),
    scene: 'zen',
    marker: Icons.spa_rounded,
  ),
  // A warm studio and a striped mat.
  'yoga': MiniSkin(
    top: Color(0xFF4A2F45),
    bottom: Color(0xFF1F141D),
    panel: Color(0xFF5E4159),
    accent: Color(0xFFF6B78C),
    zone: Color(0xFF9AD1A0),
    scene: 'mat',
    marker: Icons.self_improvement_rounded,
  ),
  // Green felt and gold chips.
  'casino': MiniSkin(
    top: Color(0xFF0E6B43),
    bottom: Color(0xFF053520),
    panel: Color(0xFF0C7A4C),
    accent: Color(0xFFE8C547),
    zone: Color(0xFFFFFFFF),
    scene: 'felt',
  ),
  // A dark stage under a spotlight; pads are piano keys.
  'instrument': MiniSkin(
    top: Color(0xFF221F3A),
    bottom: Color(0xFF0B0A16),
    panel: Color(0xFF2E2B4C),
    accent: Color(0xFFFFD166),
    zone: Color(0xFF06D6A0),
    scene: 'stage',
    padStyle: 'keys',
    pads: [
      Color(0xFFFFD166),
      Color(0xFFEF476F),
      Color(0xFF06D6A0),
      Color(0xFF118AB2),
    ],
  ),
  // A wooden desk, paper and ink; pads are index cards.
  'write_story': MiniSkin(
    top: Color(0xFF4A3424),
    bottom: Color(0xFF1E140C),
    panel: Color(0xFF5E4630),
    accent: Color(0xFFEFE3C4),
    zone: Color(0xFF7FB7BE),
    scene: 'desk',
    padStyle: 'cards',
    pads: [
      Color(0xFFF2E6C9),
      Color(0xFFE9D7AE),
      Color(0xFFF5EBD7),
      Color(0xFFE6D3A3),
    ],
  ),
  // Neon on black: an arcade.
  'video_games': MiniSkin(
    top: Color(0xFF1A0638),
    bottom: Color(0xFF02010A),
    panel: Color(0xFF241046),
    accent: Color(0xFFFF2A6D),
    onAccent: Color(0xFFFFFFFF),
    zone: Color(0xFF05D9E8),
    scene: 'arcade',
    player: Icons.rocket_rounded,
    hazard: Icons.public_rounded,
    target: Icons.android_rounded,
    decoy: Icons.person_rounded,
  ),
  // Tarmac, lane markings and road-sign yellow.
  'driving_lessons': MiniSkin(
    top: Color(0xFF34393D),
    bottom: Color(0xFF1A1D1F),
    panel: Color(0xFF41474B),
    accent: Color(0xFFFFD000),
    zone: Color(0xFF3DDC84),
    scene: 'road',
    hazard: Icons.warning_rounded,
  ),
};

MiniSkin skinFor(String? activity) =>
    _skins[activity == 'write_song' ? 'instrument' : activity] ?? _plainSkin;

class _SkinScope extends InheritedWidget {
  const _SkinScope({required this.skin, required super.child});
  final MiniSkin skin;

  @override
  bool updateShouldNotify(_SkinScope old) => old.skin != skin;
}

MiniSkin _skinOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_SkinScope>()?.skin ??
    _plainSkin;

/// The scene behind the game.
class _ScenePainter extends CustomPainter {
  _ScenePainter(this.skin);
  final MiniSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.top, skin.bottom],
        ).createShader(Offset.zero & size),
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final rng = Random(skin.scene.hashCode);
    switch (skin.scene) {
      case 'gym':
        // Rubber floor tiles and weight plates on a rack.
        for (var y = h * 0.62; y < h; y += 60) {
          canvas.drawLine(Offset(0, y), Offset(w, y), line);
        }
        for (var x = 0.0; x < w; x += 60) {
          canvas.drawLine(Offset(x, h * 0.62), Offset(x, h), line);
        }
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(w - 40, 90.0 + i * 70),
            26 - i * 3,
            Paint()..color = skin.accent.withValues(alpha: 0.12),
          );
        }
      case 'chalk':
        // A wooden frame and old chalk smudges.
        canvas.drawRect(
          Rect.fromLTWH(10, 10, w - 20, h - 20),
          Paint()
            ..color = const Color(0xFF8B5E3C).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10,
        );
        for (var i = 0; i < 9; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(rng.nextDouble() * w, rng.nextDouble() * h),
              width: 80 + rng.nextDouble() * 120,
              height: 20 + rng.nextDouble() * 30,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.03),
          );
        }
      case 'shop':
        // Shelves of boxes.
        for (var y = 80.0; y < h; y += 110) {
          canvas.drawRect(Rect.fromLTWH(0, y, w, 6), fill);
          for (var x = 8.0; x < w; x += 34 + rng.nextDouble() * 20) {
            final bh = 30 + rng.nextDouble() * 40;
            canvas.drawRect(
              Rect.fromLTWH(x, y - bh, 26, bh),
              Paint()
                ..color = skin.pads[rng.nextInt(4)].withValues(alpha: 0.08),
            );
          }
        }
      case 'street':
        // Lamp glow and a crowd of heads and shoulders.
        canvas.drawCircle(
          Offset(w * 0.8, h * 0.15),
          90,
          Paint()..color = skin.accent.withValues(alpha: 0.07),
        );
        for (var i = 0; i < 14; i++) {
          final x = rng.nextDouble() * w;
          final y = h * 0.7 + rng.nextDouble() * h * 0.3;
          canvas.drawCircle(Offset(x, y), 14, fill);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, y + 40), width: 50, height: 50),
              const Radius.circular(20),
            ),
            fill,
          );
        }
      case 'zen':
        // Ripples on still water.
        for (var r = 40.0; r < w; r += 45) {
          canvas.drawCircle(Offset(w / 2, h * 0.55), r, line);
        }
      case 'mat':
        // A low sun and a striped mat.
        canvas.drawCircle(
          Offset(w / 2, h * 0.2),
          70,
          Paint()..color = skin.accent.withValues(alpha: 0.12),
        );
        for (var x = w * 0.2; x < w * 0.8; x += 18) {
          canvas.drawRect(
            Rect.fromLTWH(x, h * 0.35, 9, h * 0.65),
            Paint()..color = skin.zone.withValues(alpha: 0.05),
          );
        }
      case 'felt':
        // The table edge and stacks of chips.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w / 2, h * 0.5),
            width: w * 1.1,
            height: h * 0.8,
          ),
          Paint()
            ..color = skin.accent.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(30.0 + i * 16, h - 40),
            14,
            Paint()
              ..color = (i.isEven ? skin.accent : Colors.redAccent).withValues(
                alpha: 0.25,
              ),
          );
        }
      case 'stage':
        // A spotlight and a strip of keys along the bottom.
        final path = Path()
          ..moveTo(w * 0.45, 0)
          ..lineTo(w * 0.55, 0)
          ..lineTo(w * 0.9, h)
          ..lineTo(w * 0.1, h)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = skin.accent.withValues(alpha: 0.05),
        );
        for (var x = 0.0; x < w; x += 28) {
          canvas.drawRect(
            Rect.fromLTWH(x, h - 70, 26, 70),
            Paint()..color = Colors.white.withValues(alpha: 0.06),
          );
        }
      case 'desk':
        // Wood grain and a sheet of ruled paper.
        for (var y = 0.0; y < h; y += 14) {
          canvas.drawLine(
            Offset(0, y),
            Offset(w, y + rng.nextDouble() * 8),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.08)
              ..strokeWidth = 1,
          );
        }
        canvas.save();
        canvas.translate(w * 0.55, h * 0.12);
        canvas.rotate(0.12);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * 0.5, h * 0.5),
          Paint()..color = skin.accent.withValues(alpha: 0.08),
        );
        for (var y = 24.0; y < h * 0.5; y += 18) {
          canvas.drawLine(Offset(0, y), Offset(w * 0.5, y), line);
        }
        canvas.restore();
      case 'arcade':
        // Stars and a neon grid running to the horizon.
        for (var i = 0; i < 40; i++) {
          canvas.drawCircle(
            Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.5),
            rng.nextDouble() * 1.6,
            Paint()..color = Colors.white.withValues(alpha: 0.5),
          );
        }
        final grid = Paint()
          ..color = skin.accent.withValues(alpha: 0.18)
          ..strokeWidth = 1.5;
        for (var i = 0; i < 10; i++) {
          final y = h * 0.6 + pow(i / 10, 2) * h * 0.4;
          canvas.drawLine(Offset(0, y), Offset(w, y), grid);
        }
        for (var i = -8; i <= 8; i++) {
          canvas.drawLine(
            Offset(w / 2 + i * 12, h * 0.6),
            Offset(w / 2 + i * 90, h),
            grid,
          );
        }
      case 'road':
        // Verges, tarmac and a dashed centre line.
        final verge = Paint()
          ..color = const Color(0xFF3E7D3A).withValues(alpha: 0.25);
        canvas.drawRect(Rect.fromLTWH(0, 0, 18, h), verge);
        canvas.drawRect(Rect.fromLTWH(w - 18, 0, 18, h), verge);
        final dash = Paint()
          ..color = skin.accent.withValues(alpha: 0.18)
          ..strokeWidth = 4;
        for (var y = 0.0; y < h; y += 50) {
          canvas.drawLine(Offset(w / 2, y), Offset(w / 2, y + 26), dash);
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.skin != skin;
}

/// A pad for memory and rhythm games, shaped by the skin: a coloured
/// tile, a piano key, or an index card.
class _Pad extends StatelessWidget {
  const _Pad({
    required this.index,
    required this.label,
    required this.lit,
    required this.onTap,
    this.dim = 0.35,
  });
  final int index;
  final String label;
  final bool lit;
  final VoidCallback onTap;
  final double dim;

  @override
  Widget build(BuildContext context) {
    final k = _skinOf(context);
    final c = k.pads[index % k.pads.length];
    final (w, h, radius, face, text) = switch (k.padStyle) {
      // Ivory keys that light up in the note's colour.
      'keys' => (
        76.0,
        210.0,
        BorderRadius.vertical(bottom: Radius.circular(14)),
        lit ? c : const Color(0xFFF7F4EC),
        const Color(0xFF14161C),
      ),
      // Index cards on the desk; the lit one lifts and glows.
      'cards' => (
        150.0,
        110.0,
        BorderRadius.circular(6),
        lit ? Colors.white : c.withValues(alpha: 0.8),
        const Color(0xFF3A2A1C),
      ),
      _ => (
        130.0,
        130.0,
        BorderRadius.circular(24),
        c.withValues(alpha: lit ? 1 : dim),
        NF.text,
      ),
    };
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTapDown: (_) => onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: w,
          height: h,
          alignment: k.padStyle == 'keys'
              ? Alignment.bottomCenter
              : Alignment.center,
          padding: const EdgeInsets.all(10),
          transform: Matrix4.translationValues(
            0,
            lit && k.padStyle == 'cards' ? -8 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: face,
            borderRadius: radius,
            border: k.padStyle == 'keys'
                ? Border.all(color: Colors.black26, width: 2)
                : null,
            boxShadow: lit ? [BoxShadow(color: c, blurRadius: 30)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: NF.sora(18, weight: FontWeight.w700, color: text),
          ),
        ),
      ),
    );
  }
}

/// Red, amber and green, for the driving reaction game.
class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.light});
  final String light;

  @override
  Widget build(BuildContext context) {
    Widget lamp(String id, Color on) => Container(
      width: 96,
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: light == id ? on : on.withValues(alpha: 0.15),
        boxShadow: light == id ? [BoxShadow(color: on, blurRadius: 40)] : null,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111315),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          lamp('red', const Color(0xFFE63946)),
          lamp('amber', const Color(0xFFFFB703)),
          lamp('green', const Color(0xFF2DC653)),
        ],
      ),
    );
  }
}

/// A barbell that rises with every rep.
class _Barbell extends StatelessWidget {
  const _Barbell({required this.lift});

  /// 0 (on the floor) to 1 (locked out overhead).
  final double lift;

  @override
  Widget build(BuildContext context) {
    final k = _skinOf(context);
    Widget plate(double h) => Container(
      width: 18,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: k.accent,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            left: 0,
            right: 0,
            top: 86 - lift * 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                plate(56),
                plate(70),
                Container(
                  width: 170,
                  height: 8,
                  color: const Color(0xFFB8BEC6),
                ),
                plate(70),
                plate(56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A playing card: rank in the corner, suit in the middle.
class _PlayingCard extends StatelessWidget {
  const _PlayingCard({required this.rank, required this.suit, this.width = 56});
  final String rank;

  /// 0 spades, 1 hearts, 2 diamonds, 3 clubs.
  final int suit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final red = suit == 1 || suit == 2;
    final ink = red ? const Color(0xFFC62828) : const Color(0xFF16213A);
    final glyph = const ['♠', '♥', '♦', '♣'][suit % 4];
    final h = width * 1.42;
    return Container(
      width: width,
      height: h,
      padding: EdgeInsets.all(width * 0.07),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: _skinOf(context).accent, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Stack(
        children: [
          Text(
            rank,
            style: NF.sora(width * 0.3, weight: FontWeight.w700, color: ink),
          ),
          Center(
            child: Text(
              glyph,
              style: TextStyle(fontSize: width * 0.5, color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
