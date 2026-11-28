import 'package:flutter/material.dart';

import '../engine/currency.dart' show currencyOf;
import '../engine/era_houses.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// Wealth → The Great Houses in an era life (Phase 2D): the rich list of
/// the age in a gold-trimmed "Palazzo" look (the era's Gilded): each
/// family's crest, city, trade and estimated fortune, rising or falling
/// with history, and your house once it joins.
class EraHousesScreen extends StatelessWidget {
  const EraHousesScreen({super.key, required this.controller});
  final GameController controller;

  static const gold = Color(0xFFB8933F);
  static const goldDeep = Color(0xFF8A6A2C);

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
        return v >= 1000000
            ? '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M'
            : (v >= 1000 ? '${(v / 1000).round()}k' : '$v');
      }
      return Scaffold(
        backgroundColor: NF.bg,
        appBar: AppBar(
          backgroundColor: NF.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  eraKicker('The Great Houses · ${life.year}'),
                  const SizedBox(height: 4),
                  Text('The Palazzo list', style: eraHand(life, 38)),
                  const SizedBox(height: 6),
                  Text(
                    'The richest families of the age, as historians estimate them. Your house can join.',
                    style: NF.sora(15, color: NF.soft, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: goldDeep, width: 2),
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: NF.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gold, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          for (final (i, h) in standing.indexed)
                            _Rank(
                              rank: i + 1,
                              h: h,
                              worth: '$symbol${k(h.worth)}',
                              first: i == 0,
                            ),
                          for (final h in fallen)
                            Opacity(
                              opacity: 0.55,
                              child: _Rank(rank: null, h: h, worth: 'fallen', first: false),
                            ),
                          if (!on)
                            _YouRow(
                              name: eraYourHouse(life),
                              line:
                                  '${eraM(life, eraNetWorth(life, era))} · joins the list at ${eraM(life, eraHousesJoin(life, era))}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    era.housesData['note'] as String? ?? '',
                    style: NF.sora(12.5, color: NF.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Crest extends StatelessWidget {
  const _Crest(this.letter);
  final String letter;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: NF.surface,
      border: Border.all(color: EraHousesScreen.goldDeep, width: 1.6),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(3),
        bottom: Radius.circular(15),
      ),
    ),
    child: Text(letter, style: NF.sora(15, weight: FontWeight.w700, color: NF.orange)),
  );
}

class _Rank extends StatelessWidget {
  const _Rank({required this.rank, required this.h, required this.worth, required this.first});
  final int? rank;
  final EraGreatHouse h;
  final String worth;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final letter = h.name.replaceFirst(RegExp(r'^The (house of |households of the )?'), '').characters.first;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: h.you ? NF.blue.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(8),
        border: first || h.you
            ? null
            : Border(top: BorderSide(color: NF.text.withValues(alpha: 0.14))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(rank == null ? '–' : '$rank', style: NF.sora(17, weight: FontWeight.w700, color: NF.blue)),
          ),
          _Crest(letter),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name, style: NF.sora(15.5, weight: FontWeight.w700)),
                Text(
                  [h.city, h.fallen ? (h.note ?? 'fallen') : (h.note ?? h.trade)].join(' · '),
                  style: NF.sora(12.5, color: NF.muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(worth, style: NF.sora(14, weight: FontWeight.w700)),
          if (!h.fallen && h.trend != 0)
            Icon(
              h.trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: h.trend > 0 ? NF.good : NF.danger,
            ),
        ],
      ),
    );
  }
}

class _YouRow extends StatelessWidget {
  const _YouRow({required this.name, required this.line});
  final String name;
  final String line;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
    decoration: BoxDecoration(
      color: NF.blue.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        SizedBox(width: 26, child: Text('?', style: NF.sora(17, weight: FontWeight.w700, color: NF.blue))),
        _Crest(name.split(' ').last.characters.first.toUpperCase()),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: NF.sora(15.5, weight: FontWeight.w700)),
              Text(line, style: NF.sora(12.5, color: NF.muted, height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}
