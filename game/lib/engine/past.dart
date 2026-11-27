/// The past changes the modern world (Legends plan §8, Phase 1 bridge).
///
/// When a timeline reaches 2026, or the player links one, it becomes the
/// history of their modern world. Only one is linked at a time. It adds a
/// deep past before 2026 and never rewrites what was already lived in the
/// modern world. Every modern system reads it through [past]:
/// `past.has('milan_holds_1499')`, `past.houseOf(surname)`,
/// `past.founded('university')`, `past.currents`.
///
/// Rules that keep it fair: every effect is small, capped and fades like a
/// news effect; money from the past is normalised; a modern life never
/// needs a linked past. With nothing linked, every hook here returns
/// nothing, and the modern game behaves exactly as before.
library;

import 'dart:math';

import 'legends.dart';
import 'models.dart';
import 'timeline.dart';
import 'world_data.dart' show CountryData;

/// Something that happened in the linked past.
class PastEvent {
  PastEvent(this.year, this.text, {this.big = false, this.effect});
  final int year;
  final String text;

  /// Big events get anniversaries in the news and may carry a small,
  /// fading news effect (a key of worldEffects in world.dart).
  final bool big;
  final String? effect;

  Map<String, dynamic> toJson() => {
    'year': year,
    'text': text,
    if (big) 'big': big,
    if (effect != null) 'effect': effect,
  };
  factory PastEvent.fromJson(Map<String, dynamic> j) => PastEvent(
    j['year'],
    j['text'],
    big: j['big'] ?? false,
    effect: j['effect'],
  );
}

/// A linked timeline, as the modern world remembers it.
class PastRecord {
  PastRecord({
    required this.timelineId,
    required this.era,
    required this.house,
    this.legend,
    Map<String, int>? name,
    Map<String, int>? facts,
    Map<String, int>? currents,
    List<PastEvent>? events,
    List<Map<String, dynamic>>? heirlooms,
    List<Map<String, dynamic>>? buildings,
    List<Map<String, dynamic>>? companies,
    List<Map<String, dynamic>>? institutions,
    List<Map<String, dynamic>>? nations,
    List<Map<String, dynamic>>? rivals,
    List<Map<String, dynamic>>? descendants,
    List<String>? trades,
  }) : name = name ?? {},
       facts = facts ?? {},
       currents = currents ?? {},
       events = events ?? [],
       heirlooms = heirlooms ?? [],
       buildings = buildings ?? [],
       companies = companies ?? [],
       institutions = institutions ?? [],
       nations = nations ?? [],
       rivals = rivals ?? [],
       descendants = descendants ?? [],
       trades = trades ?? [];

  final String timelineId;
  final String era;

  /// Your house: the surname the modern world knows ("Vespri").
  final String house;

  /// The Legend this past was played as, if any ("Leonardo da Vinci").
  final String? legend;

  /// Family-name axes carried into World.names (fame, infamy, wealth,
  /// philanthropy, power), 0-100.
  final Map<String, int> name;
  final Map<String, int> facts;

  /// Long currents: Science, Faith, Arts, Mercantile... 0-100.
  final Map<String, int> currents;
  final List<PastEvent> events;

  /// {id, name, value, story}: passed down to modern members of the house.
  final List<Map<String, dynamic>> heirlooms;

  /// {name, kind, built, city, value, forSale}: palazzi, libraries.
  final List<Map<String, dynamic>> buildings;

  /// {id, name, sector, founded, base}: still trading today.
  final List<Map<String, dynamic>> companies;

  /// {name, kind (university, school, academy, faith), founded, city}.
  final List<Map<String, dynamic>> institutions;

  /// {name, founded, cities, male, female, surnames}.
  final List<Map<String, dynamic>> nations;

  /// Rival houses: {house, feud (bool), trade, wealth, power}.
  final List<Map<String, dynamic>> rivals;

  /// Modern descendants who know the story: {name, house, role, feud}.
  final List<Map<String, dynamic>> descendants;

  /// Careers your house was known for (career ids in careers.dart).
  final List<String> trades;

