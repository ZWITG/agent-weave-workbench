import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/era_path.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/world.dart';

import 'timeline_fixtures.dart';

/// Phase 2B: era work, guild ladders and schooling.
void main() {
  setUpAll(loadTimelineContent);
  EraRules era() => eraRegistry['renaissance']!;

  Life person(
    String city,
    int year, {
    String gender = 'male',
    int status = 1,
    List<String> reads = const [],
    int age = 25,
  }) {
    final r = era().regionOfCity(city);
    final l =
        Life(
            seed: 1,
            firstName: 'Test',
            surname: 'Case',
            gender: gender,
            country: r.nameIn(year),
            city: city,
            birthYear: year - age,
            stats: Stats({}),
            npcs: [],
          )
          ..age = age
          ..era = 'renaissance'
          ..money = 500;
    l.eraPath
      ..['status'] = status
      ..['reads'] = reads;
    return l;
  }

  test('every job has a full ladder and sensible rules', () {
    final e = era();
    expect(e.jobs.length, greaterThanOrEqualTo(30));
    final ids = <String>{};
    for (final j in e.jobs) {
      expect(ids.add(j.id), isTrue, reason: 'duplicate ${j.id}');
      expect(j.ladder.length, 3, reason: j.id);
      expect(j.years.length, greaterThanOrEqualTo(2), reason: j.id);
      expect(j.fees.length, greaterThanOrEqualTo(2), reason: j.id);
      expect(j.rise.length, greaterThanOrEqualTo(2), reason: j.id);
      expect(j.sex, anyOf(isNull, 'male', 'female'), reason: j.id);
      if (j.hub != null) expect(e.hubs, contains(j.hub), reason: j.id);
      for (final r in j.reads) {
        expect({'read', 'reckon', 'latin', 'arabic'}, contains(r));
      }
    }
    expect(e.hubs.length, 14);
    for (final s in e.school) {
      expect(s.years, greaterThan(0));
      for (final c in s.cities) {
        expect(e.regionOfCity(c).cities, contains(c), reason: s.id);
      }
    }
  });

  test('every place has work for men and for women, every decade', () {
    final e = era();
    for (var year = 1450; year <= 1650; year += 10) {
      for (final r in e.regionsIn(year)) {
        final city = r.citiesIn(year).first;
        for (final g in ['male', 'female']) {
          final l = person(city, year, gender: g);
          final open = [
            for (final j in e.jobs)
              if (eraJobLock(l, e, j) == null) j.id,
          ];
          expect(
            open.length,
            greaterThanOrEqualTo(g == 'male' ? 4 : 2),
            reason: '$g in $city, $year: $open',
          );
        }
      }
    }
  });

  test('no job or school before its time', () {
    final e = era();
    final printer = e.job('printer')!, player = e.job('player')!;
    expect(eraJobHere(person('Florence', 1460), e, printer), isFalse);
    expect(eraJobHere(person('Florence', 1470), e, printer), isTrue);
    expect(eraJobHere(person('London', 1470), e, printer), isFalse);
    expect(eraJobHere(person('London', 1480), e, printer), isTrue);
    expect(eraJobHere(person('London', 1570), e, player), isFalse);
    expect(eraJobHere(person('London', 1580), e, player), isTrue);
    final kongo = e.schoolById('kongo_school')!;
    expect(eraSchoolHere(person('Mbanza Kongo', 1500), e, kongo), isFalse);
    expect(eraSchoolHere(person('Mbanza Kongo', 1510), e, kongo), isTrue);
    final madrasa = e.schoolById('granada_madrasa')!;
    expect(eraSchoolHere(person('Granada', 1495), e, madrasa), isFalse);
    // The priest needs a Catholic place; the parson a Protestant England.
    expect(eraJobHere(person('Fez', 1500), e, e.job('priest')!), isFalse);
    expect(eraJobHere(person('London', 1520), e, e.job('parson')!), isFalse);
    expect(eraJobHere(person('London', 1560), e, e.job('parson')!), isTrue);
    // No modern word in any job or school.
    final bad = RegExp(
      '\\b(${e.anachronisms.where((w) => w != r'\$').join('|')})\\b',
      caseSensitive: false,
    );
    for (final j in e.jobs) {
      for (final s in [
        j.name,
        ...j.ladder.map((r) => r.title),
        ...j.rise,
        if (j.extra != null) j.extra!,
        if (j.guild != null) j.guild!,
      ]) {
        expect(bad.hasMatch(s), isFalse, reason: s);
      }
    }
    for (final s in e.school) {
      expect(bad.hasMatch(s.name), isFalse, reason: s.name);
    }
  });

  test('status, birth and reading close doors, and say why', () {
    final e = era();
    final notary = e.job('notary')!;
    final l = person('Florence', 1480, status: 2, reads: ['read', 'latin']);
    expect(eraJobLock(l, e, notary), isNull);
    l.eraPath['illegit'] = true;
    expect(eraJobLock(l, e, notary), contains('outside marriage'));
    final poor = person('Florence', 1480, status: 1, reads: ['read', 'latin']);
    expect(eraJobLock(poor, e, notary), startsWith('Closed: born'));
    final unread = person('Florence', 1480, status: 2);
    expect(eraJobLock(unread, e, notary), 'Needs Latin.');
    final woman = person(
      'Florence',
      1480,
      gender: 'female',
      status: 2,
      reads: ['read', 'latin'],
    );
    expect(eraJobLock(woman, e, notary), contains('closed to women'));
    expect(eraJobLock(woman, e, e.job('midwife')!), isNull);
    expect(eraJobLock(l, e, e.job('midwife')!), contains('only women'));
  });

  test('Leonardo: a citizen born outside marriage, on the painter ladder', () {
    final e = era();
    final leo = legendRegistry['leonardo']!;
    final t = newTimeline('renaissance', 1452, legend: leo.id);
    final life = startLegend(leo, t, seed: 3);
    expect(eraStatus(life), 2);
    expect(eraIllegit(life), isTrue);
    life
      ..age = 20
      ..job = "Garzone in Verrocchio's workshop";
    syncEraJob(life, e);
    expect(eraJobOf(life, e)!.id, 'painter');
    expect(eraStep(life), 0);
    life.job = 'Painter of the Guild of St Luke';
    syncEraJob(life, e);
    expect(eraStep(life), 1);
    expect(life.job, 'Painter of the Guild of St Luke');
    life.job = 'Ducal engineer of Milan';
    syncEraJob(life, e);
    expect(eraJobOf(life, e)!.id, 'engineer');
    // His work follows his story.
    final before = life.job;
    expect(takeEraJob(life, e, e.job('banker')!), contains('story'));
    expect(life.job, before);
    expect(eraJobLock(life, e, e.job('notary')!), contains('outside marriage'));
  });

  test('a trade can be learned, risen in and left', () {
    final e = era();
    final l = person('Florence', 1480)..stats.values['smarts'] = 70;
    final painter = e.job('painter')!;
    expect(takeEraJob(l, e, painter), contains("painter's garzone"));
    expect(l.job, "Painter's garzone");
    expect(eraRiseLock(l, e), startsWith('After'));
    final rng = Random(1);
    for (var y = 0; y < 12 && eraStep(l) == 0; y++) {
      l.usedActions.clear();
      l.age++;
      eraPathYear(l, e, rng);
      if (eraRiseLock(l, e) == null) riseInEraTrade(l, e, rng);
    }
    expect(eraStep(l), 1);
    expect(l.job, 'Journeyman painter');
    expect(l.salary, greaterThan(eraPay(l, e, painter, 0)));
    leaveEraJob(l, e);
    expect(l.job, isNull);
    expect(eraJobOf(l, e), isNull);
  });

  test('school teaches reading, and universities need Latin', () {
    final e = era();
    final kid = person('Florence', 1480, age: 7, status: 2);
    final abacus = e.schoolById('abacus')!;
    expect(enrolEraSchool(kid, e, abacus), contains('Abacus school'));
    final rng = Random(2);
    for (var y = 0; y < 3; y++) {
      kid.age++;
      eraPathYear(kid, e, rng);
    }
    expect(eraReads(kid), containsAll(['read', 'reckon']));
    expect(eraSchoolsDone(kid), ['abacus']);
    final student = person('Padua', 1500, age: 18, reads: ['read']);
    final padua = e.schoolById('padua')!;
    expect(eraSchoolLock(student, e, padua), 'Needs Latin first.');
    student.eraPath['reads'] = ['read', 'latin'];
    expect(eraSchoolLock(student, e, padua), isNull);
    final away = person('Florence', 1500, age: 18, reads: ['read', 'latin']);
    expect(eraSchoolLock(away, e, padua), contains('journey'));
    final sankore = e.schoolById('sankore')!;
    final talib = person('Timbuktu', 1520, age: 15, reads: ['read', 'arabic']);
    expect(eraSchoolLock(talib, e, sankore), isNull);
    // Teaching yourself Latin is slow but gets there.
    final self = person('Florence', 1480, reads: ['read']);
    for (var y = 0; y < 15 && !eraReads(self).contains('latin'); y++) {
      self.usedActions.clear();
      teachYourselfLatin(self, rng);
    }
    expect(eraReads(self), contains('latin'));
  });

  test('ordinary lives find many trades, not only wool', () {
    final world = World(seed: 31);
    final e = timelineEngine(world: world);
    final before = jsonEncode(world.toJson());
    final rules = era();
    final trades = <String, int>{};
    final readers = <int, int>{};
    var placed = 0;
    for (var seed = 0; seed < 300; seed++) {
      final year = 1450 + (seed * 37) % 180;
      final t = newTimeline('renaissance', year, seed: 7000 + seed);
      e.timeline = t;
      final life = startTimelineLife(rules, t, seed: seed, year: year);
      expect(life.eraPath['status'], inInclusiveRange(0, 3));
      final rng = Random(seed);
      final jobs = <String>{};
      var guard = 0;
      while (life.alive && guard++ < 130 && life.age < 40) {
        final s = e.ageUp(life);
        if (life.eraPath['job'] != null) jobs.add(life.eraPath['job']);
        if (s != null) {
          final shown = visibleChoices(life, s);
          if (shown.isNotEmpty) {
            final c = shown[rng.nextInt(shown.length)];
            if (c.lockReason(life) == null) e.choose(life, s, c);
          }
        }
        if (eraRiseLock(life, rules) == null) {
          riseInEraTrade(life, rules, rng);
        }
      }
      if (jobs.isNotEmpty) placed++;
      for (final j in jobs) {
        trades[j] = (trades[j] ?? 0) + 1;
      }
      if (eraReads(life).isNotEmpty) {
        final st = eraStatus(life);
        readers[st] = (readers[st] ?? 0) + 1;
      }
      // Saves keep the path.
      final back = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
      expect(back.eraPath['status'], life.eraPath['status']);
      expect(back.eraPath['job'], life.eraPath['job']);
    }
    expect(trades.length, greaterThanOrEqualTo(18), reason: '$trades');
    expect(trades['wool'] ?? 0, lessThan(placed ~/ 5), reason: '$trades');
    expect(placed, greaterThan(150));
    // The better born read more often.
    expect(readers[2] ?? 0, greaterThan(readers[0] ?? 0), reason: '$readers');
    expect(jsonEncode(world.toJson()), before, reason: 'modern world changed');
  });

  test('a modern life never gets an era path', () {
    final l = Life(
      seed: 1,
      firstName: 'A',
      surname: 'B',
      gender: 'male',
      country: 'South Africa',
      city: 'Durban',
      birthYear: 2000,
      stats: Stats({}),
      npcs: [],
    );
    expect(l.eraPath, isEmpty);
    expect(l.toJson().containsKey('eraPath'), isFalse);
  });
}
