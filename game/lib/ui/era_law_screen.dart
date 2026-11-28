import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/era_justice.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// Me → The law in an era life (Phase 2C): the denunciations against your
/// name as heat, the crimes of the night streets with their sentences, the
/// bribe that loses a denunciation, and your record. In Florence it is the
/// tamburo, the drum where anyone can accuse anyone.
class EraLawScreen extends StatelessWidget {
  const EraLawScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final court = eraCourt(life, era);
      final drum = court['drum'] as String;
      final heat = eraHeat(life);
      final group = era.regionOf(life).group;
      final curfew =
          group == 'italy' || group == 'islands' || group == 'england';
      final lock = eraLawLock(life);
      final record = eraRecord(life);
      final bribe = eraBribe(life, era);
      final inside = eraInsideOf(life);
      final ban = life.eraWorld['banished'] as Map?;
      return EraPage(
        life: life,
        kicker: 'The law · ${life.city} ${life.year}',
        title: drum == 'the tamburo'
            ? 'The drum is listening'
            : drum == "the lion's mouths"
            ? "The lion's mouths"
            : 'Your name and the law',
        sub: court['drumAbout'] as String,
        top: Column(
          children: [
            if (drum == 'the tamburo' || drum == "the lion's mouths")
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 130,
                  child: CustomPaint(
                    size: const Size(150, 130),
                    painter: _DrumPainter(
                      ink: NF.text,
                      paper: NF.surface,
                      chalk: NF.orange,
                      lion: drum != 'the tamburo',
                    ),
                  ),
                ),
              ),
            EraMeter(value: heat),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Heat $heat of 5 · ${eraCap(court['court'] as String)}',
                style: NF.sora(13, color: NF.muted),
              ),
            ),
          ],
        ),
        children: [
          if (inside != null)
            EraCard(
              life: life,
              title: inside['kind'] == 'galleys'
                  ? 'On the galleys'
                  : 'Held in ${inside['name']}',
              note: 'See the Prison tab. The streets will wait.',
              children: const [],
            ),
          if (eraHearingOf(life) != null)
            EraCard(
              life: life,
              title: 'Your hearing',
              note: 'It is waiting for you on the Life tab.',
              children: const [],
            ),
          EraCard(
            life: life,
            title: curfew ? 'After curfew' : 'After dark',
            note:
                lock ??
                'Each one adds heat. The more heat, the more eyes on you.',
            children: [
              for (final (i, cr) in eraCrimes(life, era).indexed)
                EraRow(
                  first: i == 0,
                  title: cr.label,
                  sub: cr.about,
                  pill: switch (cr.heat) {
                    1 => 'Low',
                    2 => 'Medium',
                    _ => 'High',
                  },
                  filled: cr.heat >= 3,
                  lock:
                      lock ??
                      (life.usedActions.contains('era_crime_${cr.id}')
                          ? 'Not again this year.'
                          : null),
                  onTap: () => eraRun(
                    context,
                    controller,
                    cr.label,
                    (l, e, rng) => commitEraCrime(l, e, cr.id, rng),
                    icon: Icons.nightlight_round,
                  ),
                ),
              EraRow(
                title: bribe.label,
                sub:
                    'Clears one denunciation · ${moneyIn(bribe.cost, life.country)}',
                pill: '−1',
                lock:
                    lock ??
                    (heat == 0
                        ? 'Nothing against your name to lose.'
                        : life.money < bribe.cost
                        ? 'Needs ${moneyIn(bribe.cost, life.country)}.'
                        : life.usedActions.contains('era_bribe')
                        ? 'Not again this year.'
                        : null),
                onTap: () => eraRun(
                  context,
                  controller,
                  'A word with a clerk',
                  bribeEraClerk,
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          EraCard(
            life: life,
            title: 'Your record',
            note: record.isEmpty ? 'Nothing against your name.' : null,
            children: [
              for (final line in record.reversed.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '$line.',
                    style: NF.sora(14, color: NF.soft, height: 1.35),
                  ),
                ),
              if (ban != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Banished from ${ban['city']} until ${ban['until']}.',
                    style: NF.sora(13, color: NF.orange),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

/// The tamburo, drawn in ink: a drum with a slot and a folded letter going
/// in. In Venice, a stone lion's mouth.
class _DrumPainter extends CustomPainter {
  _DrumPainter({
    required this.ink,
    required this.paper,
    required this.chalk,
    this.lion = false,
  });
  final Color ink;
  final Color paper;
  final Color chalk;
  final bool lion;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final fill = Paint()..color = paper;
    final red = Paint()
      ..color = chalk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    if (lion) {
      // A stone slab with a lion's face and an open mouth.
      final slab = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 70), width: 120, height: 110),
        const Radius.circular(10),
      );
      canvas.drawRRect(slab, fill);
      canvas.drawRRect(slab, line);
      canvas.drawCircle(Offset(cx, 58), 34, red);
      canvas.drawCircle(Offset(cx - 12, 50), 3.5, Paint()..color = ink);
      canvas.drawCircle(Offset(cx + 12, 50), 3.5, Paint()..color = ink);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 78), width: 44, height: 12),
          const Radius.circular(6),
        ),
        Paint()..color = ink,
      );
      _letter(canvas, Offset(cx, 66), line);
      return;
    }
    final top = Rect.fromCenter(center: Offset(cx, 38), width: 110, height: 26);
    final body = Path()
      ..moveTo(cx - 55, 38)
      ..lineTo(cx - 55, 104)
      ..quadraticBezierTo(cx, 128, cx + 55, 104)
      ..lineTo(cx + 55, 38);
    canvas.drawPath(body, fill);
    canvas.drawPath(body, line);
    for (final y in [66.0, 88.0]) {
      final band = Path()
        ..moveTo(cx - 55, y)
        ..quadraticBezierTo(cx, y + 20, cx + 55, y);
      canvas.drawPath(band, red);
    }
    canvas.drawOval(top, Paint()..color = paper);
    canvas.drawOval(top, line);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, 38), width: 30, height: 6),
      Paint()..color = ink,
    );
    _letter(canvas, Offset(cx, 22), line);
  }

  void _letter(Canvas canvas, Offset at, Paint line) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(0.14);
    final r = Rect.fromCenter(center: Offset.zero, width: 18, height: 24);
    canvas.drawRect(r, Paint()..color = paper);
    canvas.drawRect(r, line..strokeWidth = 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrumPainter old) =>
      old.ink != ink || old.lion != lion;
}
