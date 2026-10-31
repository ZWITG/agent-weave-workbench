import 'dart:math';

import 'actions.dart';
import 'crime_jobs.dart' show crimeSkill;
import 'justice.dart';
import 'models.dart';
import 'storylet.dart';
import 'variants.dart';

// The underworld outside prison: heat you can see and manage, dirty money
// that must be laundered (placement, layering, integration), and crews you
// can join, rise through, inform on or try to leave.
//
// Design notes from research: a heat system should be clearly shown and
// give real ways to manage it, or it is only escalating punishment; rival
// crews are tracked apart from police heat; laundering follows the classic
// three stages (cash businesses and small deposits, casino chips and
// layered accounts, then buying property or businesses).

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

bool _roll(Random rng, int pct) => rng.nextInt(100) < pct;

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

// ---------------- Heat ----------------

/// How hot you are with the police, from notoriety and open cases.
int heat(Life l) {
  final cases = l.cases.fold<int>(0, (s, c) => s + (c['evidence'] as int) ~/ 4);
  final dirty = l.dirty > 0 ? min(20, l.dirty ~/ 20000) : 0;
  return (l.notoriety * 3 + cases + dirty).clamp(0, 100).toInt();
}

String heatLabel(int h) => h >= 70
    ? 'Red hot'
    : h >= 45
    ? 'Hot'
    : h >= 20
    ? 'Warm'
    : h > 0
    ? 'Cool'
    : 'Clean';

// ---------------- Crews ----------------

typedef Crew = ({
  String id,
  String name,
  String trade,
  String blurb,
  String crime,
  String stat,
});

const crewList = <Crew>[
  (
    id: 'harbour',
    name: 'The Harbour Syndicate',
    trade: 'smuggling',
    blurb: 'Docks, containers and customs officers on the payroll.',
    crime: 'smuggling',
    stat: 'discipline',
  ),
  (
    id: 'velvet',
    name: 'The Velvet Circle',
    trade: 'fraud',
    blurb: 'Suits, card games and other people\'s money.',
    crime: 'fraud',
    stat: 'charisma',
  ),
  (
    id: 'southside',
    name: 'The Southside Crew',
    trade: 'protection',
    blurb: 'Corners, shops that pay to stay safe, and a short temper.',
    crime: 'extortion',
    stat: 'athleticism',
  ),
];

const crewRanks = ['Associate', 'Soldier', 'Lieutenant', 'Underboss', 'Boss'];

Crew crewById(String id) =>
    crewList.firstWhere((c) => c.id == id, orElse: () => crewList.first);

bool inCrew(Life l) => l.crew['id'] != null;
Crew? crewOf(Life l) => inCrew(l) ? crewById(l.crew['id'] as String) : null;
int crewRank(Life l) => (l.crew['rank'] as int?) ?? 0;
int crewRespect(Life l) => (l.crew['respect'] as int?) ?? 0;
int crewLoyalty(Life l) => (l.crew['loyalty'] as int?) ?? 50;
int rivalry(Life l) => (l.crew['rivalry'] as int?) ?? 0;
bool informant(Life l) => l.crew['informant'] == true;

void _adjust(Life l, String key, int by) => l.crew[key] =
    (((l.crew[key] as int?) ?? (key == 'loyalty' ? 50 : 0)) + by).clamp(0, 100);

/// The crew's share of what you bring in, by rank.
double crewCut(Life l) => const [0.5, 0.4, 0.3, 0.2, 0.0][crewRank(l)];

/// Street reputation: what crews look at before letting you in.
int streetRep(Life l) =>
    (crimeSkill(l) + l.notoriety * 2 + convictions(l) * 8).clamp(0, 100);

/// Moving to another country ends your crew life; returns a feed line
/// (or null when you were not in a crew).
String? leaveCrewForMove(Life l) {
  final crew = crewOf(l);
  if (crew == null) return null;
  _leaveCrew(l);
  return 'Moving abroad ended your time with ${crew.name}. Nobody threw a party.';
}

void _leaveCrew(Life l) {
  final name = crewOf(l)?.name;
  l.crew
    ..clear()
    ..['left'] = name;
}

