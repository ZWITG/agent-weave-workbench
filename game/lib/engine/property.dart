import 'dart:math';

import 'actions.dart';
import 'finance.dart';
import 'friends.dart';
import 'homes.dart';
import 'models.dart';
import 'storylet.dart';
import 'world_data.dart';

// Property, both sides of the lease.
// Landlords: up to five buy-to-lets, each with a tenant you choose from
// applicants, a rent you set, an optional letting agent, empty months and
// tenant trouble. Owners: move house (sell or let the old one) and
// remortgage. Renters: six flats a year (shared houses come with
// flatmates), landlords who raise the rent, sell up or ignore repairs, and
// deposits that do not always come back in full.

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

const maxLets = 5;

/// Every home you let out.
List<Asset> lettingsOf(Life l) =>
    l.assets.where((a) => a.kind == 'house' && a.info['let'] == true).toList();

Asset? _byId(Life l, String id) =>
    l.assets.where((a) => a.id == id).firstOrNull;

// ---------------- Tenants ----------------

typedef TenantKind = ({
  String label,
  String hint,

  /// Yearly chance (out of 100) they move out, before the rent level.
  int leave,

  /// Yearly chance they stop paying, damage the place, or ask for repairs.
  int unpaid,
  int damage,
  int repairs,
});

const tenantKinds = <String, TenantKind>{
  'professional': (
    label: 'Young professional',
    hint: 'Steady job, glowing references',
    leave: 15,
    unpaid: 3,
    damage: 3,
    repairs: 8,
  ),
  'students': (
    label: 'Three students',
    hint: 'Parents guarantee the rent · parties likely',
    leave: 30,
    unpaid: 4,
    damage: 25,
    repairs: 6,
  ),
  'family': (
    label: 'A family of four',
    hint: 'Want somewhere to stay for years · kids and a dog',
    leave: 5,
    unpaid: 5,
    damage: 10,
    repairs: 18,
  ),
  'retiree': (
    label: 'A retired teacher',
    hint: 'Quiet, tidy, renting for thirty years',
    leave: 6,
    unpaid: 2,
    damage: 2,
    repairs: 10,
  ),
  'charmer': (
    label: 'A smooth talker',
    hint: 'Offers six months up front, in cash, today',
    leave: 20,
    unpaid: 30,
    damage: 12,
    repairs: 2,
  ),
};

bool isVacant(Asset a) =>
    a.info.containsKey('tenant') && a.info['tenant'] == null;

Map<String, dynamic>? tenantOf(Asset a) =>
    (a.info['tenant'] as Map?)?.cast<String, dynamic>();

String rentLevelOf(Asset a) => a.info['rentLevel'] as String? ?? 'market';

const rentLevels = <String, (String, double)>{
  'low': ('Below market', 0.85),
  'market': ('Market rent', 1.0),
  'high': ('Above market', 1.2),
};

/// What the tenants actually pay you this year (after empty months, late
/// rent and the agent's cut).
int rentIncome(Life l, Asset a) {
  if (isVacant(a)) return 0;
  var r = rentFor(a);
  if (l.marks.contains('late_rent:${l.age}:${a.id}') ||
      l.marks.contains('late_rent:${l.age}')) {
    r ~/= 2;
  }
  if (l.marks.contains('void:${l.age}:${a.id}')) r = r * 2 ~/ 3;
  if (a.info['agent'] == true) r = (r * 0.88).round();
  return r;
}

List<(String, Map<String, dynamic>)> _applicants(Life l, Asset a) {
  final rng = Random(l.seed * 7 + l.age * 131 + a.id.hashCode);
  final kinds = tenantKinds.keys.toList()..shuffle(rng);
  final c = countryNamed(l.country);
  return [
    for (final k in kinds.take(3))
      () {
        final pool = rng.nextBool() ? c.female : c.male;
        final name =
            '${pool[rng.nextInt(pool.length)]} ${c.surnames[rng.nextInt(c.surnames.length)]}';
        return (k, <String, dynamic>{'kind': k, 'name': name, 'since': l.age});
      }(),
  ];
}