  Map<String, dynamic> toJson() => {
    'timelineId': timelineId,
    'era': era,
    'house': house,
    if (legend != null) 'legend': legend,
    'name': name,
    'facts': facts,
    'currents': currents,
    'events': [for (final e in events) e.toJson()],
    'heirlooms': heirlooms,
    'buildings': buildings,
    'companies': companies,
    'institutions': institutions,
    'nations': nations,
    'rivals': rivals,
    'descendants': descendants,
    'trades': trades,
  };

  static List<Map<String, dynamic>> _maps(dynamic raw) => [
    for (final m in (raw as List?) ?? const []) Map<String, dynamic>.from(m),
  ];

  factory PastRecord.fromJson(Map<String, dynamic> j) => PastRecord(
    timelineId: j['timelineId'],
    era: j['era'],
    house: j['house'],
    legend: j['legend'],
    name: Map<String, int>.from(j['name'] ?? const {}),
    facts: Map<String, int>.from(j['facts'] ?? const {}),
    currents: Map<String, int>.from(j['currents'] ?? const {}),
    events: [
      for (final e in (j['events'] as List?) ?? const [])
        PastEvent.fromJson(Map<String, dynamic>.from(e)),
    ],
    heirlooms: _maps(j['heirlooms']),
    buildings: _maps(j['buildings']),
    companies: _maps(j['companies']),
    institutions: _maps(j['institutions']),
    nations: _maps(j['nations']),
    rivals: _maps(j['rivals']),
    descendants: _maps(j['descendants']),
    trades: List<String>.from(j['trades'] ?? const []),
  );

  /// The past left by a finished Legend life and its timeline. What the
  /// Legend leaves behind is data in its file ("legacy"); entries with a
  /// "fact" only count when that fact is true in this history.
  factory PastRecord.fromLegendLife(Life life, Timeline t, Legend legend) {
    bool holds(Map<String, dynamic> m) =>
        m['fact'] == null ||
        t.has(m['fact']) ||
        life.flags.containsKey(m['fact']) ||
        life.flags.containsKey('fact:${m['fact']}');
    List<Map<String, dynamic>> pick(String key) => [
      for (final m in PastRecord._maps(legend.legacy[key]))
        if (holds(m)) m..remove('fact'),
    ];
    final fate = legend.fates.where((f) => f.id == life.fate).firstOrNull;
    final rewritten = life.pivots.values.where((v) => v == 'rewritten').length;
    return PastRecord(
      timelineId: t.id,
      era: t.era,
      house: legend.house ?? legend.surname,
      legend: legend.name,
      name: {
        'fame': (40 + life.codex.length * 3).clamp(0, 60),
        'wealth': (life.money ~/ 50).clamp(0, 30),
        'power': (rewritten * 10).clamp(0, 30),
      },
      facts: Map.of(t.facts),
      currents: Map.of(t.currents),
      events: [
        for (final line in t.log)
          if (RegExp(r'^(\d{3,4}): (.+)$').firstMatch(line) case final m?)
            PastEvent(int.parse(m[1]!), m[2]!, big: true),
        if (fate != null)
          PastEvent(life.year, '${legend.firstName} ${legend.surname} died: ${fate.title}'),
      ],
      heirlooms: pick('heirlooms'),
      buildings: pick('buildings'),
      companies: pick('companies'),
      institutions: pick('institutions'),
      nations: pick('nations'),
      rivals: pick('rivals'),
      descendants: pick('descendants'),
      trades: List<String>.from(legend.legacy['trades'] ?? const []),
    );
  }
}

/// The one way modern systems read the linked past.
class PastView {
  PastRecord? active;

  bool get linked => active != null;

  /// Is this fact true in the linked history?
  bool has(String fact) => active?.facts.containsKey(fact) ?? false;

  /// The past's view of a surname: your house or a rival house, with its
  /// name axes; null if the past never heard of it.
  Map<String, dynamic>? houseOf(String surname) {
    final p = active;
    if (p == null) return null;
    if (p.house == surname) return {'house': p.house, 'mine': true, ...p.name};
    for (final r in p.rivals) {
      if (r['house'] == surname) return {...r, 'mine': false};
    }
    return null;
  }

