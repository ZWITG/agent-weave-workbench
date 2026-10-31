import 'dart:math';

import 'actions.dart';
import 'celebrity.dart' show addFame, addImage;
import 'family.dart' show childrenOf;
import 'models.dart';
import 'storylet.dart';

// The upper echelon: a stage of life that opens, unannounced until then,
// when your net worth passes the equivalent of US$100 million. About
// 117,000 people in the world are worth that much and about 3,800 are
// billionaires (Altrata World Ultra Wealth Report 2025; Fortune 2026).
// The activities follow what the ultra-rich actually do with their money:
// trophy assets (islands, superyachts, sports teams, art), space flights,
// philanthropy and foundations, media and political influence, family
// offices, security and longevity, and trusts for their heirs.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'money',
  scene: true,
  choices: choices,
);

/// The line into the upper echelon, in game dollars (US price level).
const eliteThreshold = 100000000;

/// The billionaire milestone.
const billion = 1000000000;

bool upperEchelon(Life l) => l.flags.containsKey('upper_echelon');

/// Roughly how many people in the world are richer than you: a Pareto
/// curve through ~117,000 people above $100M and ~3,800 above $1B.
int richerThan(int netWorth) {
  if (netWorth <= 0) return 8000000000;
  final n = 3800 * pow(1e9 / netWorth, 1.49);
  return max(0, n.round() - 1);
}

String richRank(Life l) {
  final n = richerThan(l.netWorth);
  if (n < 1) return 'the richest person alive';
  if (n < 10) return 'one of the ${n + 1} richest people alive';
  final rounded = n >= 1000 ? (n / 1000).round() * 1000 : (n / 10).round() * 10;
  return 'one of about ${rounded.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')} people this rich';
}

// ---------------- Each birthday ----------------

/// Opens the stage when you cross the line, then the life up there:
/// rich-list news, invitations, threats, teams, heirs and yearly costs.
List<String> eliteYear(Life l, Random rng) {
  final feed = <String>[];
  if (!upperEchelon(l)) {
    if (l.netWorth >= eliteThreshold && l.age >= 18) {
      l.flags['upper_echelon'] = Memory(l.age, 'joining the upper echelon');
      l.sceneQueue.add('elite_intro');
    }
    return feed;
  }
  // Selling the newspaper ends the protection it gave.
  if (l.marks.contains('paper_publicist') && !l.has('media')) {
    l.marks.removeAll(['publicist', 'paper_publicist']);
  }
  // Sports teams: a season every year.
  for (final t in l.assets.where((a) => a.kind == 'team')) {
    final big = t.value >= 300000000;
    // Star signings tilt the season; a new stadium lifts the takings.
    final squad = (t.info['squad'] as int?) ?? 0;
    final roll = max(0, rng.nextInt(100) - squad);
    final result = roll < 15
        ? 'won the league'
        : roll < 60
        ? 'had a respectable season'
        : 'were relegated amid fan protests';
    final income = roll < 15
        ? (big ? 25000000 : 4000000)
        : roll < 60
        ? (big ? 5000000 : 500000)
        : (big ? -15000000 : -2000000);
    final gate = t.info['stadium'] == true && income > 0 ? income ~/ 2 : 0;
    l.money += income + gate;
    t.info['squad'] = max(0, squad - 4); // stars age and leave
    if (roll < 15) {
      addFame(l, 4);
      l.stats.add('happiness', 5);
    } else if (roll >= 60) {
      addImage(l, -4);
    }
    feed.add(
      'Your ${t.name.toLowerCase()} $result. ${income + gate >= 0 ? 'Profit' : 'Loss'}: ${_m((income + gate).abs())}.',
    );
  }
  // The longevity clinic and foundation, every year.
  if (l.marks.contains('longevity')) l.stats.add('health', 3);
  if (l.marks.contains('foundation')) {
    l.stats.add('karma', 1);
    addImage(l, 2);
  }
  // Three commas: the billion-dollar milestone.
  if (l.netWorth >= billion && !l.flags.containsKey('billionaire')) {
    l.flags['billionaire'] = Memory(l.age, 'becoming a billionaire');
    l.sceneQueue.add('elite_billion');
  }
  // Falling off the list (the stage stays open; the world notices).
  if (l.netWorth < eliteThreshold ~/ 2 && !l.marks.contains('fallen')) {
    l.marks.add('fallen');
    addImage(l, -5);
    feed.add(
      'The rich list dropped you. A magazine ran a piece called "Where did it all go?" with your photo.',
    );
  } else if (l.netWorth >= eliteThreshold) {
    l.marks.remove('fallen');
  }
  final queued = l.sceneQueue.any((s) => s.startsWith('elite_'));
  if (!queued && l.marks.contains('offshore') && rng.nextInt(100) < 6) {
    l.sceneQueue.add('elite_leak');
    return feed;
  }
  if (!queued && rng.nextInt(100) < 8) {
    l.sceneQueue.add('elite_ask');
    return feed;
  }
  final roll = rng.nextInt(100);
  if (!queued && !l.marks.contains('security') && roll < 7) {
    l.sceneQueue.add('elite_threat');
  } else if (roll < 30) {
    feed.add(switch (rng.nextInt(4)) {
      0 => 'An invitation arrived for the World Forum in the mountains: presidents, CEOs and you, in the same ski lodge.',
      1 => 'You were photographed at the Spring Gala in a borrowed tiara worth more than most houses.',
      2 =>
        'The rich list came out: you are ${richRank(l)}. Your phone filled with requests from people you have never met.',
      _ => 'A charity, a museum and three universities wrote asking for money, all on the same day.',
    });
  } else if (l.image < -30 && roll < 45) {
    addImage(l, -3);
    l.stats.add('happiness', -3);
    feed.add(
      'Protesters gathered outside your home with banners about inequality. Your name was on one of them.',
    );
  }
  // Heirs notice what is coming to them.
  final heirs = childrenOf(l)
      .where((c) => c.alive && c.ageIn(l.year) >= 18)
      .toList();
  if (heirs.isNotEmpty && rng.nextInt(100) < 12) {
    final h = heirs[rng.nextInt(heirs.length)];
    final trust = l.marks.contains('trusts');
    h.addFacets(affection: trust ? 2 : -3);
    feed.add(
      trust
          ? '${h.name.split(' ').first} thanked you for the trust fund and started a business with it.'
          : '${h.name.split(' ').first} asked, not very subtly, what happens to "all this" when you are gone.',
    );
  }
  return feed;
}

