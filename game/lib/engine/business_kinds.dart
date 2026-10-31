import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'storylet.dart';

// What makes each kind of business its own: who you are in it, the
// upgrades that fit the trade, one signature move a year, and the events
// that only happen in that line of work.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

/// A one-off upgrade. [demand] adds customers every year (0.08 = 8%),
/// [savings] cuts the cost of materials, the rest change the meters once.
typedef BizPerk = ({
  String id,
  String label,
  String blurb,
  int cost,
  double demand,
  double savings,
  int quality,
  int brand,
  int satisfaction,
});

BizPerk _perk(
  String id,
  String label,
  String blurb,
  int cost, {
  double demand = 0,
  double savings = 0,
  int quality = 0,
  int brand = 0,
  int satisfaction = 0,
}) => (
  id: id,
  label: label,
  blurb: blurb,
  cost: cost,
  demand: demand,
  savings: savings,
  quality: quality,
  brand: brand,
  satisfaction: satisfaction,
);

/// The once-a-year move only this trade has.
typedef BizSignature = ({
  String label,
  String detail,
  int cost,
  String Function(Life l, Business b, Random rng) run,
});

/// Everything specific to one kind of business.
typedef BizKind = ({
  String blurb,
  String role,
  List<BizPerk> perks,
  BizSignature signature,
  List<String> events,
});

int _clamp(int v) => v.clamp(0, 100);

void _bump(
  Business b, {
  int quality = 0,
  int brand = 0,
  int satisfaction = 0,
  int morale = 0,
}) {
  b
    ..quality = _clamp(b.quality + quality)
    ..brand = _clamp(b.brand + brand)
    ..satisfaction = _clamp(b.satisfaction + satisfaction)
    ..morale = _clamp(b.morale + morale);
}

