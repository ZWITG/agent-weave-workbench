import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../engine/justice.dart' show crimeById;
import '../engine/models.dart';
import '../game_controller.dart';
import '../sound.dart';
import '../theme.dart';
import 'yard_time.dart';

// Lockdown: the moment the game changes hands. When a sentence starts, the
// screen you were on is frozen, a siren washes over it, cell bars slam down
// (a clang and a shake), then Yard Time green creeps out of every bar and
// eats the old colours away, top first, until the old look is gone. An
// inmate number is stamped across it and the bars lift into the fence at
// the top. On release the gate slides open instead and the night look comes
// back through the gap.
//
// The old screen is a snapshot taken just before the game rebuilds in its
// new palette, so both looks are on screen at once while one consumes the
// other. Tap to skip; Reduce motion turns it into a short fade.

enum _Kind { enter, release }

class Lockdown extends StatefulWidget {
  const Lockdown({
    super.key,
    required this.controller,
    required this.reduceMotion,
    required this.child,
  });

  final GameController controller;
  final bool reduceMotion;
  final Widget child;

  /// Turned off by tests that do not want to wait for it.
  static bool enabled = true;

  @override
  State<Lockdown> createState() => _LockdownState();
}

class _LockdownState extends State<Lockdown>
    with SingleTickerProviderStateMixin {
  final _shotKey = GlobalKey();
  late final AnimationController _anim;
  Life? _life;
  Prison? _prison;
  bool _inside = false;

  _Kind? _kind;
  ui.Image? _shot;
  String _stamp = '';
  String _number = '';
  String _sub = '';
  final _cued = <String>{};

  GameController get c => widget.controller;

  bool get _isInside {
    final l = c.life;
    return l != null && l.alive && l.prison != null;
  }

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(_cues)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
    _life = c.life;
    _inside = _isInside;
    _prison = _life?.prison;
    c.addListener(_changed);
  }

  @override
  void didUpdateWidget(Lockdown old) {
    super.didUpdateWidget(old);
    if (old.controller != c) {
      old.controller.removeListener(_changed);
      c.addListener(_changed);
    }
  }

  /// Runs when the game changes, before it rebuilds: the last frame is
  /// still on screen, so it can be photographed.
  void _changed() {
    final l = c.life;
    final now = _isInside;
    final sameLife = identical(l, _life);
    final was = _inside;
    final before = _prison;
    _life = l;
    _inside = now;
    if (now) _prison = l!.prison;
    // Only a sentence starting or ending in the life being played: not a
    // new life, a loaded save, a rewind or a death.
    if (now == was || !sameLife || l == null || !l.alive) return;
    if (!Lockdown.enabled || _kind != null) return;
    _shot?.dispose();
    _shot = _capture();
    if (now) {
      final p = l.prison!;
      _kind = _Kind.enter;
      _stamp = p.youth ? 'DETAINED' : 'BOOKED';
      _number = 'INMATE #${inmateNumber(l)}';
      _sub =
          '${crimeById(p.crime).label} · ${p.years} ${p.years == 1 ? 'year' : 'years'}';
    } else {
      final escaped = l.flags['escaped']?.age == l.age;
      final served = before?.served ?? 0;
      _kind = _Kind.release;
      _stamp = escaped ? 'ESCAPED' : 'RELEASED';
      _number = '';
      _sub = escaped
          ? 'Keep your head down'
          : served == 0
          ? 'Out already'
          : 'After $served ${served == 1 ? 'year' : 'years'} inside';
    }
    _cued.clear();
    _anim.duration = widget.reduceMotion
        ? const Duration(milliseconds: 450)
        : _kind == _Kind.enter
        ? const Duration(milliseconds: 4600)
        : const Duration(milliseconds: 2800);
    _anim.forward(from: 0);
    // The rebuild in the new palette is already on its way.
    setState(() {});
  }

  ui.Image? _capture() {
    try {
      final b = _shotKey.currentContext?.findRenderObject();
      if (b is! RenderRepaintBoundary || !b.hasSize) return null;
      final dpr = min(MediaQuery.devicePixelRatioOf(context), 2.0);
      return b.toImageSync(pixelRatio: dpr);
    } catch (_) {
      // No snapshot (an old web renderer, or mid-paint): the animation
      // still plays over a flat wash of the old colour.
      return null;
    }
  }

  /// Sounds and haptics at their beats.
  void _cues() {
    if (widget.reduceMotion) return;
    final t = _anim.value;
    void at(String id, double when, VoidCallback f) {
      if (t >= when && _cued.add(id)) f();
    }

    if (_kind == _Kind.enter) {
      at('siren', 0.0, () => Sound.instance.cue('siren'));
      at('clang', _Beat.slam, () {
        HapticFeedback.heavyImpact();
        Sound.instance.cue('clang');
      });
      at('stamp', _Beat.stampLand, () {
        HapticFeedback.mediumImpact();
        Sound.instance.hit();
      });
    } else {
      at('gate', 0.05, () => Sound.instance.cue('gate'));
    }
  }

  void _finish() {
    if (!mounted) return;
    _anim.stop();
    setState(() {
      _kind = null;
      _shot?.dispose();
      _shot = null;
    });
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _anim.dispose();
    _shot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The game always stays first in the stack, so it keeps its state
    // while the overlay comes and goes.
    final kind = _kind;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _shotKey, child: widget.child),
        if (kind != null)
          Positioned.fill(
            child: Semantics(
              label: kind == _Kind.enter
                  ? 'You are in prison. $_number. $_sub.'
                  : '$_stamp. $_sub.',
              liveRegion: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Tap to skip once the bars are down.
                onTap: () {
                  if (_anim.value > 0.2 || widget.reduceMotion) _finish();
                },
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _LockdownPainter(
                      kind: kind,
                      t: _anim.value,
                      shot: _shot,
                      fade: widget.reduceMotion,
                      stamp: _stamp,
                      number: _number,
                      sub: _sub,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Where the beats of the entry fall, as fractions of its length.
abstract final class _Beat {
  static const barsFrom = 0.10;
  static const slam = 0.30;
  static const consumeFrom = 0.34;
  static const consumeTo = 0.80;
  static const stampFrom = 0.64;
  static const stampLand = 0.70;
  static const liftFrom = 0.86;
}

class _LockdownPainter extends CustomPainter {
  _LockdownPainter({
    required this.kind,
    required this.t,
    required this.shot,
    required this.fade,
    required this.stamp,
    required this.number,
    required this.sub,
  });

  final _Kind kind;
  final double t;
  final ui.Image? shot;
  final bool fade;
  final String stamp;
  final String number;
  final String sub;

  // The two looks, whichever palette is live right now.
  NFPalette get _old => kind == _Kind.enter ? nightFeed : yardTime;

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (fade) {
      _drawOld(canvas, size, Offset.zero & size, opacity: 1 - t);
      return;
    }
    if (kind == _Kind.enter) {
      _enter(canvas, size);
    } else {
      _release(canvas, size);
    }
  }

  /// The old screen (or its colour) inside [clip].
  void _drawOld(
    Canvas canvas,
    Size size,
    Rect bounds, {
    Path? clip,
    double opacity = 1,
    double drain = 0,
  }) {
    canvas.save();
    if (clip != null) canvas.clipPath(clip);
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0))
      ..filterQuality = FilterQuality.medium;
    if (drain > 0) paint.colorFilter = ColorFilter.matrix(_drain(drain));
    final img = shot;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Offset.zero & size,
        paint,
      );
    } else {
      canvas.drawRect(
        bounds,
        Paint()..color = _old.bg.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }
    canvas.restore();
  }

  /// Colour draining out towards a cold grey-green as the yard takes over.
  static List<double> _drain(double k) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final s = 1 - 0.75 * k;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 10 * k,
      r * i, g * i, b * i + s, 0, 4 * k,
      0, 0, 0, 1, 0,
    ];
  }

  // ---------------- Going in ----------------

  void _enter(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = max(4, (w / 74).round());
    final gap = w / n;
    final barW = min(16.0, gap * 0.2);

    // Shake after the slam.
    final shake = _seg(t, _Beat.slam, _Beat.slam + 0.1);
    final amp = t >= _Beat.slam && shake < 1 ? 9 * (1 - shake) : 0.0;
    final dx = amp * sin(shake * 40);
    final dy = amp * 0.5 * cos(shake * 33);
    canvas.save();
    canvas.translate(dx, dy);

    // 1. The old screen, eaten away from each bar once they are down.
    final consume = Curves.easeInOutCubic.transform(
      _seg(t, _Beat.consumeFrom, _Beat.consumeTo),
    );
    final remaining = consume <= 0
        ? null
        : _uneaten(size, n, gap, barW, consume);
    if (consume < 1) {
      _drawOld(
        canvas,
        size,
        Offset.zero & size,
        clip: remaining,
        drain: _seg(t, _Beat.slam, _Beat.consumeTo),
      );
      // The creeping edge: wet chalk-green where the yard meets the old.
      if (remaining != null) {
        canvas.drawPath(
          remaining,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = yardTime.orange.withValues(alpha: 0.25 * (1 - consume))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawPath(
          remaining,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = yardTime.orange.withValues(alpha: 0.8 * (1 - consume)),
        );
      }
    }

    // 2. Siren: red and blue light washing in from the sides.
    final siren = 1 - _seg(t, 0.0, 0.26);
    if (siren > 0) {
      final redSide = (t * 9).floor().isEven;
      final pulse = 0.5 + 0.5 * sin(t * 9 * pi * 2);
      for (final (left, color) in [
        (true, redSide ? const Color(0xFFFF3B3B) : const Color(0xFF3B6BFF)),
        (false, redSide ? const Color(0xFF3B6BFF) : const Color(0xFFFF3B3B)),
      ]) {
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = RadialGradient(
              center: Alignment(left ? -1.2 : 1.2, -0.6),
              radius: 1.1,
              colors: [
                color.withValues(
                  alpha: 0.42 * siren * (left ? pulse : 1 - pulse),
                ),
                color.withValues(alpha: 0),
              ],
            ).createShader(Offset.zero & size),
        );
      }
    }

    // 3. The bars: they fall heavy, all landing on the slam, and lift away
    // into the fence at the end.
    final lift = Curves.easeInCubic.transform(_seg(t, _Beat.liftFrom, 1));
    if (t >= _Beat.barsFrom && lift < 1) {
      final barTop = -h * lift;
      for (var k = 0; k <= n; k++) {
        // Outer bars first, closing in on the middle.
        final order = (k - n / 2).abs() / (n / 2);
        final start = _Beat.barsFrom + (1 - order) * 0.08;
        final fall = Curves.easeInQuad.transform(
          _seg(t, start, _Beat.slam - 0.02 + (1 - order) * 0.02),
        );
        final top = t < _Beat.slam ? -h * (1 - fall) : barTop;
        _bar(canvas, k * gap, top, h, barW);
      }
      // Two flat crossbars.
      final drop = Curves.easeInQuad.transform(
        _seg(t, _Beat.barsFrom + 0.06, _Beat.slam),
      );
      final top = t < _Beat.slam ? -h * (1 - drop) : barTop;
      for (final y in [h * 0.16, h * 0.84]) {
        _crossbar(canvas, Rect.fromLTWH(-4, top + y - 7, w + 8, 14));
      }
    }
    canvas.restore();

    // 4. The stamp.
    _stampPlate(
      canvas,
      size,
      appear: Curves.easeInExpo.transform(
        _seg(t, _Beat.stampFrom, _Beat.stampLand),
      ),
      fadeOut: _seg(t, 0.9, 1),
    );
  }

  /// What is left of the old screen: one jagged column per gap between
  /// bars, narrowing from both bars as the yard spreads, the top first.
  Path _uneaten(Size size, int n, double gap, double barW, double p) {
    final h = size.height;
    final path = Path();
    const step = 10.0;
    for (var k = 0; k < n; k++) {
      final left = <Offset>[];
      final right = <Offset>[];
      final x0 = k * gap + barW / 2;
      final x1 = (k + 1) * gap - barW / 2;
      final half = (x1 - x0) / 2;
      for (var y = -step; y <= h + step; y += step) {
        final local = (p * 1.4 - (y / h) * 0.4).clamp(0.0, 1.0);
        final jag = sin(local * pi) * 9;
        final a = local * (half + 6) + _wobble(y, k * 2) * jag;
        final b = local * (half + 6) + _wobble(y, k * 2 + 1) * jag;
        var l = x0 + a;
        var r = x1 - b;
        if (l > r) l = r = (l + r) / 2;
        left.add(Offset(l, y));
        right.add(Offset(r, y));
      }
      path.addPolygon([...left, ...right.reversed], true);
    }
    return path;
  }

  static double _wobble(double y, int k) =>
      0.55 * sin(y * 0.041 + k * 1.7) +
      0.3 * sin(y * 0.127 + k * 3.1) +
      0.15 * sin(y * 0.33 + k * 0.9);

  void _bar(Canvas canvas, double cx, double top, double h, double w) {
    final r = Rect.fromLTWH(cx - w / 2, top, w, h);
    canvas.drawRect(
      r.shift(const Offset(5, 0)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(w / 2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1C2622),
            Color(0xFF6F8A80),
            Color(0xFFB9CCC4),
            Color(0xFF4A5E57),
            Color(0xFF141C19),
          ],
          stops: [0, 0.3, 0.45, 0.7, 1],
        ).createShader(r),
    );
  }

  void _crossbar(Canvas canvas, Rect r) {
    canvas.drawRect(
      r.shift(const Offset(0, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FA69D), Color(0xFF3B4C46), Color(0xFF1A2420)],
        ).createShader(r),
    );
    // Rivets.
    final rivet = Paint()..color = const Color(0xFFB9CCC4);
    for (var x = r.left + 20; x < r.right; x += 37) {
      canvas.drawCircle(Offset(x, r.center.dy), 1.6, rivet);
    }
  }

  /// The stencil plate stamped over the middle of the screen.
  void _stampPlate(
    Canvas canvas,
    Size size, {
    required double appear,
    required double fadeOut,
  }) {
    if (appear <= 0 || fadeOut >= 1) return;
    // Chalk-mint on the way in, the warm night orange on the way out.
    final look = kind == _Kind.enter ? yardTime : nightFeed;
    final ink = look.orange;
    final alpha = (appear * (1 - fadeOut)).clamp(0.0, 1.0);
    final scale = 1 + 1.4 * (1 - appear);
    final width = min(size.width - 48, 340.0);

    TextPainter text(String s, TextStyle style) => TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width - 28);

    final big = text(
      stamp,
      NF.stencil(width < 300 ? 38 : 46, color: ink.withValues(alpha: alpha)),
    );
    final num = number.isEmpty
        ? null
        : text(number, NF.stencil(17, color: ink.withValues(alpha: alpha)));
    final line = text(
      sub,
      NF.chalk(24, color: look.text.withValues(alpha: alpha)),
    );
    final h =
        20 +
        big.height +
        (num == null ? 0 : num.height + 6) +
        8 +
        line.height +
        18;

    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.46);
    canvas.rotate(-0.07);
    canvas.scale(scale);
    final plate = Rect.fromCenter(center: Offset.zero, width: width, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate.inflate(10), const Radius.circular(14)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(6)),
      Paint()..color = look.nav.withValues(alpha: 0.94 * alpha),
    );
    // A double inked border, slightly broken like a worn stamp.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = ink.withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate.deflate(5), const Radius.circular(4)),
      border,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate.deflate(11), const Radius.circular(2)),
      border..strokeWidth = 1.2,
    );
    final rng = Random(stamp.length * 7 + sub.length);
    final worn = Paint()..color = look.nav.withValues(alpha: 0.9 * alpha);
    for (var i = 0; i < 7; i++) {
      final onTop = rng.nextBool();
      final x = plate.left + 12 + rng.nextDouble() * (plate.width - 24);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, onTop ? plate.top + 5 : plate.bottom - 5),
          width: 3 + rng.nextDouble() * 9,
          height: 5,
        ),
        worn,
      );
    }
    var y = plate.top + 20;
    big.paint(canvas, Offset(-big.width / 2, y));
    y += big.height + 6;
    if (num != null) {
      num.paint(canvas, Offset(-num.width / 2, y));
      y += num.height;
    }
    y += 8;
    line.paint(canvas, Offset(-line.width / 2, y));
    canvas.restore();
  }

  // ---------------- Coming out ----------------

  void _release(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = max(4, (w / 74).round());
    final gap = w / n;
    final barW = min(16.0, gap * 0.2);
    final barsIn = _seg(t, 0, 0.1);
    final open = Curves.easeInOutCubic.transform(_seg(t, 0.12, 0.72));
    final fadeAll = _seg(t, 0.82, 1);
    final o = open * (w / 2 + gap);

    // Daylight through the gap, then the old yard either side of it.
    if (open > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            radius: 0.9,
            colors: [
              nightFeed.orange.withValues(alpha: 0.3 * (1 - fadeAll)),
              nightFeed.orange.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    final rest = Path()
      ..addRect(Rect.fromLTRB(-1, -1, w / 2 - o, h + 1))
      ..addRect(Rect.fromLTRB(w / 2 + o, -1, w + 1, h + 1));
    _drawOld(
      canvas,
      size,
      Offset.zero & size,
      clip: rest,
      opacity: 1 - fadeAll,
    );

    // The gate: bars ride the two edges of the opening.
    if (fadeAll < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, barsIn * (1 - fadeAll)),
      );
      for (var k = 0; k <= n; k++) {
        final x = k * gap;
        final shift = x < w / 2 ? -o : o;
        _bar(canvas, x + shift, 0, h, barW);
      }
      for (final y in [h * 0.16, h * 0.84]) {
        _crossbar(canvas, Rect.fromLTRB(-4, y - 7, w / 2 - o, y + 7));
        _crossbar(canvas, Rect.fromLTRB(w / 2 + o, y - 7, w + 4, y + 7));
      }
      canvas.restore();
    }

    _stampPlate(
      canvas,
      size,
      appear: Curves.easeOutBack.transform(_seg(t, 0.3, 0.42)).clamp(0, 1),
      fadeOut: _seg(t, 0.82, 1),
    );
  }

  @override
  bool shouldRepaint(_LockdownPainter old) =>
      old.t != t || old.shot != shot || old.kind != kind;
}
