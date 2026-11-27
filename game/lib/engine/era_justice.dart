/// The law in an era life (Legends plan §5.5, Phase 2C): the denunciation
/// drum as heat, the era's crimes, courts and sentences, hearings with a
/// petition for grace or sanctuary, and era prisons and the galleys. Only
/// timeline lives reach this file; the modern justice, policing and prison
/// systems never run in them, and this never runs in a modern life.
///
/// Executions never happen to the player: the worst sentences are years in
/// prison, the galleys and banishment (plan §10.4).
library;

import 'dart:math';

import 'currency.dart';
import 'era_faith.dart' show eraStanding, eraFaithOf;
import 'era_path.dart' show eraStatus;
import 'eras.dart';
import 'models.dart';
import 'storylet.dart';

/// Heat: how many denunciations sit against your name (0 to 5).
int eraHeat(Life l) => (l.eraWorld['heat'] as int?) ?? 0;

void _heat(Life l, int by) =>
    l.eraWorld['heat'] = (eraHeat(l) + by).clamp(0, 5).toInt();

/// Your record: dated lines, newest last.
List<String> eraRecord(Life l) =>
    List<String>.from((l.eraWorld['record'] as List?) ?? const []);

void _record(Life l, String line) =>
    l.eraWorld['record'] = [...eraRecord(l), '${l.year}: $line'];

/// Where you are held, if anywhere: kind (prison, debt or galleys), name,
/// years left, debt, whether you pay the jailer, and why.
Map<String, dynamic>? eraInsideOf(Life l) {
  final m = l.eraWorld['inside'];
  return m == null ? null : Map<String, dynamic>.from(m as Map);
}

bool eraInside(Life l) => l.eraWorld['inside'] != null;

/// The hearing waiting for you, if you were caught.
Map<String, dynamic>? eraHearingOf(Life l) {
  final m = l.eraWorld['hearing'];
  return m == null ? null : Map<String, dynamic>.from(m as Map);
}

/// The court of this place and year, with its officers and its drum.
Map<String, dynamic> eraCourt(Life l, EraRules era) =>
    eraFirst(era.lawData['courts'] as List?, l, era) ??
    {
      'court': 'the magistrates',
      'officers': 'the watch',
      'drum': 'denunciations',
      'drumAbout': 'Each denunciation adds heat to your name.',
      'named': 'Someone denounced you to the magistrates.',
    };

/// The prison of this place, or null where there is none (Kongo and
/// Ndongo punish with fines and banishment).
String? eraPrisonName(Life l, EraRules era, {bool debt = false}) {
  final p = eraFirst(era.lawData['prisons'] as List?, l, era);
  if (p == null) return null;
  return debt ? (p['debt'] as String? ?? p['name']) : p['name'] as String;
}

Map<String, dynamic>? _prison(Life l, EraRules era) =>
    eraFirst(era.lawData['prisons'] as List?, l, era);

/// The galleys this place sends men to, if any.
String? eraGalleysName(Life l, EraRules era) =>
    eraFirst(era.lawData['galleys'] as List?, l, era)?['name'] as String?;

String _money(Life l, int florins) => moneyIn(florins, l.country);

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// One of the era's crimes, as it is called here.
typedef EraCrime = ({
  String id,
  String label,
  String about,
  int heat,
  double catchOdds,
  Map<String, dynamic> data,
});

String _labelHere(Map j, Life l, EraRules era) {
  final labels = Map<String, dynamic>.from((j['labels'] as Map?) ?? const {});
  final region = era.regionOf(l);
  return (labels[region.id] ?? labels[region.group] ?? j['label']) as String;
}

/// The crimes open to this life here and now.
List<EraCrime> eraCrimes(Life l, EraRules era) => [
  for (final raw in (era.lawData['crimes'] as List?) ?? const [])
    if (eraScoped(raw as Map, l, era) &&
        l.age >= ((raw['minAge'] as int?) ?? 14) &&
        (raw['sex'] == null || raw['sex'] == l.gender))
      (
        id: raw['id'] as String,
        label: _labelHere(raw, l, era),
        about: _sentenceAbout(Map<String, dynamic>.from(raw), l, era),
        heat: (raw['heat'] as int?) ?? 1,
        catchOdds: ((raw['catch'] as num?) ?? 0.3).toDouble(),
        data: Map<String, dynamic>.from(raw),
      ),
];

