import 'dart:math';

import 'business_kinds.dart';

import 'actions.dart';
import 'careers.dart' show studying;
import 'economy.dart';
import 'models.dart';
import 'storylet.dart';

/// Money depth (plan Module 6): credit score, loan types, defaults and
/// bankruptcy, a fictional stock market with bonds, gold and a coin, and
/// businesses you found and run.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

String _pct(double r) =>
    '${(r * 100).toStringAsFixed(r * 100 % 1 == 0 ? 0 : 1)}%';

// ---------------- Credit score ----------------

/// Plan: 300–850; starts unrated; on-time payments raise it, missed
/// payments (−35), defaults (−100) and bankruptcy (to about 320) lower it.
String creditBand(int? s) => s == null
    ? 'Unrated'
    : s < 580
    ? 'Poor'
    : s < 670
    ? 'Fair'
    : s < 740
    ? 'Good'
    : s < 800
    ? 'Very good'
    : 'Excellent';

int creditOf(Life l) => l.credit ?? 640;

void creditChange(Life l, int delta) =>
    l.credit = (creditOf(l) + delta).clamp(300, 850);

/// Loans are blocked for 7 years after bankruptcy.
bool loansBlocked(Life l) =>
    l.bankruptAge != null && l.age - l.bankruptAge! < 7;

/// Credit card limit by band; going over it is a default.
int cardLimit(Life l) => switch (creditBand(l.credit)) {
  'Unrated' => 3000,
  'Poor' => 2500,
  'Fair' => 6000,
  'Good' => 12000,
  'Very good' => 20000,
  _ => 30000,
};

/// How far the score is from perfect, 0 (850) to 1 (300).
double _risk(Life l) => (850 - creditOf(l)) / 550;

double rateOf(Life l, String debt) => l.rates[debt] ?? debtRates[debt] ?? 0.1;

/// What raised or lowered the score, for the explanation sheet.
const creditTips = [
  'Paying every debt on time each birthday: +8',
  'Overspending onto the card (a missed payment): −35',
  'Going over your card limit (a default): −100',
  'Bankruptcy: drops to about 320, then +15 a year for 7 years',
];

/// Each birthday, after debt payments (called from yearlyMoney).
List<String> creditYear(Life l, {required bool overspent}) {
  final feed = <String>[];
  if (l.credit == null && l.debts.isEmpty) return feed;
  final before = creditOf(l);
  l.credit ??= 640;
  if (l.bankruptAge != null && l.age - l.bankruptAge! <= 7) {
    creditChange(l, 15);
  }
  if (overspent) {
    creditChange(l, -35);
  } else if (l.debts.isNotEmpty) {
    creditChange(l, 8);
  }
  final card = l.debts['Credit card'] ?? 0;
  if (card > cardLimit(l)) {
    // A default; the crisis scene comes at most once every 3 years.
    creditChange(l, l.marks.contains('default:${l.age - 1}') ? -20 : -100);
    l.marks.add('default:${l.age}');
    final recent = [for (var a = l.age - 2; a <= l.age; a++) 'crisis:$a']
        .any(l.marks.contains);
    if (!recent) {
      l.marks.add('crisis:${l.age}');
      l.sceneQueue.add('debt_crisis');
    }
  }
  final now = creditOf(l);
  if (creditBand(now) != creditBand(before) && l.credit != null) {
    feed.add(
      'Your credit score is now $now (${creditBand(now)}).${now < before ? ' Missed payments hurt it.' : ' Paying on time is paying off.'}',
    );
  }
  return feed;
}

// ---------------- Loan types ----------------

typedef LoanType = ({
  String name,
  String blurb,
  int minAge,
  double Function(Life) rate,
  int Function(Life) limit,
  String? Function(Life) lock,
});

/// A parent or sibling who would lend you money (Bond 60%+).
Npc? lenderOf(Life l) {
  final family = l.npcs
      .where(
        (n) =>
            n.alive &&
            n.circle == 'Family' &&
            n.bond >= 60 &&
            n.ageIn(l.year) >= 25,
      )
      .toList();
  if (family.isEmpty) return null;
  family.sort((a, b) => b.bond.compareTo(a.bond));
  return family.first;
}

final loanTypes = <LoanType>[
  (
    name: 'Personal loan',
    blurb: 'Up to a year of salary. The rate follows your credit score.',
    minAge: 18,
    rate: (l) => 0.08 + _risk(l) * 0.10,
    limit: (l) {
      final mult = switch (creditBand(l.credit)) {
        'Poor' => 0.5,
        'Fair' => 0.8,
        'Excellent' => 1.5,
        _ => 1.0,
      };
      return max(
        0,
        (l.salary * mult).round() - (l.debts['Personal loan'] ?? 0),
      );
    },
    lock: (l) => l.job == null ? 'Needs a job' : null,
  ),
  (
    name: 'Business loan',
    blurb: 'For your business. Needs Fair credit (580+).',
    minAge: 18,
    rate: (l) => 0.06 + _risk(l) * 0.08,
    limit: (l) => max(0, 60000 - (l.debts['Business loan'] ?? 0)),
    lock: (l) => l.business == null
        ? 'Needs a business'
        : creditOf(l) < 580
        ? 'Needs Fair credit (580+)'
        : null,
  ),
  (
    name: 'Payday loan',
    blurb: 'Fast cash, no questions. You repay it all plus a 90% fee at your next birthday.',
    minAge: 18,
    rate: (l) => 0.90,
    limit: (l) => max(0, 1500 - (l.debts['Payday loan'] ?? 0)),
    lock: (l) => null,
  ),
  (
    name: 'Family loan',
    blurb: 'Interest-free from someone close. They will remember if it goes wrong.',
    minAge: 16,
    rate: (l) => 0.0,
    limit: (l) => l.debts.containsKey('Family loan') ? 0 : 5000,
    lock: (l) {
      if (l.debts.containsKey('Family loan')) {
        return 'Pay back the last one first';
      }
      return lenderOf(l) == null ? 'Nobody close enough (Bond 60%+)' : null;
    },
  ),
];