// ---------------- Each birthday ----------------

/// Landlord and renter life for the year. Returns feed lines and queues
/// scenes for things that need a decision.
List<String> propertyYear(Life l, Random rng) {
  final feed = <String>[];
  var asked = false;
  for (final a in lettingsOf(l)) {
    final t = tenantOf(a);
    if (isVacant(a)) {
      // An empty home loses a third of the year's rent and needs a tenant.
      l.marks.add('void:${l.age}:${a.id}');
      if (a.info['agent'] == true) {
        final pick = _applicants(l, a).first.$2;
        a.info['tenant'] = pick;
        feed.add(
          'Your letting agent found a tenant for the ${a.name.toLowerCase()} in ${a.info['area']}: ${pick['name']} (${tenantKinds[pick['kind']]!.label.toLowerCase()}).',
        );
      } else if (!asked) {
        l.sceneQueue.add('let_pick:${a.id}');
        asked = true;
      }
      continue;
    }
    if (t == null) continue; // an older let with an unnamed tenant
    final k = tenantKinds[t['kind']] ?? tenantKinds['professional']!;
    final level = rentLevelOf(a);
    final leave =
        k.leave +
        (level == 'high'
            ? 15
            : level == 'low'
            ? -4
            : 0);
    final who = (t['name'] as String).split(' ').first;
    final agent = a.info['agent'] == true;
    if (rng.nextInt(100) < leave) {
      a.info['tenant'] = null;
      feed.add(
        '$who handed in their notice on your ${a.name.toLowerCase()}${level == 'high' ? ', saying the rent was too steep' : ''}. It is empty now.',
      );
      continue;
    }
    final roll = rng.nextInt(100);
    if (roll < k.unpaid) {
      if (agent) {
        l.marks.add('late_rent:${l.age}:${a.id}');
        feed.add(
          '$who fell behind on the rent. Your agent chased it and got half back.',
        );
      } else if (!asked) {
        l.sceneQueue.add('let_trouble:${a.id}:unpaid');
        asked = true;
      }
    } else if (roll < k.unpaid + k.damage) {
      a.condition = max(0, a.condition - 12 - rng.nextInt(10));
      feed.add(
        t['kind'] == 'students'
            ? 'The students in your ${a.name.toLowerCase()} threw a party the neighbours will never forget. Condition ${a.condition}%.'
            : 'Wear and tear at your ${a.name.toLowerCase()}: a broken boiler and a stained carpet. Condition ${a.condition}%.',
      );
    } else if (roll < k.unpaid + k.damage + k.repairs) {
      if (agent) {
        final cost = 400 + rng.nextInt(800);
        l.money -= cost;
        feed.add(
          'Your agent sorted a leaking roof at the ${a.name.toLowerCase()} for ${_m(cost)}.',
        );
      } else if (!asked) {
        l.sceneQueue.add('let_trouble:${a.id}:repair');
        asked = true;
      }
    } else if (roll > 96) {
      feed.add(
        '$who sent you a photo of the garden they planted at your ${a.name.toLowerCase()}. Best tenant ever.',
      );
    }
  }
  final flat = l.assets.where((a) => a.kind == 'rental').firstOrNull;
  if (flat != null && rng.nextInt(100) < 22) {
    final bad = flat.info['landlord'] == 'slow';
    switch (rng.nextInt(bad ? 4 : 3)) {
      case 0:
        l.sceneQueue.add('landlord_rise');
      case 1:
        l.sceneQueue.add('landlord_sells');
      case 2:
        feed.add(
          'Your landlord fixed the boiler the same day you reported it. A good one.',
        );
      default:
        l.reason = 'A landlord who never fixes anything';
        l.stats.add('happiness', -3);
        l.stats.add('health', -1);
        feed.add(
          'The mould in the bathroom is back. Your landlord has not replied in six weeks.',
        );
    }
  }
  return feed;
}

// ---------------- Moving out of a rental ----------------