String _sentenceAbout(Map<String, dynamic> c, Life l, EraRules era) {
  final s = Map<String, dynamic>.from(c['sentence'] as Map);
  final prison = eraPrisonName(l, era);
  return switch (s['kind']) {
    'fine' => s['orPrison'] != null && prison != null
        ? 'A fine, or $prison'
        : 'A fine',
    'prison' => prison == null ? 'A heavy fine' : _cap(prison),
    'galleys' =>
      eraGalleysName(l, era) != null && l.gender == 'male'
          ? _cap(eraGalleysName(l, era)!)
          : (prison == null ? 'A heavy fine' : 'Years in $prison'),
    _ => c['about'] as String? ?? '',
  };
}

/// Why this life can't break the law now, or null.
String? eraLawLock(Life l) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 10) return 'From age 10.';
  if (eraInside(l)) return 'Not while you are held.';
  if (eraHearingOf(l) != null) return 'Your hearing comes first.';
  return null;
}

/// How likely the watch is to catch [c] this year (more heat, more
/// eyes; a doubled watch in the news).
double eraCatchOdds(Life l, EraCrime c) {
  final watch = ((l.eraWorld['news'] as Map?)?['watch'] as int?) ?? 0;
  return (c.catchOdds * (1 + eraHeat(l) * 0.1) * (1 + watch * 0.25)).clamp(
    0.05,
    0.9,
  );
}

/// Does [id]: may gain money, adds heat, and may be caught, which queues a
/// hearing (scenes: era_hearing).
String commitEraCrime(Life l, EraRules era, String id, Random rng) {
  final lock = eraLawLock(l);
  if (lock != null) return lock;
  final c = eraCrimes(l, era).where((c) => c.id == id).firstOrNull;
  if (c == null) return 'Not here, not now.';
  if (!eraOnce(l, 'era_crime_$id')) return 'Not again this year.';
  final d = c.data;
  l.eraWorld['lastCrime'] = l.year;
  l.reason = c.label;
  final parts = <String>[];
  final gain = d['gain'] as List?;
  var got = 0;
  if (gain != null) {
    final lo = gain[0] as int, hi = gain[1] as int;
    got = (lo + rng.nextInt(hi - lo + 1)) * era.regionOf(l).priceScale ~/ 1;
    got = max(1, got);
  }
  if (d['gamble'] == true) got = rng.nextInt(7) - 2;
  if (got != 0) {
    l.money += got;
    parts.add(
      got > 0
          ? 'You came away with ${_money(l, got)}.'
          : 'You lost ${_money(l, -got)} on the dice.',
    );
  }
  if (d['joy'] != null) l.stats.add('happiness', d['joy'] as int);
  if (d['hurt'] != null) {
    l.stats.add('health', -(d['hurt'] as int));
    parts.add('You came home with a split lip.');
  }
  // Witnesses talk: heat rises.
  _heat(l, c.heat);
  final court = eraCourt(l, era);
  if (rng.nextDouble() < eraCatchOdds(l, c)) {
    l.eraWorld['hearing'] = {
      'crime': c.id,
      'label': c.label,
      'sentence': d['sentence'],
    };
    l.sceneQueue.add('era_hearing');
    parts.add('${_cap(court['officers'] as String)} caught you.');
    l.feed.add(
      FeedEntry(l.age, '${c.label}: you were caught.', kind: 'milestone'),
    );
  } else {
    parts.add('No one stopped you. Heat on your name: ${eraHeat(l)} of 5.');
  }
  return '${_intro(c.id)} ${parts.join(' ')}';
}

