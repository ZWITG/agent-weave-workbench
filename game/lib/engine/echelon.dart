import 'dart:math';

import 'actions.dart';
import 'celebrity.dart' show addFame, addImage;
import 'currency.dart' show currencyOf, activeCountry;
import 'dynasty.dart' show heirsOf;
import 'elite.dart'
    show upperEchelon, eliteThreshold, billion, foundationFund, richerThan;
import 'models.dart';
import 'storylet.dart';
import 'variants.dart' show ActionVariant;

// The Echelon: what life at the very top is for, once money stops being the
// problem. Players of life sims say the same thing about the late game:
// once you have bought the biggest house, money stops mattering and the
// game goes quiet. So the top of Relivable is built around goals that
// money alone does not settle:
//
// - Tiers: Centimillionaire ($100M), Half-billionaire, Billionaire ("three
//   commas"), Decabillionaire ($10B), Centibillionaire ($100B) and Richest
//   Alive. Each new tier is a moment, and unlocks bigger plays.
// - The List: eight named rival tycoons whose fortunes rise and fall every
//   year. Climb past them, feud with them, buy them out. They age, and
//   their heirs take over (and usually lose some of it).
// - Influence (0–100): earned from your newspaper, foundation, politics and
//   rank, and spent on power moves: lobbying, burying a story, a summit,
//   a hostile takeover, making a head of government.
// - Moonshots (from $10B): fusion power, a Mars outpost, curing a disease,
//   cleaning the oceans, an AI lab. Years of funding, a real chance of
//   failure, and a place in history if it works.
// - Heirs: about 70% of billionaire heirs "lose a comma" (UBS/PwC), mostly
//   because they were never prepared. Groom your heirs: a prepared heir
//   keeps the family office, the foundation and your seat on the List; an
//   unprepared one loses a quarter of it to lawyers and hangers-on.
//
// Numbers: Forbes counted a record 3,428 billionaires in March 2026, the
// richest worth $839 billion. A full security detail costs $2M+ a year.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

/// Short money for the List and the Echelon screen, in the currency of
/// where you live (\$4.2B, ¥310M).
String bigMoney(int v) {
  final (rate, symbol) = currencyOf(activeCountry);
  final a = (v.abs() * rate);
  String f(double x, String u) =>
      '${x >= 100 ? x.toStringAsFixed(0) : x.toStringAsFixed(1)}$u';
  final s = a >= 1e12
      ? f(a / 1e12, 'T')
      : a >= 1e9
      ? f(a / 1e9, 'B')
      : a >= 1e6
      ? f(a / 1e6, 'M')
      : a.round().toString();
  return '${v < 0 ? '−' : ''}$symbol$s';
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'money',
  scene: true,
  choices: choices,
);

// ---------------- Tiers ----------------

typedef Tier = ({String name, String short, int floor, String unlocks});

const echelonTiers = <Tier>[
  (
    name: 'Centimillionaire',
    short: '\$100M',
    floor: 100000000,
    unlocks: 'Islands, superyachts, art, a seat on the List',
  ),
  (
    name: 'Half-billionaire',
    short: '\$500M',
    floor: 500000000,
    unlocks: 'Power moves: lobbying, burying stories, summits',
  ),
  (
    name: 'Billionaire',
    short: '\$1B',
    floor: 1000000000,
    unlocks: 'Hostile takeovers and backing a government',
  ),
  (
    name: 'Decabillionaire',
    short: '\$10B',
    floor: 10000000000,
    unlocks: 'Moonshots: fusion, Mars, cures, an AI lab',
  ),
  (
    name: 'Centibillionaire',
    short: '\$100B',
    floor: 100000000000,
    unlocks: 'Buying a social network, founding a city',
  ),
  (
    name: 'Richest Alive',
    short: '#1',
    floor: 0,
    unlocks: 'The whole world watching',
  ),
];

/// Your tier now (0..5), or -1 below the line.
int echelonTier(Life l) {
  if (!upperEchelon(l)) return -1;
  if (rankOf(l) == 1) return 5;
  var t = 0;
  for (var i = 0; i < 5; i++) {
    if (l.netWorth >= echelonTiers[i].floor) t = i;
  }
  return t;
}

/// The highest tier you have reached in this life.
int tierReached(Life l) => (l.echelon['tier'] as int?) ?? -1;

// ---------------- The List: rival tycoons ----------------

typedef _Seed = (String name, String sector, double vol, bool woman);

const _rivalPool = <_Seed>[
  ('Viktor Hale', 'Rockets and electric cars', 0.32, false),
  ('Margaux Delacroix-Bell', 'Luxury fashion house', 0.12, true),
  ('Ren Takahashi', 'Chips and AI', 0.28, false),
  ('Augustus Crane', 'Oil and shipping (old money)', 0.10, false),
  ('Priya Raman', 'Pharmaceuticals', 0.16, true),
  ('Dmitri Volkov', 'Metals and "logistics"', 0.22, false),
  ('Adaeze Okafor', 'Telecoms and banking', 0.14, true),
  ('Sloane Whitaker', 'Hedge fund', 0.24, true),
  ('Lucas Ferreira', 'Mining and farmland', 0.15, false),
  ('Ingrid Solberg', 'Energy and wind', 0.13, true),
];

