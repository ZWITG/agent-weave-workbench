import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/era_homes.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import 'era_art.dart';
import 'era_kit.dart' show eraRun;
import 'result_popup.dart';

/// Wealth → Home in an era life, drawn as your street: an ink elevation of
/// every home you could live in here, from a rented room to a palazzo,
/// with your flag over the one you live in. Tap a house (or its card) to
/// rent, buy, move in or sell.
class EraHomesScreen extends StatelessWidget {
  const EraHomesScreen({super.key, required this.controller});
  final GameController controller;

  static const _elsewhere = {
    'italy':
        'London: a timber-framed house, a manor. Fez: a riad round a courtyard. Cairo: rooms in a rab\'. Mbanza Kongo: a walled compound. Ndongo and Matamba: the kilombo war camp.',
    'england':
        'Florence: a workshop with rooms above, a villa, a palazzo. Fez: a riad round a courtyard. Mbanza Kongo: a walled compound.',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final here = eraHomesHere(life, era);
      final owned = eraOwnedHomes(life);
      final now = eraHomeNow(life, era);
      String m(int v) => eraM(life, v);
      // The street, cheapest first; the family home (when you have no
      // home of your own) stands at the start.
      int value(EraHome h) => h.buy > 0 ? h.buy : h.rent * 25;
      final street = [...here]..sort((a, b) => value(a).compareTo(value(b)));
      final houses = <_House>[
        if (now == null)
          _House(
            id: null,
            label: 'Family',
            price: 'you',
            style: street.any((h) => const {'hut', 'court'}.contains(_style(h, 0, 9))) ? 'hut' : 'cottage',
          ),
        for (final (i, h) in street.take(now == null ? 5 : 6).indexed)
          _House(
            id: h.id,
            label: _short(h.label),
            price: owned.containsKey(h.id) ? 'yours' : (h.rent > 0 ? '${m(h.rent)}/yr' : (h.buy > 0 ? m(h.buy) : 'free')),
            style: _style(h, i, street.length),
          ),
      ];
      final hereId = now?.id;
      return Scaffold(
        backgroundColor: EraInk.paper,
        appBar: AppBar(
          backgroundColor: EraInk.paper,
          foregroundColor: EraInk.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              children: [
                inkKicker('Homes · ${life.city} ${life.year}'),
                Text('A roof in ${life.city}', style: hand(42)),
                const SizedBox(height: 6),
                // The street.
                Container(
                  height: 210,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [EraInk.paper, EraInk.paper, EraInk.paper2],
                      stops: [0, 0.7, 0.7],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in houses)
                        Expanded(
                          flex: switch (h.style) {
                            'villa' || 'palazzo' => 5,
                            'cottage' => 3,
                            _ => 4,
                          },
                          child: GestureDetector(
                            onTap: h.id == null
                                ? null
                                : () => _act(context, life, era, eraHomeById(life, era, h.id!)!),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 150,
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: _FacadePainter(h.style, here: h.id == hereId),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: fell(11.5, height: 1.1)),
                                Text(
                                  h.price,
                                  maxLines: 1,
                                  style: fell(11.5, color: h.id == hereId ? EraInk.red : EraInk.ink2, height: 1.1),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Where you live.
                _HomeCard(
                  glyph: 'home',
                  title: eraHomeLine(life, era),
                  sub: now == null
                      ? 'Free, and nobody leaves you alone'
                      : (eraRents(life)
                            ? (now.rent == 0 ? now.about : 'Rent ${m(now.rent)} a year · ${now.about}')
                            : (now.upkeep > 0 ? 'Upkeep ${m(now.upkeep)} a year · ${now.about}' : now.about)),
                  standing: now?.standing ?? 0,
                  here: true,
                  action: eraRents(life) && now?.data['start'] != true ? 'Leave' : null,
                  onTap: eraRents(life) && now?.data['start'] != true
                      ? () => _run(context, 'Moving out', eraLeaveHome)
                      : null,
                ),
                for (final h in street)
                  if (h.id != hereId)
                    _HomeCard(
                      glyph: h.country ? 'hunt' : (h.work ? 'shop' : 'home'),
                      title: h.label,
                      sub: _lock(life, era, h) ?? h.about,
                      standing: h.standing,
                      price: owned.containsKey(h.id)
                          ? 'Yours'
                          : (h.rent > 0 ? '${m(h.rent)}/yr' : (h.buy > 0 ? m(h.buy) : 'Free')),
                      dim: _lock(life, era, h) != null,
                      onTap: () => _act(context, life, era, h),
                    ),
                if (owned.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 2),
                    child: Text('Your houses', style: hand(30)),
                  ),
                  for (final e in owned.entries)
                    if (eraHomeById(life, era, e.key) case final h?)
                      _HomeCard(
                        glyph: 'chest',
                        title: h.label,
                        sub: eraHomeId(life) == h.id
                            ? 'You live here · worth about ${m(e.value)}'
                            : 'Worth about ${m(e.value)} · sell for ${m(e.value * 4 ~/ 5)}',
                        standing: h.standing,
                        action: eraHomeId(life) == h.id ? 'Sell' : 'Move in',
                        onTap: eraHomeId(life) == h.id
                            ? () => _run(context, 'Selling', (l, era) => eraSellHome(l, era, h.id))
                            : () => _run(context, 'Moving', (l, era) => eraMoveHome(l, era, h.id)),
                      ),
                ],
                if (_elsewhere[era.regionOf(life).group] case final text?) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Text('Elsewhere', style: hand(30)),
                  ),
                  Text(text, style: fell(14.5, color: EraInk.ink2)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  static String _short(String label) {
    final w = label.replaceFirst(RegExp(r'^(A|An|The) '), '').split(' ');
    return w.length > 1 && !const {'in', 'with', 'of', 'on', 'round', 'above'}.contains(w[1])
        ? w.take(2).join(' ')
        : w.first;
  }

  static String _style(EraHome h, int i, int n) {
    if (const {'lineage', 'mudhouse', 'kilombo'}.contains(h.id)) return 'hut';
    if (const {'kongo_compound', 'noble_enclosure', 'sahel_compound', 'riad', 'funduq', 'medina', 'qaa', 'rab'}.contains(h.id)) {
      return 'court';
    }
    if (h.country) return 'villa';
    if (h.work) return 'workshop';
    if (h.label.toLowerCase().contains('palazzo') || h.standing >= 4) return 'palazzo';
    if (h.label.toLowerCase().contains('room') || h.standing <= 0) return 'room';
    if (h.label.toLowerCase().contains('compound') || h.label.toLowerCase().contains('riad')) return 'court';
    return i >= n - 1 ? 'palazzo' : 'townhouse';
  }

  String? _lock(Life life, EraRules era, EraHome h) {
    if (eraOwnedHomes(life).containsKey(h.id)) return null;
    return eraHomeLock(life, era, h, buy: !h.data.containsKey('rent'));
  }

  void _run(BuildContext context, String t, String Function(Life, EraRules) a) =>
      eraRun(context, controller, t, (l, e, _) => a(l, e), icon: Icons.house_outlined);

  void _act(BuildContext context, Life life, EraRules era, EraHome h) {
    final owned = eraOwnedHomes(life);
    if (owned.containsKey(h.id)) {
      if (eraHomeId(life) == h.id) {
        _run(context, 'Selling', (l, e) => eraSellHome(l, e, h.id));
      } else {
        _run(context, 'Moving', (l, e) => eraMoveHome(l, e, h.id));
      }
      return;
    }
    if (eraHomeId(life) == h.id) return;
    final lock = _lock(life, era, h);
    if (lock != null) {
      showResultPopup(context, ActionResult(lock), title: h.label, icon: Icons.lock_outline);
      return;
    }
    if (h.data.containsKey('rent')) {
      _run(context, h.label, (l, e) => eraRentHome(l, e, h.id));
    } else {
      _run(context, h.label, (l, e) => eraBuyHome(l, e, h.id));
    }
  }
}

class _House {
  const _House({required this.id, required this.label, required this.price, required this.style});
  final String? id;
  final String label;
  final String price;
  final String style;
}

/// One house front in ink: a cottage, a room house, a workshop, a
/// townhouse, a courtyard house, a villa or a palazzo. A flag flies over
/// the one you live in.
class _FacadePainter extends CustomPainter {
  _FacadePainter(this.style, {required this.here});
  final String style;
  final bool here;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = Paint()
      ..color = EraInk.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final wall = Paint()..color = EraInk.card;
    final roof = Paint()..color = EraInk.red;
    final gold = Paint()..color = EraInk.gold;
    final wood = Paint()..color = EraInk.wood;
    final glass = Paint()..color = EraInk.paper2;
    final hatch = Paint()
      ..color = EraInk.ink.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    void box(Rect r, Paint fill) {
      canvas.drawRect(r, fill);
      canvas.drawRect(r, s);
    }

    void poly(List<Offset> pts, Paint fill) {
      final p = Path()..addPolygon(pts, true);
      canvas.drawPath(p, fill);
      canvas.drawPath(p, s);
    }

    void windows(Rect body, int cols, int rows, {double top = 14, double bottom = 30}) {
      final ww = body.width / (cols * 2 + 1);
      final avail = body.height - top - bottom;
      final wh = min(20.0, avail / (rows * 1.6));
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          box(Rect.fromLTWH(body.left + ww * (c * 2 + 1), body.top + top + r * wh * 1.6, ww, wh), glass);
        }
      }
    }

    final m = w * 0.06;
    late Rect body;
    late double flagX, flagY;
    switch (style) {
      case 'cottage':
        body = Rect.fromLTRB(m, h * 0.5, w - m, h);
        box(body, wall);
        poly([Offset(m - 3, body.top), Offset(w / 2, h * 0.3), Offset(w - m + 3, body.top)], roof);
        box(Rect.fromLTWH(w / 2 - 7, h - 26, 14, 26), wood);
        flagX = w / 2;
        flagY = h * 0.3;
      case 'room':
        body = Rect.fromLTRB(m, h * 0.42, w - m, h);
        box(body, wall);
        poly([Offset(m - 4, body.top), Offset(w / 2, h * 0.26), Offset(w - m + 4, body.top)], roof);
        windows(body, 2, 2);
        box(Rect.fromLTWH(w / 2 - 9, h - 26, 18, 26), wood);
        flagX = w / 2;
        flagY = h * 0.26;
      case 'workshop':
        body = Rect.fromLTRB(m, h * 0.22, w - m, h);
        box(body, wall);
        box(Rect.fromLTRB(m - 3, h * 0.17, w - m + 3, h * 0.22), gold);
        windows(body, 2, 3, bottom: 40);
        // An open shopfront with an awning.
        box(Rect.fromLTWH(m + 4, h - 34, w - 2 * m - 8, 34), wood);
        for (var x = m + 4; x < w - m - 4; x += 8) {
          canvas.drawRect(Rect.fromLTWH(x, h - 42, 4, 8), roof);
        }
        flagX = w / 2;
        flagY = h * 0.17;
      case 'townhouse':
        body = Rect.fromLTRB(m, h * 0.3, w - m, h);
        box(body, wall);
        poly([Offset(m - 4, body.top), Offset(w / 2, h * 0.14), Offset(w - m + 4, body.top)], roof);
        windows(body, 2, 3);
        final door = Path()
          ..moveTo(w / 2 - 10, h)
          ..lineTo(w / 2 - 10, h - 18)
          ..arcToPoint(Offset(w / 2 + 10, h - 18), radius: const Radius.circular(10))
          ..lineTo(w / 2 + 10, h);
        canvas.drawPath(door, wood);
        canvas.drawPath(door, s);
        flagX = w / 2;
        flagY = h * 0.14;
      case 'hut':
        body = Rect.fromLTRB(w * 0.18, h * 0.62, w * 0.82, h);
        box(body, Paint()..color = const Color(0xFFC9A577));
        poly([Offset(w * 0.08, body.top + 4), Offset(w / 2, h * 0.36), Offset(w * 0.92, body.top + 4)], Paint()..color = const Color(0xFFB8933F));
        for (var x = w * 0.2; x < w * 0.8; x += 6) {
          canvas.drawLine(Offset(x, body.top - 2), Offset(w / 2 + (x - w / 2) * 0.3, h * 0.42), hatch);
        }
        box(Rect.fromLTWH(w / 2 - 7, h - 24, 14, 24), wood);
        flagX = w / 2;
        flagY = h * 0.36;
      case 'court':
        body = Rect.fromLTRB(m, h * 0.5, w - m, h);
        box(body, wall);
        for (var x = m; x < w - m; x += 10) {
          canvas.drawRect(Rect.fromLTWH(x, body.top - 6, 6, 6), Paint()..color = EraInk.ink);
        }
        final arch = Path()
          ..moveTo(w / 2 - 12, h)
          ..lineTo(w / 2 - 12, h - 22)
          ..arcToPoint(Offset(w / 2 + 12, h - 22), radius: const Radius.circular(12))
          ..lineTo(w / 2 + 12, h);
        canvas.drawPath(arch, wood);
        canvas.drawPath(arch, s);
        // A palm beyond the wall.
        canvas.drawLine(Offset(w * 0.78, body.top), Offset(w * 0.74, h * 0.2), s);
        final frond = Paint()
          ..color = EraInk.green
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        for (final a in [-2.8, -2.2, -1.6, -1.0, -0.35]) {
          canvas.drawLine(Offset(w * 0.74, h * 0.2), Offset(w * 0.74 + cos(a) * 20, h * 0.2 - sin(a) * -8 + 6), frond);
        }
        flagX = w * 0.3;
        flagY = body.top - 6;
      case 'villa':
        body = Rect.fromLTRB(m, h * 0.52, w - m, h);
        box(body, wall);
        poly([Offset(m - 5, body.top), Offset(w / 2, h * 0.34), Offset(w - m + 5, body.top)], roof);
        for (var i = 0; i < 4; i++) {
          final x = body.left + 6 + i * (body.width - 12) / 4;
          box(Rect.fromLTWH(x + 2, h - 32, (body.width - 12) / 4 - 4, 32), glass);
        }
        // Cypresses.
        for (final x in [w * 0.02, w * 0.98]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(x, h * 0.62), width: 10, height: 40), Paint()..color = EraInk.green);
        }
        flagX = w / 2;
        flagY = h * 0.34;
      default: // palazzo
        body = Rect.fromLTRB(m, h * 0.12, w - m, h);
        box(body, wall);
        box(Rect.fromLTRB(m - 4, h * 0.06, w - m + 4, h * 0.12), gold);
        windows(body, 3, 3, top: 16, bottom: 36);
        for (var y = body.top + 4; y < h; y += 9) {
          canvas.drawLine(Offset(body.left, y), Offset(body.left + 6, y), hatch);
          canvas.drawLine(Offset(body.right - 6, y), Offset(body.right, y), hatch);
        }
        final arch = Path()
          ..moveTo(w / 2 - 13, h)
          ..lineTo(w / 2 - 13, h - 20)
          ..arcToPoint(Offset(w / 2 + 13, h - 20), radius: const Radius.circular(13))
          ..lineTo(w / 2 + 13, h);
        canvas.drawPath(arch, wood);
        canvas.drawPath(arch, s);
        flagX = w / 2;
        flagY = h * 0.06;
    }
    if (here) {
      canvas.drawLine(Offset(flagX, flagY), Offset(flagX, flagY - 30), s..strokeWidth = 2);
      final flag = Path()
        ..moveTo(flagX, flagY - 30)
        ..lineTo(flagX + 20, flagY - 24)
        ..lineTo(flagX, flagY - 17)
        ..close();
      canvas.drawPath(flag, roof);
    }
  }

  @override
  bool shouldRepaint(_FacadePainter old) => old.style != style || old.here != here;
}

