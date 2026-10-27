import 'dart:math';

import 'actions.dart';
import 'homes.dart' show homeOf, lettingOf;
import 'models.dart';
import 'storylet.dart';

// Things you own beyond homes and cars: heirlooms that carry their owners'
// names down the generations, collectibles with yearly trends, rarity and
// fakes, boats and aircraft (with their licences), home upgrades that
// change daily life and how many guests you can host, and natural
// disasters that home insurance can soften.

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

/// A stable hash for names, so trends are the same on every device.
int _hash(String s) => s.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);

// ---------------- Heirlooms ----------------

typedef HeirloomItem = ({String id, String name, String about, int value});

const heirloomItems = <HeirloomItem>[
  (
    id: 'pocket_watch',
    name: 'Pocket watch',
    about: 'a silver pocket watch that still ticks',
    value: 1800,
  ),
  (
    id: 'ring',
    name: 'Family ring',
    about: 'a gold ring with a small, stubborn diamond',
    value: 3500,
  ),
  (
    id: 'quilt',
    name: 'Patchwork quilt',
    about: 'a quilt stitched from three generations of shirts',
    value: 400,
  ),
  (
    id: 'painting',
    name: 'Landscape painting',
    about: 'an oil painting of a valley nobody can name',
    value: 6000,
  ),
  (
    id: 'medal',
    name: 'Old medal',
    about: 'a medal in a velvet box, and the story that goes with it',
    value: 1200,
  ),
  (
    id: 'recipes',
    name: 'Recipe book',
    about: 'a handwritten recipe book, splattered and priceless',
    value: 150,
  ),
];

HeirloomItem? heirloomById(String id) =>
    heirloomItems.where((h) => h.id == id).firstOrNull;

List<String> heirloomHistory(Asset a) =>
    List<String>.from(a.info['history'] ?? const []);

int heirloomValue(Life l) =>
    l.assets.where((a) => a.kind == 'heirloom').fold(0, (s, a) => s + a.value);

Asset makeHeirloom(Life l, HeirloomItem h, List<String> history) => Asset(
  id: 'heirloom_${h.id}_${l.age}',
  kind: 'heirloom',
  name: h.name,
  value: h.value,
  yearlyCost: 0,
  since: l.age,
  info: {'item': h.id, 'about': h.about, 'history': history, 'dep': -2},
);

/// Some families keep something old; it reaches you as a young adult.
void maybeFamilyHeirloom(Life l, Random rng) {
  if (rng.nextInt(100) >= 30) return;
  final h = heirloomItems[rng.nextInt(heirloomItems.length)];
  l.marks.add('family_heirloom:${h.id}');
}

/// Heirlooms pass to the heir with one more owner in their story; they
/// stay out of the estate that is split and taxed.
List<Asset> passHeirlooms(Life old) => [
  for (final a in old.assets.where((a) => a.kind == 'heirloom'))
    Asset(
      id: a.id,
      kind: 'heirloom',
      name: a.name,
      value: a.value,
      yearlyCost: 0,
      since: 0,
      condition: a.condition,
      info: {
        ...a.info,
        'history': [
          ...heirloomHistory(a),
          '${old.fullName} (${old.birthYear}–${old.year})',
        ],
      },
    ),
];

/// Selling the family's history: the family takes it personally.
String sellHeirloomFallout(Life l, Asset a) {
  final family = l.npcs
      .where((n) => n.alive && (n.circle == 'Family' || n.circle == 'Children'))
      .toList();
  for (final n in family) {
    n.addFacets(affection: -5, resentment: 4);
    n.remember(
      NpcMemory(
        age: l.age,
        text: 'you selling the ${a.name.toLowerCase()}',
        valence: -2,
        intensity: 3,
        tags: ['heirloom'],
      ),
    );
  }
  l.flags['sold_heirloom'] = Memory(
    l.age,
    'selling the family ${a.name.toLowerCase()}',
  );
  final owners = heirloomHistory(a).length;
  return family.isEmpty
      ? 'Nobody is left to mind. It still feels strange.'
      : '${family.first.name.split(' ').first} found out. "That was ${owners > 1 ? '$owners generations' : 'Grandma\'s'} of us," they said, and nothing else.';
}

// ---------------- Collectibles ----------------

const collectibleTypes = <String, String>{
  'cards': 'Trading cards',
  'vinyl': 'Vinyl records',
  'sneakers': 'Sneakers',
  'comics': 'Comic books',
  'watches': 'Watches',
  'art': 'Art prints',
  'stamps': 'Stamps',
};