  /// The first thing of [kind] your house founded (university, school,
  /// academy, faith, company, palazzo, nation...).
  Map<String, dynamic>? founded(String kind) {
    final p = active;
    if (p == null) return null;
    if (kind == 'company') return p.companies.firstOrNull;
    if (kind == 'nation') return p.nations.firstOrNull;
    return [
      ...p.institutions,
      ...p.buildings,
    ].where((m) => m['kind'] == kind).firstOrNull;
  }

  Map<String, int> get currents => active?.currents ?? const {};

  /// A modern life belongs to the house by surname or by blood.
  bool ofHouse(Life l) =>
      active != null &&
      (l.surname == active!.house || l.flags.containsKey('house_blood'));

  /// The house that feuded with yours, if any.
  Map<String, dynamic>? get feud =>
      active?.rivals.where((r) => r['feud'] == true).firstOrNull;
}

/// The linked past. Set from World.past whenever the engine's world is set.
final past = PastView();

// ---------------- News: "From history" ----------------

/// Events with a round anniversary this year (every 25 years).
List<PastEvent> anniversaries(int year) => [
  for (final e in past.active?.events ?? const <PastEvent>[])
    if (year > e.year && (year - e.year) % 25 == 0) e,
];

/// "525 years ago, Milan held against France."
String historyLine(PastEvent e, int year) {
  final t = e.text;
  return '${year - e.year} years ago, ${t[0].toLowerCase()}${t.substring(1)}${t.endsWith('.') ? '' : '.'}';
}

/// The "From history" column for a year: anniversaries first, then the
/// oldest facts of your house.
List<String> historyColumn(int year, {int max = 3}) {
  final out = [for (final e in anniversaries(year)) historyLine(e, year)];
  final p = past.active;
  if (p != null && out.length < max) {
    for (final e in p.events.where((e) => e.big)) {
      final line = 'In ${e.year}: ${e.text}';
      if (!out.contains(line)) out.add(line);
      if (out.length >= max) break;
    }
  }
  return out.take(max).toList();
}

/// Small, fading effects from big anniversaries: half a normal news
/// effect, for that year only, capped at ±3.
Map<String, int> pastMods(
  int year,
  Map<String, Map<String, int>> effects,
) {
  final out = <String, int>{};
  for (final e in anniversaries(year)) {
    if (!e.big || e.effect == null) continue;
    for (final m in (effects[e.effect] ?? const {}).entries) {
      out[m.key] = (out[m.key] ?? 0) + m.value ~/ 2;
    }
  }
  return out.map((k, v) => MapEntry(k, v.clamp(-3, 3)));
}

// ---------------- Family names ----------------

/// What linking adds to World.names, capped so a past can never make a
/// name more than well known.
Map<String, Map<String, int>> pastNames() {
  final p = past.active;
  if (p == null) return const {};
  Map<String, int> axes(Map m) => {
    for (final k in const ['fame', 'infamy', 'wealth', 'philanthropy', 'power'])
      if ((m[k] as int? ?? 0) > 0) k: (m[k] as int).clamp(0, 60),
  };
  return {
    p.house: axes(p.name),
    for (final r in p.rivals) r['house'] as String: axes(r),
  };
}

// ---------------- The Echelon: old money ----------------

/// Old-money houses (yours and your rivals') for the rich list:
/// (name, sector, volatility, she).
List<(String, String, double, bool)> oldMoneyRivals() {
  final p = past.active;
  if (p == null) return const [];
  return [
    for (final r in p.rivals)
      if ((r['wealth'] as int? ?? 0) >= 40)
        (
          'The ${r['house']} family',
          'Old money since ${r['since'] ?? p.events.firstOrNull?.year ?? 1500}'
              '${r['trade'] != null ? ' (${r['trade']})' : ''}',
          0.08,
          false,
        ),
  ];
}

