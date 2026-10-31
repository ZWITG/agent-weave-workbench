import 'dart:math';

import 'actions.dart';
import 'celebrity.dart' show addFame, addImage, gainFollowers;
import 'friends.dart';
import 'models.dart';
import 'storylet.dart';

// Music: write songs, release them as singles or albums, and earn from
// streams for years. It starts quietly under Hobbies; after a few songs are
// written and released, the chapter Road to the Underground opens the
// Music category with small tasks to grow. Hits chart, bring fame and
// followers, and catch the eye of record labels; gigs and tours turn
// listeners into money.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

String streamsLabel(num n) => n >= 1000000000
    ? '${(n / 1000000000).toStringAsFixed(1)}B'
    : n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M'
    : n >= 1000
    ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k'
    : '${n.round()}';

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'fame',
  scene: true,
  choices: choices,
);

const genres = <String, String>{
  'pop': 'Pop',
  'rock': 'Rock',
  'hiphop': 'Hip-hop',
  'ballad': 'Ballad',
  'electronic': 'Electronic',
  'folk': 'Folk',
};

/// The sound everyone wants this year, the same for every life.
String trendingGenre(int year) =>
    genres.keys.elementAt(Random(year * 53).nextInt(genres.length));

/// What a stream pays you, after the platform's cut.
const perStream = 0.004;

/// Your share of royalties on a label (they keep the rest).
const labelShare = 0.25;

List<Map<String, dynamic>> unreleased(Life l) =>
    l.songs.where((s) => s['out'] != true).toList();
List<Map<String, dynamic>> released(Life l) =>
    l.songs.where((s) => s['out'] == true).toList();

/// Monthly listeners: your fanbase, built up by good releases.
int listenersOf(Life l) => (l.music['fans'] as int?) ?? 0;

/// Fans stop growing as you near the biggest stars' audiences.
const fanCeiling = 60000000;

bool playsInstrument(Life l) =>
    l.flags.containsKey('instrument') ||
    l.school.lessons == 'Piano' ||
    l.school.clubs.contains('Band') ||
    l.school.electives.contains('Music');

// ---------------- Writing ----------------

const _first = [
  'Midnight',
  'Paper',
  'Golden',
  'Broken',
  'Neon',
  'Summer',
  'Electric',
  'Quiet',
  'Wild',
  'Silver',
  'Lonely',
  'Burning',
];
const _second = [
  'Hearts',
  'Streets',
  'Rain',
  'Dreams',
  'Signals',
  'Highways',
  'Letters',
  'Fire',
  'Lights',
  'Waves',
  'Promises',
  'Ghosts',
];

/// Writes a song; [score] is the mini-game result (0..1).
ActionResult writeSong(Life l, Random rng, String genre, double? score) {
  if (unreleased(l).length >= 12) {
    return ActionResult(
      'Your notebook is full of unreleased songs. Release some first.',
    );
  }
  // Quality comes from you: songwriting skill most of all, then how well
  // you played the mini-game, your creativity and an instrument. Luck only
  // nudges it.
  final skill = songwritingOf(l);
  final played = score ?? 0.6;
  final q =
      (skill * 0.55 +
              l.stats['creativity'] * 0.2 +
              played * 25 +
              (playsInstrument(l) ? 5 : 0) +
              rng.nextInt(9) -
              4)
          .round()
          .clamp(1, 100);
  // Every song makes you better; a well-played session teaches more.
  final gain = max(
    1,
    1 + (played * 3).round() + (skill < 30 ? 1 : 0) - (skill >= 70 ? 2 : 0),
  );
  l.music['skill'] = min(100, skill + gain);
  final title =
      '${_first[rng.nextInt(_first.length)]} ${_second[rng.nextInt(_second.length)]}';
  l.songs.add({
    'title': title,
    'genre': genre,
    'q': q,
    'age': l.age,
    'out': false,
    'streams': 0,
    'rate': 0,
    'best': 0,
  });
  l.stats.add('creativity', 1);
  l.stats.add('happiness', 1);
  final unlock = _checkUnlock(l);
  final verdict = q >= 80
      ? 'This might be the best thing you have ever written.'
      : q >= 55
      ? 'It is good. Really good, actually.'
      : q >= 35
      ? 'It is fine. The chorus needs work.'
      : 'Even you skip it.';
  return ActionResult(
    'You wrote "$title", a ${genres[genre]!.toLowerCase()} song. $verdict',
    [
      'Songwriting ${songwritingOf(l)} (+$gain)',
      '${unreleased(l).length} unreleased song${unreleased(l).length == 1 ? '' : 's'}',
      if (genre == trendingGenre(l.year))
        '${genres[genre]} is what everyone wants this year',
      ?unlock,
    ],
  );
}

