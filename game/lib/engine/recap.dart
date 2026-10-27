import 'dart:math';

import 'actions.dart';
import 'family.dart' show childrenOf;
import 'lifespan.dart';
import 'models.dart';
import 'storylet.dart';

/// The end of a life as a moment (plan Core Module 9 and Social §9): a
/// funeral with the people who came and a eulogy built from what they
/// remember, then the Life Recap story cards with a Life Archetype and a
/// Chaos Index, privacy toggles for sharing, and the Dynasty Recap.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

// ---------------- Funeral and eulogy ----------------

const funeralTypes = {
  'burial': 'A burial',
  'cremation': 'A cremation',
  'natural': 'A natural burial under a young tree',
  'sea': 'Ashes scattered at sea',
  'party': 'A celebration of life, with music and no black clothes',
};

typedef Funeral = ({
  String type,
  int attendance,
  String? speaker,
  List<String> eulogy,
  List<String> absent,
});

Funeral funeralFor(Life l) {
  final type =
      l.marks
          .where((m) => m.startsWith('funeral:'))
          .map((m) => m.substring(8))
          .firstOrNull ??
      'cremation';
  final people =
      l.npcs
          .where((n) => n.alive && n.circle != 'Pets' && n.circle != 'Prison')
          .toList()
        ..sort((a, b) => b.bond.compareTo(a.bond));
  final came = people.where((n) => n.bond >= 40).toList();
  final strangers = l.fame * 12 + (l.stats['karma'] >= 80 ? 30 : 0);
  final eulogy = <String>[];
  for (final n in came.take(4)) {
    final mem = n.memories.where((m) => !m.negative).toList()
      ..sort((a, b) => b.intensity.compareTo(a.intensity));
    if (mem.isEmpty) continue;
    eulogy.add(
      '${n.name.split(' ').first} (${n.role.toLowerCase()}): "I will never forget ${_firstPerson(mem.first.text)}."',
    );
  }
  if (eulogy.isEmpty && came.isNotEmpty) {
    eulogy.add(
      '${came.first.name.split(' ').first}: "They were there when it mattered. That is what I will remember."',
    );
  }
  final absent = [
    for (final n in people.where(
      (n) =>
          n.resentment >= 40 ||
          n.memories.any((m) => m.negative && m.intensity >= 4),
    ))
      n.name.split(' ').first,
  ];
  return (
    type: type,
    attendance: came.length + strangers,
    speaker: came.isEmpty ? null : came.first.name,
    eulogy: eulogy,
    absent: absent.take(2).toList(),
  );
}

/// NPC memories are written from their side ("you trusting them"); the
/// eulogy speaks in the first person.
String _firstPerson(String t) => t
    .replaceAll(RegExp(r'\bthem\b'), 'me')
    .replaceAll(RegExp(r'\bthey were\b'), 'I was')
    .replaceAll(RegExp(r'\bthey\b'), 'I')
    .replaceAll(RegExp(r'\btheir\b'), 'my');

Storylet funeralWishScene() => Storylet(
  id: 'scene:funeral_wish',
  text: 'Planning your own funeral is strange, and oddly calming. When the day comes, what would you like?',
  category: 'life',
  scene: true,
  choices: [
    for (final e in funeralTypes.entries)
      Choice(
        label: e.value,
        outcome: '',
        run: (l, rng) {
          l.marks.removeWhere((m) => m.startsWith('funeral:'));
          l.marks.add('funeral:${e.key}');
          return 'Written down and filed with your will. Your family will know what you wanted.';
        },
      ),
  ],
);

final recapActions = <GameAction>[
  GameAction(
    id: 'plan_funeral',
    label: 'Plan your funeral',
    category: 'Law',
    keywords: ['funeral', 'burial', 'cremation', 'wishes', 'death'],
    minAge: 50,
    run: (l, rng) {
      l.sceneQueue.add('funeral_wish');
      return ActionResult('You sit down with a cup of tea and a blank page.');
    },
  ),
];

// ---------------- Archetype and Chaos Index ----------------

int _flags(Life l, List<String> keys) =>
    keys.where((k) => l.flags.containsKey(k)).length;

/// Risk taken over a life, 0..1.
double riskScore(Life l) {
  final events =
      _flags(l, [
        'arrested',
        'prison',
        'heist',
        'escaped',
        'bankrupt',
        'founded_business',
        'emigrated',
        'jackpot',
        'addiction_gambling',
        'affair_found',
        'marathon',
      ]) +
      l.record.length +
      (l.debts.values.fold(0, (a, b) => a + b) > 50000 ? 1 : 0) +
      (l.stats['impulsivity'] > 65 ? 1 : 0);
  return (events / 6).clamp(0.0, 1.0);
}