const _rarity = <String, (int, int)>{
  'common': (120, 500),
  'rare': (900, 4000),
  'legendary': (6000, 30000),
};

/// How a collecting type's prices move this year, in percent. Crazes and
/// crashes come and go; the same year is the same for everyone.
int collectibleTrend(String type, int year) {
  final r = Random(_hash(type) ^ (year * 7919));
  final roll = r.nextInt(100);
  if (roll < 8) return 30 + r.nextInt(30);
  if (roll < 16) return -(20 + r.nextInt(20));
  return r.nextInt(25) - 9;
}

String trendLabel(int t) => t >= 15
    ? 'hot'
    : t <= -8
    ? 'cold'
    : 'steady';

typedef CollectOffer = ({
  String type,
  String rarity,
  int price,
  bool papers,
  bool fake,
  String seller,
});

const _sellers = [
  'a stall holder who keeps glancing at the exit',
  'a retired collector with a magnifying glass on a string',
  'an online seller with 4,000 five-star reviews',
  'a teenager who "found it in the attic"',
  'an auction house with a very serious catalogue',
];

List<CollectOffer> collectOffers(Life l) {
  final r = Random(l.seed * 13 + l.age * 101 + 5);
  return [
    for (var i = 0; i < 3; i++)
      () {
        final type = collectibleTypes.keys.elementAt(
          r.nextInt(collectibleTypes.length),
        );
        final rarity = switch (r.nextInt(100)) {
          < 60 => 'common',
          < 90 => 'rare',
          _ => 'legendary',
        };
        final (lo, hi) = _rarity[rarity]!;
        final papers = r.nextInt(100) < 55;
        final base = lo + r.nextInt(hi - lo);
        final price = ((papers ? base : base * 0.7) / 10).round() * 10;
        final fakeOdds = papers ? 3 : (rarity == 'legendary' ? 50 : 30);
        return (
          type: type,
          rarity: rarity,
          price: price,
          papers: papers,
          fake: r.nextInt(100) < fakeOdds,
          seller: _sellers[r.nextInt(_sellers.length)],
        );
      }(),
  ];
}

String _rarityLabel(String r) => '${r[0].toUpperCase()}${r.substring(1)}';

Storylet collectScene(Life l) {
  final offers = collectOffers(l);
  final trends = {
    for (final t in collectibleTypes.keys) t: collectibleTrend(t, l.year),
  };
  final hot = trends.entries
      .where((e) => e.value >= 15)
      .map((e) => collectibleTypes[e.key]!.toLowerCase());
  final cold = trends.entries
      .where((e) => e.value <= -8)
      .map((e) => collectibleTypes[e.key]!.toLowerCase());
  return _scene(
    'collect_market',
    'The collectors\' fair is packed. ${hot.isEmpty ? 'Nothing is especially hot this year.' : 'Everyone is talking about ${hot.join(' and ')}.'}${cold.isEmpty ? '' : ' Nobody wants ${cold.join(' or ')} right now.'} Three things catch your eye. Items without papers are cheaper, and some of them are not what they seem.',
    [
      for (final o in offers)
        Choice(
          label:
              '${_rarityLabel(o.rarity)} ${collectibleTypes[o.type]!.toLowerCase()} (${_m(o.price)})',
          outcome: '',
          needsMoney: o.price,
          risk: o.papers
              ? 'With papers · from ${o.seller}'
              : 'No papers: could be fake · from ${o.seller}',
          run: (l, rng) {
            l.money -= o.price;
            l.assets.add(
              Asset(
                id: 'col${l.age}_${o.type}_${o.price}',
                kind: 'collectible',
                name:
                    '${_rarityLabel(o.rarity)} ${collectibleTypes[o.type]!.toLowerCase()}',
                value: o.price,
                yearlyCost: 0,
                since: l.age,
                info: {
                  'type': o.type,
                  'rarity': o.rarity,
                  'papers': o.papers,
                  'fake': o.fake,
                  'checked': o.papers,
                  'dep': -collectibleTrend(o.type, l.year),
                },
              ),
            );
            l.stats.add('happiness', 2);
            l.flags['collector'] ??= Memory(l.age, 'starting a collection');
            return 'You carried it home like it was made of glass. ${o.papers ? 'The certificate goes in a drawer you will never lose.' : 'No papers, but the seller swore on their mother.'}';
          },
        ),
      Choice(
        label: 'Just browse',
        outcome: 'You bought a hot dog and an opinion about mint condition.',
      ),
    ],
  );
}

