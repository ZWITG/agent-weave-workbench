import 'dart:math';

import 'family.dart' show childrenOf;
import 'love.dart' show partnerOf;
import 'economy.dart' show sellAsset;

import 'actions.dart';
import 'finance.dart';
import 'friends.dart';
import 'homes.dart';
import 'models.dart';
import 'property.dart';
import 'storylet.dart';
import 'world_data.dart';

// Real estate, the investor's side: a portfolio summary, property auctions
// (cheap, cash only, bought unseen, so a fixer-upper can be flipped for a
// profit or turn out to be a money pit), holiday lets (more money than a
// long let, more wear, swings with the economy), quick controls for each
// rental, and things to do in the home you live in.

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

// ---------------- Portfolio ----------------

typedef Portfolio = ({
  int homes,
  int value,
  int owed,
  int rent,
  int costs,
  int interest,
});

/// Everything you own in bricks and mortar, in one set of numbers.
Portfolio portfolioOf(Life l) {
  final houses = l.assets.where((a) => a.kind == 'house').toList();
  final lets = lettingsOf(l);
  final owed =
      (l.debts['Mortgage'] ?? 0) + (l.debts['Buy-to-let mortgage'] ?? 0);
  final btl = l.debts['Buy-to-let mortgage'] ?? 0;
  return (
    homes: houses.length,
    value: houses.fold(0, (s, a) => s + a.value),
    owed: owed,
    rent: lets.fold(0, (s, a) => s + rentIncome(l, a)),
    costs: lets.fold(0, (s, a) => s + a.yearlyCost + propertyTaxOn(l, a)),
    interest: (btl * rateOf(l, 'Buy-to-let mortgage')).round(),
  );
}

// ---------------- Property tax ----------------

/// Rough yearly property tax as a share of value, by country (local rates
/// vary; these are typical effective rates). China has no recurring tax on
/// homes yet; elsewhere it falls back to 0.5%.
const propertyTaxRates = <String, double>{
  'United States': 0.010,
  'Canada': 0.008,
  'United Kingdom': 0.006,
  'Ireland': 0.002,
  'France': 0.005,
  'Germany': 0.003,
  'Netherlands': 0.002,
  'Portugal': 0.004,
  'Spain': 0.005,
  'Italy': 0.004,
  'Sweden': 0.001,
  'Japan': 0.014,
  'South Korea': 0.002,
  'China': 0.0,
  'India': 0.002,
  'Philippines': 0.010,
  'Australia': 0.004,
  'Brazil': 0.006,
  'Argentina': 0.005,
  'Mexico': 0.001,
  'South Africa': 0.006,
  'Egypt': 0.001,
  'Nigeria': 0.003,
  'Kenya': 0.001,
};

double propertyTaxRate(String country) => propertyTaxRates[country] ?? 0.005;

/// This year's property tax on one building you own, rounded to \$10.
int propertyTaxOn(Life l, Asset a) {
  if (a.kind != 'house') return 0;
  return (a.value * propertyTaxRate(l.country) / 10).round() * 10;
}

/// Property tax on everything you own, paid with your other bills.
int propertyTax(Life l) => l.assets.fold(0, (s, a) => s + propertyTaxOn(l, a));

/// What your rentals make in a year after running costs and the interest
/// on their mortgage.
int rentalProfit(Life l) {
  final p = portfolioOf(l);
  return p.rent - p.costs - p.interest;
}

// ---------------- Quick controls for a rental ----------------

String setRentLevel(Life l, Asset a, String to) {
  a.info['rentLevel'] = to;
  return 'Rent on the ${a.name.toLowerCase()} is now ${_m(rentFor(a))} a year.';
}

String toggleAgent(Life l, Asset a) {
  final had = a.info['agent'] == true;
  a.info['agent'] = !had;
  return had
      ? 'You took the keys back from the letting agent.'
      : 'A letting agent now looks after the ${a.name.toLowerCase()} for 12% of the rent.';
}

String giveNotice(Life l, Asset a) {
  final t = tenantOf(a);
  if (t == null) return '';
  a.info['tenant'] = null;
  l.stats.add('karma', -1);
  return '${(t['name'] as String).split(' ').first} packed up and left. The keys are on the counter.';
}

// ---------------- Holiday lets ----------------

bool isHoliday(Asset a) => a.info['mode'] == 'holiday';

