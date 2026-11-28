/// The market in an era life (Legends plan §5.6, Phase 2D): cloth and
/// dress, beasts, books (only once a press has reached the place, or a
/// copied manuscript where there is none), paper and pigments, music and
/// a sword with a permit. Nothing modern is for sale. What you own is kept
/// in the era life and counts towards your house's worth.
library;

import 'dart:math';

import 'era_justice.dart' show eraInside;
import 'era_wealth.dart';
import 'eras.dart';
import 'models.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// The market's name here ("the Mercato Vecchio").
String eraMarketName(Life l, EraRules era) =>
    ((era.marketData['market'] as Map?) ?? const {})[l.city] as String? ??
    'the market';

/// Every item for sale here and now (one per id: the place's version).
List<Map<String, dynamic>> eraMarketHere(Life l, EraRules era) {
  final seen = <String>{};
  final out = <Map<String, dynamic>>[];
  for (final raw in (era.marketData['items'] as List?) ?? const []) {
    final i = Map<String, dynamic>.from(raw as Map);
    if (!eraScoped(i, l, era) || !seen.add(i['id'] as String)) continue;
    out.add(i);
  }
  return out;
}

/// An item by id, in this place's version (or any version).
Map<String, dynamic>? eraItem(Life l, EraRules era, String id) {
  final here = eraMarketHere(l, era).where((i) => i['id'] == id).firstOrNull;
  if (here != null) return here;
  for (final raw in (era.marketData['items'] as List?) ?? const []) {
    if ((raw as Map)['id'] == id) return Map<String, dynamic>.from(raw);
  }
  return null;
}

/// The year printing reaches this place, or null.
int? eraPressYear(Life l, EraRules era) =>
    ((era.marketData['press'] as Map?) ?? const {})[era.regionOf(l).id] as int?;

List<String> eraOwned(Life l) =>
    List<String>.from((l.eraWorld['owned'] as List?) ?? const []);

bool eraOwns(Life l, String id) => eraOwned(l).contains(id);

void eraOwn(Life l, String id) {
  if (!eraOwns(l, id)) l.eraWorld['owned'] = [...eraOwned(l), id];
}

void eraDisown(Life l, String id) =>
    l.eraWorld['owned'] = eraOwned(l)..remove(id);

/// What your things would fetch: half what they cost.
int eraThingsValue(Life l, EraRules era) {
  var v = 0;
  for (final id in eraOwned(l)) {
    v += eraCost(l, era, _int(eraItem(l, era, id)?['cost'])) ~/ 2;
  }
  return v;
}

String? eraItemLock(Life l, EraRules era, Map<String, dynamic> i) {
  if (!l.alive) return 'This life is over.';
  if (eraInside(l)) return 'Not while you are held.';
  if (l.age < 8) return 'When you are older.';
  final id = i['id'] as String;
  if (eraOwns(l, id) && id != 'spice') return 'You have one.';
  if (i['press'] == true) {
    final press = eraPressYear(l, era);
    if (press == null || l.year < press) {
      return press == null
          ? 'No press here yet: books are copied by hand.'
          : 'No press here until $press: books are copied by hand.';
    }
  }
  final cost = eraCost(l, era, _int(i['cost']));
  if (l.money < cost) return 'Needs ${eraM(l, cost)}.';
  return null;
}

/// Buys an item: pays, keeps it, and its small effects.
String eraBuy(Life l, EraRules era, String id, Random rng) {
  final i = eraMarketHere(l, era).where((i) => i['id'] == id).firstOrNull;
  if (i == null) return 'Not for sale here.';
  final lock = eraItemLock(l, era, i);
  if (lock != null) return lock;
  final cost = eraCost(l, era, _int(i['cost']));
  l.money -= cost;
  if (id != 'spice') eraOwn(l, id);
  for (final s in ['looks', 'smarts', 'creativity']) {
    if (i[s] != null) l.stats.add(s, _int(i[s]));
  }
  var text = 'You bought ${eraLower(i['label'] as String)} for ${eraM(l, cost)}.';
  if (i['pages'] == true) {
    l.eraWorld['pages'] = _int(l.eraWorld['pages']) + 5;
    if (l.legendId == 'leonardo') {
      text += ' Five new pages fill up with gears, birds and faces.';
    }
  }
  if (id == 'spice') {
    l.stats.add('happiness', 2);
    text += ' The kitchen smells of the Indies.';
  }
  // Sumptuary laws: fine silk on the wrong back draws a fine.
  if (i['sumptuary'] == true && rng.nextDouble() < 0.2) {
    final fine = max(1, cost ~/ 3);
    l.money -= fine;
    text += ' The officers of the sumptuary law stopped you in the street and fined you ${eraM(l, fine)}.';
  }
  return text;
}

/// Sells something back at the market for half its price.
String eraSell(Life l, EraRules era, String id) {
  if (!eraOwns(l, id)) return 'You do not own that.';
  final i = eraItem(l, era, id);
  final back = max(1, eraCost(l, era, _int(i?['cost'])) ~/ 2);
  eraDisown(l, id);
  l.money += back;
  return 'You sold ${eraLower((i?['label'] as String?) ?? 'it')} for ${eraM(l, back)}.';
}