/// Appraisal: the expert finds the fakes in your collection.
ActionResult appraiseCollection(Life l) {
  final unchecked = l.assets
      .where((a) => a.kind == 'collectible' && a.info['checked'] != true)
      .toList();
  final fakes = <Asset>[];
  for (final a in unchecked) {
    a.info['checked'] = true;
    if (a.info['fake'] == true) {
      a.value = max(10, (a.value * 0.05).round());
      a.info['dep'] = 0;
      fakes.add(a);
    }
  }
  final total = l.assets
      .where((a) => a.kind == 'collectible')
      .fold(0, (s, a) => s + a.value);
  return ActionResult(
    fakes.isEmpty
        ? 'The expert turned every piece over twice. "All genuine. You have a good eye."'
        : 'The expert went quiet over your ${fakes.first.name.toLowerCase()}. "I am sorry. This is a fake, and not a good one."',
    [
      'Money −\$250',
      'Collection now worth ${_m(total)}',
      if (fakes.isNotEmpty)
        'Why: ${fakes.length} fake${fakes.length == 1 ? '' : 's'} found',
    ],
  );
}

/// What a buyer pays for a collectible: fakes are spotted on sale.
(int, String?) collectibleSale(Asset a) =>
    a.info['fake'] == true && a.info['checked'] != true
    ? (
        max(10, (a.value * 0.05).round()),
        'The buyer\'s expert spotted that it was a fake.',
      )
    : (a.value, null);

// ---------------- Boats and aircraft ----------------

typedef CraftModel = ({
  String id,
  String kind,
  String name,
  int price,
  int upkeep,
  int dep,
  String blurb,
});

const craft = <CraftModel>[
  (
    id: 'dinghy',
    kind: 'boat',
    name: 'Sailing dinghy',
    price: 3500,
    upkeep: 400,
    dep: 10,
    blurb: 'Small, wet and joyful',
  ),
  (
    id: 'speedboat',
    kind: 'boat',
    name: 'Speedboat',
    price: 28000,
    upkeep: 3000,
    dep: 10,
    blurb: 'Marina fees, fuel and spray',
  ),
  (
    id: 'yacht',
    kind: 'boat',
    name: 'Yacht',
    price: 280000,
    upkeep: 28000,
    dep: 7,
    blurb: 'Sleeps six; a crew is extra',
  ),
  (
    id: 'light_aircraft',
    kind: 'plane',
    name: 'Light aircraft',
    price: 120000,
    upkeep: 14000,
    dep: 6,
    blurb: 'Two seats, one propeller, endless sky',
  ),
  (
    id: 'seaplane',
    kind: 'plane',
    name: 'Seaplane',
    price: 350000,
    upkeep: 30000,
    dep: 6,
    blurb: 'Lands on lakes; impresses everyone',
  ),
  (
    id: 'jet',
    kind: 'plane',
    name: 'Private jet',
    price: 3500000,
    upkeep: 450000,
    dep: 8,
    blurb: 'Pilots, hangar and fuel included in the pain',
  ),
];

bool canFly(Life l) =>
    l.flags.containsKey('pilot_licence') ||
    l.flags.containsKey('private_pilot');

Storylet craftDealer(String kind, Life l) {
  final models = craft.where((c) => c.kind == kind).toList();
  return _scene(
    kind == 'boat' ? 'boat_dealer' : 'plane_dealer',
    kind == 'boat'
        ? 'The marina broker smells of sunscreen and commission. "Everything here floats," he promises.'
        : 'The aircraft broker walks you across a windy airfield. "Running costs," she says, "are the real price."',
    [
      for (final c in models)
        Choice(
          label: '${c.name} (${_m(c.price)})',
          outcome: '',
          needsMoney: c.price,
          risk: '${c.blurb} · ${_m(c.upkeep)} a year · loses ${c.dep}% a year',
          run: (l, rng) {
            l.money -= c.price;
            l.assets.add(
              Asset(
                id: '${c.id}${l.age}',
                kind: c.kind,
                name: c.name,
                value: c.price,
                yearlyCost: c.upkeep,
                since: l.age,
                info: {'dep': c.dep, 'model': c.id},
              ),
            );
            l.flags['owns_${c.kind}'] = Memory(
              l.age,
              'buying a ${c.name.toLowerCase()}',
            );
            l.stats.add('happiness', c.price >= 100000 ? 6 : 4);
            return c.kind == 'boat'
                ? 'You named her after someone you love and took her out the same afternoon.'
                : 'Your first flight in your own plane was perfectly smooth. You landed grinning.';
          },
        ),
      Choice(
        label: 'Not today',
        outcome: 'You took a brochure. It is very glossy.',
      ),
    ],
  );
}

