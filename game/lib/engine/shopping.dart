import 'dart:math';

import 'actions.dart';
import 'finance.dart' show cardLimit, creditBand;
import 'health.dart' show exposeTo;
import 'models.dart';

// The shop: departments of things with lasting effects, quality you can
// feel, daily deals and real-date sales, three ways to pay, gifts people
// love (or just politely accept), subscriptions that renew each birthday,
// and returns and second-hand sales.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

typedef ShopItem = ({
  String id,
  String dept,
  String name,
  int price,
  String blurb,
  Map<String, int> now,
  Map<String, int> yearly,
  int years,
  int resale,
  int minAge,
  Set<String> likes,
});

ShopItem _i(
  String id,
  String dept,
  String name,
  int price,
  String blurb, {
  Map<String, int> now = const {},
  Map<String, int> yearly = const {},
  int years = 0,
  int resale = 30,
  int minAge = 8,
  Set<String> likes = const {},
}) => (
  id: id,
  dept: dept,
  name: name,
  price: price,
  blurb: blurb,
  now: now,
  yearly: yearly,
  years: years,
  resale: resale,
  minAge: minAge,
  likes: likes,
);

const departments = <String, String>{
  'clothes': 'Clothes',
  'tech': 'Tech',
  'home': 'Home',
  'books': 'Books',
  'sport': 'Hobbies',
  'luxury': 'Luxury',
  'gifts': 'Gifts',
  'subs': 'Subscriptions',
};