// ---------------- Dirty money ----------------

/// Each birthday: dirty money fades as it blends into your life, but a
/// lot of it, next to a small honest income, draws an investigation.
void dirtyMoneyYear(Life l, Random rng) {
  if (l.dirty <= 0) return;
  l.dirty = min(l.dirty, max(0, l.netWorth));
  if (l.dirty <= 0) return;
  final honest =
      l.salary + l.businesses.fold(0, (s, b) => s + max(0, b.profit));
  final suspicion =
      (l.dirty / (l.dirty + honest * 2 + 40000) * 35).round() -
      (informant(l) ? 15 : 0) +
      (l.worldMods['policing'] ?? 0) ~/ 2;
  if (l.prison == null &&
      !l.sceneQueue.any((s) => s.startsWith('unexplained')) &&
      _roll(rng, suspicion)) {
    l.sceneQueue.add('unexplained_wealth');
  }
  l.dirty = (l.dirty * 0.9).round();
}

/// Laundering: turn dirty money into money you can explain, for a cut.
ActionResult launder(
  Life l,
  Random rng, {
  required int amount,
  required double cut,
  required String text,
  int risk = 0,
}) {
  final take = min(amount, l.dirty);
  final fee = (take * cut).round();
  l.money -= fee;
  l.dirty -= take;
  if (risk > 0 && _roll(rng, risk)) {
    l.cases.add({
      'crime': 'money_laundering',
      'age': l.age,
      'evidence': 45 + rng.nextInt(20),
    });
    l.notoriety += 2;
    return ActionResult(
      '$text But someone noticed: a bank filed a suspicious-activity report.',
      ['Cleaned ${_m(take)}', 'Cost ${_m(fee)}', 'An investigation has opened'],
    );
  }
  return ActionResult(text, ['Cleaned ${_m(take)}', 'Cost ${_m(fee)}']);
}

String? _needsDirty(Life l) =>
    l.dirty < 1000 ? 'No dirty money to clean' : null;

final launderVariants = <ActionVariant>[
  ActionVariant(
    id: 'business',
    label: 'Through your business',
    detail: '10% cost · mixes it into the takings',
    check: (l) => l.businesses.isEmpty ? 'Needs a business' : null,
    run: (l, rng, who, score) {
      final room = l.businesses.fold(0, (s, b) => s + b.revenue ~/ 2) + 20000;
      return launder(
        l,
        rng,
        amount: room,
        cut: 0.10,
        risk: 8,
        text:
            'A few extra customers who never existed. ${l.businesses.first.name} had a very good year on paper.',
      );
    },
  ),
  ActionVariant(
    id: 'deposits',
    label: 'Small cash deposits',
    detail: '3% cost · slow, a little at a time',
    run: (l, rng, who, score) => launder(
      l,
      rng,
      amount: 15000,
      cut: 0.03,
      risk: 12,
      text: 'Dozens of deposits just under the reporting limit, at a dozen different branches.',
    ),
  ),
  ActionVariant(
    id: 'casino',
    label: 'Casino chips',
    detail: '15% cost · buy chips, play a little, cash out',
    minAge: 18,
    run: (l, rng, who, score) => launder(
      l,
      rng,
      amount: 60000,
      cut: 0.15,
      risk: 6,
      text: 'You bought chips with cash, lost a little at roulette and cashed out with a receipt.',
    ),
  ),
  ActionVariant(
    id: 'property',
    label: 'Buy and sell property',
    detail: '8% cost · cleans a lot at once',
    check: (l) => l.dirty < 50000 ? 'Needs \$50,000 of dirty money' : null,
    run: (l, rng, who, score) {
      final amount = l.dirty;
      final r = launder(
        l,
        rng,
        amount: amount,
        cut: 0.08,
        risk: 10,
        text: 'A flat bought in cash through a company abroad, then sold a year later. The sale money is clean.',
      );
      return r;
    },
  ),
  ActionVariant(
    id: 'crypto',
    label: 'Crypto',
    detail: '12% cost · fast, prices swing',
    check: (l) => l.year < 2013 ? 'Not until 2013' : null,
    run: (l, rng, who, score) {
      // A market frenzy in the news lifts crypto, for now.
      final swing = rng.nextInt(41) - 20 + (l.worldMods['markets'] ?? 0) ~/ 2;
      final take = min(80000, l.dirty);
      final r = launder(
        l,
        rng,
        amount: take,
        cut: 0.12,
        risk: 7,
        text: 'Coins through a mixer and three exchanges.',
      );
      final change = take * swing ~/ 100;
      l.money += change;
      return ActionResult(
        '${r.text} The price ${swing >= 0 ? 'rose' : 'fell'} while it moved.',
        [...r.notes, '${change >= 0 ? 'Gain' : 'Loss'} ${_m(change.abs())}'],
      );
    },
  ),
  ActionVariant(
    id: 'crew',
    label: 'Through the crew\'s fronts',
    detail: '6% cost · laundromats and car washes',
    check: (l) => inCrew(l) ? null : 'Needs a crew',
    run: (l, rng, who, score) => launder(
      l,
      rng,
      amount: 100000,
      cut: 0.06,
      risk: 4,
      text:
          'The crew runs it through a laundromat that has never washed a sock.',
    ),
  ),
];