// ---------------- Home upgrades and hosting ----------------

typedef HomeUpgrade = ({
  String id,
  String name,
  int cost,
  String effect,
  int valuePct,
  int upkeep,
  int hosting,
});

const homeUpgrades = <HomeUpgrade>[
  (
    id: 'garden',
    name: 'Garden makeover',
    cost: 5000,
    effect: 'Happiness +1 a year · 4 more guests',
    valuePct: 3,
    upkeep: 200,
    hosting: 4,
  ),
  (
    id: 'office',
    name: 'Home office',
    cost: 6000,
    effect: 'Smarts +1 a year · better at your job',
    valuePct: 2,
    upkeep: 0,
    hosting: 0,
  ),
  (
    id: 'gym',
    name: 'Home gym',
    cost: 8000,
    effect: 'Health +1 a year',
    valuePct: 1,
    upkeep: 0,
    hosting: 0,
  ),
  (
    id: 'games',
    name: 'Games room',
    cost: 12000,
    effect: 'Hosts 6 more guests · happiness +1 a year',
    valuePct: 2,
    upkeep: 0,
    hosting: 6,
  ),
  (
    id: 'solar',
    name: 'Solar panels',
    cost: 15000,
    effect: 'Upkeep \$900 a year less',
    valuePct: 3,
    upkeep: -900,
    hosting: 0,
  ),
  (
    id: 'security',
    name: 'Security system',
    cost: 3000,
    effect: 'Insurance 15% cheaper · peace of mind',
    valuePct: 1,
    upkeep: 120,
    hosting: 0,
  ),
  (
    id: 'nursery',
    name: 'Nursery',
    cost: 4000,
    effect: 'Happiness +1 a year while a child is under 5',
    valuePct: 1,
    upkeep: 0,
    hosting: 0,
  ),
  (
    id: 'pool',
    name: 'Swimming pool',
    cost: 45000,
    effect: 'Happiness +2 and health +1 a year · 8 more guests',
    valuePct: 6,
    upkeep: 2500,
    hosting: 8,
  ),
  (
    id: 'extension',
    name: 'Extension',
    cost: 60000,
    effect: 'One more bedroom · 4 more guests',
    valuePct: 10,
    upkeep: 600,
    hosting: 4,
  ),
];

List<String> roomsOf(Asset? home) =>
    List<String>.from(home?.info['rooms'] ?? const []);

/// How many guests your home holds for a party.
int hostingCapacity(Life l) {
  final home = homeOf(l);
  if (home == null) return l.has('rental') ? 6 : 8;
  final beds = (home.info['bedrooms'] as int?) ?? 2;
  return 6 +
      beds * 3 +
      roomsOf(home).fold(
        0,
        (s, r) =>
            s +
            (homeUpgrades.where((u) => u.id == r).firstOrNull?.hosting ?? 0),
      );
}

Storylet? upgradeScene(Life l) {
  final home = homeOf(l);
  if (home == null) return null;
  final have = roomsOf(home);
  final open = homeUpgrades.where((u) => !have.contains(u.id)).toList();
  return _scene(
    'home_upgrade',
    'You walk round your ${home.name.toLowerCase()} with a tape measure and big ideas. It holds about ${hostingCapacity(l)} guests now.${have.isEmpty ? '' : ' Already done: ${have.map((r) => homeUpgrades.firstWhere((u) => u.id == r).name.toLowerCase()).join(', ')}.'}',
    [
      for (final u in open)
        Choice(
          label: '${u.name} (${_m(u.cost)})',
          outcome: '',
          needsMoney: u.cost,
          risk: u.effect,
          run: (l, rng) {
            final h = homeOf(l)!;
            l.money -= u.cost;
            h.value += (h.value * u.valuePct / 100).round();
            h.yearlyCost = max(0, h.yearlyCost + u.upkeep);
            h.info['rooms'] = [...roomsOf(h), u.id];
            if (u.id == 'extension') {
              h.info['bedrooms'] = ((h.info['bedrooms'] as int?) ?? 2) + 1;
            }
            l.stats.add('happiness', 2);
            return switch (u.id) {
              'pool' => 'The pool is finished. The first swim is cold, loud and perfect.',
              'extension' =>
                'Six months of dust later, you have a whole new room.',
              'solar' =>
                'The panels went up in a day. You check the app far too often.',
              'gym' => 'The home gym is ready. The excuses are not.',
              _ =>
                'The builders packed up and left it better than they found it.',
            };
          },
        ),
      Choice(
        label: 'Not now',
        outcome: 'You put the tape measure back in the drawer.',
      ),
    ],
  );
}