/// Fortunes from the top of the List down, in game dollars.
const _ladder = [420e9, 210e9, 95e9, 38e9, 12e9, 3.6e9, 1.1e9, 0.35e9];

List<Map<String, dynamic>> rivals(Life l) => [
  for (final r in (l.echelon['rivals'] as List?) ?? const [])
    Map<String, dynamic>.from(r as Map),
];

void _saveRivals(Life l, List<Map<String, dynamic>> rs) =>
    l.echelon['rivals'] = rs;

/// Deals the eight rivals the first time you reach the List.
void ensureRivals(Life l) {
  if (l.echelon['rivals'] != null) return;
  final rng = Random(l.seed * 7 + 99);
  final pool = [..._rivalPool]..shuffle(rng);
  _saveRivals(l, [
    for (var i = 0; i < 8; i++)
      {
        'id': 'r$i',
        'name': pool[i].$1,
        'sector': pool[i].$2,
        'vol': pool[i].$3,
        'she': pool[i].$4,
        'worth': (_ladder[i] * (0.85 + rng.nextDouble() * 0.3)).round(),
        'born': l.year - 45 - rng.nextInt(35),
        'feud': 0,
        'gen': 1,
      },
  ]);
}

/// Your place on the List (1 = richest), counting the eight rivals.
int rankOf(Life l) =>
    1 + rivals(l).where((r) => (r['worth'] as int) > l.netWorth).length;

/// The List as rows: (name, sector, worth, you?, feud).
List<({String name, String sector, int worth, bool you, int feud})> theList(
  Life l,
) {
  final rows = [
    for (final r in rivals(l))
      (
        name: r['name'] as String,
        sector: r['sector'] as String,
        worth: r['worth'] as int,
        you: false,
        feud: r['feud'] as int,
      ),
    (name: l.fullName, sector: 'You', worth: l.netWorth, you: true, feud: 0),
  ]..sort((a, b) => b.worth.compareTo(a.worth));
  return rows;
}

String _first(Map<String, dynamic> r) => (r['name'] as String).split(' ').first;
String _they(Map<String, dynamic> r) => r['she'] == true ? 'she' : 'he';
String _their(Map<String, dynamic> r) => r['she'] == true ? 'her' : 'his';

// ---------------- Influence ----------------

int influence(Life l) => (l.echelon['influence'] as int?) ?? 0;

void addInfluence(Life l, int d) =>
    l.echelon['influence'] = (influence(l) + d).clamp(0, 100);

String influenceLabel(int v) => v >= 80
    ? 'Kingmaker'
    : v >= 60
    ? 'Power broker'
    : v >= 40
    ? 'Well connected'
    : v >= 20
    ? 'Known in the right rooms'
    : 'New money';

// ---------------- Moonshots ----------------

typedef Moonshot = ({
  String id,
  String name,
  int cost,
  int years,
  int odds,
  String win,
  String lose,
});

const moonshots = <Moonshot>[
  (
    id: 'fusion',
    name: 'Fusion power',
    cost: 8000000000,
    years: 6,
    odds: 40,
    win: 'Your reactor ran for a full year on seawater. Energy will never cost the same again.',
    lose: 'The plasma would not hold. Your fusion company closed with a museum exhibit and a lot of patents.',
  ),
  (
    id: 'mars',
    name: 'A Mars outpost',
    cost: 20000000000,
    years: 8,
    odds: 35,
    win: 'Four people woke up on Mars this morning in a habitat with your name over the door.',
    lose: 'The last lander broke up on the way down. The programme ended with a minute of silence.',
  ),
  (
    id: 'cure',
    name: 'Cure a disease',
    cost: 5000000000,
    years: 5,
    odds: 55,
    win: 'The trial results came in: it works. A disease that killed millions is now treatable.',
    lose: 'The final trial failed. The research was published openly so the next team starts further ahead.',
  ),
  (
    id: 'oceans',
    name: 'Clean the oceans',
    cost: 2000000000,
    years: 4,
    odds: 65,
    win: 'Your fleet cleared the great garbage patch. Satellite photos showed blue where it used to be grey.',
    lose: 'The barriers broke apart in the storms. Some of the plastic came out; most of it is still there.',
  ),
  (
    id: 'ai_lab',
    name: 'Build an AI lab',
    cost: 12000000000,
    years: 5,
    odds: 45,
    win: 'Your lab\'s model made headlines everywhere, and its value made your fortune look small.',
    lose: 'Rivals shipped first. Your lab was sold for parts to a company you used to compete with.',
  ),
];

Moonshot moonshotById(String id) => moonshots.firstWhere((m) => m.id == id);

Map<String, dynamic>? activeMoonshot(Life l) =>
    (l.echelon['moonshot'] as Map?)?.cast<String, dynamic>();

List<String> moonshotsDone(Life l) =>
    List<String>.from((l.echelon['moonshots_won'] as List?) ?? const []);