/// Beds, linen and a coffee machine for paying guests.
int furnishCost(Asset a) => max(3000, (a.value * 0.03 / 100).round() * 100);

/// How much more a holiday let earns than a long let, by economy.
const holidayBoost = {
  'Boom': 1.7,
  'Normal': 1.5,
  'Slowdown': 1.35,
  'Recession': 1.15,
  'Crash': 1.0,
};

/// Share of the year a holiday let was booked (rolled each birthday).
int occupancyOf(Asset a) => (a.info['occ'] as int?) ?? 65;

/// A holiday let's income for the year: long-let rent scaled by the
/// economy and bookings, less a fifth for cleaning and booking-site fees.
int holidayIncome(Life l, Asset a) =>
    ((rentFor(a) * (holidayBoost[l.economy] ?? 1.4) * occupancyOf(a) / 65) *
            0.8 /
            100)
        .round() *
    100;

String? holidayLock(Life l, Asset a) {
  if (isHoliday(a)) return null;
  if (l.money < furnishCost(a)) return 'Needs ${_m(furnishCost(a))} to furnish';
  return null;
}

ActionResult makeHolidayLet(Life l, Asset a) {
  final cost = furnishCost(a);
  final t = tenantOf(a);
  l.money -= cost;
  a.info
    ..remove('tenant')
    ..['mode'] = 'holiday'
    ..['occ'] = 65;
  if (t != null) l.stats.add('karma', -1);
  return ActionResult(
    'You furnished the ${a.name.toLowerCase()} in ${a.info['area']} and listed it for holiday guests.${t != null ? ' ${(t['name'] as String).split(' ').first} had to find somewhere else.' : ''}',
    [
      'Money −${_m(cost)}',
      'About ${_m(holidayIncome(l, a))} a year if bookings hold',
    ],
  );
}

ActionResult endHolidayLet(Life l, Asset a) {
  a.info
    ..remove('mode')
    ..remove('occ')
    ..['tenant'] = null;
  return ActionResult(
    'You took the ${a.name.toLowerCase()} off the holiday sites. It is empty and ready for a long-term tenant.',
  );
}

/// A holiday let's year: bookings, wear and the odd story.
List<String> holidayYear(Life l, Asset a, Random rng) {
  final feed = <String>[];
  final area = a.info['area'] as String? ?? '';
  final scenic = area == 'Riverside' || area == 'Harbour' || area == 'Old Town';
  var occ = 45 + rng.nextInt(41) + (scenic ? 8 : 0);
  occ += switch (l.economy) {
    'Boom' => 8,
    'Recession' => -10,
    'Crash' => -18,
    _ => 0,
  };
  if (a.condition < 50) occ -= 15;
  if (l.marks.remove('five_star:${a.id}')) occ += 10;
  // Ghost hunters love a haunted holiday let.
  if (List<String>.from(a.info['traits'] ?? const []).contains('haunted')) {
    occ += 10;
  }
  occ = occ.clamp(15, 98);
  a.info['occ'] = occ;
  a.condition = max(0, a.condition - 3 - rng.nextInt(4));
  final name = a.name.toLowerCase();
  final roll = rng.nextInt(100);
  if (roll < 10) {
    a.condition = max(0, a.condition - 12);
    feed.add(
      'A "quiet family weekend" at your holiday $name turned out to be a hen party. Condition ${a.condition}%.',
    );
  } else if (roll < 20) {
    l.marks.add('five_star:${a.id}');
    feed.add(
      'A guest at your holiday $name left a glowing five-star review. Bookings should pick up next year.',
    );
  } else if (roll < 25) {
    final fine = 500 + rng.nextInt(10) * 100;
    l.money -= fine;
    feed.add(
      'Neighbours of your holiday $name complained to the council about the wheelie suitcases at 3am. Fine: ${_m(fine)}.',
    );
  } else {
    feed.add(
      'Your holiday $name in $area was booked $occ% of the year (${_m(holidayIncome(l, a))}).',
    );
  }
  return feed;
}

// ---------------- Auctions ----------------

typedef Lot = ({
  int i,
  String type,
  int beds,
  bool garden,
  String area,
  int worth,
  int guide,
  int condition,
  int looks,
  List<String> traits,
  int upkeep,
  String why,
});

