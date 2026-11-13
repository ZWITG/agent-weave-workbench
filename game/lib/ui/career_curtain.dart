import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../engine/elite.dart' show upperEchelon;
import '../engine/models.dart';
import '../game_controller.dart';
import '../sound.dart';
import '../theme.dart';

// Career looks: while you work in a special career the whole game wears
// that career's colours (theme.dart, careerLooks): Marquee for actors,
// Blue Line for the police, Night Shift for doctors and so on.
//
// Starting one plays the Curtain: the screen you were on freezes, the new
// look opens out of the middle of it like a spotlight, the career's card
// (its badge, your new title and the look's name) settles, then the card
// lifts away and the game is in its new colours. Tap to skip; Reduce
// motion makes it a short fade.

/// The special career whose look this life should wear, or null (no job,
/// retired, in prison, or a career without a look).
String? careerLookId(Life? l) {
  if (l == null || !l.alive || l.prison != null || l.retired) return null;
  if (l.job == null) return null;
  return careerLooks.containsKey(l.careerId) ? l.careerId : null;
}

/// The career look actually on screen: riches, prison and the Crime and
/// Real estate pages win over it, and Settings can turn it off.
String? shownCareerLook(GameController c) {
  final l = c.life;
  if (!c.profile.careerLooks) return null;
  if (l == null || upperEchelon(l)) return null;
  if (c.alleyLook || c.sunsetLook) return null;
  return careerLookId(l);
}

class CareerCurtain extends StatefulWidget {
  const CareerCurtain({
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
  State<CareerCurtain> createState() => _CareerCurtainState();
}

class _CareerCurtainState extends State<CareerCurtain>
    with SingleTickerProviderStateMixin {
  final _shotKey = GlobalKey();
  late final AnimationController _anim;
  Life? _life;
  String? _look;
  CareerLook? _playing;
  String _title = '';
  int _rank = 0;

  /// 'NOW WORKING AS' when a career starts, 'PROMOTED TO' on a promotion
  /// (the Curtain Call).
  String _kicker = 'NOW WORKING AS';
  ui.Image? _shot;
  bool _cued = false;

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(() {
        if (!_cued && _anim.value > 0.12) {
          _cued = true;
          if (!widget.reduceMotion) {
            HapticFeedback.lightImpact();
            Sound.instance.cue('promote');
          }
        }
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
    _life = c.life;
    _look = careerLookId(_life);
    _rank = _life?.careerRank ?? 0;
    c.addListener(_changed);
  }

  @override
  void didUpdateWidget(CareerCurtain old) {
    super.didUpdateWidget(old);
    if (old.controller != c) {
      old.controller.removeListener(_changed);
      c.addListener(_changed);
    }
  }

  /// Runs before the rebuild, so the old look can still be photographed.
  void _changed() {
    final l = c.life;
    final same = identical(l, _life);
    final was = _look;
    final now = careerLookId(l);
    final rankWas = _rank;
    _life = l;
    _look = now;
    _rank = l?.careerRank ?? 0;
    // Only starting a special career (or a promotion in one) in the life
    // being played: not a new life, a loaded save, or a page opening or
    // closing over the look.
    if (!same || now == null) return;
    final promoted = now == was && _rank > rankWas;
    if (now == was && !promoted) return;
    if (shownCareerLook(c) != now) return;
    if (!CareerCurtain.enabled || _playing != null) return;
    _shot?.dispose();
    _shot = _capture();
    _playing = careerLooks[now];
    _title = l?.job ?? '';
    _kicker = promoted ? 'PROMOTED TO' : 'NOW WORKING AS';
    _cued = false;
    _anim.duration = widget.reduceMotion
        ? const Duration(milliseconds: 500)
        : promoted
        ? const Duration(milliseconds: 2400)
        : const Duration(milliseconds: 3000);
    _anim.forward(from: 0);
    setState(() {});
  }

  ui.Image? _capture() {
    try {
      final b = _shotKey.currentContext?.findRenderObject();
      if (b is! RenderRepaintBoundary || !b.hasSize) return null;
      final dpr = min(MediaQuery.devicePixelRatioOf(context), 2.0);
      return b.toImageSync(pixelRatio: dpr);
    } catch (_) {
      return null;
    }
  }

  void _finish() {
    if (!mounted) return;
    _anim.stop();
    setState(() {
      _playing = null;
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
    final look = _playing;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _shotKey, child: widget.child),
        if (look != null)
          Positioned.fill(
            child: Semantics(
              label:
                  '${_kicker == 'PROMOTED TO' ? 'Promoted' : 'New career'}: $_title. The game now wears ${look.name}: ${look.tagline}.',
              liveRegion: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _finish,
                child: Material(
                  type: MaterialType.transparency,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) => _overlay(look, _anim.value),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _overlay(CareerLook look, double t) {
    final p = look.palette;
    if (widget.reduceMotion) {
      final o = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      return Opacity(
        opacity: o.clamp(0, 1),
        child: ColoredBox(color: p.bg, child: _card(look, 1)),
      );
    }
    double seg(double a, double b) =>
        Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
    final iris = seg(0.0, 0.42);
    final card = seg(0.22, 0.5);
    final out = seg(0.82, 1.0);
    return Opacity(
      opacity: 1 - out,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_shot != null)
            RawImage(image: _shot, fit: BoxFit.cover)
          else
            ColoredBox(color: nightFeed.bg),
          CustomPaint(painter: _IrisPainter(look.palette, iris, t)),
          Opacity(
            opacity: card,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - card) - 30 * out),
              child: _card(look, card),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(CareerLook look, double k) {
    final p = look.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface2,
                border: Border.all(color: p.borderStrong, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: p.orange.withValues(alpha: 0.35 * k),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(look.icon, size: 42, color: p.orange),
            ),
            const SizedBox(height: 18),
            Text(
              _kicker,
              style: NF
                  .sora(12, weight: FontWeight.w700, color: p.muted)
                  .copyWith(letterSpacing: 2.4),
            ),
            const SizedBox(height: 6),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: NF.sora(30, weight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.blue.withValues(alpha: 0.7)),
              ),
              child: Text(
                look.name.toUpperCase(),
                style: NF
                    .sora(13, weight: FontWeight.w700, color: p.blue)
                    .copyWith(letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              look.tagline,
              textAlign: TextAlign.center,
              style: NF.sora(14, color: p.soft, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// The new look opening out of the middle of the old screen, with a ring of
/// the career's accent on its edge and a soft beam sweeping across it.
class _IrisPainter extends CustomPainter {
  _IrisPainter(this.p, this.k, this.t);
  final NFPalette p;
  final double k, t;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final full = sqrt(size.width * size.width + size.height * size.height) / 2;
    final r = full * k;
    if (r <= 0) return;
    canvas.drawCircle(centre, r, Paint()..color = p.bg);
    // A spotlight pool in the middle of the new look.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.surface2.withValues(alpha: 0.9),
            p.bg.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: max(1, r))),
    );
    if (k < 1) {
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = p.orange.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        centre,
        r + 7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = p.blue.withValues(alpha: 0.5),
      );
    }
    // A beam of light sweeping across once the look is open.
    final sweep = ((t - 0.3) / 0.5).clamp(0.0, 1.0);
    if (sweep > 0 && sweep < 1) {
      final x = -size.width * 0.5 + size.width * 2 * sweep;
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: centre, radius: r)),
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 60, 0, 120, size.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              p.blue.withValues(alpha: 0),
              p.blue.withValues(alpha: 0.10),
              p.blue.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IrisPainter old) => old.k != k || old.t != t;
}
