import 'package:flutter/material.dart';

import '../engine/legends.dart';
import '../engine/models.dart';
import '../theme.dart';
import 'legend_look.dart';
import 'widgets.dart';

/// Opens the Codex: "What really happened" cards for this Legend.
Future<void> openCodex(BuildContext context, Life life, Legend legend) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CodexScreen(life: life, legend: legend),
      ),
    );

/// The Codex (opened from the Me tab and the Chronicle line): one card per
/// turning point and per discovery. A card unlocks when you live through
/// that moment, and shows both what history records and what you did.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key, required this.life, required this.legend});
  final Life life;
  final Legend legend;

  static String _yours(String? v) => switch (v) {
    'canon' => 'You kept history.',
    'rewritten' => 'You rewrote history here.',
    null => '',
    _ => 'You bent history here.',
  };

  @override
  Widget build(BuildContext context) {
    final look = legendLookFor(life);
    final fate = legend.fates.where((f) => f.id == life.fate).firstOrNull;
    final cards = <(String, String, String?, String?, int?)>[
      for (final p in legend.turningPoints)
        (p.id, p.title, p.history, life.pivots[p.id], p.year),
      for (final e in legend.codex.entries)
        (e.key, e.value['title']!, e.value['text'], null, null),
    ];
    final found = cards.where((c) => life.codex.contains(c.$1)).length;
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        foregroundColor: NF.text,
        title: Text('Codex', style: NF.sora(20, weight: FontWeight.w700)),
      ),
      body: GlowBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'What really happened',
              style: look == null
                  ? NF.sora(16, weight: FontWeight.w700, color: NF.orange)
                  : legendHand(look, 24),
            ),
            const SizedBox(height: 4),
            Text(
              '$found of ${cards.length} cards found · Chronicle ${life.chronicle}%',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 14),
            if (fate != null) ...[
              NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fate',
                      style: look == null
                          ? NF.sora(12, color: NF.orange)
                          : legendHand(look, 18),
                    ),
                    Text(
                      fate.title,
                      style: NF.sora(20, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(fate.text, style: NF.sora(14, color: NF.soft, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(
                      'In history, ${legend.firstName} died in ${legend.deathYear}.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final (id, title, text, yours, year) in cards) ...[
              _card(look, id, title, text, yours, year),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(
    LegendLook? look,
    String id,
    String title,
    String? text,
    String? yours,
    int? year,
  ) {
    final open = life.codex.contains(id);
    return Opacity(
      opacity: open ? 1 : 0.6,
      child: NFCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    open ? title : 'A sealed page',
                    style: NF.sora(17, weight: FontWeight.w700),
                  ),
                ),
                if (year != null)
                  Text(
                    '$year',
                    style: look == null
                        ? NF.sora(13, color: NF.orange)
                        : legendHand(look, 18),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              open
                  ? (text ?? '')
                  : year != null
                  ? 'Live to $year to read what really happened.'
                  : 'Found by a choice somewhere in this life.',
              style: NF.sora(14, color: NF.soft, height: 1.45),
            ),
            if (open && yours != null) ...[
              const SizedBox(height: 8),
              Text(
                _yours(yours),
                style: look == null
                    ? NF.sora(13, weight: FontWeight.w700, color: NF.orange)
                    : legendHand(look, 19),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