const _lotReasons = [
  'Repossessed by the bank',
  'Probate sale: the owner left no will',
  'Fire damage in the kitchen',
  'Empty for ten years',
  'The seller needs cash by Friday',
  'Former student house, well loved',
];

const _econ = {
  'Boom': 1.08,
  'Normal': 1.0,
  'Slowdown': 0.98,
  'Recession': 0.92,
  'Crash': 0.85,
};

/// This year's three auction lots: tired homes with a guide price well
/// under what they would be worth, sold as seen.
List<Lot> auctionLots(Life l) {
  final rng = Random(l.seed * 29 + l.age * 71 + 3);
  return [
    for (var i = 0; i < 3; i++)
      () {
        // Never a mansion at auction.
        final t = homeTypes[rng.nextInt(homeTypes.length - 1)];
        final area = areas.keys.elementAt(rng.nextInt(areas.length));
        final traits = <String>[
          for (final k in homeTraits.keys)
            if (rng.nextInt(100) < (homeTraits[k]!.$2 < 0 ? 32 : 12)) k,
        ];
        final looks = 25 + rng.nextInt(30);
        var cond = looks;
        for (final k in traits) {
          cond += homeTraits[k]!.$2;
        }
        cond = cond.clamp(10, 70);
        final base =
            200000 *
            countryProfile(l.country).cost *
            t.price *
            areas[area]!.$1 *
            (_econ[l.economy] ?? 1);
        final worth = (base * (0.75 + cond / 400) / 1000).round() * 1000;
        final guess = base * (0.75 + looks / 400);
        final guide =
            (guess * (0.6 + rng.nextDouble() * 0.12) / 1000).round() * 1000;
        return (
          i: i,
          type: t.name,
          beds: t.minBeds + rng.nextInt(t.maxBeds - t.minBeds + 1),
          garden: t.garden,
          area: area,
          worth: worth,
          guide: guide,
          condition: cond,
          looks: looks,
          traits: traits,
          upkeep: ((worth * 0.012) / 100).round() * 100,
          why: _lotReasons[rng.nextInt(_lotReasons.length)],
        );
      }(),
  ];
}

bool _lotGone(Life l, int i) => l.marks.contains('lot:${l.age}:$i');

/// Total cash a winning bid needs: the bid, 2% fees and 3% to the
/// auction house.
int lotCash(int bid) => (bid * 1.05).round();

String? auctionLock(Life l, int bid) {
  if (l.money < lotCash(bid)) {
    return 'Needs ${_m(lotCash(bid))} in cash (auctions take no mortgages)';
  }
  if (homeOf(l) != null && lettingsOf(l).length >= lettingCap(l)) {
    return 'You own ${lettingCap(l)} rentals already';
  }
  return null;
}

String _winLot(Life l, Lot lot, int bid) {
  l.marks.add('lot:${l.age}:${lot.i}');
  // An auction buy is never a move: it is your home only if you have none.
  final moving = l.marks.remove('hunt:${l.age}:move');
  final listing = (
    i: 20 + lot.i,
    type: lot.type,
    beds: lot.beds,
    garden: lot.garden,
    pool: false,
    area: lot.area,
    price: bid,
    condition: lot.condition,
    shown: lot.looks,
    traits: lot.traits,
    upkeep: lot.upkeep,
  );
  final text = buyListing(l, listing, bid);
  if (moving) l.marks.add('hunt:${l.age}:move');
  final fee = (bid * 0.03).round();
  l.money -= fee;
  final home = l.assets.last;
  home.value = lot.worth;
  home.info['auction'] = true;
  final found = lot.traits
      .where((t) => homeTraits[t]!.$2 < 0)
      .map((t) => homeTraits[t]!.$1)
      .toList();
  return 'Going, going, gone: the ${lot.type.toLowerCase()} is yours for ${_m(bid)} plus ${_m(fee)} to the auction house. '
      '${found.isEmpty ? 'Once inside, it was better than it looked. ' : 'Once inside you found ${found.join(' and ')}. '}'
      'Valued at ${_m(lot.worth)}. ${text.replaceFirst(RegExp(r'^You (bought|got)[^.]*\. '), '')}';
}

Asset? _asset(Life l, List<String> args) =>
    args.isEmpty ? null : l.assets.where((a) => a.id == args.first).firstOrNull;

