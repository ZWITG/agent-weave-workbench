import 'dart:math';

import 'actions.dart';
import 'finance.dart';
import 'models.dart';
import 'property.dart';
import 'storylet.dart';

/// Homes and vehicles (plan Module 7): listings with viewings and surveys
/// that reveal hidden traits, offers and bidding wars, mortgages priced by
/// your credit score, renting with a deposit, repairs and renovation,
/// buy-to-let with tenants, and a car dealership with auto loans.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

// ---------------- Listings ----------------

typedef HomeType = ({
  String name,
  int minBeds,
  int maxBeds,
  bool garden,
  double price,
  int poolChance,
});

const homeTypes = <HomeType>[
  (
    name: 'Flat',
    minBeds: 1,
    maxBeds: 2,
    garden: false,
    price: 0.55,
    poolChance: 0,
  ),
  (
    name: 'Terraced house',
    minBeds: 2,
    maxBeds: 3,
    garden: true,
    price: 0.8,
    poolChance: 0,
  ),
  (
    name: 'Semi-detached house',
    minBeds: 3,
    maxBeds: 3,
    garden: true,
    price: 1.0,
    poolChance: 5,
  ),
  (
    name: 'Detached house',
    minBeds: 3,
    maxBeds: 5,
    garden: true,
    price: 1.4,
    poolChance: 30,
  ),
  (
    name: 'Penthouse',
    minBeds: 2,
    maxBeds: 3,
    garden: false,
    price: 1.8,
    poolChance: 20,
  ),
  (
    name: 'Farmhouse',
    minBeds: 4,
    maxBeds: 5,
    garden: true,
    price: 1.3,
    poolChance: 10,
  ),
  (
    name: 'Houseboat',
    minBeds: 1,
    maxBeds: 1,
    garden: false,
    price: 0.45,
    poolChance: 0,
  ),
  (
    name: 'Mansion',
    minBeds: 6,
    maxBeds: 8,
    garden: true,
    price: 4.0,
    poolChance: 80,
  ),
];

const areas = <String, (double, String)>{
  'Old Town': (1.15, 'charming, noisy at night'),
  'Riverside': (1.25, 'lovely views, long commute'),
  'Northgate': (0.85, 'cheaper and up and coming'),
  'Harbour': (1.1, 'sea air and seagulls'),
  'Hillcrest': (1.3, 'leafy and quiet'),
  'Market Quarter': (0.95, 'close to everything'),
};

/// Hidden traits a viewing or survey can reveal: label, condition change,
/// yearly happiness while you live there.
const homeTraits = <String, (String, int, int)>{
  'damp': ('damp in the walls', -25, 0),
  'roof': ('a brand-new roof', 15, 0),
  'neighbours': ('lovely neighbours', 0, 2),
  'road': ('a noisy main road', 0, -1),
  'subsidence': ('cracks from subsidence', -15, 0),
  'haunted': ('a local "haunted house" rumour', 0, 0),
  'cellar': ('a sealed cellar nobody mentioned', 0, 0),
};

const _econPrice = {
  'Boom': 1.08,
  'Normal': 1.0,
  'Slowdown': 0.98,
  'Recession': 0.92,
  'Crash': 0.85,
};

typedef Listing = ({
  int i,
  String type,
  int beds,
  bool garden,
  bool pool,
  String area,
  int price,
  int condition,
  int shown,
  List<String> traits,
  int upkeep,
});

String conditionBand(int c) => c >= 80
    ? 'Good'
    : c >= 55
    ? 'Fair'
    : 'Needs work';