// ---------------- Disasters and home insurance ----------------

const _hazards = <String, List<String>>{
  'Japan': ['earthquake', 'typhoon'],
  'Philippines': ['typhoon', 'flood', 'earthquake'],
  'United States': ['hurricane', 'wildfire', 'tornado', 'flood'],
  'Mexico': ['earthquake', 'hurricane'],
  'India': ['flood', 'cyclone'],
  'Brazil': ['flood', 'landslide'],
  'Australia': ['bushfire', 'flood', 'cyclone'],
  'Canada': ['wildfire', 'flood', 'ice storm'],
  'United Kingdom': ['flood', 'storm'],
  'Ireland': ['storm', 'flood'],
  'Netherlands': ['flood', 'storm'],
  'Germany': ['flood', 'storm'],
  'Portugal': ['wildfire', 'storm'],
  'Nigeria': ['flood', 'storm'],
};

/// Chance per home per year, in percent.
int hazardRate(String country) => switch (country) {
  'Philippines' => 5,
  'Japan' => 4,
  'United States' || 'Mexico' || 'India' || 'Australia' => 3,
  _ => 2,
};

List<String> hazardsOf(String country) => _hazards[country] ?? const ['storm'];

const insuranceExcess = 1000;

bool insured(Asset a) => a.info['insured'] == true;

int premiumFor(Life l, Asset a) {
  final claims = (a.info['claims'] as int?) ?? 0;
  var p = a.value * 0.003 * (1 + 0.15 * hazardRate(l.country));
  if (roomsOf(a).contains('security')) p *= 0.85;
  p *= 1 + 0.2 * claims;
  return max(300, (p / 10).round() * 10);
}

/// Yearly premium for every insured home you own.
int homeInsuranceCost(Life l) => l.assets
    .where((a) => a.kind == 'house' && insured(a))
    .fold(0, (s, a) => s + premiumFor(l, a));

String _what(String hazard) => switch (hazard) {
  'earthquake' => 'An earthquake shook',
  'typhoon' => 'A typhoon tore through',
  'hurricane' => 'A hurricane slammed into',
  'cyclone' => 'A cyclone battered',
  'wildfire' || 'bushfire' => 'A $hazard swept towards',
  'tornado' => 'A tornado touched down near',
  'flood' => 'Floodwater rose through',
  'landslide' => 'A landslide came down above',
  'ice storm' => 'An ice storm froze',
  _ => 'A violent storm hit',
};

Storylet? disasterScene(List<String> args, Life l) {
  if (args.length < 3) return null;
  final hazard = args[0];
  final home = l.assets.where((a) => a.id == args[1]).firstOrNull;
  final damage = int.tryParse(args[2]) ?? 0;
  if (home == null) return null;
  final covered = insured(home);
  return _scene(
    'disaster',
    '${_what(hazard)} ${l.city}. Your ${home.name.toLowerCase()} took about ${_m(damage)} of damage (condition ${home.condition}%). ${covered ? 'You are insured, with a ${_m(insuranceExcess)} excess.' : 'You are not insured.'}',
    [
      if (covered)
        Choice(
          label: 'Claim on your insurance',
          outcome: '',
          needsMoney: insuranceExcess,
          risk: 'You pay the ${_m(insuranceExcess)} excess; premiums rise 20%',
          run: (l, rng) {
            l.money -= insuranceExcess;
            home.condition = max(home.condition, 90);
            home.info['claims'] = ((home.info['claims'] as int?) ?? 0) + 1;
            return 'The assessor came within a week. The builders came within a month. Your home is whole again, and the insurance paid ${_m(damage - insuranceExcess)}.';
          },
        ),
      Choice(
        label: 'Pay for the repairs yourself (${_m(damage)})',
        outcome: '',
        needsMoney: damage,
        run: (l, rng) {
          l.money -= damage;
          home.condition = max(home.condition, 90);
          return 'It cost more than you want to remember, but the house is sound again.';
        },
      ),
      Choice(
        label: 'Live with the damage for now',
        outcome: '',
        risk: 'The home loses value and the damp sets in',
        run: (l, rng) {
          home.value = max(0, home.value - (damage * 0.6).round());
          l.stats.add('happiness', -3);
          return 'You moved the furniture away from the worst of it and tried not to look at the ceiling.';
        },
      ),
    ],
  );
}

