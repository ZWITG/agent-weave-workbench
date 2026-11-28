import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/era_activities.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import 'era_art.dart';
import 'era_law_screen.dart';
import 'era_market_screen.dart';
import 'journey.dart';
import 'minigames.dart';
import 'result_popup.dart';

/// Activities in an era life, drawn as a city broadsheet: the season's
/// big feast as a woodcut headline, then every pastime as a little print,
/// sorted into Feasts, Sport, Leisure, Faith and Travel. Each plays an
/// existing mini-game in an era skin, then tells what happened. The
/// market, the law and journeys open their own screens.
class EraActivitiesPanel extends StatefulWidget {
  const EraActivitiesPanel({
    super.key,
    required this.controller,
    this.scroll,
  });
  final GameController controller;
  final ScrollController? scroll;

  @override
  State<EraActivitiesPanel> createState() => _EraActivitiesPanelState();
}

const _kinds = ['All', 'Feasts', 'Sport', 'Leisure', 'Faith', 'Travel'];

String _kindOf(String id) => switch (id) {
  'era_carnival' || 'era_san_giovanni' || 'era_procession' || 'era_playhouse' => 'Feasts',
  'era_calcio' || 'era_joust' || 'era_tilt' || 'era_pallacorda' || 'era_ride' => 'Sport',
  'era_pilgrimage' || 'era_shrine' || 'era_hajj' => 'Faith',
  'era_journey' || 'era_market' => 'Travel',
  _ => 'Leisure',
};

String _glyphOf(String id) => switch (id) {
  'era_carnival' => 'masks',
  'era_san_giovanni' => 'fire',
  'era_procession' => 'candle',
  'era_playhouse' => 'stage',
  'era_calcio' => 'ball',
  'era_joust' => 'lance',
  'era_tilt' => 'horse',
  'era_pallacorda' => 'court',
  'era_ride' => 'hunt',
  'era_cards' => 'cards',
  'era_chess' => 'chess',
  'era_tavern' => 'tavern',
  'era_storyteller' => 'book',
  'era_bath' => 'bath',
  'era_music' => 'lute',
  'era_dance' => 'dance',
  'era_market' => 'awning',
  'era_pilgrimage' => 'flag',
  'era_shrine' => 'shrine',
  'era_hajj' => 'crescent',
  'era_night' => 'night',
  'era_journey' => 'ship',
  _ => 'drum',
};

class _EraActivitiesPanelState extends State<EraActivitiesPanel> {
  String _kind = 'All';

  GameController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      // The same activity can appear once per place (several rows of data);
      // show each id once.
      final seen = <String>{};
      final acts = [
        for (final a in eraActivitiesHere(life, era))
          if (seen.add(a['id'] as String)) a,
      ];
      final feasts = acts.where((a) => _kindOf(a['id'] as String) == 'Feasts').toList();
      final hero = feasts.firstWhere(
        (a) => eraActivityLock(life, era, a) == null,
        orElse: () => feasts.isNotEmpty ? feasts.first : acts.first,
      );
      final shown = [
        for (final a in acts)
          if (a != hero && (_kind == 'All' || _kindOf(a['id'] as String) == _kind)) a,
      ];
      final kinds = [for (final k in _kinds) if (k == 'All' || acts.any((a) => _kindOf(a['id'] as String) == k)) k];
      return Container(
        color: EraInk.paper,
        child: ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _Masthead(city: life.city, line: 'printed in ${life.year}'),
            const SizedBox(height: 10),
            _Headline(
              glyph: _glyphOf(hero['id'] as String),
              label: hero['label'] as String,
              sub: eraActivityLock(life, era, hero) ?? _sub(life, era, hero),
              locked: eraActivityLock(life, era, hero) != null,
              onTap: () => _open(context, hero),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final k in kinds)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _kind = k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kind == k ? EraInk.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EraInk.ink, width: 1.5),
                          ),
                          child: Text(k, style: fell(13.5, color: _kind == k ? EraInk.paper : EraInk.ink)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth > 520 ? 4 : 3;
                final w = (box.maxWidth - (cols - 1) * 8) / cols;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in shown)
                      SizedBox(
                        width: w,
                        child: _Print(
                          glyph: _glyphOf(a['id'] as String),
                          label: a['label'] as String,
                          sub: eraActivityLock(life, era, a) ?? _price(life, era, a),
                          locked: eraActivityLock(life, era, a) != null,
                          onTap: () => _open(context, a),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );

  String _price(Life life, EraRules era, Map a) {
    final cost = eraActivityCost(life, era, a);
    return cost > 0 ? eraM(life, cost) : 'free';
  }

  String _sub(Life life, EraRules era, Map a) {
    final cost = eraActivityCost(life, era, a);
    return [
      a['about'] as String? ?? '',
      if (cost > 0) eraM(life, cost),
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  Future<void> _open(BuildContext context, Map<String, dynamic> a) async {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final nav = Navigator.of(context);
    if (a['market'] == true) {
      nav.push(MaterialPageRoute(builder: (_) => EraMarketScreen(controller: controller)));
      return;
    }
    if (a['law'] == true) {
      nav.push(MaterialPageRoute(builder: (_) => EraLawScreen(controller: controller)));
      return;
    }
    if (a['journey'] == true) {
      await openJourneys(context, controller);
      return;
    }
    final lock = eraActivityLock(life, era, a);
    if (lock != null) {
      await showResultPopup(context, ActionResult(lock), title: a['label'] as String);
      return;
    }
    var score = 0.6;
    final game = eraActivityGame(a);
    if (game != null) {
      final s = await showMiniGame(
        context,
        game,
        age: life.age,
        title: a['label'] as String,
        activity: a['id'] as String,
        life: life,
        game: game,
      );
      if (s == null) return;
      score = s;
    }
    final r = controller.eraLifeAct(
      (l, e, rng) => doEraActivity(l, e, a['id'] as String, score, rng),
    );
    if (nav.mounted) {
      await showResultPopup(
        nav.context,
        r,
        title: a['label'] as String,
        icon: Icons.celebration_outlined,
      );
    }
  }
}

/// "The Pleasures of Vinci", between double rules.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.city, required this.line});
  final String city;
  final String line;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: EraInk.ink, width: 3),
        bottom: BorderSide(color: EraInk.ink, width: 3),
      ),
    ),
    child: Column(
      children: [
        Text('The Pleasures of $city', textAlign: TextAlign.center, style: fell(26)),
        Text(
          'A broadsheet · $line',
          textAlign: TextAlign.center,
          style: fell(12.5, color: EraInk.ink2, italic: true),
        ),
      ],
    ),
  );
}