/// Null when this loan can be taken now, otherwise why not.
String? loanLock(Life l, LoanType t) {
  if (l.age < t.minAge) return 'Unlocks at ${t.minAge}';
  if (l.prison != null) return 'Not possible in prison';
  if (loansBlocked(l) && t.name != 'Family loan') {
    return 'Blocked for ${7 - (l.age - l.bankruptAge!)} more years after bankruptcy';
  }
  final lock = t.lock(l);
  if (lock != null) return lock;
  if (t.limit(l) <= 0) return 'You have borrowed the most you can';
  return null;
}

ActionResult takeLoan(Life l, LoanType t, int amount) {
  final a = min(amount, t.limit(l));
  final rate = t.rate(l);
  l.credit ??= 640;
  l.money += a;
  l.debts[t.name] = (l.debts[t.name] ?? 0) + a;
  l.rates[t.name] = rate;
  if (t.name == 'Family loan') {
    final lender = lenderOf(l)!;
    l.marks.add('lender:${lender.id}');
    lender.remember(
      NpcMemory(
        age: l.age,
        text: 'lending you ${_m(a)}',
        valence: 1,
        intensity: 2,
        tags: ['money'],
      ),
    );
    return ActionResult(
      '${lender.name.split(' ').first} lent you ${_m(a)}, interest-free, with a look that says "I trust you".',
      ['Money +${_m(a)}', 'About 20% is repaid each birthday'],
    );
  }
  return ActionResult(
    t.name == 'Payday loan'
        ? 'The payday lender handed over ${_m(a)} in five minutes. At your next birthday you owe ${_m((a * 1.9).round())}.'
        : 'The bank approved a ${t.name.toLowerCase()} of ${_m(a)} at ${_pct(rate)} a year.',
    [
      'Money +${_m(a)}',
      if (t.name == 'Payday loan')
        'Warning: if you can\'t repay, it lands on your credit card'
      else
        'Rate set by your credit score (${creditOf(l)})',
    ],
  );
}

/// When a family loan is paid off, the lender remembers it kindly.
void familyLoanPaid(Life l) {
  for (final m in l.marks.where((m) => m.startsWith('lender:')).toList()) {
    l.npc(m.substring(7))?.addFacets(trust: 6, affection: 3);
    l.marks.remove(m);
  }
}

// ---------------- Default and bankruptcy ----------------

Storylet? debtCrisisScene(Life l) {
  final card = l.debts['Credit card'] ?? 0;
  if (card <= 0) return null;
  final lender = lenderOf(l);
  final rate = 0.08 + _risk(l) * 0.10;
  return Storylet(
    id: 'scene:debt_crisis',
    text:
        'The envelopes are red now. You owe ${_m(card)} on your credit card, over your ${_m(cardLimit(l))} limit, and the collectors call at dinner time. Your credit score has dropped to ${creditOf(l)} (${creditBand(l.credit)}). Something has to change.',
    category: 'money',
    scene: true,
    choices: [
      Choice(
        label: 'Consolidate into one personal loan',
        outcome: '',
        risk: 'Rate ${_pct(rate)} instead of 20%',
        lock: (l) => loansBlocked(l)
            ? 'Blocked after bankruptcy'
            : creditOf(l) < 580
            ? 'Needs Fair credit (580+)'
            : null,
        run: (l, rng) {
          final moved =
              (l.debts.remove('Credit card') ?? 0) +
              (l.debts.remove('Payday loan') ?? 0);
          l.debts['Personal loan'] = (l.debts['Personal loan'] ?? 0) + moved;
          l.rates['Personal loan'] = rate;
          l.stress = l.stress - 5;
          return 'The bank rolled ${_m(moved)} of card debt into one loan at ${_pct(rate)}. One payment, a lower rate, and the phone finally stops ringing.';
        },
      ),
      Choice(
        label: lender == null
            ? 'Ask family for help'
            : 'Ask ${lender.name.split(' ').first} for help',
        outcome: '',
        risk: 'Interest-free, but they will remember',
        lock: (l) =>
            lenderOf(l) == null ? 'Nobody close enough (Bond 60%+)' : null,
        run: (l, rng) {
          final who = lenderOf(l)!;
          final help = min(card, 10000);
          l.debts['Credit card'] = card - help;
          if (l.debts['Credit card']! <= 0) l.debts.remove('Credit card');
          l.debts['Family loan'] = (l.debts['Family loan'] ?? 0) + help;
          l.rates['Family loan'] = 0;
          l.marks.add('lender:${who.id}');
          who.addFacets(trust: -3);
          who.remember(
            NpcMemory(
              age: l.age,
              text: 'bailing you out of debt',
              valence: 0,
              intensity: 3,
              tags: ['money'],
            ),
          );
          return '${who.name.split(' ').first} paid ${_m(help)} off your card and said, "Pay me back when you can. And cut up that card." It was the most humbling phone call of your life.';
        },
      ),
      Choice(
        label: 'Declare bankruptcy',
        outcome: '',
        risk: 'Clears most debts · loans blocked 7 years',
        run: (l, rng) => bankruptcy(l),
      ),
      Choice(
        label: 'Go frugal and keep paying',
        outcome: '',
        risk: 'Stressful',
        run: (l, rng) {
          l.lifestyle = 'frugal';
          l.stress = l.stress + 10;
          l.stats.add('happiness', -3);
          return 'You cancelled every subscription, learned twelve ways to cook lentils and set up a payment plan. It will take years, but it is yours to fix.';
        },
      ),
    ],
  );
}