/// What a running moonshot costs each year (cash-flow line).
int moonshotYearly(Life l) {
  final m = activeMoonshot(l);
  if (m == null) return 0;
  final s = moonshotById(m['id'] as String);
  return (s.cost * 0.7 / s.years).round();
}

// ---------------- Heirs ----------------

int readiness(Life l, Npc heir) =>
    ((l.echelon['ready'] as Map?)?[heir.id] as int?) ?? 0;

void _setReady(Life l, Npc heir, int v) {
  final m = Map<String, dynamic>.from((l.echelon['ready'] as Map?) ?? {});
  m[heir.id] = v.clamp(0, 100);
  l.echelon['ready'] = m;
}

List<Npc> adultHeirs(Life l) =>
    heirsOf(l).where((c) => c.ageIn(l.year) >= 16).toList();

// ---------------- Legacy ----------------

/// A score for what you leave behind: giving, buildings, moonshots, rank.
int legacyScore(Life l) {
  var s = 0;
  s += min(300, foundationFund(l) ~/ 10000000);
  if (l.marks.contains('pledge')) s += 120;
  if (l.flags.containsKey('museum')) s += 60;
  if (l.flags.containsKey('endowed')) s += 40;
  if (l.flags.containsKey('founded_city')) s += 200;
  s += 180 * moonshotsDone(l).length;
  s += 40 * max(0, tierReached(l));
  final best = (l.echelon['best_rank'] as int?) ?? 9;
  s += max(0, 9 - best) * 15;
  if (l.flags.containsKey('richest_alive')) s += 150;
  return s;
}

String legacyLabel(int s) => s >= 700
    ? 'History book'
    : s >= 450
    ? 'A name that lasts'
    : s >= 250
    ? 'Remembered'
    : s >= 100
    ? 'Noticed'
    : 'Just rich';

// ---------------- Each birthday ----------------

/// Runs every birthday once you are in the upper echelon.
List<String> echelonYear(Life l, Random rng) {
  final feed = <String>[];
  if (!upperEchelon(l)) return feed;
  ensureRivals(l);

  // Rivals' fortunes move; the old ones die and their heirs take over.
  final rs = rivals(l);
  final before = rankOf(l);
  for (final r in rs) {
    final vol = (r['vol'] as num).toDouble();
    final g = 0.06 + (rng.nextDouble() * 2 - 1) * vol;
    r['worth'] = max(50000000, ((r['worth'] as int) * (1 + g)).round());
    r['feud'] = max(0, (r['feud'] as int) - 4);
    final age = l.year - (r['born'] as int);
    if (age > 78 && rng.nextInt(100) < (age - 75) * 2) {
      final old = r['name'] as String;
      final surname = old.split(' ').last;
      const heirs = ['Theo', 'Isla', 'Max', 'Anya', 'Leo', 'Clara', 'Felix'];
      final heir = heirs[rng.nextInt(heirs.length)];
      r['name'] = '$heir $surname';
      r['she'] = const {'Isla', 'Anya', 'Clara'}.contains(heir);
      r['born'] = l.year - 30 - rng.nextInt(15);
      r['worth'] = ((r['worth'] as int) * 0.72).round();
      r['gen'] = (r['gen'] as int) + 1;
      r['feud'] = 0;
      feed.add(
        '$old died at $age. $heir $surname takes over the fortune, minus the lawyers, the tax office and a cousin or two. Their family fell down the List.',
      );
    }
  }
  _saveRivals(l, rs);
  final rank = rankOf(l);
  final best = (l.echelon['best_rank'] as int?) ?? 99;
  if (rank < best) l.echelon['best_rank'] = rank;
  if (rank < before) {
    final passed = theList(l).where((row) => !row.you).toList()[rank - 1];
    l.stats.add('happiness', 3);
    feed.add(
      rank == 1
          ? 'The List came out. Your name is at the top of it.'
          : 'The List came out: you are number $rank, past ${passed.name}.',
    );
  } else if (rank > before) {
    feed.add('The List came out: you slipped to number $rank.');
  }

  // Richest alive.
  if (rank == 1 && !l.flags.containsKey('richest_alive')) {
    l.flags['richest_alive'] = Memory(
      l.age,
      'becoming the richest person alive',
    );
    l.sceneQueue.add('echelon_top');
  }

  // Tiers: a moment each time you reach a new one.
  final t = echelonTier(l);
  if (t > tierReached(l)) {
    l.echelon['tier'] = t;
    if (t > 0) {
      addFame(l, 2 + t);
      feed.add(
        'You are now a ${echelonTiers[t].name.toLowerCase()}. ${echelonTiers[t].unlocks}.',
      );
    }
  }

  // Influence: earned by what you own and do, and it fades if unused.
  var gain = max(0, echelonTier(l)) * 2;
  if (l.has('media')) gain += 4;
  if (l.marks.contains('foundation')) gain += 3;
  if (l.flags.containsKey('kingmaker')) gain += 3;
  if (l.marks.contains('pledge')) gain += 2;
  addInfluence(l, gain - (influence(l) * 0.08).round());

  // A moonshot: a year of work, and at the end, the result.
  final m = activeMoonshot(l);
  if (m != null) {
    final s = moonshotById(m['id'] as String);
    m['year'] = (m['year'] as int) + 1;
    l.echelon['moonshot'] = m;
    if ((m['year'] as int) >= s.years) {
      l.sceneQueue.add('echelon_moonshot');
    } else {
      feed.add(switch (rng.nextInt(3)) {
        0 =>
          '${s.name}: year ${m['year']} of ${s.years}. The engineers say "promising", which you have learned means nothing yet.',
        1 =>
          '${s.name}: a breakthrough in the lab and a setback in the field, in the same month.',
        _ =>
          '${s.name}: year ${m['year']} of ${s.years}. You visited the site in a hard hat and everyone pretended you were helping.',
      });
    }
  }

  // Heirs' readiness slips if you do not keep at it.
  for (final h in adultHeirs(l)) {
    final r = readiness(l, h);
    if (r > 0) _setReady(l, h, r - 3);
  }

  // A rival makes a move (not while you are in a cell).
  if (l.prison == null &&
      !l.sceneQueue.any(
        (s) => s.startsWith('echelon_') || s.startsWith('elite_'),
      ) &&
      rng.nextInt(100) < 30) {
    l.sceneQueue.add('echelon_rival:${rs[rng.nextInt(rs.length)]['id']}');
  } else if (rng.nextInt(100) < 35) {
    final r = rs[rng.nextInt(rs.length)];
    feed.add(switch (rng.nextInt(5)) {
      0 =>
        '${r['name']} bought a vineyard, a castle and a football club in the same week.',
      1 =>
        '${r['name']} was on every front page for a divorce settlement bigger than most countries\' budgets.',
      2 =>
        '${r['name']} said in an interview that people like you are "a passing fashion".',
      3 =>
        '${r['name']}\'s new yacht is twelve metres longer than anyone else\'s. ${_they(r)[0].toUpperCase()}${_they(r).substring(1)} made sure everyone knew.',
      _ =>
        '${r['name']} gave a university \$500 million and asked for nothing except ${_their(r)} name in letters three metres high.',
    });
  }
  return feed;
}