/// This year's homes for sale: the same six every time you look this year.
List<Listing> listings(Life l) {
  final rng = Random(l.seed * 13 + l.age * 37 + 5);
  final out = <Listing>[];
  for (var i = 0; i < 6; i++) {
    var t = homeTypes[rng.nextInt(homeTypes.length - 1)];
    if (i == 5 && rng.nextInt(100) < 15) t = homeTypes.last;
    final area = areas.keys.elementAt(rng.nextInt(areas.length));
    final traits = <String>[
      for (final k in homeTraits.keys)
        if (rng.nextInt(100) < 18) k,
    ];
    var cond = 50 + rng.nextInt(46);
    for (final k in traits) {
      cond += homeTraits[k]!.$2;
    }
    cond = cond.clamp(15, 100);
    final shown = 50 + rng.nextInt(46);
    final pool = rng.nextInt(100) < t.poolChance;
    final price =
        (200000 *
                t.price *
                areas[area]!.$1 *
                (0.75 + shown / 400) *
                (_econPrice[l.economy] ?? 1) /
                1000)
            .round() *
        1000;
    out.add((
      i: i,
      type: t.name,
      beds: t.minBeds + rng.nextInt(t.maxBeds - t.minBeds + 1),
      garden: t.garden,
      pool: pool,
      area: area,
      price: price,
      condition: cond,
      shown: shown,
      traits: traits,
      upkeep: ((price * 0.012 + (pool ? 1500 : 0)) / 100).round() * 100,
    ));
  }
  return out;
}

String _features(Listing h) =>
    ['${h.beds} bed', if (h.garden) 'garden', if (h.pool) 'pool'].join(' · ');

bool _surveyed(Life l, int i) => l.marks.contains('survey:${l.age}:$i');

List<String> _known(Life l, Listing h) => _surveyed(l, h.i)
    ? h.traits
    : [
        for (final t in h.traits)
          if (l.marks.contains('trait:${l.age}:${h.i}:$t')) t,
      ];

/// The main home you live in (not a buy-to-let).
Asset? homeOf(Life l) => l.assets
    .where((a) => a.kind == 'house' && a.info['let'] != true)
    .firstOrNull;
Asset? lettingOf(Life l) => l.assets
    .where((a) => a.kind == 'house' && a.info['let'] == true)
    .firstOrNull;

double mortgageRate(Life l) => 0.035 + (850 - creditOf(l)) / 550 * 0.04;

/// Why you can't buy this listing, or null. Cash buyers need the price
/// plus 2% fees; mortgage buyers need a deposit, an income and credit.
String? buyLock(Life l, int price) {
  if (l.money >= (price * 1.02).round()) return null;
  final deposit = (price * 0.12).round();
  if (l.money < deposit) return 'Needs ${_m(deposit)} (10% deposit + fees)';
  if (l.salary <= 0 && l.pension <= 0 && l.business == null) {
    return 'A mortgage needs an income';
  }
  if (loansBlocked(l)) return 'No mortgage for 7 years after bankruptcy';
  if (creditOf(l) < 580) return 'Needs Fair credit (580+) for a mortgage';
  if (homeOf(l) != null &&
      !l.marks.contains('hunt:${l.age}:move') &&
      lettingsOf(l).length >= maxLets) {
    return 'You own $maxLets rentals already';
  }
  return null;
}

/// This rental's part of the buy-to-let mortgage (shared by all lets in
/// proportion to what each one borrowed).
int letDebtShare(Life l, Asset a) {
  final debt = l.debts['Buy-to-let mortgage'] ?? 0;
  if (debt == 0) return 0;
  final lets = lettingsOf(l);
  final total = lets.fold<int>(
    0,
    (s, x) => s + ((x.info['loan'] as int?) ?? 0),
  );
  if (total == 0) return lets.length <= 1 ? debt : 0;
  return (debt * ((a.info['loan'] as int?) ?? 0) / total).round();
}