/// Plan: clears most debts, loses non-exempt assets, blocks loans for 7
/// years, and the score recovers slowly. The home and student loan stay.
String bankruptcy(Life l) {
  const cleared = [
    'Credit card',
    'Personal loan',
    'Payday loan',
    'Pay later',
    'Auto loan',
    'Business loan',
    'Family loan',
  ];
  var total = 0;
  for (final d in cleared) {
    total += l.debts.remove(d) ?? 0;
  }
  for (final m in l.marks.where((m) => m.startsWith('lender:')).toList()) {
    l.npc(m.substring(7))
      ?..addFacets(trust: -12, resentment: 8)
      ..remember(
        NpcMemory(
          age: l.age,
          text: 'never getting their money back',
          valence: -2,
          intensity: 3,
          tags: ['money'],
        ),
      );
    l.marks.remove(m);
  }
  final seized = <String>[];
  if (l.invested + l.portfolioValue > 0) {
    seized.add('investments worth ${_m(l.invested + l.portfolioValue)}');
    l.invested = 0;
    l.shares.clear();
    l.paid.clear();
  }
  if (l.savings > 2000) {
    seized.add('${_m(l.savings - 2000)} of savings');
    l.savings = 2000;
  }
  final cars = l.assets.where((a) => a.kind == 'car' && a.value > 5000);
  if (cars.isNotEmpty) {
    seized.add('your ${cars.first.name.toLowerCase()}');
    l.assets.removeWhere((a) => a.kind == 'car' && a.value > 5000);
  }
  for (final b in l.businesses) {
    seized.add(b.name);
  }
  l.businesses.clear();
  l.bizFocus = 0;
  l.credit = 320;
  l.bankruptAge = l.age;
  l.flags['bankrupt'] = Memory(l.age, 'declaring bankruptcy');
  l.stats.add('happiness', -8);
  l.stress = l.stress + 15;
  return 'A judge signed the papers in four minutes. ${_m(total)} of debt is gone${seized.isEmpty ? '' : ', and so are ${seized.join(', ')}'}. Your home and any student loan stay with you. Your credit score fell to 320; no bank will lend to you for 7 years. It feels like failing and starting over at the same time.';
}

// ---------------- The market: fictional tickers ----------------

typedef Ticker = ({
  String id,
  String name,
  String sector,
  String kind,
  double base,
  int drift,
  int vol,
  double beta,
  int since,
  double yield,
  String blurb,
});

/// Prices drift back toward a band around their base price (the game has
/// no inflation, so prices must not grow forever); the long-run return
/// comes from dividends and interest, paid in cash each birthday.
const tickers = <Ticker>[
  (
    id: 'NIMB',
    name: 'Nimbus Cloud',
    sector: 'Tech',
    kind: 'stock',
    base: 60,
    drift: 9,
    vol: 22,
    beta: 1.2,
    since: 0,
    yield: 0.01,
    blurb: 'Fast-growing tech. Big swings.',
  ),
  (
    id: 'VOLT',
    name: 'Voltaic Motors',
    sector: 'Energy',
    kind: 'stock',
    base: 25,
    drift: 8,
    vol: 30,
    beta: 1.4,
    since: 0,
    yield: 0.0,
    blurb: 'Electric cars and batteries. Very volatile.',
  ),
  (
    id: 'BRKL',
    name: 'Brookline Foods',
    sector: 'Food',
    kind: 'stock',
    base: 40,
    drift: 5,
    vol: 8,
    beta: 0.6,
    since: 0,
    yield: 0.035,
    blurb: 'Groceries everyone buys. Slow and steady.',
  ),
  (
    id: 'MEDX',
    name: 'Medexa Health',
    sector: 'Health',
    kind: 'stock',
    base: 80,
    drift: 6,
    vol: 12,
    beta: 0.7,
    since: 0,
    yield: 0.025,
    blurb: 'Medicines and clinics. Holds up in bad years.',
  ),
  (
    id: 'HRTH',
    name: 'Hearthstone Homes',
    sector: 'Property',
    kind: 'stock',
    base: 35,
    drift: 5,
    vol: 15,
    beta: 1.1,
    since: 0,
    yield: 0.03,
    blurb: 'House builder. Rises and falls with the economy.',
  ),
  (
    id: 'PIXL',
    name: 'Pixelforge Games',
    sector: 'Media',
    kind: 'stock',
    base: 30,
    drift: 8,
    vol: 28,
    beta: 1.0,
    since: 0,
    yield: 0.005,
    blurb: 'One hit game away from glory, or ruin.',
  ),
  (
    id: 'ORCA',
    name: 'Orca Shipping',
    sector: 'Transport',
    kind: 'stock',
    base: 15,
    drift: 4,
    vol: 18,
    beta: 1.3,
    since: 0,
    yield: 0.04,
    blurb: 'Container ships. Booms and busts with trade.',
  ),
  (
    id: 'GOLD',
    name: 'Gold',
    sector: 'Commodity',
    kind: 'commodity',
    base: 1800,
    drift: 3,
    vol: 10,
    beta: -0.4,
    since: 0,
    yield: 0.0,
    blurb: 'Tends to rise when everything else falls.',
  ),
  (
    id: 'GOVB',
    name: 'Government bond fund',
    sector: 'Bonds',
    kind: 'bond',
    base: 100,
    drift: 3,
    vol: 2,
    beta: -0.1,
    since: 0,
    yield: 0.03,
    blurb: 'Low risk, about 3% a year.',
  ),
  (
    id: 'CORP',
    name: 'Corporate bond fund',
    sector: 'Bonds',
    kind: 'bond',
    base: 100,
    drift: 5,
    vol: 4,
    beta: 0.3,
    since: 0,
    yield: 0.05,
    blurb: 'About 5% a year; can dip in a recession.',
  ),
  (
    id: 'PBBL',
    name: 'Pebblecoin',
    sector: 'Crypto',
    kind: 'coin',
    base: 0.5,
    drift: 20,
    vol: 75,
    beta: 1.6,
    since: 2009,
    yield: 0.0,
    blurb: 'A digital coin. Wild swings; can crash 80%.',
  ),
];

