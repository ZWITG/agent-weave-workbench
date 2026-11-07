import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'widgets.dart';

const _good = Color(0xFF5EE6A8);

Color toneColor(String tone) => switch (tone) {
  'good' => _good,
  'bad' => NF.danger,
  'mixed' => NF.orange,
  _ => NF.blue,
};

IconData _toneIcon(String tone) => switch (tone) {
  'good' => Icons.celebration_rounded,
  'bad' => Icons.sentiment_dissatisfied_rounded,
  'mixed' => Icons.balance_rounded,
  _ => Icons.auto_awesome_rounded,
};

/// The result of an event: a reaction headline, the story outcome, animated
/// stat / bond / money changes and what the world will remember.
class OutcomeCard extends StatelessWidget {
  const OutcomeCard({
    super.key,
    required this.controller,
    required this.outcome,
  });
  final GameController controller;
  final Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(outcome.tone);
    final chips = <(String, int, Color)>[
      for (final e in outcome.statDeltas.entries)
        (statLabel(e.key), e.value, statStyle[e.key]!.$1),
      for (final e in outcome.bondDeltas.entries)
        ('Bond · ${e.key}', e.value, NF.orange),
      if (outcome.moneyDelta != 0) ('Money', outcome.moneyDelta, _good),
    ];
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.20), NF.surface],
          ),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: motion(context, const Duration(milliseconds: 500)),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _toneIcon(outcome.tone),
                      color: color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    outcome.headline,
                    style: NF.sora(20, weight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(outcome.text, style: NF.sora(16, height: 1.5)),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < chips.length; i++)
                    _DeltaChip(
                      label: chips[i].$1,
                      delta: chips[i].$2,
                      color: chips[i].$3,
                      index: i,
                      money: chips[i].$1 == 'Money',
                    ),
                ],
              ),
            ],
            if (outcome.echoes.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final e in outcome.echoes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: NF.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e, style: NF.sora(13, color: NF.soft)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: primaryButton(),
                onPressed: controller.dismissOutcome,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.label,
    required this.delta,
    required this.color,
    required this.index,
    this.money = false,
  });
  final String label;
  final int delta;
  final Color color;
  final int index;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final valueText = money
        ? '${up ? '+' : ''}${moneyText(delta)}'
        : '${up ? '+' : '−'}${delta.abs()}';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, Duration(milliseconds: 350 + index * 140)),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: child,
        ),
      ),
      child: Semantics(
        label: '$label ${up ? 'up' : 'down'} ${delta.abs()}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (up ? color : NF.danger).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (up ? color : NF.danger).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: up ? color : NF.danger,
              ),
              const SizedBox(width: 4),
              Text(
                '$label $valueText',
                style: NF.sora(
                  13,
                  weight: FontWeight.w700,
                  color: up ? color : NF.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String statLabel(String k) => k[0].toUpperCase() + k.substring(1);

/// "$1,500" (sign handled by the caller).
String moneyText(int v) => money(v.abs());
