import 'dart:math';

import 'actions.dart';
import 'careers.dart' show studying;
import 'currency.dart' show currencyLabel;
import 'health.dart' show exposeTo;
import 'jobs.dart' show leaveJob;
import 'justice.dart' show caughtInTheAct, convictions, hasSeriousRecord;
import 'minigame_rules.dart';
import 'models.dart';
import 'possessions.dart' show hostingCapacity;
import 'school.dart' show inSchool;
import 'storylet.dart';
import 'world.dart';
import 'world_data.dart';

/// Everyday life around you (plan Social §7 and Core Module 10): what your
/// family name means to strangers, history class and the library, shopping,
/// road trips, the black market, parties with a guest list, a quiet moment
/// of reflection, and moving abroad.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

// ---------------- The world reacts to your name ----------------

/// Strangers react to a family name with a reputation (plan Module 11).
String? nameReaction(Life l, World w, Random rng) {
  final rep = w.names[l.surname];
  if (rep == null || l.age < 8 || rng.nextInt(100) >= 12) return null;
  final top = rep.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (top.first.value < 20) return null;
  final s = l.surname;
  l.reason = 'The $s name';
  switch (top.first.key) {
    case 'fame':
      l.stats.add('happiness', 1);
      return 'A barista reads your name off the cup and looks up: "Any relation to the famous ${s}s?"';
    case 'infamy':
      l.stats.add('happiness', -2);
      return 'A landlord pauses at your surname. "Not one of THOSE ${s}s, I hope." Your family\'s past follows you around.';
    case 'wealth':
      l.stats.add('happiness', 1);
      return 'Waiters become very attentive once they hear the name $s.';
    case 'philanthropy':
      l.stats.add('happiness', 2);
      return 'An old man shakes your hand in the street. The $s fund paid for his granddaughter\'s schooling.';
    default:
      return 'A clerk spots the name $s on your form and suddenly finds a way to speed things up.';
  }
}

/// History class teaches what earlier lives did in this world.
String? historyClass(Life l, World w, Random rng) {
  if (!inSchool(l) || l.age < 11 || rng.nextInt(100) >= 30) return null;
  final past = w.ledger.where((s) => s.year < l.year - 5).toList();
  if (past.isEmpty) return null;
  final s = past[rng.nextInt(past.length)];
  l.reason = 'History class';
  l.stats.add('smarts', 1);
  return 'In history class you learned about ${s.year}: "${s.headline}". ${s.person == null ? '' : 'The teacher said ${s.person} changed ${l.city}.'}';
}

// ---------------- Scenes ----------------

Storylet _scene(
  String id,
  String text,
  List<Choice> choices, {
  String category = 'life',
}) => Storylet(
  id: 'scene:$id',
  text: text,
  category: category,
  scene: true,
  choices: choices,
);

/// Emigration odds and the reasons behind them (plan: approval factors).
(int, List<String>) visaOdds(Life l, String to) {
  final why = <String>[];
  var p = 45;
  void add(int d, String r) {
    p += d;
    why.add('$r ${d >= 0 ? '+' : '−'}${d.abs()}');
  }

  if (l.money + l.savings >= 10000) add(10, 'Savings');
  if (l.salary > 0) add(10, 'A job');
  if (l.education == 'graduate' || l.school.degrees.isNotEmpty) {
    add(10, 'A degree');
  }
  final mine = countryProfile(l.country).languages;
  if (countryProfile(to).languages.any(mine.contains)) {
    add(15, 'Shared language');
  }
  if (hasSeriousRecord(l)) {
    add(-40, 'Serious criminal record');
  } else if (convictions(l) > 0) {
    add(-20, 'Criminal record');
  }
  if (l.cases.isNotEmpty) add(-10, 'Police interest');
  if (l.flags.containsKey('second_passport')) add(35, 'A second passport');
  return (p.clamp(5, 95), why);
}

/// The cost of applying for a visa and moving.
const emigrateCost = 3000;

/// Plain words for how a visa application looks.
String visaOutlook(int odds) => odds >= 60
    ? 'A visa looks likely'
    : odds < 30
    ? 'A visa will be hard to get'
    : 'A visa is possible';