/// Ends your tenancy: the deposit comes back, less any deductions.
String leaveRental(Life l, Random rng) {
  final flat = l.assets.where((a) => a.kind == 'rental').firstOrNull;
  if (flat == null) return '';
  l.assets.remove(flat);
  l.flags.remove('own_flat');
  final deposit = (flat.info['deposit'] as int?) ?? 0;
  if (deposit <= 0) return '';
  // Some landlords find something to keep money for.
  final keep = flat.info['landlord'] == 'slow' || rng.nextInt(100) < 20
      ? (deposit * (0.2 + rng.nextDouble() * 0.3)).round()
      : 0;
  l.money += deposit - keep;
  return keep > 0
      ? ' The landlord kept ${_m(keep)} of your deposit for "cleaning and a scuffed wall".'
      : ' Your full ${_m(deposit)} deposit came back.';
}

// ---------------- Rentals to live in ----------------

typedef RentalListing = ({
  int i,
  String name,
  String area,
  int rent,
  String blurb,
  bool shared,
  String landlord,
});

const _flatKinds = <(String, int, String, bool)>[
  ('Room in a shared house', 5400, 'Two flatmates, one bathroom', true),
  ('Studio', 7200, 'Small but all yours', false),
  ('One-bed flat', 9600, 'A proper bedroom door', false),
  ('Two-bed flat', 13200, 'Room for a guest or a study', false),
  ('Garden flat', 12000, 'A patch of grass to call your own', false),
  ('Loft apartment', 18000, 'Exposed brick and huge windows', false),
  ('Family house', 19200, 'Three bedrooms and a garden', false),
  ('Luxury apartment', 30000, 'Concierge, gym and a view', false),
];

/// Six homes to rent this year.
List<RentalListing> rentalListings(Life l) {
  final rng = Random(l.seed * 17 + l.age * 53 + 9);
  final mod = 100 + (l.worldMods['rent'] ?? 0);
  final kinds = List.of(_flatKinds)..shuffle(rng);
  // Always a cheap option: a room in a shared house.
  if (!kinds.take(6).any((k) => k.$4)) {
    kinds.insert(0, _flatKinds.first);
  }
  return [
    for (var i = 0; i < 6; i++)
      () {
        final (name, base, blurb, shared) = kinds[i];
        final area = areas.keys.elementAt(rng.nextInt(areas.length));
        final rent =
            (base *
                    areas[area]!.$1 *
                    mod /
                    100 *
                    (0.9 + rng.nextDouble() * 0.2) /
                    100)
                .round() *
            100;
        return (
          i: i,
          name: name,
          area: area,
          rent: rent,
          blurb: blurb,
          shared: shared,
          landlord: rng.nextInt(100) < 30 ? 'slow' : 'good',
        );
      }(),
  ];
}

String rentFlat(Life l, RentalListing f, Random rng) {
  final moving = leaveRental(l, rng);
  final deposit = (f.rent / 6).round();
  l.money -= deposit;
  l.flags['own_flat'] = Memory(l.age, 'your first flat');
  l.assets.add(
    Asset(
      id: 'flat${l.age}_${f.i}',
      kind: 'rental',
      name: f.name,
      value: 0,
      yearlyCost: f.rent,
      since: l.age,
      info: {
        'deposit': deposit,
        'area': f.area,
        'landlord': f.landlord,
        if (f.shared) 'shared': true,
      },
    ),
  );
  l.stats.add('happiness', 5);
  var mates = '';
  if (f.shared) {
    final a = meetFriend(l, rng, role: 'Flatmate', bond: 50, spread: 4);
    final b = meetFriend(l, rng, role: 'Flatmate', bond: 45, spread: 4);
    mates =
        ' Your flatmates are ${a.name.split(' ').first} and ${b.name.split(' ').first}.';
  }
  return 'You signed the lease on a ${f.name.toLowerCase()} in ${f.area}. Deposit ${_m(deposit)}, rent ${_m(f.rent)} a year.$mates$moving';
}

// ---------------- Remortgaging ----------------

