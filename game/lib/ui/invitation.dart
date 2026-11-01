import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/echelon.dart';
import '../engine/elite.dart' show upperEchelon, richerThan;
import '../engine/models.dart';
import '../game_controller.dart';
import '../sound.dart';
import 'echelon_screen.dart' show Gilt;
import 'lockdown.dart' show Lockdown, moltenDuration;

// The Invitation: the moment you cross into the upper echelon. The screen
// goes dark, a black envelope edged in gold rises, a gold wax seal stamps
// it and cracks, the flap opens and an engraved card slides out: "You are
// cordially invited — The Upper Echelon". Each later tier (Half-billionaire,
// Billionaire...) gets a gold plaque dropped in with a burst of sparks.
// Tap to skip; Reduce motion turns both into a short fade.

enum _Kind { invite, tier }

class Ascension extends StatefulWidget {
  const Ascension({
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
  State<Ascension> createState() => _AscensionState();
}

class _AscensionState extends State<Ascension>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Life? _life;
  bool _upper = false;
  int _tier = -1;
  _Kind? _kind;
  String _title = '';
  String _sub = '';
  bool _cued = false;
  Timer? _wait;

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(() {
        if (!_cued && _anim.value > (_kind == _Kind.invite ? 0.45 : 0.25)) {
          _cued = true;
          if (!widget.reduceMotion) {
            HapticFeedback.mediumImpact();
            Sound.instance.cue(_kind == _Kind.invite ? 'celebrate' : 'promote');
          }
        }
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
    _remember();
    c.addListener(_changed);
  }

  void _remember() {
    _life = c.life;
    _upper = _life != null && upperEchelon(_life!);
    _tier = _life == null ? -1 : tierReached(_life!);
  }

  void _changed() {
    final l = c.life;
    final same = identical(l, _life);
    final wasUpper = _upper;
    final wasTier = _tier;
    _remember();
    if (!same || l == null || !l.alive || !Ascension.enabled) return;
    if (_kind != null) return;
    final upper = upperEchelon(l);
    final tier = tierReached(l);
    if (upper && !wasUpper) {
      _kind = _Kind.invite;
      final t = max(0, tier);
      _title = echelonTiers[t].name;
      final n = richerThan(l.netWorth);
      _sub = n > 1000
          ? 'One of about ${(n / 1000).round()},000 people this rich'
          : 'One of the few hundred richest people alive';
    } else if (upper && tier > wasTier && tier > 0) {
      _kind = _Kind.tier;
      _title = echelonTiers[tier].name;
      _sub = echelonTiers[tier].unlocks;
    } else {
      return;
    }
    _cued = false;
    _anim.duration = widget.reduceMotion
        ? const Duration(milliseconds: 600)
        : _kind == _Kind.invite
        ? const Duration(milliseconds: 5200)
        : const Duration(milliseconds: 3400);
    // The Invitation waits for the molten gold (lockdown.dart) to settle.
    _wait?.cancel();
    if (_kind == _Kind.invite && Lockdown.enabled && !widget.reduceMotion) {
      _anim.value = 0;
      _wait = Timer(moltenDuration * 0.9, () {
        if (mounted && _kind != null) _anim.forward(from: 0);
      });
    } else {
      _anim.forward(from: 0);
    }
    setState(() {});
  }

  void _finish() {
    if (!mounted) return;
    _anim.stop();
    setState(() => _kind = null);
  }

  @override
  void dispose() {
    _wait?.cancel();
    c.removeListener(_changed);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (kind != null)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: kind == _Kind.invite
                  ? 'You are invited to the Upper Echelon. $_title. $_sub.'
                  : 'New tier: $_title. Unlocks $_sub.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_anim.value > 0.15 || widget.reduceMotion) _finish();
                },
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _Painter(
                      kind: kind,
                      t: _anim.value,
                      fade: widget.reduceMotion,
                      title: _title,
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

class _Painter extends CustomPainter {
  _Painter({
    required this.kind,
    required this.t,
    required this.fade,
    required this.title,
    required this.sub,
  });

  final _Kind kind;
  final double t;
  final bool fade;
  final String title;
  final String sub;

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  TextPainter _text(
    String s,
    double size, {
    Color color = Gilt.ivory,
    FontWeight weight = FontWeight.w500,
    double spacing = 0,
    String family = 'Playfair',
    double max = 300,
  }) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color,
        letterSpacing: spacing,
        height: 1.15,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 3,
  )..layout(maxWidth: max);

  @override
  void paint(Canvas canvas, Size size) {
    final out = 1 - _seg(t, fade ? 0.5 : 0.9, 1);
    // The veil.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Gilt.bg.withValues(alpha: 0.93 * _seg(t, 0, 0.1) * out),
    );
    if (fade) {
      _card(canvas, size, size.center(Offset.zero), out, 1);
      return;
    }
    if (kind == _Kind.invite) {
      _invite(canvas, size, out);
    } else {
      _plaque(canvas, size, out);
    }
  }

  // ---------------- The invitation ----------------

  void _invite(Canvas canvas, Size size, double out) {
    final w = min(size.width - 48, 320.0);
    final h = w * 0.64;
    final rise = Curves.easeOutCubic.transform(_seg(t, 0.08, 0.32));
    final cx = size.width / 2;
    final restY = size.height * 0.58;
    final y = restY + (1 - rise) * (size.height * 0.6);
    final env = Rect.fromCenter(center: Offset(cx, y), width: w, height: h);

    // The card rises out of the envelope once the flap is open, and comes
    // clear of the pocket to sit in front of it.
    final slide = Curves.easeOutCubic.transform(_seg(t, 0.56, 0.82));
    final cardCenter = Offset(cx, y - h * 0.1 - slide * h * 1.25);
    final cardOut = slide >= 0.78;
    final envFade = 1 - 0.65 * _seg(t, 0.7, 0.85);
    final cardScale = w * 0.9 / 300;

    // The flap: closed (pointing down) until it flips open.
    final open = Curves.easeInOut.transform(_seg(t, 0.46, 0.58));
    final flapTip = env.top + h * 0.55 * (1 - 2 * open);
    final flap = Path()
      ..moveTo(env.left, env.top)
      ..lineTo(cx, flapTip)
      ..lineTo(env.right, env.top)
      ..close();

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(0, 0, 0, out),
    );
    final paper = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1712), Color(0xFF050504)],
      ).createShader(env);
    final rim = Paint()
      ..color = Gilt.gold.withValues(alpha: envFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    void drawFlap() {
      canvas.drawPath(
        flap,
        Paint()
          ..color =
              (open > 0.5 ? const Color(0xFF0F0D0A) : const Color(0xFF1D1912))
                  .withValues(alpha: envFade),
      );
      canvas.drawPath(flap, rim);
    }

    // Back of the envelope, and the open flap behind the card.
    canvas.drawRRect(
      RRect.fromRectAndRadius(env, const Radius.circular(6)),
      paper..color = Color.fromRGBO(0, 0, 0, envFade),
    );
    if (open > 0.5) drawFlap();
    if (slide > 0 && !cardOut) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, env.top + h * 0.5));
      _card(canvas, size, cardCenter, 1, cardScale);
      canvas.restore();
    }
    // Front pocket: two side folds and the bottom fold.
    final front = Path()
      ..moveTo(env.left, env.top + h * 0.35)
      ..lineTo(cx, env.top + h * 0.62)
      ..lineTo(env.right, env.top + h * 0.35)
      ..lineTo(env.right, env.bottom)
      ..lineTo(env.left, env.bottom)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15120D), Color(0xFF0A0907)],
        ).createShader(env)
        ..color = Color.fromRGBO(0, 0, 0, envFade),
    );
    canvas.drawPath(front, rim);
    // The sides and bottom; the top edge belongs to the back, behind the card.
    canvas.drawPath(
      Path()
        ..moveTo(env.left, env.top)
        ..lineTo(env.left, env.bottom)
        ..lineTo(env.right, env.bottom)
        ..lineTo(env.right, env.top),
      rim,
    );
    if (open <= 0.5) {
      canvas.drawLine(env.topLeft, env.topRight, rim);
      drawFlap();
    }
    if (cardOut) _card(canvas, size, cardCenter, 1, cardScale);

    // The wax seal: stamped on, then cracked in two.
    final stamp = _seg(t, 0.3, 0.4);
    final crack = _seg(t, 0.44, 0.56);
    if (stamp > 0 && crack < 1) {
      final scale = 1 + 0.8 * pow(1 - Curves.easeOutBack.transform(stamp), 2);
      final sealC = Offset(cx, env.top + h * 0.55);
      final r = w * 0.085 * scale;
      for (final side in [-1, 1]) {
        canvas.save();
        canvas.translate(
          sealC.dx + side * crack * r * 1.6,
          sealC.dy + crack * r,
        );
        canvas.rotate(side * crack * 0.6);
        canvas.clipRect(
          side < 0
              ? Rect.fromLTRB(-r * 2, -r * 2, 0, r * 2)
              : Rect.fromLTRB(0, -r * 2, r * 2, r * 2),
        );
        final a = (1 - crack).clamp(0.0, 1.0) * stamp;
        canvas.drawCircle(
          Offset.zero,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [
                Gilt.goldHi.withValues(alpha: a),
                Gilt.gold.withValues(alpha: a),
                Gilt.goldLo.withValues(alpha: a),
              ],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
        );
        canvas.drawCircle(
          Offset.zero,
          r * 0.72,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Gilt.goldLo.withValues(alpha: a),
        );
        final e = _text(
          'E',
          r * 1.0,
          color: Gilt.goldLo.withValues(alpha: a),
          weight: FontWeight.w800,
        );
        e.paint(canvas, Offset(-e.width / 2, -e.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();

    // Gold dust once the card is out.
    _sparks(canvas, size, Offset(cx, cardCenter.dy), _seg(t, 0.62, 1), out, 28);
  }

  /// The engraved card: ivory, a gold double rule, and the words.
  void _card(Canvas canvas, Size size, Offset c, double alpha, double s) {
    const cw = 300.0, ch = 196.0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(s);
    final r = Rect.fromCenter(center: Offset.zero, width: cw, height: ch);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()..color = const Color(0xFFF4EEDF).withValues(alpha: alpha),
    );
    for (final (d, sw) in [(8.0, 1.6), (12.0, 0.6)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(d), const Radius.circular(2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..color = Gilt.goldLo.withValues(alpha: alpha),
      );
    }
    const ink = Color(0xFF2A2418);
    final a = _text(
      'You are cordially invited to',
      13,
      color: ink.withValues(alpha: alpha),
      max: cw - 40,
    );
    final b = _text(
      'THE UPPER ECHELON',
      21,
      color: Gilt.goldLo.withValues(alpha: alpha),
      weight: FontWeight.w800,
      spacing: 2.5,
      max: cw - 30,
    );
    final d = _text(
      title,
      18,
      color: ink.withValues(alpha: alpha),
      weight: FontWeight.w600,
      max: cw - 40,
    );
    final e = _text(
      sub,
      10.5,
      color: ink.withValues(alpha: 0.7 * alpha),
      family: 'Sora',
      max: cw - 50,
    );
    var y = -ch / 2 + 30;
    a.paint(canvas, Offset(-a.width / 2, y));
    y += a.height + 8;
    b.paint(canvas, Offset(-b.width / 2, y));
    y += b.height + 10;
    canvas.drawLine(
      Offset(-40, y),
      Offset(40, y),
      Paint()
        ..color = Gilt.goldLo.withValues(alpha: alpha)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(0, y),
      2.5,
      Paint()..color = Gilt.goldLo.withValues(alpha: alpha),
    );
    y += 10;
    d.paint(canvas, Offset(-d.width / 2, y));
    y += d.height + 4;
    e.paint(canvas, Offset(-e.width / 2, y));
    canvas.restore();
  }

  // ---------------- A new tier ----------------

  void _plaque(Canvas canvas, Size size, double out) {
    final drop = Curves.easeOutBack.transform(_seg(t, 0.05, 0.3));
    final w = min(size.width - 56, 320.0);
    final c = Offset(size.width / 2, size.height * 0.45);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 + 0.5 * (1 - drop));
    final a = (drop * out).clamp(0.0, 1.0);
    final big = _text(
      title.toUpperCase(),
      w < 290 ? 24 : 28,
      color: const Color(0xFF2B210D).withValues(alpha: a),
      weight: FontWeight.w800,
      spacing: 2,
      max: w - 30,
    );
    final top = _text(
      'A NEW TIER',
      10,
      color: const Color(0xFF4A3A16).withValues(alpha: a),
      family: 'Sora',
      weight: FontWeight.w700,
      spacing: 3,
      max: w - 30,
    );
    final low = _text(
      sub,
      12,
      color: Gilt.ivory.withValues(alpha: a),
      family: 'Sora',
      max: w,
    );
    final h = 30 + top.height + big.height + 26;
    final r = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(14)),
      Paint()
        ..color = Gilt.gold.withValues(alpha: 0.35 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Gilt.goldHi.withValues(alpha: a),
            Gilt.gold.withValues(alpha: a),
            Gilt.goldLo.withValues(alpha: a),
            Gilt.gold.withValues(alpha: a),
          ],
        ).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.deflate(6), const Radius.circular(6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF5A4518).withValues(alpha: a),
    );
    // Screws in the corners.
    for (final p in [
      r.topLeft + const Offset(14, 14),
      r.topRight + const Offset(-14, 14),
      r.bottomLeft + const Offset(14, -14),
      r.bottomRight + const Offset(-14, -14),
    ]) {
      canvas.drawCircle(
        p,
        3,
        Paint()..color = const Color(0xFF5A4518).withValues(alpha: a),
      );
    }
    var y = r.top + 16;
    top.paint(canvas, Offset(-top.width / 2, y));
    y += top.height + 4;
    big.paint(canvas, Offset(-big.width / 2, y));
    low.paint(canvas, Offset(-low.width / 2, r.bottom + 18));
    canvas.restore();
    _sparks(canvas, size, c, _seg(t, 0.22, 1), out, 40);
  }

  /// Gold sparks flung out from [c] and drifting down.
  void _sparks(
    Canvas canvas,
    Size size,
    Offset c,
    double p,
    double out,
    int n,
  ) {
    if (p <= 0) return;
    final rng = Random(n * 13 + title.length);
    for (var i = 0; i < n; i++) {
      final ang = rng.nextDouble() * pi * 2;
      final speed = 60 + rng.nextDouble() * 160;
      final pos =
          c +
          Offset(cos(ang), sin(ang)) * speed * Curves.easeOut.transform(p) +
          Offset(0, 80 * p * p);
      final a = (1 - p) * out;
      final r = 1 + rng.nextDouble() * 2.2;
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = (i.isEven ? Gilt.goldHi : Gilt.gold).withValues(
            alpha: a.clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.t != t || old.kind != kind;
}