/// A once-only line when an old-money house notices a rich member of yours.
String? oldMoneyLine(Life l) {
  final p = past.active;
  if (p == null || !past.ofHouse(l) || l.marks.contains('past:old_money')) {
    return null;
  }
  final ally = p.rivals.where((r) => r['feud'] != true).firstOrNull;
  if (ally == null) return null;
  l.marks.add('past:old_money');
  return 'An invitation on heavy paper: the ${ally['house']} family, old money '
      'since your ancestors\' day, would like to meet a ${p.house} again.';
}

// ---------------- Careers ----------------

/// The family trade bonus, in percent of pay (at most 5%).
int pastTradeBonus(Life l, String careerId) =>
    past.ofHouse(l) && past.active!.trades.contains(careerId) ? 5 : 0;

/// A Hub line about your ancestors, once per career.
String? ancestorHubLine(Life l) {
  final p = past.active;
  final id = l.careerId;
  if (p == null || id == null || l.marks.contains('past:hub:$id')) return null;
  final who = p.legend ?? 'the ${p.house} house';
  String? line;
  if (id == 'actor') {
    line = 'A casting call for a period drama about $who. '
        '${past.ofHouse(l) ? 'They want a real ${p.house} for the part.' : 'You read for it.'}';
  } else if (past.ofHouse(l) && p.trades.contains(id)) {
    line = 'An old colleague smiles at your surname: "A ${p.house} in this '
        'trade again. Your family was doing this centuries ago."';
  }
  if (line != null) l.marks.add('past:hub:$id');
  return line;
}

// ---------------- Property ----------------

/// Buildings of your house that come up for sale: (name, kind, built,
/// price). Shown as a rare listing; always for a member of the house.
List<Map<String, dynamic>> pastListings(Life l) {
  final p = past.active;
  if (p == null) return const [];
  final rng = Random(l.seed * 41 + l.age * 13);
  return [
    for (final b in p.buildings)
      if (b['forSale'] == true && (past.ofHouse(l) || rng.nextInt(100) < 20))
        b,
  ];
}

/// A once-only landmark line in a life's city.
String? landmarkLine(Life l) {
  final p = past.active;
  if (p == null || l.marks.contains('past:landmark') || l.age < 8) {
    return null;
  }
  final b = p.buildings.firstOrNull;
  if (b == null) return null;
  l.marks.add('past:landmark');
  return past.ofHouse(l)
      ? 'A school trip to the ${b['name']}, built by your ancestors in ${b['built']}. '
            'Your surname is carved over the door.'
      : 'Tourists queue outside the ${b['name']}, built by the ${p.house} family in ${b['built']}.';
}

// ---------------- Possessions: heirlooms ----------------

/// Heirlooms passed down to a modern member of the house. Their value is
/// normalised: never more than a modest windfall.
List<Asset> pastHeirlooms(Life l) {
  final p = past.active;
  if (p == null || !past.ofHouse(l)) return const [];
  return [
    for (final h in p.heirlooms)
      if (!l.assets.any((a) => a.id == 'past_${h['id']}'))
        Asset(
          id: 'past_${h['id']}',
          kind: 'heirloom',
          name: h['name'],
          value: min((h['value'] as int?) ?? 5000, 250000),
          yearlyCost: 0,
          since: l.age,
          info: {
            'history': [h['story'] ?? 'Passed down in the ${p.house} family'],
            'past': true,
          },
        ),
  ];
}

// ---------------- Crime ----------------

/// The feud house's name for a modern crime family, if any.
String? feudCrimeFamily() {
  final f = past.feud;
  return f == null ? null : 'The ${f['house']} family';
}

/// An old grudge resurfacing for a member of the house in the underworld.
String? grudgeLine(Life l, Random rng) {
  final f = past.feud;
  if (f == null || !past.ofHouse(l) || l.marks.contains('past:grudge')) {
    return null;
  }
  if (rng.nextInt(100) >= 25) return null;
  l.marks.add('past:grudge');
  return 'A man with the ${f['house']} crest on his ring stops you in the '
      'street: "Your family owes mine. We have not forgotten."';
}

// ---------------- Money and stocks ----------------