/// Applies for a visa to [to] and, if it is granted, moves there.
String emigrateTo(Life l, String to, Random rng) {
  final c = countryNamed(to);
  final (odds, why) = visaOdds(l, to);
  l.money -= emigrateCost;
  if (rng.nextInt(100) >= odds) {
    return 'The visa was refused. Main factors: ${why.take(3).join(', ')}. You can try again another year.';
  }
  final from = l.country;
  final hadJob = l.job;
  if (l.job != null) leaveJob(l);
  l.assets.removeWhere((a) => a.kind == 'rental');
  l.country = c.name;
  l.city = c.cities[rng.nextInt(c.cities.length)];
  l.marks.add('lived:${c.name}');
  l.flags['emigrated'] = Memory(l.age, 'moving from $from to ${c.name}');
  for (final n in l.npcs.where(
    (n) => n.circle == 'Family' || n.circle == 'Friends',
  )) {
    n.addFacets(affection: -3);
  }
  l.stats.add('happiness', 5);
  return 'You landed in ${l.city} with two suitcases and a head full of plans. ${hadJob == null ? '' : 'You left your job as $hadJob behind. '}Healthcare, laws and prices work differently here: check your country card on the Me tab. Money is now counted in the ${currencyLabel(c.name)}.';
}

Storylet? communityScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'emigrate':
      final options = countries.where((c) => c.name != l.country).toList();
      return _scene(
        id,
        'You have been looking at flights and visa forms for weeks. A fresh start somewhere new costs \$3,000 in fees and moving costs. Where to?',
        category: 'travel',
        [
          for (final c in options)
            () {
              final (odds, why) = visaOdds(l, c.name);
              final prof = countryProfile(c.name);
              return Choice(
                label: c.name,
                outcome: '',
                risk:
                    '${prof.blurb} Pay ${prof.payLabel.toLowerCase()}, prices ${prof.costLabel.toLowerCase()}.${odds >= 60
                        ? ' A visa looks likely.'
                        : odds < 30
                        ? ' A visa will be hard to get.'
                        : ''}${prof.climate == 'hostile' ? ' Warning: LGBTQ+ people face legal risk here.' : ''}',
                needsMoney: 3000,
                run: (l, rng) => emigrateTo(l, c.name, rng),
              );
            }(),
          Choice(
            label: 'Stay where you are',
            outcome: 'Home is home, for now.',
          ),
        ],
      );
    case 'shop':
      final gift = l.who('@partner') ?? l.who('@friend') ?? l.who('@parent');
      return _scene(
        id,
        'A Saturday in ${l.city}\'s shops, card in hand. What are you after?',
        category: 'money',
        [
          Choice(
            label: 'New clothes (\$150)',
            outcome: '',
            needsMoney: 150,
            run: (l, rng) {
              l.money -= 150;
              l.stats.add('looks', 1);
              l.stats.add('happiness', 2);
              return 'A jacket that makes you stand a little taller. Worth it.';
            },
          ),
          if (gift != null)
            Choice(
              label: 'A gift for ${gift.name.split(' ').first} (\$80)',
              outcome: '',
              needsMoney: 80,
              run: (l, rng) {
                l.money -= 80;
                gift.addFacets(affection: 6);
                gift.lastContactAge = l.age;
                return '${gift.name.split(' ').first} opened it, went quiet, then hugged you. "You remembered."';
              },
            ),
          Choice(
            label: 'The latest phone (\$900)',
            outcome: '',
            needsMoney: 900,
            run: (l, rng) {
              l.money -= 900;
              l.stats.add('happiness', 3);
              return 'Your new phone takes better photos than you do.';
            },
          ),
          Choice(
            label: 'A piece of jewellery (\$2,500)',
            outcome: '',
            risk: 'Resale value drops about 45%',
            needsMoney: 2500,
            run: (l, rng) {
              l.money -= 2500;
              l.assets.add(
                Asset(
                  id: 'jewel${l.age}',
                  kind: 'valuable',
                  name: 'Jewellery',
                  value: 1375,
                  yearlyCost: 0,
                  since: l.age,
                  info: {'dep': 2},
                ),
              );
              l.stats.add('happiness', 4);
              return 'It sparkles. The receipt does not.';
            },
          ),
          Choice(
            label: 'Window shopping only',
            outcome: 'You looked at everything and bought a coffee.',
          ),
        ],
      );
    case 'party':
      final friends = l.npcs
          .where((n) => n.alive && n.circle == 'Friends')
          .toList();
      final family = l.npcs
          .where(
            (n) => n.alive && (n.circle == 'Family' || n.circle == 'Partner'),
          )
          .toList();
      String throwParty(Life l, Random rng, List<Npc> guests, int budget) {
        l.money -= budget;
        final notInvited = [
          ...friends,
          ...family,
        ].where((n) => !guests.contains(n)).toList();
        final events = <String>[];
        final room = hostingCapacity(l);
        if (guests.length > room) {
          l.stats.add('happiness', -1);
          events.add(
            'With ${guests.length} people in a home built for $room, the queue for the bathroom became its own party.',
          );
        }
        final ex = l.npcs.where((n) => n.circle == 'Exes' && n.alive);
        if (ex.isNotEmpty &&
            l.who('@partner') != null &&
            rng.nextInt(100) < 35) {
          final e = ex.first;
          e.addFacets(affection: -4);
          events.add(
            '${e.name.split(' ').first} turned up uninvited and made the kitchen very awkward for ${l.who('@partner')!.name.split(' ').first}.',
          );
        }
        if (guests.length >= 2 && rng.nextInt(100) < 40) {
          final a = guests[rng.nextInt(guests.length)];
          final b = guests.firstWhere((g) => g != a, orElse: () => a);
          if (a != b) {
            for (final g in [a, b]) {
              g.remember(
                NpcMemory(
                  age: l.age,
                  text: 'meeting a new friend at your party',
                  valence: 1,
                  intensity: 2,
                  tags: ['party'],
                ),
              );
            }
            events.add(
              '${a.name.split(' ').first} and ${b.name.split(' ').first} talked all night and swapped numbers.',
            );
          }
        }
        if (budget >= 600 && rng.nextInt(100) < 25) {
          events.add(
            'The neighbours called the police about the noise at 1 a.m.',
          );
          l.stats.add('karma', -1);
        }
        if (notInvited.isNotEmpty && rng.nextInt(100) < 35) {
          final n = notInvited[rng.nextInt(notInvited.length)];
          n.addFacets(affection: -6, resentment: 3);
          n.remember(
            NpcMemory(
              age: l.age,
              text: 'not being invited to your party',
              valence: -1,
              intensity: 2,
              tags: ['party'],
            ),
          );
          events.add(
            '${n.name.split(' ').first} saw the photos and was hurt not to be invited.',
          );
        }
        for (final g in guests) {
          g.addFacets(affection: 3 + budget ~/ 300);
          g.lastContactAge = l.age;
        }
        final great =
            rng.nextInt(100) < 40 + l.stats['charisma'] ~/ 3 + budget ~/ 100;
        l.stats.add('happiness', great ? 7 : 2);
        if (great) {
          l.flags['party_of_the_year'] = Memory(l.age, 'the party of the year');
        }
        exposeTo(l, 'alcohol', rng);
        return '${great ? 'The party of the year.' : 'A nice evening, if not legendary.'} ${guests.length} came. ${events.join(' ')}';
      }

      Choice option(String label, List<Npc> guests, int budget) => Choice(
        label: '$label (${guests.length} guests, ${_m(budget)})',
        outcome: '',
        needsMoney: budget,
        lock: (l) => guests.isEmpty ? 'Nobody to invite yet' : null,
        run: (l, rng) => throwParty(l, rng, guests, budget),
      );
      return _scene(
        id,
        'You are throwing a party. Who makes the guest list? Anyone left off might find out.',
        category: 'social',
        [
          option(
            'Close friends, small and cosy',
            friends.where((n) => n.bond >= 50).toList(),
            150,
          ),
          option('Family and friends', [...family, ...friends], 400),
          option('Everyone you know, big house party', [
            ...family,
            ...friends,
            ...l.npcs.where((n) => n.alive && n.circle == 'Work'),
          ], 800),
          Choice(
            label: 'Cancel the party',
            outcome: 'You decided a quiet night in was the real party.',
          ),
        ],
      );
    case 'black_market':
      Choice item(
        String label,
        int cost,
        String text,
        Map<String, int> stats, {
        String? flag,
      }) => Choice(
        label: '$label (${_m(cost)})',
        outcome: '',
        needsMoney: cost,
        risk: '15% chance of a police sting',
        run: (l, rng) {
          l.money -= cost;
          l.stats.add('karma', -3);
          if (rng.nextInt(100) < 15) {
            caughtInTheAct(l, 'black_market');
            return 'The "seller" flashed a police badge. It was a sting.';
          }
          stats.forEach(l.stats.add);
          if (flag != null) l.flags[flag] = Memory(l.age, label.toLowerCase());
          return text;
        },
      );
      return _scene(
        id,
        'A friend of a friend knows a guy who knows a car park. In the boot of a hatchback: things that definitely fell off a lorry.',
        category: 'crime',
        [
          item('A fake ID', 300, 'It looks almost real. Almost.', {
            'happiness': 1,
          }, flag: 'fake_id'),
          item('A "designer" handbag', 200, 'Nobody can tell. You can tell.', {
            'looks': 1,
          }),
          item(
            'A phone with no box and no questions',
            150,
            'It works. You try not to think about whose it was.',
            {'happiness': 1},
          ),
          Choice(
            label: 'Walk away',
            outcome: 'You decided you did not need any of it that badly.',
          ),
        ],
      );
  }
  return null;
}