final bizKinds = <String, BizKind>{
  'cafe': (
    blurb: 'Regulars, coffee and atmosphere. Charisma brings people back.',
    role: 'owner and head barista',
    perks: [
      _perk(
        'espresso',
        'A better espresso machine',
        'Quality +10, more customers',
        20000,
        quality: 10,
        demand: 0.05,
      ),
      _perk(
        'terrace',
        'Outdoor seating',
        'About 8% more customers',
        15000,
        demand: 0.08,
      ),
      _perk(
        'loyalty',
        'A loyalty card app',
        'Customers +10, brand +5',
        8000,
        satisfaction: 10,
        brand: 5,
      ),
    ],
    signature: (
      label: 'Host a latte-art night',
      detail: '\$2,000 · brand and customers up',
      cost: 2000,
      run: (l, b, rng) {
        _bump(b, brand: 8, satisfaction: 5, morale: 4);
        return 'Baristas battled with milk jugs while a DJ played. Half the street came in, and some never left.';
      },
    ),
    events: ['cafe_inspection', 'cafe_chain'],
  ),
  'bakery': (
    blurb: 'Early mornings and the smell of bread. Creativity sells.',
    role: 'owner and head baker',
    perks: [
      _perk(
        'deck_oven',
        'A stone-deck oven',
        'Quality +12',
        25000,
        quality: 12,
      ),
      _perk(
        'wholesale',
        'Supply local cafés',
        'About 10% more sales',
        10000,
        demand: 0.10,
      ),
      _perk(
        'wedding_cakes',
        'A wedding-cake service',
        'More sales, brand +5',
        8000,
        demand: 0.06,
        brand: 5,
      ),
    ],
    signature: (
      label: 'Bake a showpiece for the window',
      detail: '\$1,500 · brand and quality up',
      cost: 1500,
      run: (l, b, rng) {
        _bump(b, brand: 6, quality: 3);
        return 'A sugar replica of the town hall filled the window. People photographed it all week.';
      },
    ),
    events: ['bakery_oven', 'bakery_flour'],
  ),
  'restaurant': (
    blurb: 'Big rent, big staff, big rewards. Creativity runs the kitchen.',
    role: 'owner and head chef',
    perks: [
      _perk(
        'head_chef',
        'Hire a star head chef',
        'Quality +15',
        30000,
        quality: 15,
      ),
      _perk(
        'wine_list',
        'A proper wine list',
        'About 6% more spend',
        15000,
        demand: 0.06,
      ),
      _perk(
        'private_room',
        'A private dining room',
        'About 10% more bookings',
        35000,
        demand: 0.10,
      ),
    ],
    signature: (
      label: 'Run a tasting-menu week',
      detail: '\$6,000 · quality and brand up',
      cost: 6000,
      run: (l, b, rng) {
        _bump(b, quality: 5, brand: 8, morale: -3);
        return 'Twelve courses a night for a week. The kitchen was exhausted; the reviews were not.';
      },
    ),
    events: ['restaurant_critic', 'restaurant_fire'],
  ),
  'food_truck': (
    blurb: 'Low rent, long days, go where the crowds are.',
    role: 'owner and cook',
    perks: [
      _perk(
        'second_truck',
        'A second truck',
        'About 25% more sales',
        25000,
        demand: 0.25,
      ),
      _perk(
        'app_orders',
        'Order-ahead app',
        'More sales, customers +5',
        3000,
        demand: 0.05,
        satisfaction: 5,
      ),
      _perk(
        'festival_licence',
        'A festival trading licence',
        'About 8% more sales',
        5000,
        demand: 0.08,
      ),
    ],
    signature: (
      label: 'Park at a music festival',
      detail: '\$3,000 pitch fee · a big boost this year',
      cost: 3000,
      run: (l, b, rng) {
        b.boost += 15;
        _bump(b, brand: 4);
        return 'Three days, forty thousand hungry people and a queue that never ended. You slept in the truck.';
      },
    ),
    events: ['truck_permit', 'truck_viral'],
  ),
  'app': (
    blurb: 'Expensive engineers, huge upside. Smarts ships good software.',
    role: 'founder and CEO',
    perks: [
      _perk(
        'designer',
        'Hire a top designer',
        'Quality +12',
        15000,
        quality: 12,
      ),
      _perk(
        'cloud',
        'Move to better cloud servers',
        'Running costs down',
        20000,
        savings: 0.05,
        satisfaction: 5,
      ),
      _perk(
        'store_ads',
        'App-store advertising',
        'Brand +15, more downloads',
        10000,
        brand: 15,
        demand: 0.05,
      ),
    ],
    signature: (
      label: 'Ship a big update',
      detail: '\$15,000 · quality up, if it works',
      cost: 15000,
      run: (l, b, rng) {
        if (rng.nextInt(100) < 75) {
          _bump(b, quality: 8, satisfaction: 4);
          return 'Version 2.0 went out on a Tuesday. The reviews called it "finally good".';
        }
        _bump(b, satisfaction: -8, morale: -5);
        return 'The update broke logins for a day. The team fixed it by morning, but the one-star reviews stayed.';
      },
    ),
    events: ['app_breach', 'app_buyout'],
  ),
  'games': (
    blurb: 'Hits pay for years; flops sink studios. Creativity makes the game.',
    role: 'studio head and lead designer',
    perks: [
      _perk(
        'engine',
        'Licence a game engine',
        'Quality +8, costs down',
        10000,
        quality: 8,
        savings: 0.05,
      ),
      _perk(
        'publisher',
        'Sign a publishing deal',
        'About 12% more sales',
        20000,
        demand: 0.12,
      ),
      _perk(
        'esports',
        'Sponsor an esports team',
        'Brand +15',
        15000,
        brand: 15,
      ),
    ],
    signature: (
      label: 'Show a demo at a games expo',
      detail: '\$12,000 · brand up',
      cost: 12000,
      run: (l, b, rng) {
        _bump(b, brand: 12, morale: 3);
        return 'The queue for your demo wrapped round the hall. A famous streamer played it live.';
      },
    ),
    events: ['games_crunch', 'games_launch'],
  ),
  'clothing': (
    blurb: 'Seasons, trends and margins. Creativity sets the style.',
    role: 'founder and creative director',
    perks: [
      _perk(
        'factory',
        'Your own factory',
        'Materials 12% cheaper',
        60000,
        savings: 0.12,
      ),
      _perk(
        'collab',
        'A celebrity collaboration',
        'Brand +20',
        30000,
        brand: 20,
      ),
      _perk(
        'webshop',
        'An online shop',
        'About 10% more sales',
        10000,
        demand: 0.10,
      ),
    ],
    signature: (
      label: 'Drop a limited collection',
      detail: '\$10,000 · brand up and a boost this year',
      cost: 10000,
      run: (l, b, rng) {
        b.boost += 10;
        _bump(b, brand: 10);
        return 'Two hundred pieces, numbered. They sold out in nine minutes and appeared on resale sites at triple the price.';
      },
    ),
    events: ['clothing_fashion_week', 'clothing_sweatshop'],
  ),
  'gym': (
    blurb: 'Memberships and motivation. Athleticism sets the standard.',
    role: 'owner and head trainer',
    perks: [
      _perk('equipment', 'New equipment', 'Quality +12', 30000, quality: 12),
      _perk(
        'trainers',
        'Personal trainers',
        'More members, customers +5',
        15000,
        demand: 0.08,
        satisfaction: 5,
      ),
      _perk(
        'sauna',
        'A sauna and pool',
        'About 12% more members, customers +10',
        60000,
        demand: 0.12,
        satisfaction: 10,
      ),
    ],
    signature: (
      label: 'Run a 30-day challenge',
      detail: '\$2,000 · customers and brand up',
      cost: 2000,
      run: (l, b, rng) {
        _bump(b, satisfaction: 8, brand: 5);
        l.stats.add('health', 2);
        return 'Two hundred members, one leaderboard and you training alongside them. Before-and-after photos covered a wall.';
      },
    ),
    events: ['gym_january', 'gym_injury'],
  ),
  'salon': (
    blurb: 'Loyal clients and word of mouth. Looks and taste matter.',
    role: 'owner and senior stylist',
    perks: [
      _perk(
        'product_line',
        'Your own product line',
        'About 8% more sales',
        12000,
        demand: 0.08,
      ),
      _perk(
        'nail_bar',
        'A nail bar',
        'About 10% more sales',
        15000,
        demand: 0.10,
      ),
      _perk('booking', 'Online booking', 'Customers +8', 4000, satisfaction: 8),
    ],
    signature: (
      label: 'Style a bridal party',
      detail: 'Free · earns about \$3,000',
      cost: 0,
      run: (l, b, rng) {
        l.money += 3000;
        _bump(b, satisfaction: 6, brand: 3);
        return 'Seven bridesmaids, one nervous bride and a 5am start. Everyone cried at the right moments.';
      },
    ),
    events: ['salon_celebrity', 'salon_allergy'],
  ),
  'cleaning': (
    blurb: 'Cheap to start, grows with contracts. Discipline keeps it tidy.',
    role: 'owner and operations manager',
    perks: [
      _perk(
        'eco',
        'Eco-friendly products',
        'Brand +8, costs down',
        5000,
        brand: 8,
        savings: 0.03,
      ),
      _perk(
        'vans',
        'Vans with your logo',
        'Brand +10, more work',
        20000,
        brand: 10,
        demand: 0.06,
      ),
      _perk(
        'contracts_team',
        'A commercial contracts team',
        'About 12% more work',
        15000,
        demand: 0.12,
      ),
    ],
    signature: (
      label: 'Pitch for an office contract',
      detail: 'Free · might win a big boost this year',
      cost: 0,
      run: (l, b, rng) {
        if (rng.nextInt(100) < 50 + b.brand ~/ 4) {
          b.boost += 20;
          return 'You won the contract: six office floors, five nights a week.';
        }
        return 'They went with a bigger firm. You asked for feedback and wrote it all down.';
      },
    ),
    events: ['cleaning_find', 'cleaning_staff'],
  ),
  'construction': (
    blurb: 'Big contracts, big costs. Discipline keeps jobs on time.',
    role: 'owner and site manager',
    perks: [
      _perk(
        'machinery',
        'Your own machinery',
        'Materials 8% cheaper',
        50000,
        savings: 0.08,
      ),
      _perk(
        'architect',
        'Partner with an architect',
        'Quality +10, more work',
        20000,
        quality: 10,
        demand: 0.06,
      ),
      _perk(
        'safety',
        'Safety certification',
        'Customers +10',
        8000,
        satisfaction: 10,
      ),
    ],
    signature: (
      label: 'Bid on a council contract',
      detail: '\$5,000 bid costs · might win a big boost',
      cost: 5000,
      run: (l, b, rng) {
        if (rng.nextInt(100) < 35 + b.quality ~/ 4) {
          b.boost += 30;
          _bump(b, brand: 5);
          return 'You won: a new school, eighteen months of work and your sign on the hoardings.';
        }
        return 'The contract went to a firm with "connections". The bid costs are gone.';
      },
    ),
    events: ['construction_delay', 'construction_bribe'],
  ),
  'podcast': (
    blurb: 'Cheap to start, lives on its audience. Charisma is the show.',
    role: 'host and producer',
    perks: [
      _perk('gear', 'Pro studio gear', 'Quality +10', 8000, quality: 10),
      _perk(
        'video',
        'A video channel',
        'About 12% more listeners',
        6000,
        demand: 0.12,
      ),
      _perk(
        'ad_network',
        'Join an ad network',
        'About 8% more income',
        5000,
        demand: 0.08,
      ),
    ],
    signature: (
      label: 'Book a famous guest',
      detail: '\$5,000 · brand up',
      cost: 5000,
      run: (l, b, rng) {
        _bump(b, brand: 15);
        return 'A film star talked for three hours and said one thing that became a headline. Downloads tripled that week.';
      },
    ),
    events: ['podcast_sponsor', 'podcast_cancel'],
  ),
};

