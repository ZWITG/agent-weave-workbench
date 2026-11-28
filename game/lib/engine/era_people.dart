/// People in an era life, redone (Phase 2D; ZWITG: the old way was "too
/// bland and boring"). Everyone has a nature: one of the four humours,
/// what they like, what they can't bear, and what's on their mind this
/// year. You learn these by spending time with them. Six ways (Talk,
/// Write, Give, Ask, Quarrel, Make peace) and three moments a year each
/// open a short scene with choices; how it goes depends on who they are
/// and what you know. They answer in their own voice, keep a memory, and
/// come to you with their own scenes. Matches, dowries and widowhood are
/// here too. Modern lives keep the modern People sheet (relationships.dart).
library;

import 'dart:math';

import 'era_faith.dart' show eraFaithOf, eraStanding;
import 'era_health.dart' show eraPlagueHere;
import 'era_justice.dart' show eraInside;
import 'era_market.dart';
import 'era_path.dart' show eraStatus;
import 'era_wealth.dart';
import 'eras.dart';
import 'love.dart' show freshNpcId, partnerOf;
import 'models.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

Map<String, dynamic> _p(EraRules era, String key) =>
    Map<String, dynamic>.from((era.peopleData[key] as Map?) ?? const {});

/// The people an era life can spend time with (alive, not pets).
List<Npc> eraPeople(Life l) => [
  for (final n in l.npcs)
    if (n.alive && n.circle != 'Pets' && !n.contactCut) n,
];

bool _close(Npc n) =>
    n.circle == 'Family' ||
    n.circle == 'Partner' ||
    n.circle == 'Children' ||
    n.bond >= 50;

Map<String, dynamic>? _legendNpc(Life l, EraRules era, Npc n) {
  final byLegend = (_p(era, 'legend')[l.legendId] as Map?) ?? const {};
  final m = byLegend[n.id] as Map?;
  return m == null ? null : Map<String, dynamic>.from(m);
}

// ---------------- Nature ----------------

/// Gives [n] a nature the first time it's needed: their humour, two
/// likes, a dislike. Legend people have their real ones.
void eraNature(Life l, EraRules era, Npc n) {
  if (n.info['humour'] != null) return;
  final legend = _legendNpc(l, era, n);
  final humours = _p(era, 'humours');
  final rng = Random(n.id.hashCode ^ l.seed ^ n.birthYear);
  final keys = humours.keys.toList()..sort();
  final humour = legend?['humour'] as String? ?? keys[rng.nextInt(keys.length)];
  final h = Map<String, dynamic>.from(humours[humour] as Map);
  final likesPool = _p(era, 'likes').keys.toList()..sort();
  final likes = <String>[
    ...List<String>.from(legend?['likes'] ?? const []),
  ];
  // One like from the humour, one of their own.
  final fromHumour = List<String>.from(h['likes'] as List);
  if (likes.isEmpty) likes.add(fromHumour[rng.nextInt(fromHumour.length)]);
  while (likes.length < 2) {
    final x = likesPool[rng.nextInt(likesPool.length)];
    if (!likes.contains(x)) likes.add(x);
  }
  n.info['humour'] = humour;
  n.info['likes'] = likes;
  n.info['dislike'] = legend?['dislike'] ?? h['dislike'];
  // Family who know you well: you know their humour already.
  n.info['known'] = <String>[
    if (n.bond >= 60 && (n.circle == 'Family' || n.circle == 'Partner'))
      'humour',
  ];
}

List<String> _known(Npc n) => List<String>.from((n.info['known'] as List?) ?? const []);

bool eraKnows(Npc n, String what) => _known(n).contains(what);

void _learn(Npc n, String what) {
  if (!eraKnows(n, what)) n.info['known'] = [..._known(n), what];
}

String eraHumourOf(Npc n) => n.info['humour'] as String? ?? 'sanguine';
List<String> eraLikesOf(Npc n) => List<String>.from((n.info['likes'] as List?) ?? const []);
String eraDislikeOf(Npc n) => n.info['dislike'] as String? ?? 'cold';

/// A person's nature as chips: what you know, and a hint for the rest.
List<({String text, bool known})> eraNatureChips(Life l, EraRules era, Npc n) {
  eraNature(l, era, n);
  final h = Map<String, dynamic>.from(_p(era, 'humours')[eraHumourOf(n)] as Map);
  final likes = _p(era, 'likes');
  final dislikes = _p(era, 'dislikes');
  final out = <({String text, bool known})>[];
  if (eraKnows(n, 'humour')) {
    out.add((text: '${h['label']}: ${h['about']}', known: true));
  }
  final known = [
    for (final x in eraLikesOf(n))
      if (eraKnows(n, 'like:$x')) likes[x] as String,
  ];
  if (known.isNotEmpty) out.add((text: 'Loves ${known.join(', ')}', known: true));
  if (eraKnows(n, 'dislike')) {
    out.add((text: 'Hates ${dislikes[eraDislikeOf(n)]}', known: true));
  }
  final unknown =
      (eraKnows(n, 'humour') ? 0 : 1) +
      eraLikesOf(n).where((x) => !eraKnows(n, 'like:$x')).length +
      (eraKnows(n, 'dislike') ? 0 : 1);
  if (unknown > 0) {
    out.add((text: '$unknown more to learn by spending time together', known: false));
  }
  return out;
}

/// Where they live, and a line about them.
String eraWhere(Life l, EraRules era, Npc n) =>
    _legendNpc(l, era, n)?['where'] as String? ??
    (n.info['city'] as String?) ??
    l.city;

String? eraAbout(Life l, EraRules era, Npc n) =>
    _legendNpc(l, era, n)?['note'] as String?;

// ---------------- What's on their mind ----------------

/// This year's want or worry, if they have one and it isn't settled.
Map<String, dynamic>? eraMind(Life l, Npc n) {
  final m = n.info['mind'] as Map?;
  if (m == null || m['year'] != l.year || m['solved'] == true) return null;
  return Map<String, dynamic>.from(m);
}

String _they(Npc n) => n.gender == 'female' ? 'she' : 'he';
String _them(Npc n) => n.gender == 'female' ? 'her' : 'him';
String _their(Npc n) => n.gender == 'female' ? 'her' : 'his';
String _first(Npc n) => n.name.split(' ').first;

String _fill(String s, Npc n) => s
    .replaceAll('{they_cap}', eraUp(_they(n)))
    .replaceAll('{they}', _they(n))
    .replaceAll('{them}', _them(n))
    .replaceAll('{their}', _their(n))
    .replaceAll('{name}', _first(n));