/// People over ambition, 0 (all ambition) .. 1 (all people).
double peopleScore(Life l) {
  final bonds =
      (l.npcs.where((n) => n.circle != 'Pets').toList()
            ..sort((a, b) => b.bond.compareTo(a.bond)))
          .take(5)
          .fold(0, (a, n) => a + n.bond);
  final people =
      bonds / 5 +
      childrenOf(l).length * 8 +
      (l.flags.containsKey('married') ? 10 : 0);
  final ambition =
      l.careerRank * 15 +
      l.school.degrees.length * 10 +
      (l.netWorth >= 1000000
          ? 40
          : l.netWorth >= 250000
          ? 20
          : 0) +
      l.fame ~/ 3;
  return people / max(1, people + ambition);
}

const _archetypes = [
  [
    'The Careful Climber',
    'The Steady Hand',
    'The Quiet Guardian',
    'The Gentle Heart',
  ],
  [
    'The Planner',
    'The Dependable One',
    'The Family Anchor',
    'The Kind Neighbour',
  ],
  [
    'The Bold Builder',
    'The Restless Achiever',
    'The Reluctant Hero',
    'The Warm Adventurer',
  ],
  [
    'The Ruthless Climber',
    'The Wildcard',
    'The Chaotic Romantic',
    'The Free Spirit',
  ],
];

/// One of 16 archetypes from caution vs risk and ambition vs people.
String archetypeOf(Life l) {
  final r = min(3, (riskScore(l) * 4).floor());
  final p = min(3, (peopleScore(l) * 4).floor());
  return _archetypes[r][p];
}

/// How dramatic the life was, 0..100.
int chaosIndex(Life l) {
  final events =
      _flags(l, [
        'arrested',
        'prison',
        'divorced',
        'affair_found',
        'bankrupt',
        'fired',
        'emigrated',
        'expelled',
        'escaped',
        'heist',
        'parents_divorced',
        'jackpot',
        'widowed',
        'sold_business',
        'closed_business',
        'acquitted',
      ]) +
      l.flags.keys
          .where((k) => k.startsWith('addiction_') || k.startsWith('survived_'))
          .length +
      l.marks
          .where((m) => m.startsWith('scandal:') || m.startsWith('crisis:'))
          .length +
      l.npcs.where((n) => n.circle == 'Exes').length;
  return min(100, events * 9);
}

// ---------------- Story cards ----------------

typedef RecapCard = ({String kind, String title, String big, String body});

typedef RecapPrivacy = ({bool names, bool crimes, bool money, bool cause});

const shareSafe = (names: false, crimes: true, money: false, cause: false);

List<RecapCard> recapCards(
  Life l, {
  RecapPrivacy hide = (names: false, crimes: false, money: false, cause: false),
  List<int> pastChaos = const [],
}) {
  String who(Npc n) =>
      hide.names ? 'your ${n.role.toLowerCase()}' : n.name.split(' ').first;
  final cards = <RecapCard>[];
  final parents = l.npcs.where((n) => n.role == 'Mother' || n.role == 'Father');
  cards.add((
    kind: 'birth',
    title: 'Where it began',
    big: '${l.city}, ${l.birthYear}',
    body: hide.names
        ? 'You were born in ${l.country}.'
        : 'You were born in ${l.country} to ${parents.map((p) => p.name.split(' ').first).join(' and ')}.',
  ));
  final friend =
      (l.npcs.where((n) => n.circle == 'Friends').toList()
            ..sort((a, b) => b.bond.compareTo(a.bond)))
          .firstOrNull;
  final pet = l.npcs.where((n) => n.circle == 'Pets').firstOrNull;
  cards.add((
    kind: 'childhood',
    title: 'Growing up',
    big: friend != null
        ? who(friend)
        : (pet != null ? who(pet) : 'Small adventures'),
    body: friend != null
        ? 'Your best friend: ${who(friend)} (${friend.bond}%).${pet != null ? ' And ${who(pet)} the ${pet.role.toLowerCase()}.' : ''}'
        : pet != null
        ? 'Your companion: ${who(pet)} the ${pet.role.toLowerCase()}.'
        : 'A childhood of your own making.',
  ));
  final firstLove = l.npcs
      .where((n) => n.circle == 'Partner' || n.circle == 'Exes')
      .firstOrNull;
  cards.add((
    kind: 'school',
    title: 'School and first love',
    big: l.school.degrees.isNotEmpty ? l.school.degrees.first : _edu(l),
    body: firstLove == null
        ? 'Love could wait.'
        : 'First love: ${who(firstLove)}.',
  ));
  cards.add((
    kind: 'career',
    title: 'Work and money',
    big: hide.money
        ? (l.job ?? (l.retired ? 'Retired' : 'Your own path'))
        : _m(l.netWorth),
    body:
        '${l.job != null ? 'Last job: ${l.job}. ' : ''}${hide.money ? '' : 'Net worth at the end: ${_m(l.netWorth)}.'}',
  ));
  final risk = _biggestRisk(l, hide.crimes);
  cards.add((
    kind: 'risk',
    title: 'The biggest risk you took',
    big: risk.$1,
    body: risk.$2,
  ));
  final loyal =
      (l.npcs.where((n) => n.circle != 'Prison').toList()
            ..sort((a, b) => b.bond.compareTo(a.bond)))
          .firstOrNull;
  if (loyal != null) {
    cards.add((
      kind: 'people',
      title: 'Your people',
      big: who(loyal),
      body: 'Your most loyal person was ${who(loyal)} (${loyal.bond}%).',
    ));
  }
  final grudge =
      (l.npcs.where((n) => n.resentment >= 30).toList()
            ..sort((a, b) => b.resentment.compareTo(a.resentment)))
          .firstOrNull;
  if (grudge != null) {
    cards.add((
      kind: 'grudge',
      title: 'The grudge never settled',
      big: who(grudge),
      body: '${who(grudge)} never quite forgave you.',
    ));
  }
  cards.add((
    kind: 'archetype',
    title: 'Life Archetype',
    big: archetypeOf(l),
    body:
        'From how much you risked (${(riskScore(l) * 100).round()}%) and how much you lived for people rather than ambition (${(peopleScore(l) * 100).round()}%).',
  ));
  final chaos = chaosIndex(l);
  final calmer = pastChaos.where((c) => c < chaos).length;
  cards.add((
    kind: 'chaos',
    title: 'Chaos Index',
    big: '$chaos',
    body: pastChaos.isEmpty
        ? 'Out of 100: arrests, break-ups, scandals, fresh starts and comebacks all count.'
        : 'More chaotic than ${(calmer * 100 / pastChaos.length).round()}% of your other lives.',
  ));
  final t = titleFor(l);
  cards.add((
    kind: 'title',
    title: t.name,
    big: '${l.birthYear}–${l.year}',
    body:
        '"${t.epitaph}"${hide.cause || l.causeOfDeath == null ? '' : ' · ${l.causeOfDeath}'}',
  ));
  cards.add((
    kind: 'seed',
    title: 'Try this life',
    big: seedCode(l.seed),
    body:
        'Enter this code on the New Life screen to start from the same birth.',
  ));
  return cards;
}