String _intro(String id) => switch (id) {
  'blade' => 'You went out after the bell with a blade under your cloak.',
  'brawl' => 'Words became fists outside the tavern.',
  'dice' => 'You threw the dice where the law says you must not.',
  'theft' => 'In the crush of the market, a purse found its way to you.',
  'smuggle' => 'You slipped the load past the toll-takers at dusk.',
  'clip' => 'You shaved the edges of good coins, a little at a time.',
  _ => 'You did it.',
};

/// The bribe that loses a denunciation, as it is called here.
({String label, int cost}) eraBribe(Life l, EraRules era) {
  final b = Map<String, dynamic>.from(
    (era.lawData['bribe'] as Map?) ?? const {},
  );
  final labels = Map<String, dynamic>.from((b['labels'] as Map?) ?? const {});
  final court = eraCourt(l, era)['court'] as String;
  final label =
      (labels[era.regionOf(l).id] as String?) ??
      (b['label'] as String? ?? 'Bribe a clerk of {court}').replaceAll(
        '{court}',
        court.replaceFirst('the ', 'the '),
      );
  final cost = era.price('living_year', era.regionOf(l), l.year) *
      ((b['cost'] as int?) ?? 8) ~/
      9;
  return (label: label, cost: max(2, cost));
}

/// Pays a clerk to lose a denunciation.
String bribeEraClerk(Life l, EraRules era, Random rng) {
  final lock = eraLawLock(l);
  if (lock != null) return lock;
  if (eraHeat(l) == 0) return 'There is nothing against your name to lose.';
  final b = eraBribe(l, era);
  if (l.money < b.cost) return 'Needs ${_money(l, b.cost)}.';
  if (!eraOnce(l, 'era_bribe')) return 'Not again this year.';
  l.money -= b.cost;
  final odds =
      ((era.lawData['bribe'] as Map?)?['catch'] as num?)?.toDouble() ?? 0.15;
  if (rng.nextDouble() < odds) {
    _heat(l, 2);
    _record(l, 'tried to bribe a clerk, and was reported');
    return 'The clerk took your money and reported you. Heat: ${eraHeat(l)} of 5.';
  }
  _heat(l, -1);
  return 'A denunciation went missing from the pile. Heat: ${eraHeat(l)} of 5.';
}

// ---------------- Hearings and sentences ----------------

String _sentenceText(Map s, Life l, EraRules era) {
  final kind = s['kind'];
  final galleys = eraGalleysName(l, era);
  final prison = eraPrisonName(l, era);
  if (kind == 'galleys' && galleys != null && l.gender == 'male') {
    return '${s['years']} years on $galleys';
  }
  if (kind == 'galleys' || kind == 'prison') {
    final years = (kind == 'galleys' ? s['orPrison'] : s['years']) as int? ?? 1;
    if (prison == null) return 'a fine of ${_money(l, _fineFor(l, era, years * 6))}';
    return years == 1 ? 'a year in $prison' : '$years years in $prison';
  }
  return 'a fine of ${_money(l, _fineFor(l, era, s['amount'] as int? ?? 2))}';
}

int _fineFor(Life l, EraRules era, int base) => max(
  1,
  (base * era.regionOf(l).priceScale * era.priceLevel(l.year)).round(),
);

/// Ways out of a hearing here: petition for grace, sanctuary or flight.
String _graceLabel(Life l, EraRules era) {
  final g = era.regionOf(l).group;
  return switch (g) {
    'italy' || 'islands' => 'Petition for grace (grazia)',
    'england' => 'Petition for a pardon',
    'kongo' => 'Ask the elders for mercy',
    _ => 'Ask the qadi for mercy',
  };
}

bool _sanctuaryHere(Life l, EraRules era) {
  final s = Map<String, dynamic>.from(
    (era.lawData['sanctuary'] as Map?) ?? const {},
  );
  final g = era.regionOf(l).group;
  if (g == 'england') return l.year <= ((s['englandTo'] as int?) ?? 1539);
  if (g == 'iberia' && eraFaithOf(l) == 'muslim') return false;
  return ((s['groups'] as List?) ?? const []).contains(g);
}