final catalogue = <ShopItem>[
  // Clothes and style
  _i(
    'basics',
    'clothes',
    'Wardrobe basics',
    120,
    'Jeans, tees and socks without holes',
    now: {'looks': 2, 'happiness': 1},
  ),
  _i(
    'outfit',
    'clothes',
    'Designer outfit',
    900,
    'Turns heads for a few years',
    now: {'looks': 4, 'happiness': 2},
    yearly: {'looks': 1},
    years: 3,
    resale: 25,
    minAge: 14,
    likes: {'teen', 'adult'},
  ),
  _i(
    'trainers',
    'clothes',
    'Running shoes',
    150,
    'Make every run a little easier',
    now: {'athleticism': 1},
    yearly: {'health': 1},
    years: 2,
    likes: {'teen', 'adult'},
  ),
  _i(
    'coat',
    'clothes',
    'Statement coat',
    400,
    'Warm, sharp and very you',
    now: {'looks': 3},
    years: 4,
    resale: 20,
    minAge: 14,
  ),
  _i(
    'perfume',
    'clothes',
    'Perfume',
    180,
    'You smell expensive',
    now: {'looks': 1, 'happiness': 1},
    minAge: 14,
    likes: {'partner', 'adult', 'elder'},
  ),
  // Tech
  _i(
    'phone_budget',
    'tech',
    'Budget phone',
    250,
    'Calls, messages and one decent camera',
    now: {'happiness': 1},
    years: 3,
    resale: 20,
    minAge: 10,
  ),
  _i(
    'phone',
    'tech',
    'Latest phone',
    1100,
    'The camera is better than your eyes',
    now: {'happiness': 4, 'charisma': 1},
    years: 3,
    resale: 35,
    minAge: 12,
    likes: {'teen'},
  ),
  _i(
    'laptop',
    'tech',
    'Laptop',
    900,
    'Smarts +1 a year while it lasts',
    now: {'happiness': 2},
    yearly: {'smarts': 1},
    years: 4,
    resale: 25,
    minAge: 10,
    likes: {'teen'},
  ),
  _i(
    'console',
    'tech',
    'Games console',
    500,
    'Happiness +1 a year · can become a habit',
    now: {'happiness': 3},
    yearly: {'happiness': 1},
    years: 5,
    resale: 30,
    minAge: 6,
    likes: {'kid', 'teen'},
  ),
  _i(
    'headphones',
    'tech',
    'Noise-cancelling headphones',
    220,
    'The world goes quiet',
    now: {'happiness': 2},
    years: 3,
    resale: 25,
    likes: {'teen', 'adult'},
  ),
  _i(
    'smartwatch',
    'tech',
    'Smartwatch',
    350,
    'Health +1 a year · nags you to stand up',
    now: {'happiness': 1},
    yearly: {'health': 1},
    years: 3,
    resale: 20,
    minAge: 14,
  ),
  // Home
  _i(
    'sofa',
    'home',
    'Very comfy sofa',
    1200,
    'Happiness +1 a year for 8 years',
    yearly: {'happiness': 1},
    years: 8,
    resale: 15,
    minAge: 18,
  ),
  _i(
    'bed',
    'home',
    'Proper mattress',
    800,
    'Health +1 a year · actual sleep',
    yearly: {'health': 1},
    years: 8,
    resale: 5,
    minAge: 18,
  ),
  _i(
    'plants',
    'home',
    'Houseplant jungle',
    90,
    'Some will survive',
    now: {'happiness': 2},
    minAge: 14,
    likes: {'elder', 'adult'},
  ),
  _i(
    'coffee',
    'home',
    'Coffee machine',
    300,
    'Happiness +1 a year · mornings fixed',
    yearly: {'happiness': 1},
    years: 5,
    resale: 20,
    minAge: 18,
    likes: {'adult'},
  ),
  _i(
    'art',
    'home',
    'Framed art print',
    150,
    'A wall worth looking at',
    now: {'creativity': 1, 'happiness': 1},
    years: 15,
    resale: 30,
    minAge: 14,
    likes: {'adult', 'elder', 'partner'},
  ),
  // Books and learning
  _i(
    'novel',
    'books',
    'A good novel',
    15,
    'Gone in a weekend',
    now: {'happiness': 1, 'smarts': 1},
    minAge: 6,
    likes: {'adult', 'elder', 'teen'},
  ),
  _i(
    'textbooks',
    'books',
    'Study guide bundle',
    120,
    'Exams feel less scary',
    now: {'smarts': 3},
    minAge: 10,
  ),
  _i(
    'course',
    'books',
    'Language course',
    300,
    'Smarts +1 a year for 2 years',
    now: {'smarts': 1},
    yearly: {'smarts': 1},
    years: 2,
    minAge: 12,
    likes: {'adult'},
  ),
  _i(
    'artkit',
    'books',
    'Art supplies',
    80,
    'Paints, pencils and a fresh sketchbook',
    now: {'creativity': 3},
    minAge: 4,
    likes: {'kid', 'teen'},
  ),
  // Sport and hobbies
  _i(
    'bike',
    'sport',
    'Bicycle',
    450,
    'Health +1 a year for 6 years',
    now: {'athleticism': 2},
    yearly: {'health': 1},
    years: 6,
    resale: 35,
    minAge: 6,
    likes: {'kid', 'teen'},
  ),
  _i(
    'guitar',
    'sport',
    'Guitar',
    350,
    'Creativity +1 a year if you practise',
    now: {'creativity': 2},
    yearly: {'creativity': 1},
    years: 10,
    resale: 45,
    minAge: 8,
    likes: {'teen'},
  ),
  _i(
    'camera',
    'sport',
    'Camera',
    700,
    'Creativity +3 · holidays look better',
    now: {'creativity': 3},
    years: 6,
    resale: 40,
    minAge: 12,
  ),
  _i(
    'boardgames',
    'sport',
    'Board game night set',
    60,
    'Friends and family come round more',
    now: {'happiness': 2},
    years: 10,
    resale: 10,
    minAge: 6,
    likes: {'kid', 'adult', 'elder'},
  ),
  _i(
    'camping',
    'sport',
    'Camping gear',
    400,
    'Tent, stove and a sleeping bag',
    now: {'happiness': 2},
    years: 8,
    resale: 30,
    minAge: 12,
  ),
  // Luxury (kept on the Wealth tab as valuables)
  _i(
    'handbag',
    'luxury',
    'Designer handbag',
    2800,
    'Keeps about half its value',
    now: {'looks': 2, 'happiness': 3},
    resale: 50,
    minAge: 16,
    likes: {'partner', 'adult'},
  ),
  _i(
    'watch',
    'luxury',
    'Luxury watch',
    8000,
    'Can gain value if you look after it',
    now: {'looks': 2, 'happiness': 3},
    resale: 75,
    minAge: 18,
    likes: {'partner', 'adult'},
  ),
  _i(
    'jewellery',
    'luxury',
    'Fine jewellery',
    2500,
    'Sparkles · resale about 55%',
    now: {'looks': 2, 'happiness': 4},
    resale: 55,
    minAge: 16,
    likes: {'partner', 'elder'},
  ),
  // Gifts
  _i(
    'flowers',
    'gifts',
    'Flowers',
    40,
    'Bright, fragrant and a little apologetic',
    minAge: 6,
    likes: {'partner', 'elder', 'adult'},
  ),
  _i(
    'chocolates',
    'gifts',
    'Box of chocolates',
    25,
    'The good ones, with the map inside',
    minAge: 4,
    likes: {'kid', 'elder', 'partner'},
  ),
  _i(
    'toy',
    'gifts',
    'Toy',
    50,
    'Loud, colourful, adored',
    minAge: 8,
    likes: {'kid'},
  ),
  _i(
    'videogame',
    'gifts',
    'Video game',
    70,
    'Gone for the weekend',
    minAge: 8,
    likes: {'kid', 'teen'},
  ),
  _i(
    'giftcard',
    'gifts',
    'Gift card',
    100,
    'Safe, if not very personal',
    minAge: 10,
    likes: {'teen'},
  ),
  _i(
    'experience',
    'gifts',
    'Experience day',
    300,
    'A spa day, a race track, a cooking class',
    minAge: 16,
    likes: {'partner', 'adult'},
  ),
  _i(
    'album',
    'gifts',
    'Photo album of memories',
    60,
    'Made by hand, page by page',
    minAge: 10,
    likes: {'elder', 'partner', 'adult'},
  ),
];