/// How much more you could borrow against your home (75% loan to value).
int equityAvailable(Life l) {
  final home = homeOf(l);
  if (home == null) return 0;
  return max(0, (home.value * 0.75).round() - (l.debts['Mortgage'] ?? 0));
}

// ---------------- Scenes ----------------

Storylet? propertyScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'hunt_purpose':
      final home = homeOf(l);
      if (home == null) return null;
      final full = lettingsOf(l).length >= maxLets;
      return _scene(
        id,
        'You already own a ${home.name.toLowerCase()} in ${home.info['area'] ?? l.city}. What are you looking for?',
        [
          Choice(
            label: 'A new home to move into',
            outcome: '',
            risk: 'Then sell or let out the one you have',
            run: (l, rng) {
              l.marks.add('hunt:${l.age}:move');
              l.sceneQueue.insert(0, 'house_hunt');
              return 'You start looking for somewhere new to live.';
            },
          ),
          Choice(
            label: 'A home to let out',
            outcome: '',
            risk: '${lettingsOf(l).length} of $maxLets rentals owned',
            lock: (_) => full ? 'You own $maxLets rentals already' : null,
            run: (l, rng) {
              l.marks.add('hunt:${l.age}:let');
              l.sceneQueue.insert(0, 'house_hunt');
              return 'You start looking for a buy-to-let.';
            },
          ),
          Choice(label: 'Never mind', outcome: 'You closed the listings.'),
        ],
      );
    case 'old_home':
      final old = args.isEmpty ? null : _byId(l, args.first);
      if (old == null) return null;
      return _scene(
        id,
        'You have moved into your new home. What about the old ${old.name.toLowerCase()}, worth about ${_m(old.value)}?',
        [
          Choice(
            label: 'Sell it',
            outcome: '',
            risk: '3% agent fee · its mortgage is paid off',
            run: (l, rng) {
              final owed = letDebtShare(l, old);
              final fee = (old.value * 0.03).round();
              l.assets.remove(old);
              final left = (l.debts['Buy-to-let mortgage'] ?? 0) - owed;
              if (left > 0) {
                l.debts['Buy-to-let mortgage'] = left;
              } else {
                l.debts.remove('Buy-to-let mortgage');
                l.rates.remove('Buy-to-let mortgage');
              }
              l.money += old.value - fee - owed;
              return 'Sold. After the fee${owed > 0 ? ' and its mortgage' : ''}, ${_m(old.value - fee - owed)} landed in your account.';
            },
          ),
          Choice(
            label: 'Let it out',
            outcome: '',
            risk: 'Rent comes in · its mortgage becomes a buy-to-let',
            lock: (l) => lettingsOf(l).length > maxLets
                ? 'You own $maxLets rentals already'
                : null,
            run: (l, rng) {
              l.sceneQueue.insert(0, 'let_pick:${old.id}');
              return 'You are a landlord now. Time to find a tenant.';
            },
          ),
        ],
      );
    case 'let_pick':
      final a = args.isEmpty ? null : _byId(l, args.first);
      if (a == null || !isVacant(a)) return null;
      return _scene(
        id,
        'Your ${a.name.toLowerCase()} in ${a.info['area']} is empty. Three people want to rent it at ${_m(rentFor(a))} a year.',
        [
          for (final (k, t) in _applicants(l, a))
            Choice(
              label: '${t['name']} · ${tenantKinds[k]!.label}',
              outcome: '',
              risk: tenantKinds[k]!.hint,
              run: (l, rng) {
                a.info['tenant'] = t;
                l.marks.remove('void:${l.age}:${a.id}');
                if (k == 'charmer') l.money += rentFor(a) ~/ 2;
                return '${(t['name'] as String).split(' ').first} moved in${k == 'charmer' ? ' and handed you six months\' rent in an envelope' : ''}.';
              },
            ),
          Choice(
            label: 'Let an agent choose',
            outcome: '',
            risk: 'They take 12% of the rent and handle problems',
            run: (l, rng) {
              a.info['agent'] = true;
              final t = _applicants(l, a).first.$2;
              a.info['tenant'] = t;
              l.marks.remove('void:${l.age}:${a.id}');
              return 'The agent picked ${t['name']}. From now on they deal with the tenants.';
            },
          ),
          Choice(
            label: 'Leave it empty for now',
            outcome: 'No rent, but no headaches either.',
          ),
        ],
      );
    case 'let_trouble':
      if (args.length < 2) return null;
      final a = _byId(l, args[0]);
      final t = a == null ? null : tenantOf(a);
      if (a == null || t == null) return null;
      final who = (t['name'] as String).split(' ').first;
      if (args[1] == 'unpaid') {
        return _scene(
          id,
          '$who has stopped paying the rent on your ${a.name.toLowerCase()}. Three months behind and not answering the phone.',
          [
            Choice(
              label: 'Give them time',
              outcome: '',
              risk: 'They might catch up, or not',
              run: (l, rng) {
                if (rng.nextInt(100) < 55) {
                  return '$who lost their job and was embarrassed. They paid it all back within the year.';
                }
                l.marks.add('late_rent:${l.age}:${a.id}');
                return '$who never caught up. You lost half the year\'s rent.';
              },
            ),
            Choice(
              label: 'Evict them (\$2,500 in legal costs)',
              outcome: '',
              needsMoney: 2500,
              run: (l, rng) {
                l.money -= 2500;
                a.info['tenant'] = null;
                l.marks.add('void:${l.age}:${a.id}');
                l.stats.add('karma', -2);
                return 'Court papers, bailiffs, and an empty home at the end of it. You need a new tenant.';
              },
            ),
            Choice(
              label: 'Hire a letting agent to deal with it',
              outcome: '',
              risk: '12% of the rent from now on',
              run: (l, rng) {
                a.info['agent'] = true;
                l.marks.add('late_rent:${l.age}:${a.id}');
                return 'The agent sent letters with the right words on them. Half the arrears came back.';
              },
            ),
          ],
        );
      }
      final cost = (a.value * 0.006).round().clamp(600, 6000);
      return _scene(
        id,
        '$who says the boiler at your ${a.name.toLowerCase()} has broken, in the middle of winter.',
        [
          Choice(
            label: 'Fix it properly (${_m(cost)})',
            outcome: '',
            needsMoney: cost,
            run: (l, rng) {
              l.money -= cost;
              a.condition = min(100, a.condition + 8);
              return 'A new boiler went in the next day. $who sent a thank-you card.';
            },
          ),
          Choice(
            label: 'Patch it cheaply (${_m(cost ~/ 4)})',
            outcome: '',
            risk: 'It might break again',
            run: (l, rng) {
              l.money -= cost ~/ 4;
              a.condition = max(0, a.condition - 5);
              return 'Your mate Gary had a go. It works, mostly.';
            },
          ),
          Choice(
            label: 'Ignore it',
            outcome: '',
            risk: 'They may leave',
            run: (l, rng) {
              l.stats.add('karma', -3);
              if (rng.nextInt(100) < 60) {
                a.info['tenant'] = null;
                return '$who moved out in February, telling everyone why. The home is empty.';
              }
              a.condition = max(0, a.condition - 10);
              return '$who bought a heater and stopped speaking to you.';
            },
          ),
        ],
      );
    case 'let_list':
      final lets = lettingsOf(l);
      if (lets.isEmpty) return null;
      return _scene(id, 'Your rentals: ${lets.length} of $maxLets.', [
        for (final a in lets)
          Choice(
            label: '${a.name} · ${a.info['area'] ?? ''}',
            outcome: '',
            risk: isVacant(a)
                ? 'Empty'
                : '${tenantOf(a)?['name'] ?? 'Tenants'} · ${_m(rentIncome(l, a))} a year',
            run: (l, rng) {
              l.sceneQueue.insert(0, 'let_manage:${a.id}');
              return 'You open the file on your ${a.name.toLowerCase()}.';
            },
          ),
        Choice(label: 'Done', outcome: 'You closed the folder.'),
      ]);
    case 'let_manage':
      final a = args.isEmpty ? null : _byId(l, args.first);
      if (a == null) return null;
      final t = tenantOf(a);
      final level = rentLevelOf(a);
      final agent = a.info['agent'] == true;
      Choice setRent(String to) => Choice(
        label: 'Set ${rentLevels[to]!.$1.toLowerCase()}',
        outcome: '',
        risk: switch (to) {
          'low' => 'Tenants stay longer',
          'high' => 'More money · tenants leave sooner',
          _ => 'What similar homes charge',
        },
        run: (l, rng) {
          a.info['rentLevel'] = to;
          return 'Rent on the ${a.name.toLowerCase()} is now ${_m(rentFor(a))} a year.';
        },
      );
      return _scene(
        id,
        '${a.name} in ${a.info['area']}. ${isVacant(a)
            ? 'Empty.'
            : t == null
            ? 'Let to tenants.'
            : 'Tenant: ${t['name']} (${tenantKinds[t['kind']]?.label.toLowerCase() ?? 'tenant'}), since age ${t['since']}.'} ${rentLevels[level]!.$1}: ${_m(rentFor(a))} a year. ${agent ? 'A letting agent manages it.' : 'You manage it yourself.'} Condition ${a.condition}%.',
        [
          if (isVacant(a))
            Choice(
              label: 'Find a tenant',
              outcome: '',
              run: (l, rng) {
                l.sceneQueue.insert(0, 'let_pick:${a.id}');
                return 'You put the advert up.';
              },
            ),
          for (final to in rentLevels.keys)
            if (to != level) setRent(to),
          Choice(
            label: agent ? 'Let the agent go' : 'Hire a letting agent',
            outcome: '',
            risk: agent
                ? 'Keep all the rent · deal with problems yourself'
                : '12% of the rent · they find tenants and handle problems',
            run: (l, rng) {
              a.info['agent'] = !agent;
              return agent
                  ? 'You took the keys back from the agent.'
                  : 'The agent took the keys and a copy of the tenancy agreement.';
            },
          ),
          if (t != null)
            Choice(
              label: 'Give the tenant notice',
              outcome: '',
              risk: 'The home will be empty until you find someone',
              run: (l, rng) {
                a.info['tenant'] = null;
                l.stats.add('karma', -1);
                return '${(t['name'] as String).split(' ').first} packed up and left. The keys are on the counter.';
              },
            ),
          Choice(label: 'Done', outcome: 'You closed the file.'),
        ],
      );
    case 'remortgage':
      final home = homeOf(l);
      if (home == null) return null;
      final avail = equityAvailable(l);
      final owed = l.debts['Mortgage'] ?? 0;
      final rate = mortgageRate(l);
      final current = l.rates['Mortgage'];
      Choice release(int amount) => Choice(
        label: 'Borrow ${_m(amount)} against your home',
        outcome: '',
        risk:
            'Rate ${(rate * 100).toStringAsFixed(1)}% · added to your mortgage',
        run: (l, rng) {
          l.money += amount - 1000;
          l.debts['Mortgage'] = owed + amount;
          final weighted = owed == 0
              ? rate
              : ((current ?? rate) * owed + rate * amount) / (owed + amount);
          l.rates['Mortgage'] = weighted;
          return 'The bank released ${_m(amount)} (less a ${_m(1000)} fee). Your mortgage is now ${_m(owed + amount)}.';
        },
      );
      return _scene(
        id,
        'Your ${home.name.toLowerCase()} is worth about ${_m(home.value)}. You owe ${_m(owed)}${current == null ? '' : ' at ${(current * 100).toStringAsFixed(1)}%'}. Banks lend up to 75% of a home\'s value; today\'s rate for you is ${(rate * 100).toStringAsFixed(1)}%.',
        [
          if (avail >= 10000) release(min(avail, 10000)),
          if (avail >= 40000) release(min(avail, 40000)),
          if (avail > 40000) release(avail),
          if (owed > 0 && current != null && current - rate >= 0.005)
            Choice(
              label: 'Switch to the better rate (\$1,000 fee)',
              outcome: '',
              risk:
                  '${(current * 100).toStringAsFixed(1)}% → ${(rate * 100).toStringAsFixed(1)}%',
              needsMoney: 1000,
              run: (l, rng) {
                l.money -= 1000;
                l.rates['Mortgage'] = rate;
                return 'New deal signed. Your payments drop from next year.';
              },
            ),
          Choice(label: 'Leave it as it is', outcome: 'You kept your deal.'),
        ],
      );
    case 'landlord_rise':
      final flat = l.assets.where((a) => a.kind == 'rental').firstOrNull;
      if (flat == null) return null;
      final rise = (flat.yearlyCost * 0.1 / 100).round() * 100;
      return _scene(
        id,
        'A letter from your landlord: the rent on your ${flat.name.toLowerCase()} goes up by ${_m(rise)} a year.',
        [
          Choice(
            label: 'Accept it',
            outcome: '',
            run: (l, rng) {
              flat.yearlyCost += rise;
              return 'You signed the new agreement. Rent ${_m(flat.yearlyCost)} a year.';
            },
          ),
          Choice(
            label: 'Negotiate',
            outcome: '',
            risk: 'Charisma helps',
            run: (l, rng) {
              if (rng.nextInt(100) < 35 + (l.stats['charisma'] - 50) ~/ 2) {
                flat.yearlyCost += rise ~/ 2;
                return 'You reminded them you always pay on time. They met you halfway.';
              }
              flat.yearlyCost += rise;
              return 'They would not budge. Rent ${_m(flat.yearlyCost)} a year.';
            },
          ),
          Choice(
            label: 'Look for somewhere else',
            outcome: '',
            run: (l, rng) {
              l.sceneQueue.insert(0, 'flat_hunt');
              return 'You start scrolling rentals again.';
            },
          ),
        ],
      );
    case 'landlord_sells':
      final flat = l.assets.where((a) => a.kind == 'rental').firstOrNull;
      if (flat == null) return null;
      return _scene(
        id,
        'Your landlord is selling the ${flat.name.toLowerCase()}. You have two months to find somewhere else.',
        [
          Choice(
            label: 'Find a new place',
            outcome: '',
            run: (l, rng) {
              l.sceneQueue.insert(0, 'flat_hunt');
              return 'Boxes everywhere. You start looking.';
            },
          ),
          Choice(
            label: 'Move back in with family',
            outcome: '',
            run: (l, rng) {
              final note = leaveRental(l, rng);
              l.stats.add('happiness', -4);
              return 'Your old bedroom, your old posters.$note';
            },
          ),
        ],
      );
  }
  return null;
}

