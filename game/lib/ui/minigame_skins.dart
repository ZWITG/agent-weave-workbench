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
  // Night streets: sodium amber on wet tarmac.
  'getaway': MiniSkin(
    top: Color(0xFF15181D),
    bottom: Color(0xFF07080A),
    panel: Color(0xFF2A2D33),
    accent: Color(0xFFFFB547),
    zone: Color(0xFF59F2A6),
    scene: 'road',
  ),
  // A dark house: torchlight yellow.
  'breakin': MiniSkin(
    top: Color(0xFF15161B),
    bottom: Color(0xFF07080A),
    panel: Color(0xFF23252C),
    accent: Color(0xFFFFB547),
    zone: Color(0xFF59F2A6),
    scene: 'plain',
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

/// Inside, every game is played in prison: the yard for working out,
/// otherwise your cell.
const _yardSkin = MiniSkin(
  top: Color(0xFF34403B),
  bottom: Color(0xFF151C19),
  panel: Color(0xFF3E4C46),
  accent: Color(0xFF9FE0C1),
  zone: Color(0xFFE3CF7A),
  scene: 'yard',
  target: Icons.sports_mma_rounded,
  decoy: Icons.local_police_rounded,
  watcher: Icons.local_police_rounded,
);
const _cellSkin = MiniSkin(
  top: Color(0xFF2A3430),
  bottom: Color(0xFF101614),
  panel: Color(0xFF34413C),
  accent: Color(0xFFE5EFEA),
  zone: Color(0xFF9FE0C1),
  scene: 'cell',
  watcher: Icons.local_police_rounded,
  pads: [
    Color(0xFF9FE0C1),
    Color(0xFFE3CF7A),
    Color(0xFF8DB4E8),
    Color(0xFFE5EFEA),
  ],
);

/// Era activities (Phase 2D): ink on parchment in a Legend's look (or the
/// era's colours in an ordinary era life), with a scene for each.
const _eraScenes = <String, String>{
  'era_carnival': 'era_masks',
  'era_san_giovanni': 'era_piazza',
  'era_procession': 'era_piazza',
  'era_joust': 'era_lists',
  'era_tilt': 'era_lists',
  'era_playhouse': 'era_playhouse',
  'era_calcio': 'era_field',
  'era_pallacorda': 'era_court',
  'era_cards': 'era_table',
  'era_tavern': 'era_table',
  'era_chess': 'era_table',
  'era_storyteller': 'era_table',
  'era_bath': 'era_bath',
  'era_music': 'era_staff',
  'era_dance': 'era_raffia',
  'era_ride': 'era_hills',
  'era_pilgrimage': 'era_road',
  'era_shrine': 'era_road',
  'era_hajj': 'era_dunes',
  'era_portrait': 'era_window',
};

MiniSkin _eraSkin(String activity) => MiniSkin(
  top: NF.surface,
  bottom: NF.bg,
  panel: NF.surface2,
  accent: NF.orange,
  onAccent: NF.surface,
  zone: const Color(0xFF6B7F3A),
  scene: _eraScenes[activity] ?? 'era_piazza',
  pads: [NF.blue, const Color(0xFF6B7F3A), const Color(0xFFB8933F), NF.text],
  player: switch (activity) {
    'era_hajj' => Icons.directions_walk_rounded,
    'era_calcio' => Icons.sports_handball_rounded,
    _ => Icons.hiking_rounded,
  },
  hazard: switch (activity) {
    'era_hajj' => Icons.wb_sunny_outlined,
    'era_calcio' => Icons.sports_kabaddi_rounded,
    _ => Icons.terrain_rounded,
  },
  marker: switch (activity) {
    'era_joust' || 'era_tilt' => Icons.flag_rounded,
    'era_ride' => Icons.pets_rounded,
    _ => null,
  },
);

MiniSkin skinFor(String? activity) => activity != null && _eraScenes.containsKey(activity)
    ? _eraSkin(activity)
    : NF.prison
    ? (activity == 'prison_gym' || activity == 'breakout'
          ? _yardSkin
          : _cellSkin)
    : _skins[activity == 'write_song' ? 'instrument' : activity] ?? _plainSkin;

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
      case 'yard':
        // Chain-link fence along the top, razor wire, a floodlight and
        // chalked tallies on the wall.
        final wire = Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..strokeWidth = 1.4;
        final fenceH = h * 0.32;
        for (var x = -fenceH; x < w + fenceH; x += 22) {
          canvas.drawLine(Offset(x, 0), Offset(x + fenceH, fenceH), wire);
          canvas.drawLine(Offset(x + fenceH, 0), Offset(x, fenceH), wire);
        }
        canvas.drawLine(Offset(0, fenceH), Offset(w, fenceH), line);
        for (var x = 6.0; x < w; x += 18) {
          canvas.drawCircle(Offset(x, 10), 5, line);
        }
        canvas.drawCircle(
          Offset(w * 0.82, h * 0.06),
          90,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    skin.zone.withValues(alpha: 0.16),
                    skin.zone.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(w * 0.82, h * 0.06),
                    radius: 90,
                  ),
                ),
        );
        _tallies(canvas, Offset(18, h * 0.78), 12, skin.accent);
      case 'cell':
        // Bars across the whole scene, a bunk and the days on the wall.
        final bar = Paint()..color = Colors.black.withValues(alpha: 0.22);
        for (var x = 24.0; x < w; x += 56) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 9, h), bar);
        }
        canvas.drawRect(Rect.fromLTWH(0, h * 0.2, w, 8), bar);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.8, w, 8), bar);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.66, w * 0.45, 14), fill);
        _tallies(canvas, Offset(w - 120, h * 0.3), 17, skin.accent);
      default:
        if (skin.scene.startsWith('era_')) _era(canvas, size);
    }
  }

  /// The era scenes, drawn in ink.
  void _era(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ink = Paint()
      ..color = NF.text.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final wash = Paint()..color = NF.text.withValues(alpha: 0.05);
    final rng = Random(skin.scene.hashCode);
    switch (skin.scene) {
      case 'era_masks':
        for (var i = 0; i < 9; i++) {
          final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
          canvas.drawOval(Rect.fromCenter(center: c, width: 70, height: 44), ink);
          canvas.drawOval(Rect.fromCenter(center: c + const Offset(-15, -4), width: 16, height: 9), ink);
          canvas.drawOval(Rect.fromCenter(center: c + const Offset(15, -4), width: 16, height: 9), ink);
        }
      case 'era_piazza' || 'era_lists' || 'era_playhouse':
        // A skyline of towers and banners along the bottom.
        var x = 0.0;
        while (x < w) {
          final tw = 30 + rng.nextDouble() * 40;
          final th = 60 + rng.nextDouble() * 140;
          canvas.drawRect(Rect.fromLTWH(x, h - th, tw, th), wash);
          canvas.drawRect(Rect.fromLTWH(x, h - th, tw, th), ink);
          for (var b = x + 6; b < x + tw - 6; b += 10) {
            canvas.drawRect(Rect.fromLTWH(b, h - th - 7, 5, 7), ink);
          }
          x += tw + 6;
        }
        if (skin.scene == 'era_lists') {
          canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), ink..strokeWidth = 4);
        }
        if (skin.scene == 'era_playhouse') {
          canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.38, ink);
          canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.3, ink);
        }
        for (var i = 0; i < 5; i++) {
          final bx = 40 + i * (w - 80) / 4;
          canvas.drawLine(Offset(bx, 60), Offset(bx, 120), ink);
          canvas.drawPath(
            Path()
              ..moveTo(bx, 60)
              ..lineTo(bx + 30, 70)
              ..lineTo(bx, 82),
            wash,
          );
        }
      case 'era_field':
        canvas.drawRect(Rect.fromLTWH(20, 40, w - 40, h - 80), ink);
        canvas.drawLine(Offset(20, h / 2), Offset(w - 20, h / 2), ink);
        canvas.drawCircle(Offset(w / 2, h / 2), 50, ink);
      case 'era_court':
        canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), ink..strokeWidth = 3);
        for (var x = 0.0; x < w; x += 14) {
          canvas.drawLine(Offset(x, h / 2 - 20), Offset(x, h / 2), ink..strokeWidth = 1);
        }
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.12), wash);
      case 'era_table':
        canvas.drawRect(Rect.fromLTWH(0, h * 0.72, w, h * 0.28), wash);
        canvas.drawLine(Offset(0, h * 0.72), Offset(w, h * 0.72), ink);
        for (final cx in [w * 0.15, w * 0.85]) {
          canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.68), width: 10, height: 34), ink);
          canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.6), width: 8, height: 16), ink);
        }
        for (var i = 0; i < 4; i++) {
          final ax = i * w / 3.5;
          canvas.drawArc(Rect.fromLTWH(ax, 30, w / 4, 140), pi, pi, false, ink);
        }
      case 'era_bath':
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(Rect.fromLTWH(i * w / 3 + 8, 40, w / 3 - 16, 200), pi, pi, false, ink);
        }
        for (var i = 0; i < 8; i++) {
          final sx = rng.nextDouble() * w, sy = h * 0.4 + rng.nextDouble() * h * 0.5;
          final path = Path()..moveTo(sx, sy);
          for (var k = 0; k < 4; k++) {
            path.quadraticBezierTo(sx + (k.isEven ? 10 : -10), sy - 10 - k * 14, sx, sy - 20 - k * 14);
          }
          canvas.drawPath(path, ink);
        }
      case 'era_staff':
        for (var s = 0; s < 3; s++) {
          final top = 80.0 + s * (h - 160) / 3;
          for (var l = 0; l < 5; l++) {
            canvas.drawLine(Offset(16, top + l * 9), Offset(w - 16, top + l * 9), ink..strokeWidth = 1);
          }
          for (var n = 0; n < 7; n++) {
            final nx = 40 + n * (w - 80) / 7;
            final ny = top + rng.nextInt(5) * 9.0;
            canvas.drawOval(Rect.fromCenter(center: Offset(nx, ny), width: 10, height: 7), wash..color = NF.text.withValues(alpha: 0.12));
            canvas.drawLine(Offset(nx + 5, ny), Offset(nx + 5, ny - 26), ink);
          }
        }
      case 'era_raffia':
        // A band of raffia-cloth geometry, top and bottom.
        for (final y in [30.0, h - 70]) {
          for (var x = 0.0; x < w; x += 40) {
            canvas.drawPath(
              Path()
                ..moveTo(x, y + 40)
                ..lineTo(x + 20, y)
                ..lineTo(x + 40, y + 40),
              ink,
            );
            canvas.drawRect(Rect.fromLTWH(x + 14, y + 22, 12, 12), wash..color = NF.text.withValues(alpha: 0.1));
          }
        }
      case 'era_hills' || 'era_road' || 'era_window':
        final hill = Path()
          ..moveTo(0, h * 0.75)
          ..quadraticBezierTo(w * 0.25, h * 0.55, w * 0.5, h * 0.7)
          ..quadraticBezierTo(w * 0.75, h * 0.85, w, h * 0.62)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(hill, wash);
        canvas.drawPath(hill, ink);
        for (final x in [w * 0.12, w * 0.2, w * 0.82]) {
          final y = h * 0.62;
          canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 14, height: 46), ink);
        }
        if (skin.scene == 'era_road') {
          canvas.drawPath(
            Path()
              ..moveTo(w * 0.42, h)
              ..lineTo(w * 0.5, h * 0.66)
              ..lineTo(w * 0.58, h),
            ink,
          );
        }
        if (skin.scene == 'era_window') {
          canvas.drawRect(Rect.fromLTWH(24, 24, w - 48, h - 48), ink..strokeWidth = 5);
          canvas.drawLine(Offset(w / 2, 24), Offset(w / 2, h - 24), ink);
        }
      case 'era_dunes':
        for (var i = 0; i < 4; i++) {
          final y = h * (0.45 + i * 0.13);
          canvas.drawPath(
            Path()
              ..moveTo(0, y)
              ..quadraticBezierTo(w * 0.3, y - 40, w * 0.6, y)
              ..quadraticBezierTo(w * 0.8, y + 25, w, y - 10),
            ink,
          );
        }
        canvas.drawCircle(Offset(w * 0.8, 90), 26, ink);
    }
  }

  /// Chalk tally marks in fives.
  void _tallies(Canvas canvas, Offset at, int n, Color chalk) {
    final p = Paint()
      ..color = chalk.withValues(alpha: 0.16)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    var x = at.dx;
    for (var i = 0; i < n; i++) {
      if (i % 5 == 4) {
        canvas.drawLine(
          Offset(x - 26, at.dy + 18),
          Offset(x + 2, at.dy + 4),
          p,
        );
        x += 14;
      } else {
        canvas.drawLine(Offset(x, at.dy), Offset(x, at.dy + 22), p);
        x += 7;
      }
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