String buyListing(Life l, Listing h, int price) {
  final moving = homeOf(l) != null && l.marks.contains('hunt:${l.age}:move');
  final asLet = homeOf(l) != null && !moving;
  // Moving: the old home's mortgage becomes a buy-to-let loan until you
  // decide to sell it or let it out.
  final old = moving ? homeOf(l) : null;
  if (old != null) {
    final owed = l.debts.remove('Mortgage') ?? 0;
    final rate = l.rates.remove('Mortgage') ?? mortgageRate(l);
    old.info['let'] = true;
    old.info['tenant'] = null;
    old.info['loan'] = owed;
    if (owed > 0) {
      l.debts['Buy-to-let mortgage'] =
          (l.debts['Buy-to-let mortgage'] ?? 0) + owed;
      l.rates['Buy-to-let mortgage'] = rate + 0.01;
    }
    l.sceneQueue.insert(0, 'old_home:${old.id}');
  }
  final fees = (price * 0.02).round();
  final cash = l.money >= price + fees;
  final deposit = cash
      ? price
      : (price * (l.money >= price * 0.32 ? 0.2 : 0.1)).round();
  final loan = price - deposit;
  l.money -= deposit + fees;
  if (!asLet) {
    l.assets.removeWhere((a) => a.kind == 'rental');
    l.flags.remove('own_flat');
    l.flags['owns_house'] = Memory(l.age, 'buying your first home');
  }
  final rate = mortgageRate(l);
  final debt = asLet ? 'Buy-to-let mortgage' : 'Mortgage';
  if (loan > 0) {
    l.credit ??= 640;
    l.debts[debt] = (l.debts[debt] ?? 0) + loan;
    l.rates[debt] = asLet ? rate + 0.01 : rate;
  }
  var find = '';
  if (h.traits.contains('cellar')) {
    final bonus = 3000 + Random(l.seed + l.age).nextInt(6) * 1000;
    l.money += bonus;
    find =
        ' Behind the sealed cellar door: a crate of old coins, worth ${_m(bonus)}.';
  }
  l.assets.add(
    Asset(
      id: 'home${l.age}_${h.i}',
      kind: 'house',
      name: h.type,
      value: price,
      yearlyCost: h.upkeep,
      since: l.age,
      condition: h.condition,
      info: {
        'beds': h.beds,
        'garden': h.garden,
        'pool': h.pool,
        'area': h.area,
        'traits': h.traits,
        if (asLet) ...{
          'let': true,
          'tenant': null,
          'loan': loan,
          'rentLevel': 'market',
        },
      },
    ),
  );
  if (asLet) l.sceneQueue.insert(0, 'let_pick:${l.assets.last.id}');
  l.stats.add('happiness', asLet ? 3 : 8);
  return '${asLet ? 'You bought a ${h.type.toLowerCase()} in ${h.area} to let out.' : 'You got the keys to a ${h.type.toLowerCase()} in ${h.area}.'} ${cash ? 'You paid ${_m(price)} in cash.' : 'You put down ${_m(deposit)} and took a ${_m(loan)} ${debt.toLowerCase()} at ${(l.rates[debt]! * 100).toStringAsFixed(1)}% over 25 years.'} Fees: ${_m(fees)}.$find${asLet ? ' Tenants will pay about ${_m(rentFor(l.assets.last))} a year.' : ''}';
}

/// Yearly rent from tenants: about 5% of the home's value.
int rentFor(Asset a) =>
    ((a.value *
                0.05 *
                (a.condition < 40 ? 0.7 : 1) *
                rentLevels[rentLevelOf(a)]!.$2) /
            100)
        .round() *
    100;

int repairCost(Asset a) =>
    max(500, ((95 - a.condition) * a.value * 0.0006).round());

ActionResult repairHome(Life l, Asset a) {
  final cost = repairCost(a);
  l.money -= cost;
  final before = a.condition;
  a.condition = 95;
  return ActionResult(
    'Builders fixed everything on the list. Mostly on time.',
    ['Money −${_m(cost)}', 'Condition $before% → 95%'],
  );
}

const _renoGain = {
  'Boom': 0.18,
  'Normal': 0.14,
  'Slowdown': 0.12,
  'Recession': 0.08,
  'Crash': 0.06,
};

int renovationCost(Asset a) => (a.value * 0.1).round();

