import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import 'widgets.dart';

/// End of the prototype slice (age 30) or an early death: a Life Recap card.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final engine = controller.engine!;
    final closest = [...life.npcs]..sort((a, b) => b.bond.compareTo(a.bond));
    final memories = life.flags.values.toList()..sort((a, b) => a.age.compareTo(b.age));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                NFCard(
                  color: NF.nav,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(life.alive ? 'Life recap · first 30 years' : 'Life recap'),
                      const SizedBox(height: 12),
                      Text(life.fullName, style: NF.sora(28, weight: FontWeight.w700)),
                      Text(
                        life.alive
                            ? '${life.birthYear}–${life.year} · ${life.city}, ${life.country}'
                            : '${life.birthYear}–${life.year} · died at ${life.age} (${life.causeOfDeath})',
                        style: NF.sora(14, color: NF.muted),
                      ),
                      const SizedBox(height: 20),
                      Text('${life.job ?? 'No job'} · \$${life.money} in the bank',
                          style: NF.sora(15, color: NF.soft)),
                      if (closest.isNotEmpty)
                        Text('Closest to ${closest.first.name} (${closest.first.bond}%)',
                            style: NF.sora(15, color: NF.soft)),
                      const SizedBox(height: 20),
                      const SectionLabel('Moments that mattered', color: NF.blue),
                      const SizedBox(height: 8),
                      if (memories.isEmpty) Text('A quiet life.', style: NF.sora(14, color: NF.muted)),
                      for (final m in memories.take(6))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Age ${m.age} · ${engine.fill(m.label, life)}',
                              style: NF.sora(14, color: NF.soft)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  life.alive
                      ? 'This prototype ends at 30. The full game goes on to old age, children and the history books.'
                      : 'Your story ends here.',
                  textAlign: TextAlign.center,
                  style: NF.sora(13, color: NF.muted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: orangeButton().copyWith(minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56))),
                  onPressed: controller.endLife,
                  child: const Text('Live another life'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