/// Yearly costs of life at the top (cash-flow lines).
List<(String, int)> eliteCosts(Life l) => [
  if (l.marks.contains('family_office'))
    ('Family office (fees, net of extra returns)', familyOfficeNet(l)),
  if (l.marks.contains('security')) ('Security detail', -2000000),
  if (l.marks.contains('longevity')) ('Longevity clinic', -1000000),
  if (l.marks.contains('foundation'))
    ('Your foundation\'s grants', -foundationGrants(l)),
  for (final i in l.assets.where((a) => a.info['resort'] == true))
    ('${i.name} resort', i.value * 6 ~/ 100),
  if (l.marks.contains('offshore'))
    ('Offshore structures (tax saved, net of fees)', offshoreNet(l)),
  if (l.has('bunker')) ('Bunker caretakers', -200000),
];

/// Offshore money earns about 0.8% a year more after fees, before any
/// leak comes along.
int offshoreNet(Life l) =>
    ((l.savings + l.invested + l.portfolioValue) * 0.008).round() - 250000;

/// The foundation's endowment (kept with the music state, which is saved).
int foundationFund(Life l) => (l.music['foundation'] as int?) ?? 0;

/// A family office costs fees but earns about 1% more on your money.
int familyOfficeNet(Life l) =>
    ((l.savings + l.invested + l.portfolioValue) * 0.01).round() - 1500000;

/// A foundation gives away 5% of its endowment a year.
int foundationGrants(Life l) => (foundationFund(l) * 0.05).round();

// ---------------- Scenes ----------------