Ticker? tickerById(String id) => tickers.where((t) => t.id == id).firstOrNull;

const _upNews = {
  'Tech': 'a record year for cloud contracts',
  'Energy': 'a battery breakthrough',
  'Food': 'a surprise hit snack',
  'Health': 'a new medicine approved',
  'Property': 'a housing boom',
  'Media': 'a smash-hit game',
  'Transport': 'busy shipping lanes',
  'Commodity': 'nervous investors buying gold',
  'Bonds': 'falling interest rates',
  'Crypto': 'a celebrity endorsement',
};

const _downNews = {
  'Tech': 'a data leak scandal',
  'Energy': 'a battery recall',
  'Food': 'a contamination scare',
  'Health': 'a failed drug trial',
  'Property': 'a housing slump',
  'Media': 'a game delayed for the third time',
  'Transport': 'a canal blockage',
  'Commodity': 'calmer markets',
  'Bonds': 'rising interest rates',
  'Crypto': 'an exchange collapse',
};

/// The world's prices for the next year (world.dart), with news lines for
/// big moves. Every life in that year sees the same prices.
Map<String, double> stepPrices(
  Map<String, double> prev,
  String economy,
  int year,
  Random rng,
  List<String> news,
) {
  final adj = (fundReturns[economy]?.$1 ?? 7) - 7;
  final next = <String, double>{};
  for (final t in tickers) {
    if (year < t.since) continue;
    final before = prev[t.id];
    if (before == null || before <= 0) {
      next[t.id] = t.base;
      continue;
    }
    final noise =
        (rng.nextDouble() * 2 - 1) +
        (rng.nextDouble() * 2 - 1) +
        (rng.nextDouble() * 2 - 1);
    // Mean reversion toward the base price keeps prices in a band.
    final drag = 8 * log(before / t.base);
    var pct = t.drift - drag + t.beta * adj + noise * t.vol * 0.6;
    if (rng.nextInt(100) < 10 && t.kind != 'bond') {
      final up = rng.nextBool();
      pct += up ? 15 + rng.nextInt(20) : -(15 + rng.nextInt(20));
    }
    pct = max(-85, pct);
    if (pct.abs() >= 20) {
      news.add(
        '${t.name} ${pct > 0 ? 'rose' : 'fell'} ${pct.abs().round()}% after ${pct > 0 ? _upNews[t.sector] : _downNews[t.sector]}.',
      );
    }
    next[t.id] = max(0.01, before * (1 + pct / 100));
  }
  return next;
}

/// Dividends and interest on holdings this year (cash flow line).
int dividends(Life l) {
  var total = 0.0;
  for (final e in l.shares.entries) {
    final t = tickerById(e.key);
    if (t == null) continue;
    total += e.value * (l.quotes[e.key] ?? 0) * t.yield;
  }
  return total.round();
}

int holdingValue(Life l, String id) =>
    ((l.shares[id] ?? 0) * (l.quotes[id] ?? 0)).round();

ActionResult buyShares(Life l, String id, int dollars) {
  final t = tickerById(id)!;
  final price = l.quotes[id] ?? 0;
  final a = min(dollars, max(0, l.money));
  if (price <= 0 || a <= 0) return ActionResult('Nothing to buy.');
  l.money -= a;
  l.shares[id] = (l.shares[id] ?? 0) + a / price;
  l.paid[id] = (l.paid[id] ?? 0) + a;
  return ActionResult('You bought ${_m(a)} of ${t.name}.', [
    'Money −${_m(a)}',
    'Price ${_price(price)}',
  ]);
}

ActionResult sellShares(Life l, String id, int dollars) {
  final t = tickerById(id)!;
  final value = holdingValue(l, id);
  final a = min(dollars, value);
  if (a <= 0) return ActionResult('Nothing to sell.');
  final share = a / value;
  final paid = ((l.paid[id] ?? 0) * share).round();
  l.shares[id] = (l.shares[id] ?? 0) * (1 - share);
  l.paid[id] = (l.paid[id] ?? 0) - paid;
  if (a >= value) {
    l.shares.remove(id);
    l.paid.remove(id);
  }
  l.money += a;
  final gain = a - paid;
  return ActionResult('You sold ${_m(a)} of ${t.name}.', [
    'Money +${_m(a)}',
    gain >= 0 ? 'Profit ${_m(gain)}' : 'Loss ${_m(-gain)}',
  ]);
}