void _newMind(Life l, EraRules era, Npc n, Random rng) {
  final age = n.ageIn(l.year);
  final options = [
    for (final raw in (era.peopleData['minds'] as List?) ?? const [])
      if ((raw as Map)['minAge'] == null || age >= (raw['minAge'] as int))
        if (raw['maxAge'] == null || age <= (raw['maxAge'] as int))
          if (raw['plague'] != true || eraPlagueHere(l, era))
            Map<String, dynamic>.from(raw),
  ];
  if (options.isEmpty) return;
  final m = options[rng.nextInt(options.length)];
  n.info['mind'] = {
    'year': l.year,
    'id': m['id'],
    'text': _fill(m['text'] as String, n),
    'help': m['help'],
  };
}

/// What helping with their mind costs, in florins.
int eraHelpCost(Life l, EraRules era, String help) => switch (help) {
  'grain' => eraCost(l, era, 3),
  'money' => eraCost(l, era, 15),
  'physician' => eraCost(l, era, 6),
  _ => 0,
};

String eraHelpLabel(Map mind) => switch (mind['help']) {
  'grain' => 'Send grain',
  'money' => 'Send money',
  'physician' => 'Send a physician',
  'visit' => 'Visit',
  'favour' => 'Put in a word for them',
  _ => 'Talk it through',
};

// ---------------- Scenes ----------------

/// A choice in a scene. [hint] is 'loves', 'upset', 'risky' or 'help'
/// (only shown when you know enough), or ''.
typedef EraChoice = ({
  String id,
  String label,
  String sub,
  String hint,
  String? lock,
});

typedef EraScene = ({
  String kind,
  String kicker,
  String title,
  String text,
  List<EraChoice> choices,
  bool game,
});

/// What happened: their reply, what you see, the changes, a memory they
/// keep and anything you learned.
typedef EraOutcome = ({
  String quote,
  String text,
  List<String> deltas,
  String? memory,
  String? learned,
  bool good,
});

/// The always-there ways to spend time with someone.
const eraWays = ['talk', 'write', 'give', 'ask', 'quarrel', 'peace'];

String eraWayLabel(String w) => const {
  'talk': 'Talk',
  'write': 'Write',
  'give': 'Give',
  'ask': 'Ask',
  'quarrel': 'Quarrel',
  'peace': 'Make peace',
}[w]!;

String eraWaySub(String w) => const {
  'talk': 'pick a topic',
  'write': 'a letter',
  'give': 'a gift or money',
  'ask': 'a favour',
  'quarrel': 'say it',
  'peace': 'when hurt',
}[w]!;

String? eraWayLock(Life l, Npc n, String w) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 3) return 'When you are older.';
  if (eraInside(l) && w != 'write') return 'Only letters reach you inside.';
  if (w == 'write' && l.age < 8) return 'When you can write.';
  if (w == 'peace' && n.resentment <= 0 && n.grudge == null) {
    return 'Nothing to make peace over.';
  }
  if (l.usedActions.contains('era_way_${n.id}_$w')) return 'Done this year.';
  return null;
}

/// The topic (like or dislike key) each choice touches, and how risky it
/// is (0: safe, 1: could go either way, 2: risky).
const _topics = <String, (String, int)>{
  'old': ('old', 0),
  'news': ('news', 0),
  'work': ('work', 0),
  'troubles': ('help', 0),
  'secret': ('secret', 2),
  'honest': ('crossed', 2),
  'letter_warm': ('letter', 0),
  'letter_news': ('news', 0),
  'letter_drawing': ('art', 0),
  'messenger': ('letter', 0),
  'advice': ('respect', 0),
  'loan': ('money', 1),
  'favour': ('help', 1),
  'speak': ('crossed', 1),
  'wound': ('secret', 2),
  'leave': ('cold', 1),
  'apologise': ('help', 0),
  'peace_gift': ('gift', 0),
  'mediator': ('faith', 0),
  'feast': ('feast', 0),
  'ride': ('horse', 0),
  'carnival': ('feast', 0),
  'church': ('faith', 0),
  'portrait': ('art', 0),
  'walk': ('quiet', 0),
};

String _hint(Npc n, String choice) {
  final t = _topics[choice] ?? _giftTopic(choice);
  if (t == null) return '';
  final (topic, risk) = t;
  final likes = eraLikesOf(n);
  if (likes.contains(topic) && eraKnows(n, 'like:$topic')) return 'loves';
  if (eraDislikeOf(n) == topic && eraKnows(n, 'dislike')) return 'upset';
  if (risk >= 2) return 'risky';
  return '';
}

(String, int)? _giftTopic(String choice) =>
    choice.startsWith('gift_') ? ('gift', 0) : null;

EraChoice _c(Npc n, String id, String label, String sub, {String? lock, String? hint}) =>
    (id: id, label: label, sub: sub, hint: hint ?? _hint(n, id), lock: lock);

List<Map<String, dynamic>> eraGifts(Life l, EraRules era) => [
  for (final g in (era.peopleData['gifts'] as List?) ?? const [])
    if ((g as Map)['needs'] != 'book' ||
        (eraPressYear(l, era) != null && l.year >= eraPressYear(l, era)!) ||
        const {'maghreb', 'egypt', 'sahel', 'iberia'}.contains(era.regionOf(l).group))
      Map<String, dynamic>.from(g),
];

String _moneyName(Life l, EraRules era) {
  final r = era.regionOf(l);
  return era.currencies[r.currencyIn(l.year)]?.name ?? 'florins';
}

String? _secretLabel(Life l, EraRules era, Npc n) {
  final s = (_p(era, 'secrets')[l.legendId] as Map?)?[n.id] as String?;
  return s;
}