// ---------------- Crew jobs ----------------

ActionResult _crewJob(
  Life l,
  Random rng,
  String crimeId, {
  int riskAdj = 0,
  double gainMul = 1,
  required String text,
  int respect = 6,
}) {
  final cut = crewCut(l);
  final before = l.money;
  final r = commitCrime(
    l,
    crimeById(crimeId),
    rng,
    riskAdj: riskAdj - 8, // the crew plans it well
    gainMul: gainMul * (1 - cut),
    text: text,
  );
  final earned = l.money - before;
  if (earned > 0) {
    _adjust(l, 'respect', respect);
    _adjust(l, 'loyalty', 2);
  } else if (l.sceneQueue.any((s) => s.startsWith('arrest:'))) {
    _adjust(l, 'respect', -4);
  }
  return ActionResult(r.text, [
    ...r.notes,
    if (cut > 0 && earned > 0) 'The crew took ${(cut * 100).round()}%',
    if (earned > 0) 'Respect up',
  ]);
}

final crewJobVariants = <ActionVariant>[
  ActionVariant(
    id: 'collect',
    label: 'Collect protection money',
    detail: 'Steady money, shop owners remember',
    run: (l, rng, who, score) => _crewJob(
      l,
      rng,
      'extortion',
      gainMul: 0.6,
      text: 'You walked down the high street with a notebook. Every shop paid. Your share: {gain}.',
    ),
  ),
  ActionVariant(
    id: 'shipment',
    label: 'Move a shipment',
    detail: 'Big money, bigger risk',
    run: (l, rng, who, score) => _crewJob(
      l,
      rng,
      'smuggling',
      riskAdj: 5,
      text: 'A van, a warehouse and no questions. The crates arrived; your share was {gain}.',
      respect: 8,
    ),
  ),
  ActionVariant(
    id: 'cards',
    label: 'Run a card game',
    detail: 'Low risk, charm helps',
    run: (l, rng, who, score) => _crewJob(
      l,
      rng,
      'fraud',
      riskAdj: -10,
      gainMul: 0.4,
      text: 'A back room, a marked deck and a very rich dentist. The house won {gain}.',
      respect: 4,
    ),
  ),
  ActionVariant(
    id: 'score',
    label: 'Settle a score for the boss',
    detail: 'Violent: big respect, big risk',
    run: (l, rng, who, score) {
      _adjust(l, 'rivalry', 8);
      return _crewJob(
        l,
        rng,
        'assault',
        riskAdj: 5,
        text: 'You delivered the boss\'s message in person. The rival crew will not forget it.',
        respect: 12,
      );
    },
  ),
  ActionVariant(
    id: 'big',
    label: 'Plan a big job',
    detail: 'Lieutenants and up: an armoured van',
    check: (l) => crewRank(l) < 2 ? 'Lieutenant and above' : null,
    run: (l, rng, who, score) => _crewJob(
      l,
      rng,
      'armed_robbery',
      gainMul: 2.5,
      text: 'Eight people, three cars and a plan you rehearsed for a month. Your share: {gain}.',
      respect: 15,
    ),
  ),
];