/// Subscriptions renew each birthday and show in the cash flow.
typedef Subscription = ({
  String id,
  String name,
  int yearly,
  Map<String, int> effects,
  int minAge,
  String blurb,
});

const subscriptions = <Subscription>[
  (
    id: 'streaming',
    name: 'Streaming service',
    yearly: 180,
    effects: {'happiness': 1},
    minAge: 12,
    blurb: 'Happiness +1 a year',
  ),
  (
    id: 'music',
    name: 'Music app',
    yearly: 120,
    effects: {'happiness': 1},
    minAge: 12,
    blurb: 'Happiness +1 a year',
  ),
  (
    id: 'gym',
    name: 'Gym membership',
    yearly: 480,
    effects: {'health': 1, 'athleticism': 1},
    minAge: 16,
    blurb: 'Health and athleticism +1 a year',
  ),
  (
    id: 'mealkit',
    name: 'Meal kit deliveries',
    yearly: 2400,
    effects: {'health': 1},
    minAge: 18,
    blurb: 'Health +1 a year · no more beige dinners',
  ),
  (
    id: 'courses',
    name: 'Online courses',
    yearly: 300,
    effects: {'smarts': 1},
    minAge: 14,
    blurb: 'Smarts +1 a year',
  ),
  (
    id: 'box',
    name: 'Monthly mystery box',
    yearly: 360,
    effects: {'happiness': 1},
    minAge: 16,
    blurb: 'Happiness +1 a year · mostly socks',
  ),
];

ShopItem? itemById(String id) => catalogue.where((i) => i.id == id).firstOrNull;
Subscription? subById(String id) =>
    subscriptions.where((s) => s.id == id).firstOrNull;

int _hash(String s) =>
    s.codeUnits.fold(11, (a, c) => (a * 31 + c) & 0x7fffffff);

// ---------------- Sales and deals ----------------

/// A sale running on this real date, if any: (name, percent off, depts).
(String, int, Set<String>)? saleOn(DateTime d) {
  final md = d.month * 100 + d.day;
  if (md >= 1120 && md <= 1130) {
    return ('Black Friday', 30, {...departments.keys}..remove('subs'));
  }
  if (md >= 1210 && md <= 1224) {
    return ('Holiday gift sale', 15, {'gifts', 'tech'});
  }
  if (md >= 1226 || md <= 105) {
    return ('New Year sale', 25, {'clothes', 'home'});
  }
  if (md >= 701 && md <= 715) return ('Summer sale', 40, {'clothes', 'sport'});
  if (md >= 820 && md <= 905) return ('Back to school', 20, {'books', 'tech'});
  return null;
}