/// The season's feast as a woodcut: a piazza, rays and the big drawing.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.glyph,
    required this.label,
    required this.sub,
    required this.locked,
    required this.onTap,
  });
  final String glyph;
  final String label;
  final String sub;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: EraInk.card,
        border: Border.all(color: EraInk.ink, width: 2.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(painter: _WoodcutPainter(glyph)),
          ),
          Container(
            color: EraInk.ink,
            padding: const EdgeInsets.fromLTRB(12, 7, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: fell(21, color: EraInk.paper)),
                      Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: fell(12.5, color: EraInk.paper2)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkButton(locked ? 'Locked' : 'Go ›', onTap: onTap, color: locked ? EraInk.ink2 : EraInk.red),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _WoodcutPainter extends CustomPainter {
  _WoodcutPainter(this.glyph);
  final String glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = Paint()
      ..color = EraInk.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final hatch = Paint()
      ..color = EraInk.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final ground = h * 0.84;
    // Sun rays behind the drawing.
    final c = Offset(w / 2, h * 0.5);
    for (var i = 0; i < 28; i++) {
      final a = i / 28 * 2 * pi;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * 46, c + Offset(cos(a), sin(a)) * (i.isEven ? 90 : 72), hatch);
    }
    // Buildings left and right, with hatched shadows.
    void building(double x, double bw, double bh, {bool tower = false}) {
      final top = ground - bh;
      canvas.drawRect(Rect.fromLTWH(x, top, bw, bh), Paint()..color = EraInk.card);
      canvas.drawRect(Rect.fromLTWH(x, top, bw, bh), s);
      canvas.drawPath(
        Path()
          ..moveTo(x - 4, top)
          ..lineTo(x + bw / 2, top - (tower ? 8 : 18))
          ..lineTo(x + bw + 4, top),
        s,
      );
      for (var y = top + 12; y < ground - 20; y += 22) {
        canvas.drawRect(Rect.fromLTWH(x + bw * 0.3, y, bw * 0.4, 12), s);
      }
      for (var k = x + bw - 10; k < x + bw; k += 3) {
        canvas.drawLine(Offset(k, top + 4), Offset(k, ground), hatch);
      }
      if (tower) {
        for (var b = x + 3; b < x + bw - 3; b += 8) {
          canvas.drawRect(Rect.fromLTWH(b, top - 14, 4, 6), s);
        }
      }
    }

    building(8, 46, 92);
    building(58, 30, 120, tower: true);
    building(w - 54, 46, 100);
    building(w - 92, 34, 70);
    canvas.drawLine(Offset(0, ground), Offset(w, ground), s..strokeWidth = 2.2);
    for (var x = 4.0; x < w; x += 14) {
      canvas.drawLine(Offset(x, ground + 4), Offset(x + 8, h - 2), hatch);
    }
    // Bunting.
    final bunting = Path()..moveTo(0, 22);
    bunting.quadraticBezierTo(w / 2, 52, w, 22);
    canvas.drawPath(bunting, s..strokeWidth = 1.2);
    for (final metric in bunting.computeMetrics()) {
      for (var d = 18.0; d < metric.length; d += 26) {
        final t = metric.getTangentForOffset(d)!.position;
        canvas.drawPath(
          Path()
            ..moveTo(t.dx - 6, t.dy)
            ..lineTo(t.dx + 6, t.dy)
            ..lineTo(t.dx, t.dy + 12)
            ..close(),
          Paint()..color = (d ~/ 26).isEven ? EraInk.red : EraInk.gold,
        );
      }
    }
    // The big drawing in the middle.
    paintGlyph(canvas, Rect.fromCenter(center: c, width: 96, height: 96), glyph, EraInk.ink, EraInk.red);
  }

  @override
  bool shouldRepaint(_WoodcutPainter old) => old.glyph != glyph;
}

/// A little print: an ink drawing, the name and its price.
class _Print extends StatelessWidget {
  const _Print({required this.glyph, required this.label, required this.sub, required this.locked, required this.onTap});
  final String glyph;
  final String label;
  final String sub;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: locked ? 0.55 : 1,
          child: Container(
            width: double.infinity,
            height: 124,
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            decoration: BoxDecoration(
              color: EraInk.card,
              border: Border.all(color: EraInk.ink, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(2, 3))],
            ),
            child: Column(
              children: [
                InkGlyph(glyph, size: 46),
                const SizedBox(height: 4),
                Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: fell(13.5, height: 1.05)),
                const Spacer(),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fell(11.5, color: EraInk.red),
                ),
              ],
            ),
          ),
        ),
        if (locked)
          const Positioned(right: -5, top: -5, child: WaxSeal('', size: 22)),
      ],
    ),
  );
}