String _price(double p) => p < 10 ? '\$${p.toStringAsFixed(2)}' : _m(p.round());

String priceLabel(double p) => _price(p);

/// Each birthday after the cash flow: holdings move with the new prices.
List<String> portfolioYear(
  Life l,
  Map<String, double> prices,
  List<String> news,
) {
  final feed = <String>[];
  var change = 0;
  for (final e in l.shares.entries) {
    final before = (e.value * (l.quotes[e.key] ?? 0)).round();
    final after = (e.value * (prices[e.key] ?? 0)).round();
    change += after - before;
    final t = tickerById(e.key);
    if (t == null || before <= 0) continue;
    final pct = ((after - before) / before * 100).round();
    if (pct.abs() >= 20) {
      final why = news.where((n) => n.startsWith(t.name)).firstOrNull;
      feed.add(
        why != null
            ? '$why Your shares are now worth ${_m(after)}.'
            : '${t.name} ${pct > 0 ? 'rose' : 'fell'} ${pct.abs()}%. Your shares are now worth ${_m(after)}.',
      );
    }
  }
  l.quotes = Map.of(prices);
  if (l.shares.isNotEmpty) {
    l.lastGrowth = [...l.lastGrowth, ('Stocks, bonds and coins', change)];
  }
  l.netWorthByAge[l.age] = l.netWorth;
  return feed;
}

// ---------------- Business ----------------

typedef Industry = ({
  String id,
  String name,
  int startup,
  int perStaff,
  int wage,
  double materials,
  int rent,
  int maxStaff,
  String stat,
  String product,
});

const industries = <Industry>[
  (
    id: 'cafe',
    name: 'Café',
    startup: 40000,
    perStaff: 60000,
    wage: 26000,
    materials: 0.32,
    rent: 18000,
    maxStaff: 8,
    stat: 'charisma',
    product: 'coffee',
  ),
  (
    id: 'bakery',
    name: 'Bakery',
    startup: 35000,
    perStaff: 58000,
    wage: 26000,
    materials: 0.30,
    rent: 15000,
    maxStaff: 8,
    stat: 'creativity',
    product: 'bread',
  ),
  (
    id: 'restaurant',
    name: 'Restaurant',
    startup: 90000,
    perStaff: 65000,
    wage: 28000,
    materials: 0.33,
    rent: 40000,
    maxStaff: 20,
    stat: 'creativity',
    product: 'menu',
  ),
  (
    id: 'food_truck',
    name: 'Food truck',
    startup: 25000,
    perStaff: 62000,
    wage: 26000,
    materials: 0.30,
    rent: 6000,
    maxStaff: 3,
    stat: 'charisma',
    product: 'street food',
  ),
  (
    id: 'app',
    name: 'Tech app',
    startup: 30000,
    perStaff: 85000,
    wage: 55000,
    materials: 0.10,
    rent: 12000,
    maxStaff: 30,
    stat: 'smarts',
    product: 'app',
  ),
  (
    id: 'games',
    name: 'Games studio',
    startup: 60000,
    perStaff: 80000,
    wage: 50000,
    materials: 0.12,
    rent: 20000,
    maxStaff: 40,
    stat: 'creativity',
    product: 'games',
  ),
  (
    id: 'clothing',
    name: 'Clothing brand',
    startup: 45000,
    perStaff: 70000,
    wage: 34000,
    materials: 0.38,
    rent: 15000,
    maxStaff: 15,
    stat: 'creativity',
    product: 'collection',
  ),
  (
    id: 'gym',
    name: 'Gym',
    startup: 80000,
    perStaff: 64000,
    wage: 28000,
    materials: 0.10,
    rent: 35000,
    maxStaff: 12,
    stat: 'athleticism',
    product: 'classes',
  ),
  (
    id: 'salon',
    name: 'Salon',
    startup: 30000,
    perStaff: 57000,
    wage: 26000,
    materials: 0.18,
    rent: 14000,
    maxStaff: 8,
    stat: 'looks',
    product: 'treatments',
  ),
  (
    id: 'cleaning',
    name: 'Cleaning company',
    startup: 15000,
    perStaff: 50000,
    wage: 24000,
    materials: 0.10,
    rent: 4000,
    maxStaff: 30,
    stat: 'discipline',
    product: 'service',
  ),
  (
    id: 'construction',
    name: 'Construction firm',
    startup: 70000,
    perStaff: 78000,
    wage: 40000,
    materials: 0.40,
    rent: 20000,
    maxStaff: 30,
    stat: 'discipline',
    product: 'builds',
  ),
  (
    id: 'podcast',
    name: 'Podcast studio',
    startup: 10000,
    perStaff: 66000,
    wage: 35000,
    materials: 0.08,
    rent: 3000,
    maxStaff: 5,
    stat: 'charisma',
    product: 'show',
  ),
];

Industry industryById(String id) =>
    industries.firstWhere((i) => i.id == id, orElse: () => industries.first);

const bizTiers = {
  'budget': (
    label: 'Budget',
    price: 0.8,
    wages: 0.92,
    cost: 0.8,
    blurb: 'Cheap and cheerful: lower prices, more customers.',
  ),
  'mid': (
    label: 'Mid-market',
    price: 1.0,
    wages: 1.0,
    cost: 1.0,
    blurb: 'Good value for most people.',
  ),
  'premium': (
    label: 'Premium',
    price: 1.35,
    wages: 1.12,
    cost: 1.4,
    blurb: 'High prices. Customers expect quality 70+.',
  ),
};

