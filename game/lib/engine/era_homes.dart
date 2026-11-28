/// Homes in an era life (Legends plan §5.6, Phase 2D): rent a room or a
/// workshop, buy a townhouse, a villa or a palazzo, and their equivalents
/// in London, Fez, Cairo, Timbuktu and Kongo. Where you live sets your
/// standing and costs rent or upkeep each year; a house in the country
/// lets you leave the city in a plague year. Leonardo's real homes come
/// on history's path. Only timeline lives reach this file.
library;

import 'dart:math';

import 'era_justice.dart' show eraInside;
import 'era_path.dart' show eraStatus;
import 'era_wealth.dart';
import 'eras.dart';
import 'models.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// One home: from the era table, or one of a Legend's real homes.
typedef EraHome = ({
  String id,
  String label,
  String about,
  int rent,
  int buy,
  int upkeep,
  int standing,
  bool country,
  bool work,
  Map<String, dynamic> data,
});

EraHome _home(Life l, EraRules era, Map<String, dynamic> h) => (
  id: h['id'] as String,
  label: h['label'] as String,
  about: h['about'] as String? ?? '',
  rent: h.containsKey('rent') ? eraCost(l, era, _int(h['rent'])) : 0,
  buy: h.containsKey('buy') ? eraCost(l, era, _int(h['buy'])) : 0,
  upkeep: eraCost(l, era, _int(h['upkeep'])),
  standing: _int(h['standing']),
  country: h['country'] == true,
  work: h['work'] == true,
  data: h,
);

/// Every home on offer here and now.
List<EraHome> eraHomesHere(Life l, EraRules era) => [
  for (final h in (era.homesData['list'] as List?) ?? const [])
    if (eraScoped(h as Map, l, era)) _home(l, era, Map<String, dynamic>.from(h)),
];

/// A home by id: this place's, or a Legend's own.
EraHome? eraHomeById(Life l, EraRules era, String? id) {
  if (id == null) return null;
  for (final h in [
    ...(era.homesData['list'] as List?) ?? const [],
    ...(era.homesData['legend'] as List?) ?? const [],
  ]) {
    if ((h as Map)['id'] == id) {
      return _home(l, era, Map<String, dynamic>.from(h));
    }
  }
  return null;
}

/// Homes you own: id -> what it is worth (what you paid).
Map<String, int> eraOwnedHomes(Life l) => {
  for (final e in ((l.eraWorld['homes'] as Map?) ?? const {}).entries)
    e.key as String: _int(e.value),
};

int eraHomesValue(Life l) =>
    eraOwnedHomes(l).values.fold<int>(0, (a, b) => a + b);

/// Where you live: a home id, or null for "with your family".
String? eraHomeId(Life l) => l.eraWorld['home'] as String?;

EraHome? eraHomeNow(Life l, EraRules era) => eraHomeById(l, era, eraHomeId(l));

bool eraRents(Life l) =>
    eraHomeId(l) != null && !eraOwnedHomes(l).containsKey(eraHomeId(l));

/// The line under "Home" on the Wealth tab.
String eraHomeLine(Life l, EraRules era) {
  final h = eraHomeNow(l, era);
  if (h == null) {
    return l.age < 16 ? 'With your family' : 'With your family, for now';
  }
  return h.label;
}

/// The standing your home gives you (0 to 5).
int eraHomeStanding(Life l, EraRules era) {
  var best = eraHomeNow(l, era)?.standing ?? 0;
  for (final id in eraOwnedHomes(l).keys) {
    best = max(best, eraHomeById(l, era, id)?.standing ?? 0);
  }
  return best;
}

/// A house in the country you own (for leaving the city in a plague year).
EraHome? eraCountryHome(Life l, EraRules era) {
  for (final id in eraOwnedHomes(l).keys) {
    final h = eraHomeById(l, era, id);
    if (h != null && (h.country || h.id == 'vigna' || h.id == 'cloux')) {
      return h;
    }
  }
  return null;
}

String? eraHomeLock(Life l, EraRules era, EraHome h, {required bool buy}) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 16) return 'When you are older.';
  if (eraInside(l)) return 'Not while you are held.';
  final lock = h.data['lock'] as String?;
  final status = h.data['status'] as int?;
  if (status != null && eraStatus(l) < status) return lock ?? 'Not for you.';
  if (eraOwnedHomes(l).containsKey(h.id)) {
    return eraHomeId(l) == h.id ? 'You live here.' : null;
  }
  if (!buy && eraHomeId(l) == h.id) return 'You live here.';
  final cost = buy ? h.buy : h.rent;
  if (l.money < cost) return 'Needs ${eraM(l, cost)}.';
  return null;
}

String eraRentHome(Life l, EraRules era, String id) {
  final h = eraHomesHere(l, era).where((h) => h.id == id).firstOrNull;
  if (h == null || !h.data.containsKey('rent')) return 'Not to rent here.';
  final lock = eraHomeLock(l, era, h, buy: false);
  if (lock != null) return lock;
  l.money -= h.rent;
  l.eraWorld['home'] = h.id;
  l.eraWorld['homeCity'] = l.city;
  return h.rent == 0
      ? 'You moved into ${eraLower(h.label)}.'
      : 'You paid ${eraM(l, h.rent)} for the first year and moved into ${eraLower(h.label)}.';
}

