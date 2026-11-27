import 'package:flutter/material.dart';

import '../engine/legends.dart';
import '../engine/models.dart';
import '../theme.dart';
import 'codex.dart';
import 'legend_look.dart';

/// The thin Chronicle line under the four stat cards (approved layout):
/// how closely this Legend life follows recorded history. Only in a
/// Legend life; tapping it opens the Codex.
class ChronicleStrip extends StatelessWidget {
  const ChronicleStrip({super.key, required this.life, required this.legend});
  final Life life;
  final Legend legend;

  static String label(int c) => c >= 90
      ? 'As history records'
      : c >= 60
      ? "On history's path, mostly"
      : c >= 30
      ? 'Diverging'
      : 'A new history';

  @override
  Widget build(BuildContext context) {
    final look = legendLookFor(life);
    final ink = look?.ink ?? NF.text;
    final accent = look?.accent ?? NF.orange;
    final c = life.chronicle;
    final done = life.pivots.length;
    final total = legend.turningPoints.length;
    return Semantics(
      button: true,
      label: 'Chronicle $c percent, ${label(c)}. Opens the Codex.',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => openCodex(context, life, legend),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Chronicle $c%',
                    style: NF.sora(14, weight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: look == null
                          ? NF.sora(13, color: NF.muted)
                          : legendHand(look, 17),
                    ),
                  ),
                  Text(
                    'Turning points $done/$total',
                    style: NF.sora(12, color: NF.muted),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 7,
                  child: CustomPaint(
                    painter: _HatchBar(c / 100, ink, accent),
                    size: Size.infinite,
                  ),
                ),
              ),
              if (look != null) ...[
                const SizedBox(height: 4),
                LegendMotif(look: look),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A pen-hatched bar, like the mockup's red chalk meter.
class _HatchBar extends CustomPainter {
  _HatchBar(this.value, this.ink, this.accent);
  final double value;
  final Color ink, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, frame);
    final w = size.width * value.clamp(0, 1);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, size.height));
    final hatch = Paint()
      ..color = accent
      ..strokeWidth = 1.6;
    for (var x = -size.height; x < w + size.height; x += 4) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        hatch,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchBar old) =>
      old.value != value || old.ink != ink || old.accent != accent;
}