/// Companies your house founded that still trade, as ticker fields:
/// (id, name, sector, base price, founded).
List<(String, String, String, double, int)> pastCompanies() => [
  for (final c in past.active?.companies ?? const <Map<String, dynamic>>[])
    (
      c['id'] as String,
      c['name'] as String,
      (c['sector'] as String?) ?? 'Finance',
      ((c['base'] as num?) ?? 40).toDouble(),
      (c['founded'] as int?) ?? 1500,
    ),
];

// ---------------- School ----------------

/// A small admissions edge for members of a house that founded a
/// university or academy: +3 points.
int pastAdmissionEdge(Life l) =>
    past.ofHouse(l) &&
        (past.founded('university') != null || past.founded('academy') != null)
    ? 3
    : 0;

// ---------------- Countries ----------------

/// Nations founded in the past, as countries you can move to (Phase 4
/// writes these; the hook is here now).
List<CountryData> pastNations() => [
  for (final n in past.active?.nations ?? const <Map<String, dynamic>>[])
    CountryData(
      name: n['name'],
      cities: List<String>.from(n['cities'] ?? const ['Capital']),
      male: List<String>.from(n['male'] ?? const ['Luca']),
      female: List<String>.from(n['female'] ?? const ['Lucia']),
      surnames: List<String>.from(n['surnames'] ?? [past.active!.house]),
      currency: n['currency'] ?? 'florin',
    ),
];

// ---------------- Health ----------------

/// Long currents nudge life expectancy by at most a year either way:
/// strong Science adds, a world without it takes away. Returns a death
/// chance multiplier (1.0 with no past).
double pastLifespanFactor() {
  final p = past.active;
  if (p == null) return 1;
  final science = p.currents['Science'];
  final faith = p.currents['Faith'];
  if (science == null && faith == null) return 1;
  final years = (((science ?? 50) - 50) / 50 + ((faith ?? 50) - 50) / 200)
      .clamp(-1.0, 1.0);
  // About 8.5% per year of age on the Gompertz curve (lifespan.dart).
  return exp(-0.085 * years);
}

// ---------------- People ----------------

/// Descendants of the Legend and of rival houses who know your name.
List<Npc> pastPeople(Life l, Random rng) {
  final p = past.active;
  if (p == null) return const [];
  final out = <Npc>[];
  for (final d in p.descendants) {
    if (rng.nextInt(100) >= (past.ofHouse(l) ? 60 : 15)) continue;
    final feud = d['feud'] == true;
    final id = 'past_${(d['name'] as String).toLowerCase().replaceAll(' ', '_')}';
    if (l.npc(id) != null) continue;
    final n = Npc(
      id: id,
      role: feud ? 'Family rival' : 'Old family friend',
      name: d['name'],
      circle: 'Friends',
      birthYear: l.birthYear - 30 - rng.nextInt(20),
      bond: feud && past.ofHouse(l) ? 25 : 55,
    )..info['house'] = d['house'];
    n.remember(
      NpcMemory(
        age: 0,
        text: feud
            ? 'the old feud between the ${d['house']} and ${p.house} houses'
            : 'what the ${p.house} house did for theirs, long ago',
        valence: feud ? -2 : 2,
        intensity: 2,
        tags: ['past'],
      ),
    );
    out.add(n);
  }
  return out;
}

// ---------------- Faith ----------------

/// A once-only line about a movement your house started, if it lasted.
String? pastFaithLine(Life l) {
  final f = past.founded('faith');
  if (f == null || l.marks.contains('past:faith') || l.age < 12) return null;
  l.marks.add('past:faith');
  return 'The ${f['name']}, started in ${f['founded']} by the ${past.active!.house} '
      'house, still meets in ${f['city'] ?? 'the old quarter'}.';
}

// ---------------- Recap ----------------

/// The house's history for the Life Recap of a member.
List<String> houseHistory(Life l) {
  final p = past.active;
  if (p == null || !past.ofHouse(l)) return const [];
  return [
    'House ${p.house}${p.legend != null ? ', the line of ${p.legend}' : ''}',
    for (final e in p.events.where((e) => e.big).take(5)) '${e.year}: ${e.text}',
  ];
}