String? renovateLock(Life l, Asset a) {
  final last = a.info['renovated'] as int?;
  if (last != null && l.age - last < 5) {
    return 'Renovated ${l.age - last} years ago';
  }
  if (l.money < renovationCost(a)) return 'Needs ${_m(renovationCost(a))}';
  return null;
}

ActionResult renovateHome(Life l, Asset a) {
  final cost = renovationCost(a);
  final gain = (a.value * (_renoGain[l.economy] ?? 0.12)).round();
  l.money -= cost;
  a.value += gain;
  a.condition = 100;
  a.info['renovated'] = l.age;
  return ActionResult(
    'New kitchen, new bathroom, and you can finally open the back door without kicking it.',
    [
      'Money −${_m(cost)}',
      'Value +${_m(gain)} (${l.economy.toLowerCase()} market)',
      'Condition 100%',
    ],
  );
}

/// Each birthday: life in your home and tenants in your rental.
List<String> homeYear(Life l, Random rng) {
  final feed = <String>[];
  final home = homeOf(l);
  if (home != null) {
    for (final t in List<String>.from(home.info['traits'] ?? const [])) {
      final h = homeTraits[t]?.$3 ?? 0;
      if (h != 0) {
        l.reason = h > 0 ? 'Lovely neighbours' : 'A noisy road';
        l.stats.add('happiness', h);
      }
    }
    if (home.condition < 30) {
      l.reason = 'Damp and mould at home';
      l.stats.add('health', -2);
      home.value = (home.value * 0.97).round();
      feed.add(
        'Your home is falling apart (condition ${home.condition}%). The damp is getting into your chest. Repairs would fix it.',
      );
    }
  }
  feed.addAll(propertyYear(l, rng));
  return feed;
}

// ---------------- Scenes: house hunting ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'money',
  scene: true,
  choices: choices,
);

/// Offer acceptance by how far from the asking price and the economy.
int offerOdds(String economy, double vsAsking) {
  if (vsAsking < 1) {
    return switch (economy) {
      'Boom' => 15,
      'Normal' => 35,
      'Slowdown' => 50,
      'Recession' => 65,
      _ => 75,
    };
  }
  if (vsAsking == 1) {
    return switch (economy) {
      'Boom' => 55,
      'Normal' => 80,
      _ => 90,
    };
  }
  return economy == 'Boom' ? 85 : 97;
}