// ---------------- Each birthday ----------------

/// Runs before yearly money: room effects, heirlooms arriving, collectible
/// trends for this year, and the chance of a disaster.
List<String> possessionsYear(Life l, Random rng) {
  final feed = <String>[];
  final home = homeOf(l);
  for (final r in roomsOf(home)) {
    switch (r) {
      case 'gym':
        l.stats.add('health', 1);
      case 'office':
        l.stats.add('smarts', 1);
      case 'garden' || 'games':
        l.stats.add('happiness', 1);
      case 'pool':
        l.stats.add('happiness', 2);
        l.stats.add('health', 1);
      case 'nursery':
        if (l.npcs.any(
          (n) => n.circle == 'Children' && n.alive && n.ageIn(l.year) < 5,
        )) {
          l.stats.add('happiness', 1);
        }
    }
  }
  final waiting = l.marks
      .where((m) => m.startsWith('family_heirloom:'))
      .firstOrNull;
  if (waiting != null && l.age >= 18 && l.age <= 40 && rng.nextInt(100) < 25) {
    final h = heirloomById(waiting.substring(16));
    l.marks.remove(waiting);
    if (h != null) {
      final giver = l.npcs
          .where((n) => n.alive && (n.role == 'Mother' || n.role == 'Father'))
          .firstOrNull;
      l.assets.add(
        makeHeirloom(l, h, [
          'Your great-grandparents (${l.birthYear - 75}s)',
          'Your grandparents (${l.birthYear - 50}s)',
          if (giver != null) giver.name,
        ]),
      );
      l.flags['heirloom'] = Memory(
        l.age,
        'being given the family ${h.name.toLowerCase()}',
      );
      feed.add(
        '${giver?.name.split(' ').first ?? 'A solicitor'} gave you ${h.about}. "It has been in the family for generations. Now it is yours."',
      );
    }
  }
  for (final a in l.assets.where((a) => a.kind == 'collectible')) {
    if (a.info['fake'] == true && a.info['checked'] == true) continue;
    final t = collectibleTrend(a.info['type'] as String? ?? 'cards', l.year);
    a.info['dep'] = -t;
    if (t >= 30) {
      feed.add(
        '${collectibleTypes[a.info['type']] ?? 'Collectibles'} are suddenly the craze. Your ${a.name.toLowerCase()} is worth $t% more.',
      );
    } else if (t <= -20) {
      feed.add(
        'The ${(collectibleTypes[a.info['type']] ?? 'collectibles').toLowerCase()} market crashed. Your ${a.name.toLowerCase()} lost ${-t}% of its value.',
      );
    }
  }
  for (final h in [?home, ?lettingOf(l)]) {
    if (h.kind != 'house') continue;
    if (rng.nextInt(100) >= hazardRate(l.country)) continue;
    final hazards = hazardsOf(l.country);
    final hazard = hazards[rng.nextInt(hazards.length)];
    final damage = max(2000, (h.value * (8 + rng.nextInt(28)) / 100).round());
    h.condition = max(5, h.condition - 20 - rng.nextInt(30));
    l.sceneQueue.add('disaster:$hazard:${h.id}:$damage');
    l.flags['survived_${hazard.replaceAll(' ', '_')}'] = Memory(
      l.age,
      'living through a $hazard',
    );
    break;
  }
  return feed;
}

// ---------------- Activities ----------------

