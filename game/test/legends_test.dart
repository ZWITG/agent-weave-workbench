import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/causes.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/timeline.dart';

import 'timeline_fixtures.dart';

Life _blank() => Life(
  seed: 1,
  firstName: 'Test',
  surname: 'Case',
  gender: 'male',
  country: 'United States',
  city: 'Boston',
  birthYear: 2000,
  stats: Stats({}),
  npcs: [],
);

void main() {
  group('Storylet fields', () {
    test('every existing storylet parses as before, untagged', () {
      final all = modernStorylets();
      expect(all, isNotEmpty);
      for (final s in all) {
        expect(s.timeline, isFalse, reason: s.id);
        expect(s.pivot, isNull);
        expect(s.year, isNull);
        for (final c in s.choices) {
          expect(c.gated, isFalse);
          expect(c.adds, isEmpty);
          expect(c.rewrites, isNull);
        }
      }
    });

    test('new optional fields are read', () {
      final s = Storylet.fromJson({
        'id': 'x',
        'era': 'renaissance',
        'legend': 'leo',
        'yearRange': [1470, 1480],
        'pivot': true,
        'text': 't',
        'choices': [
          {
            'label': 'a',
            'canon': true,
            'causes': {'military': 60},
            'adds': {'science': 5},
            'why': 'did a',
            'rewrites': 'fact_a',
            'chronicle': 20,
            'failOutcome': 'no',
            'failEffects': {'stats': {'happiness': -3}},
            'codex': 'card',
          },
        ],
      });
      expect(s.era, 'renaissance');
      expect(s.legend, 'leo');
      expect(s.yearFrom, 1470);
      expect(s.yearTo, 1480);
      expect(s.pivot, 'x');
      final c = s.choices.single;
      expect(c.canon, isTrue);
      expect(c.causes, {'military': 60});
      expect(c.adds, {'science': 5});
      expect(c.rewrites, 'fact_a');
      expect(c.chronicle, 20);
      expect(c.failEffects!.stats, {'happiness': -3});
      expect(c.codex, 'card');
    });

    test('timeline storylets never reach a modern life, and back', () {
      loadTimelineContent();
      final modern = _blank()..age = 30;
      for (final s in timelineStorylets()) {
        expect(s.isEligible(modern), isFalse, reason: s.id);
      }
      final old = _blank()
        ..era = 'renaissance'
        ..age = 30;
      for (final s in modernStorylets()) {
        expect(s.isEligible(old), isFalse, reason: s.id);
      }
    });
  });

  group('Causes', () {
    test('hidden below half, long shot from half, built for at full', () {
      final l = _blank();
      const need = {'military': 60};
      expect(causeTier(l, need), CauseTier.hidden);
      expect(causeOdds(l, need), 0);
      addCause(l, 'military', 29, 'drew a crossbow');
      expect(causeTier(l, need), CauseTier.hidden);
      addCause(l, 'military', 1, 'drew a cart');
      expect(causeTier(l, need), CauseTier.longShot);
      expect(causeOdds(l, need), closeTo(0.10, 1e-9));
      addCause(l, 'military', 29, 'drew a bridge');
      expect(causeOdds(l, need), inInclusiveRange(0.10, 0.35));
      addCause(l, 'military', 1, 'built a model');
      expect(causeTier(l, need), CauseTier.builtFor);
      expect(causeOdds(l, need), closeTo(0.55, 1e-9));
      addCause(l, 'military', 500, 'lived for war');
      expect(causeOdds(l, need), 0.85);
      expect(causeTag(l, need), 'You built for this');
    });

    test('the weakest of several causes decides', () {
      final l = _blank();
      addCause(l, 'a', 100, 'x');
      addCause(l, 'b', 10, 'y');
      expect(causeTier(l, {'a': 50, 'b': 50}), CauseTier.hidden);
    });

    test('a because line names the biggest reasons with their year', () {
      final l = _blank()..age = 26;
      addCause(l, 'military', 10, 'studied the Bargello guns');
      addCause(l, 'military', 15, 'filled notebooks with siege engines');
      addCause(l, 'arts', 40, 'painted an angel');
      expect(
        becauseLine(l, {'military': 60}),
        'Because you filled notebooks with siege engines in 2026 and '
        'studied the Bargello guns in 2026.',
      );
    });

    test('odds hold over many rolls', () {
      var wins = 0;
      for (var i = 0; i < 2000; i++) {
        final l = _blank()..age = i % 90;
        final x = Life.fromJson(l.toJson()..['seed'] = i);
        addCause(x, 'm', 60, 'x');
        if (rollCause(x, {'m': 60}, 'k')) wins++;
      }
      expect(wins / 2000, closeTo(0.55, 0.05));
    });
  });

  group('Legend runner', () {
    test('turning points fire in their year and the Chronicle follows', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      final t = newTimeline('renaissance', 1450, legend: leo.id);
      e.timeline = t;
      final life = startLegend(leo, t, seed: 3);
      final seen = <String, int>{};
      playOut(e, life, (s, shown) {
        if (s.pivot != null) seen[s.pivot!] = life.year;
        final canon = shown.indexWhere((c) => c.canon);
        return canon < 0 ? 0 : canon;
      });
      expect(seen, {'drum_1476': 1476, 'letter_1482': 1482});
      expect(life.pivots, {'drum_1476': 'canon', 'letter_1482': 'canon'});
      expect(life.chronicle, 100);
      expect(life.codex, containsAll(['drum_1476', 'letter_1482']));
      expect(life.alive, isFalse);
      expect(life.fate, 'as_history_records');
      expect(t.facts, isEmpty);
      expect(t.year, life.year);
    });

    test('building the cause makes the rewrite visible and writes a fact', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      var rewrote = 0, shownRewrite = 0;
      for (var seed = 0; seed < 200; seed++) {
        final t = newTimeline('renaissance', 1450, legend: leo.id, seed: seed);
        e.timeline = t;
        final life = startLegend(leo, t, seed: seed);
        playOut(e, life, (s, shown) {
          final rw = shown.indexWhere((c) => c.rewrites == 'leo_engineer_milan');
          if (rw >= 0) {
            shownRewrite++;
            return rw;
          }
          final war = shown.indexWhere((c) => (c.adds['military'] ?? 0) > 0);
          return war < 0 ? 0 : war;
        });
        if (t.has('leo_engineer_milan')) {
          rewrote++;
          expect(life.flags.containsKey('fact:leo_engineer_milan'), isTrue);
          expect(life.pivots['letter_1482'], 'rewritten');
          expect(life.fate, 'engineer_of_milan');
          expect(life.chronicle, lessThan(100));
        }
      }
      expect(shownRewrite, greaterThan(150));
      // Mostly built for (55-85%), sometimes a long shot: never certain.
      expect(rewrote, inInclusiveRange(60, 140));
    });

    test('without the cause the rewrite never shows', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      for (var seed = 0; seed < 20; seed++) {
        final t = newTimeline('renaissance', 1450, legend: leo.id, seed: seed);
        e.timeline = t;
        final life = startLegend(leo, t, seed: seed);
        playOut(e, life, (s, shown) {
          expect(shown.any((c) => c.rewrites == 'leo_engineer_milan'), isFalse);
          final art = shown.indexWhere(
            (c) => (c.adds['military'] ?? 0) == 0 && c.rewrites == null,
          );
          return art < 0 ? 0 : art;
        });
        expect(t.has('leo_engineer_milan'), isFalse);
      }
    });

    test('every Fate can be reached', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      final reached = <String>{};
      final strategies = <int Function(Storylet, List<Choice>)>[
        (s, shown) => shown.indexWhere((c) => c.canon).clamp(0, 9),
        (s, shown) {
          final rw = shown.indexWhere((c) => c.rewrites != null);
          if (rw >= 0) return rw;
          final w = shown.indexWhere((c) => (c.adds['military'] ?? 0) > 0);
          return w < 0 ? 0 : w;
        },
        (s, shown) => shown.length - 1,
        (s, shown) {
          if (s.pivot != null) {
            final o = shown.indexWhere((c) => !c.canon && c.rewrites == null);
            return o < 0 ? 0 : o;
          }
          return 0;
        },
      ];
      for (var seed = 0; seed < 40; seed++) {
        for (final pick in strategies) {
          final t = newTimeline('renaissance', 1450, legend: leo.id, seed: seed);
          e.timeline = t;
          final life = startLegend(leo, t, seed: seed);
          playOut(e, life, pick);
          if (life.fate != null) reached.add(life.fate!);
        }
      }
      expect(reached, {for (final f in leo.fates) f.id});
    });

    test('historical people die when history says', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      final t = newTimeline('renaissance', 1450, legend: leo.id);
      e.timeline = t;
      final life = startLegend(leo, t, seed: 11);
      while (life.year < 1466 && life.alive) {
        final s = e.ageUp(life);
        if (s != null) e.choose(life, s, visibleChoices(life, s).first);
      }
      expect(life.npc('grandfather')!.alive, isFalse);
      expect(life.npc('father')!.alive, isTrue);
    });
  });

  group('Saves', () {
    test('old saves load with empty Legend fields', () {
      final old = _blank().toJson();
      for (final k in [
        'legendId',
        'timelineId',
        'era',
        'causes',
        'causeLog',
        'chronicle',
        'pivots',
        'codex',
        'fate',
      ]) {
        expect(old.containsKey(k), isFalse, reason: k);
      }
      final l = Life.fromJson(old);
      expect(l.legendId, isNull);
      expect(l.era, isNull);
      expect(l.causes, isEmpty);
      expect(l.chronicle, 100);
      expect(l.codex, isEmpty);
    });

    test('Legend fields round-trip', () {
      final l = _blank()
        ..legendId = 'leonardo_test'
        ..timelineId = 't1'
        ..era = 'renaissance'
        ..chronicle = 70
        ..fate = 'x';
      addCause(l, 'military', 12, 'drew');
      l.pivots['drum_1476'] = 'other:30';
      l.codex.add('drum_1476');
      final back = Life.fromJson(l.toJson());
      expect(back.legendId, 'leonardo_test');
      expect(back.timelineId, 't1');
      expect(back.era, 'renaissance');
      expect(back.causes, {'military': 12.0});
      expect(back.causeLog.single['why'], 'drew');
      expect(back.chronicle, 70);
      expect(back.pivots, {'drum_1476': 'other:30'});
      expect(back.codex, {'drum_1476'});
      expect(back.fate, 'x');
    });

    test('a timeline round-trips', () {
      final t = Timeline(id: 'a', era: 'renaissance', startYear: 1450, seed: 4)
        ..write('milan_holds_1499', 1499, 'Milan held')
        ..addCurrent('Science', 12);
      final b = Timeline.fromJson(t.toJson());
      expect(b.facts, {'milan_holds_1499': 1499});
      expect(b.currents, {'Science': 12});
      expect(b.log.single, '1499: Milan held');
    });
  });
}