/// The hearing, as a Life-tab event: accept the sentence, petition, take
/// sanctuary or leave the city. Built by scenes.dart from 'era_hearing'.
Storylet? eraHearingScene(Life l) {
  final era = eraRegistry[l.era];
  final h = eraHearingOf(l);
  if (era == null || h == null) return null;
  final court = eraCourt(l, era);
  final s = Map<String, dynamic>.from(h['sentence'] as Map);
  final sentence = _sentenceText(s, l, era);
  final why = h['crime'] == 'denounced'
      ? 'The denunciations against you have piled up.'
      : 'You are charged: ${(h['label'] as String).toLowerCase()}.';
  return Storylet(
    id: 'scene:era_hearing',
    scene: true,
    // Not 'crime': that would put on the modern Back Alley look.
    category: 'life',
    text:
        'Before ${court['court']}. $why The sentence will be $sentence.',
    choices: [
      Choice(
        label: 'Accept the sentence',
        outcome: '',
        run: (life, rng) => resolveEraHearing(life, era, 'accept', rng),
      ),
      Choice(
        label: _graceLabel(l, era),
        outcome: '',
        risk: 'Risky',
        run: (life, rng) => resolveEraHearing(life, era, 'grace', rng),
      ),
      if (_sanctuaryHere(l, era))
        Choice(
          label: 'Take sanctuary in a church',
          outcome: '',
          run: (life, rng) => resolveEraHearing(life, era, 'sanctuary', rng),
        ),
      Choice(
        label: 'Leave ${l.city} before they come',
        outcome: '',
        run: (life, rng) => resolveEraHearing(life, era, 'flee', rng),
      ),
    ],
  );
}

/// The odds a petition for grace is granted: your standing at church or
/// mosque, your family's rank, and how much is against you.
double eraGraceOdds(Life l) =>
    (0.3 + eraStanding(l) * 0.06 + eraStatus(l) * 0.06 - eraHeat(l) * 0.04)
        .clamp(0.1, 0.8);

String resolveEraHearing(Life l, EraRules era, String how, Random rng) {
  final h = eraHearingOf(l);
  if (h == null) return 'There is no hearing.';
  l.eraWorld.remove('hearing');
  final s = Map<String, dynamic>.from(h['sentence'] as Map);
  final label = (h['label'] as String).toLowerCase();
  switch (how) {
    case 'grace':
      if (rng.nextDouble() < eraGraceOdds(l)) {
        _heat(l, -1);
        _record(l, '$label. Pardoned on petition');
        l.stats.add('happiness', 6);
        return 'The petition was granted. You walked out a free person, '
            'with a warning.';
      }
      final text = _apply(l, era, s, label, rng);
      return 'The petition was refused. $text';
    case 'sanctuary':
      _record(l, '$label. Took sanctuary');
      l.stats.add('happiness', -5);
      l.eraWorld['lastCrime'] = l.year;
      return 'You ran for the church door and claimed sanctuary. No officer '
          'may take you from it. You came out weeks later, thinner, and '
          'the charge still stands against your name.';
    case 'flee':
      return _flee(l, era, label, rng);
    default:
      return _apply(l, era, s, label, rng);
  }
}

String _flee(Life l, EraRules era, String label, Random rng) {
  final from = l.city;
  final here = era.regionOf(l);
  // Another state of the same part of the world, or another town here.
  final away = [
    for (final r in era.regionsIn(l.year))
      if (r.group == here.group && r.id != here.id)
        for (final c in r.citiesIn(l.year)) (r, c),
  ];
  final near = [
    for (final c in here.citiesIn(l.year))
      if (c != from) (here, c),
  ];
  final options = away.isNotEmpty ? away : near;
  if (options.isEmpty) return _apply(l, era, {'kind': 'fine', 'amount': 4}, label, rng);
  final (region, city) = options[rng.nextInt(options.length)];
  l.city = city;
  l.country = region.nameIn(l.year);
  l.eraWorld['banished'] = {'city': from, 'until': l.year + 5};
  l.eraWorld['heat'] = 1;
  l.job = null;
  l.salary = 0;
  _record(l, '$label. Fled $from; banished for five years');
  l.stats.add('happiness', -8);
  return 'You left $from that night with what you could carry, and came to '
      '$city. Back home you are banished for five years.';
}