/// Yearly costs of the echelon (cash-flow lines).
List<(String, int)> echelonCosts(Life l) => [
  if (activeMoonshot(l) != null)
    (
      'Moonshot: ${moonshotById(activeMoonshot(l)!['id'] as String).name}',
      -moonshotYearly(l),
    ),
];

// ---------------- Scenes ----------------

Storylet? echelonScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'echelon_rival':
      final r = rivals(l).where((r) => r['id'] == args.firstOrNull).firstOrNull;
      if (r == null) return null;
      return _rivalScene(l, r);
    case 'echelon_top':
      return _scene(
        id,
        'At 6am a journalist called for a comment. Overnight, markets moved, and the List was re-run: you are the richest person alive. Every camera in the world now points at you.',
        [
          Choice(
            label: 'Enjoy the view',
            outcome: 'You stood on the roof at sunrise and let yourself have it. Just this once.',
            run: (l, rng) {
              l.stats.add('happiness', 10);
              addFame(l, 10);
              return null;
            },
          ),
          Choice(
            label: 'Announce what you will do with it',
            outcome: 'You stood at a lectern and promised to give most of it away while you are alive. The speech is still quoted.',
            run: (l, rng) {
              addImage(l, 15);
              l.stats.add('karma', 6);
              addInfluence(l, 15);
              return null;
            },
          ),
          Choice(
            label: 'Disappear for a while',
            outcome: 'You turned off your phone and spent a month on a boat no one could find. The mystery made you more famous.',
            run: (l, rng) {
              l.stats.add('happiness', 6);
              addFame(l, 6);
              return null;
            },
          ),
        ],
      );
    case 'echelon_moonshot':
      final m = activeMoonshot(l);
      if (m == null) return null;
      final s = moonshotById(m['id'] as String);
      return _scene(
        id,
        '${s.name}: ${s.years} years and ${_m(s.cost)} later, the day of the result. The team is gathered in a room that is very quiet.',
        [
          Choice(
            label: 'Watch it live',
            outcome: '',
            risk: 'Odds rise with your smarts',
            run: (l, rng) => _finishMoonshot(l, rng, s),
          ),
          Choice(
            label: 'Wait for the call',
            outcome: '',
            run: (l, rng) => _finishMoonshot(l, rng, s),
          ),
        ],
      );
    case 'echelon_groom':
      final heirs = adultHeirs(l);
      if (heirs.isEmpty) return null;
      return _scene(
        id,
        'Your family office put it bluntly: most fortunes are gone by the third generation, because nobody prepared the heirs. Who do you work on this year?',
        [
          for (final h in heirs.take(4)) ...[
            Choice(
              label:
                  '${h.name.split(' ').first}: a seat on the board (${readiness(l, h)}% ready)',
              outcome: '',
              run: (l, rng) => _groom(l, h, 22, 'board'),
            ),
          ],
          if (heirs.isNotEmpty)
            Choice(
              label:
                  'Make ${heirs.first.name.split(' ').first} work somewhere else first',
              outcome: '',
              run: (l, rng) => _groom(l, heirs.first, 15, 'away'),
            ),
          Choice(
            label: 'Family council for all of them',
            outcome: '',
            run: (l, rng) {
              for (final h in heirs) {
                _setReady(l, h, readiness(l, h) + 10);
                h.addFacets(trust: 3);
              }
              return 'A weekend in a country house with an adviser, a whiteboard and the whole family. There was shouting on day one and a plan by day three. Everyone is a little more ready.';
            },
          ),
        ],
      );
  }
  return null;
}