Storylet? eliteScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'elite_intro':
      return _scene(
        id,
        'Your accountant asked for a meeting in person. She closed the door and said quietly: "You are now ${richRank(l)}." Doors you did not know existed have opened: private banks, invitations, people who want something. This is the upper echelon.',
        [
          Choice(
            label: 'Enjoy it',
            outcome: 'You opened a very old bottle of something and looked at the view for a long time. The Upper echelon is in Activities now.',
            run: (l, rng) {
              l.stats.add('happiness', 8);
              return null;
            },
          ),
          Choice(
            label: 'Think about what it is for',
            outcome: 'You lay awake thinking about what all of it could do. The Upper echelon is in Activities now.',
            run: (l, rng) {
              l.stats.add('karma', 3);
              return null;
            },
          ),
        ],
      );
    case 'elite_billion':
      return _scene(
        id,
        'Your family office called before breakfast: on paper, you are now worth more than \$1,000,000,000. Fewer than 4,000 people alive can say that. The business press wants a quote.',
        [
          Choice(
            label: 'Throw a party worthy of it',
            needsMoney: 2000000,
            outcome: 'Fireworks over the water, a famous band, and four hundred guests you half knew. Your name trended for two days.',
            run: (l, rng) {
              l.money -= 2000000;
              addFame(l, 6);
              l.stats.add('happiness', 10);
              return null;
            },
          ),
          Choice(
            label: 'Say nothing and keep working',
            outcome: 'You declined every interview. That made them write about you more.',
            run: (l, rng) {
              l.stats.add('smarts', 2);
              addImage(l, 4);
              return null;
            },
          ),
          Choice(
            label: 'Sign the Giving Pledge',
            outcome: '',
            risk: 'Promise to give away at least half your wealth',
            run: (l, rng) {
              l.marks.add('pledge');
              l.stats.add('karma', 10);
              addImage(l, 15);
              return 'You signed a public promise to give away most of your fortune. The letter you wrote for it was read on the news.';
            },
          ),
        ],
      );
    case 'elite_leak':
      return _scene(
        id,
        'A leak of millions of files from an offshore law firm hit the news this morning. Your name is in them, next to three companies in places you have never visited.',
        [
          Choice(
            label: 'Settle with the tax office',
            outcome: '',
            needsMoney: (l.netWorth * 0.02).round(),
            risk: 'Costs about 2% of your net worth',
            run: (l, rng) {
              final bill = (l.netWorth * 0.02).round();
              l.money -= bill;
              l.marks.remove('offshore');
              addImage(l, -6);
              return 'You paid ${_m(bill)} and closed the companies. The story faded within a week.';
            },
          ),
          Choice(
            label: 'Deny everything',
            outcome: '',
            risk: 'Lawyers say it was all legal',
            run: (l, rng) {
              if (rng.nextInt(100) < 55) {
                addImage(l, -4);
                return 'Your lawyers buried the reporters in letters. It was legal, technically, and the story moved on.';
              }
              final fine = (l.netWorth * 0.05).round();
              l.money -= fine;
              l.marks.remove('offshore');
              addImage(l, -20);
              l.stats.add('happiness', -8);
              return 'A second leak proved you had lied. The fine was ${_m(fine)}, and the headlines were worse.';
            },
          ),
          Choice(
            label: 'Bring the money home and apologise',
            outcome: 'You closed the companies and apologised on camera. Some people respected it.',
            run: (l, rng) {
              l.marks.remove('offshore');
              addImage(l, -2);
              l.stats.add('karma', 3);
              return null;
            },
          ),
        ],
      );
    case 'elite_ask':
      final ask = 1000000;
      return _scene(
        id,
        'An old school friend you have not spoken to in twenty years called. Their child is sick, the treatment is abroad, and they asked, ashamed, for ${_m(ask)}.',
        [
          Choice(
            label: 'Pay for everything',
            outcome: 'The treatment worked. Their child sent you a drawing that you keep on your desk.',
            needsMoney: ask,
            run: (l, rng) {
              l.money -= ask;
              l.stats.add('karma', 6);
              l.stats.add('happiness', 5);
              return null;
            },
          ),
          Choice(
            label: 'Have your office look into it',
            outcome: '',
            needsMoney: ask,
            risk: 'Might be real, might not',
            run: (l, rng) {
              if (rng.nextInt(100) < 50) {
                l.money -= ask;
                l.stats.add('karma', 4);
                return 'It checked out. You paid, quietly, through the foundation.';
              }
              l.stats.add('happiness', -3);
              return 'There was no sick child. It was a scam using your friend\'s name. You trust people a little less now.';
            },
          ),
          Choice(
            label: 'Say no',
            outcome: 'You said you could not help. Rich people get these calls every week, you told yourself.',
            run: (l, rng) {
              l.stats.add('karma', -3);
              return null;
            },
          ),
        ],
      );
    case 'elite_threat':
      final ransom = max(1000000, (l.netWorth * 0.01).round());
      return _scene(
        id,
        'A message from an unknown number, with a photo of your front gate: "Pay ${_m(ransom)} or we will make sure you regret it."',
        [
          Choice(
            label: 'Call the police and hire security',
            outcome: '',
            risk: 'A security detail costs \$2,000,000 a year',
            run: (l, rng) {
              l.marks.add('security');
              return 'Within hours there were guards at the gate and a former special forces officer in your kitchen. The threats stopped.';
            },
          ),
          Choice(
            label: 'Pay quietly',
            outcome: '',
            needsMoney: ransom,
            run: (l, rng) {
              l.money -= ransom;
              l.stats.add('happiness', -5);
              return 'You paid. It went quiet. You will never know if they would have done anything.';
            },
          ),
          Choice(
            label: 'Ignore it',
            outcome: '',
            risk: 'It might be nothing',
            run: (l, rng) {
              if (rng.nextInt(100) < 70) {
                return 'It was nothing. Or someone lost their nerve.';
              }
              l.stats.add('health', -10);
              l.stats.add('happiness', -10);
              l.money -= ransom ~/ 2;
              return 'Two men grabbed you outside a restaurant. You were released after three days and a payment. You do not go anywhere alone now.';
            },
          ),
        ],
      );
    case 'elite_island':
      Choice island(String name, int price, String blurb) => Choice(
        label: '$name · ${_m(price)}',
        outcome: '',
        risk: blurb,
        needsMoney: price,
        run: (l, rng) {
          l.money -= price;
          l.assets.add(
            Asset(
              id: 'island${l.age}_${l.assets.length}',
              kind: 'island',
              name: name,
              value: price,
              yearlyCost: price ~/ 50,
              since: l.age,
              info: {'dep': -3},
            ),
          );
          addFame(l, 3);
          l.stats.add('happiness', 6);
          return 'The island is yours. You walked its whole beach barefoot on the first morning.';
        },
      );
      return _scene(id, 'Three islands are quietly for sale.', [
        island('A Caribbean cay', 25000000, 'White sand, one jetty'),
        island('A Pacific atoll', 60000000, 'A lagoon and an airstrip'),
        island(
          'A Mediterranean island with a villa',
          120000000,
          'A harbour, a vineyard, a staff of twelve',
        ),
        Choice(label: 'Not now', outcome: 'You kept looking at the map.'),
      ]);
    case 'elite_team':
      Choice team(String name, int price, String blurb) => Choice(
        label: '$name · ${_m(price)}',
        outcome: '',
        risk: blurb,
        needsMoney: price,
        run: (l, rng) {
          l.money -= price;
          l.assets.add(
            Asset(
              id: 'team${l.age}_${l.assets.length}',
              kind: 'team',
              name: name,
              value: price,
              yearlyCost: 0,
              since: l.age,
              info: {'dep': -5},
            ),
          );
          addFame(l, price >= 300000000 ? 10 : 4);
          return 'You held up the scarf at the press conference. The fans chanted your name, for now.';
        },
      );
      return _scene(id, 'Two clubs are for sale.', [
        team(
          'A lower-league football club',
          30000000,
          'A loyal town and a crumbling stadium',
        ),
        team(
          'A top-flight club',
          600000000,
          'Global fans, global scrutiny, big money either way',
        ),
        Choice(
          label: 'Not now',
          outcome: 'You watched the match from the stands.',
        ),
      ]);
  }
  return null;
}

