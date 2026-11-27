import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/career_hub.dart' show hubYear;
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/echelon.dart';
import 'package:relivable/engine/elite.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/finance.dart';
import 'package:relivable/engine/gangs.dart';
import 'package:relivable/engine/homes.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/lifespan.dart';
import 'package:relivable/engine/meta.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/past.dart';
import 'package:relivable/engine/profile.dart';
import 'package:relivable/engine/recap.dart';
import 'package:relivable/engine/school.dart';
import 'package:relivable/engine/world.dart';
import 'package:relivable/engine/world_data.dart';

import 'timeline_fixtures.dart';

PastRecord samplePast() =>
    PastRecord.fromJson(readJson('assets/past/sample_renaissance.json'));

/// A fresh engine whose world has the sample past linked.
GameEngine linkedEngine() {
  final w = World(seed: 5);
  final e = GameEngine(modernStorylets(), world: w);
  w.linkPast(samplePast());
  e.world = w;
  return e;
}

void main() {
  tearDown(() => past.active = null);

  group('No past linked: nothing changes', () {
    test('every hook is neutral', () {
      final e = GameEngine(modernStorylets(), world: World(seed: 5));
      expect(past.linked, isFalse);
      final l = e.newLife(seed: 42, countryName: 'Italy');
      l.age = 30;
      expect(anniversaries(2024), isEmpty);
      expect(historyColumn(2024), isEmpty);
      expect(pastMods(2024, {'festival': {'happiness': 3}}), isEmpty);
      expect(pastNames(), isEmpty);
      expect(oldMoneyRivals(), isEmpty);
      expect(oldMoneyLine(l), isNull);
      expect(pastTradeBonus(l, 'analyst'), 0);
      expect(ancestorHubLine(l..careerId = 'actor'), isNull);
      expect(pastListings(l), isEmpty);
      expect(landmarkLine(l), isNull);
      expect(pastHeirlooms(l), isEmpty);
      expect(feudCrimeFamily(), isNull);
      expect(grudgeLine(l, Random(1)), isNull);
      expect(pastCompanies(), isEmpty);
      expect(pastAdmissionEdge(l), 0);
      expect(pastNations(), isEmpty);
      expect(pastLifespanFactor(), 1.0);
      expect(pastPeople(l, Random(1)), isEmpty);
      expect(pastFaithLine(l), isNull);
      expect(houseHistory(l), isEmpty);
      expect(allTickers().length, tickers.length);
      expect(allCountries().length, countries.length);
      expect(gangs.map((g) => g.name), ['The Night Owls', 'The Iron Brotherhood', 'The Ledger']);
      expect(l.marks.where((m) => m.startsWith('past:')), isEmpty);
    });

    test('a modern life plays the same before a link and after an unlink', () {
      String play(GameEngine e) {
        final l = e.newLife(seed: 77, countryName: 'Italy');
        playOut(e, l, (s, shown) => 0);
        return jsonEncode(l.toJson());
      }

      final a = play(GameEngine(modernStorylets(), world: World(seed: 9)));
      final w = World(seed: 9)..linkPast(samplePast());
      w.unlinkPast();
      expect(w.names, isEmpty);
      final b = play(GameEngine(modernStorylets(), world: w));
      expect(b, a);
    });

    test('playing a Legend never touches the modern world', () {
      final e = timelineEngine(world: World(seed: 3));
      final before = jsonEncode(e.world.toJson());
      final leo = legendRegistry['leonardo_test']!;
      final t = newTimeline('renaissance', 1450, legend: leo.id);
      e.timeline = t;
      playOut(e, startLegend(leo, t, seed: 4), (s, shown) => 0);
      expect(jsonEncode(e.world.toJson()), before);
    });
  });

  group('A linked past reaches every modern system', () {
    test('the past is saved with the world', () {
      final w = World(seed: 1)..linkPast(samplePast());
      final back = World.fromJson(jsonDecode(jsonEncode(w.toJson())));
      expect(back.past!.house, 'Vespri');
      expect(back.past!.facts['milan_holds_1499'], 1499);
      final e = GameEngine(modernStorylets(), world: back);
      expect(past.has('milan_holds_1499'), isTrue);
      expect(past.houseOf('Vespri')!['mine'], isTrue);
      expect(past.houseOf('Albertini')!['feud'], isTrue);
      expect(past.founded('university')!['name'], 'Studio Vespri University');
      expect(past.currents['Science'], 80);
      expect(e.world.past, isNotNull);
    });

    test('news: a From history column and small anniversary effects', () {
      final e = linkedEngine();
      expect(
        historyColumn(2024).first,
        '525 years ago, milan held against France, with Vespri money behind its walls.',
      );
      final mods = e.world.modsFor(2024, 'Italy', 'Rome', 'Rossi');
      expect(mods['happiness'], 1);
      // A life in 2024 reads it in the feed.
      final l = e.newLife(seed: 3, countryName: 'Italy', startYear: 2016);
      while (l.year < 2024) {
        e.ageUp(l);
      }
      expect(l.feed.any((f) => f.text.startsWith('From history: 525 years ago')), isTrue);
    });

    test('family name: the house and its rivals are known', () {
      final e = linkedEngine();
      expect(e.world.names['Vespri']!['wealth'], 40);
      expect(e.world.reputation('Vespri'), contains('wealthy'));
      expect(e.world.names['Albertini']!['wealth'], 55);
      expect(e.world.modsFor(2030, 'Italy', 'Rome', 'Vespri')['name'], 5);
    });

    test('Echelon: old money on the List, and an invitation', () {
      final e = linkedEngine();
      final l = e.newLife(seed: 8, descendant: true)..age = 40;
      ensureRivals(l);
      final names = [for (final r in rivals(l)) r['name']];
      expect(names, contains('The Albertini family'));
      expect(names, contains('The Ridolfi family'));
      expect(oldMoneyLine(l), contains('Ridolfi'));
      expect(oldMoneyLine(l), isNull, reason: 'once only');
      expect(upperEchelon(l), isFalse);
    });

    test('careers: the family trade pays 5% more, and Hubs mention it', () {
      final e = linkedEngine();
      final analyst = careers.firstWhere((c) => c.id == 'analyst');
      final mine = e.newLife(seed: 9, countryName: 'Italy', descendant: true);
      final other = e.newLife(seed: 9, countryName: 'Italy');
      expect(mine.surname, 'Vespri');
      expect(analyst.payIn(mine, 1), greaterThan(analyst.payIn(other, 1)));
      expect(analyst.payIn(mine, 1) / analyst.payIn(other, 1), closeTo(1.05, 0.01));
      mine.careerId = 'analyst';
      expect(ancestorHubLine(mine), contains('centuries ago'));
      other.careerId = 'actor';
      expect(ancestorHubLine(other), contains('period drama'));
      expect(hubYear, isNotNull);
    });

    test('property: the palazzo comes up for sale, and a landmark', () {
      final e = linkedEngine();
      final l = e.newLife(seed: 10, countryName: 'Italy', descendant: true)..age = 30;
      final homes = listings(l);
      expect(homes.length, 7);
      expect(homes.last.type, contains('Palazzo Vespri'));
      expect(landmarkLine(l), contains('your ancestors'));
    });

    test('possessions: heirlooms come down to the house', () {
      final e = linkedEngine();
      final l = e.newLife(seed: 11, descendant: true);
      final h = l.assets.where((a) => a.id.startsWith('past_')).toList();
      expect(h.map((a) => a.name), ['Vespri crest ring', 'A page of the 1499 Vespri ledger']);
      expect(h.every((a) => a.kind == 'heirloom'), isTrue);
      final other = e.newLife(seed: 11);
      expect(other.assets.where((a) => a.id.startsWith('past_')), isEmpty);
    });

    test('crime: the feud house runs a gang, and the grudge resurfaces', () {
      final e = linkedEngine();
      expect(gangs.map((g) => g.name), contains('The Albertini Ledger'));
      expect(gangById('ledger').about, contains('the Albertini family'));
      final l = e.newLife(seed: 12, descendant: true)..age = 25;
      String? line;
      for (var i = 0; i < 40 && line == null; i++) {
        line = grudgeLine(l, Random(i));
      }
      expect(line, contains('Albertini'));
    });

    test('money: the house bank trades on the market', () {
      final e = linkedEngine();
      expect(tickerById('VSPR')!.name, 'Banca Vespri');
      expect(e.world.pricesFor(2030)['VSPR'], isNotNull);
    });

    test('school: members of the founding house get +3 at admissions', () {
      final e = linkedEngine();
      final l = e.newLife(seed: 13, countryName: 'Italy')..age = 17;
      final base = admissionScore(l).score;
      l.flags['house_blood'] = Memory(0, 'x');
      expect(admissionScore(l).score, base + 3);
    });

    test('countries: a nation founded in the past is a place to live', () {
      linkedEngine();
      expect(allCountries().map((c) => c.name), contains('Free Cities of the Undrawn Isles'));
      expect(countryNamed('Free Cities of the Undrawn Isles').cities, contains('Porto Vespri'));
    });

    test('health: a long Science current adds under a year of life', () {
      final e = GameEngine(modernStorylets(), world: World(seed: 1));
      final l = e.newLife(seed: 14)..age = 70;
      final before = deathChance(l);
      final w = World(seed: 1)..linkPast(samplePast());
      e.world = w;
      final after = deathChance(l);
      expect(after, lessThan(before));
      // At most one year on the Gompertz curve.
      expect(after / before, greaterThanOrEqualTo(exp(-0.085) - 1e-9));
    });

    test('people: descendants of rival houses know your name', () {
      final e = linkedEngine();
      var met = false;
      for (var s = 0; s < 10 && !met; s++) {
        final l = e.newLife(seed: 100 + s, descendant: true);
        final marco = l.npc('past_marco_albertini');
        if (marco != null) {
          met = true;
          expect(marco.memories.single.text, contains('old feud'));
          expect(marco.memories.single.negative, isTrue);
        }
      }
      expect(met, isTrue);
    });

    test('faith, milestones and recap', () {
      final e = linkedEngine();
      final l = e.newLife(seed: 15, descendant: true)..age = 20;
      expect(pastFaithLine(l), contains('Brotherhood of the Lantern'));
      final a = achievements.firstWhere((a) => a.id == 'ancestors');
      expect(a.test(l, Profile()), isTrue);
      expect(recapHouse(l).first, 'House Vespri');
      expect(recapHouse(l), contains('1499: Milan held against France, with Vespri money behind its walls'));
    });
  });

  group('A Legend life becomes a past', () {
    test('Leonardo leaves his heirloom, and his company only if rewritten', () {
      final e = timelineEngine();
      final leo = legendRegistry['leonardo_test']!;
      for (final rewrite in [false, true]) {
        PastRecord? rec;
        for (var seed = 0; seed < 40 && rec == null; seed++) {
          final t = newTimeline('renaissance', 1450, legend: leo.id, seed: seed);
          e.timeline = t;
          final life = startLegend(leo, t, seed: seed);
          playOut(e, life, (s, shown) {
            if (!rewrite) return shown.indexWhere((c) => c.canon).clamp(0, 9);
            final rw = shown.indexWhere((c) => c.rewrites != null);
            if (rw >= 0) return rw;
            final w = shown.indexWhere((c) => (c.adds['military'] ?? 0) > 0);
            return w < 0 ? 0 : w;
          });
          if (t.has('leo_engineer_milan') == rewrite) {
            rec = PastRecord.fromLegendLife(life, t, leo);
          }
        }
        expect(rec, isNotNull);
        expect(rec!.house, 'da Vinci');
        expect(rec.heirlooms.single['name'], 'A notebook page in mirror writing');
        expect(rec.companies.map((c) => c['id']), rewrite ? ['VNCI'] : isEmpty);
        expect(rec.trades, ['developer', 'lab']);
        final w = World(seed: 2)..linkPast(rec);
        final m = GameEngine(modernStorylets(), world: w);
        final kid = m.newLife(seed: 6, descendant: true);
        expect(kid.surname, 'da Vinci');
        expect(kid.assets.any((a) => a.name == 'A notebook page in mirror writing'), isTrue);
        expect(tickerById('VNCI') != null, rewrite);
        past.active = null;
      }
    });
  });
}