/// Three daily deals, the same for everyone on the same day.
Map<String, int> dealsOn(DateTime d) {
  final r = Random(_hash('${d.year}-${d.month}-${d.day}'));
  final pool = catalogue.where((i) => i.dept != 'gifts').toList();
  final out = <String, int>{};
  while (out.length < 3) {
    out[pool[r.nextInt(pool.length)].id] = const [20, 30, 40][out.length];
  }
  return out;
}

/// Percent off this item today (the bigger of the sale and the deal).
int discountOn(ShopItem i, DateTime d) {
  final sale = saleOn(d);
  final fromSale = sale != null && sale.$3.contains(i.dept) ? sale.$2 : 0;
  return max(fromSale, dealsOn(d)[i.id] ?? 0);
}

int priceOf(Life l, ShopItem i, DateTime d) {
  final econ = switch (l.economy) {
    'Boom' => 1.05,
    'Recession' || 'Crash' => 0.95,
    _ => 1.0,
  };
  final p = i.price * econ * (100 - discountOn(i, d)) / 100;
  return max(1, p < 100 ? p.round() : (p / 5).round() * 5);
}

// ---------------- Paying ----------------

/// Pay in 3: a third now, the rest due in full at the next birthday.
const payLaterDebt = 'Pay later';

String? payLock(Life l, String how, int price) => switch (how) {
  'cash' => l.money >= price ? null : 'Needs ${_m(price)} in cash',
  'card' =>
    l.age < 18
        ? 'Cards open at 18'
        : (l.debts['Credit card'] ?? 0) + price > cardLimit(l)
        ? 'Over your ${_m(cardLimit(l))} card limit'
        : null,
  _ =>
    l.age < 18
        ? 'Opens at 18'
        : price < 60
        ? 'Only for \$60 or more'
        : creditBand(l.credit) == 'Poor'
        ? 'Your credit score is too low'
        : (l.debts[payLaterDebt] ?? 0) + price > 3000
        ? 'Pay later is capped at \$3,000 owed'
        : l.money < (price / 3).ceil()
        ? 'Needs ${_m((price / 3).ceil())} today'
        : null,
};

void _pay(Life l, String how, int price) {
  switch (how) {
    case 'cash':
      l.money -= price;
    case 'card':
      l.credit ??= 640;
      l.debts['Credit card'] = (l.debts['Credit card'] ?? 0) + price;
    default:
      final now = (price / 3).ceil();
      l.money -= now;
      l.credit ??= 640;
      l.debts[payLaterDebt] = (l.debts[payLaterDebt] ?? 0) + price - now;
  }
}

// ---------------- Gifts ----------------

/// Who someone is, for gift tastes.
String tasteOf(Life l, Npc n) {
  if (n.circle == 'Partner') return 'partner';
  final a = n.ageIn(l.year);
  if (a < 13) return 'kid';
  if (a < 18) return 'teen';
  if (a >= 65) return 'elder';
  return 'adult';
}

bool loves(Life l, Npc n, ShopItem i) => i.likes.contains(tasteOf(l, n));

// ---------------- Buying, returning, selling ----------------

List<Map<String, dynamic>> ownedItems(Life l) => l.items;

String? itemLock(Life l, ShopItem i) {
  if (l.age < i.minAge) return 'From age ${i.minAge}';
  if (l.prison != null) return 'Not possible in prison';
  return null;
}

