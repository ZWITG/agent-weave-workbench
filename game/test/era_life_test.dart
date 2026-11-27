import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/era_faith.dart';
import 'package:relivable/engine/era_health.dart';
import 'package:relivable/engine/era_justice.dart';
import 'package:relivable/engine/era_news.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';

import 'timeline_fixtures.dart';

/// Phase 2C: health and plague, the law and prison, faith and the news in
/// an era life.
void main() {
  setUpAll(loadTimelineContent);
  EraRules era() => eraRegistry['renaissance']!;

  test('plague comes in the real plague years, and only there', () {
    final e = era();
    expect(eraPlagueHere(blankEraLife(city: 'Florence', year: 1478), e), isTrue);
    expect(eraPlagueHere(blankEraLife(city: 'Venice', year: 1576), e), isTrue);
    expect(eraPlagueHere(blankEraLife(city: 'London', year: 1603), e), isTrue);
    expect(eraPlagueHere(blankEraLife(city: 'Florence', year: 1480), e), isFalse);
    expect(eraPlagueHere(blankEraLife(city: 'London', year: 1478), e), isFalse);
    expect(eraPlagueHere(blankEraLife(city: 'Timbuktu', year: 1478), e), isFalse);
  });

  test('healers belong to their place; no modern medicine anywhere', () {
    final e = era();
    List<String> ids(String city, int y) => [
      for (final h in eraHealers(blankEraLife(city: city, year: y), e)) h.id,
    ];
    expect(ids('Florence', 1478), containsAll(['barber', 'physician', 'hospital']));
    expect(ids('Mbanza Kongo', 1520), ['nganga']);
    expect(ids('Cairo', 1500), contains('hospital'));
    expect(ids('Milan', 1450), isNot(contains('hospital')));
    expect(ids('Milan', 1460), contains('hospital'));
  });

  test('setting a bone works; bleeding a fever mostly does not', () {
    final e = era();
    var bone = 0, bled = 0;
    for (var i = 0; i < 400; i++) {
      final l = blankEraLife(city: 'Florence', year: 1478)..money = 100;
      l.eraWorld['ill'] = ['bone', 'consumption'];
      final rng = Random(i);
      treatEraAilment(l, e, 'bone', 'barber', rng);
      if (!eraIllnesses(l).contains('bone')) bone++;
      treatEraAilment(l, e, 'consumption', 'barber', rng);
      if (!eraIllnesses(l).contains('consumption')) bled++;
    }
    expect(bone, greaterThan(320));
    expect(bled, lessThan(80));
  });

  test('a crime adds heat, and getting caught means a hearing', () {
    final e = era();
    var caught = 0;
    for (var i = 0; i < 200; i++) {
      final l = blankEraLife(city: 'Florence', year: 1480);
      commitEraCrime(l, e, 'theft', Random(i));
      expect(eraHeat(l), 2);
      if (eraHearingOf(l) != null) {
        caught++;
        expect(l.sceneQueue, contains('era_hearing'));
        final scene = eraHearingScene(l)!;
        expect(scene.text, contains('Otto di Guardia'));
        expect(scene.choices.map((c) => c.label), contains('Take sanctuary in a church'));
      }
    }
    expect(caught, inInclusiveRange(40, 120));
  });

  test('sentences: fines, the Stinche, Newgate, the galleys; never death', () {
    final e = era();
    final rng = Random(3);
    // Theft in Florence: a year in the Stinche.
    final f = blankEraLife(city: 'Florence', year: 1480);
    f.eraWorld['hearing'] = {
      'crime': 'theft',
      'label': 'Steal at the market',
      'sentence': {'kind': 'prison', 'years': 1},
    };
    resolveEraHearing(f, e, 'accept', rng);
    expect(eraInsideOf(f)!['name'], 'the Stinche');
    // Clipping coins in Venice, as a man: the galleys.
    final v = blankEraLife(city: 'Venice', year: 1500);
    v.eraWorld['hearing'] = {
      'crime': 'clip',
      'label': 'Clip silver from coins',
      'sentence': {'kind': 'galleys', 'years': 3, 'orPrison': 2},
    };
    resolveEraHearing(v, e, 'accept', rng);
    expect(eraInsideOf(v)!['kind'], 'galleys');
    // The same in London: prison, not the galleys.
    final ln = blankEraLife(city: 'London', year: 1590);
    ln.eraWorld['hearing'] = Map.of(v.eraWorld['hearing'] ?? {
      'crime': 'clip',
      'label': 'Clip silver from coins',
      'sentence': {'kind': 'galleys', 'years': 3, 'orPrison': 2},
    });
    resolveEraHearing(ln, e, 'accept', rng);
    expect(eraInsideOf(ln)!['name'], 'Newgate');
    // Kongo has no prisons: a fine.
    final k = blankEraLife(city: 'Mbanza Kongo', year: 1520)..money = 500;
    k.eraWorld['hearing'] = {
      'crime': 'theft',
      'label': 'Steal at the market',
      'sentence': {'kind': 'prison', 'years': 1},
    };
    expect(resolveEraHearing(k, e, 'accept', rng), contains('fine'));
    expect(eraInside(k), isFalse);
  });

  test('a hearing can be fled: banished for five years', () {
    final e = era();
    final l = blankEraLife(city: 'Florence', year: 1480);
    l.eraWorld['hearing'] = {
      'crime': 'brawl',
      'label': 'Pick a brawl',
      'sentence': {'kind': 'fine', 'amount': 2},
    };
    resolveEraHearing(l, e, 'flee', Random(1));
    expect(l.city, isNot('Florence'));
    expect((l.eraWorld['banished'] as Map)['city'], 'Florence');
  });

  test('Leonardo: the drum of 1476 goes on his record', () {
    final e = timelineEngine();
    final leo = legendRegistry['leonardo']!;
    final t = newTimeline('renaissance', 1450, legend: leo.id, seed: 3);
    e.timeline = t;
    final life = startLegend(leo, t, seed: 3);
    playOut(e, life, (s, shown) {
      final canon = shown.indexWhere((c) => c.canon);
      return canon < 0 ? 0 : canon;
    });
    expect(eraRecord(life).first, startsWith('1476: named in the drum'));
    expect(eraFaithOf(life), 'catholic');
  });

  test('faith follows the place and year of birth', () {
    final e = era();
    String born(String city, int year, int seed) {
      // Born in [year]: the fixture is thirty in year + 30, so age 0 is [year].
      final l = blankEraLife(city: city, year: year + 30)..age = 0;
      eraFaithAtBirth(l, e, Random(seed));
      return eraFaithOf(l);
    }

    expect(born('London', 1560, 1), 'english');
    expect(born('Florence', 1470, 1), 'catholic');
    expect(born('Mbanza Kongo', 1470, 1), 'kongo');
    expect(born('Mbanza Kongo', 1520, 1), 'kongo_catholic');
    expect(born('Kabasa', 1600, 1), 'mbundu');
    final fez = {for (var s = 0; s < 300; s++) born('Fez', 1500, s)};
    expect(fez, containsAll(['muslim', 'jewish']));
    // England's church changes with the Crown.
    final l = blankEraLife(city: 'London', year: 1555)..eraWorld['faith'] = 'english';
    expect(eraFaithName(l, e), 'Catholic');
    expect(eraFaithName(l..age = 40, e), 'Church of England'); // 1565
  });

  test('news: the crier, then avvisi, then print; word from the caravans', () {
    final e = era();
    expect(eraPaper(blankEraLife(city: 'Florence', year: 1478), e).kind, 'crier');
    expect(
      eraPaper(blankEraLife(city: 'Venice', year: 1576), e).title,
      'Avvisi di Venezia',
    );
    expect(eraPaper(blankEraLife(city: 'London', year: 1625), e).title, 'Coranto');
    expect(
      eraPaper(blankEraLife(city: 'Timbuktu', year: 1500), e).title,
      'Word from the caravans',
    );
    final issue = eraIssue(blankEraLife(city: 'Florence', year: 1478), e);
    expect(issue.stories.first.text, startsWith('Plague in Florence'));
    expect(issue.effects['prices'], 4);
    // A London life never hears Florentine gossip.
    final london = eraIssue(blankEraLife(city: 'London', year: 1478), e);
    expect(london.stories.map((s) => s.text).join(), isNot(contains('Medici')));
  });

  test('every new era string is free of modern words', () {
    final e = era();
    final bad = RegExp(
      '\\b(${e.anachronisms.where((w) => w != r'\$').join('|')})\\b|\\\$',
      caseSensitive: false,
    );
    final blob = jsonEncode([e.healthData, e.lawData, e.faithData, e.newsData]);
    final hits = bad.allMatches(blob).map((m) => m.group(0)).toSet();
    expect(hits, isEmpty);
  });

  test('300 lives with crime and plague: prison always ends, no execution', () {
    final e = timelineEngine();
    final r = era();
    var held = 0, plagues = 0;
    for (var seed = 0; seed < 300; seed++) {
      final t = newTimeline('renaissance', 1450 + (seed % 19) * 10, seed: seed);
      e.timeline = t;
      final life = startTimelineLife(
        r,
        t,
        seed: seed,
        year: t.startYear,
        regionId: r.regions[seed % r.regions.length].id,
      );
      final rng = Random(seed);
      var insideFor = 0;
      var guard = 0;
      while (life.alive && guard++ < 130) {
        if (life.age >= 14 && rng.nextInt(3) == 0) {
          final crimes = eraCrimes(life, r);
          if (crimes.isNotEmpty) {
            commitEraCrime(life, r, crimes[rng.nextInt(crimes.length)].id, rng);
          }
        }
        if (eraPlagueHere(life, r)) {
          plagues++;
          chooseEraPlague(life, r, ['flee', 'shut', 'help'][rng.nextInt(3)]);
        }
        final s = e.ageUp(life);
        if (s != null) {
          final shown = visibleChoices(life, s);
          if (shown.isNotEmpty) {
            final c = shown[rng.nextInt(shown.length)];
            if (c.lockReason(life) == null) e.choose(life, s, c);
          }
        }
        if (eraInside(life)) {
          held++;
          insideFor++;
          expect(insideFor, lessThan(12), reason: 'seed $seed held too long');
        } else {
          insideFor = 0;
        }
      }
      expect(life.alive, isFalse);
      expect(life.causeOfDeath, isNot(contains('xecut')));
      for (final f in life.feed) {
        expect(f.text, isNot(contains('{')), reason: f.text);
      }
      final back = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
      expect(back.eraWorld['faith'], life.eraWorld['faith']);
    }
    expect(held, greaterThan(20));
    expect(plagues, greaterThan(10));
  });

  test('modern lives carry no era world', () {
    final l = Life(
      seed: 1,
      firstName: 'A',
      surname: 'B',
      gender: 'female',
      country: 'United States',
      city: 'Boston',
      birthYear: 2000,
      stats: Stats({}),
      npcs: [],
    );
    expect(l.toJson().containsKey('eraWorld'), isFalse);
  });
}