Storylet? realtyScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'sell_home':
      final a = _asset(l, args);
      if (a == null) return null;
      Choice ask(String level, String label, double f) {
        final price = (a.value * f / 1000).round() * 1000;
        final odds = saleOdds(l, a, level);
        return Choice(
          label: '$label (${_m(price)})',
          outcome: '',
          risk: '$odds% chance of an offer this year',
          lock: (l) => l.marks.contains('sale:${l.age}:${a.id}:$level')
              ? 'No takers at that price this year'
              : null,
          run: (l, rng) {
            l.marks.add('sale:${l.age}:${a.id}:$level');
            if (rng.nextInt(100) >= odds) {
              return 'Viewings, a few nosy neighbours, no offers. Try a lower price, or wait for a better market.';
            }
            final offer =
                (price * (0.94 + rng.nextDouble() * 0.08) / 1000).round() *
                1000;
            l.sceneQueue.insert(0, 'sale_offer:${a.id}:$offer');
            return 'A buyer wants to make an offer.';
          },
        );
      }

      final owed = a.info['let'] == true
          ? letDebtShare(l, a)
          : (l.debts['Mortgage'] ?? 0);
      final haunted = List<String>.from(a.info['traits'] ?? const [])
          .contains('haunted');
      return _scene(
        id,
        'You put your ${a.name.toLowerCase()} in ${a.info['area'] ?? l.city} on the market. It is valued at ${_m(a.value)} in a ${l.economy.toLowerCase()} market; condition ${a.condition}%.${owed > 0 ? ' ${_m(owed)} of mortgage is paid off from the sale.' : ''}${haunted ? ' Buyers have heard the ghost stories.' : ''} The agent takes 3%.',
        [
          ask('quick', 'Quick sale, 8% under value', 0.92),
          ask('market', 'Ask the valuation', 1),
          ask('high', 'Ask 10% over', 1.1),
          Choice(label: 'Keep it', outcome: 'You took the sign down.'),
        ],
      );
    case 'sale_offer':
      final a = _asset(l, args);
      final offer = args.length > 1 ? int.tryParse(args[1]) : null;
      if (a == null || offer == null) return null;
      final counter = (offer * 1.04 / 1000).round() * 1000;
      return _scene(
        id,
        'A buyer offers ${_m(offer)} for your ${a.name.toLowerCase()} (valued at ${_m(a.value)}). The agent says they seem serious.',
        [
          Choice(
            label: 'Accept ${_m(offer)}',
            outcome: '',
            run: (l, rng) => completeSale(l, a, offer),
          ),
          Choice(
            label: 'Counter at ${_m(counter)}',
            outcome: '',
            risk: 'They may walk away',
            run: (l, rng) {
              if (rng.nextInt(100) < 55) return completeSale(l, a, counter);
              return 'The buyer thanked you for your time and bought the house next door instead.';
            },
          ),
          Choice(label: 'Decline', outcome: 'You decided not to sell.'),
        ],
      );
    case 'haunting':
      final a = _asset(l, args);
      if (a == null) return null;
      return _scene(
        id,
        'Doors in your ${a.name.toLowerCase()} close on their own at 3am. Something taps on the bedroom wall in threes. The old neighbours were not joking.',
        [
          Choice(
            label: 'Hire a medium (\$800)',
            outcome: '',
            risk: 'Might settle it for good',
            needsMoney: 800,
            run: (l, rng) {
              l.money -= 800;
              if (rng.nextBool()) {
                (a.info['traits'] as List).remove('haunted');
                return 'The medium lit candles, spoke to "Edith", and left. The house has been quiet ever since.';
              }
              return 'The medium got as far as the landing, went pale and left without charging the second half. It is still haunted.';
            },
          ),
          Choice(
            label: 'Make friends with it',
            outcome: '',
            run: (l, rng) {
              a.info['ghost'] = 'friendly';
              l.stats.add('happiness', 2);
              return 'You started saying goodnight to the ghost. The tapping became gentler. You call it Gerald.';
            },
          ),
          Choice(
            label: 'Charge for ghost tours',
            outcome: '',
            risk: 'Money, and the neighbours will talk',
            run: (l, rng) {
              final take = 1500 + rng.nextInt(26) * 100;
              l.money += take;
              l.stats.add('karma', -1);
              return 'Ghost hunters paid ${_m(take)} to sit in your kitchen with torches. Gerald did not show up, but a cupboard door did swing open on cue.';
            },
          ),
        ],
      );
    case 'gift_home':
      final a = _asset(l, args);
      if (a == null) return null;
      final people = giftable(l);
      return _scene(
        id,
        'Who should get your ${a.name.toLowerCase()} in ${a.info['area'] ?? l.city}, worth about ${_m(a.value)}? A gift like this is never forgotten.',
        [
          for (final p in people)
            Choice(
              label: '${p.name} (${p.role.toLowerCase()})',
              outcome: '',
              run: (l, rng) {
                l.assets.remove(a);
                if (a.info['let'] != true) l.flags.remove('owns_house');
                p.addBond(25);
                p.remember(
                  NpcMemory(
                    age: l.age,
                    text: 'You gave them your ${a.name.toLowerCase()}.',
                    valence: 1,
                    intensity: 5,
                    tags: ['gift', 'home'],
                  ),
                );
                l.stats.add('karma', 3);
                l.stats.add('happiness', 4);
                return 'You handed ${p.name.split(' ').first} the keys. They cried, then asked where the fuse box is.';
              },
            ),
          Choice(label: 'Not yet', outcome: 'You kept the keys for now.'),
        ],
      );
    case 'commercial':
      final units = commercialUnits(l)
          .where((u) => !l.marks.contains('unit:${l.age}:${u.i}'))
          .toList();
      return _scene(
        id,
        units.isEmpty
            ? 'Nothing else is for sale this year.'
            : 'Commercial property in ${l.city}: shops, offices and warehouses let to businesses. Higher rent than homes and longer leases, but empty units hurt in a recession. Banks lend up to 65%.',
        [
          for (final u in units)
            Choice(
              label: '${u.name} · ${u.area} · ${_m(u.price)}',
              outcome: '',
              risk:
                  'Rent about ${_m((u.price * commercialYield / 100).round() * 100)} a year · ${u.blurb}',
              lock: (l) => commercialLock(l, u.price),
              run: (l, rng) => buyCommercial(l, u),
            ),
          Choice(label: 'Not now', outcome: 'You closed the brochure.'),
        ],
      );
    case 'auction':
      final lots = auctionLots(l).where((x) => !_lotGone(l, x.i)).toList();
      if (lots.isEmpty) {
        return _scene(id, 'Every lot this year has gone under the hammer.', [
          Choice(
            label: 'Next year, then',
            outcome: 'You put the catalogue away.',
          ),
        ]);
      }
      return _scene(
        id,
        'The auction catalogue for ${l.city}: ${lots.length} lot${lots.length == 1 ? '' : 's'}, sold as seen. No surveys, no mortgages, no going back once the hammer falls. ${homeOf(l) != null ? 'Anything you win becomes a rental.' : 'Anything you win becomes your home.'}',
        [
          for (final x in lots)
            Choice(
              label: 'Lot ${x.i + 1}: ${x.type} · ${x.area}',
              outcome: '',
              risk:
                  'Guide ${_m(x.guide)} · ${x.why} · looks ${conditionBand(x.looks).toLowerCase()}',
              run: (l, rng) {
                l.sceneQueue.insert(0, 'auction_lot:${x.i}');
                return 'You find a seat near the back with your paddle.';
              },
            ),
          Choice(
            label: 'Just watching',
            outcome:
                'You watched a stranger buy a bungalow for the price of a car.',
          ),
        ],
      );
    case 'auction_lot':
      final i = int.tryParse(args.firstOrNull ?? '') ?? -1;
      final lot = auctionLots(l).where((x) => x.i == i).firstOrNull;
      if (lot == null || _lotGone(l, i)) return null;
      Choice bid(String label, double f, int odds) {
        final price = (lot.guide * f / 1000).round() * 1000;
        return Choice(
          label: '$label (${_m(price)})',
          outcome: '',
          risk: '$odds% chance you win · ${_m(lotCash(price))} with fees',
          lock: (l) => auctionLock(l, price),
          run: (l, rng) {
            if (rng.nextInt(100) >= odds) {
              l.marks.add('lot:${l.age}:${lot.i}');
              return 'A developer in the front row kept bidding. Lot ${lot.i + 1} went to them for ${_m((price * 1.08 / 1000).round() * 1000)}.';
            }
            return _winLot(l, lot, price);
          },
        );
      }

      final known = lot.traits
          .where((t) => homeTraits[t]!.$2 >= 0 && t != 'cellar')
          .map((t) => homeTraits[t]!.$1)
          .toList();
      return _scene(
        id,
        'Lot ${lot.i + 1}: ${lot.type.toLowerCase()} in ${lot.area}, ${lot.beds} bed${lot.garden ? ' with a garden' : ''}. ${lot.why}. From the photos it looks ${conditionBand(lot.looks).toLowerCase()}${known.isEmpty ? '' : ', and the catalogue mentions ${known.join(', ')}'}. Guide price ${_m(lot.guide)}; similar homes in good order sell for far more. Nobody gets to look inside first.',
        [
          bid('Bid the guide price', 1, 40),
          bid('Bid 10% over guide', 1.1, 70),
          bid('Bid 20% over guide', 1.2, 92),
          Choice(
            label: 'Let it go',
            outcome: 'You kept your paddle in your lap.',
          ),
        ],
      );
  }
  return null;
}