/// Songwriting skill, 0 to 100: it grows with every song you write.
int songwritingOf(Life l) => (l.music['skill'] as int?) ?? 0;

/// An established artist (a top-40 hit, or 100k monthly listeners) is
/// boosted by fame, followers and public image; before that, songs stand
/// on their own.
bool establishedArtist(Life l) =>
    l.flags.containsKey('charted') || listenersOf(l) >= 100000;

String qualityLabel(int q) => q >= 85
    ? 'a potential hit'
    : q >= 65
    ? 'strong'
    : q >= 45
    ? 'decent'
    : q >= 25
    ? 'rough'
    : 'weak';

/// Gives a song your own title. Returns the title it ended up with: the
/// trimmed name, or the old one if the name is blank.
String renameSong(Life l, Map<String, dynamic> song, String name) {
  final t = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return song['title'] as String;
  song['title'] = t.length > 40 ? t.substring(0, 40).trim() : t;
  return song['title'] as String;
}

// ---------------- Road to the Underground ----------------

/// The Music category and its chapter open once you have written three
/// songs and released two.
bool musicUnlocked(Life l) => l.music['road'] != null;
bool roadDone(Life l) => l.music['roadDone'] != null;
List<String> roadProgress(Life l) =>
    List<String>.from(l.music['road'] as List? ?? const []);

String? _checkUnlock(Life l) {
  if (musicUnlocked(l) || l.songs.length < 3 || released(l).length < 2) {
    return null;
  }
  l.music['road'] = <String>[];
  l.sceneQueue.add('underground_intro');
  return 'A new chapter begins: Road to the Underground';
}

/// The chapter's tasks: id, what to do, and what it gives you.
const roadTasks = <(String, String, String)>[
  ('open_mic', 'Play your first open mic', 'Charisma and your first real fans'),
  (
    'studio',
    'Release a song recorded in a real studio',
    'A producer who wants to work with you',
  ),
  (
    'jam',
    'Jam with local musicians',
    'A bandmate, and a song better than you could write alone',
  ),
  (
    'streams',
    'Reach 25,000 streams',
    'An underground music blog writes about you',
  ),
  ('merch', 'Sell merch at a show', 'Money, and people wearing your name'),
];

int totalStreams(Life l) =>
    released(l).fold<int>(0, (a, s) => a + ((s['streams'] as int?) ?? 0));

/// Marks a chapter task done and gives its reward. Returns notes for the
/// result, empty when nothing changed.
List<String> roadTask(Life l, String id, Random rng) {
  if (!musicUnlocked(l) || roadDone(l)) return const [];
  final done = roadProgress(l);
  if (done.contains(id)) return const [];
  done.add(id);
  l.music['road'] = done;
  final title = roadTasks.firstWhere((t) => t.$1 == id).$2;
  final notes = <String>['Road to the Underground: $title ✓'];
  switch (id) {
    case 'open_mic':
      l.stats.add('charisma', 2);
      gainFollowers(l, 500);
    case 'studio':
      final p = meetFriend(l, rng, role: 'Music producer', bond: 55, spread: 8);
      notes.add('${p.name} (producer) joined your friends');
    case 'jam':
      l.stats.add('creativity', 2);
    case 'streams':
      addFame(l, 4);
      gainFollowers(l, 2000);
      notes.add('Fame up: an underground blog wrote about you');
    case 'merch':
      l.money += 500;
  }
  if (done.length == roadTasks.length) {
    l.music['roadDone'] = l.age;
    l.flags['underground'] = Memory(l.age, 'making a name in the underground');
    addFame(l, 5);
    l.stats.add('happiness', 5);
    notes.add(
      'Chapter complete: you are a name in the underground. Labels and promoters are listening now.',
    );
  }
  return notes;
}