String _groom(Life l, Npc h, int gain, String how) {
  final first = h.name.split(' ').first;
  _setReady(l, h, readiness(l, h) + gain);
  h.addFacets(respect: 4, trust: 2);
  return how == 'board'
      ? '$first sat in on every board meeting this year, asked one very good question, and was asked to stay. Readiness ${readiness(l, h)}%.'
      : '$first spent the year working for someone who did not know the surname. They came back humbler and much sharper. Readiness ${readiness(l, h)}%.';
}

String _finishMoonshot(Life l, Random rng, Moonshot s) {
  l.echelon.remove('moonshot');
  final odds = (s.odds + (l.stats['smarts'] - 50) ~/ 4).clamp(10, 85);
  if (rng.nextInt(100) < odds) {
    l.echelon['moonshots_won'] = [...moonshotsDone(l), s.id];
    l.flags['moonshot_${s.id}'] = Memory(l.age, s.name.toLowerCase());
    addFame(l, 15);
    addImage(l, 15);
    addInfluence(l, 20);
    l.stats.add('happiness', 12);
    if (s.id == 'ai_lab') l.invested += s.cost * 2;
    if (s.id == 'fusion') l.invested += s.cost;
    return '${s.win} Your name is going into the history books.';
  }
  addImage(l, -6);
  l.stats.add('happiness', -8);
  return s.lose;
}

Storylet _rivalScene(Life l, Map<String, dynamic> r) {
  final first = _first(r);
  final hasTeam = l.assets.any((a) => a.kind == 'team');
  final hasArt = l.assets.any((a) => a.kind == 'valuable');
  void feud(int d) {
    final rs = rivals(l);
    for (final x in rs) {
      if (x['id'] == r['id']) {
        x['feud'] = ((x['feud'] as int) + d).clamp(0, 100);
      }
    }
    _saveRivals(l, rs);
  }

  void worth(double f) {
    final rs = rivals(l);
    for (final x in rs) {
      if (x['id'] == r['id']) x['worth'] = ((x['worth'] as int) * f).round();
    }
    _saveRivals(l, rs);
  }

  final hot = (r['feud'] as int) >= 50;
  if (hot) {
    return _scene(
      'echelon_rival',
      '${r['name']} has been after you all year: a leak here, a poached executive there. This morning ${_their(r)} lawyers sent a letter claiming one of your deals was built on ${_their(r)} idea.',
      [
        Choice(
          label: 'Settle and make peace',
          needsMoney: 50000000,
          outcome:
              'You paid, shook hands for the cameras and agreed never to speak of it again. $first sent flowers.',
          run: (l, rng) {
            l.money -= 50000000;
            feud(-60);
            return null;
          },
        ),
        Choice(
          label: 'Countersue and go to war',
          outcome: '',
          risk: 'A long, public fight',
          run: (l, rng) {
            if (rng.nextInt(100) < 50 + (influence(l) - 40) ~/ 3) {
              worth(0.9);
              addInfluence(l, 8);
              feud(10);
              return 'Your lawyers buried $first in discovery. ${_they(r)[0].toUpperCase()}${_they(r).substring(1)} dropped the case and ${_their(r)} shares fell 10%.';
            }
            l.money -= 120000000;
            addImage(l, -6);
            feud(10);
            return 'The judge sided with $first. It cost you ${_m(120000000)} and a week of very bad headlines.';
          },
        ),
        Choice(
          label: 'Leak what you know about them',
          outcome: '',
          risk: 'Dirty, and it can come back',
          run: (l, rng) {
            l.stats.add('karma', -5);
            worth(0.85);
            feud(25);
            if (rng.nextBool()) {
              addImage(l, -8);
              return 'The story ran, $first\'s company lost 15% in a day, and then a reporter worked out who the source was.';
            }
            return 'The story ran, $first\'s company lost 15% in a day, and nobody ever found out who talked.';
          },
        ),
      ],
    );
  }
  return switch (Random(l.age + (r['worth'] as int)).nextInt(4)) {
    0 when hasTeam => _scene(
      'echelon_rival',
      '${r['name']} wants your sports team, and offered a third more than it is worth, "before you embarrass it further".',
      [
        Choice(
          label: 'Sell it to them',
          outcome: '',
          run: (l, rng) {
            final t = l.assets.firstWhere((a) => a.kind == 'team');
            final price = (t.value * 1.33).round();
            l.assets.remove(t);
            l.money += price;
            feud(-10);
            return 'You sold ${t.name} to $first for ${_m(price)}. The fans booed ${_them(r)} at the first home game.';
          },
        ),
        Choice(
          label: 'Not for any price',
          outcome:
              'You told $first, in public, that the club is not for sale. The fans sang your name.',
          run: (l, rng) {
            feud(15);
            addFame(l, 2);
            return null;
          },
        ),
      ],
    ),
    1 when hasArt => _scene(
      'echelon_rival',
      'At the evening sale, ${r['name']} is bidding against you for the one painting you came for. The room has gone silent.',
      [
        Choice(
          label: 'Keep bidding',
          needsMoney: 90000000,
          outcome: '',
          risk: 'Expensive pride',
          run: (l, rng) {
            final price = 60000000 + rng.nextInt(30) * 1000000;
            l.money -= price;
            l.assets.add(
              Asset(
                id: 'art_rival${l.age}',
                kind: 'valuable',
                name: 'The painting $first wanted',
                value: (price * 0.8).round(),
                yearlyCost: price ~/ 200,
                since: l.age,
                info: {'dep': -6},
              ),
            );
            feud(15);
            addFame(l, 3);
            return 'You won at ${_m(price)}, the room applauded, and $first walked out before the next lot.';
          },
        ),
        Choice(
          label: 'Let them have it',
          outcome:
              '$first paid a record price. You bought the next lot for a tenth of it and like it more.',
          run: (l, rng) {
            feud(-5);
            return null;
          },
        ),
      ],
    ),
    2 => _scene(
      'echelon_rival',
      '${r['name']} (${r['sector']}) has proposed a joint venture: your money, ${_their(r)} industry, split down the middle.',
      [
        Choice(
          label: 'Go in big',
          needsMoney: 200000000,
          outcome: '',
          risk: 'Could double, could vanish',
          run: (l, rng) {
            l.money -= 200000000;
            if (rng.nextInt(100) < 55) {
              l.money += 420000000;
              feud(-20);
              return 'The venture paid off: ${_m(420000000)} back. $first called you "a real partner" on television.';
            }
            feud(10);
            return 'The venture collapsed, and somehow $first got out first. You lost ${_m(200000000)}.';
          },
        ),
        Choice(
          label: 'Turn it down',
          outcome:
              'You said no politely. $first did it alone, and you watched how it went from a distance.',
          run: (l, rng) => null,
        ),
      ],
    ),
    _ => _scene(
      'echelon_rival',
      '${r['name']} has challenged you, half joking, on live television: "Let us see who gives away more this year."',
      [
        Choice(
          label: 'Accept: give \$100 million',
          needsMoney: 100000000,
          outcome: '',
          run: (l, rng) {
            l.money -= 100000000;
            l.stats.add('karma', 8);
            addImage(l, 10);
            addInfluence(l, 6);
            feud(-15);
            return 'Hospitals, schools and a famine appeal got ${_m(100000000)}. $first matched it. The real winners were the hospitals.';
          },
        ),
        Choice(
          label: 'Laugh it off',
          outcome: 'You laughed it off. The clip of you laughing was used in a lot of articles about the rich.',
          run: (l, rng) {
            addImage(l, -3);
            feud(5);
            return null;
          },
        ),
      ],
    ),
  };
}

