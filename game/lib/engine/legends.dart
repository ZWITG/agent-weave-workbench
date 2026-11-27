/// Legends (plan §3): playable lives of people from history. A Legend is
/// data (`assets/legends/<id>.json`): who they were, their chapters, the
/// turning points where history can be kept or rewritten, their Fates and
/// their look. The runner here starts the life, fires turning points in
/// their year, keeps the Chronicle and picks the Fate when the life ends.
library;

import 'dart:math';

import 'causes.dart';
import 'eras.dart';
import 'models.dart';
import 'storylet.dart';
import 'timeline.dart';

/// Every Legend file in assets/legends, in load order.
const legendFiles = ['leonardo_test.json'];

/// Loaded Legends by id; filled by the game controller (and tests).
final Map<String, Legend> legendRegistry = {};

class LegendChapter {
  LegendChapter(this.title, this.from, this.to);
  final String title;
  final int from;
  final int to;
}

/// A turning point: the year it happens and what really happened.
class TurningPoint {
  TurningPoint({
    required this.id,
    required this.year,
    required this.title,
    required this.history,
  });
  final String id;
  final int year;
  final String title;

  /// The Codex card: "What really happened".
  final String history;
}

/// How a Legend life can end, and what it takes.
class Fate {
  Fate({
    required this.id,
    required this.title,
    required this.text,
    this.facts = const [],
    this.notFacts = const [],
    this.chronicleMin = 0,
    this.chronicleMax = 100,
    this.unfinished = false,
  });

  /// Only for a life that ended before all its turning points came.
  final bool unfinished;
  final String id;
  final String title;
  final String text;
  final List<String> facts;
  final List<String> notFacts;
  final int chronicleMin;
  final int chronicleMax;

  bool fits(Life life, Timeline? t) {
    final legend = legendRegistry[life.legendId];
    final open =
        legend?.turningPoints.any((p) => !life.pivots.containsKey(p.id)) ??
        false;
    if (unfinished != open) return false;
    bool has(String f) =>
        (t?.has(f) ?? false) ||
        life.flags.containsKey('fact:$f') ||
        life.flags.containsKey(f);
    if (!facts.every(has)) return false;
    if (notFacts.any(has)) return false;
    return life.chronicle >= chronicleMin && life.chronicle <= chronicleMax;
  }

  factory Fate.fromJson(Map<String, dynamic> j) => Fate(
    id: j['id'],
    title: j['title'],
    text: j['text'],
    facts: List<String>.from(j['facts'] ?? const []),
    notFacts: List<String>.from(j['notFacts'] ?? const []),
    chronicleMin: j['chronicleMin'] ?? 0,
    chronicleMax: j['chronicleMax'] ?? 100,
    unfinished: j['unfinished'] ?? false,
  );
}

class Legend {
  Legend({
    required this.id,
    required this.name,
    required this.era,
    required this.firstName,
    required this.surname,
    required this.gender,
    required this.birthYear,
    required this.deathYear,
    required this.region,
    required this.city,
    required this.look,
    required this.chapters,
    required this.turningPoints,
    required this.fates,
    required this.storylets,
    this.house,
    this.npcs = const [],
    this.stats = const {},
    this.money = 0,
    this.codex = const {},
    this.test = false,
    this.skipEvents = const [],
    this.legacy = const {},
  });

  /// What this Legend leaves the modern world (past.dart): heirlooms,
  /// buildings, companies, institutions, rivals, descendants, trades.
  final Map<String, dynamic> legacy;

  /// Everyday era events that do not fit this person (ids).
  final List<String> skipEvents;

  final String id;
  final String name;
  final String era;
  final String firstName;
  final String surname;

  /// The house name the past bridge carries into the modern world.
  final String? house;
  final String gender;
  final int birthYear;

  /// When they really died (shown in the Codex).
  final int deathYear;
  final String region;
  final String city;

  /// The LegendLook id (ui/legend_look.dart).
  final String look;
  final List<LegendChapter> chapters;
  final List<TurningPoint> turningPoints;
  final List<Fate> fates;
  final List<Storylet> storylets;
  final List<Map<String, dynamic>> npcs;
  final Map<String, int> stats;
  final int money;

  /// Extra Codex cards unlocked by choices: id -> {title, text}.
  final Map<String, Map<String, String>> codex;

  /// Test Legends only appear in debug builds.
  final bool test;

  TurningPoint? point(String id) =>
      turningPoints.where((p) => p.id == id).firstOrNull;

  String chapterFor(int year) {
    for (final c in chapters) {
      if (year >= c.from && year <= c.to) return c.title;
    }
    return chapters.isEmpty ? '' : chapters.last.title;
  }