/// A home as a card: a drawing, its name, its standing in stars and its
/// price or what you can do. The one you live in is printed dark.
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.glyph,
    required this.title,
    required this.sub,
    required this.standing,
    this.price,
    this.action,
    this.onTap,
    this.here = false,
    this.dim = false,
  });
  final String glyph;
  final String title;
  final String sub;
  final int standing;
  final String? price;
  final String? action;
  final VoidCallback? onTap;
  final bool here;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final fg = here ? EraInk.paper : EraInk.ink;
    final stars = standing.clamp(0, 5);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dim ? 0.6 : 1,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          decoration: BoxDecoration(
            color: here ? EraInk.ink : EraInk.card,
            border: Border.all(color: EraInk.ink, width: 2),
          ),
          child: Row(
            children: [
              InkGlyph(glyph, size: 40, color: fg, accent: here ? EraInk.goldLight : EraInk.red),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: fell(16, color: fg)),
                    Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: fell(12.5, color: here ? EraInk.paper2 : EraInk.ink2, italic: dim)),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 13,
                            color: here ? EraInk.goldLight : EraInk.gold2,
                          ),
                        const SizedBox(width: 4),
                        Text('standing', style: fell(11.5, color: here ? EraInk.goldLight : EraInk.gold2)),
                      ],
                    ),
                  ],
                ),
              ),
              if (price != null) Text(price!, style: hand(24, color: fg)),
              if (action != null) InkButton(action!, onTap: onTap, color: here ? EraInk.red : EraInk.red),
            ],
          ),
        ),
      ),
    );
  }
}