String _them(Map<String, dynamic> r) => r['she'] == true ? 'her' : 'him';

// ---------------- Activities ----------------

String? _need(Life l, {int tier = 0, int infl = 0, int cash = 0}) {
  if (!upperEchelon(l)) return 'Not available';
  if (echelonTier(l) < tier) {
    return 'From ${echelonTiers[tier].name.toLowerCase()} (${_m(echelonTiers[tier].floor)})';
  }
  if (influence(l) < infl) return 'Needs $infl influence';
  if (cash > 0 && l.money < cash) return 'Needs ${_m(cash)} in cash';
  return null;
}

GameAction _power(
  String id,
  String label,
  List<String> keywords,
  String note,
  ActionResult Function(Life l, Random rng) run, {
  int tier = 0,
  int infl = 0,
  int cash = 0,
  String? Function(Life l)? extra,
}) => GameAction(
  id: id,
  label: label,
  category: 'Upper echelon',
  keywords: keywords,
  minAge: 18,
  priceNote: note,
  extraCheck: (l) =>
      _need(l, tier: tier, infl: infl, cash: cash) ?? extra?.call(l),
  run: run,
);

final echelonActions = <GameAction>[
  _power(
    'power_lobby',
    'Lobby for a tax break',
    ['lobby', 'tax', 'politics', 'influence', 'law'],
    '25 influence · a law written with you in mind',
    (l, rng) {
      addInfluence(l, -25);
      final gain = min(2000000000, (l.netWorth * 0.006).round());
      l.money += gain;
      addImage(l, -5);
      l.stats.add('karma', -3);
      return ActionResult(
        'A clause appeared on page 412 of a bill nobody read. It saves you ${_m(gain)} this year.',
        ['Money +${_m(gain)}', 'Influence −25', 'Image down'],
      );
    },
    tier: 1,
    infl: 25,
  ),
  _power(
    'power_bury',
    'Kill a story',
    ['story', 'press', 'scandal', 'image', 'reputation', 'bury'],
    '20 influence · one phone call',
    (l, rng) {
      addInfluence(l, -20);
      addImage(l, 12);
      l.marks.remove('fallen');
      return ActionResult(
        'You made one phone call. The story about you was "pending further checks" until everyone forgot it existed.',
        ['Image +12', 'Influence −20'],
      );
    },
    tier: 1,
    infl: 20,
  ),
  _power(
    'power_summit',
    'Host a summit of the powerful',
    ['summit', 'forum', 'davos', 'conference', 'leaders'],
    '\$5M · presidents, founders and you, in one room',
    (l, rng) {
      l.money -= 5000000;
      addInfluence(l, 18);
      addFame(l, 4);
      final rs = rivals(l);
      for (final r in rs) {
        r['feud'] = max(0, (r['feud'] as int) - 10);
      }
      _saveRivals(l, rs);
      return ActionResult(
        'Three presidents, two of your rivals and a famous economist at your lake house. Everyone left with your private number.',
        ['Money −${_m(5000000)}', 'Influence +18', 'Rivalries cool'],
      );
    },
    tier: 1,
    cash: 5000000,
  ),
  _power(
    'power_takeover',
    'Hostile takeover of a rival',
    ['takeover', 'buy out', 'rival', 'acquire', 'merger'],
    '40 influence · a tenth of their fortune in cash',
    (l, rng) {
      l.sceneQueue.add('echelon_takeover');
      return ActionResult('Your bankers start buying shares quietly.');
    },
    tier: 2,
    infl: 40,
  ),
  _power(
    'power_kingmaker',
    'Make a head of government',
    ['president', 'prime minister', 'election', 'kingmaker', 'politics'],
    '50 influence · \$250M · a friend at the top',
    (l, rng) {
      l.money -= 250000000;
      addInfluence(l, -50);
      if (rng.nextInt(100) < 55 + (influence(l) ~/ 4)) {
        l.flags['kingmaker'] = Memory(l.age, 'making a head of government');
        addInfluence(l, 45);
        addImage(l, -8);
        return ActionResult(
          'Your candidate won by a landslide nobody predicted. On election night they thanked "a friend" by name. Yours.',
          ['Money −${_m(250000000)}', 'Influence up', 'Image down'],
        );
      }
      addImage(l, -10);
      return ActionResult(
        'Your candidate lost, and the winner remembers who paid for the other side.',
        ['Money −${_m(250000000)}', 'Influence −50', 'Image −10'],
      );
    },
    tier: 2,
    infl: 50,
    cash: 250000000,
  ),
  _power(
    'groom_heir',
    'Prepare your heirs',
    ['heir', 'succession', 'children', 'inheritance', 'dynasty', 'board'],
    'Most fortunes are lost by unprepared heirs',
    (l, rng) {
      l.sceneQueue.add('echelon_groom');
      return ActionResult('You clear an afternoon in your diary.');
    },
    extra: (l) =>
        adultHeirs(l).isEmpty ? 'Needs children aged 16 or over' : null,
  ),
  GameAction(
    id: 'moonshot',
    label: 'Fund a moonshot',
    category: 'Upper echelon',
    keywords: [
      'moonshot',
      'fusion',
      'mars',
      'cure',
      'ocean',
      'ai',
      'space',
      'legacy',
    ],
    minAge: 18,
    priceNote: 'Billions, years, and a real chance it fails',
    extraCheck: (l) =>
        _need(l, tier: 3) ??
        (activeMoonshot(l) != null ? 'One at a time' : null),
    run: (l, rng) => ActionResult('You open a folder marked "impossible".'),
  ),
  _power(
    'buy_network',
    'Buy a social network',
    ['social network', 'social media', 'platform', 'buy app', 'media empire'],
    '\$40B · the town square, and everyone in it',
    (l, rng) {
      l.money -= 40000000000;
      l.assets.add(
        Asset(
          id: 'network${l.age}',
          kind: 'media',
          name: 'A social network',
          value: 32000000000,
          yearlyCost: 1500000000,
          since: l.age,
          info: {'dep': 4},
        ),
      );
      addInfluence(l, 30);
      addFame(l, 12);
      addImage(l, -10);
      return ActionResult(
        'You bought a social network with three billion users. Half of them are now furious with you, which is good for engagement.',
        ['Money −${_m(40000000000)}', 'Influence +30', 'Image −10'],
      );
    },
    tier: 4,
    cash: 40000000000,
    extra: (l) => l.assets.any((a) => a.name == 'A social network')
        ? 'You already own one'
        : null,
  ),
  _power(
    'found_city',
    'Found a city',
    ['city', 'charter city', 'build a city', 'town', 'utopia'],
    '\$25B · streets, schools and your name on the map',
    (l, rng) {
      l.money -= 25000000000;
      final name = '${l.surname}ville';
      l.assets.add(
        Asset(
          id: 'city${l.age}',
          kind: 'city',
          name: name,
          value: 18000000000,
          yearlyCost: 300000000,
          since: l.age,
          info: {'dep': -2},
        ),
      );
      l.flags['founded_city'] = Memory(l.age, 'founding $name');
      addFame(l, 15);
      addInfluence(l, 15);
      return ActionResult(
        'On empty desert, surveyors marked out $name: a hospital, a university, a tram line and room for a million people. The first families moved in this spring.',
        ['Money −${_m(25000000000)}', 'Legacy up'],
      );
    },
    tier: 4,
    cash: 25000000000,
    extra: (l) =>
        l.flags.containsKey('founded_city') ? 'You founded one' : null,
  ),
];