Storylet? homeScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'house_hunt':
      final list = listings(l);
      final letting =
          homeOf(l) != null && !l.marks.contains('hunt:${l.age}:move');
      return _scene(
        id,
        '${letting ? 'You are looking for a second home to let out.' : 'You spend a Saturday scrolling listings.'} Six homes are for sale in ${l.city} this year, in a ${l.economy.toLowerCase()} market. Each listing shows what the seller wants you to see; a viewing or a survey shows the rest.',
        [
          for (final h in list)
            Choice(
              label: '${h.type} · ${h.area} · ${_m(h.price)}',
              outcome: '',
              risk:
                  '${_features(h)} · looks ${conditionBand(h.shown).toLowerCase()} · ${_m(h.upkeep)}/yr',
              run: (l, rng) {
                l.sceneQueue.add('house_view:${h.i}');
                return 'You booked an appointment to look at the ${h.type.toLowerCase()}.';
              },
            ),
          Choice(label: 'Not this year', outcome: 'Nothing felt like home.'),
        ],
      );
    case 'house_view':
      final h = listings(l)[int.tryParse(args.first) ?? 0];
      final known = _known(l, h);
      final surveyed = _surveyed(l, h.i);
      final viewed = l.marks.contains('view:${l.age}:${h.i}');
      final lock = buyLock(l, h.price);
      Choice offer(String label, double f) {
        final price = (h.price * f / 1000).round() * 1000;
        final odds = offerOdds(l.economy, f);
        return Choice(
          label: '$label (${_m(price)})',
          outcome: '',
          risk: '$odds% chance they accept',
          lock: (l) => buyLock(l, price),
          run: (l, rng) {
            if (rng.nextInt(100) >= odds) {
              return 'The seller turned down ${_m(price)}. In a ${l.economy.toLowerCase()} market, they can afford to wait.';
            }
            if (f <= 1 &&
                (l.economy == 'Boom' || l.economy == 'Normal') &&
                rng.nextInt(100) < 25) {
              l.sceneQueue.add('bidding:${h.i}:$price');
              return 'The agent calls back: another buyer has offered more. It is a bidding war.';
            }
            return buyListing(l, h, price);
          },
        );
      }

      return _scene(
        id,
        '${h.type} in ${h.area} (${areas[h.area]!.$2}). ${_features(h)}. Asking ${_m(h.price)}; running costs about ${_m(h.upkeep)} a year. Condition: ${surveyed ? '${h.condition}% (surveyed)' : '${conditionBand(h.shown)} (from the photos)'}. ${known.isEmpty ? (surveyed ? 'The survey found nothing worrying.' : 'You only know what the listing says.') : 'You know about: ${known.map((t) => homeTraits[t]!.$1).join(', ')}.'}${lock != null ? ' $lock.' : ''}',
        [
          if (!viewed && !surveyed)
            Choice(
              label: 'Go to a viewing (free)',
              outcome: '',
              risk: 'May reveal one hidden thing',
              run: (l, rng) {
                l.marks.add('view:${l.age}:${h.i}');
                final hidden = h.traits
                    .where((t) => !known.contains(t))
                    .toList();
                l.sceneQueue.add('house_view:${h.i}');
                if (hidden.isEmpty) {
                  return 'It looked just like the photos. The agent called the kitchen "a blank canvas".';
                }
                final t = hidden[rng.nextInt(hidden.length)];
                l.marks.add('trait:${l.age}:${h.i}:$t');
                return 'At the viewing you noticed ${homeTraits[t]!.$1}.';
              },
            ),
          if (!surveyed)
            Choice(
              label: 'Pay for a survey (\$400)',
              outcome: '',
              risk: 'Reveals everything',
              needsMoney: 400,
              run: (l, rng) {
                l.money -= 400;
                l.marks.add('survey:${l.age}:${h.i}');
                l.sceneQueue.add('house_view:${h.i}');
                return h.traits.isEmpty
                    ? 'The surveyor found nothing worrying. Condition ${h.condition}%.'
                    : 'The surveyor\'s report: ${h.traits.map((t) => homeTraits[t]!.$1).join(', ')}. Real condition ${h.condition}%.';
              },
            ),
          offer('Offer 8% below asking', 0.92),
          offer('Offer the asking price', 1),
          offer('Offer 5% above asking', 1.05),
          Choice(
            label: 'Walk away',
            outcome: 'You walked away. There will be other homes.',
          ),
        ],
      );
    case 'bidding':
      if (args.length < 2) return null;
      final h = listings(l)[int.tryParse(args[0]) ?? 0];
      final offered = int.tryParse(args[1]) ?? h.price;
      Choice raise(String label, double f, int odds) {
        final price = (offered * f / 1000).round() * 1000;
        return Choice(
          label: '$label (${_m(price)})',
          outcome: '',
          risk: '$odds% chance you win',
          lock: (l) => buyLock(l, price),
          run: (l, rng) => rng.nextInt(100) < odds
              ? buyListing(l, h, price)
              : 'The other buyer went higher still. The ${h.type.toLowerCase()} is theirs.',
        );
      }

      return _scene(
        id,
        'Another buyer wants the ${h.type.toLowerCase()} in ${h.area} too. The agent says, "Best and final offers by Friday."',
        [
          raise('Raise by 5%', 1.05, 70),
          raise('Raise by 10%', 1.10, 95),
          Choice(
            label: 'Walk away',
            outcome: 'You let it go. The next one will be the one.',
          ),
        ],
      );
    case 'flat_hunt':
      final renting = l.has('rental');
      return _scene(
        id,
        'Six places to rent in ${l.city} this year. Landlords ask for two months\' rent as a deposit${renting ? '; yours comes back when you move out, if they are fair' : ''}.',
        [
          for (final f in rentalListings(l))
            Choice(
              label: '${f.name} · ${f.area} · ${_m(f.rent)} a year',
              outcome: '',
              risk: '${f.blurb} · deposit ${_m((f.rent / 6).round())}',
              needsMoney: (f.rent / 6).round(),
              run: (l, rng) => rentFlat(l, f, rng),
            ),
          Choice(
            label: renting ? 'Stay where you are' : 'Stay at home',
            outcome: renting
                ? 'Better the devil you know.'
                : 'Home sweet (family) home.',
          ),
        ],
      );
    case 'car_dealer':
      return _scene(
        id,
        'The salesperson at Northgate Motors has a firm handshake and a tie with tiny cars on it. "What are we driving home today?"',
        [
          for (final c in cars)
            if (l.year >= c.since)
              Choice(
                label: '${c.name} · ${_m(c.price)}',
                outcome: '',
                risk: c.blurb,
                run: (l, rng) {
                  l.sceneQueue.add('car_pay:${c.id}');
                  return 'You took the ${c.name.toLowerCase()} for a test drive.';
                },
              ),
          Choice(
            label: 'Just looking',
            outcome: 'You escaped without buying anything.',
          ),
        ],
      );
    case 'car_pay':
      final c = cars.firstWhere(
        (c) => c.id == args.first,
        orElse: () => cars.first,
      );
      // A second argument is the discount won by haggling (0 = tried, no).
      final haggled = args.length > 1;
      final off = haggled ? int.tryParse(args[1]) ?? 0 : 0;
      final price = (c.price * (100 - off) / 100).round();
      final down = (price * 0.1).round();
      final rate = 0.05 + (850 - creditOf(l)) / 550 * 0.07;
      return _scene(
        id,
        'The ${c.name.toLowerCase()} costs ${_m(price)}${off > 0 ? ' after your haggling ($off% off)' : ''}. Running costs are about ${_m(c.upkeep)} a year. How do you want to pay?',
        [
          if (!haggled)
            Choice(
              label: 'Haggle for a better price',
              outcome: '',
              risk: 'Charisma helps · they may not budge',
              run: (l, rng) {
                final win = rng.nextInt(100) < 40 + l.stats['charisma'] ~/ 3;
                final got = win ? 5 + rng.nextInt(8) : 0;
                l.sceneQueue.insert(0, 'car_pay:${c.id}:$got');
                return win
                    ? 'You walked towards the door. The salesperson "spoke to the manager" and knocked $got% off.'
                    : 'The salesperson smiled. "That is already our best price." It was worth a try.';
              },
            ),
          Choice(
            label: 'Pay cash (${_m(price)})',
            outcome: '',
            needsMoney: price,
            run: (l, rng) {
              l.money -= price;
              return addCarModel(l, c, 'You paid in full.');
            },
          ),
          Choice(
            label: 'Auto loan: ${_m(down)} down',
            outcome: '',
            risk:
                'Rate ${(rate * 100).toStringAsFixed(1)}% · repossessed if you go bankrupt',
            needsMoney: down,
            lock: (l) => loansBlocked(l)
                ? 'No loans for 7 years after bankruptcy'
                : creditOf(l) < 560
                ? 'Credit too low (needs 560+)'
                : l.salary <= 0 && l.pension <= 0
                ? 'Needs an income'
                : null,
            run: (l, rng) {
              l.money -= down;
              l.credit ??= 640;
              l.debts['Auto loan'] = (l.debts['Auto loan'] ?? 0) + price - down;
              l.rates['Auto loan'] = rate;
              return addCarModel(
                l,
                c,
                'You put ${_m(down)} down; the rest is an auto loan at ${(rate * 100).toStringAsFixed(1)}%.',
              );
            },
          ),
          Choice(
            label: 'Walk away',
            outcome: 'You said you would "think about it".',
          ),
        ],
      );
  }
  return null;
}