/// The scene a way or a moment opens.
EraScene eraScene(Life l, EraRules era, Npc n, String kind) {
  eraNature(l, era, n);
  final first = _first(n);
  final mind = eraMind(l, n);
  final season = l.year;
  final secret = _secretLabel(l, era, n);
  final talk = <EraChoice>[
    _c(n, 'old', 'Talk about the old days', 'Remember together'),
    _c(n, 'news', 'Tell $first the news of ${l.city}', 'Gossip and proclamations'),
    if (l.job != null) _c(n, 'work', 'Talk about your work', l.job!),
    _c(n, 'troubles', 'Ask what\'s on ${_their(n)} mind', 'Listen'),
    if (secret != null)
      _c(
        n,
        'secret',
        secret,
        'Something never spoken of',
        lock: n.trust < 60 ? 'Needs more trust' : null,
      )
    else
      _c(n, 'honest', 'Ask what ${_they(n)} really thinks of you', 'You may not like the answer'),
  ];
  switch (kind) {
    case 'talk':
      return (
        kind: kind,
        kicker: 'Talk · $season',
        title: 'With $first',
        text: _arrival(l, era, n, false),
        choices: talk,
        game: false,
      );
    case 'visit':
      return (
        kind: kind,
        kicker: 'A visit · $season',
        title: 'The house at ${eraWhere(l, era, n).split(',').first}',
        text: _arrival(l, era, n, true),
        choices: [
          ...talk.take(3),
          ?talk.lastOrNull,
          if (mind != null)
            _c(
              n,
              'help_mind',
              eraHelpLabel(mind),
              'Helps what\'s on ${_their(n)} mind',
              hint: 'help',
              lock: l.money < eraHelpCost(l, era, mind['help'] as String)
                  ? 'Needs ${eraM(l, eraHelpCost(l, era, mind['help'] as String))}'
                  : null,
            ),
        ],
        game: false,
      );
    case 'write':
      return (
        kind: kind,
        kicker: 'A letter · $season',
        title: 'Dear $first',
        text: 'Paper, a pen and the carrier who goes ${eraWhere(l, era, n) == l.city ? 'across the city' : 'to ${eraWhere(l, era, n).split(',').first}'} on market days.',
        choices: [
          _c(n, 'letter_warm', 'A warm letter', 'How you are, and that you think of ${_them(n)}'),
          _c(n, 'letter_news', 'A letter full of news', 'Everything that happened this year'),
          _c(
            n,
            'letter_drawing',
            'A letter with a drawing',
            'A sketch in the margin',
            lock: l.stats['creativity'] < 40 && !eraOwns(l, 'paper')
                ? 'Needs paper and some skill'
                : null,
          ),
          _c(
            n,
            'messenger',
            'Send a messenger',
            'Faster than the carrier · ${eraM(l, eraCost(l, era, 1))}',
            lock: l.money < eraCost(l, era, 1) ? 'Needs ${eraM(l, eraCost(l, era, 1))}' : null,
          ),
        ],
        game: false,
      );
    case 'give':
      return (
        kind: kind,
        kicker: 'A gift · $season',
        title: 'Something for $first',
        text: 'What would ${_they(n)} like?',
        choices: [
          for (final g in eraGifts(l, era))
            _c(
              n,
              'gift_${g['id']}',
              (g['label'] as String).replaceAll('{money}', _moneyName(l, era)),
              eraM(l, eraCost(l, era, _int(g['cost']))),
              hint: (g['likes'] as List).any(
                    (x) => eraLikesOf(n).contains(x) && eraKnows(n, 'like:$x'),
                  )
                  ? 'loves'
                  : '',
              lock: l.money < eraCost(l, era, _int(g['cost']))
                  ? 'Needs ${eraM(l, eraCost(l, era, _int(g['cost'])))}'
                  : null,
            ),
        ],
        game: false,
      );
    case 'ask':
      return (
        kind: kind,
        kicker: 'A favour · $season',
        title: 'Asking $first',
        text: 'It is not easy to ask. ${eraUp(_they(n))} waits for you to say it.',
        choices: [
          _c(n, 'advice', 'Ask for advice', 'People like to be asked'),
          _c(
            n,
            'loan',
            'Ask for a loan',
            'Some ${_moneyName(l, era)} until next year',
            lock: l.age < 14 ? 'When you are older' : null,
          ),
          _c(n, 'favour', 'Ask ${_them(n)} to put in a word for you', 'With a master, a patron or a guild'),
        ],
        game: false,
      );
    case 'quarrel':
      return (
        kind: kind,
        kicker: 'A quarrel · $season',
        title: 'It has to be said',
        text: 'Something between you and $first has been sitting there too long.',
        choices: [
          _c(n, 'speak', 'Say what you really think', 'Clear the air, or make it worse'),
          _c(n, 'wound', 'Bring up an old wound', 'What ${_they(n)} did, years ago'),
          _c(n, 'leave', 'Walk out', 'Let the door say it'),
        ],
        game: false,
      );
    case 'peace':
      return (
        kind: kind,
        kicker: 'Making peace · $season',
        title: 'Mending it with $first',
        text: 'The quarrel still hangs between you.',
        choices: [
          _c(n, 'apologise', 'Say you\'re sorry', 'And mean it'),
          _c(
            n,
            'peace_gift',
            'A gift to say it for you',
            eraM(l, eraCost(l, era, 3)),
            lock: l.money < eraCost(l, era, 3) ? 'Needs ${eraM(l, eraCost(l, era, 3))}' : null,
          ),
          _c(n, 'mediator', _mediator(l), 'Someone you both respect'),
        ],
        game: false,
      );
    default:
      return _moment(l, era, n, kind);
  }
}

String _mediator(Life l) => switch (eraFaithOf(l)) {
  'muslim' => 'Ask the imam to make peace',
  'jewish' => 'Ask the rabbi to make peace',
  'kongo' || 'mbundu' => 'Ask the elders to make peace',
  _ => 'Ask the priest to make peace',
};

String _arrival(Life l, EraRules era, Npc n, bool visit) {
  final first = _first(n);
  final humour = eraHumourOf(n);
  if (l.legendId == 'leonardo' && n.id == 'mother' && visit) {
    return 'Caterina is shelling beans in the doorway. She doesn\'t get up, but she smiles. "Look at your hands. Paint everywhere. Sit."';
  }
  return switch (humour) {
    'sanguine' =>
      '$first is already talking before you\'re through the door, and pours you wine.',
    'choleric' =>
      '$first looks up from ${_their(n)} accounts. "Well? I haven\'t got all day."',
    'melancholic' =>
      '$first is by the window, and it takes a moment before ${_they(n)} notices you.',
    _ => '$first nods you in and goes on with what ${_they(n)} was doing. There\'s bread on the table.',
  };
}

// ---------------- Moments ----------------

/// Moment ids that can be dealt to [n] this year.
List<String> _momentPool(Life l, EraRules era, Npc n) {
  final group = era.regionOf(l).group;
  return [
    'visit',
    if (l.legendId == 'leonardo' || l.stats['creativity'] >= 45) 'portrait',
    if (_secretLabel(l, era, n) != null) 'secret_moment',
    'feast',
    if (eraOwns(l, 'horse')) 'ride',
    if (group == 'italy') 'carnival',
    if (eraPlagueHere(l, era)) 'plague',
    'church',
    'walk',
    if (eraMind(l, n) != null) 'help',
  ];
}

/// This year's three moments with [n] (dealt once a year, used up).
List<String> eraMoments(Life l, EraRules era, Npc n) {
  if (!_close(n) || l.age < 6) return const [];
  final all = Map<String, dynamic>.from((l.eraWorld['moments'] as Map?) ?? const {});
  final m = all[n.id] as Map?;
  if (m != null && m['year'] == l.year) return List<String>.from(m['ids'] as List);
  eraNature(l, era, n);
  final rng = Random(l.seed ^ l.year ^ n.id.hashCode);
  final pool = _momentPool(l, era, n);
  final ids = <String>[];
  // What's on their mind and a secret come first when there are any.
  if (pool.contains('help')) ids.add('help');
  if (pool.contains('secret_moment') && rng.nextBool()) ids.add('secret_moment');
  final rest = pool.where((p) => !ids.contains(p)).toList()..shuffle(rng);
  ids.addAll(rest.take(3 - ids.length));
  all[n.id] = {'year': l.year, 'ids': ids};
  l.eraWorld['moments'] = all;
  return ids;
}