/// "Fund a moonshot": one option per project.
final moonshotVariants = <ActionVariant>[
  for (final s in moonshots)
    ActionVariant(
      id: s.id,
      label: s.name,
      detail:
          '${_m(s.cost)} over ${s.years} years · ${s.odds >= 55
              ? 'good odds'
              : s.odds >= 40
              ? 'a coin toss'
              : 'long odds'}',
      check: (l) => l.money < (s.cost * 0.3).round()
          ? 'Needs ${_m((s.cost * 0.3).round())} up front'
          : null,
      run: (l, rng, who, score) {
        final upfront = (s.cost * 0.3).round();
        l.money -= upfront;
        l.echelon['moonshot'] = {'id': s.id, 'year': 0};
        addFame(l, 5);
        addInfluence(l, 5);
        return ActionResult(
          'You announced it on a stage in front of a giant screen: ${s.name.toLowerCase()}, in ${s.years} years. Half the room called it visionary, the other half a vanity project.',
          [
            'Money −${_m(upfront)} now',
            'About ${_m((s.cost * 0.7 / s.years).round())} a year for ${s.years} years',
          ],
        );
      },
    ),
];

/// The takeover: pick which rival.
Storylet? takeoverScene(Life l) {
  final rs = rivals(l)
    ..sort((a, b) => (a['worth'] as int).compareTo(b['worth'] as int));
  return _scene(
    'echelon_takeover',
    'Your bankers have built quiet stakes in your rivals\' companies. One phone call and you can launch a hostile bid. Who do you go after?',
    [
      for (final r in rs.take(5))
        Choice(
          label:
              '${r['name']} · ${r['sector']} (${_m((r['worth'] as int) ~/ 10)})',
          outcome: '',
          lock: (l) => l.money < (r['worth'] as int) ~/ 10
              ? 'Needs ${_m((r['worth'] as int) ~/ 10)} in cash'
              : null,
          risk: 'Regulators may block it',
          run: (l, rng) {
            final price = (r['worth'] as int) ~/ 10;
            addInfluence(l, -40);
            final all = rivals(l);
            final x = all.firstWhere((y) => y['id'] == r['id']);
            if (rng.nextInt(100) < 30) {
              l.money -= price ~/ 20;
              x['feud'] = min(100, (x['feud'] as int) + 30);
              _saveRivals(l, all);
              return 'Regulators blocked the bid at the last minute. You lost ${_m(price ~/ 20)} in fees, and ${_first(r)} will not forget it.';
            }
            l.money -= price;
            l.invested += (price * 1.35).round();
            x['worth'] = ((x['worth'] as int) * 0.8).round();
            x['feud'] = min(100, (x['feud'] as int) + 40);
            _saveRivals(l, all);
            addFame(l, 5);
            return 'You won control of ${_first(r)}\'s flagship company. Your stake is worth ${_m((price * 1.35).round())}, and ${_first(r)} lost a fifth of ${_their(r)} fortune. The feud is now legendary.';
          },
        ),
      Choice(
        label: 'Call it off',
        outcome: 'You told the bankers to stand down. Some battles are better as threats.',
        run: (l, rng) {
          addInfluence(l, -40);
          return null;
        },
      ),
    ],
  );
}