final propertyActions = <GameAction>[
  GameAction(
    id: 'manage_rentals',
    label: 'Manage your rentals',
    category: 'Assets',
    priceNote: 'Tenants, rent levels and letting agents',
    keywords: ['landlord', 'tenant', 'rental', 'let', 'buy to let', 'rent'],
    minAge: 18,
    extraCheck: (l) =>
        lettingsOf(l).isEmpty ? 'You do not let out any homes' : null,
    run: (l, rng) {
      l.sceneQueue.add('let_list');
      return ActionResult('You open your landlord folder.');
    },
  ),
  GameAction(
    id: 'remortgage',
    label: 'Remortgage your home',
    category: 'Assets',
    priceNote: 'Borrow against your home, or switch to a better rate',
    keywords: ['remortgage', 'equity', 'mortgage', 'borrow', 'rate'],
    minAge: 21,
    extraCheck: (l) => homeOf(l) == null
        ? 'Needs a home you own'
        : loansBlocked(l)
        ? 'No loans for 7 years after bankruptcy'
        : creditOf(l) < 580
        ? 'Needs Fair credit (580+)'
        : l.salary <= 0 && l.pension <= 0 && l.business == null
        ? 'Needs an income'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('remortgage');
      return ActionResult('You book a meeting with the bank.');
    },
  ),
];
