/// Faith in an era life (Legends plan §5.2 and §10, Phase 2C): the faith
/// you are born into, its practices, your standing with neighbours, and in
/// England the church the Crown changes. Faith is always the player's
/// choice; the game never mocks a faith or calls one right. Only timeline
/// lives reach this file; modern faith (faith.dart) never runs in them.
library;

import 'dart:math';

import 'currency.dart';
import 'era_path.dart' show eraReads;
import 'eras.dart';
import 'models.dart';

/// The faith id of this life ("catholic", "muslim", "jewish"...).
String eraFaithOf(Life l) => (l.eraWorld['faith'] as String?) ?? '';

/// Standing with neighbours at church, mosque or synagogue (0 to 5).
int eraStanding(Life l) => (l.eraWorld['standing'] as int?) ?? 0;

/// True for someone in England who keeps the old faith after 1559.
bool eraRecusant(Life l) => l.eraWorld['recusant'] == true;

Map<String, dynamic> _faith(EraRules era, String id) => Map<String, dynamic>.from(
  ((era.faithData['faiths'] as Map?) ?? const {})[id] as Map? ?? const {},
);

/// The faith's name this year (the church of England changes with the
/// Crown).
String eraFaithName(Life l, EraRules era) {
  final id = eraFaithOf(l);
  final names = ((era.faithData['names'] as Map?) ?? const {})[id] as Map?;
  if (names != null) {
    String? out;
    final keys = [for (final k in names.keys) int.parse(k as String)]..sort();
    for (final k in keys) {
      if (k <= l.year) out = names['$k'] as String;
    }
    if (out != null) {
      if (eraRecusant(l) && out == 'Church of England') {
        return 'Catholic (recusant)';
      }
      return out;
    }
  }
  return _faith(era, id)['name'] as String? ?? 'Undecided';
}

/// Sets the faith of a newborn era life from the place and year.
void eraFaithAtBirth(Life l, EraRules era, Random rng) {
  if (eraFaithOf(l).isNotEmpty) return;
  for (final raw in (era.faithData['birth'] as List?) ?? const []) {
    final b = raw as Map;
    if (!eraScoped(b, l, era, year: l.birthYear)) continue;
    final share = (b['share'] as num?)?.toDouble();
    if (share != null && rng.nextDouble() >= share) continue;
    l.eraWorld['faith'] = b['faith'];
    return;
  }
  l.eraWorld['faith'] = 'catholic';
}

/// The line about how you were born into your faith.
String eraFaithBorn(Life l, EraRules era) {
  final f = _faith(era, eraFaithOf(l));
  final churches = Map<String, dynamic>.from(
    (era.faithData['churches'] as Map?) ?? const {},
  );
  final church = churches[l.city] as String? ?? 'the parish church';
  return (f['born'] as String? ?? '')
      .replaceAll('{church}', church)
      .replaceAll('{city}', l.city);
}

/// Facts about the life of this faith here and now (the Ghetto, the
/// recusancy laws), stated plainly.
List<String> eraFaithNotes(Life l, EraRules era) => [
  for (final raw in (era.faithData['notes'] as List?) ?? const [])
    if ((raw as Map)['faith'] == eraFaithOf(l) && eraScoped(raw, l, era))
      raw['text'] as String,
];

/// One practice of a faith.
typedef EraPractice = ({
  String id,
  String label,
  String about,
  Map<String, dynamic> data,
});

List<EraPractice> eraPractices(Life l, EraRules era) {
  final f = _faith(era, eraFaithOf(l));
  final out = <EraPractice>[];
  for (final raw in (f['practices'] as List?) ?? const []) {
    final p = Map<String, dynamic>.from(raw as Map);
    final from = p['from'] as int?;
    if (from != null && l.year < from) continue;
    if (p['once'] == true && l.eraWorld['did_${p['id']}'] == true) continue;
    // In England, a recusant hears Mass in secret instead of the sermon.
    if (eraRecusant(l) && p['id'] == 'sermon') {
      out.add((
        id: 'secret_mass',
        label: 'Hear Mass in secret',
        about: 'A priest in a back room, the door watched',
        data: {'risk': 0.06},
      ));
      continue;
    }
    out.add((
      id: p['id'] as String,
      label: p['label'] as String,
      about: p['about'] as String? ?? '',
      data: p,
    ));
  }
  return out;
}