/// Applies a sentence: a fine (or the debtors' ward if you can't pay),
/// prison, or the galleys.
String _apply(
  Life l,
  EraRules era,
  Map<String, dynamic> s,
  String label,
  Random rng,
) {
  final kind = s['kind'] as String? ?? 'fine';
  final prison = eraPrisonName(l, era);
  final galleys = eraGalleysName(l, era);
  _heat(l, -2);
  if (kind == 'galleys' && galleys != null && l.gender == 'male') {
    final years = s['years'] as int? ?? 3;
    _hold(l, 'galleys', galleys, years: years, why: label);
    _record(l, '$label. $years years on $galleys');
    l.stats.add('happiness', -12);
    return 'You were sent to row on $galleys for $years years, chained to '
        'the bench with the others.';
  }
  if (kind == 'galleys' || kind == 'prison') {
    final years = (kind == 'galleys' ? s['orPrison'] : s['years']) as int? ?? 1;
    if (prison == null) {
      return _fine(l, era, _fineFor(l, era, years * 6), label, prison);
    }
    _hold(l, 'prison', prison, years: years, why: label);
    _record(l, '$label. ${years == 1 ? 'A year' : '$years years'} in $prison');
    l.stats.add('happiness', -10);
    return 'You were taken to $prison for '
        '${years == 1 ? 'a year' : '$years years'}.';
  }
  final fine = _fineFor(l, era, s['amount'] as int? ?? 2);
  final or = s['orPrison'] as int?;
  if (l.money < fine && or != null && prison != null) {
    _hold(l, 'prison', prison, years: or, why: label);
    _record(l, '$label. Could not pay the fine; ${or == 1 ? 'a year' : '$or years'} in $prison');
    return 'You could not pay the fine of ${_money(l, fine)}, so you were '
        'taken to $prison.';
  }
  return _fine(l, era, fine, label, prison);
}

String _fine(Life l, EraRules era, int fine, String label, String? prison) {
  if (l.money >= fine) {
    l.money -= fine;
    _record(l, '$label. Fined ${_money(l, fine)}');
    l.stats.add('happiness', -3);
    return 'You paid a fine of ${_money(l, fine)}.';
  }
  final paid = max(0, l.money);
  l.money -= paid;
  final debtPrison = eraPrisonName(l, era, debt: true);
  if (debtPrison != null) {
    _hold(l, 'debt', debtPrison, debt: fine - paid, why: label);
    _record(l, '$label. Fined ${_money(l, fine)}; held for the debt');
    return 'You could not pay all of the fine. You are held in '
        '$debtPrison until the ${_money(l, fine - paid)} still owed is paid.';
  }
  _record(l, '$label. Fined ${_money(l, fine)}; your family paid the rest');
  for (final n in l.npcs.where((n) => n.alive && n.circle == 'Family')) {
    n.addBond(-6);
  }
  return 'You could not pay all of the fine. Your family made up the rest, '
      'and they will not forget it.';
}

void _hold(
  Life l,
  String kind,
  String name, {
  int years = 0,
  int debt = 0,
  required String why,
}) {
  l.eraWorld['inside'] = {
    'kind': kind,
    'name': name,
    'left': years,
    'debt': debt,
    'fed': true,
    'since': l.year,
    'why': why,
  };
  l.feed.add(
    FeedEntry(
      l.age,
      kind == 'galleys' ? 'You were sent to $name.' : 'You were taken to $name.',
      kind: 'milestone',
    ),
  );
}

// ---------------- Inside ----------------

/// What the jailer charges a year for bread and a blanket.
int eraJailerFee(Life l, EraRules era) => max(
  1,
  (((era.lawData['jailerFee'] as int?) ?? 3) *
          era.regionOf(l).priceScale *
          era.priceLevel(l.year))
      .round(),
);