ActionResult buyItem(
  Life l,
  ShopItem i, {
  String pay = 'cash',
  Npc? giftFor,
  DateTime? now,
  Random? rng,
}) {
  final d = now ?? DateTime.now();
  final price = priceOf(l, i, d);
  final off = discountOn(i, d);
  _pay(l, pay, price);
  final notes = <String>[
    switch (pay) {
      'cash' => 'Money −${_m(price)}',
      'card' => 'On your credit card: ${_m(price)} at 20% a year',
      _ =>
        'Money −${_m((price / 3).ceil())} today, ${_m(price - (price / 3).ceil())} due next birthday',
    },
    if (off > 0) 'Saved ${_m(i.price - price)} ($off% off)',
  ];
  final bought = l.marks.where((m) => m.startsWith('bought:${l.age}:')).length;
  l.marks.add('bought:${l.age}:${i.id}');
  if (giftFor != null) {
    final love = loves(l, giftFor, i);
    final gain = min(12, 3 + price ~/ 150) * (love ? 2 : 1);
    giftFor.addFacets(affection: gain, trust: love ? 2 : 0);
    giftFor.lastContactAge = l.age;
    giftFor.remember(
      NpcMemory(
        age: l.age,
        text: 'the ${i.name.toLowerCase()} you gave me',
        valence: love ? 2 : 1,
        intensity: love ? 3 : 2,
        tags: ['gift'],
      ),
    );
    l.stats.add('happiness', 1);
    final who = giftFor.name.split(' ').first;
    return ActionResult(
      love
          ? '$who unwrapped it and lit up. "How did you know?" They will remember this one.'
          : '$who said thank you and meant it, mostly. It was a kind thought.',
      [...notes, 'Bond with $who +$gain${love ? ' (they love this)' : ''}'],
    );
  }
  i.now.forEach(l.stats.add);
  notes.addAll([
    for (final e in i.now.entries)
      '${e.key[0].toUpperCase()}${e.key.substring(1)} ${e.value >= 0 ? '+' : '−'}${e.value.abs()}',
  ]);
  if (l.stats['happiness'] < 40) {
    l.stats.add('happiness', 2);
    notes.add('Retail therapy: happiness +2, for now');
  }
  if (i.dept == 'luxury') {
    l.assets.add(
      Asset(
        id: '${i.id}${l.age}_$bought',
        kind: 'valuable',
        name: i.name,
        value: (price * i.resale / 100).round(),
        yearlyCost: 0,
        since: l.age,
        info: {'dep': i.id == 'watch' ? -1 : 3},
      ),
    );
    notes.add(
      'Kept on Wealth › What you own · worth about ${_m((price * i.resale / 100).round())}',
    );
  } else if (i.years > 0) {
    l.items.add({
      'id': i.id,
      'paid': price,
      'age': l.age,
      'left': i.years,
      'pay': pay,
    });
  }
  if (i.id == 'console' && rng != null) {
    final note = exposeTo(l, 'gaming', rng);
    if (note != null) notes.add(note);
  }
  if (bought >= 5 &&
      l.stats['impulsivity'] > 55 &&
      !l.flags.containsKey('shopaholic')) {
    l.flags['shopaholic'] = Memory(l.age, 'shopping a little too much');
    notes.add(
      'Why: that is ${bought + 1} things this year. The parcels are piling up.',
    );
  }
  return ActionResult(switch (i.dept) {
    'clothes' =>
      'You tried it on, turned around twice in the mirror and bought it.',
    'tech' => 'You peeled off the plastic film. Best moment of the week.',
    'home' => 'It took two people and some swearing to get it in, but it fits perfectly.',
    'books' => 'You started it on the bus home.',
    'sport' => 'You used it the same day. That is a good sign.',
    'luxury' => 'The shop assistant wrapped it in tissue paper like a newborn.',
    _ => 'Bought.',
  }, notes);
}

/// Things bought this year can go back for 90% (cash) or come off the card.
String? returnLock(Life l, Map<String, dynamic> item) =>
    item['age'] == l.age ? null : 'Only in the year you bought it';

