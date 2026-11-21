import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/career_hub.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/kin.dart' show seasonClock;
import 'package:relivable/engine/music.dart' show listenersOf;
import 'package:relivable/engine/policing.dart' show casesClosed;
import 'package:relivable/engine/storylet.dart';

// The season tabs on every Career Hub are a once-a-year choice that moves
// the career's meter, stats and promotion.
List<Storylet> _storylets() => [
  for (final file in storyletFiles)
    ...(jsonDecode(File('assets/storylets/$file').readAsStringSync()) as List)
        .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
];

void main() {
  seasonClock = () => DateTime(2026, 8, 1);
  final engine = GameEngine(_storylets());

  dynamic start(String id, int seed) {
    final l = engine.newLife(seed: seed)..age = 30;
    l.sceneQueue.clear();
    startCareer(l, careerById(id)!);
    l.sceneQueue.clear();
    return l;
  }

  test('every Hub career has a move behind each of its four tabs', () {
    for (final id in hubSpecs.keys) {
      final l = start(id, 1000 + id.hashCode % 100);
      expect(hubFor(l), isNotNull, reason: id);
      for (var i = 0; i < 4; i++) {
        expect(hubSeasonHint(l, i), isNotEmpty, reason: '$id tab $i');
        expect(hubSeasonAction(l, i).lockReason(l), isNull, reason: id);
      }
    }
  });

  test('armed forces: Training builds Readiness, once a year', () {
    final l = start('military', 901);
    l.hub['meter'] = 21;
    l.hub['beat'] = 1; // Exercises is in season
    final r = engine.runAction(l, hubSeasonAction(l, 0));
    expect(hubMeter(l), 26);
    expect(r.notes, contains('Readiness +5'));
    expect(hubSeasonChosen(l), 0);
    // The other tabs are locked until next year.
    expect(hubSeasonAction(l, 3).lockReason(l), contains('Training'));
  });

  test('in season counts for more', () {
    final l = start('military', 902);
    l.hub['meter'] = 21;
    l.hub['beat'] = 0; // Training is in season
    final r = hubSeason(l, Random(1), 0);
    expect(hubMeter(l), 29);
    expect(r.notes, contains('In season'));
  });

  test('Leave: happiness and health back, Readiness slips', () {
    final l = start('military', 903);
    l.hub['meter'] = 50;
    l.stats.values['happiness'] = 40;
    l.stats.values['health'] = 40;
    hubSeason(l, Random(1), 3);
    expect(hubMeter(l), 46);
    expect(l.stats['happiness'], 46);
    expect(l.stats['health'], 43);
  });

  test('Deployment: a win jumps Readiness, pays and lifts performance', () {
    var wins = 0, losses = 0;
    for (var s = 0; s < 40; s++) {
      final l = start('military', 950 + s);
      l.hub['meter'] = 60;
      l.hub['beat'] = 0;
      l.performance = 50;
      final money = l.money;
      hubSeason(l, Random(s), 2);
      if (hubMeter(l) > 60) {
        wins++;
        expect(hubMeter(l), 72);
        expect(l.performance, 58);
        expect(l.money, greaterThan(money));
        expect(medals(l), greaterThanOrEqualTo(1));
      } else {
        losses++;
        expect(hubMeter(l), 55);
      }
    }
    expect(wins, greaterThan(0));
    expect(losses, greaterThan(0));
  });

  test('a focus year is not a quiet year', () {
    final l = start('military', 904);
    l.hub['meter'] = 30;
    hubSeason(l, Random(1), 0);
    final after = hubMeter(l);
    hubYear(l, Random(2));
    expect(hubMeter(l), greaterThanOrEqualTo(after));
  });

  test('musicians grow listeners; police close cases', () {
    final m = start('musician', 905);
    m.music['fans'] = 1000;
    hubSeason(m, Random(1), 0);
    expect(listenersOf(m), greaterThan(1000));
    var closed = false;
    for (var s = 0; s < 20 && !closed; s++) {
      final p = start('police', 960 + s);
      p.marks.add('cop_closed:5');
      hubSeason(p, Random(s), 2);
      closed = casesClosed(p) == 6;
    }
    expect(closed, isTrue);
  });
}