/// Each birthday: streams keep counting, so the streams task can finish.
List<String> musicYear(Life l, Random rng) => [
  for (final n in roadCheck(l, rng))
    if (!n.startsWith('Fame up')) n,
];

/// Checks the chapter tasks that come from numbers rather than actions.
List<String> roadCheck(Life l, Random rng) => [
  if (totalStreams(l) >= 25000) ...roadTask(l, 'streams', rng),
];

// ---------------- Releasing ----------------

/// Where a release lands: 1, 10, 40, 100, or 0 for no chart.
int chartFor(int streams) => streams >= 50000000
    ? 1
    : streams >= 20000000
    ? 10
    : streams >= 5000000
    ? 40
    : streams >= 1000000
    ? 100
    : 0;

String chartLabel(int c) => switch (c) {
  1 => 'Number 1',
  10 => 'the top 10',
  40 => 'the top 40',
  100 => 'the top 100',
  _ => 'no chart',
};

/// Releases [songs] (one for a single, several for an album). [how] is
/// home, studio or label. Returns the result text and notes.
ActionResult releaseSongs(
  Life l,
  List<Map<String, dynamic>> songs,
  String how,
  Random rng, {
  bool album = false,
}) {
  final signed = l.music['label'] != null;
  final cost = how == 'studio' ? 2000 * songs.length : 0;
  l.money -= cost;
  // Until you are established, only people who already know your music
  // listen; after that, your fame and followers bring everyone else.
  final established = establishedArtist(l);
  final followers = l.followers.values.fold<int>(0, (a, b) => a + b);
  final audience =
      1500 +
      listenersOf(l) +
      (established ? followers * 0.2 + l.fame * 3000 : 0);
  final promo = how == 'label' ? 3.0 : 1.0;
  var total = 0;
  for (final s in songs) {
    final q =
        ((s['q'] as int) + (how == 'home' ? -10 : (how == 'studio' ? 6 : 10)))
            .clamp(1, 100);
    final hit =
        pow(q / 50, 3) *
        (s['genre'] == trendingGenre(l.year) ? 1.8 : 1) *
        (established ? 1 + l.image / 200 : 1) *
        (album ? 1.2 : 1);
    // A little luck either way; the song itself decides.
    final streams =
        (audience * hit * promo * (0.85 + rng.nextDouble() * 0.3) * 5)
            .round();
    // Good songs turn listeners into fans; weak ones barely do.
    final fans = listenersOf(l);
    final newFans =
        (streams * 0.05 * q / 100 * (1 - fans / fanCeiling)).round();
    l.music['fans'] = (fans + max(0, newFans)).clamp(0, fanCeiling);
    s['out'] = true;
    s['released'] = l.age;
    s['streams'] = streams;
    s['rate'] = streams;
    s['best'] = chartFor(streams);
    s['label'] = how == 'label';
    total += streams;
  }
  // The best chart place among them (1 is best; 0 means no chart).
  final charts = [
    for (final s in songs)
      if ((s['best'] as int) > 0) s['best'] as int,
  ];
  final top = charts.isEmpty ? 0 : charts.reduce(min);
  // Hits make you famous; famous makes the next one bigger.
  final fameUp = switch (top) {
    1 => 12,
    10 => 7,
    40 => 4,
    100 => 2,
    _ => total > 200000 ? 1 : 0,
  };
  addFame(l, fameUp + (album ? 2 : 0));
  final newFans = gainFollowers(l, total ~/ 40);
  if (top > 0 && top <= 10) addImage(l, 3);
  if (top > 0 && top <= 40) {
    l.flags['charted'] = Memory(
      l.age,
      'reaching ${chartLabel(top)} with "${songs.first['title']}"',
    );
  }
  if (top > 0 &&
      top <= 40 &&
      !signed &&
      roadDone(l) &&
      !l.music.containsKey('offered')) {
    l.sceneQueue.add('label_offer');
  }
  l.stats.add('happiness', top > 0 ? 6 : 1);
  final what = album
      ? 'your album "${l.music['albumTitle'] ?? songs.first['title']}"'
      : '"${songs.first['title']}"';
  final text = switch (top) {
    1 =>
      'You released $what and it went to Number 1. Your phone has not stopped ringing.',
    10 =>
      'You released $what and it climbed into the top 10. Radio stations are playing it.',
    40 => 'You released $what and it made the top 40. People are humming it.',
    100 => 'You released $what and it scraped into the top 100. A start.',
    _ =>
      total > 100000
          ? 'You released $what. It found a loyal little audience.'
          : 'You released $what. Your mum streamed it eleven times.',
  };
  final unlock = _checkUnlock(l);
  return ActionResult(text, [
    ?unlock,
    if (how == 'studio') ...roadTask(l, 'studio', rng),
    ...roadCheck(l, rng),
    if (cost > 0) 'Money −${_m(cost)} (studio)',
    '${streamsLabel(total)} streams in the first year',
    if (top > 0) 'Charted: ${chartLabel(top)}',
    if (newFans > 0) '+${streamsLabel(newFans)} followers',
    if (fameUp > 0) 'Fame up',
    'Royalties are paid each birthday',
  ]);
}