({String label, String sub, String tag}) eraMomentCard(Life l, EraRules era, Npc n, String id) {
  final where = eraWhere(l, era, n).split(',').first;
  return switch (id) {
    'visit' => (
      label: where == l.city ? 'Call at ${_their(n)} house' : 'Visit ${_them(n)} at $where',
      sub: where == l.city ? 'Across the city' : 'Half a day\'s ride',
      tag: 'SCENE',
    ),
    'portrait' => (label: 'Draw ${_their(n)} portrait', sub: 'Uses your art', tag: 'MINI-GAME'),
    'secret_moment' => (label: _secretLabel(l, era, n)!, sub: '${eraUp(_they(n))} may not answer', tag: 'RISKY'),
    'feast' => (label: 'Hold a feast for ${_them(n)}', sub: eraM(l, eraCost(l, era, 4)), tag: 'SCENE'),
    'ride' => (label: 'Ride out together', sub: 'The hills, a hawk', tag: 'SCENE'),
    'carnival' => (label: 'Take ${_them(n)} to Carnival', sub: 'Masks on', tag: 'SCENE'),
    'plague' => (label: 'Send bread and vinegar', sub: 'The plague is here', tag: 'HELP'),
    'church' => (label: _worship(l), sub: 'Side by side', tag: 'SCENE'),
    'walk' => (label: 'A walk at dusk', sub: 'Just the two of you', tag: 'SCENE'),
    _ => (label: 'Help with what\'s on ${_their(n)} mind', sub: eraHelpLabel(eraMind(l, n) ?? const {}), tag: 'HELP'),
  };
}

String _worship(Life l) => switch (eraFaithOf(l)) {
  'muslim' => 'Friday prayer together',
  'jewish' => 'Shabbat dinner together',
  'kongo' || 'mbundu' => 'Honour the ancestors together',
  'english' => 'Church together on Sunday',
  _ => 'Mass together',
};

EraScene _moment(Life l, EraRules era, Npc n, String id) {
  final card = eraMomentCard(l, era, n, id);
  if (id == 'visit') return eraScene(l, era, n, 'visit');
  final first = _first(n);
  final choices = switch (id) {
    'portrait' => [_c(n, 'portrait', 'Sit ${_them(n)} by the window and draw', 'A mini-game')],
    'secret_moment' => [
      _c(n, 'secret', card.label, 'Ask it straight', lock: n.trust < 60 ? 'Needs more trust' : null),
      _c(n, 'old', 'Talk about the old days instead', 'Leave it for another year'),
    ],
    'feast' => [
      _c(
        n,
        'feast',
        'Lay the table for $first',
        'Roast, wine and musicians · ${eraM(l, eraCost(l, era, 4))}',
        lock: l.money < eraCost(l, era, 4) ? 'Needs ${eraM(l, eraCost(l, era, 4))}' : null,
      ),
    ],
    'ride' => [_c(n, 'ride', 'Ride out at dawn', 'Back by dark')],
    'carnival' => [
      _c(
        n,
        'carnival',
        'Masks on, into the crowd',
        eraM(l, eraCost(l, era, 1)),
        lock: l.money < eraCost(l, era, 1) ? 'Needs ${eraM(l, eraCost(l, era, 1))}' : null,
      ),
    ],
    'plague' || 'help' => [
      if (eraMind(l, n) != null || id == 'plague')
        _c(
          n,
          'help_mind',
          id == 'plague' ? 'Send bread and vinegar' : eraHelpLabel(eraMind(l, n)!),
          id == 'plague' ? 'Left at the door, as the Health Office asks' : (eraMind(l, n)!['text'] as String),
          hint: 'help',
          lock: () {
            final cost = id == 'plague'
                ? eraCost(l, era, 2)
                : eraHelpCost(l, era, eraMind(l, n)!['help'] as String);
            return l.money < cost ? 'Needs ${eraM(l, cost)}' : null;
          }(),
        ),
    ],
    'church' => [_c(n, 'church', card.label, 'Side by side')],
    _ => [_c(n, 'walk', 'Walk by the river', 'Talk or don\'t')],
  };
  return (
    kind: id,
    kicker: 'A moment · ${l.year}',
    title: card.label,
    text: switch (id) {
      'portrait' => '$first sits still for once. The light is good.',
      'secret_moment' => 'You\'ve wanted to ask for years.',
      'plague' => 'The doors are marked and the streets are quiet. $first is shut in.',
      'help' => eraMind(l, n)?['text'] as String? ?? '',
      _ => _arrival(l, era, n, false),
    },
    choices: choices,
    game: id == 'portrait',
  );
}

// ---------------- Resolving a choice ----------------

String _quote(Life l, EraRules era, Npc n, String choice, bool good) {
  final lq =
      (((_p(era, 'legendQuotes')[l.legendId] as Map?)?[n.id] as Map?) ??
      const {});
  final topic = _topics[choice]?.$1;
  if (good && lq[topic] != null) return lq[topic] as String;
  if (choice == 'secret' && lq['secret'] != null) return lq['secret'] as String;
  final q = Map<String, dynamic>.from(
    (_p(era, 'quotes')[eraHumourOf(n)] as Map?) ?? const {},
  );
  final list = List<String>.from((q[good ? 'good' : 'bad'] as List?) ?? const ['…']);
  return list[(l.year + n.id.hashCode + choice.hashCode).abs() % list.length];
}

void _bump(Npc n, {int aff = 0, int trust = 0, int respect = 0, int hurt = 0}) {
  n.affection = (n.affection + aff).clamp(0, 100);
  n.trust = (n.trust + trust).clamp(0, 100);
  n.respect = (n.respect + respect).clamp(0, 100);
  n.resentment = (n.resentment + hurt).clamp(0, 100);
  n.familiarity = (n.familiarity + 2).clamp(0, 100);
}

