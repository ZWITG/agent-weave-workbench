import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/property.dart';
import '../engine/realty.dart';

/// Sunset Strip, the look of Wealth › Real estate: a beach-town dusk. The
/// skyline on top rises from the ground with one building for each home
/// you own, redrawn from the home icons (assets/homes/). Lit windows mean
/// someone lives there; holiday lets wear fairy lights; in a crash some
/// windows go dark. No property: an empty plot waiting for your first home.

// The palette of the icons.
const _skyTop = Color(0xFF2A1060);
const _skyMid = Color(0xFF8E1F7A);
const _skyLow = Color(0xFFFF6A5C);
const _horizon = Color(0xFFFFB65E);
const _sunTop = Color(0xFFFFE08A);
const _sunLow = Color(0xFFFF7FA8);
const _ink = Color(0xFF1A0E33);
const _ground = Color(0xFF160D2E);
const _cyan = Color(0xFF5EF0EE);
const _glass = Color(0xFF7DF2F0);
const _dark = Color(0xFF3A2A5A);
const _pink = Color(0xFFFF8FB8);
const _hot = Color(0xFFFF3D8B);
const _cream = Color(0xFFFFF3E8);
const _shade = Color(0xFFE6CFE0);
const _teal = Color(0xFF4FD6D0);
const _sand = Color(0xFFF6D7A7);
const _terra = Color(0xFFE8603C);
const _brick = Color(0xFFC0583E);
const _wood = Color(0xFF9A5A34);

/// Which icon (and skyline building) a home gets.
String homeArt(Asset a) {
  if (a.kind == 'rental') {
    return switch (a.name) {
      'Studio' => 'shack',
      'One-bed flat' => 'strip',
      'Two-bed flat' => 'block',
      'Garden flat' => 'motel',
      'Loft apartment' => 'warehouse',
      'Family house' => 'modern',
      'Luxury apartment' => 'deco',
      _ => 'trailer', // a room in a shared house
    };
  }
  return typeArt(a.name, a.info['area'] as String?);
}

const _smartAreas = {'Old Town', 'Riverside', 'Hillcrest'};

String typeArt(String type, [String? area]) => switch (type) {
  'Flat' => _smartAreas.contains(area) ? 'deco' : 'block',
  'Penthouse' => 'tower',
  'Terraced house' => 'motel',
  'Semi-detached house' => 'modern',
  'Detached house' =>
    area == 'Harbour' || area == 'Riverside' ? 'stilt' : 'modern',
  'Houseboat' => 'boat',
  'Farmhouse' || 'Mansion' => 'villa',
  _ => 'motel',
};

/// Icon files in assets/homes. Art without its own file yet borrows the
/// closest one; drop a PNG named after the art in that folder to use it.
const _iconFile = {
  'trailer': 'trailer',
  'motel': 'motel',
  'stilt': 'stilt',
  'tower': 'tower',
  'villa': 'villa',
  'strip': 'motel',
  'boat': 'stilt',
  'warehouse': 'motel',
  'deco': 'tower',
  'modern': 'villa',
  'shack': 'trailer',
  'block': 'tower',
};

/// The icon for a kind of home, as a rounded tile.
class HomeIcon extends StatelessWidget {
  const HomeIcon(this.art, {super.key, this.size = 44});
  final String art;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: Image.asset(
      'assets/homes/${_iconFile[art] ?? art}.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: _skyMid,
        child: Icon(Icons.home_rounded, color: _cream, size: size * 0.55),
      ),
    ),
  );
}

/// One building on the skyline.
typedef Tower = ({String art, double scale, bool lit, bool holiday});

List<Tower> skylineOf(Life l) {
  final houses = l.assets
      .where((a) => a.kind == 'house' || a.kind == 'rental')
      .toList();
  if (houses.isEmpty) return const [];
  final top = houses.map((a) => a.value).fold(1, max);
  return [
    for (final a in houses.take(9))
      (
        art: homeArt(a),
        scale: a.kind == 'rental' ? 0.85 : 0.8 + 0.25 * a.value / top,
        lit:
            a.kind == 'rental' ||
            a.info['let'] != true ||
            isHoliday(a) ||
            tenantOf(a) != null,
        holiday: isHoliday(a),
      ),
  ];
}