// ---------------- Yearly ----------------

/// Each birthday in a crew: rackets pay up the chain, the crew protects
/// you, promotion, and one of the crew's problems lands on you.
List<String> crewYear(Life l, Random rng) {
  final feed = <String>[];
  dirtyMoneyYear(l, rng);
  final crew = crewOf(l);
  if (crew == null &&
      l.prison == null &&
      l.businesses.isNotEmpty &&
      !l.sceneQueue.contains('biz_racket') &&
      _roll(rng, max(1, 6 - (l.worldMods['gangs'] ?? 0) ~/ 5))) {
    l.sceneQueue.add('biz_racket');
  }
  if (crew == null || l.prison != null) return feed;
  final rank = crewRank(l);
  // Rackets: lieutenants and up earn from the crew's business.
  if (rank >= 2) {
    // Rackets follow the economy, and a police crackdown squeezes them.
    final econ = switch (l.economy) {
      'Boom' => 1.25,
      'Recession' || 'Crash' => 0.7,
      _ => 1.0,
    };
    final squeeze = 1 - (l.worldMods['gangs'] ?? 0) / 40;
    final take =
        (([0, 0, 20000, 60000, 200000][rank] + rng.nextInt(10000)) *
                econ *
                squeeze)
            .round();
    l.money += take;
    l.dirty += take;
    feed.add(
      'Your share of the ${crew.trade} rackets came in: ${_m(take)} in cash nobody can explain.',
    );
  }
  // The crew looks after its own: witnesses forget, evidence goes missing.
  if (crewLoyalty(l) >= 50 || informant(l)) {
    for (final c in l.cases) {
      c['evidence'] = max(0, (c['evidence'] as int) - (informant(l) ? 15 : 6));
    }
  }
  // Promotion.
  if (rank < 3 && crewRespect(l) >= 60) {
    l.crew['rank'] = rank + 1;
    l.crew['respect'] = 20;
    feed.add(
      'The boss poured two glasses and raised one to you. You are a ${crewRanks[rank + 1]} of ${crew.name} now.',
    );
    l.flags['crew_${crewRanks[rank + 1].toLowerCase()}'] = Memory(
      l.age,
      'becoming a ${crewRanks[rank + 1]}',
    );
    return feed;
  }
  _adjust(l, 'respect', -3);
  // An informant can be found out.
  if (informant(l) && _roll(rng, 12)) {
    l.sceneQueue.add('crew_found_out');
    return feed;
  }
  final roll = rng.nextInt(100);
  if (rank == 3 && crewRespect(l) >= 70 && roll < 40) {
    l.sceneQueue.add('crew_coup');
  } else if (roll < 18) {
    l.sceneQueue.add('crew_test');
  } else if (roll < 18 + 10 + rivalry(l) ~/ 4) {
    l.sceneQueue.add('crew_rival');
  } else if (roll < 50 + (l.worldMods['gangs'] ?? 0) &&
      heat(l) >= 35 - (l.worldMods['gangs'] ?? 0) &&
      !informant(l)) {
    l.sceneQueue.add('crew_cops');
  }
  return feed;
}

/// Outside a crew, a reputation on the street brings an invitation.
void crewInviteYear(Life l, Random rng) {
  if (inCrew(l) ||
      l.prison != null ||
      l.age < 18 ||
      l.crew['left'] != null ||
      streetRep(l) + (l.worldMods['infamy'] ?? 0) < 30) {
    return;
  }
  // An infamous family name opens doors in the underworld.
  if (_roll(rng, 15 + (l.worldMods['infamy'] ?? 0))) {
    l.sceneQueue.add('crew_invite');
  }
}

// ---------------- Scenes ----------------

Choice _join(Crew c) => Choice(
  label: c.name,
  outcome: '',
  risk: c.blurb,
  run: (l, rng) {
    final odds = 30 + streetRep(l) ~/ 2 + (l.stats[c.stat] - 50) ~/ 4;
    if (!_roll(rng, odds)) {
      return 'They listened, said nothing and never called back. You are not ready for ${c.name}.';
    }
    l.crew
      ..clear()
      ..addAll({
        'id': c.id,
        'rank': 0,
        'respect': 10,
        'loyalty': 50,
        'since': l.age,
      });
    l.sceneQueue.insert(0, 'crew_initiation');
    return 'A man in a good coat nodded once. "Prove it," he said.';
  },
);