/// Plays a choice in a scene. [score] is the mini-game's (portraits).
EraOutcome eraChoose(
  Life l,
  EraRules era,
  Npc n,
  String kind,
  String choice,
  Random rng, {
  double score = 0.6,
}) {
  eraNature(l, era, n);
  final scene = eraScene(l, era, n, kind);
  final c = scene.choices.where((c) => c.id == choice).firstOrNull;
  if (c == null || c.lock != null) {
    return (quote: '', text: c?.lock ?? 'Not now.', deltas: const [], memory: null, learned: null, good: false);
  }
  if (eraWays.contains(kind)) l.usedActions.add('era_way_${n.id}_$kind');
  // Moments are used up.
  if (!eraWays.contains(kind)) {
    final all = Map<String, dynamic>.from((l.eraWorld['moments'] as Map?) ?? const {});
    final m = all[n.id] as Map?;
    if (m != null) {
      all[n.id] = {
        'year': m['year'],
        'ids': List<String>.from(m['ids'] as List)..remove(kind == 'visit' ? 'visit' : kind),
      };
      l.eraWorld['moments'] = all;
    }
  }
  n.lastContactAge = l.age;
  final first = _first(n);
  final (topic, risk) = _topics[choice] ?? _giftTopic(choice) ?? ('', 0);
  final likes = eraLikesOf(n).contains(topic);
  final hates = eraDislikeOf(n) == topic;
  var chance = 0.72 + (likes ? 0.22 : 0) - (hates ? 0.45 : 0) - risk * 0.15;
  chance += (n.trust - 50) / 250;
  if (choice == 'portrait') chance = 0.25 + score * 0.7;
  final good = rng.nextDouble() < chance.clamp(0.05, 0.97);
  final deltas = <String>[];
  String? memory;
  String? learned;
  var text = '';
  void d(String label, int v) {
    if (v != 0) deltas.add('$label ${v > 0 ? '+' : ''}$v');
  }

  int aff = 0, trust = 0, respect = 0, hurt = 0, happy = 0;
  if (good) {
    aff = likes ? 7 : 4;
    trust = 3;
    happy = likes ? 5 : 3;
  } else {
    aff = hates ? -6 : -2;
    hurt = hates ? 8 : 3;
    happy = -2;
  }
  switch (choice) {
    case 'old':
      text = good
          ? 'You stay until the lamps. Old names, old rooms, the time the river flooded.'
          : 'The old days brought up an old hurt. The talk dried up.';
      if (good) memory = 'The day you remembered the old days together';
    case 'news':
      text = good
          ? 'You told ${_them(n)} everything: who married, who fell, what the criers said. ${eraUp(_they(n))} hung on every word.'
          : '${eraUp(_they(n))} had heard it all already, and said so.';
    case 'work':
      respect = good ? 5 : -2;
      text = good
          ? '$first asked good questions about your work, and listened to the answers.'
          : '$first thinks your trade is beneath the family, and let you know it.';
    case 'troubles':
      final mind = eraMind(l, n);
      text = mind == null
          ? '${eraUp(_they(n))} says all is well. Perhaps it is.'
          : 'In the end ${_they(n)} told you: ${eraLower(mind['text'] as String)}';
      trust += 2;
      if (mind != null) n.info['mind'] = {...mind, 'told': true};
    case 'secret':
    case 'honest':
      if (good) {
        trust += 6;
        aff += 2;
        text = choice == 'secret'
            ? '$first was quiet a long time. Then ${_they(n)} told you. You walk home with it.'
            : '$first told you, plainly. Some of it stung. Most of it was love.';
        memory = 'The day you asked, and ${_they(n)} answered';
      } else {
        hurt += 6;
        text = '$first turned away. "Not today." The door closed a little between you.';
      }
    case 'letter_warm':
    case 'letter_news':
    case 'letter_drawing':
      final keeps = eraLikesOf(n).contains('letter');
      if (keeps) aff += 3;
      text = good
          ? '$first wrote back within the month.${choice == 'letter_drawing' ? ' Your drawing is pinned by ${_their(n)} bed.' : ''}'
          : 'No answer came. Maybe the carrier lost it.';
      if (choice == 'letter_drawing' && l.legendId == 'leonardo') {
        l.eraWorld['pages'] = _int(l.eraWorld['pages']) + 1;
        deltas.add('+1 notebook page');
      }
    case 'messenger':
      l.money -= eraCost(l, era, 1);
      text = 'The messenger was there and back in a day, with $first\'s answer and a basket of eggs.';
    case 'advice':
      respect += 4;
      text = good
          ? '$first thought it over and gave you advice you\'ll use for years.'
          : '$first\'s advice was to do the opposite of what you wanted. Typical.';
    case 'loan':
      if (good && n.bond >= 45) {
        final amount = eraCost(l, era, 10 + rng.nextInt(20));
        l.money += amount;
        n.debt -= amount;
        text = '$first lent you ${eraM(l, amount)}. "Pay me back when you can. You will, won\'t you?"';
      } else {
        aff -= 2;
        text = '$first said no. Money spoils families, ${_they(n)} said.';
      }
    case 'favour':
      if (good) {
        respect += 2;
        l.eraWorld['favour'] = l.year;
        text = '$first put in a word for you with someone who matters. Doors open a little easier this year.';
      } else {
        text = '$first said ${_they(n)}\'d try. You doubt ${_they(n)} did.';
      }
    case 'speak':
      if (good) {
        respect += 5;
        hurt = max(0, hurt - 4);
        n.resentment = max(0, n.resentment - 8);
        text = 'Voices were raised. Then, at last, you understood each other.';
      } else {
        hurt += 4;
        text = 'It got worse. Things were said that can\'t be unsaid.';
      }
    case 'wound':
      if (good) {
        trust += 4;
        n.resentment = max(0, n.resentment - 10);
        text = '$first went white, then said ${_they(n)} was sorry. You never thought you\'d hear it.';
        memory = 'The day the old wound was spoken of';
      } else {
        hurt += 10;
        aff -= 4;
        text = '$first threw it back at you, and worse.';
      }
    case 'leave':
      hurt += 3;
      text = 'You walked out. The door said it for you.';
    case 'apologise':
    case 'peace_gift':
    case 'mediator':
      if (choice == 'peace_gift') l.money -= eraCost(l, era, 3);
      if (good) {
        n.resentment = max(0, n.resentment - 20);
        n.memories.removeWhere((m) => m.negative && m.intensity < 4);
        text = '$first took your hands. It\'s mended, mostly.';
      } else {
        n.resentment = max(0, n.resentment - 5);
        text = '$first heard you out, but it will take more than that.';
      }
    case 'feast':
      l.money -= eraCost(l, era, 4);
      text = good
          ? 'Roast kid, good wine and a lutenist. $first stayed until the candles were stubs.'
          : 'The wine was sour and the musicians late. $first left early.';
      if (good) memory = 'The feast you gave';
    case 'ride':
      text = good
          ? 'You rode out at dawn and came back at dusk, muddy and happy.'
          : 'A horse went lame and you walked home in silence.';
    case 'carnival':
      l.money -= eraCost(l, era, 1);
      text = good
          ? 'Masks on, you danced behind the floats until dawn.'
          : 'The crowd split you up and you spent the night looking for each other.';
    case 'church':
      l.eraWorld['standing'] = min(5, eraStanding(l) + (good ? 1 : 0));
      text = good ? 'Side by side, and the neighbours saw you together.' : 'You sat apart, and the neighbours noticed.';
    case 'walk':
      text = good ? 'You walked until the bells and hardly said a word. It was enough.' : 'The walk was awkward. Neither of you knew what to say.';
    case 'portrait':
      text = good
          ? 'The likeness is so true that $first cried a little and asked to keep it.'
          : '$first looked at the drawing for a long time. "Is that how you see me?"';
      if (good) memory = 'The portrait you drew';
      if (l.legendId == 'leonardo') {
        l.eraWorld['pages'] = _int(l.eraWorld['pages']) + 1;
        deltas.add('+1 notebook page');
      }
    case 'help_mind':
      final mind = eraMind(l, n);
      final help = kind == 'plague' ? 'grain' : (mind?['help'] as String? ?? 'talk');
      final cost = kind == 'plague' ? eraCost(l, era, 2) : eraHelpCost(l, era, help);
      l.money -= cost;
      aff = 8;
      trust = 6;
      hurt = 0;
      happy = 5;
      n.resentment = max(0, n.resentment - 5);
      if (mind != null) n.info['mind'] = {...mind, 'solved': true};
      text = switch (help) {
        'grain' => 'Two sacks of grain went out on a cart. $first sent back word: "You shouldn\'t have." And: "Thank you."',
        'money' => 'You sent the money with a note that said nothing about it. $first knows.',
        'physician' => 'The physician came, listened to the chest and prescribed rest and broth. $first is better by spring.',
        'favour' => 'You put in a word. A week later $first had the work.',
        _ => 'You sat with $first until it didn\'t seem so bad.',
      };
      memory = 'The year you helped, without being asked';
    default:
      if (choice.startsWith('gift_')) {
        final g = eraGifts(l, era).where((g) => 'gift_${g['id']}' == choice).firstOrNull;
        if (g != null) {
          l.money -= eraCost(l, era, _int(g['cost']));
          final loved = (g['likes'] as List).any((x) => eraLikesOf(n).contains(x));
          aff = loved ? 8 : 3;
          if (loved) {
            for (final x in g['likes'] as List) {
              if (eraLikesOf(n).contains(x) && !eraKnows(n, 'like:$x')) {
                _learn(n, 'like:$x');
                learned = '${eraUp(_they(n))} loves ${(_p(era, 'likes')[x] as String)}';
              }
            }
          }
          text = loved
              ? '$first\'s face lit up. Exactly right.'
              : '$first thanked you politely and put it on a shelf.';
        }
      }
  }
  // Learning something about them: a good scene reveals one thing.
  if (learned == null && (good || hates)) {
    if (hates && !eraKnows(n, 'dislike')) {
      _learn(n, 'dislike');
      learned = '${eraUp(_they(n))} hates ${_p(era, 'dislikes')[eraDislikeOf(n)]}';
    } else if (likes && !eraKnows(n, 'like:$topic')) {
      _learn(n, 'like:$topic');
      learned = '${eraUp(_they(n))} loves ${_p(era, 'likes')[topic]}';
    } else if (!eraKnows(n, 'humour') && rng.nextDouble() < 0.5) {
      _learn(n, 'humour');
      final h = _p(era, 'humours')[eraHumourOf(n)] as Map;
      learned = '${eraUp(_they(n))} is ${(h['label'] as String).toLowerCase()}: ${h['about']}';
    }
  }
  _bump(n, aff: aff, trust: trust, respect: respect, hurt: hurt);
  l.stats.add('happiness', happy);
  d('Love', aff);
  d('Trust', trust);
  if (respect != 0) d('Respect', respect);
  if (hurt > 0) d('Hurt', hurt);
  d('Happiness', happy);
  if (memory != null) {
    n.memories.add(NpcMemory(age: l.age, text: memory, valence: 2, intensity: 3, tags: ['era']));
  } else if (!good && hurt >= 6) {
    n.memories.add(NpcMemory(age: l.age, text: 'The day you hurt ${_them(n)}', valence: -2, intensity: 3, tags: ['era', 'hurt']));
  }
  final quote = _quote(l, era, n, choice, good);
  l.feed.add(FeedEntry(l.age, '${n.name}: $text', kind: 'npc', who: n.id));
  return (quote: quote, text: text, deltas: deltas, memory: memory, learned: learned, good: good);
}