String _edu(Life l) => switch (l.education) {
  'graduate' => 'Graduate',
  'high school graduate' => 'School diploma',
  'university' => 'University',
  _ => 'School of life',
};

(String, String) _biggestRisk(Life l, bool hideCrimes) {
  if (l.flags.containsKey('heist')) {
    return hideCrimes
        ? ('A big gamble', 'You bet everything on one night.')
        : ('The heist', 'You pulled off ${l.flags['heist']!.label}.');
  }
  if (l.flags.containsKey('escaped')) {
    return hideCrimes
        ? ('A great escape', 'You got out of a tight spot.')
        : ('The escape', 'You broke out of prison.');
  }
  if (l.flags.containsKey('founded_business')) {
    return (
      'Going it alone',
      'You started ${l.flags['founded_business']!.label.replaceFirst('opening ', '')}.',
    );
  }
  if (l.flags.containsKey('emigrated')) {
    return (
      'A fresh start',
      'You moved abroad: ${l.flags['emigrated']!.label.replaceFirst('moving ', '')}.',
    );
  }
  if (l.flags.containsKey('jackpot')) {
    return ('The ticket', 'You bought a lottery ticket. It won.');
  }
  if (l.flags.containsKey('married')) {
    return ('Saying yes', 'You married for love.');
  }
  return (
    'Playing it safe',
    'You chose steady over spectacular. That counts too.',
  );
}

/// Chaos Index of the lives finished before this one (recorded by
/// recordLifeEnd), so the recap can say "more chaotic than X%".
List<int> pastChaosOf(Life l) {
  final m = l.marks.where((m) => m.startsWith('chaos_past:')).firstOrNull;
  if (m == null || m.length == 11) return const [];
  return [for (final v in m.substring(11).split(',')) int.tryParse(v) ?? 0];
}

/// The cards as plain text, for copying anywhere.
String recapText(Life l, List<RecapCard> cards, {bool names = true}) => [
  names ? 'My life in Relivable: ${l.fullName}' : 'My life in Relivable',
  for (final c in cards)
    '${c.title}: ${c.big}. ${c.body}'.replaceAll('..', '.'),
].join('\n');

/// Dynasty Recap: one line per generation, then this life.
List<String> dynastyLines(Life l) => [
  for (final (i, g) in l.lineage.indexed)
    'Generation ${i + 1}: ${g['name']} (${g['born']}–${g['died']}), ${g['title']}${(g['job'] ?? '') != '' ? ', ${g['job']}' : ''}',
  'Generation ${l.generation}: ${l.fullName} (${l.birthYear}–${l.year}), ${titleFor(l).name}${l.job != null ? ', ${l.job}' : ''}',
];
