import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/eras.dart';
import '../engine/legends.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'journey.dart';
import 'legend_look.dart';
import 'widgets.dart';

/// In a Legend preview life, the modern Path, Wealth and Activities screens
/// are replaced by what the era has so far, and a note that the rest comes
/// with the Renaissance update (Legends plan, Phase 2). Nothing modern
/// (phones, shares, cars) can be reached from 1470s Florence.
class LegendSoonTab extends StatelessWidget {
  const LegendSoonTab({super.key, required this.life, required this.kind});
  final Life life;

  /// 'path' or 'wealth'.
  final String kind;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: [LegendSoonCard(life: life, kind: kind)],
  );
}

class LegendSoonCard extends StatelessWidget {
  const LegendSoonCard({
    super.key,
    required this.life,
    required this.kind,
    this.controller,
  });
  final Life life;
  final String kind;

  /// Given on the Activities card, for the journey button.
  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    final look = legendLookFor(life);
    final legend = legendRegistry[life.legendId];
    final hand = look == null
        ? NF.sora(16, color: NF.orange)
        : legendHand(look, 21);
    final era = eraRegistry[life.era];
    final region = era?.regionOf(life);
    final money = era?.currencies[region?.currencyIn(life.year)];
    String price(String item) =>
        moneyIn(era!.price(item, region!, life.year), life.country);
    final (title, lines) = switch (kind) {
      'wealth' => (
        'Your purse',
        [
          'In your purse: ${moneyIn(life.money, life.country)}',
          if (life.job != null && life.salary > 0)
            '${life.job}: ${moneyIn(life.salary, life.country)} a year',
          if (money != null) 'Money here is counted in ${money.name}.',
          if (era != null && region != null)
            "A year's bread costs ${price('bread_year')}, a cloak "
                '${price('cloak')} and a horse ${price('horse')}.',
          if (era != null && era.priceLevel(life.year) > 1.25)
            'Prices have been rising for years, faster than pay.',
        ],
      ),
      'activities' => (
        '${life.city}, ${life.year}',
        [
          if (region != null) ...[
            '${region.nameIn(life.year)}, ruled by ${region.rulerIn(life.year) ?? 'no one'}.',
            'Faith: ${region.faithIn(life.year)}. People here speak ${region.language}.',
          ],
          'Each year brings the moments of ${legend == null ? 'this life' : "${legend.firstName}'s life"}: '
              'press Age +1 to live the next one.',
          if (legend != null) 'Your choices build towards the turning points, and the Codex keeps what really happened.',
        ],
      ),
      _ => (
        legend?.chapterFor(life.year) ?? 'Your path',
        [
          if (life.job != null) 'Now: ${life.job}',
          'Your path is written by the events of each year and the turning points ahead.',
        ],
      ),
    };
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: hand),
          const SizedBox(height: 8),
          for (final l in lines) ...[
            Text(l, style: NF.sora(15, color: NF.soft, height: 1.4)),
            const SizedBox(height: 6),
          ],
          if (kind == 'activities' && controller != null && life.alive) ...[
            const SizedBox(height: 4),
            FilledButton.icon(
              style: primaryButton().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Make a journey'),
              onPressed: () => openJourneys(context, controller!),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text(
            'More to do in ${legend == null ? 'this world' : "${legend.firstName}'s world"} '
            'comes with the Renaissance update: workshops, commissions, '
            'markets and the mini-games of the era.',
            style: NF.sora(13, color: NF.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