// ---------------- Scenes this file and the property files own ----------------

/// Every scene that belongs to property, so the game can keep wearing
/// Sunset Strip while one is on screen.
const propertySceneIds = {
  'hunt_purpose',
  'old_home',
  'let_pick',
  'let_trouble',
  'let_list',
  'let_manage',
  'remortgage',
  'landlord_rise',
  'landlord_sells',
  'house_hunt',
  'house_view',
  'bidding',
  'flat_hunt',
  'auction',
  'auction_lot',
  'sell_home',
  'sale_offer',
  'haunting',
  'gift_home',
  'commercial',
  'home_upgrade',
  'disaster',
};

// ---------------- Selling ----------------

/// Chance (out of 100) that a buyer makes an offer at this price level.
int saleOdds(Life l, Asset a, String level) {
  var odds = switch (level) {
    'quick' => 95,
    'high' => switch (l.economy) {
      'Boom' => 65,
      'Normal' => 35,
      'Slowdown' => 25,
      'Recession' => 15,
      _ => 8,
    },
    _ => switch (l.economy) {
      'Boom' => 92,
      'Normal' => 78,
      'Slowdown' => 62,
      'Recession' => 45,
      _ => 30,
    },
  };
  if (a.condition < 50) odds -= 15;
  if (List<String>.from(a.info['traits'] ?? const []).contains('haunted')) {
    odds -= 20;
  }
  return odds.clamp(5, 98);
}