// ---------------- Inheritance ----------------

/// When an heir takes over an upper-echelon life: a prepared heir keeps
/// the machinery (family office, foundation, influence, the List); an
/// unprepared one loses a quarter to lawyers and hangers-on.
/// Returns the share after that, and the line for the feed.
(int, String?) inheritEchelon(Life old, Life heir, Npc who, int share) {
  if (!upperEchelon(old)) return (share, null);
  final r = readiness(old, who);
  final first = who.name.split(' ').first;
  // The List and the rivals carry on in the family.
  heir.echelon['rivals'] = old.echelon['rivals'];
  if (r >= 70) {
    for (final m in ['family_office', 'foundation', 'trusts', 'pledge']) {
      if (old.marks.contains(m)) heir.marks.add(m);
    }
    if (old.music['foundation'] != null) {
      heir.music['foundation'] = old.music['foundation'];
    }
    heir.echelon['influence'] = influence(old) ~/ 2;
    return (
      share,
      '$first had been preparing for this for years: the family office, the foundation and the seat at the table passed over without a hitch.',
    );
  }
  if (r < 30) {
    final lost = share ~/ 4;
    return (
      share - lost,
      'Nobody had prepared $first for this. Lawyers, advisers and a cousin with a claim took ${_m(lost)} before the money arrived.',
    );
  }
  return (share, null);
}

/// Tier for the inheritance check below the threshold (used by tests).
bool aboveLine(int worth) => worth >= eliteThreshold;

/// Real-world context for the rich list action.
String worldContext(int worth) =>
    'Forbes counted 3,428 billionaires in 2026. About ${richerThan(worth)} people are richer than you; ${worth >= billion ? 'you are one of the billionaires' : 'you are not a billionaire yet'}.';