int startupCost(Industry ind, String tier) =>
    (ind.startup * bizTiers[tier]!.cost).round();

const _econDemand = {
  'Boom': 1.15,
  'Normal': 1.0,
  'Slowdown': 0.92,
  'Recession': 0.8,
  'Crash': 0.65,
};

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

/// One year of trading (plan: revenue from demand, quality, brand, price
/// and the economy; profit after wages, materials, rent and tax). Returns
/// the profit (or loss) that reaches your cash.
int businessYear(Life l, Random rng, [Business? which]) {
  final b = which ?? l.business!;
  final ind = industryById(b.industry);
  final tier = bizTiers[b.tier]!;
  final appeal = b.quality * 0.45 + b.brand * 0.3 + b.satisfaction * 0.25;
  final tierFit = b.tier == 'premium'
      ? (b.quality >= 70 ? 1.05 : 0.8)
      : b.tier == 'budget'
      ? 1.08
      : 1.0;
  final crowd = b.staff > ind.maxStaff ? ind.maxStaff / b.staff : 1.0;
  final econ = _econDemand[l.economy] ?? 1.0;
  final (perkDemand, perkSavings) = perkEffects(b);
  final demand =
      (0.45 + appeal / 100) *
      (1 + perkDemand + b.boost / 100) *
      econ *
      tierFit *
      crowd *
      (0.9 + rng.nextDouble() * 0.2);
  final revenue = (ind.perStaff * b.staff * demand * tier.price).round();
  final wages = (ind.wage * b.staff * tier.wages).round();
  final materials =
      (revenue *
              ind.materials *
              (b.tier == 'premium' ? 1.1 : 1) *
              (1 - perkSavings))
          .round();
  final rent = (ind.rent * (b.tier == 'premium' ? 1.3 : 1)).round();
  final before = revenue - wages - materials - rent;
  final tax = before > 0 ? (before * 0.2).round() : 0;
  final profit = before - tax;
  b
    ..revenue = revenue
    ..profit = profit
    ..lossYears = profit < 0 ? b.lossYears + 1 : 0
    ..lines = [
      ('Revenue', revenue),
      ('Wages (${b.staff} staff)', -wages),
      ('Materials and stock', -materials),
      ('Rent', -rent),
      if (tax > 0) ('Tax on profit', -tax),
    ];
  final reasons = <(int, String)>[
    (
      (b.quality - 50).abs(),
      'Customers rate your ${ind.product} ${b.quality}%',
    ),
    ((b.brand - 30).abs(), 'Brand awareness ${b.brand}%'),
    (((econ - 1) * 100).abs().round(), '${l.economy} economy'),
    ((b.morale - 60).abs(), 'Staff morale ${b.morale}%'),
    if (crowd < 1) (40, 'More staff than the market needs'),
    if (b.tier == 'premium' && b.quality < 70)
      (35, 'Premium prices without premium quality'),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  b.reasons = [for (final r in reasons.take(3)) r.$2];
  b.boost = 0; // festivals, contracts and the like last one year
  maybeTradeEvent(l, b, rng);
  // The year changes the business too.
  b.brand = max(0, b.brand - 4);
  b.morale = (b.morale + (60 - b.morale) ~/ 4).clamp(0, 100);
  b.quality = (b.quality + (l.stats[ind.stat] - 50) ~/ 10 - 1).clamp(5, 100);
  b.satisfaction =
      (b.satisfaction +
              ((b.quality + (b.morale - 50) ~/ 3) - b.satisfaction) * 3 ~/ 10)
          .clamp(0, 100);
  if (b.lossYears >= 2 && !l.marks.contains('insolvency:${l.age}')) {
    l.marks.add('insolvency:${l.age}');
    l.sceneQueue.add('insolvency:${b.name}');
  }
  return profit;
}

String businessSummary(Business b) =>
    '${b.name}: revenue ${_m(b.revenue)}, ${b.profit >= 0 ? 'profit ${_m(b.profit)}' : 'a loss of ${_m(-b.profit)}'}. ${b.reasons.isEmpty ? '' : '${b.reasons.first}.'}';

/// The most businesses one person can run at once.
const maxBusinesses = 5;

/// Business moves are once a year for each business.
String _moveKey(Life l, String id) => '$id@${l.business?.name}';

/// Switches which business the manager screen works on.
void focusBusiness(Life l, int i) {
  if (i >= 0 && i < l.businesses.length) l.bizFocus = i;
}

String? _bizLock(Life l, String id, int cost) {
  if (l.business == null) return 'No business';
  if (l.usedActions.contains(_moveKey(l, id))) return 'Done this year';
  if (cost > 0 && l.money < cost) return 'Needs ${_m(cost)}';
  return null;
}

typedef BizMove = ({
  String id,
  String label,
  String Function(Life) detail,
  int Function(Life) cost,
  ActionResult Function(Life, Random) run,
});

final bizMoves = <BizMove>[
  (
    id: 'biz_ads',
    label: 'Marketing campaign',
    detail: (l) => '${_m(8000)} · Brand +15',
    cost: (l) => 8000,
    run: (l, rng) {
      final b = l.business!;
      l.money -= 8000;
      b.brand = min(100, b.brand + 15);
      return ActionResult(
        'Posters, a radio slot and a very persuasive influencer. People are talking about ${b.name}.',
        ['Money −${_m(8000)}', 'Brand ${b.brand}%'],
      );
    },
  ),
  (
    id: 'biz_improve',
    label: 'Improve the product',
    detail: (l) => '${_m(10000)} · Quality up',
    cost: (l) => 10000,
    run: (l, rng) {
      final b = l.business!;
      final ind = industryById(b.industry);
      l.money -= 10000;
      final gain = 6 + l.stats[ind.stat] ~/ 15;
      b.quality = min(100, b.quality + gain);
      return ActionResult(
        'You spent weeks perfecting the ${ind.product}. Even the regulars noticed.',
        ['Money −${_m(10000)}', 'Quality ${b.quality}% (+$gain)'],
      );
    },
  ),
  (
    id: 'biz_hire',
    label: 'Hire someone',
    detail: (l) {
      final ind = industryById(l.business!.industry);
      return '+${_m(ind.wage)} a year in wages';
    },
    cost: (l) => 0,
    run: (l, rng) {
      final b = l.business!;
      b.staff++;
      b.morale = min(100, b.morale + 3);
      final ind = industryById(b.industry);
      return ActionResult(
        'A new hire joined ${b.name}. The team has ${b.staff} people now.',
        [
          'Wages +${_m(ind.wage)} a year',
          if (b.staff > ind.maxStaff)
            'Careful: more staff than a ${ind.name.toLowerCase()} usually needs',
        ],
      );
    },
  ),
  (
    id: 'biz_cut',
    label: 'Let someone go',
    detail: (l) => 'Saves wages · Morale −12',
    cost: (l) => 0,
    run: (l, rng) {
      final b = l.business!;
      if (b.staff <= 1) return ActionResult('It is just you now.');
      b.staff--;
      b.morale = max(0, b.morale - 12);
      return ActionResult(
        'The worst conversation of the year. The rest of the team went quiet for a week.',
        ['Staff ${b.staff}', 'Morale ${b.morale}%'],
      );
    },
  ),
  (
    id: 'biz_raise',
    label: 'Give the team a raise',
    detail: (l) => '${_m(1500 * l.business!.staff)} · Morale +15',
    cost: (l) => 1500 * l.business!.staff,
    run: (l, rng) {
      final b = l.business!;
      final cost = 1500 * b.staff;
      l.money -= cost;
      b.morale = min(100, b.morale + 15);
      return ActionResult(
        'You handed out raises. Someone baked a cake with your face on it.',
        ['Money −${_m(cost)}', 'Morale ${b.morale}%'],
      );
    },
  ),
];

String? bizMoveLock(Life l, BizMove m) => _bizLock(l, m.id, m.cost(l));

ActionResult runBizMove(Life l, BizMove m, Random rng) {
  l.usedActions.add(_moveKey(l, m.id));
  return m.run(l, rng);
}

ActionResult setTier(Life l, String tier) {
  final b = l.business!;
  b.tier = tier;
  return ActionResult(
    '${b.name} is now ${bizTiers[tier]!.label.toLowerCase()}. ${bizTiers[tier]!.blurb}',
  );
}

ActionResult sellBusiness(Life l) {
  final b = l.business!;
  final value = l.valueOfBusiness(b);
  l.money += value;
  l.business = null;
  l.flags['sold_business'] = Memory(l.age, 'selling ${b.name}');
  return ActionResult(
    'A buyer shook your hand and took the keys to ${b.name}.',
    ['Money +${_m(value)}', 'Why: 3 years of profit, plus staff and brand'],
  );
}

ActionResult closeBusiness(Life l) {
  final b = l.business!;
  l.business = null;
  l.flags['closed_business'] = Memory(l.age, 'closing ${b.name}');
  l.stats.add('happiness', -4);
  return ActionResult('You turned the sign to "Closed" for the last time.', [
    if (l.debts.containsKey('Business loan'))
      'The business loan still has to be repaid',
  ]);
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'money',
  scene: true,
  choices: choices,
);

/// Founding wizard (plan): industry → business model → funding.
Storylet? businessScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'biz_found':
      if (l.businesses.length >= maxBusinesses) return null;
      return _scene(
        id,
        'You have been sketching business ideas on napkins for years. Which one is it going to be? Each kind of business leans on a different skill.',
        [
          for (final ind in industries)
            Choice(
              label: '${ind.name} · from ${_m(startupCost(ind, 'budget'))}',
              outcome: '',
              risk: 'Skill: ${_cap(ind.stat)}',
              run: (l, rng) {
                l.sceneQueue.add('biz_tier:${ind.id}');
                return 'A ${ind.name.toLowerCase()} it is. Now: what kind?';
              },
            ),
          Choice(
            label: 'Not now',
            outcome: 'The napkins went back in the drawer.',
          ),
        ],
      );
    case 'biz_tier':
      final ind = industryById(args.first);
      return _scene(
        id,
        '${bizKinds[ind.id]?.blurb ?? ''} Your ${ind.stat}: ${l.stats[ind.stat]}. Every ${ind.name.toLowerCase()} needs a place in the market. Budget sells more for less; premium charges more but customers expect quality.',
        [
          for (final e in bizTiers.entries)
            Choice(
              label:
                  '${e.value.label} · ${_m(startupCost(ind, e.key))} to start',
              outcome: '',
              risk: e.value.blurb,
              run: (l, rng) {
                l.sceneQueue.add('biz_fund:${ind.id}:${e.key}');
                return 'You picked ${e.value.label.toLowerCase()}. Now the money.';
              },
            ),
          Choice(label: 'Back out', outcome: 'Maybe another year.'),
        ],
      );
    case 'biz_fund':
      if (args.length < 2) return null;
      final ind = industryById(args[0]);
      final tier = args[1];
      final cost = startupCost(ind, tier);
      final own = (cost * 0.2).round();
      final rate = 0.06 + _risk(l) * 0.08;
      final lender = lenderOf(l);
      String open(Life l, String how) {
        final base =
            '${l.surname} ${ind.name == 'Tech app' ? 'Apps' : ind.name}';
        // A second shop of the same kind gets a number.
        var name = base;
        for (var n = 2; l.businesses.any((b) => b.name == name); n++) {
          name = '$base $n';
        }
        l.business =
            Business(name: name, industry: ind.id, tier: tier, since: l.age)
              ..staff = ind.maxStaff <= 3 ? 1 : 2
              ..quality = (35 + l.stats[ind.stat] ~/ 4).clamp(20, 70);
        l.flags['founded_business'] = Memory(l.age, 'opening $name');
        l.stats.add('happiness', 6);
        l.stress = l.stress + 8;
        return 'You signed the lease, painted the sign yourself and opened the doors of $name. $how Each birthday shows its revenue, costs and why.';
      }

      return _scene(
        id,
        'Opening a ${bizTiers[tier]!.label.toLowerCase()} ${ind.name.toLowerCase()} costs ${_m(cost)}: fit-out, equipment and the first months of rent.',
        [
          Choice(
            label: 'Pay it all yourself (${_m(cost)})',
            outcome: '',
            needsMoney: cost,
            run: (l, rng) {
              l.money -= cost;
              return open(l, 'No debts, all yours.');
            },
          ),
          Choice(
            label: 'Business loan for ${_m(cost - own)}',
            outcome: '',
            risk: 'You put in ${_m(own)} · rate ${_pct(rate)}',
            needsMoney: own,
            lock: (l) => loansBlocked(l)
                ? 'Blocked after bankruptcy'
                : creditOf(l) < 580
                ? 'Needs Fair credit (580+)'
                : null,
            run: (l, rng) {
              l.money -= own;
              l.credit ??= 640;
              l.debts['Business loan'] =
                  (l.debts['Business loan'] ?? 0) + cost - own;
              l.rates['Business loan'] = rate;
              return open(
                l,
                'The bank lent ${_m(cost - own)} at ${_pct(rate)}.',
              );
            },
          ),
          if (cost <= 40000)
            Choice(
              label: lender == null
                  ? 'Ask family to back you'
                  : 'Ask ${lender.name.split(' ').first} to back you',
              outcome: '',
              risk: 'Interest-free family loan',
              lock: (l) => lenderOf(l) == null
                  ? 'Nobody close enough (Bond 60%+)'
                  : null,
              run: (l, rng) {
                final who = lenderOf(l)!;
                l.debts['Family loan'] = (l.debts['Family loan'] ?? 0) + cost;
                l.rates['Family loan'] = 0;
                l.marks.add('lender:${who.id}');
                who.remember(
                  NpcMemory(
                    age: l.age,
                    text: 'backing your business',
                    valence: 2,
                    intensity: 3,
                    tags: ['money'],
                  ),
                );
                return open(
                  l,
                  '${who.name.split(' ').first} put up the money and cried a little at the opening.',
                );
              },
            ),
          Choice(
            label: 'Back out',
            outcome: 'You decided the timing was wrong.',
          ),
        ],
      );
    case 'insolvency':
      final i = args.isEmpty
          ? l.bizFocus
          : l.businesses.indexWhere((x) => x.name == args.join(':'));
      if (i < 0 || i >= l.businesses.length) return null;
      final b = l.businesses[i];
      return _scene(
        id,
        'Two years of losses. ${b.name} owes suppliers, the bank is calling and you have stopped opening the post. Main reasons: ${b.reasons.join('; ').toLowerCase()}.',
        [
          Choice(
            label: 'Cut staff and keep going',
            outcome: '',
            risk: 'Morale −15',
            run: (l, rng) {
              b.staff = max(1, (b.staff * 0.7).floor());
              b.morale = max(0, b.morale - 15);
              b.lossYears = 0;
              return 'You cut the team to ${b.staff}. Everyone left works harder and smiles less.';
            },
          ),
          Choice(
            label: 'Sell for whatever you can get',
            outcome: '',
            run: (l, rng) {
              final value = (l.valueOfBusiness(b) * 0.5).round();
              l.money += value;
              l.businesses.remove(b);
              l.bizFocus = 0;
              l.flags['sold_business'] = Memory(l.age, 'selling ${b.name}');
              return 'A competitor bought ${b.name} for ${_m(value)}. It stung, but it is over.';
            },
          ),
          Choice(
            label: 'Close the doors',
            outcome: '',
            run: (l, rng) {
              focusBusiness(l, l.businesses.indexOf(b));
              return closeBusiness(l).text;
            },
          ),
          Choice(
            label: 'Declare bankruptcy',
            outcome: '',
            risk: 'Clears most debts · loans blocked 7 years',
            run: (l, rng) => bankruptcy(l),
          ),
        ],
      );
  }
  return null;
}

final financeActions = <GameAction>[
  GameAction(
    id: 'start_business',
    label: 'Start a business',
    category: 'Money',
    priceNote: 'From \$8,000 · step-by-step planner',
    keywords: ['business', 'start', 'company', 'shop', 'startup', 'found'],
    minAge: 18,
    extraCheck: (l) => l.businesses.length >= maxBusinesses
        ? 'You already run $maxBusinesses businesses'
        : studying(l)
        ? 'Finish your course first'
        : null,
    run: (l, rng) {
      l.sceneQueue.add('biz_found');
      return ActionResult('You open a notebook and start planning.');
    },
  ),
];