String completeSale(Life l, Asset a, int price) {
  a.value = price;
  final r = sellAsset(l, a);
  return '${r.text} ${r.notes.join('. ')}.';
}

// ---------------- Giving a home away ----------------

/// Grown-up family who could be given a home: children, partner, siblings.
List<Npc> giftable(Life l) => [
  ...childrenOf(l).where((c) => c.alive && c.ageIn(l.year) >= 18),
  ?partnerOf(l),
  ...l.npcs.where(
    (n) =>
        n.alive &&
        (n.role == 'Sister' || n.role == 'Brother') &&
        n.ageIn(l.year) >= 18,
  ),
];

String? giftLock(Life l, Asset a) {
  if (giftable(l).isEmpty) return 'No grown-up family to give it to';
  final owed = a.info['let'] == true
      ? letDebtShare(l, a)
      : (l.debts['Mortgage'] ?? 0);
  if (owed > 0) return 'Pay off its mortgage first';
  return null;
}

// ---------------- The letting company ----------------

const lettingCompanyCost = 25000;

String? companyLock(Life l) {
  if (l.flags.containsKey('letting_co')) return 'You run one already';
  if (lettingsOf(l).length < 5) return 'Needs 5 rentals';
  if (l.money < lettingCompanyCost) return 'Needs ${_m(lettingCompanyCost)}';
  return null;
}

ActionResult startLettingCompany(Life l) {
  l.money -= lettingCompanyCost;
  l.flags['letting_co'] = Memory(l.age, 'starting a letting company');
  return ActionResult(
    'You set up ${l.surname} Lettings Ltd: an office above a bakery, a part-time manager and a logo you designed yourself.',
    [
      'Money −${_m(lettingCompanyCost)}',
      'Rentals allowed: $maxLets → $companyLets',
    ],
  );
}

// ---------------- Bulk actions for landlords ----------------

/// Empty long lets (not holiday lets).
List<Asset> emptyLets(Life l) =>
    lettingsOf(l).where((a) => isVacant(a) && !isHoliday(a)).toList();

