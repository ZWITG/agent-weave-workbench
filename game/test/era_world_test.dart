import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/currency.dart';
import 'package:relivable/engine/eras.dart';

import 'timeline_fixtures.dart';

/// The Renaissance world pack (Phase 2A): every place has a ruler, a
/// money and prices for every year it exists, and nothing is missing.
void main() {
  setUpAll(loadTimelineContent);

  test('every region has a ruler, a money and names for every year', () {
    final era = eraRegistry['renaissance']!;
    expect(era.regions.length, greaterThanOrEqualTo(15));
    for (final r in era.regions) {
      for (var y = era.from; y <= era.to; y++) {
        if (!r.openIn(y)) continue;
        expect(r.rulerIn(y), isNotNull, reason: '${r.id} has no ruler in $y');
        expect(era.currencies, contains(r.currencyIn(y)), reason: '${r.id} $y');
        expect(r.faithIn(y), isNotEmpty, reason: '${r.id} faith $y');
        expect(r.citiesIn(y), isNotEmpty, reason: '${r.id} cities $y');
        expect(r.maleIn(y), isNotEmpty, reason: r.id);
        expect(r.femaleIn(y), isNotEmpty, reason: r.id);
      }
      expect(r.surnames, isNotEmpty, reason: r.id);
      expect(r.language, isNotEmpty, reason: r.id);
      expect(r.group, isNotEmpty, reason: r.id);
      expect(r.lat != 0 || r.lon != 0, isTrue, reason: r.id);
    }
  });

  test('every city belongs to one region only', () {
    final era = eraRegistry['renaissance']!;
    final seen = <String, String>{};
    for (final r in era.regions) {
      for (final c in r.cities) {
        expect(seen[c], isNull, reason: '$c is in ${seen[c]} and ${r.id}');
        seen[c] = r.id;
      }
    }
  });

  test('Africa is in the world from the start', () {
    final era = eraRegistry['renaissance']!;
    final ids = {for (final r in era.regionsIn(1450)) r.id};
    expect(ids, containsAll(['fez', 'songhai', 'cairo', 'kongo', 'ndongo']));
    expect(era.region('luanda').openIn(1575), isFalse);
    expect(era.region('luanda').openIn(1576), isTrue);
    expect(era.region('malta').citiesIn(1565), isNot(contains('Valletta')));
    expect(era.region('malta').citiesIn(1566), contains('Valletta'));
  });

  test('names and rulers follow history', () {
    final era = eraRegistry['renaissance']!;
    final f = era.region('florence');
    expect(f.nameIn(1500), 'Republic of Florence');
    expect(f.nameIn(1540), 'Duchy of Florence');
    expect(f.nameIn(1600), 'Grand Duchy of Tuscany');
    expect(era.region('granada').nameIn(1492), 'Kingdom of Granada');
    expect(era.region('granada').currencyIn(1491), 'dinar');
    expect(era.region('cairo').nameIn(1517), 'Ottoman Egypt');
    expect(era.region('england').rulerIn(1600), 'Queen Elizabeth I');
    expect(era.region('songhai').rulerIn(1500), 'Askia Muhammad');
    expect(era.region('ndongo').rulerIn(1625), 'Queen Nzinga');
    expect(era.region('kongo').maleIn(1480), isNot(contains('Afonso')));
    expect(era.region('kongo').maleIn(1500), contains('Afonso'));
  });

  test('prices rise after 1550 and wages lag behind', () {
    final era = eraRegistry['renaissance']!;
    final f = era.region('florence');
    expect(era.priceLevel(1450), 1.0);
    expect(era.priceLevel(1600), 2.0);
    expect(era.priceLevel(1525), inInclusiveRange(1.05, 1.15));
    final p1500 = era.price('horse', f, 1500),
        p1600 = era.price('horse', f, 1600);
    final w1500 = era.wage(40, f, 1500), w1600 = era.wage(40, f, 1600);
    expect(p1600, greaterThan(p1500));
    expect(w1600 / w1500, lessThan(p1600 / p1500));
    // Poorer places are cheaper.
    expect(era.price('horse', era.region('kongo'), 1500), lessThan(p1500));
  });

  test('each place shows its own money', () {
    final era = eraRegistry['renaissance']!;
    expect(moneyIn(100, 'Republic of Florence'), 'ƒ100');
    expect(moneyIn(100, 'Republic of Venice'), 'duc. 100');
    // 100 florins at 40d each is 4,000d: £16 13s 4d.
    expect(moneyIn(100, 'Kingdom of England'), '£16 13s 4d');
    expect(moneyIn(1, 'Kingdom of England'), '3s 4d');
    expect(shortMoney(100, 'Kingdom of England'), '£16 13s');
    expect(moneyIn(3, 'Kingdom of Kongo'), 'nz. 3,000');
    expect(moneyIn(2, 'Kingdom of Ndongo'), 'lib. 40');
    expect(moneyIn(1, 'Portuguese Luanda'), 'rs. 400');
    expect(era.regions.length, greaterThan(10));
  });

  test('journeys: road nearby, ships overseas, caravans to the Sahel', () {
    final era = eraRegistry['renaissance']!;
    final life = blankEraLife(city: 'Florence', year: 1500)..money = 500;
    final js = journeysFrom(life, era);
    Journey to(String c) => js.firstWhere((j) => j.to == c);
    expect(to('Prato').by, JourneyBy.road);
    expect(to('Prato').days, lessThan(4));
    expect(to('Milan').by, JourneyBy.road);
    expect(to('London').by, JourneyBy.sea);
    expect(to('Fez').by, JourneyBy.sea);
    expect(js.any((j) => j.to == 'Luanda'), isFalse, reason: 'not before 1576');
    final fez = blankEraLife(city: 'Fez', year: 1510);
    final toTimbuktu = journeysFrom(
      fez,
      era,
    ).firstWhere((j) => j.to == 'Timbuktu');
    expect(toTimbuktu.by, JourneyBy.caravan);
    expect(toTimbuktu.days, greaterThan(30));
    expect(to('London').cost, greaterThan(to('Prato').cost));
  });
}