BizKind? kindOf(Business b) => bizKinds[b.industry];

/// Extra customers and cheaper materials from the upgrades bought.
(double, double) perkEffects(Business b) {
  var demand = 0.0;
  var savings = 0.0;
  for (final p in kindOf(b)?.perks ?? const <BizPerk>[]) {
    if (b.perks.contains(p.id)) {
      demand += p.demand;
      savings += p.savings;
    }
  }
  return (demand, savings);
}

String? perkLock(Life l, BizPerk p) {
  final b = l.business;
  if (b == null) return 'No business';
  if (b.perks.contains(p.id)) return 'Done';
  if (l.money < p.cost) return 'Needs ${_m(p.cost)}';
  return null;
}

ActionResult buyPerk(Life l, BizPerk p) {
  final b = l.business!;
  l.money -= p.cost;
  b.perks.add(p.id);
  _bump(b, quality: p.quality, brand: p.brand, satisfaction: p.satisfaction);
  return ActionResult('${b.name}: ${p.label.toLowerCase()} is in.', [
    'Money −${_m(p.cost)}',
    p.blurb,
  ]);
}

String _sigKey(Business b) => 'biz_signature@${b.name}';

String? signatureLock(Life l) {
  final b = l.business;
  final k = b == null ? null : kindOf(b);
  if (b == null || k == null) return 'No business';
  if (l.usedActions.contains(_sigKey(b))) return 'Done this year';
  if (l.money < k.signature.cost) return 'Needs ${_m(k.signature.cost)}';
  return null;
}