String eraBuyHome(Life l, EraRules era, String id) {
  final h = eraHomesHere(l, era).where((h) => h.id == id).firstOrNull;
  if (h == null || !h.data.containsKey('buy')) return 'Not for sale here.';
  final lock = eraHomeLock(l, era, h, buy: true);
  if (lock != null) return lock;
  l.money -= h.buy;
  l.eraWorld['homes'] = {...eraOwnedHomes(l), h.id: h.buy};
  // A country house is a second home; anything else you move into.
  if (!h.country || eraHomeId(l) == null) {
    l.eraWorld['home'] = h.id;
    l.eraWorld['homeCity'] = l.city;
  }
  l.stats.add('happiness', 6);
  l.flags['home_${h.id}'] = Memory(l.age, 'buying ${eraLower(h.label)}');
  return switch (h.id) {
    'palazzo' =>
      'The notary read the deed aloud and you are the owner of a palazzo. Your arms go up over the door.',
    'villa' || 'manor' || 'estate' =>
      'You bought ${eraLower(h.label)}. When the city sickens, you have somewhere to go.',
    _ => 'You bought ${eraLower(h.label)} for ${eraM(l, h.buy)} and moved in.',
  };
}

String eraMoveHome(Life l, EraRules era, String id) {
  if (!eraOwnedHomes(l).containsKey(id)) return 'You do not own that.';
  final h = eraHomeById(l, era, id);
  if (h == null) return 'Not here.';
  l.eraWorld['home'] = id;
  return 'You moved into ${eraLower(h.label)}.';
}

/// Sells a home you own for about four-fifths of what you paid.
String eraSellHome(Life l, EraRules era, String id) {
  final owned = eraOwnedHomes(l);
  final paid = owned[id];
  if (paid == null) return 'You do not own that.';
  final h = eraHomeById(l, era, id);
  final back = paid * 4 ~/ 5;
  l.money += back;
  owned.remove(id);
  l.eraWorld['homes'] = owned;
  if (eraHomeId(l) == id) l.eraWorld.remove('home');
  return 'You sold ${eraLower(h?.label ?? 'the house')} for ${eraM(l, back)}.';
}

/// Gives up a rented home and goes back to the family.
String eraLeaveHome(Life l, EraRules era) {
  final h = eraHomeNow(l, era);
  if (h == null || !eraRents(l)) return 'You do not rent anywhere.';
  l.eraWorld.remove('home');
  return 'You gave up ${eraLower(h.label)}.';
}

/// One year of homes at a birthday: rent and upkeep, an eviction when you
/// can't pay, moving away from a rented home, and a Legend's real homes
/// on history's path.
List<String> eraHomesYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  // A Legend's homes: the first home of their working life, and gifts.
  for (final raw in (era.homesData['legend'] as List?) ?? const []) {
    final h = Map<String, dynamic>.from(raw as Map);
    if (h['legend'] != l.legendId) continue;
    final id = h['id'] as String;
    if (l.eraWorld['got_$id'] == true) continue;
    if (h['start'] == true) {
      if (eraHomeId(l) == null &&
          l.age >= 14 &&
          eraScoped(h, l, era) &&
          !eraInside(l)) {
        l.eraWorld['home'] = id;
        l.eraWorld['homeCity'] = l.city;
        l.eraWorld['got_$id'] = true;
      }
      continue;
    }
    if (l.year == h['from'] && eraScoped(h, l, era)) {
      l.eraWorld['got_$id'] = true;
      l.eraWorld['homes'] = {...eraOwnedHomes(l), id: _int(h['value'])};
      out.add(h['gift'] as String);
      l.stats.add('happiness', 6);
    }
  }
  // A Legend's first home is left behind when they move on.
  final legendStart = eraHomeById(l, era, eraHomeId(l));
  if (legendStart != null &&
      legendStart.data['start'] == true &&
      !eraScoped(legendStart.data, l, era)) {
    l.eraWorld.remove('home');
  }
  if (eraInside(l)) return out;
  // A rented home is in one city: moving away gives it up.
  if (eraRents(l) && l.eraWorld['homeCity'] != null && l.eraWorld['homeCity'] != l.city) {
    l.eraWorld.remove('home');
  }
  // Rent.
  final now = eraHomeNow(l, era);
  if (now != null && eraRents(l) && now.rent > 0 && now.data['start'] != true) {
    if (l.money >= now.rent) {
      l.money -= now.rent;
      l.lastYear.add(('Rent', -now.rent));
    } else {
      l.eraWorld.remove('home');
      out.add('You could not pay the rent on ${eraLower(now.label)}. The landlord put your things in the street.');
      l.stats.add('happiness', -6);
    }
  }
  // Upkeep of what you own: servants, roofs, taxes.
  var upkeep = 0;
  for (final id in eraOwnedHomes(l).keys) {
    upkeep += eraHomeById(l, era, id)?.upkeep ?? 0;
  }
  if (upkeep > 0) {
    final paid = min(upkeep, max(0, l.money));
    l.money -= paid;
    l.lastYear.add(('Upkeep', -paid));
    if (paid < upkeep) {
      out.add('There was not enough to keep up your houses. The roofs leak and the servants grumble.');
      l.stats.add('happiness', -3);
    }
  }
  return out;
}