/// Pay the jailer for food, or go without.
String setEraFed(Life l, EraRules era, bool fed) {
  final m = eraInsideOf(l);
  if (m == null || m['kind'] == 'galleys') return 'Not here.';
  if (fed && l.money < eraJailerFee(l, era)) {
    return 'Needs ${_money(l, eraJailerFee(l, era))} a year.';
  }
  m['fed'] = fed;
  l.eraWorld['inside'] = m;
  return fed
      ? 'You pay the jailer: bread, a blanket and a place by the wall.'
      : 'You keep your coins and eat what the charity brings.';
}

/// Pays off what you owe and walks out of the debtors' ward.
String payEraDebt(Life l, EraRules era) {
  final m = eraInsideOf(l);
  if (m == null || m['kind'] != 'debt') return 'You owe nothing.';
  final debt = m['debt'] as int? ?? 0;
  if (l.money < debt) return 'Needs ${_money(l, debt)}.';
  l.money -= debt;
  _release(l);
  return 'You paid the ${_money(l, debt)} and walked out into the street.';
}

/// Begs at the grate: a few coins from passers-by.
String begAtGrate(Life l, EraRules era, Random rng) {
  final m = eraInsideOf(l);
  if (m == null || m['kind'] == 'galleys') return 'Not here.';
  if (!eraOnce(l, 'era_beg')) return 'Not again this year.';
  final got = 1 + rng.nextInt(2);
  l.money += got;
  l.stats.add('happiness', -2);
  return 'You held a bag on a string through the grate. Passers-by dropped '
      '${_money(l, got)} into it.';
}

/// Petitions for release from inside: your guild, your family, your
/// standing. Once a year.
String petitionFromInside(Life l, EraRules era, Random rng) {
  final m = eraInsideOf(l);
  if (m == null) return 'You are free.';
  if (!eraOnce(l, 'era_petition')) return 'Not again this year.';
  final guild = l.job != null ? 0.08 : 0.0;
  if (rng.nextDouble() < eraGraceOdds(l) * 0.6 + guild) {
    _record(l, 'released on petition');
    _release(l);
    l.stats.add('happiness', 10);
    return 'Your petition was read and granted. You are free.';
  }
  return 'The petition went up. No answer came back this year.';
}

/// Asks someone to visit: bread, news and a stronger bond.
String askToVisit(Life l, Npc n, Random rng) {
  if (!eraInside(l)) return 'You are free.';
  if (!eraOnce(l, 'era_visit_${n.id}')) return 'Not again this year.';
  if (n.bond < 25) {
    n.addBond(-2);
    return '${n.name.split(' ').first} did not come.';
  }
  n.addBond(6);
  l.stats.add('happiness', 5);
  l.stats.add('health', 1);
  return '${n.name.split(' ').first} came with bread and news from outside.';
}

void _release(Life l) {
  final m = eraInsideOf(l);
  l.eraWorld.remove('inside');
  if (m != null) {
    l.feed.add(
      FeedEntry(
        l.age,
        m['kind'] == 'galleys'
            ? 'Your years on the galleys are over. You came ashore.'
            : 'You walked out of ${m['name']}.',
        kind: 'milestone',
      ),
    );
  }
}

/// The feast-day release of the place's prison, if it has one.
String? eraFeastRelease(Life l, EraRules era) =>
    _prison(l, era)?['feast'] as String?;

// ---------------- The year ----------------