// ---------------- They come to you ----------------

typedef EraCall = ({Npc npc, String kind, String text});

List<EraCall> eraCalls(Life l) {
  final out = <EraCall>[];
  for (final raw in (l.eraWorld['calls'] as List?) ?? const []) {
    final m = raw as Map;
    if (m['year'] != l.year) continue;
    final n = l.npcs.where((n) => n.id == m['npc'] && n.alive).firstOrNull;
    if (n != null) out.add((npc: n, kind: m['kind'] as String, text: m['text'] as String));
  }
  return out;
}

EraScene eraCallScene(Life l, EraRules era, EraCall call) {
  final n = call.npc;
  final first = _first(n);
  final choices = switch (call.kind) {
    'invite' => [
      _c(n, 'go', 'Go', 'An evening at ${_their(n)} table'),
      _c(n, 'decline', 'Send your regrets', 'Another time'),
    ],
    'loan' => [
      _c(
        n,
        'give',
        'Lend ${_them(n)} ${eraM(l, eraCost(l, era, 10))}',
        'You may not see it again',
        lock: l.money < eraCost(l, era, 10) ? 'Needs ${eraM(l, eraCost(l, era, 10))}' : null,
      ),
      _c(n, 'refuse', 'Say no', 'Gently'),
    ],
    'neglect' => [
      _c(n, 'apologise', 'Say you\'re sorry, and visit', 'You should have come'),
      _c(n, 'firm', 'Say you\'ve been busy', 'It\'s true'),
    ],
    _ => [
      _c(n, 'congratulate', 'Congratulate ${_them(n)}', 'With a gift · ${eraM(l, eraCost(l, era, 2))}', lock: l.money < eraCost(l, era, 2) ? 'Needs ${eraM(l, eraCost(l, era, 2))}' : null),
      _c(n, 'nod', 'Send your good wishes', 'A word with the carrier'),
    ],
  };
  return (kind: 'call:${call.kind}', kicker: '$first comes to you', title: call.text.split('.').first, text: call.text, choices: choices, game: false);
}

