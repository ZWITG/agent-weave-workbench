import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/world.dart';

import 'timeline_fixtures.dart';

/// Words that would give away a modern item in the feed.
RegExp anachronismsOf(EraRules era) => RegExp(
  '\\b(${era.anachronisms.where((w) => w != r'\$').join('|')})\\b|\\\$',
  caseSensitive: false,
);

void checkLife(Life life, EraRules era, RegExp bad, String tag) {
  for (final f in life.feed) {
    expect(bad.hasMatch(f.text), isFalse, reason: '$tag: "${f.text}"');
  }
  // Nothing modern: no assets, cars, homes, shares or businesses.
  expect(life.assets.where((a) => !a.id.startsWith('past_')), isEmpty, reason: tag);
  expect(life.shares, isEmpty, reason: tag);
  expect(life.businesses, isEmpty, reason: tag);
  expect(life.year, lessThanOrEqualTo(era.from + 140), reason: tag);
  expect(life.alive, isFalse, reason: '$tag never ended');
}

void main() {
  test('200 test-Legend lives: no crash, no anachronisms, a Fate each', () {
    final world = World(seed: 21);
    final e = timelineEngine(world: world);
    final before = jsonEncode(world.toJson());
    final era = eraRegistry['renaissance']!;
    final leo = legendRegistry['leonardo']!;
    final bad = anachronismsOf(era);
    final fates = <String, int>{};
    for (var seed = 0; seed < 200; seed++) {
      final t = newTimeline('renaissance', 1450, legend: leo.id, seed: seed);
      e.timeline = t;
      final life = startLegend(leo, t, seed: seed);
      final rng = Random(seed);
      playOut(e, life, (s, shown) => rng.nextInt(shown.length));
      checkLife(life, era, bad, 'legend $seed');
      expect(life.fate, isNotNull);
      expect(life.chronicle, inInclusiveRange(0, 100));
      if (life.pivots.length < 2) {
        expect(life.fate, 'cut_short');
        expect(life.year, lessThan(1483));
      } else {
        expect(life.fate, isNot('cut_short'));
      }
      fates[life.fate!] = (fates[life.fate!] ?? 0) + 1;
      // Saves round-trip mid-history.
      final back = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
      expect(back.pivots, life.pivots);
      expect(back.fate, life.fate);
    }
    expect(fates.length, greaterThanOrEqualTo(3), reason: '$fates');
    expect(jsonEncode(world.toJson()), before, reason: 'modern world changed');
  });

  test('50 ordinary 1450 lives: no crash, no anachronisms', () {
    final world = World(seed: 22);
    final e = timelineEngine(world: world);
    final before = jsonEncode(world.toJson());
    final era = eraRegistry['renaissance']!;
    final bad = anachronismsOf(era);
    for (var seed = 0; seed < 50; seed++) {
      final t = newTimeline('renaissance', 1450, seed: 1000 + seed);
      e.timeline = t;
      final life = startTimelineLife(era, t, seed: seed, year: 1450);
      final rng = Random(seed);
      playOut(e, life, (s, shown) => rng.nextInt(shown.length));
      checkLife(life, era, bad, 'ordinary $seed');
      expect(life.legendId, isNull);
      expect(life.fate, isNull);
      expect(era.regions.first.cities, contains(life.city));
    }
    expect(jsonEncode(world.toJson()), before, reason: 'modern world changed');
  });
}