/// Why [p] can't be done now, or null.
String? eraPracticeLock(Life l, EraRules era, EraPractice p) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 6) return 'When you are older.';
  if (l.usedActions.contains('era_faith_${p.id}')) return 'Done this year.';
  final reads = p.data['reads'] as String?;
  if (reads != null && !eraReads(l).contains(reads)) {
    return 'Needs reading.';
  }
  final cost = p.data['cost'] as int?;
  if (cost != null && l.money < cost) return 'Needs ${moneyIn(cost, l.country)}.';
  return null;
}

/// Keeps a practice this year: happiness and standing with neighbours.
String keepEraPractice(Life l, EraRules era, String id, Random rng) {
  final p = eraPractices(l, era).where((p) => p.id == id).firstOrNull;
  if (p == null) return 'Not here, not now.';
  final lock = eraPracticeLock(l, era, p);
  if (lock != null) return lock;
  l.usedActions.add('era_faith_${p.id}');
  final d = p.data;
  l.eraWorld['practised'] = l.year;
  l.reason = p.label;
  l.stats.add('happiness', 3);
  if (d['health'] != null) l.stats.add('health', d['health'] as int);
  if (d['smarts'] != null) l.stats.add('smarts', d['smarts'] as int);
  if (d['cost'] != null) l.money -= d['cost'] as int;
  if (d['zakat'] == true && l.money > 0) {
    final give = max(1, l.money ~/ 40);
    l.money -= give;
  }
  if (d['once'] == true) l.eraWorld['did_${p.id}'] = true;
  final risk = (d['risk'] as num?)?.toDouble();
  if (risk != null && rng.nextDouble() < risk) {
    // Practising in secret where the law forbids it.
    l.eraWorld['heat'] = min(5, ((l.eraWorld['heat'] as int?) ?? 0) + 1);
    return 'Someone noticed. A neighbour may talk.';
  }
  final up = (d['standing'] as int?) ?? 1;
  l.eraWorld['standing'] = min(5, eraStanding(l) + up);
  return switch (p.id) {
    'confraternity' =>
      'You were enrolled in a confraternity: feasts, processions, and brothers and sisters who help in hard times.',
    'zakat' => 'You gave a fortieth of what you have to those in need.',
    'nganga' => 'The nganga listened, gave you leaves to boil, and told you what the ancestors want.',
    'bible' => 'You read the English Bible in your own tongue.',
    _ => '${p.label}: done. Your neighbours see you there.',
  };
}

/// In England after 1559: keep the old faith (and pay fines) or conform.
String setEraRecusant(Life l, EraRules era, bool recusant) {
  if (eraFaithOf(l) != 'english' || l.year < 1559) return 'Not here, not now.';
  l.eraWorld['recusant'] = recusant;
  return recusant
      ? 'You will keep the old faith. The churchwardens will note your empty place on Sundays.'
      : 'You will go to the parish church on Sundays, as the law asks.';
}

/// The yearly recusancy fine, in florins.
int eraRecusantFine(Life l, EraRules era) => max(
  1,
  (((era.faithData['recusantFine'] as int?) ?? 3) * era.priceLevel(l.year))
      .round(),
);

/// One year of faith at a birthday: standing fades without practice, and
/// England's church changes with the Crown.
List<String> eraFaithYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  if (eraFaithOf(l).isEmpty) eraFaithAtBirth(l, era, rng);
  final last = l.eraWorld['practised'] as int?;
  if (eraStanding(l) > 0 && (last == null || l.year - last >= 2)) {
    l.eraWorld['standing'] = eraStanding(l) - 1;
  }
  if (eraFaithOf(l) == 'english') {
    final was = l.eraWorld['churchName'] as String?;
    final now = eraFaithName(l, era).replaceAll(' (recusant)', '');
    if (was != null && was != now && l.age >= 6) {
      out.add(
        now == 'Catholic'
            ? 'By order of the Crown, the Mass is back in every parish church.'
            : 'By order of the Crown, the church is the Church of England again. The old altars come down.',
      );
    }
    l.eraWorld['churchName'] = now;
    if (eraRecusant(l) && l.year >= 1559 && l.age >= 16) {
      final fine = eraRecusantFine(l, era);
      final paid = min(fine, max(0, l.money));
      l.money -= paid;
      if (paid > 0) l.lastYear.add(('Recusancy fines', -paid));
    }
  }
  return out;
}