ActionResult runSignature(Life l, Random rng) {
  final b = l.business!;
  final s = kindOf(b)!.signature;
  l.usedActions.add(_sigKey(b));
  l.money -= s.cost;
  final text = s.run(l, b, rng);
  return ActionResult(text, [if (s.cost > 0) 'Money −${_m(s.cost)}']);
}

// ---------------- Trade events ----------------

/// About one year in four, something that only happens in your trade.
void maybeTradeEvent(Life l, Business b, Random rng) {
  final k = kindOf(b);
  if (k == null || rng.nextInt(100) >= 25) return;
  if (l.sceneQueue.any((s) => s.startsWith('biz_event:'))) return;
  l.sceneQueue.add(
    'biz_event:${k.events[rng.nextInt(k.events.length)]}:${b.name}',
  );
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:biz_event',
  text: text,
  category: 'money',
  scene: true,
  choices: choices,
);

Choice _c(
  String label,
  String Function(Life l, Business b, Random rng) run, {
  String? risk,
  int needsMoney = 0,
  required Business b,
}) => Choice(
  label: label,
  outcome: '',
  risk: risk,
  needsMoney: needsMoney,
  run: (l, rng) {
    final text = run(l, b, rng);
    return '${b.name}: $text';
  },
);

/// args: event id, then the business name.
Storylet? tradeEventScene(List<String> args, Life l) {
  if (args.length < 2) return null;
  final name = args.sublist(1).join(':');
  final b = l.businesses.where((x) => x.name == name).firstOrNull;
  if (b == null) return null;
  Choice c(
    String label,
    String Function(Life l, Business b, Random rng) run, {
    String? risk,
    int needsMoney = 0,
  }) => _c(label, run, risk: risk, needsMoney: needsMoney, b: b);
  bool odds(Random rng, int p) => rng.nextInt(100) < p;

  return switch (args.first) {
    'cafe_inspection' => _scene(
      'cafe_inspection',
      'A food-safety inspector walked into ${b.name} unannounced, clipboard first.',
      [
        c('Show them everything', (l, b, rng) {
          if (b.quality >= 50 || odds(rng, 60)) {
            _bump(b, brand: 4);
            return 'Five stars on the hygiene rating. You framed it.';
          }
          _bump(b, satisfaction: -6);
          l.money -= 2000;
          return 'A dirty milk steamer cost you a fine of ${_m(2000)} and a two-star rating.';
        }),
        c('Offer them a free coffee and a pastry', (l, b, rng) {
          _bump(b, brand: -2);
          return 'They declined, wrote "attempted inducement" in small letters, and passed you anyway.';
        }, risk: 'They might not like that'),
      ],
    ),
    'cafe_chain' => _scene(
      'cafe_chain',
      'A big coffee chain is opening across the road from ${b.name}.',
      [
        c('Lean into being local', (l, b, rng) {
          _bump(b, brand: 6, satisfaction: 4);
          return 'A "Keep it independent" sign and names on every cup. Your regulars stayed loyal.';
        }),
        c('Cut prices to compete', (l, b, rng) {
          b.boost += 5;
          _bump(b, morale: -4);
          return 'Cheaper coffee kept the queue, if not the margins.';
        }),
      ],
    ),
    'bakery_oven' => _scene(
      'bakery_oven',
      'At 4am the main oven at ${b.name} died with two hundred loaves inside.',
      [
        c('Pay for an emergency repair (${_m(4000)})', (l, b, rng) {
          l.money -= 4000;
          return 'The engineer came by six. You opened late but full.';
        }, needsMoney: 4000),
        c('Bake what you can in the small oven', (l, b, rng) {
          _bump(b, satisfaction: -5, morale: -3);
          b.boost -= 5;
          return 'Half-empty shelves for a week. Some regulars found another bakery.';
        }),
      ],
    ),
    'bakery_flour' => _scene(
      'bakery_flour',
      'Flour prices doubled overnight after a bad harvest.',
      [
        c('Raise your prices', (l, b, rng) {
          _bump(b, satisfaction: -4);
          return 'Customers grumbled at the new prices, but mostly paid.';
        }),
        c('Swallow the cost', (l, b, rng) {
          l.money -= 3000;
          _bump(b, satisfaction: 3);
          return 'You paid the difference yourself. Nobody noticed, which was the point.';
        }),
      ],
    ),
    'restaurant_critic' => _scene(
      'restaurant_critic',
      'A waiter whispers: the famous restaurant critic is at table six.',
      [
        c('Cook it yourself', (l, b, rng) {
          if (odds(rng, 35 + b.quality ~/ 2)) {
            b.boost += 15;
            _bump(b, brand: 15);
            return 'The review called it "the best meal in the city". You were booked for months.';
          }
          _bump(b, brand: -8);
          return 'The review said "competent". In a critic\'s language, that is an insult.';
        }),
        c('Send out everything on the menu', (l, b, rng) {
          _bump(b, brand: 4);
          return 'The critic called it "generous but exhausting". It still brought people in.';
        }),
      ],
    ),
    'restaurant_fire' => _scene(
      'restaurant_fire',
      'A pan caught fire in the kitchen of ${b.name}. It is out, but the extractor is ruined.',
      [
        c('Close for a week and fix it properly', (l, b, rng) {
          l.money -= 8000;
          b.boost -= 5;
          return 'A new extractor and a week of lost takings: ${_m(8000)}.';
        }),
        c('Patch it and keep cooking', (l, b, rng) {
          if (odds(rng, 70)) return 'It held. You hope it keeps holding.';
          _bump(b, satisfaction: -10, brand: -6);
          l.money -= 15000;
          return 'It failed during a busy Saturday. The fire brigade came and so did the local paper.';
        }, risk: 'It might hold'),
      ],
    ),
    'truck_permit' => _scene(
      'truck_permit',
      'The council changed the rules: your best pitch for ${b.name} now needs a new permit.',
      [
        c('Pay for the permit (${_m(2500)})', (l, b, rng) {
          l.money -= 2500;
          return 'Back in your spot by the station with the paperwork taped to the window.';
        }, needsMoney: 2500),
        c('Find a new spot', (l, b, rng) {
          if (odds(rng, 50)) {
            b.boost += 5;
            return 'The new spot by the university was even better.';
          }
          b.boost -= 10;
          return 'The new spot was quiet. Very quiet.';
        }),
      ],
    ),
    'truck_viral' => _scene(
      'truck_viral',
      'A video of your food went viral overnight. There is a queue round the block.',
      [
        c('Work through the night', (l, b, rng) {
          b.boost += 15;
          _bump(b, brand: 8, morale: -6);
          return 'You sold out three times. Everyone needs a holiday now.';
        }),
        c('Keep normal hours and make people wait', (l, b, rng) {
          _bump(b, brand: 10);
          return 'The wait became part of the legend.';
        }),
      ],
    ),
    'app_breach' => _scene(
      'app_breach',
      'A security researcher found that ${b.name}\'s app was leaking user emails.',
      [
        c('Tell users and fix it today', (l, b, rng) {
          l.money -= 10000;
          _bump(b, satisfaction: -3, brand: 2);
          return 'You emailed every user and fixed it by midnight. People respected the honesty.';
        }),
        c('Fix it quietly', (l, b, rng) {
          if (odds(rng, 55)) return 'Nobody ever found out.';
          l.money -= 40000;
          _bump(b, brand: -15, satisfaction: -10);
          return 'A journalist found out. The fine was ${_m(40000)} and the headlines were worse.';
        }, risk: 'If it comes out, it is worse'),
      ],
    ),
    'app_buyout' => () {
      final offer = max(200000, l.valueOfBusiness(b) * 2);
      return _scene(
        'app_buyout',
        'A tech giant wants to buy ${b.name} for ${_m(offer)}.',
        [
          Choice(
            label: 'Sell',
            outcome: '',
            run: (l, rng) {
              l.money += offer;
              l.businesses.remove(b);
              l.bizFocus = 0;
              l.flags['sold_business'] = Memory(l.age, 'selling ${b.name}');
              l.stats.add('happiness', 8);
              return 'You signed. ${_m(offer)} landed in your account and a hoodie with their logo arrived the next day.';
            },
          ),
          c('Turn them down', (l, b, rng) {
            _bump(b, morale: 6, brand: 5);
            return 'The team cheered. Now you have to prove them right.';
          }),
        ],
      );
    }(),
    'games_crunch' => _scene(
      'games_crunch',
      'Launch is in six weeks and ${b.name}\'s game is not ready.',
      [
        c('Crunch: everyone works weekends', (l, b, rng) {
          _bump(b, quality: 6, morale: -15);
          return 'The game shipped on time. Two of your best people quit afterwards.';
        }),
        c('Delay the launch', (l, b, rng) {
          b.boost -= 10;
          _bump(b, quality: 8, morale: 4);
          return '"A delayed game is eventually good," you told the fans. Some believed you.';
        }),
      ],
    ),
    'games_launch' => _scene(
      'games_launch',
      'Launch day for ${b.name}\'s new game. The reviews are coming in.',
      [
        c('Watch the reviews live', (l, b, rng) {
          if (odds(rng, 30 + b.quality ~/ 2)) {
            b.boost += 25;
            _bump(b, brand: 15);
            return 'It was a hit: "Overwhelmingly positive". The servers struggled all weekend.';
          }
          b.boost -= 10;
          _bump(b, brand: -5);
          return 'Mixed reviews and a bug that let players walk through walls. Patch notes are being written.';
        }),
      ],
    ),
    'clothing_fashion_week' => _scene(
      'clothing_fashion_week',
      'Fashion week organisers offered ${b.name} a slot on the runway.',
      [
        c('Put on a show (${_m(25000)})', (l, b, rng) {
          l.money -= 25000;
          if (odds(rng, 45 + b.quality ~/ 3)) {
            _bump(b, brand: 20);
            b.boost += 15;
            return 'The front row stood up. Buyers from three department stores called the next morning.';
          }
          _bump(b, brand: 3);
          return 'Polite applause. A fashion writer called it "safe".';
        }, needsMoney: 25000),
        c(
          'Not this season',
          (l, b, rng) => 'You watched from the back row and took notes.',
        ),
      ],
    ),
    'clothing_sweatshop' => _scene(
      'clothing_sweatshop',
      'A reporter is asking about the factory that makes ${b.name}\'s clothes.',
      [
        c('Audit your suppliers and switch if needed', (l, b, rng) {
          l.money -= 12000;
          _bump(b, brand: 6);
          l.stats.add('karma', 3);
          return 'You moved production to a certified factory. It cost more and you sleep better.';
        }),
        c('Decline to comment', (l, b, rng) {
          if (odds(rng, 50)) return 'The story never ran.';
          _bump(b, brand: -20);
          return 'The story ran with photos. Shops pulled your clothes off the racks.';
        }, risk: 'The story might run'),
      ],
    ),
    'gym_january' => _scene(
      'gym_january',
      'January: everyone has made a resolution and ${b.name} is packed.',
      [
        c('Offer a cheap annual deal', (l, b, rng) {
          b.boost += 12;
          return 'Hundreds signed up. By March, most stopped coming, but they kept paying.';
        }),
        c('Focus on keeping the regulars happy', (l, b, rng) {
          _bump(b, satisfaction: 8);
          return 'The regulars got their usual machines and noticed you cared.';
        }),
      ],
    ),
    'gym_injury' => _scene(
      'gym_injury',
      'A member hurt their back on a machine at ${b.name} and is talking to a lawyer.',
      [
        c('Settle generously (${_m(6000)})', (l, b, rng) {
          l.money -= 6000;
          return 'They signed, shook your hand and renewed their membership.';
        }),
        c('Fight it', (l, b, rng) {
          if (odds(rng, 50 + b.quality ~/ 4)) {
            return 'The machine was fine; the form was not. The case was dropped.';
          }
          l.money -= 20000;
          _bump(b, brand: -6);
          return 'You lost. The payout and fees came to ${_m(20000)}.';
        }, risk: 'Court is unpredictable'),
      ],
    ),
    'salon_celebrity' => _scene(
      'salon_celebrity',
      'A famous singer booked an appointment at ${b.name} under a fake name.',
      [
        c('Do their hair yourself', (l, b, rng) {
          if (odds(rng, 40 + l.stats['looks'] ~/ 2)) {
            _bump(b, brand: 18);
            return 'They posted a selfie and tagged you. The phone has not stopped ringing.';
          }
          _bump(b, brand: -4);
          return 'They left without a word. Their next interview mentioned "a bad haircut".';
        }),
        c('Give them your best stylist', (l, b, rng) {
          _bump(b, brand: 8);
          return 'They loved it and came back twice.';
        }),
      ],
    ),
    'salon_allergy' => _scene(
      'salon_allergy',
      'A client had an allergic reaction to a dye at ${b.name}.',
      [
        c('Pay for their treatment and apologise', (l, b, rng) {
          l.money -= 3000;
          _bump(b, satisfaction: 2);
          return 'They recovered and wrote a review praising how you handled it.';
        }),
        c('Point to the signed consent form', (l, b, rng) {
          _bump(b, satisfaction: -8, brand: -4);
          return 'Legally fine. Socially, not so much.';
        }),
      ],
    ),
    'cleaning_find' => _scene(
      'cleaning_find',
      'One of your cleaners found an envelope of cash behind a client\'s sofa.',
      [
        c('Return it to the client', (l, b, rng) {
          _bump(b, brand: 8, satisfaction: 6);
          l.stats.add('karma', 2);
          return 'The client told everyone. Three of their neighbours signed up.';
        }),
        c('Let the cleaner keep it', (l, b, rng) {
          _bump(b, morale: 6);
          if (odds(rng, 60))
            return 'Nobody asked. The cleaner was very grateful.';
          _bump(b, brand: -15);
          l.money -= 3000;
          return 'The client noticed. You refunded the money and lost the contract.';
        }, risk: 'They might notice'),
      ],
    ),
    'cleaning_staff' => _scene(
      'cleaning_staff',
      'Your cleaners at ${b.name} want a pay rise and are talking about a walkout.',
      [
        c('Give them the raise', (l, b, rng) {
          l.money -= 1200 * b.staff;
          _bump(b, morale: 15);
          return 'Raises for everyone. The vans were spotless the next morning.';
        }),
        c('Refuse', (l, b, rng) {
          _bump(b, morale: -15);
          b.boost -= 8;
          return 'They walked out for three days. Clients noticed.';
        }),
      ],
    ),
    'construction_delay' => _scene(
      'construction_delay',
      'Rain, a supplier strike and a missing digger: ${b.name}\'s biggest job is running late.',
      [
        c('Pay overtime to finish on time', (l, b, rng) {
          l.money -= 10000;
          _bump(b, satisfaction: 6);
          return 'You finished on the deadline day. The client never knew how close it was.';
        }),
        c('Ask the client for more time', (l, b, rng) {
          _bump(b, satisfaction: -8);
          return 'They agreed, with a penalty clause and a long face.';
        }),
      ],
    ),
    'construction_bribe' => _scene(
      'construction_bribe',
      'A building inspector hints that ${b.name}\'s permit could be "sped up" for a fee.',
      [
        c('Pay him', (l, b, rng) {
          l.money -= 5000;
          l.stats.add('karma', -4);
          if (odds(rng, 80)) {
            b.boost += 8;
            return 'The permit arrived the next day. You try not to think about it.';
          }
          _bump(b, brand: -20);
          return 'He was under investigation. Your name came up in court.';
        }, risk: 'It is a crime'),
        c('Report him', (l, b, rng) {
          b.boost -= 5;
          l.stats.add('karma', 4);
          return 'He was suspended. Your permit was delayed by a month, out of spite.';
        }),
        c('Wait like everyone else', (l, b, rng) {
          b.boost -= 3;
          return 'It took six weeks. The crew painted the office twice.';
        }),
      ],
    ),
    'podcast_sponsor' => _scene(
      'podcast_sponsor',
      'A sponsor offers ${b.name} ${_m(15000)} to read ads, including one for a dodgy supplement.',
      [
        c('Take the deal', (l, b, rng) {
          l.money += 15000;
          _bump(b, satisfaction: -6);
          return 'Listeners noticed the supplement ads. The comments were not kind.';
        }),
        c('Take it without the supplement', (l, b, rng) {
          l.money += 8000;
          return 'They agreed to a smaller deal. Your listeners never knew.';
        }),
        c('Turn it down', (l, b, rng) {
          _bump(b, satisfaction: 4);
          return 'Your listeners trust you a little more.';
        }),
      ],
    ),
    'podcast_cancel' => _scene(
      'podcast_cancel',
      'An old clip from ${b.name}\'s show is going round, out of context, and people are angry.',
      [
        c('Record an honest apology', (l, b, rng) {
          _bump(b, brand: -3, satisfaction: 4);
          return 'The apology episode became your most downloaded.';
        }),
        c('Double down', (l, b, rng) {
          if (odds(rng, 40)) {
            _bump(b, brand: 10);
            return 'Your fans rallied round. Downloads went up.';
          }
          _bump(b, brand: -15, satisfaction: -10);
          b.boost -= 15;
          return 'Two sponsors pulled out the same day.';
        }, risk: 'Could go either way'),
      ],
    ),
    _ => null,
  };
}