// ---------------- Actions ----------------

final communityActions = <GameAction>[
  GameAction(
    id: 'library_card',
    label: 'Get a library card',
    category: 'Hobbies',
    keywords: ['library', 'card', 'books', 'borrow'],
    minAge: 5,
    extraCheck: (l) =>
        l.flags.containsKey('library_card') ? 'You already have one' : null,
    run: (l, rng) {
      l.flags['library_card'] = Memory(l.age, 'your first library card');
      return statChange(
        l,
        'The librarian laminated your card like it was a passport. Reading now teaches you a little more.',
        {'smarts': 1, 'happiness': 2},
      );
    },
  ),
  GameAction(
    id: 'road_trip',
    label: 'Take a road trip',
    category: 'Travel',
    keywords: ['road trip', 'drive', 'trip', 'car', 'travel'],
    minAge: 18,
    cost: 400,
    extraCheck: (l) => l.has('car') ? null : 'Needs a car',
    run: (l, rng) {
      l.money -= 400;
      final buddy = l.who('@partner') ?? l.who('@friend');
      buddy?.addFacets(affection: 6);
      const stories = [
        'A flat tyre in the middle of nowhere turned into the best roadside picnic of your life.',
        'You chased a sunset down the coast road and made it with ten seconds to spare.',
        'A wrong turn led to a tiny village festival where you danced until midnight.',
      ];
      final r = statChange(
        l,
        '${stories[rng.nextInt(stories.length)]}${buddy == null ? '' : ' ${buddy.name.split(' ').first} rode shotgun and picked every song.'}',
        {'happiness': 7, 'creativity': 1},
      );
      return ActionResult(r.text, [
        'Money −\$400',
        ...r.notes,
        if (buddy != null) 'Bond with ${buddy.name.split(' ').first} up',
      ]);
    },
  ),
  GameAction(
    id: 'black_market',
    label: 'Visit the black market',
    category: 'Crime',
    keywords: ['black market', 'illegal', 'fake id', 'stolen'],
    minAge: 18,
    hint: (l) => 'Stolen and fake goods · 15% chance of a sting',
    run: (l, rng) {
      l.sceneQueue.add('black_market');
      return ActionResult('You text a number a friend gave you.');
    },
  ),
  GameAction(
    id: 'reflect',
    miniGame: 'timing',
    scored: reflectScored,
    label: 'Pray or reflect',
    category: 'Faith',
    keywords: [
      'pray',
      'prayer',
      'reflect',
      'faith',
      'quiet',
      'church',
      'mosque',
      'temple',
    ],
    minAge: 4,
    run: (l, rng) {
      l.stress = l.stress - 5;
      return statChange(
        l,
        'You took a quiet moment to pray or simply be still. Whatever you believe, it helped you breathe.',
        {'happiness': 2, 'willpower': 1},
      );
    },
  ),
  GameAction(
    id: 'community_service',
    label: 'Join a community gathering',
    category: 'Faith',
    keywords: [
      'community',
      'service',
      'gathering',
      'congregation',
      'faith',
      'festival',
    ],
    minAge: 4,
    run: (l, rng) {
      for (final n in l.npcs.where((n) => n.alive && n.circle == 'Family')) {
        n.addFacets(affection: 1);
      }
      return statChange(
        l,
        'You joined a community gathering: shared food, old songs and people who asked how you were and meant it.',
        {'happiness': 3, 'karma': 1},
      );
    },
  ),
  GameAction(
    id: 'emigrate',
    label: 'Move abroad',
    category: 'Travel',
    keywords: ['emigrate', 'move abroad', 'visa', 'move country', 'abroad'],
    minAge: 18,
    priceNote: '\$3,000 · pick a country from the list',
    extraCheck: (l) => studying(l) ? 'Finish your course first' : null,
    // The Move abroad screen picks the country (ui/move_abroad.dart).
    screen: 'move_abroad',
    run: (l, rng) {
      l.sceneQueue.add('emigrate');
      return ActionResult('You open the visa website.');
    },
  ),
];
