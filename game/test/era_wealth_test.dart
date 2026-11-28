import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/era_activities.dart';
import 'package:relivable/engine/era_health.dart';
import 'package:relivable/engine/era_homes.dart';
import 'package:relivable/engine/era_houses.dart';
import 'package:relivable/engine/era_market.dart';
import 'package:relivable/engine/era_people.dart';
import 'package:relivable/engine/era_wealth.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';

import 'timeline_fixtures.dart';

/// Phase 2D: money, homes, the Great Houses, the market, activities and
/// People redone, in an era life.
void main() {
  setUpAll(loadTimelineContent);
  EraRules era() => eraRegistry['renaissance']!;

  Life person(
    String city,
    int year, {
    String gender = 'male',
    int status = 1,
    int age = 25,
    int money = 500,
    String faith = 'catholic',
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
          ..money = money;
    l.eraPath['status'] = status;
    l.eraWorld['faith'] = faith;
    return l;
  }

  test('every new era string is free of modern words', () {
    final e = era();
    final bad = RegExp(
      '\\b(${e.anachronisms.where((w) => w != r'\$').join('|')})\\b|\\\$',
      caseSensitive: false,
    );
    final blob = jsonEncode([
      e.wealthData,
      e.homesData,
      e.marketData,
      e.activityData,
      e.housesData,
      e.peopleData,
    ]);
    final hits = bad.allMatches(blob).map((m) => m.group(0)).toSet();
    expect(hits, isEmpty);
  });

  test('the Medici bank pays, then falls in 1494', () {
    final e = era();
    final l = person('Florence', 1490);
    expect(eraBankHere(l, e)!['id'], 'medici');
    eraDepositMoney(l, e, 400);
    expect(eraDeposit(l), 400);
    final rng = Random(1);
    eraWealthYear(l, e, rng);
    expect(eraDeposit(l), greaterThan(400));
    l.age = 25 + 4; // 1494
    final out = eraWealthYear(l, e, rng);
    expect(out.join(), contains('Medici'));
    expect(eraDeposit(l), lessThan(200));
    // After 1494 Florence has other banks.
    expect(eraBankHere(person('Florence', 1500), e)!['id'], 'fl_banco');
  });

  test('no interest in Fez; nzimbu in the compound in Kongo', () {
    final e = era();
    expect((eraBankHere(person('Fez', 1500), e)!['rate'] as num), 0);
    expect(eraBankHere(person('Mbanza Kongo', 1520), e)!['id'], 'household');
    expect(eraLenderHere(person('Cairo', 1500), e)!['rate'], 0.0);
  });

  test('the Monte di Pietà opens in Florence only in 1496', () {
    final e = era();
    expect(eraMonteOpen(person('Florence', 1490), e), isFalse);
    expect(eraMonteOpen(person('Florence', 1496), e), isTrue);
    expect(eraMonteOpen(person('Perugia', 1470), e), isTrue);
    expect(eraMonteFrom(person('London', 1600), e), isNull);
  });

  test('pawn and redeem; the Monte sells after two years', () {
    final e = era();
    final l = person('Florence', 1500);
    eraBuy(l, e, 'horse', Random(1));
    expect(eraOwns(l, 'horse'), isTrue);
    final before = l.money;
    eraPawn(l, e, 'horse');
    expect(eraOwns(l, 'horse'), isFalse);
    expect(l.money, greaterThan(before));
    eraRedeem(l, e, 'horse');
    expect(eraOwns(l, 'horse'), isTrue);
    eraPawn(l, e, 'horse');
    l.age += 2;
    final out = eraWealthYear(l, e, Random(1));
    expect(out.join(), contains('auction'));
    expect(eraPawned(l), isEmpty);
  });

  test('no shares before the VOC in 1602; ventures come home or sink', () {
    final e = era();
    for (var y = 1450; y < 1602; y += 10) {
      expect(eraVenturesHere(person('London', y), e).any((v) => v['id'] == 'voc'), isFalse);
      expect(eraVenturesHere(person('Venice', y), e).any((v) => v['id'] == 'voc'), isFalse);
    }
    expect(eraVenturesHere(person('London', 1610), e).any((v) => v['id'] == 'voc'), isTrue);
    var home = 0, lost = 0;
    for (var s = 0; s < 200; s++) {
      final l = person('Venice', 1500, money: 1000);
      eraInvest(l, e, 'alexandria');
      final stake = 1000 - l.money;
      l.age++;
      eraWealthYear(l, e, Random(s));
      if (l.money > 1000 - stake) {
        home++;
      } else {
        lost++;
      }
      expect(eraStakes(l), isEmpty);
    }
    expect(home, greaterThan(120));
    expect(lost, greaterThan(15));
  });

  test('homes by place; a villa makes fleeing the plague free', () {
    final e = era();
    final fl = person('Florence', 1478, money: 5000);
    expect(eraHomesHere(fl, e).map((h) => h.id), containsAll(['room', 'bottega', 'palazzo', 'villa']));
    expect(eraHomesHere(person('Fez', 1500), e).map((h) => h.id), contains('riad'));
    expect(eraHomesHere(person('Mbanza Kongo', 1520), e).map((h) => h.id), contains('kongo_compound'));
    expect(eraHomesHere(person('London', 1580), e).map((h) => h.id), contains('manor'));
    expect(eraHomesHere(person('Florence', 1478), e).map((h) => h.id), isNot(contains('riad')));
    final flee = eraPlagueChoices(fl, e).firstWhere((c) => c.id == 'flee');
    expect(flee.cost, greaterThan(0));
    eraBuyHome(fl, e, 'villa');
    final free = eraPlagueChoices(fl, e).firstWhere((c) => c.id == 'flee');
    expect(free.cost, 0);
    expect(free.label, contains('villa'));
    // Upkeep each year.
    final m = fl.money;
    eraHomesYear(fl, e, Random(1));
    expect(fl.money, lessThan(m));
  });

  test('rent you can\'t pay ends in the street', () {
    final e = era();
    final l = person('Florence', 1480, money: 30);
    eraRentHome(l, e, 'bottega');
    expect(eraHomeId(l), 'bottega');
    l.money = 0;
    final out = eraHomesYear(l, e, Random(1));
    expect(eraHomeId(l), isNull);
    expect(out.join(), contains('street'));
  });

  test('Leonardo: Verrocchio\'s workshop, then the vineyard in 1499', () {
    final e = era();
    final t = newTimeline('renaissance', 1450, legend: 'leonardo', seed: 3);
    final l = startLegend(legendRegistry['leonardo']!, t, seed: 3);
    l.age = 16;
    l.city = 'Florence';
    eraHomesYear(l, e, Random(1));
    expect(eraHomeId(l), 'verrocchio');
    l.age = 47;
    l.city = 'Milan';
    final out = eraHomesYear(l, e, Random(1));
    expect(eraOwnedHomes(l), contains('vigna'));
    expect(out.join(), contains('Ludovico'));
    expect(eraHomeId(l), isNot('verrocchio'));
  });

  test('the Great Houses follow history, and your house can join', () {
    final e = era();
    final l = person('Florence', 1478);
    final names = eraGreatHouses(l, e).map((h) => h.id).toList();
    expect(names.first, 'medici');
    expect(eraGreatHouses(l, e).firstWhere((h) => h.id == 'pazzi').fallen, isTrue);
    expect(eraGreatHouses(person('Florence', 1477), e).firstWhere((h) => h.id == 'pazzi').fallen, isFalse);
    // The Fugger lead by 1527; the Welser are gone after 1624.
    expect(eraGreatHouses(person('Florence', 1527), e).first.id, 'fugger');
    expect(eraGreatHouses(person('Florence', 1630), e).any((h) => h.id == 'welser'), isFalse);
    // Local houses: the Aqit in Timbuktu, not in Florence.
    expect(eraGreatHouses(person('Timbuktu', 1500), e).any((h) => h.id == 'aqit' && h.local), isTrue);
    expect(eraGreatHouses(l, e).any((h) => h.id == 'aqit'), isFalse);
    expect(eraHouseRank(l, e), isNull);
    l.money = 20000;
    expect(eraHouseRank(l, e), isNotNull);
    expect(eraHousesYear(l, e).join(), contains('great houses'));
  });

  test('the market: books only after the press; nothing modern', () {
    final e = era();
    final book = eraMarketHere(person('Florence', 1465), e).firstWhere((i) => i['id'] == 'book');
    expect(eraItemLock(person('Florence', 1465), e, book), contains('1471'));
    expect(eraItemLock(person('Florence', 1472), e, book), isNull);
    final ldn = eraMarketHere(person('London', 1470), e).firstWhere((i) => i['id'] == 'book');
    expect(eraItemLock(person('London', 1470), e, ldn), contains('1476'));
    final fez = eraMarketHere(person('Fez', 1500), e).firstWhere((i) => i['id'] == 'book');
    expect(fez['label'], contains('manuscript'));
    expect(eraMarketHere(person('Mbanza Kongo', 1520), e).any((i) => i['id'] == 'horse'), isFalse);
  });

  test('activities by place, year, faith and custom', () {
    final e = era();
    List<String> ids(Life l) => eraActivitiesHere(l, e).map((a) => a['id'] as String).toList();
    expect(ids(person('Florence', 1478)), containsAll(['era_carnival', 'era_calcio', 'era_san_giovanni', 'era_market', 'era_journey']));
    expect(ids(person('London', 1575)), isNot(contains('era_playhouse')));
    expect(ids(person('London', 1576)), contains('era_playhouse'));
    expect(ids(person('Fez', 1500, faith: 'muslim')), contains('era_hajj'));
    expect(ids(person('Fez', 1500, faith: 'jewish')), isNot(contains('era_hajj')));
    expect(ids(person('Mbanza Kongo', 1520, faith: 'kongo')), contains('era_dance'));
    final woman = person('Florence', 1478, gender: 'female');
    final calcio = eraActivitiesHere(woman, e).firstWhere((a) => a['id'] == 'era_calcio');
    expect(eraActivityLock(woman, e, calcio), contains('Custom'));
    final ride = eraActivitiesHere(person('Florence', 1478), e).firstWhere((a) => a['id'] == 'era_ride');
    expect(eraActivityLock(person('Florence', 1478), e, ride), contains('horse'));
    // Once a year, and the hajj once in a life.
    final l = person('Fez', 1500, faith: 'muslim');
    doEraActivity(l, e, 'era_hajj', 0.8, Random(1));
    final hajj = eraActivitiesHere(l, e).firstWhere((a) => a['id'] == 'era_hajj');
    expect(eraActivityLock(l, e, hajj), contains('hajji'));
    expect(l.flags, contains('hajji'));
  });

  test('People: natures, scenes, replies and memories', () {
    final e = era();
    final t = newTimeline('renaissance', 1450, legend: 'leonardo', seed: 3);
    final l = startLegend(legendRegistry['leonardo']!, t, seed: 3);
    l.age = 26;
    final mother = l.npcs.firstWhere((n) => n.id == 'mother');
    eraNature(l, e, mother);
    expect(eraHumourOf(mother), 'melancholic');
    expect(eraLikesOf(mother), contains('old'));
    expect(eraKnows(mother, 'humour'), isTrue);
    final talk = eraScene(l, e, mother, 'talk');
    expect(talk.choices.map((c) => c.id), containsAll(['old', 'news', 'troubles']));
    expect(talk.choices.any((c) => c.label == 'Ask about your birth'), isTrue);
    expect(eraMoments(l, e, mother).length, 3);
    final bond = mother.bond;
    var good = 0;
    for (var s = 0; s < 20; s++) {
      l.usedActions.clear();
      final out = eraChoose(l, e, mother, 'talk', 'old', Random(s));
      if (out.good) good++;
      expect(out.text, isNotEmpty);
      expect(out.quote, isNotEmpty);
    }
    expect(good, greaterThan(14), reason: 'she loves the old days');
    expect(mother.bond, greaterThan(bond));
    expect(mother.memories, isNotEmpty);
    // Once a year for each way.
    expect(eraWayLock(l, mother, 'talk'), isNotNull);
    // A whole year of people: worries and callers, saved and loaded.
    for (var y = 0; y < 5; y++) {
      l.age++;
      eraPeopleYear(l, e, Random(y));
    }
    final back = Life.fromJson(jsonDecode(jsonEncode(l.toJson())));
    expect(back.npcs.firstWhere((n) => n.id == 'mother').info['humour'], 'melancholic');
  });

  test('matches: dowries go the right way, and widows get theirs back', () {
    final e = era();
    final man = person('Florence', 1480, money: 50);
    final offer = eraMatchOffer(man, e);
    expect(offer.youPay, isFalse);
    eraAnswerMatch(man, e, 'accept', Random(1));
    expect(man.money, 50 + offer.dowry);
    expect(man.npcs.where((n) => n.circle == 'Partner'), hasLength(1));
    expect(eraMatchLock(man), isNotNull);
    final woman = person('Florence', 1480, gender: 'female', money: 5000);
    final o2 = eraMatchOffer(woman, e);
    expect(o2.youPay, isTrue);
    eraAnswerMatch(woman, e, 'accept', Random(1));
    expect(woman.money, 5000 - o2.dowry);
    final spouse = woman.npcs.firstWhere((n) => n.circle == 'Partner');
    spouse.alive = false;
    final out = eraPeopleYear(woman, e, Random(1));
    expect(out.join(), contains('widow'));
    expect(woman.money, 5000);
  });

  test('300 lives with money, homes, activities and people: nothing breaks', () {
    final e = timelineEngine();
    final r = era();
    var joined = 0;
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
      var guard = 0;
      while (life.alive && guard++ < 130) {
        if (life.age >= 16) {
          final pick = rng.nextInt(8);
          switch (pick) {
            case 0:
              eraDepositMoney(life, r, life.money ~/ 2);
            case 1:
              final v = eraVenturesHere(life, r);
              if (v.isNotEmpty) eraInvest(life, r, v[rng.nextInt(v.length)]['id'] as String);
            case 2:
              final h = eraHomesHere(life, r);
              if (h.isNotEmpty) {
                final x = h[rng.nextInt(h.length)];
                x.data.containsKey('buy') ? eraBuyHome(life, r, x.id) : eraRentHome(life, r, x.id);
              }
            case 3:
              final i = eraMarketHere(life, r);
              if (i.isNotEmpty) eraBuy(life, r, i[rng.nextInt(i.length)]['id'] as String, rng);
            case 4:
              final a = eraActivitiesHere(life, r).where((a) => a['game'] != null).toList();
              if (a.isNotEmpty) doEraActivity(life, r, a[rng.nextInt(a.length)]['id'] as String, rng.nextDouble(), rng);
            case 5:
              final p = eraPeople(life);
              if (p.isNotEmpty) {
                final n = p[rng.nextInt(p.length)];
                final way = eraWays[rng.nextInt(eraWays.length)];
                if (eraWayLock(life, n, way) == null) {
                  final s = eraScene(life, r, n, way);
                  final open = s.choices.where((c) => c.lock == null).toList();
                  if (open.isNotEmpty) eraChoose(life, r, n, way, open[rng.nextInt(open.length)].id, rng);
                }
                for (final m in eraMoments(life, r, n).toList()) {
                  final s = eraScene(life, r, n, m);
                  final open = s.choices.where((c) => c.lock == null).toList();
                  if (open.isNotEmpty) eraChoose(life, r, n, m, open.first.id, rng, score: rng.nextDouble());
                }
              }
            case 6:
              if (eraMatchLock(life) == null) eraAnswerMatch(life, r, ['accept', 'haggle', 'love', 'refuse'][rng.nextInt(4)], rng);
              for (final call in eraCalls(life)) {
                final s = eraCallScene(life, r, call);
                final open = s.choices.where((c) => c.lock == null).toList();
                if (open.isNotEmpty) eraAnswerCall(life, r, call, open.first.id, rng);
              }
            case 7:
              if (eraLoanLock(life, r) == null) eraBorrow(life, r, 20);
              if (eraLoan(life) > 0) eraRepay(life, r, life.money ~/ 3);
          }
        }
        final s = e.ageUp(life);
        if (s != null) {
          final shown = visibleChoices(life, s);
          if (shown.isNotEmpty) {
            final c = shown[rng.nextInt(shown.length)];
            if (c.lockReason(life) == null) e.choose(life, s, c);
          }
        }
        expect(eraNetWorth(life, r), lessThan(100000000), reason: 'seed $seed');
        expect(eraLoan(life), greaterThanOrEqualTo(0));
      }
      if (life.eraWorld['onList'] == true || life.flags.containsKey('great_house')) joined++;
      expect(life.alive, isFalse);
      for (final f in life.feed) {
        expect(f.text, isNot(contains('{')), reason: f.text);
        expect(f.text, isNot(contains(r'$')), reason: f.text);
      }
      final back = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
      expect(back.eraWorld['homes'], life.eraWorld['homes']);
    }
    // Joining the Great Houses is rare, but it happens.
    expect(joined, lessThan(150));
  });
}