// ---------------- Each birthday ----------------

/// Royalties for the year, paid at the birthday (economy.dart), after
/// which every song's streams fade a little.
int musicRoyalties(Life l) {
  var pay = 0.0;
  for (final s in released(l)) {
    final rate = (s['rate'] as int?) ?? 0;
    final share = s['label'] == true ? labelShare : 1.0;
    pay += rate * perStream * share;
    s['streams'] = ((s['streams'] as int?) ?? 0) + rate;
    // Old songs fade, but a hit keeps a long tail.
    s['rate'] = (rate * ((s['best'] as int? ?? 0) == 1 ? 0.7 : 0.55)).round();
  }
  // Some fans drift away every year unless you keep releasing.
  l.music['fans'] = (listenersOf(l) * 0.85).round();
  final advance = (l.music['recoup'] as int?) ?? 0;
  if (advance > 0 && pay > 0) {
    // The label keeps your royalties until the advance is paid back.
    final kept = min(advance, pay.round());
    l.music['recoup'] = advance - kept;
    pay -= kept;
  }
  return pay.round();
}

// ---------------- Scenes ----------------

Storylet? musicScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'release_pick':
      final songs = unreleased(l)
        ..sort((a, b) => (b['q'] as int).compareTo(a['q'] as int));
      if (songs.isEmpty) return null;
      return _scene(
        id,
        'Which song goes out as your next single? ${genres[trendingGenre(l.year)]} is what everyone wants this year.',
        [
          for (final s in songs.take(6))
            Choice(
              label: '"${s['title']}" · ${genres[s['genre']]}',
              outcome: '',
              risk: 'Sounds ${qualityLabel(s['q'] as int)}',
              run: (l, rng) {
                l.sceneQueue.insert(0, 'release_how:${l.songs.indexOf(s)}');
                return 'You listen to "${s['title']}" one more time. Yes. This one.';
              },
            ),
          Choice(label: 'Not yet', outcome: 'You kept polishing.'),
        ],
      );
    case 'release_how':
    case 'album_how':
      final album = id == 'album_how';
      final i = args.isEmpty ? -1 : int.tryParse(args.first) ?? -1;
      final songs = album
          ? unreleased(l)
          : [if (i >= 0 && i < l.songs.length) l.songs[i]];
      if (songs.isEmpty) return null;
      final signed = l.music['label'] as String?;
      final studio = 2000 * songs.length;
      if (album) {
        l.music['albumTitle'] = songs.first['title'];
      }
      return _scene(
        id,
        album
            ? 'An album of ${songs.length} songs, named after "${songs.first['title']}". How do you put it out?'
            : 'How do you put out "${songs.first['title']}"?',
        [
          Choice(
            label: 'Record it at home',
            outcome: '',
            risk: 'Free · sounds homemade',
            run: (l, rng) =>
                _released(releaseSongs(l, songs, 'home', rng, album: album)),
          ),
          Choice(
            label: 'Book a studio (${_m(studio)})',
            outcome: '',
            risk: 'Professional sound',
            needsMoney: studio,
            run: (l, rng) =>
                _released(releaseSongs(l, songs, 'studio', rng, album: album)),
          ),
          if (signed != null)
            Choice(
              label: 'Through $signed',
              outcome: '',
              risk: 'Big promotion · they keep most of the royalties',
              run: (l, rng) =>
                  _released(releaseSongs(l, songs, 'label', rng, album: album)),
            ),
        ],
      );
    case 'underground_intro':
      return _scene(
        id,
        'Someone you have never met shared your song with "this is so good". A local promoter messaged: "Play my Thursday night?" Bedroom songs are turning into something. This is the road to the underground.',
        [
          Choice(
            label: 'Take it seriously',
            outcome: 'You cleared a corner for a microphone and wrote "Road to the Underground" on the first page of a new notebook. Music is in Activities now, with a few small things to do next.',
            run: (l, rng) {
              l.stats.add('happiness', 4);
              return null;
            },
          ),
          Choice(
            label: 'Keep it fun for now',
            outcome: 'No pressure. The notebook and the promoter\'s number are there when you want them, under Music in Activities.',
          ),
        ],
      );
    case 'label_offer':
      if (l.music['label'] != null) return null;
      l.music['offered'] = l.age;
      const labels = [
        'Northstar Records',
        'Velvet Room Music',
        'Bright Static',
      ];
      final name = labels[Random(l.seed + l.age).nextInt(labels.length)];
      final advance = (30000 + listenersOf(l) * 0.4 + l.fame * 2000).round();
      return _scene(
        id,
        '$name heard your song and want to sign you: a ${_m(advance)} advance, real promotion and studio time. They keep 75% of your royalties, and your share pays back the advance first.',
        [
          Choice(
            label: 'Sign with $name',
            outcome: '',
            run: (l, rng) {
              l.music['label'] = name;
              l.music['recoup'] = advance;
              l.money += advance;
              l.flags['signed'] = Memory(l.age, 'signing with $name');
              return 'You signed. The advance landed: ${_m(advance)}. Your next release goes out with a real marketing team behind it.';
            },
          ),
          Choice(
            label: 'Stay independent',
            outcome: 'You kept your masters and all your royalties. Slower, but yours.',
          ),
        ],
      );
  }
  return null;
}