  factory Legend.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final era = j['era'] as String;
    return Legend(
      id: id,
      name: j['name'],
      era: era,
      firstName: j['firstName'],
      surname: j['surname'],
      house: j['house'],
      gender: j['gender'] ?? 'male',
      birthYear: j['birthYear'],
      deathYear: j['deathYear'],
      region: j['region'],
      city: j['city'],
      look: j['look'] ?? id,
      test: j['test'] ?? false,
      skipEvents: List<String>.from(j['skipEvents'] ?? const []),
      legacy: Map<String, dynamic>.from(j['legacy'] ?? const {}),
      money: j['money'] ?? 0,
      stats: Map<String, int>.from(j['stats'] ?? const {}),
      npcs: [
        for (final n in (j['npcs'] as List?) ?? const [])
          Map<String, dynamic>.from(n),
      ],
      chapters: [
        for (final c in (j['chapters'] as List?) ?? const [])
          LegendChapter(c['title'], c['from'], c['to']),
      ],
      turningPoints: [
        for (final p in (j['turningPoints'] as List?) ?? const [])
          TurningPoint(
            id: p['id'],
            year: p['year'],
            title: p['title'],
            history: p['history'],
          ),
      ],
      fates: [
        for (final f in (j['fates'] as List?) ?? const [])
          Fate.fromJson(Map<String, dynamic>.from(f)),
      ],
      codex: {
        for (final e in Map<String, dynamic>.from(j['codex'] ?? const {})
            .entries)
          e.key: Map<String, String>.from(e.value),
      },
      // Every event of a Legend belongs to it and its era.
      storylets: [
        for (final s in (j['events'] as List?) ?? const [])
          Storylet.fromJson({
            'legend': id,
            'era': era,
            ...Map<String, dynamic>.from(s),
          }),
      ],
    );
  }
}

/// Starts a Legend's life on [t] (a new timeline in the Legend's era).
Life startLegend(Legend legend, Timeline t, {int? seed}) {
  final s = seed ?? Random().nextInt(1 << 30);
  final rng = Random(s);
  final stats = Stats.random(rng);
  legend.stats.forEach((k, v) => stats.values[k] = v);
  final life = Life(
    seed: s,
    firstName: legend.firstName,
    surname: legend.surname,
    gender: legend.gender,
    country: eraRegistry[legend.era]?.region(legend.region).name ??
        legend.region,
    city: legend.city,
    birthYear: legend.birthYear,
    stats: stats,
    npcs: [
      for (final n in legend.npcs)
        Npc(
          id: n['id'],
          role: n['role'],
          name: n['name'],
          circle: n['circle'] ?? 'Family',
          birthYear: n['birthYear'] ?? legend.birthYear - 25,
          bond: n['bond'] ?? 60,
        )..info.addAll({if (n['died'] != null) 'died': n['died']}),
    ],
    money: legend.money,
  )
    ..legendId = legend.id
    ..era = legend.era
    ..timelineId = t.id
    ..chronicle = 100
    ..chapter = legend.chapterFor(legend.birthYear);
  life.feed.add(
    FeedEntry(
      0,
      'You were born in ${legend.city} in ${legend.birthYear}. '
      'Your name is ${legend.firstName}.',
      kind: 'milestone',
    ),
  );
  t.advanceTo(legend.birthYear);
  return life;
}

/// Starts an ordinary life (no Legend) in [t]'s era: a random person of
/// the time.
Life startTimelineLife(EraRules era, Timeline t, {int? seed, int? year}) {
  final s = seed ?? Random().nextInt(1 << 30);
  final rng = Random(s);
  final region = era.regions[rng.nextInt(era.regions.length)];
  String pick(List<String> l) => l[rng.nextInt(l.length)];
  final g = rng.nextBool() ? 'female' : 'male';
  final born = year ?? t.year;
  final life = Life(
    seed: s,
    firstName: pick(g == 'female' ? region.female : region.male),
    surname: pick(region.surnames),
    gender: g,
    country: region.name,
    city: pick(region.cities),
    birthYear: born,
    stats: Stats.random(rng),
    npcs: [
      Npc(
        id: 'mother',
        role: 'Mother',
        name: pick(region.female),
        birthYear: born - 20 - rng.nextInt(12),
        bond: 70 + rng.nextInt(25),
      ),
      Npc(
        id: 'father',
        role: 'Father',
        name: pick(region.male),
        birthYear: born - 24 - rng.nextInt(14),
        bond: 55 + rng.nextInt(30),
      ),
    ],
  )
    ..era = era.id
    ..timelineId = t.id;
  life.feed.add(
    FeedEntry(
      0,
      'You were born in ${life.city} in $born, to ${life.npcs[0].name} '
      'and ${life.npcs[1].name}.',
      kind: 'milestone',
    ),
  );
  t.advanceTo(born);
  return life;
}