// ---------------- Vehicles ----------------

typedef CarModel = ({
  String id,
  String name,
  int price,
  int upkeep,
  int dep,
  int since,
  String blurb,
});

const cars = <CarModel>[
  (
    id: 'used',
    name: 'Used hatchback',
    price: 4000,
    upkeep: 1200,
    dep: 15,
    since: 0,
    blurb: 'Dented but lovable · loses 15% a year',
  ),
  (
    id: 'family',
    name: 'Family car',
    price: 18000,
    upkeep: 1800,
    dep: 15,
    since: 0,
    blurb: 'Room for everyone · loses 15% a year',
  ),
  (
    id: 'electric',
    name: 'Electric car',
    price: 32000,
    upkeep: 900,
    dep: 12,
    since: 2012,
    blurb: 'Cheap to run · loses 12% a year',
  ),
  (
    id: 'sports',
    name: 'Sports car',
    price: 55000,
    upkeep: 3500,
    dep: 18,
    since: 0,
    blurb: 'Fast and loud · loses 18% a year',
  ),
  (
    id: 'classic',
    name: 'Classic car',
    price: 25000,
    upkeep: 2000,
    dep: -3,
    since: 0,
    blurb: 'Gains about 3% a year if you look after it',
  ),
];

String addCarModel(Life l, CarModel c, String how) {
  l.flags['owns_car'] = Memory(l.age, 'buying a ${c.name.toLowerCase()}');
  l.assets.add(
    Asset(
      id: 'car${l.age}_${c.id}',
      kind: 'car',
      name: c.name,
      value: c.price,
      yearlyCost: c.upkeep,
      since: l.age,
      condition: c.id == 'used' ? 70 : 100,
      info: {'dep': c.dep},
    ),
  );
  l.stats.add('happiness', c.price >= 30000 ? 5 : 3);
  return 'You drove the ${c.name.toLowerCase()} home with the windows down. $how';
}