ActionResult returnItem(Life l, Map<String, dynamic> item) {
  final paid = item['paid'] as int;
  final i = itemById(item['id'] as String)!;
  l.items.remove(item);
  i.now.forEach((k, v) => l.stats.add(k, -v));
  if (item['pay'] == 'card') {
    final card = (l.debts['Credit card'] ?? 0) - paid;
    if (card > 0) {
      l.debts['Credit card'] = card;
    } else {
      l.debts.remove('Credit card');
      if (card < 0) l.money -= card;
    }
    return ActionResult(
      'You returned the ${i.name.toLowerCase()} with the receipt.',
      ['Refunded ${_m(paid)} to your card'],
    );
  }
  final back = (paid * 0.9).round();
  l.money += back;
  return ActionResult(
    'You returned the ${i.name.toLowerCase()}. The restocking fee stung a little.',
    ['Money +${_m(back)}', 'Why: 10% restocking fee'],
  );
}

int resaleOf(Map<String, dynamic> item) {
  final i = itemById(item['id'] as String);
  if (i == null) return 0;
  final wear = (item['left'] as int) / max(1, i.years);
  return max(
    5,
    ((item['paid'] as int) * i.resale / 100 * (0.4 + 0.6 * wear)).round(),
  );
}

ActionResult sellItem(Life l, Map<String, dynamic> item) {
  final i = itemById(item['id'] as String)!;
  final price = resaleOf(item);
  l.items.remove(item);
  l.money += price;
  return ActionResult(
    'A buyer came round, haggled a bit and took the ${i.name.toLowerCase()} away.',
    ['Money +${_m(price)}'],
  );
}

// ---------------- Subscriptions ----------------

String? subLock(Life l, Subscription s) {
  if (l.age < s.minAge) return 'From age ${s.minAge}';
  if (l.subs.contains(s.id)) return 'Subscribed';
  return null;
}

ActionResult subscribe(Life l, Subscription s) {
  l.subs.add(s.id);
  return ActionResult('You signed up for the ${s.name.toLowerCase()}.', [
    '${_m(s.yearly)} a year, paid each birthday',
    s.blurb,
  ]);
}

ActionResult unsubscribe(Life l, Subscription s) {
  l.subs.remove(s.id);
  return ActionResult(
    'You cancelled the ${s.name.toLowerCase()}. They asked if you were sure three times.',
    ['Saves ${_m(s.yearly)} a year'],
  );
}

/// Yearly cost of every subscription (part of the cash flow).
int subscriptionCost(Life l) =>
    l.subs.fold(0, (a, id) => a + (subById(id)?.yearly ?? 0));

// ---------------- Each birthday ----------------

/// Things wear out, keep giving, or break; subscriptions renew.
List<String> shoppingYear(Life l, Random rng) {
  final feed = <String>[];
  for (final item in List<Map<String, dynamic>>.from(l.items)) {
    final i = itemById(item['id'] as String);
    if (i == null) {
      l.items.remove(item);
      continue;
    }
    i.yearly.forEach(l.stats.add);
    var left = (item['left'] as int) - 1;
    if (i.dept == 'tech' && left > 0 && rng.nextInt(100) < 6) {
      left = 0;
      feed.add('You dropped your ${i.name.toLowerCase()}. It did not survive.');
    } else if (left <= 0) {
      feed.add(
        'Your ${i.name.toLowerCase()} finally wore out after ${i.years} years.',
      );
    }
    if (left <= 0) {
      l.items.remove(item);
    } else {
      item['left'] = left;
    }
  }
  for (final id in l.subs) {
    subById(id)?.effects.forEach(l.stats.add);
  }
  if (l.flags.containsKey('shopaholic') && l.subs.length >= 4) {
    feed.add(
      'You have ${l.subs.length} subscriptions. You use about two of them.',
    );
  }
  return feed;
}

// ---------------- The activity that opens the shop ----------------

final shopAction = GameAction(
  id: 'shopping',
  label: 'Go shopping',
  category: 'Money',
  keywords: [
    'shop',
    'shopping',
    'buy',
    'clothes',
    'gift',
    'phone',
    'laptop',
    'jewellery',
    'deal',
    'sale',
    'subscription',
  ],
  minAge: 8,
  repeatable: true,
  screen: 'shop',
  hint: (l) {
    final s = saleOn(DateTime.now());
    return s != null
        ? '${s.$1}: ${s.$2}% off'
        : 'Eight departments · daily deals';
  },
  run: (l, rng) => ActionResult('You head to the shops.'),
);
