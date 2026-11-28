import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/era_market.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import 'era_art.dart';
import 'era_kit.dart' show eraRun;
import 'result_popup.dart';

/// The market in an era life, drawn as a stall: a striped awning, wooden
/// shelves of cloth, beasts and craft, each thing drawn in ink with a
/// hanging price tag. What you own wears a red "YOURS" stamp and sells
/// back for half. Nothing modern is for sale.
class EraMarketScreen extends StatelessWidget {
  const EraMarketScreen({super.key, required this.controller});
  final GameController controller;

  static const _groups = {
    'Cloth and dress': ['cloak', 'silk', 'copper'],
    'Beasts': ['mule', 'horse'],
    'Craft and learning': ['book', 'paper', 'lute', 'sword', 'spice'],
  };

  static String glyphFor(String id) => switch (id) {
    'silk' => 'doublet',
    'copper' => 'pot',
    'spice' => 'sack',
    _ => id,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final items = eraMarketHere(life, era);
      bool yours(String id) => eraOwns(life, id) && id != 'spice';
      // Things you own that this market no longer sells still show, so you
      // can sell them.
      final extra = [
        for (final id in eraOwned(life))
          if (!items.any((i) => i['id'] == id))
            ?eraItem(life, era, id),
      ];
      return Scaffold(
        backgroundColor: const Color(0xFFE9D6AE),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 96 + MediaQuery.paddingOf(context).top,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: CustomPaint(painter: _AwningPainter())),
                      Positioned(
                        left: 4,
                        top: MediaQuery.paddingOf(context).top + 4,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: EraInk.ink),
                          style: IconButton.styleFrom(backgroundColor: EraInk.card),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: inkKicker('${eraMarketName(life, era)} · ${life.year}')),
                Center(child: Text('The market', style: hand(42, color: EraInk.ink))),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'You have ${eraM(life, life.money)}. Nothing modern is for sale.',
                      textAlign: TextAlign.center,
                      style: fell(14, color: EraInk.ink2, italic: true),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (final g in {
                  ..._groups,
                  if (extra.isNotEmpty) 'From elsewhere': [for (final e in extra) e['id'] as String],
                }.entries)
                  if ([...items, ...extra].any((i) => g.value.contains(i['id'])))
                    _Shelf(
                      title: g.key,
                      goods: [
                        for (final it in [...items, ...extra].where((i) => g.value.contains(i['id'])))
                          _Good(
                            glyph: glyphFor(it['id'] as String),
                            name: it['label'] as String,
                            effect: _effect(it),
                            tag: yours(it['id'] as String)
                                ? 'sell ${eraM(life, max(1, eraCost(life, era, it['cost'] as int) ~/ 2))}'
                                : eraM(life, eraCost(life, era, it['cost'] as int)),
                            yours: yours(it['id'] as String),
                            locked: !yours(it['id'] as String) && eraItemLock(life, era, it) != null,
                            onTap: () => _tap(context, it, yours: yours(it['id'] as String)),
                          ),
                      ],
                    ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                  child: Text(
                    'Tap a thing to buy it; tap what is yours to sell it back for half. Prices: game approximations from historians\' price series.',
                    style: fell(12.5, color: EraInk.ink2, italic: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _tap(BuildContext context, Map<String, dynamic> it, {required bool yours}) {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final id = it['id'] as String;
    final lock = yours ? null : eraItemLock(life, era, it);
    if (lock != null) {
      showResultPopup(context, ActionResult(lock), title: it['label'] as String, icon: Icons.lock_outline);
    } else if (yours) {
      eraRun(context, controller, 'Selling', (l, e, _) => eraSell(l, e, id), icon: Icons.storefront_outlined);
    } else {
      eraRun(
        context,
        controller,
        it['label'] as String,
        (l, e, rng) => eraBuy(l, e, id, rng),
        icon: Icons.storefront_outlined,
      );
    }
  }

  static String _effect(Map it) => [
    for (final k in const ['looks', 'smarts', 'creativity'])
      if ((it[k] as num?) case final v? when v != 0) '+${v.toInt()} $k',
    if (it['sumptuary'] == true) 'the officers notice',
  ].join(' · ');
}

/// A red and cream awning with a scalloped edge.
class _AwningPainter extends CustomPainter {
  const _AwningPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stripe = 36.0;
    final h = size.height - 18;
    for (var x = 0.0, i = 0; x < size.width; x += stripe, i++) {
      final paint = Paint()..color = i.isEven ? EraInk.red : EraInk.paper;
      canvas.drawRect(Rect.fromLTWH(x, 0, stripe, h), paint);
      canvas.drawArc(Rect.fromLTWH(x, h - 18, stripe, 36), 0, pi, true, paint);
    }
    canvas.drawLine(
      Offset(0, h),
      Offset(size.width, h),
      Paint()
        ..color = EraInk.red2.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_AwningPainter old) => false;
}

/// A labelled wooden shelf of goods.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.goods});
  final String title;
  final List<Widget> goods;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: hand(26, color: EraInk.red2)),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth / 3;
            final rows = <List<Widget>>[];
            for (var i = 0; i < goods.length; i += 3) {
              rows.add(goods.sublist(i, min(i + 3, goods.length)));
            }
            return Column(
              children: [
                for (final row in rows) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [for (final g in row) SizedBox(width: w, child: g)],
                  ),
                  Container(
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF8A6038), Color(0xFF5E3E20)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 4))],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

/// One thing on the shelf: its drawing, a hanging price tag, its name.
class _Good extends StatelessWidget {
  const _Good({
    required this.glyph,
    required this.name,
    required this.effect,
    required this.tag,
    required this.yours,
    required this.locked,
    required this.onTap,
  });
  final String glyph;
  final String name;
  final String effect;
  final String tag;
  final bool yours;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Opacity(
      opacity: locked ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                InkGlyph(glyph, size: 62),
                if (yours)
                  Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: EraInk.paper.withValues(alpha: 0.75),
                        border: Border.all(color: EraInk.red, width: 2.5),
                      ),
                      child: const Text(
                        'YOURS',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: EraInk.red,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            ClipPath(
              clipper: _TagClipper(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
                color: EraInk.ink,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: EraInk.card,
                  child: Text(tag, style: fell(13)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(name, textAlign: TextAlign.center, maxLines: 2, style: fell(13, height: 1.05)),
            if (effect.isNotEmpty)
              Text(effect, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: fell(11, color: EraInk.green)),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}

class _TagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(10, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(10, size.height)
    ..lineTo(0, size.height / 2)
    ..close();

  @override
  bool shouldReclip(_TagClipper old) => false;
}
