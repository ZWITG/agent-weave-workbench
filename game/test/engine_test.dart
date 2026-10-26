import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/storylet.dart';

List<Storylet> loadStorylets() {
  final raw = File('assets/storylets/core.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Plays a whole life (birth to the slice end) choosing at random.
Life simulate(GameEngine engine, int seed, Map<String, int> fired) {
  final rng = Random(seed);
  final life = engine.newLife(seed: seed);
  while (life.alive && life.age < sliceEndAge) {
    final event = engine.ageUp(life);
    if (event != null) {
      fired[event.id] = (fired[event.id] ?? 0) + 1;
      engine.choose(life, event, event.choices[rng.nextInt(event.choices.length)]);
    }
    final open = engine.actions.where((a) => a.lockReason(life) == null).toList();
    if (open.isNotEmpty && rng.nextBool()) {
      engine.runAction(life, open[rng.nextInt(open.length)]);
    }
  }
  return life;
}

void main() {
  final storylets = loadStorylets();
  final engine = GameEngine(storylets);

  test('storylet ids are unique and every choice has a label', () {
    final ids = storylets.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final s in storylets) {
      expect(s.choices, isNotEmpty, reason: s.id);
      expect(s.minAge <= s.maxAge, isTrue, reason: s.id);
    }
  });

  test('flags required by a storylet are set by some choice (no dead events)', () {
    final settable = <String>{'caught_shoplifting', 'owns_car'}; // set by actions
    for (final s in storylets) {
      for (final c in s.choices) {
        settable.addAll(c.effects.setFlags.keys);
      }
    }
    for (final s in storylets) {
      for (final f in [...s.requiresFlags, if (s.remembers != null) s.remembers!]) {
        expect(settable.contains(f), isTrue, reason: '${s.id} needs flag $f that nothing sets');
      }
    }
  });

  test('simulator bot: 500 lives run to the end without errors', () {
    final fired = <String, int>{};
    for (var seed = 1; seed <= 500; seed++) {
      final life = simulate(engine, seed, fired);
      expect(life.age <= sliceEndAge, isTrue);
      for (final k in [...Stats.visible, ...Stats.hidden]) {
        expect(life.stats[k], inInclusiveRange(0, 100));
      }
      for (final n in life.npcs) {
        expect(n.bond, inInclusiveRange(0, 100));
      }
    }
    final never = storylets.where((s) => !fired.containsKey(s.id)).map((s) => s.id).toList();
    expect(never, isEmpty, reason: 'Storylets that never fired in 500 lives: $never');
  });

  test('a remembered choice comes back years later', () {
    // Find a seed where the sibling lawsuit happens, then check the callback.
    for (var seed = 1; seed < 3000; seed++) {
      final life = engine.newLife(seed: seed);
      if (life.npc('sibling') == null) continue;
      while (life.age < sliceEndAge) {
        final e = engine.ageUp(life);
        if (e == null) continue;
        final sue = e.choices.where((c) => c.effects.setFlags.containsKey('sued_sibling'));
        engine.choose(life, e, sue.isNotEmpty ? sue.first : e.choices.first);
        if (e.id == 'sibling_door_baby') {
          expect(life.flags.containsKey('reconciled_sibling'), isTrue);
          return;
        }
      }
    }
    fail('The lawsuit callback never fired');
  });

  test('saves round-trip through JSON', () {
    final life = simulate(engine, 42, {});
    final copy = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
    expect(copy.toJson(), life.toJson());
  });

  test('locked actions explain why', () {
    final baby = engine.newLife(seed: 7);
    final job = engine.actions.firstWhere((a) => a.id == 'apply_job');
    expect(job.lockReason(baby), 'Unlocks at 18');
  });
}
