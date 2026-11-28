import 'package:flutter/material.dart';

import '../engine/currency.dart' show currencyOf;
import '../engine/era_houses.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import 'era_art.dart';

/// Wealth → The Great Houses in an era life, drawn as a dark hall of
/// banners: the three richest families hang as heraldic banners in their
/// own colours, the rest are ranked below with a gold bar for their
/// fortune, the fallen are struck through, and your own banner waits,
/// empty, until your house joins.
class EraHousesScreen extends StatelessWidget {
  const EraHousesScreen({super.key, required this.controller});
  final GameController controller;

  static const gold = EraInk.goldLight;
  static const _hall = Color(0xFF1F1512);
  static const _colours = [
    Color(0xFFB23A2A),
    Color(0xFF2F4F7A),
    Color(0xFF3E6A3A),
  ];

  static String crestOf(String name) =>
      name.replaceFirst(RegExp(r'^The (house of |households of the )?'), '').characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final list = eraGreatHouses(life, era);
      final standing = list.where((h) => !h.fallen).toList();
      final fallen = list.where((h) => h.fallen).toList();
      final on = standing.any((h) => h.you);
      // Fortunes are kept in florins; shown in the money of this place.
      final (rate, sym) = currencyOf(life.country);
      final symbol = sym.length > 2 ? '$sym ' : sym;
      String k(int florins) {
        final v = (florins * rate).round();
        return symbol +
            (v >= 1000000
                ? '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M'
                : (v >= 1000 ? '${(v / 1000).round()}k' : '$v'));
      }

      final top = standing.take(3).toList();
      final rest = standing.skip(3).toList();
      final most = standing.isEmpty ? 1 : standing.first.worth;
      final worth = eraNetWorth(life, era);
      final join = eraHousesJoin(life, era);
      return Scaffold(
        backgroundColor: _hall,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: gold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.3,
              colors: [Color(0xFF4A2A22), _hall],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 48, 18, 28),
                  children: [
                    inkKicker('The Great Houses · ${life.year}', color: const Color(0xFFD9B25E)),
                    Text('The hall of banners', style: hand(42, color: const Color(0xFFF6DC8F))),
                    Text(
                      'The richest families of the age, as historians estimate them. Your house can hang here too.',
                      style: fell(14.5, color: const Color(0xFFD9C49A)),
                    ),
                    const SizedBox(height: 14),
                    // The podium: second, first, third.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final i in [1, 0, 2])
                          if (i < top.length)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: i == 0 ? 0 : (i == 1 ? 26 : 44)),
                                child: _Banner(
                                  rank: i + 1,
                                  name: top[i].name.replaceFirst('The ', ''),
                                  crest: crestOf(top[i].name),
                                  colour: _colours[i],
                                  worth: k(top[i].worth),
                                  trend: top[i].trend,
                                  note: top[i].note ?? top[i].city,
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final (i, h) in rest.indexed)
                      _RankRow(
                        rank: '${i + 4}',
                        title: '${h.name} · ${h.city}',
                        sub: h.note ?? h.trade,
                        worth: k(h.worth),
                        trend: h.trend,
                        share: h.worth / most,
                        you: h.you,
                      ),
                    for (final h in fallen)
                      Opacity(
                        opacity: 0.5,
                        child: _RankRow(
                          rank: '–',
                          title: '${h.name} · ${h.city}',
                          sub: h.note ?? 'fallen',
                          worth: 'fallen',
                          trend: 0,
                          share: 0,
                          you: false,
                          struck: true,
                        ),
                      ),
                    if (!on)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gold, width: 1.5),
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: 0.8,
                              child: _Crest(letter: eraYourHouse(life).split(' ').last.characters.first.toUpperCase(), empty: true),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(eraYourHouse(life), style: fell(17, color: const Color(0xFFF1DFB5))),
                                  Text(
                                    '${eraM(life, worth)} of ${eraM(life, join)} to raise your banner',
                                    style: fell(13, color: const Color(0xFFD9C49A)),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: join <= 0 ? 0 : (worth / join).clamp(0.02, 1.0),
                                      minHeight: 6,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      color: gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      era.housesData['note'] as String? ?? '',
                      style: fell(12.5, color: const Color(0xFFB8A27A), italic: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// A shield with the family's letter.
class _Crest extends StatelessWidget {
  const _Crest({required this.letter, this.empty = false});
  final String letter;
  final bool empty;
  static const size = 44.0;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size * 1.18,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: empty ? Colors.transparent : const Color(0xFFF1DFB5),
      border: Border.all(color: EraInk.goldLight, width: 2),
      borderRadius: BorderRadius.vertical(top: const Radius.circular(3), bottom: Radius.circular(size / 2)),
    ),
    child: Text(letter, style: fell(size * 0.55, color: empty ? EraInk.goldLight : EraInk.ink)),
  );
}

/// A hanging banner on a gold rod.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.rank,
    required this.name,
    required this.crest,
    required this.colour,
    required this.worth,
    required this.trend,
    required this.note,
  });
  final int rank;
  final String name;
  final String crest;
  final Color colour;
  final String worth;
  final int trend;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [EraInk.goldLight, EraInk.gold2],
            ),
          ),
        ),
        ClipPath(
          clipper: _SwallowTail(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 34),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colour, Color.lerp(colour, Colors.black, 0.35)!],
              ),
            ),
            child: Column(
              children: [
                _Crest(letter: crest),
                const SizedBox(height: 6),
                Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: fell(16, color: Colors.white)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(worth, style: hand(25, color: const Color(0xFFF6DC8F))),
                      ),
                    ),
                    if (trend != 0)
                      Icon(
                        trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 15,
                        color: const Color(0xFFF6DC8F),
                      ),
                  ],
                ),
                Text(
                  ['1st', '2nd', '3rd'][rank - 1],
                  style: fell(11.5, color: Colors.white70),
                ),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: fell(11, color: Colors.white70, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SwallowTail extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width / 2, size.height - 24)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_SwallowTail old) => false;
}

/// A family below the podium, with a gold bar for its fortune.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.title,
    required this.sub,
    required this.worth,
    required this.trend,
    required this.share,
    required this.you,
    this.struck = false,
  });
  final String rank;
  final String title;
  final String sub;
  final String worth;
  final int trend;
  final double share;
  final bool you;
  final bool struck;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
    decoration: BoxDecoration(
      color: you ? EraInk.red2.withValues(alpha: 0.35) : null,
      border: Border(top: BorderSide(color: EraInk.goldLight.withValues(alpha: 0.22))),
    ),
    child: Row(
      children: [
        SizedBox(width: 28, child: Text(rank, style: hand(26, color: const Color(0xFFD9B25E)))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fell(15, color: const Color(0xFFF1DFB5)).copyWith(
                        decoration: struck ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFFF1DFB5),
                      ),
                    ),
                  ),
                  Text(worth, style: fell(14.5, color: const Color(0xFFF1DFB5))),
                  if (trend != 0)
                    Icon(
                      trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: trend > 0 ? const Color(0xFF8FCB7A) : const Color(0xFFE07A62),
                    ),
                ],
              ),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: fell(12, color: const Color(0xFFB8A27A))),
              if (share > 0) ...[
                const SizedBox(height: 4),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: share.clamp(0.03, 1.0),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [EraInk.goldLight, EraInk.gold2]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