/// Gives every empty rental to a letting agent, who moves a tenant in.
ActionResult fillEmptyLets(Life l) {
  final empty = emptyLets(l);
  for (final a in empty) {
    a.info['agent'] = true;
    a.info['tenant'] = agentPick(l, a);
    l.marks.remove('void:${l.age}:${a.id}');
  }
  return ActionResult(
    'Your letting agent filled ${empty.length == 1 ? 'your empty home' : 'all ${empty.length} empty homes'} by the end of the week.',
    ['Agent fee: 12% of rent on ${empty.length == 1 ? 'it' : 'each'}'],
  );
}

/// Rentals below 80% condition, and what fixing them all costs.
List<Asset> worn(Life l) =>
    lettingsOf(l).where((a) => a.condition < 80).toList();
int repairAllCost(Life l) => worn(l).fold(0, (s, a) => s + repairCost(a));

ActionResult repairAll(Life l) {
  final list = worn(l);
  final cost = repairAllCost(l);
  l.money -= cost;
  for (final a in list) {
    a.condition = 95;
  }
  return ActionResult(
    'One builder, ${list.length} addresses and a van full of plasterboard.',
    ['Money −${_m(cost)}', '${list.length} rentals now 95%'],
  );
}

// ---------------- Commercial property ----------------

/// Rent from a commercial unit, as a percentage of its value a year.
const commercialYield = 7.5;

typedef Unit = ({int i, String name, String area, int price, String blurb});

const _units = [
  ('Shop unit', 0.9, 'Busy high street, flat above'),
  ('Office floor', 1.4, 'Open plan, lift, no character'),
  ('Small warehouse', 1.1, 'Loading bay and a leaky skylight'),
  ('Restaurant site', 1.2, 'Kitchen already fitted'),
];

/// This year's three commercial units for sale.
List<Unit> commercialUnits(Life l) {
  final rng = Random(l.seed * 41 + l.age * 23 + 11);
  final kinds = List.of(_units)..shuffle(rng);
  return [
    for (var i = 0; i < 3; i++)
      () {
        final (name, f, blurb) = kinds[i];
        final area = areas.keys.elementAt(rng.nextInt(areas.length));
        final price =
            (260000 *
                    countryProfile(l.country).cost *
                    f *
                    areas[area]!.$1 *
                    (_econ[l.economy] ?? 1) *
                    (0.9 + rng.nextDouble() * 0.2) /
                    1000)
                .round() *
            1000;
        return (i: i, name: name, area: area, price: price, blurb: blurb);
      }(),
  ];
}

String? commercialLock(Life l, int price) {
  if (lettingsOf(l).length >= lettingCap(l)) {
    return 'You own ${lettingCap(l)} rentals already';
  }
  if (l.money >= (price * 1.03).round()) return null;
  if (l.money < (price * 0.38).round()) {
    return 'Needs ${_m((price * 0.38).round())} (35% deposit + fees)';
  }
  if (loansBlocked(l)) return 'No loans for 7 years after bankruptcy';
  if (creditOf(l) < 640) {
    return 'Needs Good credit (640+) for a commercial loan';
  }
  if (l.salary <= 0 && l.business == null && lettingsOf(l).isEmpty) {
    return 'A commercial loan needs an income';
  }
  return null;
}

String buyCommercial(Life l, Unit u) {
  l.marks.add('unit:${l.age}:${u.i}');
  final fees = (u.price * 0.03).round();
  final cash = l.money >= u.price + fees;
  final deposit = cash ? u.price : (u.price * 0.35).round();
  final loan = u.price - deposit;
  l.money -= deposit + fees;
  if (loan > 0) {
    l.credit ??= 640;
    l.debts['Buy-to-let mortgage'] =
        (l.debts['Buy-to-let mortgage'] ?? 0) + loan;
    l.rates['Buy-to-let mortgage'] = max(
      l.rates['Buy-to-let mortgage'] ?? 0,
      mortgageRate(l) + 0.02,
    );
  }
  l.assets.add(
    Asset(
      id: 'unit${l.age}_${u.i}',
      kind: 'house',
      name: u.name,
      value: u.price,
      yearlyCost: ((u.price * 0.01) / 100).round() * 100,
      since: l.age,
      condition: 70 + Random(l.seed + u.i).nextInt(25),
      info: {
        'area': u.area,
        'let': true,
        'commercial': true,
        'tenant': null,
        'loan': loan,
        'rentLevel': 'market',
      },
    ),
  );
  return 'You bought the ${u.name.toLowerCase()} in ${u.area} for ${_m(u.price)}${cash ? ' in cash' : ', with a ${_m(loan)} commercial loan'}. Fees ${_m(fees)}. It is empty: find a business to rent it from Wealth › Real estate.';
}

