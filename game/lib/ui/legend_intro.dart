import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/legends.dart';
import 'legend_look.dart';

/// A Legend's own button on the New Life screen (approved mockup, 27 Nov):
/// its paper and ink frame, a red-chalk seal with the initials, its motif
/// faint in the corner and a ribbon.
class LegendSelectCard extends StatelessWidget {
  const LegendSelectCard({
    super.key,
    required this.legend,
    required this.onTap,
    this.ribbon,
  });
  final Legend legend;
  final void Function(Offset at) onTap;
  final String? ribbon;

  static String initials(Legend l) =>
      '${l.firstName.characters.first}${l.surname.characters.first}';

  @override
  Widget build(BuildContext context) {
    final look = legendLooks[legend.look] ?? leonardoCodex;
    final p = look.palette;
    final motif = Text(
      look.motif,
      maxLines: 1,
      style: TextStyle(
        fontFamily: look.handFont,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: look.ink.withValues(alpha: 0.08),
      ),
    );
    return Semantics(
      button: true,
      label: 'Legends: ${legend.name}${ribbon == null ? '' : ', $ribbon'}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapUp: (d) => onTap(d.globalPosition),
          child: LegendFrame(
            look: look,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -4,
                  bottom: -24,
                  child: look.mirrorMotif
                      ? Transform.flip(flipX: true, child: motif)
                      : motif,
                ),
                Row(
                  children: [
                    LegendSeal(look: look, text: initials(legend), size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'A Legend',
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: legendHand(look, 17),
                                ),
                              ),
                              if (ribbon != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: look.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ribbon!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: look.bodyFont,
                                        fontSize: 11,
                                        color: look.cardTop,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            legend.name,
                            style: TextStyle(
                              fontFamily: look.bodyFont,
                              fontSize: 22,
                              color: p.text,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${legend.city}, ${legend.birthYear} · the free prologue',
                            style: TextStyle(
                              fontFamily: look.bodyFont,
                              fontSize: 13,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red-chalk wax seal with a Legend's initials.
class LegendSeal extends StatelessWidget {
  const LegendSeal({
    super.key,
    required this.look,
    required this.text,
    this.size = 60,
  });
  final LegendLook look;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Color.lerp(look.accent, Colors.white, 0.12)!,
          look.palette.orange,
        ],
      ),
      border: Border.all(
        color: look.cardTop.withValues(alpha: 0.3),
        width: 3,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
      boxShadow: [
        BoxShadow(
          color: look.ink.withValues(alpha: 0.4),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: look.bodyFont,
        fontSize: size * 0.42,
        color: look.cardTop,
      ),
    ),
  );
}

/// Plays a Legend's opening (about 3.5 s), then calls [onStart] under the
/// parchment and fades away into the new life. A tap skips it, and it is
/// skipped when the system asks for reduced motion.
Future<void> playLegendIntro(
  BuildContext context,
  Legend legend, {
  required Offset from,
  required VoidCallback onStart,
}) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    onStart();
    return Future.value();
  }
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (_, _, _) =>
          LegendIntro(legend: legend, from: from, onStart: onStart),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

/// The opening itself. Timeline (fractions of [total]):
///  0.00–0.18 the seal spreads out as parchment over the screen,
///  0.15–0.55 a red-chalk circle and square draw themselves, and the
///            birthplace appears in the Legend's hand (mirror writing for
///            Leonardo),
///  0.55–0.72 the writing turns round to read normally,
///  0.66–0.86 the name is inked in, left to right, with its line below,
///  0.86–1.00 a short hold; then the life starts and this fades away.
class LegendIntro extends StatefulWidget {
  const LegendIntro({
    super.key,
    required this.legend,
    required this.from,
    required this.onStart,
    this.total = const Duration(milliseconds: 3500),
    this.at,
  });
  final Legend legend;
  final Offset from;
  final VoidCallback onStart;
  final Duration total;

  /// Freezes the opening at this fraction (for screenshots).
  final double? at;

  @override
  State<LegendIntro> createState() => _LegendIntroState();
}

class _LegendIntroState extends State<LegendIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.total,
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.at != null) {
      _c.value = widget.at!;
      return;
    }
    _c.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onStart();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b) =>
      Curves.easeInOut.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final legend = widget.legend;
    final look = legendLooks[legend.look] ?? leonardoCodex;
    final size = MediaQuery.sizeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.globalToLocal(widget.from)
        : widget.from;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.at != null) return;
          _c.stop();
          _finish();
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final spread = _seg(t, 0, 0.18);
            final draw = _seg(t, 0.15, 0.55);
            final place = _seg(t, 0.30, 0.45);
            final turn = _seg(t, 0.55, 0.72);
            final ink = _seg(t, 0.66, 0.86);
            final maxR = math.sqrt(
              size.width * size.width + size.height * size.height,
            );
            final sketch = math.min(size.width * 0.34, 150.0);
            final cy = size.height * 0.40;
            final hand = legendHand(look, 34, color: look.accent);
            // Mirror writing turns round: scaleX goes -1 → 0 → 1.
            final flip = look.mirrorMotif ? -math.cos(turn * math.pi) : 1.0;
            return Stack(
              children: [
                ClipPath(
                  clipper: _Circle(origin, 30 + (maxR + 40) * spread),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, -0.3),
                        radius: 1.2,
                        colors: [
                          look.cardTop,
                          look.palette.bg,
                          look.cardBottom,
                        ],
                      ),
                    ),
                  ),
                ),
                // The seal, fading as it spreads.
                Positioned(
                  left: origin.dx - 30,
                  top: origin.dy - 30,
                  child: Opacity(
                    opacity: 1 - spread,
                    child: Transform.scale(
                      scale: 1 + spread * 2,
                      child: LegendSeal(
                        look: look,
                        text: LegendSelectCard.initials(legend),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Sketch(
                      progress: draw,
                      fade: ink,
                      center: Offset(size.width / 2, cy),
                      r: sketch,
                      color: look.accent,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: cy + sketch + 44,
                  child: Opacity(
                    opacity: place,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        flip.abs() < 0.02 ? 0.02 : flip,
                        1,
                        1,
                      ),
                      child: Text(
                        '${legend.city}, ${legend.birthYear}',
                        textAlign: TextAlign.center,
                        style: hand.copyWith(
                          color: Color.lerp(look.ink, look.accent, turn),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: cy + sketch + 92,
                  child: Column(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (r) => LinearGradient(
                          colors: const [Colors.white, Colors.transparent],
                          // The ink edge runs from just before the first
                          // letter to just past the last.
                          stops: [ink * 1.1 - 0.1, (ink * 1.1).clamp(0.0, 1.0)],
                        ).createShader(r),
                        child: Text(
                          legend.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: look.bodyFont,
                            fontSize: 32,
                            color: look.palette.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // The quill line under the name.
                      Align(
                        child: Container(
                          width: 180 * ink,
                          height: 1.6,
                          color: look.ink.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _seg(t, 0.80, 0.92),
                        child: Text(
                          'A Legend · the free prologue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: look.bodyFont,
                            fontSize: 14,
                            color: look.palette.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28 + MediaQuery.paddingOf(context).bottom,
                  child: Opacity(
                    opacity: 0.6 * _seg(t, 0.25, 0.4),
                    child: Text(
                      'Tap to skip',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: look.bodyFont,
                        fontSize: 13,
                        color: look.palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Circle extends CustomClipper<Path> {
  _Circle(this.c, this.r);
  final Offset c;
  final double r;
  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: c, radius: r));
  @override
  bool shouldReclip(_Circle o) => o.c != c || o.r != r;
}

/// A circle and a square drawn in red chalk, stroke by stroke.
class _Sketch extends CustomPainter {
  _Sketch({
    required this.progress,
    required this.fade,
    required this.center,
    required this.r,
    required this.color,
  });
  final double progress;
  final double fade;
  final Offset center;
  final double r;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85 - 0.45 * fade);
    final s = r * 0.8;
    final shapes = [
      Path()..addOval(Rect.fromCircle(center: center, radius: r)),
      Path()
        ..addRect(Rect.fromCenter(center: center, width: s * 2, height: s * 2)),
      // Two light construction lines.
      Path()
        ..moveTo(center.dx - r, center.dy)
        ..lineTo(center.dx + r, center.dy),
      Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx, center.dy + r),
    ];
    // Circle first, then the square, then the cross lines, overlapping.
    const starts = [0.0, 0.35, 0.7, 0.78];
    const ends = [0.6, 0.85, 1.0, 1.0];
    for (var i = 0; i < shapes.length; i++) {
      final f = ((progress - starts[i]) / (ends[i] - starts[i])).clamp(
        0.0,
        1.0,
      );
      if (f <= 0) continue;
      if (i >= 2) paint.color = color.withValues(alpha: 0.35 - 0.2 * fade);
      for (final m in shapes[i].computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * f), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Sketch o) =>
      o.progress != progress || o.fade != fade || o.r != r;
}