/// The turning point due this year that has not been resolved, if any.
Storylet? dueTurningPoint(Life life, List<Storylet> storylets) {
  if (life.legendId == null) return null;
  for (final s in storylets) {
    if (s.pivot == null || life.pivots.containsKey(s.pivot)) continue;
    if (s.isEligible(life)) return s;
  }
  return null;
}

/// After a choice in a timeline life: cause weight, the Chronicle, world
/// facts and Codex cards. Returns echo lines for the outcome card.
List<String> afterTimelineChoice(
  Life life,
  Storylet event,
  Choice choice,
  bool success,
  Timeline? t,
) {
  final echoes = <String>[];
  choice.adds.forEach(
    (cause, amount) => addCause(
      life,
      cause,
      amount,
      choice.why ?? choice.label.toLowerCase(),
    ),
  );
  if (choice.gated) {
    final because = becauseLine(life, choice.causes);
    if (because != null && success) echoes.add(because);
  }
  final legend = legendRegistry[life.legendId];
  if (event.pivot != null) {
    final kind = choice.canon
        ? 'canon'
        : (choice.rewrites != null && success ? 'rewritten' : 'other');
    life.pivots[event.pivot!] = choice.chronicle != null && kind == 'other'
        ? 'other:${choice.chronicle}'
        : kind;
    life.codex.add(event.pivot!);
    life.chronicle = chronicleOf(life);
    final title = legend?.point(event.pivot!)?.title ?? 'A turning point';
    echoes.add(
      kind == 'canon'
          ? 'History kept: $title'
          : kind == 'rewritten'
          ? 'History rewritten: $title'
          : 'History bent: $title',
    );
    echoes.add('New Codex card: What really happened');
  }
  if (choice.rewrites != null && success) {
    life.flags['fact:${choice.rewrites}'] = Memory(life.age, choice.label);
    t?.write(choice.rewrites!, life.year, '${life.firstName}: ${choice.label}');
  }
  if (choice.codex != null) {
    life.codex.add(choice.codex!);
    if (event.pivot == null) echoes.add('New Codex card');
  }
  return echoes;
}

/// Chronicle: how closely the life follows history, from the turning
/// points resolved so far (kept 100, bent 40 or as set, rewritten 0).
int chronicleOf(Life life) {
  if (life.pivots.isEmpty) return 100;
  var sum = 0;
  for (final v in life.pivots.values) {
    if (v == 'canon') {
      sum += 100;
    } else if (v == 'rewritten') {
      sum += 0;
    } else if (v.startsWith('other:')) {
      sum += int.tryParse(v.substring(6))?.clamp(0, 100) ?? 40;
    } else {
      sum += 40;
    }
  }
  return (sum / life.pivots.length).round();
}

/// Picks the Fate a Legend life ended in: the first that fits.
Fate? pickFate(Life life, Timeline? t) {
  final legend = legendRegistry[life.legendId];
  if (legend == null || legend.fates.isEmpty) return null;
  return legend.fates.where((f) => f.fits(life, t)).firstOrNull ??
      legend.fates.last;
}

/// Ends a Legend life: picks its Fate and writes it to the feed.
void endLegend(Life life, Timeline? t) {
  if (life.legendId == null || life.fate != null) return;
  final fate = pickFate(life, t);
  if (fate == null) return;
  life.fate = fate.id;
  life.feed.add(
    FeedEntry(life.age, 'Fate: ${fate.title}. ${fate.text}', kind: 'milestone'),
  );
  t?.log.add('${life.year}: ${life.firstName} ${life.surname}: ${fate.title}');
}

/// Adds a Legend to the registry.
Legend registerLegend(Legend legend) => legendRegistry[legend.id] = legend;

/// Every era and Legend event loaded, to add to the engine's storylets.
/// They are tagged, so a modern life never sees them.
List<Storylet> timelineStorylets() => [
  for (final e in eraRegistry.values) ...e.storylets,
  for (final l in legendRegistry.values) ...l.storylets,
];

/// The choices a card shows: cause-gated choices stay hidden until at least
/// half their cause is built (causes.dart). Ordinary choices are unchanged.
List<Choice> visibleChoices(Life life, Storylet s) => [
  for (final c in s.choices)
    if (!c.gated || causeTier(life, c.causes) != CauseTier.hidden) c,
];