/// Actions that open the home and car scenes.
final homeActions = <GameAction>[
  GameAction(
    id: 'buy_house',
    label: 'House hunting',
    category: 'Assets',
    priceNote: 'Six homes for sale this year · deposit from 10%',
    keywords: ['house', 'home', 'mortgage', 'buy', 'property', 'listing'],
    minAge: 21,
    extraCheck: (l) => l.prison != null ? 'Not possible in prison' : null,
    run: (l, rng) {
      l.sceneQueue.add(homeOf(l) != null ? 'hunt_purpose' : 'house_hunt');
      return ActionResult('You open the property listings.');
    },
  ),
  GameAction(
    id: 'rent_flat',
    label: 'Rent a place',
    category: 'Assets',
    priceNote: 'Six places, from a room in a shared house up',
    keywords: ['flat', 'apartment', 'rent', 'move out', 'home', 'move'],
    minAge: 18,
    extraCheck: (l) => homeOf(l) != null
        ? 'You own a home'
        : l.prison != null
        ? 'Not possible in prison'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('flat_hunt');
      return ActionResult('You look at flats to rent.');
    },
  ),
  GameAction(
    id: 'buy_car',
    label: 'Buy a car',
    category: 'Assets',
    priceNote: 'From \$4,000 · cash or an auto loan',
    keywords: ['car', 'buy', 'drive', 'vehicle', 'dealer'],
    minAge: 18,
    extraCheck: (l) => l.assets.where((a) => a.kind == 'car').length >= 2
        ? 'You already own two cars'
        : !l.flags.containsKey('licence')
        ? 'Needs a driving licence'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('car_dealer');
      return ActionResult('You visit the car dealership.');
    },
  ),
];