Storylet? underworldScene(String id, List<String> args, Life l) {
  final crew = crewOf(l);
  switch (id) {
    case 'crew_pick':
      if (inCrew(l)) return null;
      return _scene(
        id,
        'You know people who know people. Three crews run this city. Which door do you knock on?',
        [
          for (final c in crewList) _join(c),
          Choice(
            label: 'Walk away',
            outcome: 'You kept your hands clean, for now.',
          ),
        ],
      );
    case 'crew_invite':
      if (inCrew(l)) return null;
      final c = crewList[Random(l.seed + l.age).nextInt(crewList.length)];
      return _scene(
        id,
        'Word of your work got around. A car pulled up beside you: ${c.name} would like a word. ${c.blurb}',
        [
          _join(c),
          Choice(
            label: 'Say no, politely',
            outcome:
                'You said you were flattered. They said they would remember.',
          ),
        ],
      );
    case 'crew_initiation':
      if (crew == null || crewRank(l) > 0) return null;
      return _scene(
        id,
        '${crew.name} wants to know what you are made of. Your test:',
        [
          Choice(
            label: 'Carry a package across town',
            outcome: '',
            risk: 'Don\'t ask what is inside',
            run: (l, rng) {
              if (_roll(rng, 15)) {
                l.sceneQueue.insert(0, 'arrest:smuggling:50');
                return 'A routine traffic stop. The officer asked you to open the boot.';
              }
              _adjust(l, 'respect', 10);
              return 'You delivered it and did not look inside. You are in.';
            },
          ),
          Choice(
            label: 'Collect a debt',
            outcome: '',
            risk: 'They may not want to pay',
            run: (l, rng) {
              l.stats.add('karma', -4);
              _adjust(l, 'respect', 15);
              return 'He paid after you broke his window. You are in, and you will think about his face for a while.';
            },
          ),
          Choice(
            label: 'Pay tribute (\$5,000)',
            outcome: '',
            needsMoney: 5000,
            run: (l, rng) {
              l.money -= 5000;
              _adjust(l, 'respect', 5);
              return 'Money talks. You are in, though nobody respects you much yet.';
            },
          ),
          Choice(
            label: 'Back out',
            outcome: '',
            run: (l, rng) {
              _leaveCrew(l);
              return 'You walked away before it began. They let you, this once.';
            },
          ),
        ],
      );
    case 'crew_test':
      if (crew == null) return null;
      return _scene(
        id,
        'The boss calls you in. A shop owner has been talking to the police. "Make sure his shop has a bad night," he says, watching you.',
        [
          Choice(
            label: 'Do it',
            outcome: '',
            risk: 'Loyalty up, karma down',
            run: (l, rng) {
              l.stats.add('karma', -8);
              _adjust(l, 'loyalty', 15);
              _adjust(l, 'respect', 10);
              return commitCrime(
                l,
                crimeById('vandalism'),
                rng,
                text: 'Smashed windows and a message on the door. The shop closed a month later.',
              ).text;
            },
          ),
          Choice(
            label: 'Warn the shop owner instead',
            outcome: '',
            risk: 'If the crew finds out...',
            run: (l, rng) {
              l.stats.add('karma', 6);
              if (_roll(rng, 35)) {
                _adjust(l, 'loyalty', -30);
                l.stats.add('health', -10);
                return 'The crew found out. You spent a week in hospital and a month apologising.';
              }
              _adjust(l, 'loyalty', -5);
              return 'The shop owner left town in the night. The boss shrugged: "Lucky man."';
            },
          ),
          Choice(
            label: 'Refuse',
            outcome: '',
            run: (l, rng) {
              _adjust(l, 'loyalty', -15);
              _adjust(l, 'respect', -10);
              return 'The boss said nothing for a long time. "Noted," he said.';
            },
          ),
        ],
      );
    case 'crew_rival':
      if (crew == null) return null;
      return _scene(
        id,
        'A rival crew hit one of ${crew.name}\'s spots last night. Everyone is looking at you.',
        [
          Choice(
            label: 'Hit back',
            outcome: '',
            risk: 'Respect up, the feud grows',
            run: (l, rng) {
              _adjust(l, 'rivalry', 15);
              _adjust(l, 'respect', 10);
              if (_roll(rng, 20)) {
                l.stats.add('health', -15);
                return 'It turned into a brawl in a car park. You won, barely, and have the stitches to prove it.';
              }
              return 'You answered the same night. The rivals got the message.';
            },
          ),
          Choice(
            label: 'Arrange a sit-down',
            outcome: '',
            risk: 'Charisma helps',
            run: (l, rng) {
              if (_roll(rng, 30 + l.stats['charisma'] ~/ 2)) {
                _adjust(l, 'rivalry', -20);
                _adjust(l, 'respect', 8);
                return 'A quiet restaurant, two bosses and you in the middle. Peace, for now, and they credit you.';
              }
              _adjust(l, 'rivalry', 5);
              return 'The sit-down ended with a table flipped over. At least nobody was hurt.';
            },
          ),
          Choice(
            label: 'Lie low',
            outcome: '',
            run: (l, rng) {
              _adjust(l, 'respect', -6);
              return 'You stayed home. Some people called it smart. Others called it something else.';
            },
          ),
        ],
      );
    case 'crew_cops':
      if (crew == null) return null;
      return _scene(
        id,
        'Two detectives sit down at your café table. "We know who you work for. Help us, and your problems go away."',
        [
          Choice(
            label: 'Become an informant',
            outcome: '',
            risk: 'Your cases cool off. If the crew finds out...',
            run: (l, rng) {
              l.crew['informant'] = true;
              l.notoriety = max(0, l.notoriety - 5);
              l.stats.add('karma', 2);
              return 'You gave them a name and a date. Every week since, you check your mirrors twice.';
            },
          ),
          Choice(
            label: 'Say nothing and leave',
            outcome: '',
            run: (l, rng) {
              _adjust(l, 'loyalty', 5);
              return '"Suit yourself," said the older one. "We will be watching."';
            },
          ),
          Choice(
            label: 'Tell the crew they asked',
            outcome: '',
            run: (l, rng) {
              _adjust(l, 'loyalty', 12);
              _adjust(l, 'respect', 6);
              l.notoriety += 2;
              return 'The boss appreciated it. The detectives did not.';
            },
          ),
        ],
      );
    case 'crew_found_out':
      if (crew == null) return null;
      return _scene(
        id,
        'A photo of you with a detective is pinned to your front door with a knife. ${crew.name} knows.',
        [
          Choice(
            label: 'Run: witness protection',
            outcome: '',
            risk: 'A new life far away',
            run: (l, rng) {
              _leaveCrew(l);
              l.cases.clear();
              l.flags['witness_protection'] = Memory(
                l.age,
                'entering witness protection',
              );
              l.stats.add('happiness', -10);
              return 'You testified in a closed court. Then a car, a new city and a name you are still learning to answer to.';
            },
          ),
          Choice(
            label: 'Beg the boss for mercy',
            outcome: '',
            risk: 'Depends how loyal you have been',
            run: (l, rng) {
              if (_roll(rng, crewLoyalty(l) ~/ 2)) {
                l.crew['informant'] = false;
                l.crew['rank'] = 0;
                _adjust(l, 'loyalty', -20);
                return 'The boss let you live, and made sure you will never rise again.';
              }
              l.stats.add('health', -35);
              _leaveCrew(l);
              return 'They found you in the car park. You woke up in hospital weeks later. Nobody from the crew ever spoke to you again.';
            },
          ),
          Choice(
            label: 'Flee the country',
            outcome: '',
            needsMoney: 10000,
            run: (l, rng) {
              l.money -= 10000;
              _leaveCrew(l);
              l.sceneQueue.insert(0, 'emigrate');
              return 'You packed one bag and bought a one-way ticket.';
            },
          ),
        ],
      );
    case 'crew_coup':
      if (crew == null || crewRank(l) != 3) return null;
      return _scene(
        id,
        'The boss is getting old and careless. The soldiers look to you. Do you make your move?',
        [
          Choice(
            label: 'Take over',
            outcome: '',
            risk: 'Win it all, or lose everything',
            run: (l, rng) {
              if (_roll(rng, 30 + crewRespect(l) ~/ 2 + crewLoyalty(l) ~/ 4)) {
                l.crew['rank'] = 4;
                l.flags['crew_boss'] = Memory(
                  l.age,
                  'taking over ${crew.name}',
                );
                l.notoriety += 5;
                return 'By morning, everyone in ${crew.name} answered to you. The old boss retired to the coast, quietly.';
              }
              l.stats.add('health', -25);
              l.crew['rank'] = 1;
              _adjust(l, 'loyalty', -40);
              return 'Someone talked. You lost the fight and two ranks, and you are lucky to have lost nothing else.';
            },
          ),
          Choice(
            label: 'Stay loyal',
            outcome: '',
            run: (l, rng) {
              _adjust(l, 'loyalty', 15);
              return 'You told the boss there were whispers. He will not forget it.';
            },
          ),
        ],
      );
    case 'crew_leave':
      if (crew == null) return null;
      final price = const [5000, 20000, 60000, 150000, 0][crewRank(l)];
      return _scene(
        id,
        'Nobody just leaves ${crew.name}. You can buy your way out, disappear, or go to the police.',
        [
          if (crewRank(l) < 4)
            Choice(
              label: 'Pay your way out (${_m(price)})',
              outcome: '',
              needsMoney: price,
              run: (l, rng) {
                l.money -= price;
                _leaveCrew(l);
                return 'The boss counted it twice, then shook your hand. "Never come back."';
              },
            ),
          if (crewRank(l) == 4)
            Choice(
              label: 'Hand the crew to your second and retire',
              outcome: '',
              run: (l, rng) {
                _leaveCrew(l);
                l.stats.add('happiness', 6);
                return 'You passed the crew on with a dinner and a speech. Now you grow tomatoes and jump at loud noises.';
              },
            ),
          Choice(
            label: 'Disappear',
            outcome: '',
            risk: 'They may come looking',
            run: (l, rng) {
              _leaveCrew(l);
              if (_roll(rng, 30)) {
                l.stats.add('health', -20);
                return 'They found you anyway. The message was delivered in a car park, and it hurt.';
              }
              return 'A new city, a new phone number. Nobody came. Yet.';
            },
          ),
          Choice(
            label: 'Testify against them',
            outcome: '',
            risk: 'Your cases go away; a new life far away',
            run: (l, rng) {
              _leaveCrew(l);
              l.cases.clear();
              l.flags['witness_protection'] = Memory(l.age, 'testifying');
              l.stats.add('happiness', -8);
              return 'You gave evidence for three days. ${crew.name} fell apart, and you began again under another name.';
            },
          ),
          Choice(
            label: 'Stay',
            outcome: 'You decided you are in this for life.',
          ),
        ],
      );
    case 'biz_racket':
      if (l.businesses.isEmpty || inCrew(l)) return null;
      final b = l.businesses.first;
      final c = crewList[Random(l.seed + l.age).nextInt(crewList.length)];
      final fee = max(2000, l.valueOfBusiness(b) ~/ 20);
      return _scene(
        id,
        'Two men from ${c.name} walk into ${b.name} and admire the windows. "Nice place. Be a shame if something happened to it. ${_m(fee)} a year keeps it safe."',
        [
          Choice(
            label: 'Pay them (${_m(fee)})',
            outcome: '',
            needsMoney: fee,
            run: (l, rng) {
              l.money -= fee;
              return 'You paid. They come by every year now, polite and terrifying.';
            },
          ),
          Choice(
            label: 'Refuse',
            outcome: '',
            risk: 'They may make an example of you',
            run: (l, rng) {
              if (_roll(rng, 50)) {
                b.quality = max(5, b.quality - 15);
                b.satisfaction = max(0, b.satisfaction - 10);
                l.money -= fee;
                return 'A brick through the window, then a small fire in the bins. The repairs cost ${_m(fee)} and customers stayed away.';
              }
              return 'They shrugged and left. You check the windows every night now.';
            },
          ),
          Choice(
            label: 'Go to the police',
            outcome: '',
            run: (l, rng) {
              l.stats.add('karma', 2);
              if (_roll(rng, 30)) {
                l.stats.add('health', -15);
                return 'The police made arrests. A week later someone was waiting for you in the car park.';
              }
              return 'Detectives took your statement and the crew stayed away. For now.';
            },
          ),
        ],
      );
    case 'unexplained_wealth':
      if (l.dirty <= 0) return null;
      final fee = 10000 + l.dirty ~/ 20;
      return _scene(
        id,
        'A letter from the financial crimes unit: they would like you to explain where ${_m(l.dirty)} came from.',
        [
          Choice(
            label: 'Hire a lawyer to explain it (${_m(fee)})',
            outcome: '',
            needsMoney: fee,
            run: (l, rng) {
              l.money -= fee;
              if (_roll(rng, 70)) {
                l.dirty = 0;
                return 'Your lawyer produced a paper trail so convincing you almost believed it. Case closed.';
              }
              l.cases.add({
                'crime': 'money_laundering',
                'age': l.age,
                'evidence': 50,
              });
              return 'The paperwork did not hold up. The case is still open.';
            },
          ),
          Choice(
            label: 'Let them seize half',
            outcome: '',
            run: (l, rng) {
              final seized = l.dirty ~/ 2;
              l.money -= seized;
              l.dirty = 0;
              return 'You signed it over without admitting anything: ${_m(seized)} gone. No charges.';
            },
          ),
          Choice(
            label: 'Say nothing',
            outcome: '',
            risk: 'They may charge you',
            run: (l, rng) {
              if (_roll(rng, 50)) {
                l.sceneQueue.insert(0, 'arrest:money_laundering:60');
                return 'Silence was not an answer they accepted.';
              }
              return 'They could not prove anything, this time.';
            },
          ),
        ],
      );
  }
  return null;
}