String _released(ActionResult r) =>
    [r.text, ...r.notes.map((n) => '$n.')].join(' ');

// ---------------- Activities ----------------

final musicActions = <GameAction>[
  GameAction(
    id: 'write_song',
    label: 'Write a song',
    // A quiet hobby at first; the Music category opens with the chapter.
    category: 'Hobbies',
    miniGame: 'rhythm',
    scored: (l, rng, score) => writeSong(l, rng, 'pop', score),
    keywords: ['song', 'write', 'music', 'lyrics', 'compose'],
    minAge: 10,
    repeatable: true,
    hint: (l) =>
        'Songwriting ${songwritingOf(l)} · ${unreleased(l).length} unreleased · play the mini-game well for better songs',
    // The genre is picked as an option (variants.dart).
    run: (l, rng) => writeSong(l, rng, 'pop', null),
  ),
  GameAction(
    id: 'release_single',
    label: 'Release a song online',
    category: 'Hobbies',
    repeatable: true,
    keywords: ['release', 'single', 'song', 'stream', 'chart'],
    minAge: 13,
    extraCheck: (l) => unreleased(l).isEmpty ? 'Write a song first' : null,
    hint: (l) => 'Streams pay every year · hits make you famous',
    run: (l, rng) {
      l.sceneQueue.add('release_pick');
      return ActionResult('You open your folder of songs.');
    },
  ),
  GameAction(
    id: 'release_album',
    label: 'Release an album',
    category: 'Music',
    keywords: ['album', 'record', 'release', 'music'],
    minAge: 16,
    extraCheck: (l) => !musicUnlocked(l)
        ? 'Release a few songs first'
        : unreleased(l).length < 5
        ? 'Needs 5 unreleased songs (${unreleased(l).length} so far)'
        : null,
    hint: (l) => 'Every unreleased song at once · a bigger splash',
    run: (l, rng) {
      l.sceneQueue.add('album_how');
      return ActionResult('You put the tracklist in order.');
    },
  ),
  GameAction(
    id: 'play_gig',
    label: 'Play a gig',
    category: 'Music',
    keywords: ['gig', 'concert', 'play live', 'open mic', 'show'],
    minAge: 14,
    extraCheck: (l) => !musicUnlocked(l) ? 'Release a few songs first' : null,
    hint: (l) => listenersOf(l) >= 5000
        ? 'Your fans will come'
        : 'A small room, a few friends',
    run: (l, rng) {
      final crowd = 20 + rng.nextInt(60) + listenersOf(l) ~/ 50;
      final pay = (crowd * (8 + rng.nextInt(8))).clamp(30, 20000);
      l.money += pay;
      l.stats.add('happiness', 3);
      l.stats.add('charisma', 1);
      l.music['gigs'] = ((l.music['gigs'] as int?) ?? 0) + 1;
      final fans = gainFollowers(l, crowd * 3);
      final road = roadTask(l, 'open_mic', rng);
      return ActionResult(
        crowd > 500 ? 'The room was packed and sang every word back at you.' : 'Twenty-odd people, a sticky floor and one very enthusiastic fan at the front.',
        [
          'Money +${_m(pay)}',
          '$crowd people came',
          if (fans > 0) '+${streamsLabel(fans)} followers',
          ...road,
        ],
      );
    },
  ),
  GameAction(
    id: 'go_on_tour',
    label: 'Go on tour',
    category: 'Music',
    keywords: ['tour', 'concerts', 'arena', 'world tour', 'road'],
    minAge: 18,
    extraCheck: (l) => !roadDone(l) && l.fame < 30
        ? 'Finish Road to the Underground first'
        : listenersOf(l) < 50000 && l.fame < 30
        ? 'Needs 50k monthly listeners or some fame'
        : null,
    hint: (l) => '${streamsLabel(listenersOf(l))} monthly listeners · tiring',
    run: (l, rng) {
      final tickets =
          (listenersOf(l) * (0.3 + rng.nextDouble() * 0.3) + l.fame * 800)
              .round();
      final cut = l.music['label'] != null ? 0.6 : 0.8;
      final pay = (tickets * 45 * cut).round();
      l.money += pay;
      addFame(l, 3);
      gainFollowers(l, tickets ~/ 2);
      l.stats.add('health', -4);
      l.stats.add('happiness', 4);
      return ActionResult(
        'Thirty cities, a tour bus that smelled of crisps and a crowd that knew every word.',
        [
          'Money +${_m(pay)} after crew and venues',
          '${streamsLabel(tickets)} tickets sold',
          'Fame up',
          'Health −4',
        ],
      );
    },
  ),
  GameAction(
    id: 'road_underground',
    label: 'Road to the Underground',
    category: 'Music',
    keywords: ['underground', 'chapter', 'music tasks', 'road'],
    minAge: 10,
    repeatable: true,
    extraCheck: (l) => !musicUnlocked(l) ? 'Release a few songs first' : null,
    hint: (l) => roadDone(l)
        ? 'Chapter complete'
        : '${roadProgress(l).length} of ${roadTasks.length} done',
    run: (l, rng) {
      final done = roadProgress(l);
      return ActionResult(
        roadDone(l)
            ? 'You made it: the underground knows your name. Labels and promoters are listening.'
            : 'Small steps from bedroom songs to a real following.',
        [
          for (final (id, title, reward) in roadTasks)
            '${done.contains(id) ? '✓' : '○'} $title · $reward',
        ],
      );
    },
  ),
  GameAction(
    id: 'jam_session',
    label: 'Jam with local musicians',
    category: 'Music',
    keywords: ['jam', 'band', 'musicians', 'rehearsal', 'collab'],
    minAge: 14,
    extraCheck: (l) => !musicUnlocked(l) ? 'Release a few songs first' : null,
    hint: (l) => 'Write a song together · meet people',
    run: (l, rng) {
      final mate = meetFriend(l, rng, role: 'Bandmate', bond: 55, spread: 4);
      final r = writeSong(
        l,
        rng,
        genres.keys.elementAt(rng.nextInt(genres.length)),
        1,
      );
      // Two heads: the song comes out better than alone.
      if (l.songs.isNotEmpty) {
        l.songs.last['q'] = min(100, (l.songs.last['q'] as int) + 12);
      }
      return ActionResult(
        'A sticky rehearsal room, four people and one idea that would not leave anyone alone. ${mate.name.split(' ').first} plays a mean bass. ${r.text}',
        ['${mate.name} joined your friends', ...roadTask(l, 'jam', rng)],
      );
    },
  ),
  GameAction(
    id: 'sell_merch',
    label: 'Sell merch at a show',
    category: 'Music',
    keywords: ['merch', 't-shirts', 'tote bags', 'stall'],
    minAge: 14,
    extraCheck: (l) => !musicUnlocked(l)
        ? 'Release a few songs first'
        : ((l.music['gigs'] as int?) ?? 0) == 0
        ? 'Play a gig first'
        : null,
    hint: (l) => 'T-shirts and tote bags with your name on',
    run: (l, rng) {
      final sold = 10 + rng.nextInt(30) + listenersOf(l) ~/ 200;
      final pay = sold * 15;
      l.money += pay;
      return ActionResult(
        'You set up a table by the door. Strangers walked out wearing your name.',
        ['Money +${_m(pay)}', '$sold sold', ...roadTask(l, 'merch', rng)],
      );
    },
  ),
  GameAction(
    id: 'your_music',
    label: 'Your music',
    category: 'Music',
    keywords: ['discography', 'streams', 'songs', 'my music'],
    minAge: 10,
    repeatable: true,
    extraCheck: (l) => l.songs.isEmpty ? 'Write a song first' : null,
    hint: (l) =>
        '${released(l).length} released · ${streamsLabel(listenersOf(l))} monthly listeners',
    run: (l, rng) {
      final out = released(l)
        ..sort((a, b) => (b['streams'] as int).compareTo(a['streams'] as int));
      return ActionResult(
        l.music['label'] != null
            ? 'Signed to ${l.music['label']}. ${streamsLabel(listenersOf(l))} monthly listeners.'
            : 'Independent. ${streamsLabel(listenersOf(l))} monthly listeners.',
        [
          'Songwriting skill ${songwritingOf(l)}',
          establishedArtist(l)
              ? 'Established artist: your fame and followers boost every release'
              : 'Your songs stand on their own until your first top-40 hit',
          for (final s in out.take(6))
            '"${s['title']}" (${s['released']}): ${streamsLabel(s['streams'] as int)} streams${(s['best'] as int) > 0 ? ', ${chartLabel(s['best'] as int)}' : ''}',
          '${unreleased(l).length} unreleased',
        ],
      );
    },
  ),
];