EraOutcome eraAnswerCall(Life l, EraRules era, EraCall call, String choice, Random rng) {
  final n = call.npc;
  l.eraWorld['calls'] = [
    for (final raw in (l.eraWorld['calls'] as List?) ?? const [])
      if (!((raw as Map)['npc'] == n.id && raw['kind'] == call.kind)) raw,
  ];
  n.lastContactAge = l.age;
  final first = _first(n);
  var good = true;
  var text = '';
  final deltas = <String>[];
  int aff = 0, hurt = 0;
  switch (choice) {
    case 'go':
      aff = 6;
      l.stats.add('happiness', 4);
      text = 'A long evening at $first\'s table. You laughed more than you have all year.';
    case 'decline':
      aff = -2;
      good = false;
      text = '$first said it didn\'t matter. It mattered a little.';
    case 'give':
      final amount = eraCost(l, era, 10);
      l.money -= amount;
      n.debt += amount;
      aff = 8;
      text = '$first took the money and held your hand a moment too long. "I won\'t forget."';
    case 'refuse':
      aff = -4;
      hurt = 4;
      good = false;
      text = '$first nodded and didn\'t look at you.';
    case 'apologise':
      aff = 5;
      n.resentment = max(0, n.resentment - 10);
      text = 'You went that week. $first pretended to be cross for about an hour.';
    case 'firm':
      hurt = 5;
      good = false;
      text = '"Busy," $first said. "Everyone is busy."';
    case 'congratulate':
      l.money -= eraCost(l, era, 2);
      aff = 6;
      text = 'Your gift went round the whole family. $first was proud of it.';
    default:
      aff = 2;
      text = 'Your good wishes reached $first by the next carrier.';
  }
  _bump(n, aff: aff, hurt: hurt);
  if (aff != 0) deltas.add('Love ${aff > 0 ? '+' : ''}$aff');
  if (hurt > 0) deltas.add('Hurt $hurt');
  l.feed.add(FeedEntry(l.age, '${n.name}: $text', kind: 'npc', who: n.id));
  return (quote: _quote(l, era, n, choice, good), text: text, deltas: deltas, memory: null, learned: null, good: good);
}

// ---------------- Matches ----------------

/// A match on offer for this life: a family, a name and a dowry.
typedef EraMatch = ({String name, String family, int status, int dowry, bool youPay});

String? eraMatchLock(Life l) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 15) return 'When you are older.';
  if (l.age > 50) return 'Past the age for a match.';
  if (partnerOf(l) != null) return 'You are married.';
  if (eraInside(l)) return 'Not while you are held.';
  if (l.usedActions.contains('era_match')) return 'One match a year.';
  return null;
}

int _dowryFor(Life l, EraRules era, int status) {
  final table = List<int>.from(((era.peopleData['dowry'] as Map?)?['status'] as List?) ?? const [60, 150, 600, 3000]);
  return eraCost(l, era, table[status.clamp(0, table.length - 1)]);
}

EraMatch eraMatchOffer(Life l, EraRules era) {
  final rng = Random(l.seed ^ (l.year * 131));
  final r = era.regionOf(l);
  final them = l.gender == 'male' ? 'female' : 'male';
  final names = them == 'female' ? r.femaleIn(l.year) : r.maleIn(l.year);
  final family = r.surnames.isEmpty ? '' : r.surnames[rng.nextInt(r.surnames.length)];
  final status = (eraStatus(l) + rng.nextInt(3) - 1).clamp(0, 3);
  return (
    name: '${names[rng.nextInt(names.length)]}${family.isEmpty ? '' : ' $family'}',
    family: family.isEmpty ? 'a good family' : 'the $family',
    status: status,
    dowry: _dowryFor(l, era, status),
    youPay: l.gender == 'female',
  );
}

EraScene eraMatchScene(Life l, EraRules era) {
  final m = eraMatchOffer(l, era);
  final dowry = eraM(l, m.dowry);
  final can = !m.youPay || l.money + eraDowryFund(l) >= m.dowry;
  return (
    kind: 'match',
    kicker: 'A match · ${l.year}',
    title: m.name,
    text: m.youPay
        ? 'A broker comes from ${m.family}. Their son ${m.name.split(' ').first} would take you, with a dowry of $dowry.'
        : 'A broker comes from ${m.family}. Their daughter ${m.name.split(' ').first} comes with a dowry of $dowry.',
    choices: [
      (id: 'accept', label: 'Agree the match', sub: m.youPay ? 'Your family pays $dowry' : 'You receive $dowry', hint: '', lock: can ? null : 'Not enough for the dowry'),
      (id: 'haggle', label: 'Haggle over the dowry', sub: 'Could win more, or lose the match', hint: 'risky', lock: can ? null : 'Not enough for the dowry'),
      (id: 'love', label: 'Marry for love instead', sub: 'Against the family\'s wishes', hint: 'risky', lock: null),
      (id: 'refuse', label: 'Refuse', sub: 'Not this one', hint: '', lock: null),
    ],
    game: false,
  );
}

EraOutcome eraAnswerMatch(Life l, EraRules era, String choice, Random rng) {
  final m = eraMatchOffer(l, era);
  l.usedActions.add('era_match');
  String text;
  var dowry = m.dowry;
  var married = false;
  final deltas = <String>[];
  switch (choice) {
    case 'haggle':
      if (rng.nextDouble() < 0.55) {
        dowry = m.youPay ? dowry * 4 ~/ 5 : dowry * 6 ~/ 5;
        married = true;
        text = 'After three meetings and a great deal of wine, the notary wrote in a dowry of ${eraM(l, dowry)}.';
      } else {
        text = 'The other family took offence and found another match.';
        l.stats.add('happiness', -3);
        return (quote: '', text: text, deltas: const [], memory: null, learned: null, good: false);
      }
    case 'accept':
      married = true;
      text = 'The notary drew up the contract, and the families shook hands in church.';
    case 'love':
      married = true;
      dowry = 0;
      for (final n in l.npcs.where((n) => n.circle == 'Family' && n.alive)) {
        n.resentment = min(100, n.resentment + 6);
      }
      deltas.add('Family hurt +6');
      text = 'You married for love, quietly, with two witnesses. Your family took it badly.';
    default:
      return (quote: '', text: 'You sent the broker away.', deltas: const [], memory: null, learned: null, good: false);
  }
  if (!married) return (quote: '', text: text, deltas: deltas, memory: null, learned: null, good: false);
  if (dowry > 0) {
    if (m.youPay) {
      final fromFund = min(eraDowryFund(l), dowry);
      l.eraWorld['dowryFund'] = eraDowryFund(l) - fromFund;
      l.money -= dowry - fromFund;
      l.eraWorld['dowryOut'] = dowry;
      deltas.add('Dowry −${eraM(l, dowry)}');
    } else {
      l.money += dowry;
      deltas.add('Dowry +${eraM(l, dowry)}');
    }
  }
  final spouseName = choice == 'love'
      ? () {
          final r = era.regionOf(l);
          final names = l.gender == 'male' ? r.femaleIn(l.year) : r.maleIn(l.year);
          return '${names[rng.nextInt(names.length)]} ${r.surnames.isEmpty ? '' : r.surnames[rng.nextInt(r.surnames.length)]}'.trim();
        }()
      : m.name;
  final spouse = Npc(
    id: freshNpcId(l, 'spouse'),
    role: l.gender == 'male' ? 'Wife' : 'Husband',
    name: spouseName,
    birthYear: l.year - max(14, l.age + rng.nextInt(9) - (l.gender == 'male' ? 8 : 0)),
    circle: 'Partner',
    bond: choice == 'love' ? 75 : 50,
  )..lastContactAge = l.age;
  spouse.info.addAll({
    'gender': l.gender == 'male' ? 'female' : 'male',
    'stage': 'married',
    'stageSince': l.age,
  });
  l.npcs.add(spouse);
  l.flags['partner'] = Memory(l.age, 'your marriage');
  l.flags['married'] = Memory(l.age, 'marrying ${spouse.name}');
  l.eraWorld['spouse'] = spouse.id;
  l.stats.add('happiness', 6);
  l.feed.add(FeedEntry(l.age, 'You married ${spouse.name}. $text', kind: 'milestone'));
  return (quote: '', text: '$text You are married to ${spouse.name}.', deltas: deltas, memory: null, learned: null, good: true);
}