// ---------------- Activities ----------------

final underworldActions = <GameAction>[
  GameAction(
    id: 'join_crew',
    label: 'Find a crew',
    category: 'Crime',
    keywords: ['crew', 'gang', 'mafia', 'mob', 'organised crime', 'join'],
    minAge: 18,
    priceNote: 'Needs a reputation on the street',
    extraCheck: (l) => inCrew(l)
        ? 'You are in ${crewOf(l)!.name}'
        : streetRep(l) < 20
        ? 'Nobody knows you yet · commit a few crimes first'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('crew_pick');
      return ActionResult('You ask around in the right bars.');
    },
  ),
  GameAction(
    id: 'crew_job',
    label: 'Take a job from the crew',
    category: 'Crime',
    keywords: ['crew job', 'mob job', 'racket', 'protection', 'shipment'],
    minAge: 18,
    extraCheck: (l) => inCrew(l) ? null : 'Needs a crew',
    hint: (l) => inCrew(l)
        ? '${crewRanks[crewRank(l)]} · the crew takes ${(crewCut(l) * 100).round()}%'
        : null,
    run: (l, rng) => _crewJob(
      l,
      rng,
      crewOf(l)!.crime,
      text: 'You did what the crew asked. Your share: {gain}.',
    ),
  ),
  GameAction(
    id: 'leave_crew',
    label: 'Leave your crew',
    category: 'Crime',
    keywords: ['leave crew', 'quit gang', 'get out', 'witness'],
    minAge: 18,
    extraCheck: (l) => inCrew(l) ? null : 'Not in a crew',
    run: (l, rng) {
      l.sceneQueue.add('crew_leave');
      return ActionResult('You think about how to get out.');
    },
  ),
  GameAction(
    id: 'launder',
    label: 'Launder dirty money',
    category: 'Crime',
    keywords: ['launder', 'dirty money', 'clean money', 'wash'],
    minAge: 16,
    extraCheck: _needsDirty,
    hint: (l) => '${_m(l.dirty)} unexplained',
    run: (l, rng) => launderVariants[1].run(l, rng, null, null),
  ),
];