// ---------------- Activities ----------------

String? _elite(Life l) => upperEchelon(l) ? null : 'Not available';

GameAction _buy(
  String id,
  String label,
  List<String> keywords,
  String note,
  ActionResult Function(Life l, Random rng) run, {
  int cost = 0,
  String? Function(Life l)? extra,
  bool repeatable = false,
}) => GameAction(
  id: id,
  label: label,
  category: 'Upper echelon',
  keywords: keywords,
  minAge: 18,
  priceNote: note,
  repeatable: repeatable,
  extraCheck: (l) =>
      _elite(l) ??
      (cost > 0 && l.money < cost ? 'Needs ${_m(cost)} in cash' : null) ??
      extra?.call(l),
  run: run,
);

final eliteActions = <GameAction>[
  _buy(
    'rich_list',
    'Where you stand',
    ['rich list', 'net worth', 'ranking', 'billionaire'],
    'The rich list',
    (l, rng) => ActionResult('You are ${richRank(l)}.', [
      'Net worth ${_m(l.netWorth)}',
      'About 117,000 people in the world are worth over \$100,000,000, and about 3,800 are billionaires',
      if (foundationFund(l) > 0)
        'Your foundation holds ${_m(foundationFund(l))}',
      if (l.marks.contains('pledge')) 'You have signed the Giving Pledge',
    ]),
    repeatable: true,
  ),
  _buy(
    'buy_island',
    'Buy a private island',
    ['island', 'private island', 'buy island'],
    'From \$25,000,000',
    (l, rng) {
      l.sceneQueue.add('elite_island');
      return ActionResult('Your broker sends a discreet brochure.');
    },
    cost: 25000000,
  ),
  _buy(
    'superyacht',
    'Commission a superyacht',
    ['superyacht', 'yacht', 'boat', 'mega yacht'],
    '\$40,000,000 · crew and fuel about \$4,000,000 a year',
    (l, rng) {
      l.money -= 40000000;
      l.assets.add(
        Asset(
          id: 'superyacht${l.age}',
          kind: 'boat',
          name: 'Superyacht',
          value: 40000000,
          yearlyCost: 4000000,
          since: l.age,
          info: {'dep': 6},
        ),
      );
      addFame(l, 2);
      l.stats.add('happiness', 5);
      return ActionResult(
        'Sixty metres, a helipad and a crew of eighteen who call you "the principal". It sailed out of the shipyard under your name.',
        ['Money −${_m(40000000)}', 'Upkeep ${_m(4000000)} a year'],
      );
    },
    cost: 40000000,
    extra: (l) => l.assets.any((a) => a.name == 'Superyacht')
        ? 'You already have one'
        : null,
  ),
  _buy(
    'buy_team',
    'Buy a sports team',
    ['sports team', 'football club', 'buy club', 'team owner'],
    'From \$30,000,000 · seasons win or lose money',
    (l, rng) {
      l.sceneQueue.add('elite_team');
      return ActionResult('Your bankers make some calls.');
    },
    cost: 30000000,
  ),
  _buy(
    'art_auction',
    'Bid at an art auction',
    ['art', 'auction', 'painting', 'masterpiece', 'collector'],
    'Masterpieces from \$15,000,000 · they tend to gain value',
    (l, rng) {
      // The hammer price, never more than you can pay on the day.
      final price = min(15000000 + rng.nextInt(16) * 5000000, l.money);
      l.money -= price;
      final artists = [
        'an Impressionist',
        'a Cubist',
        'a Renaissance',
        'a Pop Art',
      ];
      final who = artists[rng.nextInt(artists.length)];
      l.assets.add(
        Asset(
          id: 'art${l.age}_${l.assets.length}',
          kind: 'valuable',
          name: 'Masterpiece by $who painter',
          value: price,
          yearlyCost: price ~/ 200,
          since: l.age,
          info: {'dep': -6},
        ),
      );
      addFame(l, 2);
      return ActionResult(
        'The paddle went up, the room gasped, the hammer fell. A masterpiece by $who painter is yours.',
        ['Money −${_m(price)}', 'Insurance about ${_m(price ~/ 200)} a year'],
      );
    },
    cost: 15000000,
  ),
  _buy(
    'space_flight',
    'Fly to space',
    ['space', 'rocket', 'astronaut', 'orbit', 'space tourism'],
    '\$28,000,000 for a seat on a rocket',
    (l, rng) {
      l.money -= 28000000;
      l.flags['astronaut'] = Memory(l.age, 'seeing the Earth from space');
      addFame(l, 6);
      l.stats.add('happiness', 12);
      return ActionResult(
        'Four minutes of weightlessness and the curve of the Earth below, thin blue atmosphere and all. Nobody who has seen it comes back quite the same.',
        ['Money −${_m(28000000)}', 'Fame up'],
      );
    },
    cost: 28000000,
    extra: (l) => l.flags.containsKey('astronaut') ? 'You have been' : null,
  ),
  _buy(
    'start_foundation',
    'Start a foundation',
    ['foundation', 'charity', 'philanthropy', 'giving pledge', 'donate'],
    'Give 10% of your net worth · it gives 5% away every year',
    (l, rng) {
      final gift = (l.netWorth * 0.1).round();
      l.money -= gift;
      l.music['foundation'] = foundationFund(l) + gift;
      l.marks.add('foundation');
      l.stats.add('karma', 10);
      addImage(l, 20);
      addFame(l, 3);
      return ActionResult(
        'You signed the papers for a foundation with your family name on it, to fund schools and clinics for as long as the money lasts.',
        ['Money −${_m(gift)}', 'Image up', 'Karma up'],
      );
    },
    extra: (l) => l.money < l.netWorth * 0.1
        ? 'Needs 10% of your net worth in cash'
        : l.marks.contains('foundation')
        ? 'Your foundation is running'
        : null,
  ),
  _buy(
    'name_building',
    'Put your name on a university building',
    ['university', 'endow', 'building', 'donation', 'legacy'],
    '\$50,000,000',
    (l, rng) {
      l.money -= 50000000;
      l.flags['endowed'] = Memory(l.age, 'a building with your name on it');
      addImage(l, 10);
      l.stats.add('karma', 4);
      return ActionResult(
        'Students will walk past ${l.surname} Hall for a hundred years. Your grandchildren will be admitted somewhere, at least.',
        ['Money −${_m(50000000)}', 'Image up'],
      );
    },
    cost: 50000000,
    extra: (l) => l.flags.containsKey('endowed') ? 'Already done' : null,
  ),
  _buy(
    'buy_newspaper',
    'Buy a newspaper',
    ['newspaper', 'media', 'press', 'buy media'],
    '\$100,000,000 · loses money, buys influence',
    (l, rng) {
      l.money -= 100000000;
      l.assets.add(
        Asset(
          id: 'paper${l.age}',
          kind: 'media',
          name: 'National newspaper',
          value: 100000000,
          yearlyCost: 5000000,
          since: l.age,
          info: {'dep': 4},
        ),
      );
      // Your own paper does not print rumours about you.
      if (!l.marks.contains('publicist')) {
        l.marks.addAll(['publicist', 'paper_publicist']);
      }
      addImage(l, -5);
      return ActionResult(
        'You bought a 150-year-old newspaper. The editor resigned on the first day. The rumours about you stopped on the second.',
        ['Money −${_m(100000000)}', 'Loses about ${_m(5000000)} a year'],
      );
    },
    cost: 100000000,
    extra: (l) => l.has('media') ? 'You own one already' : null,
  ),
  _buy(
    'family_office',
    'Set up a family office',
    ['family office', 'wealth manager', 'investments', 'private bank'],
    '\$1,500,000 a year · about 1% more on your money',
    (l, rng) {
      l.marks.add('family_office');
      return ActionResult(
        'A small team of very quiet people now manages your money, your taxes and your family\'s affairs.',
        [
          'Fees ${_m(1500000)} a year',
          'About 1% a year more on savings and investments',
        ],
      );
    },
    extra: (l) => l.marks.contains('family_office') ? 'Already set up' : null,
  ),
  _buy(
    'security_detail',
    'Hire a security detail',
    ['security', 'bodyguards', 'protection', 'kidnap'],
    '\$2,000,000 a year · no more threats',
    (l, rng) {
      l.marks.add('security');
      return ActionResult(
        'Discreet people in good suits now travel with you everywhere.',
        ['${_m(2000000)} a year'],
      );
    },
    extra: (l) => l.marks.contains('security') ? 'Already hired' : null,
  ),
  _buy(
    'longevity_clinic',
    'Join a longevity clinic',
    ['longevity', 'anti ageing', 'health', 'clinic', 'live longer'],
    '\$1,000,000 a year · Health up every year',
    (l, rng) {
      l.marks.add('longevity');
      l.stats.add('health', 4);
      return ActionResult(
        'Blood tests every month, cold plunges at dawn and a doctor who answers at any hour.',
        ['${_m(1000000)} a year', 'Health +3 every year'],
      );
    },
    extra: (l) => l.marks.contains('longevity') ? 'Already a member' : null,
  ),
  _buy(
    'political_influence',
    'Fund a political campaign',
    ['politics', 'donate', 'campaign', 'lobby', 'influence'],
    '\$10,000,000 · power, at a price',
    (l, rng) {
      l.money -= 10000000;
      l.flags['kingmaker'] = Memory(l.age, 'backing a winning campaign');
      l.stats.add('karma', -3);
      addImage(l, -6);
      addFame(l, 3);
      return ActionResult(
        'Your candidate won. They return your calls now, and the papers have started writing about "the donor".',
        ['Money −${_m(10000000)}', 'Image down', 'Influence up'],
      );
    },
    cost: 10000000,
  ),
  _buy(
    'trust_funds',
    'Set up trust funds for your children',
    ['trust fund', 'heirs', 'inheritance', 'children'],
    '\$5,000,000 for each child',
    (l, rng) {
      final kids = childrenOf(l).where((c) => c.alive).toList();
      final cost = kids.length * 5000000;
      l.money -= cost;
      l.marks.add('trusts');
      for (final k in kids) {
        k.addFacets(affection: 4, trust: 3);
      }
      return ActionResult(
        'Lawyers drew up trusts for ${kids.length} child${kids.length == 1 ? '' : 'ren'}: income now, the rest at 30.',
        ['Money −${_m(cost)}'],
      );
    },
    extra: (l) => l.marks.contains('trusts')
        ? 'Already set up'
        : childrenOf(l).where((c) => c.alive).isEmpty
        ? 'Needs children'
        : l.money < childrenOf(l).where((c) => c.alive).length * 5000000
        ? 'Needs \$5,000,000 for each child'
        : null,
  ),
  // ---------------- Using what you own ----------------
  _buy(
    'island_retreat',
    'Host friends on your island',
    ['island', 'retreat', 'holiday', 'party', 'friends'],
    'Flights and staff about \$300,000',
    (l, rng) {
      final isle = _first(l, 'island')!;
      l.money -= 300000;
      l.stats.add('happiness', 8);
      addFame(l, 1);
      final guests = l.npcs
          .where(
            (p) =>
                p.alive &&
                !p.contactCut &&
                (p.circle == 'Friends' || p.circle == 'Partner'),
          )
          .take(4)
          .toList();
      for (final g in guests) {
        g.addFacets(affection: 3);
      }
      return ActionResult(
        'A week on ${isle.name.toLowerCase()}: no phones, long dinners${guests.isEmpty ? '' : ' with ${guests.map((g) => g.name.split(' ').first).join(', ')}'}. The photos leaked anyway.',
        ['Money −${_m(300000)}', 'Happiness up'],
      );
    },
    cost: 300000,
    extra: (l) => _first(l, 'island') == null ? 'Needs an island' : null,
  ),
  _buy(
    'island_resort',
    'Turn your island into a resort',
    ['island', 'resort', 'hotel', 'tourism'],
    '\$10,000,000 to build · earns every year',
    (l, rng) {
      final isle = _first(l, 'island', (a) => a.info['resort'] != true)!;
      l.money -= 10000000;
      isle.info['resort'] = true;
      isle.value += 8000000;
      return ActionResult(
        'Twenty villas on stilts, a spa and a chef poached from Paris. ${isle.name} now takes guests at prices that need no menu.',
        [
          'Money −${_m(10000000)}',
          'Earns about ${_m(isle.value * 6 ~/ 100)} a year',
        ],
      );
    },
    cost: 10000000,
    extra: (l) => _first(l, 'island', (a) => a.info['resort'] != true) == null
        ? 'Needs an island that is not a resort yet'
        : null,
  ),
  _buy(
    'yacht_party',
    'Throw a party on your superyacht',
    ['yacht', 'party', 'cannes', 'monaco', 'celebrities'],
    'About \$500,000 a night',
    (l, rng) {
      l.money -= 500000;
      addFame(l, 3);
      l.stats.add('happiness', 6);
      final where = ['off Monaco', 'off Cannes', 'in St Barts', 'off Capri'];
      return ActionResult(
        'Anchored ${where[rng.nextInt(where.length)]}: a DJ on the helipad, film stars on the sundeck and a guest list the gossip pages printed in full.',
        ['Money −${_m(500000)}', 'Fame up'],
      );
    },
    cost: 500000,
    extra: (l) => l.assets.any((a) => a.name == 'Superyacht')
        ? null
        : 'Needs a superyacht',
  ),
  _buy(
    'sign_star',
    'Sign a superstar for your team',
    ['team', 'transfer', 'sign player', 'superstar', 'football'],
    'From \$20,000,000 · better seasons',
    (l, rng) {
      final t = _first(l, 'team')!;
      final fee = t.value >= 300000000 ? 80000000 : 20000000;
      l.money -= fee;
      t.info['squad'] = ((t.info['squad'] as int?) ?? 0) + 12;
      addFame(l, 2);
      return ActionResult(
        'The signing broke the transfer record for the club. Shirts with the new name sold out in an hour.',
        ['Money −${_m(fee)}', 'Better odds next season'],
      );
    },
    extra: (l) {
      final t = _first(l, 'team');
      if (t == null) return 'Needs a sports team';
      final fee = t.value >= 300000000 ? 80000000 : 20000000;
      return l.money < fee ? 'Needs ${_m(fee)} in cash' : null;
    },
  ),
  _buy(
    'new_stadium',
    'Build your team a new stadium',
    ['stadium', 'team', 'arena', 'build'],
    '\$150,000,000 · bigger takings in good years',
    (l, rng) {
      final t = _first(l, 'team', (a) => a.info['stadium'] != true)!;
      l.money -= 150000000;
      t.info['stadium'] = true;
      t.value += 120000000;
      addFame(l, 3);
      return ActionResult(
        'Sixty thousand seats, a roof that closes and your name over the gates. The old ground became flats.',
        ['Money −${_m(150000000)}', 'Team value up'],
      );
    },
    cost: 150000000,
    extra: (l) => _first(l, 'team', (a) => a.info['stadium'] != true) == null
        ? 'Needs a team without a new stadium'
        : null,
  ),
  _buy(
    'paper_campaign',
    'Have your newspaper back you',
    ['newspaper', 'editorial', 'media', 'headlines', 'press'],
    'Free · your editors may resent it',
    (l, rng) {
      addImage(l, 8);
      l.stats.add('karma', -2);
      return ActionResult(
        'A week of glowing front pages about your generosity and vision. Two journalists quit and wrote about why.',
        ['Image up'],
      );
    },
    extra: (l) => l.has('media') ? null : 'Needs a newspaper',
  ),
  _buy(
    'lend_art',
    'Lend a masterpiece to a museum',
    ['art', 'museum', 'lend', 'exhibition', 'painting'],
    'Free · the painting gains prestige',
    (l, rng) {
      final art = _masterpieces(l).firstWhere((a) => a.info['lent'] != true);
      art.info['lent'] = true;
      art.value = (art.value * 1.1).round();
      addImage(l, 5);
      l.stats.add('karma', 2);
      return ActionResult(
        'Your ${art.name.toLowerCase()} hung in a national museum with a small card: "Lent by a private collector". Everyone knew.',
        ['Image up', 'Its value rose'],
      );
    },
    extra: (l) => _masterpieces(l).any((a) => a.info['lent'] != true)
        ? null
        : 'Needs a masterpiece you have not lent',
  ),
  _buy(
    'private_museum',
    'Open your own museum',
    ['museum', 'art', 'gallery', 'collection', 'legacy'],
    '\$30,000,000 · needs two masterpieces',
    (l, rng) {
      l.money -= 30000000;
      l.flags['museum'] = Memory(l.age, 'opening a museum');
      addImage(l, 8);
      addFame(l, 3);
      return ActionResult(
        'A concrete building by a famous architect, free entry on Sundays, and your collection on the walls.',
        ['Money −${_m(30000000)}', 'Image and fame up'],
      );
    },
    cost: 30000000,
    extra: (l) => l.flags.containsKey('museum')
        ? 'Already open'
        : _masterpieces(l).length < 2
        ? 'Needs two masterpieces'
        : null,
  ),
  // ---------------- What the ultra-rich buy ----------------
  _buy(
    'second_passport',
    'Buy a second citizenship',
    ['passport', 'citizenship', 'visa', 'golden visa', 'residency'],
    '\$2,000,000 · moving abroad gets much easier',
    (l, rng) {
      l.money -= 2000000;
      l.flags['second_passport'] = Memory(l.age, 'a second passport');
      return ActionResult(
        'An investment in a small island nation came with a passport. Borders mostly open for you now.',
        ['Money −${_m(2000000)}', 'Visas far more likely'],
      );
    },
    cost: 2000000,
    extra: (l) =>
        l.flags.containsKey('second_passport') ? 'You have one' : null,
  ),
  _buy(
    'bunker',
    'Build a bunker',
    ['bunker', 'doomsday', 'shelter', 'new zealand', 'prepper'],
    '\$15,000,000 · caretakers \$200,000 a year',
    (l, rng) {
      l.money -= 15000000;
      l.assets.add(
        Asset(
          id: 'bunker${l.age}',
          kind: 'bunker',
          name: 'Bunker in New Zealand',
          value: 12000000,
          yearlyCost: 0,
          since: l.age,
          info: {'dep': 1},
        ),
      );
      l.stats.add('happiness', 2);
      return ActionResult(
        'Under a sheep farm: a year of food, filtered air, a cinema and a blast door. You hope never to see it again.',
        ['Money −${_m(15000000)}'],
      );
    },
    cost: 15000000,
    extra: (l) => l.has('bunker') ? 'You have one' : null,
  ),
  _buy(
    'foundation_gala',
    'Host a charity gala',
    ['gala', 'charity', 'fundraiser', 'ball', 'foundation'],
    '\$1,000,000 · raises money for your foundation',
    (l, rng) {
      l.money -= 1000000;
      final raised = (5 + rng.nextInt(16)) * 1000000 + l.fame * 100000;
      l.music['foundation'] = foundationFund(l) + raised;
      addFame(l, 2);
      addImage(l, 3);
      return ActionResult(
        'Black tie, a famous auctioneer and a dinner nobody ate. The night raised ${_m(raised)} for your foundation.',
        ['Money −${_m(1000000)}', 'Foundation +${_m(raised)}'],
      );
    },
    cost: 1000000,
    extra: (l) =>
        l.marks.contains('foundation') ? null : 'Needs a foundation first',
  ),
  _buy(
    'offshore',
    'Move money offshore',
    ['offshore', 'tax haven', 'shell company', 'tax'],
    'Saves tax every year · if it leaks, it gets ugly',
    (l, rng) {
      l.marks.add('offshore');
      l.stats.add('karma', -4);
      return ActionResult(
        'Your lawyers set up three companies in places with palm trees and no taxes. All legal, they said. Mostly.',
        ['About 0.8% a year more on savings and investments'],
      );
    },
    extra: (l) => l.marks.contains('offshore') ? 'Already offshore' : null,
  ),
  _buy(
    'giving_pledge',
    'Sign the Giving Pledge',
    ['giving pledge', 'philanthropy', 'give away', 'pledge'],
    'A public promise to give away half your fortune',
    (l, rng) {
      l.marks.add('pledge');
      l.stats.add('karma', 10);
      addImage(l, 15);
      return ActionResult(
        'You joined the list of billionaires who have promised to give most of it away.',
        ['Image up', 'Karma up'],
      );
    },
    extra: (l) => l.marks.contains('pledge')
        ? 'You have signed'
        : l.netWorth < billion
        ? 'For billionaires'
        : null,
  ),
];

Asset? _first(Life l, String kind, [bool Function(Asset a)? test]) => l.assets
    .where((a) => a.kind == kind && (test == null || test(a)))
    .firstOrNull;

List<Asset> _masterpieces(Life l) => l.assets
    .where((a) => a.kind == 'valuable' && a.name.startsWith('Masterpiece'))
    .toList();