/// One year of the law at a birthday: time served, the jailer, visits and
/// release; heat cooling; neighbours dropping your name; arrests; and
/// coming back to a city you were banished from.
List<String> eraLawYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  final court = eraCourt(l, era);
  // A hearing left unanswered goes ahead without you.
  if (eraHearingOf(l) != null && !l.sceneQueue.contains('era_hearing')) {
    out.add(resolveEraHearing(l, era, 'accept', rng));
  }
  final inside = eraInsideOf(l);
  if (inside != null) {
    final kind = inside['kind'] as String;
    if (kind == 'galleys') {
      l.stats.add('health', -6);
      l.stats.add('happiness', -4);
    } else {
      final fee = eraJailerFee(l, era);
      if (inside['fed'] == true && l.money >= fee) {
        l.money -= fee;
        l.lastYear.add(('The jailer', -fee));
      } else {
        inside['fed'] = false;
        l.stats.add('health', -8);
        out.add('Without the jailer\'s bread you went hungry most days.');
      }
      // Charity: confraternities and the community bring bread.
      if (rng.nextDouble() < 0.5) {
        l.stats.add('health', 2);
        out.add(switch (era.regionOf(l).group) {
          'italy' || 'islands' =>
            'A confraternity came to the prison with bread and wine.',
          'england' => 'Bread came from a charity of the London parishes.',
          _ => 'Good people brought bread to the prisoners, as charity asks.',
        });
      }
    }
    if (kind == 'debt') {
      // Family, charity and work in the ward chip away at the debt.
      inside['debt'] = (inside['debt'] as int? ?? 0) - eraJailerFee(l, era);
      if ((inside['debt'] as int? ?? 0) <= 0) {
        l.eraWorld['inside'] = inside;
        _release(l);
        return out;
      }
      l.eraWorld['inside'] = inside;
    } else {
      inside['left'] = (inside['left'] as int? ?? 1) - 1;
      l.eraWorld['inside'] = inside;
      final feast = eraFeastRelease(l, era);
      if ((inside['left'] as int) <= 0) {
        _release(l);
      } else if (kind == 'prison' && feast != null && rng.nextDouble() < 0.25) {
        _record(l, 'freed on the feast of St John');
        _release(l);
        out.add('On the feast of St John you were among the prisoners set free.');
      }
    }
    return out;
  }
  // Heat cools when you keep out of trouble.
  final last = l.eraWorld['lastCrime'] as int?;
  if (eraHeat(l) > 0 && (last == null || l.year - last >= 2)) _heat(l, -1);
  // Neighbours with a grudge.
  final standing = eraStanding(l);
  if (l.age >= 16 &&
      rng.nextDouble() <
          (0.015 + (eraHeat(l) >= 3 ? 0.05 : 0)) * (1 - standing * 0.12)) {
    _heat(l, 1);
    out.add(court['named'] as String);
  }
  // Coming home too soon from banishment.
  final ban = l.eraWorld['banished'] as Map?;
  if (ban != null) {
    if (l.year > (ban['until'] as int)) {
      l.eraWorld.remove('banished');
    } else if (l.city == ban['city']) {
      _arrest(l, era, 'Returned from banishment', {'kind': 'prison', 'years': 1});
      out.add('${_cap(court['officers'] as String)} knew you were back. They came for you.');
      return out;
    }
  }
  // Arrest on the denunciations.
  final heat = eraHeat(l);
  if (heat >= 3 &&
      rng.nextDouble() < (heat - 2) * 0.12 * (1 - standing * 0.08)) {
    _arrest(
      l,
      era,
      'Named in too many denunciations',
      heat >= 5
          ? {'kind': 'prison', 'years': 2}
          : heat == 4
          ? {'kind': 'prison', 'years': 1}
          : {'kind': 'fine', 'amount': 4, 'orPrison': 1},
      denounced: true,
    );
    out.add('${_cap(court['officers'] as String)} came for you at night.');
  }
  return out;
}

void _arrest(
  Life l,
  EraRules era,
  String label,
  Map<String, dynamic> sentence, {
  bool denounced = false,
}) {
  l.eraWorld['hearing'] = {
    'crime': denounced ? 'denounced' : 'banished',
    'label': label,
    'sentence': sentence,
  };
  if (!l.sceneQueue.contains('era_hearing')) l.sceneQueue.add('era_hearing');
}

/// Leonardo's real denunciation of 1476 (the drum event): it adds heat and
/// a line on his record, and the dismissal (or the quashing) clears it.
void eraLegendLaw(Life l, String pivot, bool rewritten) {
  if (pivot != 'drum_1476') return;
  if (rewritten) {
    _record(l, 'named in the drum; the accusation was quietly lost');
    _heat(l, 1);
  } else {
    _record(l, 'named in the drum. Heard twice, dismissed');
    _heat(l, 2);
  }
}
