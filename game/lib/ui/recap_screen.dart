import 'package:flutter/material.dart';

import '../engine/dynasty.dart';
import '../engine/lifespan.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'me_screens.dart';
import 'widgets.dart';

/// The end of a life (plan S60/S61): tombstone with epitaph and cause, the
/// Life Title with its rule, the moments that mattered, the life's place in
/// history, then Rewind or a new life.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final engine = controller.engine!;
    final title = titleFor(life);
    final closest = [...life.npcs]..sort((a, b) => b.bond.compareTo(a.bond));
    final memories = life.flags.values.toList()
      ..sort((a, b) => a.age.compareTo(b.age));
    final mine = engine.world.ledger
        .where((s) => s.person == life.fullName)
        .toList();
    final rarityColor = switch (title.rarity) {
      'Legendary' => NF.orange,
      'Rare' => NF.blue,
      'Uncommon' => const Color(0xFF5EE6A8),
      _ => NF.soft,
    };
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Tombstone
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    decoration: BoxDecoration(
                      color: NF.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(120),
                        bottom: Radius.circular(18),
                      ),
                      border: Border.all(color: NF.borderStrong),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_florist_rounded,
                          color: NF.orange,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          life.fullName,
                          textAlign: TextAlign.center,
                          style: NF.sora(26, weight: FontWeight.w700),
                        ),
                        Text(
                          '${life.birthYear} – ${life.year}',
                          style: NF.sora(15, color: NF.soft),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '"${title.epitaph}"',
                          textAlign: TextAlign.center,
                          style: NF
                              .sora(16, color: NF.text, height: 1.5)
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          life.alive
                              ? 'Lived to ${life.age}'
                              : 'Died at ${life.age} · ${life.causeOfDeath}',
                          style: NF.sora(13, color: NF.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Life Title with transparent scoring
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: rarityColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Life Title',
                              style: NF.sora(13, color: NF.muted),
                            ),
                            const Spacer(),
                            Text(
                              title.rarity,
                              style: NF.sora(
                                12,
                                weight: FontWeight.w700,
                                color: rarityColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title.name,
                          style: NF.sora(22, weight: FontWeight.w700),
                        ),
                        Text(
                          'Earned for: ${title.why}',
                          style: NF.sora(13, color: NF.soft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${life.job ?? (life.retired ? 'Retired' : 'No job')} · net worth ${money(life.netWorth)}',
                          style: NF.sora(15, color: NF.soft),
                        ),
                        if (closest.isNotEmpty)
                          Text(
                            'Closest to ${closest.first.name} (${closest.first.bond}%)',
                            style: NF.sora(15, color: NF.soft),
                          ),
                        const SizedBox(height: 16),
                        const SectionLabel(
                          'Moments that mattered',
                          color: NF.blue,
                        ),
                        const SizedBox(height: 8),
                        if (memories.isEmpty)
                          Text(
                            'A quiet life.',
                            style: NF.sora(14, color: NF.muted),
                          ),
                        for (final m in memories.take(8))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Age ${m.age} · ${engine.fill(m.label, life)}',
                              style: NF.sora(14, color: NF.soft),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Your place in history (plan WL-006)
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.public_rounded,
                              color: NF.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your place in history',
                              style: NF.sora(15, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (mine.isEmpty)
                          Text(
                            'The papers never wrote about you. The people who loved you will remember.',
                            style: NF.sora(14, color: NF.soft),
                          ),
                        for (final s in mine)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${s.year} · ${s.headline}',
                              style: NF.sora(14, color: NF.soft),
                            ),
                          ),
                        if (engine.world.reputation(life.surname) != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            engine.world.reputation(life.surname)!,
                            style: NF.sora(13, color: NF.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (controller.rewindLock == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        style: secondaryButton().copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(52),
                          ),
                        ),
                        icon: const Icon(Icons.history_toggle_off_rounded),
                        label: const Text('Rewind'),
                        onPressed: () => showRewind(context, controller),
                      ),
                    ),
                  _dynasty(context, life),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: orangeButton().copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(56),
                      ),
                    ),
                    onPressed: controller.endLife,
                    child: const Text('Live another life'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your world remembers this life. The next one starts in ${life.year}.',
                    textAlign: TextAlign.center,
                    style: NF.sora(12, color: NF.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Continue as an heir, or the dynasty's end (plan GE-001/003).
  Widget _dynasty(BuildContext context, Life life) {
    final heirs = heirsOf(life);
    final cap = controller.generationCap;
    if (heirs.isEmpty) {
      return Text(
        life.generation > 1
            ? 'The ${life.surname} line ends here, after ${life.generation} generations.'
            : 'No children to carry on the family.',
        textAlign: TextAlign.center,
        style: NF.sora(13, color: NF.muted),
      );
    }
    if (life.generation >= cap) {
      return NFCard(
        child: Text(
          cap < 8
              ? 'Generation ${life.generation} of $cap: your dynasty is saved here. Relivable Plus continues a dynasty to Generation 8.'
              : 'Dynasty complete: eight generations of ${life.surname}s. Their story is in the history books.',
          style: NF.sora(14, color: NF.soft),
        ),
      );
    }
    return FilledButton.icon(
      style: primaryButton().copyWith(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      ),
      icon: const Icon(Icons.family_restroom_rounded),
      label: Text(
        'Continue as an heir · Generation ${life.generation + 1} of $cap',
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HeirPicker(controller: controller)),
      ),
    );
  }
}

/// Heir cards: age, stats, what they inherit and their memory of you
/// (plan GE-004).
class HeirPicker extends StatelessWidget {
  const HeirPicker({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final heirs = heirsOf(life);
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        title: Text(
          'Choose your heir',
          style: NF.sora(18, weight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Estate after debts and tax: ${money(estateOf(life))}. The heir keeps their own memories and relationships.',
            style: NF.sora(13, color: NF.muted),
          ),
          const SizedBox(height: 12),
          for (final h in heirs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(initials: h.name.substring(0, 1), size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${h.name} ${life.surname}',
                                style: NF.sora(17, weight: FontWeight.w700),
                              ),
                              Text(
                                '${h.role} · age ${h.ageIn(life.year)}${h.info['adopted'] == true ? ' · adopted' : ''}',
                                style: NF.sora(13, color: NF.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(memoryOf(h), style: NF.sora(14, color: NF.soft)),
                    const SizedBox(height: 6),
                    Text(
                      'Inherits ${money(shareFor(life, h))}${h.ageIn(life.year) < 18 ? ' (held in trust until 18)' : ''}',
                      style: NF.sora(13, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in Map<String, dynamic>.from(
                          h.info['stats'] ?? {},
                        ).entries)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: NF.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${e.key[0].toUpperCase()}${e.key.substring(1)} ${e.value}',
                              style: NF.sora(12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: orangeButton(),
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.continueAsHeir(h);
                      },
                      child: Text('Live as ${h.name}'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