/// A child old enough for a match, not yet matched.
List<Npc> eraChildrenToMatch(Life l) => [
  for (final n in l.npcs)
    if (n.alive && n.circle == 'Children' && n.ageIn(l.year) >= 12 && n.info['matched'] != true) n,
];

EraScene eraChildMatchScene(Life l, EraRules era, Npc child) {
  final first = _first(child);
  final dowry = _dowryFor(l, era, eraStatus(l));
  final daughter = child.gender == 'female';
  return (
    kind: 'childmatch',
    kicker: 'A match for $first',
    title: 'Who will $first marry?',
    text: daughter
        ? 'Families are asking. A good match needs a dowry of about ${eraM(l, dowry)}${eraDowryFund(l) > 0 ? ' (the dowry fund holds ${eraM(l, eraDowryFund(l))})' : ''}.'
        : 'Families with daughters are asking after $first.',
    choices: [
      (
        id: 'arrange',
        label: 'Arrange a good match',
        sub: daughter ? 'You pay ${eraM(l, dowry)}; the family rises' : 'A dowry comes in; the family rises',
        hint: 'risky',
        lock: daughter && l.money + eraDowryFund(l) < dowry ? 'Not enough for the dowry' : null,
      ),
      (id: 'choose', label: 'Let $first choose', sub: 'Against custom, but $first will love you for it', hint: '', lock: null),
      (id: 'wait', label: 'Wait a few years', sub: 'There\'s time', hint: '', lock: null),
    ],
    game: false,
  );
}

EraOutcome eraAnswerChildMatch(Life l, EraRules era, Npc child, String choice, Random rng) {
  final first = _first(child);
  final dowry = _dowryFor(l, era, eraStatus(l));
  final deltas = <String>[];
  String text;
  var good = true;
  switch (choice) {
    case 'arrange':
      child.info['matched'] = true;
      if (child.gender == 'female') {
        final fromFund = min(eraDowryFund(l), dowry);
        l.eraWorld['dowryFund'] = eraDowryFund(l) - fromFund;
        l.money -= dowry - fromFund;
        deltas.add('Dowry −${eraM(l, dowry)}');
      } else {
        l.money += dowry;
        deltas.add('Dowry +${eraM(l, dowry)}');
      }
      l.eraWorld['standing'] = min(5, eraStanding(l) + 1);
      deltas.add('Standing +1');
      eraNature(l, era, child);
      if (eraHumourOf(child) == 'choleric' || rng.nextDouble() < 0.3) {
        _bump(child, aff: -8, hurt: 6);
        deltas.add('$first hurt +6');
        good = false;
        text = '$first was married in the spring, white-faced, and did not look at you during the feast.';
      } else {
        _bump(child, aff: 3);
        text = 'The match was made, and $first seems content with it.';
      }
    case 'choose':
      child.info['matched'] = true;
      _bump(child, aff: 8, trust: 4);
      deltas.add('$first love +8');
      text = '$first chose for ${_them(child)}self. The neighbours talked. $first will never forget it.';
    default:
      return (quote: '', text: 'You told the brokers to come back in a few years.', deltas: const [], memory: null, learned: null, good: true);
  }
  l.feed.add(FeedEntry(l.age, text, kind: 'npc', who: child.id));
  return (quote: '', text: text, deltas: deltas, memory: null, learned: null, good: good);
}

// ---------------- The year ----------------

/// One year of people at a birthday: new worries, people who come to
/// you, and widowhood.
List<String> eraPeopleYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  final people = eraPeople(l);
  final calls = <Map<String, dynamic>>[];
  for (final n in people) {
    eraNature(l, era, n);
    if (_close(n) && rng.nextDouble() < 0.45) _newMind(l, era, n, rng);
  }
  // Someone comes to you, at most once a year.
  final close = people.where(_close).toList();
  if (close.isNotEmpty && l.age >= 10 && rng.nextDouble() < 0.4) {
    final n = close[rng.nextInt(close.length)];
    final first = _first(n);
    final neglected = l.age - n.lastContactAge >= 3;
    final kind = neglected
        ? 'neglect'
        : const ['invite', 'loan', 'news'][rng.nextInt(3)];
    final text = switch (kind) {
      'neglect' => '$first sends word: it has been ${l.age - n.lastContactAge} years. Have you forgotten ${_them(n)}?',
      'invite' => '$first invites you to supper. ${eraUp(_they(n))} says there\'ll be eel pie.',
      'loan' => '$first comes to the door, embarrassed. ${eraUp(_they(n))} needs a loan.',
      _ => '$first has news: a betrothal in the family, and you\'re invited to the feast.',
    };
    calls.add({'npc': n.id, 'kind': kind, 'text': text, 'year': l.year});
  }
  l.eraWorld['calls'] = calls;
  // Widowhood: a widow's dowry comes back to her.
  final spouseId = l.eraWorld['spouse'] as String?;
  if (spouseId != null) {
    final s = l.npcs.where((n) => n.id == spouseId).firstOrNull;
    if (s != null && !s.alive && l.eraWorld['widowed'] != true) {
      l.eraWorld['widowed'] = true;
      final dowry = _int(l.eraWorld['dowryOut']);
      if (l.gender == 'female' && dowry > 0) {
        l.money += dowry;
        out.add('As a widow, your dowry of ${eraM(l, dowry)} comes back to you, as the law says.');
      }
    }
  }
  return out;
}
