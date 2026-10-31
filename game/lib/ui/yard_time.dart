import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../theme.dart';

// Yard Time: how the game looks while you are in prison. The colours come
// from the Yard Time palette (theme.dart); this file has the decals: a
// chain-link fence along the top, the chalk tally card with your release
// countdown, a barbed-wire divider and stencil stamps on prison stories.

/// Chalk yellow for the sun doodle, stamps and happiness.
const _chalkYellow = Color(0xFFE3CF7A);

/// A thin strip of chain-link fence.
class FenceStrip extends StatelessWidget {
  const FenceStrip({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 14,
      width: double.infinity,
      child: CustomPaint(painter: _FencePainter(NF.orange, NF.border)),
    ),
  );
}

class _FencePainter extends CustomPainter {
  _FencePainter(this.wire, this.edge);
  final Color wire;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = wire.withValues(alpha: 0.22)
      ..strokeWidth = 1.4;
    for (var x = -size.height; x < size.width + size.height; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), p);
    }
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()..color = edge,
    );
  }

  @override
  bool shouldRepaint(_FencePainter old) => old.wire != wire;
}

/// A barbed-wire line between sections.
class BarbedWire extends StatelessWidget {
  const BarbedWire({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 14,
      width: double.infinity,
      child: CustomPaint(painter: _WirePainter(NF.borderStrong)),
    ),
  );
}

class _WirePainter extends CustomPainter {
  _WirePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    for (var x = 40.0; x < size.width - 10; x += 80) {
      canvas.drawLine(Offset(x, y - 4), Offset(x + 6, y + 4), p);
      canvas.drawLine(Offset(x + 6, y - 4), Offset(x, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) => old.color != color;
}

/// The chalk tally of years served, the release countdown and the block.
class YardCard extends StatelessWidget {
  const YardCard({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final p = life.prison!;
    final served = p.served;
    final left = p.left;
    String years(int n) => '$n ${n == 1 ? 'year' : 'years'}';
    final headline = served == 0
        ? 'First year inside, ${years(left)} to go'
        : left == 0
        ? '${years(served)} down. Almost out'
        : '${years(served)} down, $left to go';
    final parole = p.youth
        ? 'No parole in youth detention'
        : served < p.paroleAt
        ? 'Parole hearing in ${years(p.paroleAt - served)}'
        : 'Parole hearing every year now';
    final tag = switch (p.security) {
      'maximum' => 'MAX SECURITY',
      'minimum' => 'MIN SECURITY',
      'youth' => 'YOUTH UNIT',
      _ => 'BLOCK C',
    };
    return Semantics(
      label:
          '${years(served)} served of ${years(p.years)}. Out in ${life.year + left}. $parole.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: NF.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NF.borderStrong, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 30,
                  child: CustomPaint(
                    painter: _TallyPainter(
                      served: served,
                      total: p.years,
                      chalk: NF.text,
                      faint: NF.border,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: NF.chalk(23),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Out in ${life.year + left} · $parole',
                        style: NF.sora(12, color: NF.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CustomPaint(painter: _SunPainter(_chalkYellow)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: p.years == 0 ? 1 : (served / p.years).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: NF.border,
                      color: NF.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Transform.rotate(
                  angle: -0.05,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 1),
                    decoration: BoxDecoration(
                      color: NF.orange,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(tag, style: NF.stencil(11, color: NF.bg)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tally marks: one per year, in groups of five with a slash; served years
/// in chalk, the rest faint. Long sentences show the first ten.
class _TallyPainter extends CustomPainter {
  _TallyPainter({
    required this.served,
    required this.total,
    required this.chalk,
    required this.faint,
  });
  final int served;
  final int total;
  final Color chalk;
  final Color faint;

  @override
  void paint(Canvas canvas, Size size) {
    final n = min(total, 10);
    final rng = Random(total * 31 + 7);
    var x = 2.0;
    for (var i = 0; i < n; i++) {
      final done = i < min(served, n);
      final p = Paint()
        ..color = done ? chalk : faint
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      if (i % 5 == 4) {
        // The fifth mark slashes across the group.
        canvas.drawLine(
          Offset(x - 22, size.height * 0.75),
          Offset(x + 2, size.height * 0.25),
          p,
        );
        x += 8;
        continue;
      }
      final tilt = rng.nextDouble() * 3 - 1.5;
      canvas.drawLine(
        Offset(x + tilt, 2),
        Offset(x - tilt, size.height - 2),
        p,
      );
      x += 6;
    }
  }

  @override
  bool shouldRepaint(_TallyPainter old) =>
      old.served != served || old.total != total || old.chalk != chalk;
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, size.width * 0.18, p);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 - 0.15;
      canvas.drawLine(
        c + Offset(cos(a), sin(a)) * size.width * 0.3,
        c + Offset(cos(a), sin(a)) * size.width * 0.45,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => false;
}

/// The stencil stamp for a prison story, from what it is about.
String? prisonStamp(String text) {
  final t = text.toLowerCase();
  const stamps = [
    ('VISIT', ['visit', 'visiting room']),
    ('LETTER', ['letter', 'wrote', 'writes']),
    ('PAROLE', ['parole']),
    ('SOLITARY', ['solitary']),
    ('FIGHT', ['fight', 'riot', 'stabbed', 'beat', 'punch', 'brawl']),
    ('GANG', ['gang', 'crew']),
    ('COURSE', ['course', 'class', 'degree', 'study', 'studied', 'exam']),
    ('WORK', ['job', 'kitchen', 'laundry', 'workshop', 'library']),
    ('YARD', ['yard', 'gym', 'workout', 'exercise']),
  ];
  for (final (label, words) in stamps) {
    if (words.any(t.contains)) return label;
  }
  return null;
}

/// A small stencil stamp pinned to the corner of a story.
class PrisonStamp extends StatelessWidget {
  const PrisonStamp(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'FIGHT' || label == 'SOLITARY'
        ? NF.danger
        : label == 'VISIT' || label == 'LETTER'
        ? _chalkYellow
        : NF.orange;
    return Transform.rotate(
      angle: label.length.isEven ? 0.06 : -0.05,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 1),
        decoration: BoxDecoration(
          color: NF.bg,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(label, style: NF.stencil(10, color: color)),
      ),
    );
  }
}
