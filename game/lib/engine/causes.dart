/// The cause system (Legends plan §4): history can only be rewritten when
/// what you did before built up to it.
///
/// Choices add weight to named causes ("science", "patron_milan",
/// "military_engineer") with a note of when and why. A choice that needs
/// causes stays hidden below half its target, shows as a "Long shot" from
/// half, and as "You built for this" at the full target. Nothing is ever
/// certain: odds top out at 85%.
library;

import 'dart:math';

import 'models.dart';

/// How a cause-gated choice shows on the card.
enum CauseTier { hidden, longShot, builtFor }

/// The worst progress (0..) across every need: weight / target.
double causeProgress(Life life, Map<String, num> needs) {
  if (needs.isEmpty) return 1;
  var worst = double.infinity;
  needs.forEach((cause, target) {
    final have = life.causes[cause] ?? 0;
    final p = target <= 0 ? 1.0 : have / target;
    if (p < worst) worst = p;
  });
  return worst;
}

CauseTier causeTier(Life life, Map<String, num> needs) {
  if (needs.isEmpty) return CauseTier.builtFor;
  final p = causeProgress(life, needs);
  if (p < 0.5) return CauseTier.hidden;
  if (p < 1) return CauseTier.longShot;
  return CauseTier.builtFor;
}

/// Chance a cause-gated choice succeeds: 0 when hidden, 10–35% as a long
/// shot, 55–85% when built for (never 100%).
double causeOdds(Life life, Map<String, num> needs) {
  if (needs.isEmpty) return 1;
  final p = causeProgress(life, needs);
  if (p < 0.5) return 0;
  if (p < 1) return 0.10 + (p - 0.5) / 0.5 * 0.25;
  return min(0.85, 0.55 + (p - 1) * 0.30);
}

/// The tag shown on the choice button.
String? causeTag(Life life, Map<String, num> needs) =>
    switch (causeTier(life, needs)) {
      CauseTier.hidden => null,
      CauseTier.longShot => 'Long shot',
      CauseTier.builtFor => 'You built for this',
    };

/// Adds cause weight and remembers why ("1478: studied the drum").
void addCause(Life life, String cause, num amount, String why) {
  if (amount == 0) return;
  life.causes[cause] = (life.causes[cause] ?? 0) + amount.toDouble();
  life.causeLog.add({
    'cause': cause,
    'amount': amount,
    'year': life.year,
    'age': life.age,
    'why': why,
  });
}

/// "Because you studied anatomy in 1489 and wrote to Ludovico in 1482."
/// Names the biggest past contributions to [needs], at most two.
String? becauseLine(Life life, Map<String, num> needs) {
  final hits = [
    for (final e in life.causeLog)
      if (needs.containsKey(e['cause']) && (e['amount'] as num) > 0) e,
  ]..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
  if (hits.isEmpty) return null;
  final parts = [
    for (final e in hits.take(2)) '${e['why']} in ${e['year']}',
  ];
  return 'Because you ${parts.join(' and ')}.';
}

/// Rolls a cause-gated choice. Deterministic per life, year and choice.
bool rollCause(Life life, Map<String, num> needs, String key) {
  final odds = causeOdds(life, needs);
  if (odds >= 1) return true;
  if (odds <= 0) return false;
  final rng = Random(life.seed * 131 + life.year * 17 + key.hashCode);
  return rng.nextDouble() < odds;
}
