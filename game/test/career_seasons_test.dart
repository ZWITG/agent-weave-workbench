import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/career_hub.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/kin.dart' show seasonClock;
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/music.dart' show listenersOf;
import 'package:relivable/engine/policing.dart' show casesClosed, dirtyFile;
import 'package:relivable/engine/storylet.dart';

// Each career's four season tabs are a once-a-year choice between options
// of its own, and each career has a signature mechanic those options move
// (career_seasons.dart).
List<Storylet> _storylets() => [
  for (final file in storyletFiles)
    ...(jsonDecode(File('assets/storylets/$file').readAsStringSync()) as List)
        .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
];

void main() {
  seasonClock = () => DateTime(2026, 8, 1);
  final engine = GameEngine(_storylets());

  Life start(String id, int seed) {
    final l = engine.newLife(seed: seed)..age = 30;
    l.sceneQueue.clear();
    startCareer(l, careerById(id)!);
    l.sceneQueue.clear();
    l.money = 100000;
    return l;
  }

  SeasonOpt opt(Life l, int tab, String id) =>
      hubTabs(l)![tab].opts.firstWhere((o) => o.id == id);

  /// Picks until it wins (odds never reach 100), up to [tries] times.
  void pickTillWin(Life l, int tab, String id, {int tries = 12, int seed = 1}) {
    final o = opt(l, tab, id);
    for (var i = 0; i < tries; i++) {
      final before = Map<String, dynamic>.of(l.hub);
      hubSeasonPick(l, Random(seed + i), tab, o, score: 1);
      if (l.hub.toString() != before.toString()) return;
    }
  }

  test('all 14 careers have four tabs of their own options', () {
    expect(hubSpecs.length, 14);
    for (final id in hubSpecs.keys) {
      final l = start(id, 1000 + id.hashCode % 100);
      final tabs = hubTabs(l);
      expect(tabs, isNotNull, reason: id);
      expect(tabs!.length, 4, reason: id);
      final seen = <String>{};
      for (var i = 0; i < 4; i++) {
        expect(hubSeasonHint(l, i), isNotEmpty, reason: '$id tab $i');
        expect(tabs[i].opts, isNotEmpty, reason: '$id tab $i');
        for (final o in tabs[i].opts) {
          expect(o.win, isNotEmpty, reason: '$id ${o.id}');
          seen.add('$i:${o.id}');
        }
      }
      expect(seen.length, tabs.fold(0, (n, t) => n + t.opts.length));
    }
  });

  test('every option runs, moves something and says what happened', () {
    for (final id in hubSpecs.keys) {
      final tabs = hubTabs(start(id, 1))!;
      for (var t = 0; t < 4; t++) {
        for (final o in tabs[t].opts) {
          for (final score in [null, 0.0, 1.0]) {
            final l = start(id, 77);
            // Give the options that need one something to work with.
            l.hub['setlist'] = [
              {'t': 'Neon Rain', 'mood': 'anthem', 'q': 3},
            ];
            l.hub['countdown'] = 0;
            final r = hubSeasonPick(l, Random(t * 31 + 5), t, o, score: score);
            expect(r.text, isNotEmpty, reason: '$id ${o.id}');
            expect(hubSeasonChosen(l), t, reason: '$id ${o.id}');
            expect(hubSeasonPicked(l), o.id, reason: '$id ${o.id}');
            expect(seasonChips(l, o, t), isA<List<(String, int)>>());
            // The hub page still reads its own details and meter after it.
            expect(() => hubFor(l)!.details?.call(l), returnsNormally);
            expect(hubMeter(l), inInclusiveRange(0, 100));
          }
        }
      }
    }
  });

  test('once a year: the other tabs lock until a birthday', () {
    final l = start('military', 901);
    final a = hubSeasonAction(l, 0, opt(l, 0, 'assault'));
    expect(a.lockReason(l), isNull);
    engine.runAction(l, a);
    expect(hubSeasonChosen(l), 0);
    expect(
      hubSeasonAction(l, 3, opt(l, 3, 'home')).lockReason(l),
      contains('Training'),
    );
    l.age++;
    expect(hubSeasonAction(l, 3, opt(l, 3, 'home')).lockReason(l), isNull);
  });

  test('in season counts for more', () {
    int gain(int beat) {
      final l = start('military', 902);
      l.hub['meter'] = 21;
      l.hub['beat'] = beat;
      pickTillWin(l, 2, 'peace');
      return hubMeter(l) - 21;
    }

    expect(gain(2), greaterThan(gain(0)));
  });

  test('locks: officer school, a song to record, a crew to launch, money', () {
    final m = start('military', 3);
    expect(seasonOptLock(m, opt(m, 0, 'officer')), isNotNull);
    final mu = start('musician', 3);
    expect(seasonOptLock(mu, opt(mu, 1, 'indie')), 'Write a song first');
    final a = start('astronaut', 3);
    expect(seasonOptLock(a, opt(a, 2, 'go')), contains('T−3'));
    a.hub['countdown'] = 0;
    expect(seasonOptLock(a, opt(a, 2, 'go')), isNull);
  });

  test('armed forces: boot prints fill, Leave clears them, and the family '
      'misses you on deployment', () {
    final l = start('military', 4);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'assault'), score: 1);
    hubSeasonPick(l, Random(2), 1, opt(l, 1, 'ridge'));
    expect(fieldFatigue(l), 2);
    hubSeasonPick(l, Random(3), 3, opt(l, 3, 'home'));
    expect(fieldFatigue(l), lessThan(2));
    final r = hubSeasonPick(l, Random(4), 2, opt(l, 2, 'peace'));
    expect(r.notes.join(), contains('letter from home'));
  });

  test('athlete: brutal blocks build fatigue; matches fill the results', () {
    final l = start('athlete', 5);
    for (var i = 0; i < 4; i++) {
      hubSeasonPick(l, Random(i), 0, opt(l, 0, 'brutal'));
    }
    expect(athleteFatigue(l), greaterThanOrEqualTo(60));
    hubSeasonPick(l, Random(9), 1, opt(l, 1, 'play'));
    expect(athleteResults(l).length, 3);
    expect(athleteResults(l).every((r) => 'WDL'.contains(r)), isTrue);
  });

  test('musician: writing adds a rated song; the setlist sways the odds', () {
    final l = start('musician', 6);
    l.music['fans'] = 1000;
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'anthem'), score: 1);
    expect(setlist(l).single['mood'], 'anthem');
    expect(setlist(l).single['q'], 5);
    expect(listenersOf(l), greaterThanOrEqualTo(1000));
    final weak = start('musician', 6)
      ..hub['setlist'] = [
        {'t': 'X', 'mood': 'love', 'q': 1},
      ];
    final strong = start('musician', 6)
      ..hub['setlist'] = [
        {'t': 'X', 'mood': 'love', 'q': 5},
      ];
    final tour = opt(weak, 3, 'europe');
    expect(seasonChips(strong, tour, 3).first, isNotNull);
    var wWins = 0, sWins = 0;
    for (var i = 0; i < 200; i++) {
      final w = start('musician', 6)..hub['setlist'] = weak.hub['setlist'];
      final s = start('musician', 6)..hub['setlist'] = strong.hub['setlist'];
      if (hubSeasonPick(w, Random(i), 3, tour).text == tour.win) wWins++;
      if (hubSeasonPick(s, Random(i), 3, tour).text == tour.win) sWins++;
    }
    expect(sWins, greaterThan(wWins));
  });

  test('actor: three roles in a genre and you are typecast', () {
    final l = start('actor', 7);
    l.hub['meter'] = 100;
    for (var n = 0; n < 3; n++) {
      final before = actorGenres(l)['Drama']!;
      for (var i = 0; i < 12 && actorGenres(l)['Drama'] == before; i++) {
        hubSeasonPick(l, Random(n * 50 + i), 0, opt(l, 0, 'drama'), score: 1);
      }
    }
    expect(typecast(l), 'Drama');
    expect(
      seasonChips(l, opt(l, 0, 'drama'), 0).map((c) => c.$1),
      contains('Your type'),
    );
    expect(
      seasonChips(l, opt(l, 0, 'comedy'), 0).map((c) => c.$1),
      contains('Off-type'),
    );
  });

  test('politician: party votes tip the scale to the whip', () {
    final l = start('politician', 8);
    expect(whipBalance(l), 50);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'party'));
    expect(whipBalance(l), greaterThan(50));
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'conscience'));
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'conscience'));
    expect(whipBalance(l), lessThan(50));
  });

  test('police: shortcuts mark your file; good work closes cases', () {
    final l = start('police', 9);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'blind'));
    expect(dirtyFile(l), greaterThan(0));
    var closed = false;
    for (var s = 0; s < 20 && !closed; s++) {
      final p = start('police', 960 + s);
      p.marks.add('cop_closed:5');
      hubSeasonPick(p, Random(s), 1, opt(p, 1, 'board'), score: 1);
      closed = casesClosed(p) == 6;
    }
    expect(closed, isTrue);
  });

  test('model: the image dial swings with the work you take', () {
    final l = start('model', 10);
    hubSeasonPick(l, Random(1), 2, opt(l, 2, 'vex'));
    expect(modelImage(l), greaterThan(0));
    final w = start('model', 10);
    hubSeasonPick(w, Random(1), 0, opt(w, 0, 'commercial'));
    expect(modelImage(w), lessThanOrEqualTo(0));
  });

  test('doctor: long wards burn you out and a holiday heals it', () {
    final l = start('doctor', 11);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'ae'));
    hubSeasonPick(l, Random(2), 2, opt(l, 2, 'trial'));
    final hot = burnout(l);
    expect(hot, greaterThan(0));
    hubSeasonPick(l, Random(3), 3, opt(l, 3, 'holiday'));
    expect(burnout(l), lessThan(hot));
  });

  test('lawyer: trials go on the record; crooks cost ethics', () {
    final l = start('lawyer', 12);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'crook'));
    expect(lawRecord(l).$3, lessThan(50));
    hubSeasonPick(l, Random(2), 1, opt(l, 1, 'cross'));
    final (won, lost, _) = lawRecord(l);
    expect(won + lost, 1);
  });

  test('vet: the farms you reach at harvest trust you more', () {
    final l = start('vet', 13);
    hubSeasonPick(l, Random(1), 2, opt(l, 2, 'ha'));
    expect(farmTrust(l), [3, 3, 1, 1]);
  });

  test('pilot: new airports stamp the logbook; a full page pays', () {
    final l = start('pilot', 14);
    pickTillWin(l, 0, 'long');
    expect(logbook(l), hasLength(1));
    l.hub['stamps'] = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final money = l.money;
    pickTillWin(l, 0, 'long', seed: 40);
    expect(logbook(l), isEmpty);
    expect(l.money, greaterThanOrEqualTo(money + 5000));
  });

  test('hustler: your corner sticks; the busy one draws the police', () {
    final l = start('hustler', 15);
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'arches'));
    expect(hustlerCorner(l), 'arches');
    var moved = 0;
    for (var i = 0; i < 60; i++) {
      final h = start('hustler', 15);
      final r = hubSeasonPick(h, Random(i), 0, opt(h, 0, 'square'));
      if (r.notes.any((n) => n.startsWith('Moved on'))) moved++;
    }
    expect(moved, greaterThan(5));
  });

  test('astronaut: training counts down to a crew, launching resets it', () {
    final l = start('astronaut', 16);
    expect(astroCountdown(l), 3);
    pickTillWin(l, 0, 'centrifuge');
    expect(astroCountdown(l), 2);
    l.hub['countdown'] = 0;
    hubSeasonPick(l, Random(1), 2, opt(l, 2, 'go'), score: 1);
    expect(astroCountdown(l), 3);
  });

  test('fighter: reading the opponent beats guessing', () {
    var right = 0, wrong = 0;
    const beats = {
      'strike': 'grapple',
      'grapple': 'defend',
      'defend': 'strike',
    };
    for (var i = 0; i < 150; i++) {
      final l = start('fighter', 17);
      final foe = fighterFoe(l).$3;
      final win = beats.entries.firstWhere((e) => e.value == foe).key;
      final lose = beats[foe]!;
      final a = start('fighter', 17), b = start('fighter', 17);
      if (hubSeasonPick(a, Random(i), 2, opt(a, 2, win)).text ==
          opt(a, 2, win).win) {
        right++;
      }
      if (hubSeasonPick(b, Random(i), 2, opt(b, 2, lose)).text ==
          opt(b, 2, lose).win) {
        wrong++;
      }
    }
    expect(right, greaterThan(wrong));
    final l = start('fighter', 18);
    hubSeasonPick(l, Random(1), 2, opt(l, 2, 'strike'));
    expect(fightDamage(l), greaterThan(0));
  });

  test('a focus year is not a quiet year', () {
    final l = start('military', 904);
    l.hub['meter'] = 30;
    hubSeasonPick(l, Random(1), 0, opt(l, 0, 'assault'), score: 1);
    final after = hubMeter(l);
    hubYear(l, Random(2));
    expect(hubMeter(l), greaterThanOrEqualTo(after));
  });

  test('the choice runs as an activity with its mini-game', () {
    final l = start('athlete', 19);
    final a = hubSeasonAction(l, 2, opt(l, 2, 'shot'));
    expect(a.miniGame, isNotNull);
    expect(a.scored, isNotNull);
    final r = engine.runAction(l, a);
    expect(r.text, isNotEmpty);
    expect(hubSeasonChosen(l), 2);
  });
}
