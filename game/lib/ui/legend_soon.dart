import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/legends.dart';
import '../engine/models.dart';
import '../theme.dart';
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
    children: [
      LegendSoonCard(life: life, kind: kind),
    ],
  );
}

class LegendSoonCard extends StatelessWidget {
  const LegendSoonCard({super.key, required this.life, required this.kind});
  final Life life;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final look = legendLookFor(life);
    final legend = legendRegistry[life.legendId];
    final hand = look == null
        ? NF.sora(16, color: NF.orange)
        : legendHand(look, 21);
    final (title, lines) = switch (kind) {
      'wealth' => (
        'Your purse',
        [
          'Florins: ${shortMoney(life.money, life.country)}',
          if (life.job != null && life.salary > 0)
            '${life.job}: ${shortMoney(life.salary, life.country)} a year',
          'In this preview, money comes from your work and your choices.',
        ],
      ),
      'activities' => (
        '${life.city}, ${life.year}',
        [
          'Each year brings the moments of ${legend == null ? 'this life' : "${legend.firstName}'s life"}: '
              'press Age +1 to live the next one.',
          'Your choices build towards the turning points, and the Codex keeps what really happened.',
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
          const SizedBox(height: 6),
          Text(
            'More to do in ${legend?.firstName ?? 'this'}\'s world comes with the '
            'Renaissance update: workshops, commissions, markets and the '
            'mini-games of the era.',
            style: NF.sora(13, color: NF.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