final possessionActions = <GameAction>[
  GameAction(
    id: 'go_collecting',
    label: 'Go to a collectors\' fair',
    category: 'Money',
    priceNote: 'Cards, vinyl, sneakers, watches · \$120 to \$30,000',
    keywords: [
      'collect',
      'collectible',
      'cards',
      'vinyl',
      'sneakers',
      'comics',
      'stamps',
      'watch',
      'auction',
    ],
    minAge: 12,
    run: (l, rng) {
      l.sceneQueue.add('collect_market');
      return ActionResult('You queue at the door of the collectors\' fair.');
    },
  ),
  GameAction(
    id: 'appraise',
    label: 'Get your collection valued',
    category: 'Money',
    cost: 250,
    priceNote: 'Costs \$250 · finds any fakes',
    keywords: ['appraise', 'value', 'expert', 'fake', 'collection', 'heirloom'],
    minAge: 12,
    extraCheck: (l) => l.assets.any((a) => a.kind == 'collectible')
        ? null
        : 'You have no collectibles yet',
    run: (l, rng) {
      l.money -= 250;
      return appraiseCollection(l);
    },
  ),
  GameAction(
    id: 'boat_licence',
    label: 'Get a boat licence',
    category: 'Licences',
    cost: 500,
    priceNote: 'Costs \$500 · a day course and a test',
    keywords: ['boat', 'licence', 'sailing', 'skipper'],
    minAge: 16,
    extraCheck: (l) =>
        l.flags.containsKey('boat_licence') ? 'You already have one' : null,
    run: (l, rng) {
      l.money -= 500;
      if (rng.nextInt(100) < 70 + l.stats['smarts'] ~/ 4) {
        l.flags['boat_licence'] = Memory(l.age, 'earning your boat licence');
        return ActionResult(
          'You tied every knot, reversed into the berth and passed. You can skipper a boat.',
          ['Money −\$500', 'Boat licence'],
        );
      }
      return ActionResult(
        'You reversed into the examiner\'s boat. You can try again next year.',
        ['Money −\$500', 'Why: failed the practical'],
      );
    },
  ),
  GameAction(
    id: 'pilot_lessons',
    label: 'Get a private pilot licence',
    category: 'Licences',
    cost: 12000,
    priceNote: 'Costs \$12,000 · 45 hours of flying',
    keywords: ['pilot', 'fly', 'licence', 'plane', 'aircraft', 'lessons'],
    minAge: 17,
    extraCheck: (l) => canFly(l) ? 'You can already fly' : null,
    run: (l, rng) {
      l.money -= 12000;
      if (rng.nextInt(100) < 60 + l.stats['smarts'] ~/ 3) {
        l.flags['private_pilot'] = Memory(l.age, 'earning your pilot licence');
        l.stats.add('happiness', 5);
        return ActionResult(
          'Forty-five hours, one wobbly crosswind landing and a checkride later, you are a pilot.',
          ['Money −\$12,000', 'Private pilot licence'],
        );
      }
      return ActionResult(
        'You froze on the checkride\'s engine-failure drill. More hours, then try again next year.',
        ['Money −\$12,000', 'Why: failed the checkride'],
      );
    },
  ),
  GameAction(
    id: 'buy_boat',
    label: 'Buy a boat',
    category: 'Assets',
    priceNote: 'From \$3,500 · needs a boat licence',
    keywords: ['boat', 'yacht', 'speedboat', 'dinghy', 'marina', 'sail'],
    minAge: 18,
    extraCheck: (l) => !l.flags.containsKey('boat_licence')
        ? 'Needs a boat licence'
        : l.assets.where((a) => a.kind == 'boat').length >= 2
        ? 'You already own two boats'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('boat_dealer');
      return ActionResult('You visit the marina broker.');
    },
  ),
  GameAction(
    id: 'buy_plane',
    label: 'Buy an aircraft',
    category: 'Assets',
    priceNote: 'From \$120,000 · needs a pilot licence',
    keywords: ['plane', 'aircraft', 'jet', 'seaplane', 'fly', 'hangar'],
    minAge: 18,
    extraCheck: (l) => !canFly(l)
        ? 'Needs a pilot licence'
        : l.assets.any((a) => a.kind == 'plane')
        ? 'You already own an aircraft'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('plane_dealer');
      return ActionResult('You visit the aircraft broker.');
    },
  ),
  GameAction(
    id: 'go_sailing',
    label: 'Take the boat out',
    category: 'Travel',
    priceNote: 'Free · bring someone along',
    keywords: ['sail', 'boat', 'sea', 'lake', 'yacht'],
    minAge: 16,
    extraCheck: (l) =>
        l.assets.any((a) => a.kind == 'boat') ? null : 'Needs a boat',
    run: (l, rng) {
      final boat = l.assets.firstWhere((a) => a.kind == 'boat');
      final mate =
          (l.npcs
                  .where(
                    (n) =>
                        n.alive &&
                        (n.circle == 'Partner' ||
                            n.circle == 'Friends' ||
                            n.circle == 'Children'),
                  )
                  .toList()
                ..sort((a, b) => b.bond.compareTo(a.bond)))
              .firstOrNull;
      if (rng.nextInt(100) < 4) {
        boat.condition = max(0, boat.condition - 30);
        l.stats.add('health', -6);
        return ActionResult(
          'A squall came out of nowhere. You limped back to the harbour soaked, bruised and very humble.',
          ['Health −6', '${boat.name} condition ${boat.condition}%'],
        );
      }
      l.stats.add('happiness', 5);
      mate?.addFacets(affection: 4);
      mate?.lastContactAge = l.age;
      return ActionResult(
        mate == null
            ? 'Just you, the wind and the water. You came home sunburnt and calm.'
            : 'You and ${mate.name.split(' ').first} sailed until the light went gold. Neither of you said much. Neither of you needed to.',
        [
          'Happiness +5',
          if (mate != null) 'Bond with ${mate.name.split(' ').first} +4',
        ],
      );
    },
  ),
  GameAction(
    id: 'fly_away',
    label: 'Fly somewhere for the day',
    category: 'Travel',
    priceNote: 'Fuel \$600',
    cost: 600,
    keywords: ['fly', 'plane', 'flight', 'trip', 'aircraft'],
    minAge: 17,
    extraCheck: (l) =>
        l.assets.any((a) => a.kind == 'plane') ? null : 'Needs an aircraft',
    run: (l, rng) {
      l.money -= 600;
      if (rng.nextInt(100) < 3) {
        l.stats.add('health', -4);
        return ActionResult(
          'The engine coughed over farmland. You made a textbook emergency landing in a field of very surprised cows.',
          ['Money −\$600', 'Health −4'],
        );
      }
      l.stats.add('happiness', 6);
      return ActionResult(
        'You flew to the coast for lunch and were home for dinner. Ordinary life looks small from up there.',
        ['Money −\$600', 'Happiness +6'],
      );
    },
  ),
  GameAction(
    id: 'home_upgrade',
    label: 'Improve your home',
    category: 'Assets',
    priceNote: 'Gym, office, pool, extension and more',
    keywords: [
      'upgrade',
      'room',
      'pool',
      'gym',
      'office',
      'extension',
      'solar',
      'garden',
      'renovate',
    ],
    minAge: 18,
    extraCheck: (l) => homeOf(l) == null
        ? 'Needs a home you own'
        : roomsOf(homeOf(l)).length >= homeUpgrades.length
        ? 'Every upgrade is done'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('home_upgrade');
      return ActionResult('You sketch plans on the back of an envelope.');
    },
  ),
  GameAction(
    id: 'home_insurance',
    label: 'Home insurance',
    category: 'Assets',
    priceNote: 'Covers disasters, \$1,000 excess',
    hint: (l) {
      final houses = l.assets.where((a) => a.kind == 'house');
      if (houses.isEmpty) return 'Covers disasters, \$1,000 excess';
      return houses.every(insured)
          ? 'Insured · ${_m(homeInsuranceCost(l))} a year · tap to cancel'
          : 'About ${_m(houses.fold(0, (s, a) => s + premiumFor(l, a)))} a year · ${hazardsOf(l.country).join(', ')} risk here';
    },
    keywords: [
      'insurance',
      'insure',
      'home',
      'flood',
      'fire',
      'earthquake',
      'storm',
    ],
    minAge: 18,
    repeatable: true,
    extraCheck: (l) =>
        l.assets.any((a) => a.kind == 'house') ? null : 'Needs a home you own',
    run: (l, rng) {
      final houses = l.assets.where((a) => a.kind == 'house').toList();
      if (houses.every(insured)) {
        for (final h in houses) {
          h.info.remove('insured');
        }
        return ActionResult(
          'You cancelled your home insurance. The savings feel good until the weather forecast.',
          ['Home insurance cancelled'],
        );
      }
      for (final h in houses) {
        h.info['insured'] = true;
      }
      return ActionResult(
        'Your homes are insured against ${hazardsOf(l.country).join(', ')} and more. You pay ${_m(homeInsuranceCost(l))} a year with your other bills.',
        ['Home insurance ${_m(homeInsuranceCost(l))} a year'],
      );
    },
  ),
];

/// Scenes in this file, dispatched from buildScene.
Storylet? possessionScene(String id, List<String> args, Life l) => switch (id) {
  'collect_market' => collectScene(l),
  'boat_dealer' => craftDealer('boat', l),
  'plane_dealer' => craftDealer('plane', l),
  'home_upgrade' => upgradeScene(l),
  'disaster' => disasterScene(args, l),
  _ => null,
};