// ---------------- Life in your own home ----------------

final realtyActions = <GameAction>[
  GameAction(
    id: 'property_auction',
    label: 'Property auction',
    category: 'Assets',
    priceNote: 'Three tired homes, well under value · cash only',
    keywords: [
      'auction',
      'property',
      'flip',
      'fixer',
      'investment',
      'house',
      'real estate',
    ],
    minAge: 21,
    repeatable: true,
    extraCheck: (l) =>
        l.marks.contains('undocumented') ? 'Auction houses need papers' : null,
    run: (l, rng) {
      l.sceneQueue.add('auction');
      return ActionResult('You pick up this year\'s auction catalogue.');
    },
  ),
  GameAction(
    id: 'housewarming',
    label: 'Throw a housewarming',
    category: 'Assets',
    priceNote: 'About \$300 for food and drink',
    keywords: ['party', 'housewarming', 'home', 'neighbours', 'friends'],
    minAge: 18,
    cost: 300,
    extraCheck: (l) => homeOf(l) == null
        ? 'Needs a home you own'
        : homeOf(l)!.info['warmed'] == true
        ? 'You already warmed this home'
        : null,
    run: (l, rng) {
      final home = homeOf(l)!;
      home.info['warmed'] = true;
      l.money -= 300;
      l.reason = 'A housewarming party';
      l.stats.add('happiness', 6);
      final n = meetFriend(l, rng, role: 'Neighbour', bond: 55, spread: 10);
      return ActionResult(
        'Friends squeezed into your new ${home.name.toLowerCase()}, someone broke a glass, and ${n.name.split(' ').first} from next door brought a plant and stayed till midnight.',
        ['Money −\$300', 'Happiness +6', 'New neighbour: ${n.name}'],
      );
    },
  ),
  GameAction(
    id: 'diy',
    label: 'Do some DIY',
    category: 'Assets',
    priceNote: 'Free · fixes a little, unless it goes wrong',
    keywords: ['diy', 'fix', 'repair', 'paint', 'shelves', 'home'],
    minAge: 18,
    extraCheck: (l) => homeOf(l) == null
        ? 'Needs a home you own'
        : homeOf(l)!.condition >= 95
        ? 'Nothing needs fixing'
        : null,
    run: (l, rng) {
      final home = homeOf(l)!;
      final handy = l.stats['smarts'] ~/ 20 + rng.nextInt(8);
      if (rng.nextInt(100) < 18) {
        l.reason = 'A DIY accident';
        l.stats.add('health', -3);
        home.condition = max(0, home.condition - 3);
        return ActionResult(
          'You drilled straight through a water pipe. The kitchen flooded and your thumb needed stitches.',
          ['Health −3', 'Condition −3%'],
        );
      }
      final gain = min(95 - home.condition, 4 + handy);
      home.condition += gain;
      l.stats.add('happiness', 2);
      return ActionResult(
        'A weekend of paint, sealant and swearing. The ${home.name.toLowerCase()} looks better for it.',
        ['Condition +$gain%', 'Happiness +2'],
      );
    },
  ),
  GameAction(
    id: 'tend_garden',
    label: 'Work in the garden',
    category: 'Assets',
    keywords: ['garden', 'grow', 'vegetables', 'flowers', 'outdoors', 'home'],
    minAge: 12,
    extraCheck: (l) =>
        homeOf(l)?.info['garden'] == true ? null : 'Needs a home with a garden',
    run: (l, rng) {
      l.reason = 'Time in the garden';
      l.stats.add('happiness', 3);
      l.stats.add('health', 2);
      if (rng.nextInt(100) < 15) {
        l.money += 150;
        return ActionResult(
          'Your marrow won second prize at the village show, and \$150 in vouchers.',
          ['Happiness +3', 'Health +2', 'Money +\$150'],
        );
      }
      return ActionResult(
        'Tomatoes, sweet peas and a robin that followed you around all afternoon.',
        ['Happiness +3', 'Health +2'],
      );
    },
  ),
];
