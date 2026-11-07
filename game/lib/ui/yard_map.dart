import 'dart:math';

import 'package:flutter/material.dart';

import '../sound.dart';
import '../theme.dart';

// The Yard map: the top of the Activities panel while you are in prison, a
// top-down plan of the prison drawn in chalk and paint. The cell block,
// the workshop, the weights pit, the basketball court where the crews
// hang out, the visiting room and the gate are places you tap to jump to
// what you can do there. A guard tower in the corner sweeps its
// searchlight across the yard. Places with nothing open are greyed out
// (in solitary, everything but your cell).

class YardZone {
  const YardZone({
    required this.id,
    required this.label,
    required this.icon,
    required this.open,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Something can be done there right now.
  final int open;
}

/// Where each place sits on the plan, as fractions of the map.
const _plan = <String, Rect>{
  'cell': Rect.fromLTWH(0.04, 0.07, 0.50, 0.30),
  'workshop': Rect.fromLTWH(0.58, 0.16, 0.26, 0.21),
  'weights': Rect.fromLTWH(0.04, 0.43, 0.27, 0.25),
  'court': Rect.fromLTWH(0.35, 0.43, 0.38, 0.25),
  'visiting': Rect.fromLTWH(0.04, 0.74, 0.42, 0.20),
  'gate': Rect.fromLTWH(0.70, 0.74, 0.26, 0.20),
};

class YardMap extends StatefulWidget {
  const YardMap({super.key, required this.zones, required this.onTap});

  final List<YardZone> zones;
  final ValueChanged<String> onTap;

  @override
  State<YardMap> createState() => _YardMapState();
}

class _YardMapState extends State<YardMap> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The searchlight holds still when Reduce motion is on.
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
      _sweep.value = 0.35;
    } else if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final h = min(w * 0.66, 280.0);
      return SizedBox(
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => CustomPaint(
                      painter: _PlanPainter(
                        sweep: _sweep.value,
                        ground: NF.surface,
                        metal: NF.borderStrong,
                        chalk: NF.text,
                        accent: NF.orange,
                      ),
                    ),
                  ),
                ),
              ),
              for (final z in widget.zones)
                if (_plan[z.id] case final r?)
                  Positioned(
                    left: r.left * w,
                    top: r.top * h,
                    width: r.width * w,
                    height: r.height * h,
                    child: _ZoneTile(
                      zone: z,
                      onTap: () {
                        Sound.instance.tap();
                        widget.onTap(z.id);
                      },
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.zone, required this.onTap});
  final YardZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = zone.open > 0;
    final ink = open ? NF.orange : NF.muted.withValues(alpha: 0.6);
    return Semantics(
      button: true,
      label: open
          ? '${zone.label}: ${zone.open} things to do'
          : '${zone.label}: closed to you right now',
      excludeSemantics: true,
      child: Material(
        color: open
            ? NF.orange.withValues(alpha: 0.08)
            : NF.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ink.withValues(alpha: open ? 0.75 : 0.35),
                width: open ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(zone.icon, size: 18, color: ink),
                  const SizedBox(height: 2),
                  Text(zone.label, style: NF.stencil(10, color: ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ground plan: concrete, painted lines, the walls and fence, the
/// buildings, the court markings and the guard tower's searchlight.
class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.sweep,
    required this.ground,
    required this.metal,
    required this.chalk,
    required this.accent,
  });

  final double sweep;
  final Color ground;
  final Color metal;
  final Color chalk;
  final Color accent;

  Rect _r(String id, Size s) {
    final f = _plan[id]!;
    return Rect.fromLTWH(
      f.left * s.width,
      f.top * s.height,
      f.width * s.width,
      f.height * s.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Concrete, with a few cracks and stains.
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final rng = Random(7);
    final crack = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      var p = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
      for (var k = 0; k < 4; k++) {
        final q = p + Offset(rng.nextDouble() * 24 - 12, rng.nextDouble() * 18);
        canvas.drawLine(p, q, crack);
        p = q;
      }
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        8 + rng.nextDouble() * 18,
        Paint()..color = Colors.black.withValues(alpha: 0.07),
      );
    }

    // The fence round the edge, and razor wire along the top of it.
    final fence = Paint()
      ..color = metal.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const band = 7.0;
    for (var x = 0.0; x < w + band; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x - band, band), fence);
      canvas.drawLine(Offset(x, h - band), Offset(x - band, h), fence);
    }
    for (var y = 0.0; y < h + band; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(band, y - band), fence);
      canvas.drawLine(Offset(w - band, y), Offset(w, y - band), fence);
    }
    final wire = Paint()
      ..color = chalk.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 4.0; x < w; x += 9) {
      canvas.drawCircle(Offset(x, band + 3), 3.5, wire);
    }

    // The cell block: a long building with rows of window slits.
    final cell = _r('cell', size);
    canvas.drawRect(
      cell.deflate(2),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    final slit = Paint()..color = accent.withValues(alpha: 0.18);
    for (var row = 0; row < 2; row++) {
      for (var x = cell.left + 10; x < cell.right - 10; x += 12) {
        canvas.drawRect(
          Rect.fromLTWH(x, cell.top + 8 + row * (cell.height - 22), 4, 6),
          slit,
        );
      }
    }

    // The workshop roof.
    final shop = _r('workshop', size);
    canvas.drawRect(
      shop.deflate(2),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    final roof = Paint()
      ..color = metal.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var y = shop.top + 6; y < shop.bottom - 4; y += 6) {
      canvas.drawLine(
        Offset(shop.left + 4, y),
        Offset(shop.right - 4, y),
        roof,
      );
    }

    // The court: painted lines and a centre circle.
    final court = _r('court', size).deflate(6);
    final line = Paint()
      ..color = chalk.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(court, line);
    canvas.drawLine(court.topCenter, court.bottomCenter, line);
    canvas.drawCircle(court.center, court.height * 0.22, line);
    canvas.drawArc(
      Rect.fromCircle(center: court.centerLeft, radius: court.height * 0.35),
      -pi / 2,
      pi,
      false,
      line,
    );
    canvas.drawArc(
      Rect.fromCircle(center: court.centerRight, radius: court.height * 0.35),
      pi / 2,
      pi,
      false,
      line,
    );

    // The weights pit: a rubber mat and plates.
    final pit = _r('weights', size).deflate(6);
    canvas.drawRect(pit, Paint()..color = Colors.black.withValues(alpha: 0.18));
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(pit.left + 10 + i * 9, pit.bottom - 9),
        6,
        Paint()..color = chalk.withValues(alpha: 0.12),
      );
    }

    // The gate: a gap in the fence with two leaves.
    final gate = _r('gate', size);
    final leaf = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(gate.left + 8, h - 2),
      Offset(gate.center.dx - 2, h - 2),
      leaf,
    );
    canvas.drawLine(
      Offset(gate.center.dx + 2, h - 2),
      Offset(gate.right - 8, h - 2),
      leaf,
    );

    // Painted walkway lines.
    final walk = Paint()
      ..color = const Color(0xFFE3CF7A).withValues(alpha: 0.16)
      ..strokeWidth = 2;
    for (var x = 12.0; x < w - 12; x += 16) {
      canvas.drawLine(Offset(x, h * 0.405), Offset(x + 8, h * 0.405), walk);
      canvas.drawLine(Offset(x, h * 0.705), Offset(x + 8, h * 0.705), walk);
    }

    // The guard tower, and its searchlight sweeping the yard.
    final tower = Offset(w - 22, 22);
    final angle = pi * 0.55 + (sweep - 0.5) * 0.9;
    final reach = max(w, h) * 0.95;
    const spread = 0.17;
    final cone = Path()
      ..moveTo(tower.dx, tower.dy)
      ..lineTo(
        tower.dx + cos(angle - spread) * reach,
        tower.dy + sin(angle - spread) * reach,
      )
      ..lineTo(
        tower.dx + cos(angle + spread) * reach,
        tower.dy + sin(angle + spread) * reach,
      )
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF3C4).withValues(alpha: 0.3),
            const Color(0xFFFFF3C4).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: tower, radius: reach)),
    );
    final spot = tower + Offset(cos(angle), sin(angle)) * reach * 0.55;
    canvas.drawOval(
      Rect.fromCenter(center: spot, width: 46, height: 30),
      Paint()
        ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(
      Rect.fromCenter(center: tower, width: 22, height: 22),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRect(
      Rect.fromCenter(center: tower, width: 22, height: 22),
      Paint()
        ..color = metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      tower,
      3,
      Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.sweep != sweep || old.ground != ground || old.accent != accent;
}