/// The skyline strip at the top of Real estate.
class SunsetSkyline extends StatefulWidget {
  const SunsetSkyline({
    super.key,
    required this.towers,
    required this.economy,
    required this.full,
    this.height = 176,
  });

  final List<Tower> towers;
  final String economy;

  /// The long rise (the first visit in a life); otherwise a short one.
  final bool full;
  final double height;

  @override
  State<SunsetSkyline> createState() => _SunsetSkylineState();
}

class _SunsetSkylineState extends State<SunsetSkyline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.full ? 2200 : 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _a.value = 1;
    } else if (!_a.isAnimating && _a.value == 0) {
      _a.forward();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.towers.isEmpty
        ? 'An empty plot at sunset, waiting for your first home'
        : 'A sunset skyline of your ${widget.towers.length} homes',
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) => CustomPaint(
          painter: _SkylinePainter(
            widget.towers,
            widget.economy,
            Curves.easeOutCubic.transform(_a.value),
            _a.value,
          ),
        ),
      ),
    ),
  );
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter(this.towers, this.economy, this.p, this.raw);
  final List<Tower> towers;
  final String economy;
  final double p;
  final double raw;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gy = h - 26;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, gy),
          [_skyTop, _skyMid, _skyLow, _horizon],
          [0, 0.45, 0.82, 1],
        ),
    );
    final rng = Random(7);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.8 * p);
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * gy * 0.45),
        rng.nextDouble() * 1.2 + 0.6,
        star,
      );
    }
    // Soft cloud streaks.
    final streak = Paint()..color = const Color(0x55FF9FD0);
    for (final (x, y, l) in [(0.08, 0.30, 0.22), (0.62, 0.20, 0.25)]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          w * x,
          h * y,
          w * (x + l),
          h * y + 6,
          const Radius.circular(3),
        ),
        streak,
      );
    }

    // The sun rises with the buildings, cut by horizontal bands.
    final r = min(w * 0.22, gy * 0.62);
    final sunY = gy - r * 0.12 + (1 - p) * r * 1.1;
    final sun = Rect.fromCircle(center: Offset(w / 2, sunY), radius: r);
    canvas.saveLayer(sun, Paint());
    canvas.drawCircle(
      sun.center,
      r,
      Paint()
        ..shader = ui.Gradient.linear(sun.topCenter, sun.bottomCenter, [
          _sunTop,
          _sunLow,
        ]),
    );
    final cut = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < 5; i++) {
      final y = sunY - r * 0.05 + i * r * 0.16;
      canvas.drawRect(Rect.fromLTWH(sun.left, y, r * 2, 2.0 + i * 1.4), cut);
    }
    canvas.restore();

    // A far-off city.
    final far = Paint()
      ..color = const Color(0xFF6A1E6E).withValues(alpha: 0.42);
    var x = 0.0;
    final cr = Random(3);
    while (x < w) {
      final bw = 14 + cr.nextDouble() * 22;
      final bh = 14 + cr.nextDouble() * 34;
      canvas.drawRect(Rect.fromLTWH(x, gy - bh * p, bw, bh * p), far);
      x += bw + 3;
    }

    // Ground, the neon line and a perspective grid.
    canvas.drawRect(Rect.fromLTWH(0, gy, w, h - gy), Paint()..color = _ground);
    canvas.drawLine(
      Offset(0, gy),
      Offset(w, gy),
      Paint()
        ..color = _cyan
        ..strokeWidth = 2,
    );
    final grid = Paint()
      ..color = _hot.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = -6; i <= 6; i++) {
      canvas.drawLine(
        Offset(w / 2 + i * 14, gy),
        Offset(w / 2 + i * w * 0.18, h),
        grid,
      );
    }
    for (final f in [0.35, 0.7]) {
      final y = gy + (h - gy) * f;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // Palms frame the strip.
    _palm(canvas, Offset(18, gy), gy * 0.78, 1);
    _palm(canvas, Offset(w - 16, gy), gy * 0.7, -1);

    if (towers.isEmpty) {
      _plot(canvas, Offset(w / 2, gy), gy);
    } else {
      final n = towers.length;
      final room = w - 70;
      final slot = room / n;
      final bw = min(74.0, slot * 0.86);
      for (var i = 0; i < n; i++) {
        final t = towers[i];
        // Each building rises in turn and lights up once it has landed.
        final start = i / (n + 1) * 0.55;
        final k = ((raw - start) / 0.45).clamp(0.0, 1.0);
        final rise = Curves.easeOutBack.transform(k);
        final cx = 35 + slot * (i + 0.5);
        final bh = min(_heightOf(t.art, gy), bw * _aspect(t.art)) * t.scale;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, w, gy + 1));
        canvas.translate(0, (1 - rise) * (bh + 10));
        _building(
          canvas,
          t.art,
          Rect.fromLTRB(cx - bw / 2, gy - bh, cx + bw / 2, gy),
          lit: t.lit && k >= 1,
          dimmed: economy == 'Crash' || economy == 'Recession',
          seed: i,
        );
        if (t.holiday && k >= 1) {
          _lights(canvas, Rect.fromLTRB(cx - bw / 2, gy - bh, cx + bw / 2, gy));
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  double _heightOf(String art, double gy) =>
      gy *
      switch (art) {
        'tower' => 0.86,
        'deco' => 0.74,
        'warehouse' => 0.46,
        'motel' => 0.5,
        'strip' => 0.36,
        'trailer' => 0.3,
        'stilt' => 0.56,
        'boat' => 0.42,
        'villa' => 0.52,
        'shack' => 0.36,
        'block' => 0.66,
        _ => 0.48,
      };

  /// The tallest each building may be for its width, so wide screens do
  /// not stretch a villa into a church.
  double _aspect(String art) => switch (art) {
    'tower' => 3.2,
    'deco' => 2.4,
    'block' => 1.7,
    'stilt' => 1.3,
    'motel' => 1.15,
    'warehouse' => 0.9,
    'villa' => 0.85,
    'modern' => 0.9,
    'boat' => 0.75,
    'shack' => 0.65,
    'strip' => 0.55,
    'trailer' => 0.45,
    _ => 1.0,
  };

  // ---------------- Buildings ----------------

  Paint _fill(Color c) => Paint()..color = c;
  Paint get _line => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round;

  void _box(Canvas c, Rect r, Color fill, {double radius = 1.5}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _fill(fill));
    c.drawRRect(rr, _line);
  }

  /// The darker right-hand side the icons have.
  void _shadeRight(Canvas c, Rect r, Color shade) => c.drawRect(
    Rect.fromLTRB(
      r.right - r.width * 0.18,
      r.top,
      r.right,
      r.bottom,
    ).deflate(0.8),
    _fill(shade),
  );

  void _win(Canvas c, Rect r, bool on) {
    c.drawRect(r, _fill(on ? _glass : _dark));
    if (on) {
      c.drawLine(
        r.topLeft + const Offset(1.5, 3),
        r.topLeft + Offset(min(5, r.width * 0.4), 1),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 1,
      );
    }
    c.drawRect(r, _line..strokeWidth = 1);
  }

  void _building(
    Canvas c,
    String art,
    Rect r, {
    required bool lit,
    required bool dimmed,
    required int seed,
  }) {
    final rng = Random(seed * 13 + 1);
    bool on() => lit && !(dimmed && rng.nextInt(3) == 0);
    final w = r.width, h = r.height;
    switch (art) {
      case 'tower':
        final body = Rect.fromLTRB(
          r.left + w * 0.12,
          r.top + h * 0.08,
          r.right - w * 0.12,
          r.bottom,
        );
        _box(
          c,
          Rect.fromLTRB(
            body.left + w * 0.2,
            r.top,
            body.right - w * 0.2,
            body.top,
          ),
          _shade,
        );
        c.drawLine(
          Offset(r.center.dx, r.top),
          Offset(r.center.dx, r.top - 8),
          _line,
        );
        c.drawCircle(Offset(r.center.dx, r.top - 9), 2.4, _fill(_hot));
        _box(c, body, _cream);
        _shadeRight(c, body, _shade);
        final floors = max(4, (body.height / 13).floor());
        final fh = body.height / floors;
        for (var i = 0; i < floors - 1; i++) {
          final y = body.top + i * fh;
          _box(
            c,
            Rect.fromLTRB(body.left - 3, y, body.right + 3, y + 3),
            _pink,
            radius: 1,
          );
          _win(
            c,
            Rect.fromLTRB(body.left + 5, y + 5, body.right - 5, y + fh - 1),
            on(),
          );
        }
        _box(
          c,
          Rect.fromLTRB(
            body.center.dx - 7,
            body.bottom - fh + 2,
            body.center.dx + 7,
            body.bottom,
          ),
          _glass,
        );
      case 'deco':
        final mid = Rect.fromLTRB(
          r.left + w * 0.34,
          r.top + h * 0.06,
          r.right - w * 0.34,
          r.bottom,
        );
        final wing = Rect.fromLTRB(
          r.left + w * 0.14,
          r.top + h * 0.3,
          r.right - w * 0.14,
          r.bottom,
        );
        final low = Rect.fromLTRB(r.left, r.top + h * 0.52, r.right, r.bottom);
        _box(c, low, _pink);
        _box(c, wing, _teal);
        _box(c, mid, _cream);
        c.drawLine(
          Offset(mid.center.dx, mid.top),
          Offset(mid.center.dx, mid.top - 8),
          _line,
        );
        c.drawCircle(Offset(mid.center.dx, mid.top - 9), 2.4, _fill(_sunTop));
        _box(
          c,
          Rect.fromLTRB(mid.left - 3, mid.top - 3, mid.right + 3, mid.top + 2),
          _hot,
          radius: 1,
        );
        _box(
          c,
          Rect.fromLTRB(
            mid.center.dx - 2,
            mid.top + 8,
            mid.center.dx + 2,
            mid.bottom - 10,
          ),
          _hot,
          radius: 1,
        );
        for (var y = wing.top + 6; y < wing.bottom - 8; y += 9) {
          _win(
            c,
            Rect.fromLTWH(wing.left + 3, y, mid.left - wing.left - 6, 5),
            on(),
          );
          _win(
            c,
            Rect.fromLTWH(mid.right + 3, y, wing.right - mid.right - 6, 5),
            on(),
          );
        }
        for (var y = low.top + 6; y < low.bottom - 6; y += 9) {
          _win(
            c,
            Rect.fromLTWH(low.left + 2, y, wing.left - low.left - 4, 5),
            on(),
          );
          _win(
            c,
            Rect.fromLTWH(wing.right + 2, y, low.right - wing.right - 4, 5),
            on(),
          );
        }
        for (var y = mid.top + 8; y < mid.bottom - 10; y += 8) {
          c.drawRect(
            Rect.fromLTWH(mid.left + 3, y, 4, 4),
            _fill(on() ? _glass : _dark),
          );
          c.drawRect(
            Rect.fromLTWH(mid.right - 7, y, 4, 4),
            _fill(on() ? _glass : _dark),
          );
        }
      case 'motel':
        final body = Rect.fromLTRB(
          r.left + w * 0.06,
          r.top + h * 0.28,
          r.right - w * 0.06,
          r.bottom,
        );
        c.drawLine(
          Offset(r.right - w * 0.2, body.top),
          Offset(r.right - w * 0.2, r.top + 10),
          _line..strokeWidth = 2,
        );
        _box(
          c,
          Rect.fromLTRB(
            r.right - w * 0.36,
            r.top,
            r.right - w * 0.04,
            r.top + 12,
          ),
          _ink,
        );
        c.drawRect(
          Rect.fromLTRB(
            r.right - w * 0.32,
            r.top + 3,
            r.right - w * 0.08,
            r.top + 9,
          ),
          _fill(on() ? _hot : _dark),
        );
        _box(c, body, _pink);
        _shadeRight(c, body, const Color(0xFFE0609A));
        _box(
          c,
          Rect.fromLTRB(r.left, body.top - 4, r.right, body.top + 1),
          _cream,
          radius: 1,
        );
        final mh = body.top + body.height * 0.48;
        _box(
          c,
          Rect.fromLTRB(body.left - 2, mh - 2, body.right + 2, mh + 2),
          _cream,
          radius: 1,
        );
        for (final row in [body.top + 5, mh + 5]) {
          for (var i = 0; i < 3; i++) {
            final x = body.left + 4 + i * (body.width - 8) / 3;
            _win(
              c,
              Rect.fromLTWH(
                x,
                row,
                (body.width - 8) / 3 - 4,
                body.height * 0.48 - 10,
              ),
              on(),
            );
          }
        }
      case 'strip':
        final body = Rect.fromLTRB(r.left, r.top + h * 0.12, r.right, r.bottom);
        _box(c, body, _teal);
        _box(
          c,
          Rect.fromLTRB(r.left - 2, body.top - 3, r.right + 2, body.top + 2),
          _cream,
          radius: 1,
        );
        final n = max(2, (w / 18).floor());
        final cell = body.width / n;
        for (var i = 0; i < n; i++) {
          final x = body.left + i * cell;
          _box(
            c,
            Rect.fromLTWH(x + 2, body.top + 6, cell * 0.38, body.height - 6),
            _hot,
            radius: 1,
          );
          _win(
            c,
            Rect.fromLTWH(
              x + cell * 0.5,
              body.top + 8,
              cell * 0.42,
              body.height * 0.35,
            ),
            on(),
          );
        }
      case 'trailer':
        final body = Rect.fromLTRB(
          r.left,
          r.top + h * 0.18,
          r.right,
          r.bottom - 5,
        );
        _box(
          c,
          Rect.fromLTRB(r.left + 6, body.bottom, r.left + 14, r.bottom),
          _dark,
        );
        _box(
          c,
          Rect.fromLTRB(r.right - 14, body.bottom, r.right - 6, r.bottom),
          _dark,
        );
        _box(c, body, _cream, radius: 3);
        _box(
          c,
          Rect.fromLTRB(r.left - 2, r.top + h * 0.1, r.right + 2, body.top + 2),
          _shade,
          radius: 1,
        );
        c.drawRect(
          Rect.fromLTWH(
            body.left + 1,
            body.bottom - body.height * 0.35,
            body.width - 2,
            2.5,
          ),
          _fill(_teal),
        );
        c.drawRect(
          Rect.fromLTWH(
            body.left + 1,
            body.bottom - body.height * 0.25,
            body.width - 2,
            2,
          ),
          _fill(_hot),
        );
        _win(
          c,
          Rect.fromLTWH(
            body.left + 4,
            body.top + 4,
            w * 0.24,
            body.height * 0.3,
          ),
          on(),
        );
        _box(
          c,
          Rect.fromLTWH(body.center.dx - 5, body.top + 3, 10, body.height - 3),
          _pink,
          radius: 1,
        );
        _win(
          c,
          Rect.fromLTWH(
            body.right - 4 - w * 0.24,
            body.top + 4,
            w * 0.24,
            body.height * 0.3,
          ),
          on(),
        );
      case 'stilt':
        final body = Rect.fromLTRB(
          r.left + w * 0.08,
          r.top + h * 0.32,
          r.right - w * 0.08,
          r.top + h * 0.66,
        );
        for (var i = 0; i < 4; i++) {
          final x = body.left + 4 + i * (body.width - 8) / 3;
          _box(
            c,
            Rect.fromLTRB(x - 1.5, body.bottom, x + 1.5, r.bottom),
            _cream,
            radius: 0,
          );
        }
        _box(c, body, _teal);
        final roof = Path()
          ..moveTo(r.left, body.top + 2)
          ..lineTo(r.center.dx, r.top)
          ..lineTo(r.right, body.top + 2)
          ..close();
        c.drawPath(roof, _fill(_cream));
        c.drawPath(roof, _line);
        c.drawCircle(
          Offset(r.center.dx, r.top + (body.top - r.top) * 0.55),
          3.5,
          _fill(on() ? _glass : _dark),
        );
        _win(
          c,
          Rect.fromLTRB(
            body.left + 4,
            body.top + 4,
            body.center.dx - 2,
            body.bottom - 8,
          ),
          on(),
        );
        _win(
          c,
          Rect.fromLTRB(
            body.center.dx + 2,
            body.top + 4,
            body.right - 4,
            body.bottom - 8,
          ),
          on(),
        );
        _box(
          c,
          Rect.fromLTRB(
            body.left - 2,
            body.bottom - 6,
            body.right + 2,
            body.bottom - 2,
          ),
          _cream,
          radius: 1,
        );
      case 'boat':
        final hull = Path()
          ..moveTo(r.left, r.bottom - h * 0.3)
          ..lineTo(r.right, r.bottom - h * 0.3)
          ..lineTo(r.right - w * 0.1, r.bottom - 2)
          ..lineTo(r.left + w * 0.08, r.bottom - 2)
          ..close();
        final cabin = Rect.fromLTRB(
          r.left + w * 0.12,
          r.top + h * 0.42,
          r.right - w * 0.2,
          r.bottom - h * 0.3,
        );
        _box(
          c,
          Rect.fromLTRB(
            cabin.left + w * 0.14,
            r.top + h * 0.2,
            cabin.right - w * 0.18,
            cabin.top,
          ),
          _cream,
        );
        c.drawLine(
          Offset(cabin.center.dx, r.top + h * 0.2),
          Offset(cabin.center.dx, r.top),
          _line,
        );
        c.drawPath(
          Path()
            ..moveTo(cabin.center.dx, r.top)
            ..lineTo(cabin.center.dx + 9, r.top + 4)
            ..lineTo(cabin.center.dx, r.top + 8)
            ..close(),
          _fill(_hot),
        );
        _box(c, cabin, _pink);
        _win(
          c,
          Rect.fromLTWH(
            cabin.left + 4,
            cabin.top + 4,
            cabin.width * 0.28,
            cabin.height * 0.45,
          ),
          on(),
        );
        _win(
          c,
          Rect.fromLTWH(
            cabin.left + cabin.width * 0.38,
            cabin.top + 4,
            cabin.width * 0.28,
            cabin.height * 0.45,
          ),
          on(),
        );
        _box(
          c,
          Rect.fromLTWH(
            cabin.right - cabin.width * 0.22,
            cabin.top + 4,
            cabin.width * 0.16,
            cabin.height - 4,
          ),
          _teal,
          radius: 1,
        );
        c.drawPath(hull, _fill(_cream));
        c.drawRect(
          Rect.fromLTWH(r.left + w * 0.04, r.bottom - h * 0.16, w * 0.9, 3),
          _fill(_hot),
        );
        c.drawPath(hull, _line);
      case 'warehouse':
        final body = Rect.fromLTRB(r.left, r.top + h * 0.26, r.right, r.bottom);
        final teeth = 4;
        final tw = body.width / teeth;
        for (var i = 0; i < teeth; i++) {
          final tooth = Path()
            ..moveTo(body.left + i * tw, body.top)
            ..lineTo(body.left + i * tw, r.top)
            ..lineTo(body.left + (i + 1) * tw, body.top)
            ..close();
          c.drawPath(tooth, _fill(const Color(0xFF9AA4C0)));
          c.drawRect(
            Rect.fromLTWH(
              body.left + i * tw + 1,
              r.top + 2,
              3,
              body.top - r.top - 2,
            ),
            _fill(on() ? _sunTop : _dark),
          );
          c.drawPath(tooth, _line);
        }
        _box(c, body, _brick);
        _shadeRight(c, body, const Color(0xFF9C4330));
        _box(
          c,
          Rect.fromLTRB(
            body.center.dx - w * 0.14,
            body.top + body.height * 0.35,
            body.center.dx + w * 0.14,
            body.bottom,
          ),
          const Color(0xFF8E80B4),
          radius: 0,
        );
        _win(
          c,
          Rect.fromLTRB(
            body.left + 4,
            body.top + 5,
            body.center.dx - w * 0.18,
            body.top + body.height * 0.5,
          ),
          on(),
        );
        _win(
          c,
          Rect.fromLTRB(
            body.center.dx + w * 0.18,
            body.top + 5,
            body.right - 4,
            body.top + body.height * 0.5,
          ),
          on(),
        );
        c.drawRect(
          Rect.fromLTRB(
            body.center.dx - 6,
            body.top + 4,
            body.center.dx + 6,
            body.top + 9,
          ),
          _fill(_hot),
        );
      case 'villa':
        final body = Rect.fromLTRB(
          r.left + w * 0.04,
          r.top + h * 0.42,
          r.right - w * 0.04,
          r.bottom,
        );
        final mid = Rect.fromLTRB(
          r.center.dx - w * 0.17,
          r.top + h * 0.22,
          r.center.dx + w * 0.17,
          r.bottom,
        );
        for (final roofOf in [body, mid]) {
          final roof = Path()
            ..moveTo(roofOf.left - 4, roofOf.top + 1)
            ..lineTo(
              roofOf.center.dx,
              roofOf.top - (roofOf == mid ? h * 0.22 : h * 0.14),
            )
            ..lineTo(roofOf.right + 4, roofOf.top + 1)
            ..close();
          if (roofOf == body) {
            c.drawPath(roof, _fill(_terra));
            c.drawPath(roof, _line);
            _box(c, body, _sand);
            _shadeRight(c, body, const Color(0xFFE6AE78));
          } else {
            _box(c, mid, _sand);
            c.drawPath(roof, _fill(_terra));
            c.drawPath(roof, _line);
          }
        }
        for (final x in [
          body.left + 4,
          body.left + 12,
          mid.right + 5,
          mid.right + 13,
        ]) {
          final win = RRect.fromRectAndCorners(
            Rect.fromLTWH(x, body.top + 8, 6, body.height * 0.42),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          );
          c.drawRRect(win, _fill(on() ? _glass : _dark));
          c.drawRRect(win, _line..strokeWidth = 1);
        }
        _box(
          c,
          Rect.fromLTWH(
            mid.center.dx - 5,
            mid.bottom - mid.height * 0.32,
            10,
            mid.height * 0.32,
          ),
          _wood,
          radius: 4,
        );
        _win(c, Rect.fromLTWH(mid.center.dx - 4, mid.top + 6, 8, 9), on());
      case 'shack':
        final body = Rect.fromLTRB(
          r.left + w * 0.06,
          r.top + h * 0.3,
          r.right - w * 0.22,
          r.bottom,
        );
        _box(c, body, const Color(0xFFD9A066));
        _shadeRight(c, body, const Color(0xFFB98048));
        for (var y = body.top + 7; y < body.bottom - 2; y += 7) {
          c.drawLine(
            Offset(body.left + 1, y),
            Offset(body.right - 1, y),
            Paint()
              ..color = const Color(0xFFB98048)
              ..strokeWidth = 1,
          );
        }
        final roof = Path()
          ..moveTo(body.left - 4, body.top + 4)
          ..lineTo(body.right + 5, r.top + h * 0.12)
          ..lineTo(body.right + 5, r.top + h * 0.12 + 6)
          ..lineTo(body.left - 4, body.top + 10)
          ..close();
        c.drawPath(roof, _fill(const Color(0xFF9AA4C0)));
        c.drawPath(roof, _line);
        _win(
          c,
          Rect.fromLTWH(
            body.left + 4,
            body.top + 12,
            body.width * 0.26,
            body.height * 0.3,
          ),
          on(),
        );
        _box(
          c,
          Rect.fromLTWH(
            body.center.dx - 4,
            body.top + 10,
            body.width * 0.24,
            body.height - 10,
          ),
          _wood,
          radius: 0,
        );
        for (final (dx, col) in [(0.82, _cyan), (0.93, _sunTop)]) {
          final board = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(r.left + w * dx, r.bottom - h * 0.26),
              width: 6,
              height: h * 0.5,
            ),
            const Radius.circular(3),
          );
          c.drawRRect(board, _fill(col));
          c.drawRRect(board, _line..strokeWidth = 1);
        }
      case 'block':
        final body = Rect.fromLTRB(
          r.left + w * 0.06,
          r.top + h * 0.14,
          r.right - w * 0.06,
          r.bottom,
        );
        _box(
          c,
          Rect.fromLTRB(
            r.center.dx - w * 0.12,
            r.top,
            r.center.dx + w * 0.16,
            r.top + h * 0.08,
          ),
          const Color(0xFF8E80B4),
        );
        c.drawLine(
          Offset(r.center.dx - w * 0.06, r.top + h * 0.08),
          Offset(r.center.dx - w * 0.06, body.top),
          _line,
        );
        c.drawLine(
          Offset(r.center.dx + w * 0.1, r.top + h * 0.08),
          Offset(r.center.dx + w * 0.1, body.top),
          _line,
        );
        _box(c, body, const Color(0xFFDB8E68));
        _shadeRight(c, body, const Color(0xFFB8694A));
        _box(
          c,
          Rect.fromLTRB(
            body.left - 3,
            body.top - 3,
            body.right + 3,
            body.top + 2,
          ),
          const Color(0xFF7A4A5E),
          radius: 1,
        );
        final cols = max(3, (body.width / 13).floor());
        final cw = (body.width - 6) / cols;
        for (var y = body.top + 6; y < body.bottom - 14; y += 10) {
          for (var i = 0; i < cols; i++) {
            final lit = on();
            final win = Rect.fromLTWH(body.left + 4 + i * cw, y, cw - 4, 6);
            // Some flats have their lamps on: warm yellow, not glass.
            c.drawRect(
              win,
              _fill(
                !lit
                    ? _dark
                    : rng.nextInt(4) == 0
                    ? _sunTop
                    : _glass,
              ),
            );
            c.drawRect(win, _line..strokeWidth = 1);
          }
        }
        _box(
          c,
          Rect.fromLTRB(
            body.center.dx - 6,
            body.bottom - 12,
            body.center.dx + 6,
            body.bottom,
          ),
          _skyTop,
          radius: 0,
        );
      default: // modern
        final up = Rect.fromLTRB(
          r.left + w * 0.22,
          r.top,
          r.right,
          r.top + h * 0.5,
        );
        final low = Rect.fromLTRB(
          r.left,
          r.top + h * 0.48,
          r.right - w * 0.2,
          r.bottom,
        );
        _box(c, low, _cream);
        _box(c, up, _cream);
        _box(
          c,
          Rect.fromLTRB(up.left - 2, up.top - 3, up.right + 2, up.top + 2),
          _skyTop,
          radius: 1,
        );
        _win(
          c,
          Rect.fromLTRB(up.left + 4, up.top + 6, up.right - 4, up.bottom - 6),
          on(),
        );
        _win(
          c,
          Rect.fromLTRB(
            low.left + 4,
            low.top + 8,
            low.center.dx + 4,
            low.bottom - 8,
          ),
          on(),
        );
        _box(
          c,
          Rect.fromLTRB(
            low.center.dx + 8,
            low.top + 8,
            low.center.dx + 17,
            low.bottom,
          ),
          _wood,
          radius: 0,
        );
        _box(
          c,
          Rect.fromLTRB(
            r.right - w * 0.18,
            r.bottom - 5,
            r.right + 2,
            r.bottom,
          ),
          _glass,
          radius: 3,
        );
    }
  }

  void _lights(Canvas c, Rect r) {
    const colors = [_hot, _sunTop, _cyan, Colors.white];
    for (var i = 0; i <= 8; i++) {
      final x = r.left + r.width * i / 8;
      final y = r.top + 4 + sin(i * pi / 4) * 2;
      c.drawCircle(Offset(x, y), 1.8, _fill(colors[i % colors.length]));
    }
  }

  void _palm(Canvas c, Offset base, double height, int dir) {
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = base + Offset(dir * 10.0, -height);
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + dir * 2,
        base.dy - height * 0.5,
        top.dx,
        top.dy,
      );
    c.drawPath(trunk, p..strokeWidth = 4.5);
    p.strokeWidth = 4;
    for (final (dx, dy, bend) in [
      (-30.0, 10.0, -8.0),
      (-22.0, 22.0, -2.0),
      (26.0, 12.0, -8.0),
      (20.0, 24.0, 0.0),
      (4.0, -16.0, -6.0),
    ]) {
      final end = top + Offset(dx, dy);
      c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            (top.dx + end.dx) / 2,
            min(top.dy, end.dy) + bend,
            end.dx,
            end.dy,
          ),
        p,
      );
    }
  }

  /// No property yet: a plot with a sign.
  void _plot(Canvas c, Offset base, double gy) {
    final post = Paint()
      ..color = _cream
      ..strokeWidth = 3;
    final top = base.dy - gy * 0.42 * p;
    c.drawLine(
      Offset(base.dx - 38, base.dy),
      Offset(base.dx - 38, top + 20),
      post,
    );
    c.drawLine(
      Offset(base.dx + 38, base.dy),
      Offset(base.dx + 38, top + 20),
      post,
    );
    final board = Rect.fromCenter(
      center: Offset(base.dx, top + 12),
      width: 120,
      height: 34,
    );
    _box(c, board, _hot, radius: 6);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'YOUR FIRST HOME\nGOES HERE',
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: _cream,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 116);
    tp.paint(c, board.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_SkylinePainter old) =>
      old.p != p || old.raw != raw || old.towers != towers;
}
