import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'finance.dart';
import 'health.dart' show healthCosts;
import 'homes.dart' show homeOf, lettingOf, rentFor;
import 'lifespan.dart' show statePension, statePensionAge;
import 'models.dart';
import 'shopping.dart' show subscriptionCost;
import 'kin.dart' show fostersOf, fosterAllowance;
import 'possessions.dart';
import 'pets.dart' show petCosts;
import 'social.dart' show socialIncome;

/// Money as a system (plan Module 6/7, prototype scope): every birthday runs
/// income → taxes → living costs → debt payments → interest → fund returns →
/// asset values → net worth, and records a cash-flow breakdown that adds up
/// exactly to the change in cash.

// ---------------- Lifestyle (budget tiers) ----------------

typedef Lifestyle = ({
  String label,
  int alone,
  int withFamily,
  int happiness,
  String blurb,
});

const lifestyles = <String, Lifestyle>{
  'frugal': (
    label: 'Frugal',
    alone: 6000,
    withFamily: 2000,
    happiness: -2,
    blurb: 'Cheap food, no extras',
  ),
  'comfortable': (
    label: 'Comfortable',
    alone: 11000,
    withFamily: 4000,
    happiness: 0,
    blurb: 'A normal, easy life',
  ),
  'lavish': (
    label: 'Lavish',
    alone: 22000,
    withFamily: 9000,
    happiness: 3,
    blurb: 'Eating out, gadgets, trips',
  ),
};

bool livesWithFamily(Life life) => !life.has('house') && !life.has('rental');

int livingCost(Life life, [String? tier]) {
  final t = lifestyles[tier ?? life.lifestyle]!;
  final base = livesWithFamily(life) ? t.withFamily : t.alone;
  // Inflation in the news pushes living costs up.
  return (base * (100 + (life.worldMods['prices'] ?? 0)) / 100).round();
}

// ---------------- Taxes and debts ----------------

/// Simple income tax bands (country tables come later).
int incomeTax(int income) {
  var tax = 0.0;
  if (income > 12000) tax += (min(income, 50000) - 12000) * 0.20;
  if (income > 50000) tax += (income - 50000) * 0.35;
  return tax.round();
}

/// Default yearly rates; most loans lock in a rate from your credit score
/// when you take them (finance.dart rateOf).
const debtRates = <String, double>{
  'Student loan': 0.05,
  'Mortgage': 0.05,
  'Buy-to-let mortgage': 0.06,
  'Personal loan': 0.12,
  'Auto loan': 0.08,
  'Business loan': 0.10,
  'Payday loan': 0.90,
  'Family loan': 0.0,
  'Credit card': 0.20,
  'Pay later': 0.0,
};

const mortgageYears = 25;
const savingsRate = 0.02;

/// Yearly mortgage payment: M = P·r·(1+r)^n / ((1+r)^n − 1).
int annuity(int principal, double rate, int years) {
  if (years <= 1) return principal;
  final f = pow(1 + rate, years);
  return (principal * rate * f / (f - 1)).round();
}

int _debtPayment(Life life, String name, int balance) {
  if (name == 'Mortgage' || name == 'Buy-to-let mortgage') {
    final house = name == 'Mortgage' ? homeOf(life) : lettingOf(life);
    final left = house == null ? 5 : mortgageYears - (life.age - house.since);
    return min(balance, annuity(balance, rateOf(life, name), max(1, left)));
  }
  // Payday loans are due in full at the next birthday.
  if (name == 'Payday loan' || name == 'Pay later') return balance;
  return min(balance, max(600, (balance * 0.2).round()));
}

/// Rent follows the local market (world news can push it up).
int yearlyCostOf(Life life, Asset a) => a.kind == 'rental'
    ? (a.yearlyCost * (100 + (life.worldMods['rent'] ?? 0)) / 100).round()
    : a.yearlyCost;

/// Living at home with no income, your family covers your living costs.
bool familyCovers(Life life) =>
    livesWithFamily(life) && life.salary <= 0 && life.age < 30 && !life.retired;

/// Student loans are only repaid once you earn.
bool _owesPayment(Life life, String name) =>
    name != 'Student loan' || life.salary > 0;

/// Rough cash change at the next birthday (before events and activities),
/// so the Wealth tab can warn before you overspend.
int forecastNextYear(Life life) {
  if (life.age + 1 < 18 && life.salary <= 0) return 0;
  var total = 0;
  if (life.job != null && life.salary > 0) {
    total += life.salary - incomeTax(life.salary);
  }
  if (life.age + 1 >= 18) {
    if (!familyCovers(life)) total -= livingCost(life);
    for (final a in life.assets) {
      total -= yearlyCostOf(life, a);
    }
  }
  for (final e in life.debts.entries) {
    if (!_owesPayment(life, e.key)) continue;
    final b = e.value + (e.value * rateOf(life, e.key)).round();
    total -= _debtPayment(life, e.key, b);
  }
  final let = lettingOf(life);
  if (let != null) total += rentFor(let);
  for (final c in healthCosts(life)) {
    total += c.$2;
  }
  if (life.business != null) total += life.business!.profit;
  if (life.age + 1 >= 18) total -= homeInsuranceCost(life);
  total += fostersOf(life).length * fosterAllowance;
  total -= subscriptionCost(life);
  return total;
}

/// Personal loans: up to one year's salary, only with a job.
int borrowLimit(Life life) =>
    life.age < 18 || loanLock(life, loanTypes.first) != null
    ? 0
    : loanTypes.first.limit(life);

// ---------------- The economy ----------------

const economyStates = ['Boom', 'Normal', 'Slowdown', 'Recession', 'Crash'];

const _transitions = <String, Map<String, int>>{
  'Boom': {'Boom': 40, 'Normal': 45, 'Slowdown': 15},
  'Normal': {'Boom': 15, 'Normal': 60, 'Slowdown': 15, 'Recession': 10},
  'Slowdown': {'Normal': 40, 'Slowdown': 30, 'Recession': 25, 'Crash': 5},
  'Recession': {'Normal': 35, 'Slowdown': 25, 'Recession': 35, 'Crash': 5},
  'Crash': {'Recession': 50, 'Slowdown': 30, 'Normal': 20},
};

/// Index fund return per state: (mean %, spread %).
const fundReturns = <String, (int, int)>{
  'Boom': (15, 6),
  'Normal': (7, 6),
  'Slowdown': (1, 6),
  'Recession': (-10, 8),
  'Crash': (-25, 8),
};

const _homeGrowth = <String, int>{
  'Boom': 6,
  'Normal': 3,
  'Slowdown': 1,
  'Recession': -4,
  'Crash': -9,
};

String nextEconomy(String now, Random rng) {
  final options = _transitions[now] ?? _transitions['Normal']!;
  var roll = rng.nextInt(100);
  for (final e in options.entries) {
    if (roll < e.value) return e.key;
    roll -= e.value;
  }
  return 'Normal';
}

/// One birthday's money. Returns feed lines worth telling the player.
List<String> yearlyMoney(Life life, Random rng) {
  final lines = <(String, int)>[];
  final growth = <(String, int)>[];
  final feed = <String>[];
  void cash(String label, int amount) {
    if (amount == 0) return;
    life.money += amount;
    lines.add((label, amount));
  }

  life.reason = 'Money';
  final jailed = life.prison != null;
  if (jailed && life.prison!.job != null) cash('Prison job', 600);
  if (life.job != null && life.salary > 0) {
    cash('Salary', life.salary);
    cash('Income tax', -incomeTax(life.salary));
  }
  if (life.flags.containsKey('child_support')) {
    final minors = life.npcs
        .where(
          (n) => n.circle == 'Children' && n.alive && n.ageIn(life.year) < 18,
        )
        .length;
    if (minors == 0) {
      life.flags.remove('child_support');
    } else {
      cash('Child support', -max(1200, (life.salary * 0.15).round()) * minors);
    }
  }
  if (life.age >= 8 && life.age <= 17 && !jailed) {
    cash('Pocket money', 50 + life.age * 10);
  }
  if (studying(life) && life.school.tuition > 0) {
    cash('Tuition', -life.school.tuition);
  }
  if (life.retired) {
    cash('Pension', life.pension);
  } else if (life.job == null && life.age >= statePensionAge) {
    cash('State pension', statePension);
  } else if (life.job == null &&
      life.age >= 18 &&
      !jailed &&
      !studying(life) &&
      life.jobLostAge != null &&
      life.age - life.jobLostAge! <= 2) {
    cash('Unemployment benefit', 6000);
  }

  if (life.business != null) {
    cash('Business: ${life.business!.name}', businessYear(life, rng));
  }
  cash('Dividends and interest', dividends(life));
  for (final (label, amount) in socialIncome(life)) {
    cash(label, amount);
  }
  if (life.age >= 18) cash('Pet care', -petCosts(life));
  final let = lettingOf(life);
  if (let != null) {
    final late = life.marks.contains('late_rent:${life.age}');
    cash('Rent from tenants', late ? rentFor(let) ~/ 2 : rentFor(let));
  }
  for (final (label, amount) in healthCosts(life)) {
    cash(label, amount);
  }
  if (life.age >= 18) cash('Home insurance', -homeInsuranceCost(life));
  cash('Fostering allowance', fostersOf(life).length * fosterAllowance);
  cash('Subscriptions', -subscriptionCost(life));
  if (life.age >= 18 && jailed) {
    lines.add(('Prison covers food and a bed', 0));
    for (final a in life.assets) {
      cash('${a.name} upkeep', -yearlyCostOf(life, a));
    }
  } else if (life.age >= 18) {
    final tier = lifestyles[life.lifestyle]!;
    if (familyCovers(life)) {
      lines.add(('Family covered your living costs', 0));
    } else {
      cash(
        livesWithFamily(life) ? 'Living costs (at home)' : 'Living costs',
        -livingCost(life),
      );
    }
    life.stats.add('happiness', tier.happiness);
    for (final a in life.assets) {
      cash(
        a.kind == 'rental' ? 'Rent' : '${a.name} upkeep',
        -yearlyCostOf(life, a),
      );
    }
  }

  for (final name in life.debts.keys.toList()) {
    var balance = life.debts[name]!;
    balance += (balance * rateOf(life, name)).round();
    final pay = _owesPayment(life, name)
        ? _debtPayment(life, name, balance)
        : 0;
    balance -= pay;
    cash('$name payment', -pay);
    if (balance <= 0) {
      life.debts.remove(name);
      life.rates.remove(name);
      if (name == 'Family loan') familyLoanPaid(life);
      feed.add('You paid off your ${name.toLowerCase()}!');
    } else {
      life.debts[name] = balance;
    }
  }

  // Children never go into debt: the family covers it.
  if (life.money < 0 && life.age < 18) {
    lines.add(('Family covered what you owed', -life.money));
    life.money = 0;
  }
  // Overspending becomes debt (a student loan while studying).
  final overspent = life.money < 0 && !studying(life);
  if (life.money < 0) {
    final short = -life.money;
    final name = studying(life) ? 'Student loan' : 'Credit card';
    life.debts[name] = (life.debts[name] ?? 0) + short;
    cash('Put on ${name.toLowerCase()}', short);
    if (name == 'Credit card') {
      feed.add(
        'You spent more than you had. \$$short went on a credit card at 20%.',
      );
    }
  }

  if (life.age >= 18) feed.addAll(creditYear(life, overspent: overspent));

  if (life.savings > 0) {
    final i = (life.savings * savingsRate).round();
    life.savings += i;
    growth.add(('Savings interest', i));
  }
  if (life.invested > 0) {
    final (mean, spread) = fundReturns[life.economy]!;
    final pct = mean + (rng.nextDouble() * 2 - 1) * spread;
    final r = (life.invested * pct / 100).round();
    life.invested = max(0, life.invested + r);
    growth.add(('Index fund (${life.economy.toLowerCase()})', r));
  }
  for (final a in life.assets) {
    if (a.kind == 'rental') continue;
    final before = a.value;
    if (a.kind == 'house') {
      final pct = _homeGrowth[life.economy]! + rng.nextInt(5) - 2;
      a.value = (a.value * (1 + pct / 100)).round();
      a.condition = max(0, a.condition - 2 - rng.nextInt(3));
    } else {
      final dep = (a.info['dep'] as int?) ?? 15;
      a.value = max(0, (a.value * (1 - dep / 100)).round());
      a.condition = max(0, a.condition - 4 - rng.nextInt(4));
    }
    growth.add(('${a.name} value', a.value - before));
  }

  life.lastYear = lines;
  life.lastGrowth = growth;
  life.netWorthByAge[life.age] = life.netWorth;
  return feed;
}

// ---------------- Player actions on the Wealth tab ----------------

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

void deposit(Life life, int amount) {
  final a = min(amount, max(0, life.money));
  life.money -= a;
  life.savings += a;
}

void withdraw(Life life, int amount) {
  final a = min(amount, life.savings);
  life.savings -= a;
  life.money += a;
}

void invest(Life life, int amount) {
  final a = min(amount, max(0, life.money));
  life.money -= a;
  life.invested += a;
}

void sellFund(Life life, int amount) {
  final a = min(amount, life.invested);
  life.invested -= a;
  life.money += a;
}

ActionResult borrow(Life life, int amount) =>
    takeLoan(life, loanTypes.first, amount);

ActionResult repay(Life life, String name, int amount) {
  final a = min(amount, min(max(0, life.money), life.debts[name] ?? 0));
  life.money -= a;
  final left = (life.debts[name] ?? 0) - a;
  if (left <= 0) {
    life.debts.remove(name);
    life.rates.remove(name);
    if (name == 'Family loan') familyLoanPaid(life);
  } else {
    life.debts[name] = left;
  }
  return ActionResult(
    left <= 0
        ? 'Your ${name.toLowerCase()} is paid off. That feels good.'
        : 'You paid ${_m(a)} off your ${name.toLowerCase()}.',
    ['Money −${_m(a)}', if (left > 0) '${_m(left)} still owed'],
  );
}

ActionResult sellAsset(Life life, Asset a) {
  life.assets.remove(a);
  switch (a.kind) {
    case 'collectible':
      final (price, why) = collectibleSale(a);
      life.money += price;
      return ActionResult('You sold your ${a.name.toLowerCase()}.', [
        'Money +${_m(price)}',
        if (why != null) 'Why: $why',
      ]);
    case 'heirloom':
      life.money += a.value;
      return ActionResult(
        'You sold the family ${a.name.toLowerCase()}. ${sellHeirloomFallout(life, a)}',
        ['Money +${_m(a.value)}'],
      );
    case 'rental':
      life.flags.remove('own_flat');
      final deposit = (a.info['deposit'] as int?) ?? 0;
      life.money += deposit;
      return ActionResult('You handed back the keys and moved home.', [
        'Rent −${_m(a.yearlyCost)}/year',
        if (deposit > 0) 'Deposit returned: +${_m(deposit)}',
      ]);
    case 'house':
      final let = a.info['let'] == true;
      final debt = let ? 'Buy-to-let mortgage' : 'Mortgage';
      if (!let) life.flags.remove('owns_house');
      final fee = (a.value * 0.03).round();
      final mortgage = life.debts.remove(debt) ?? 0;
      life.rates.remove(debt);
      final net = a.value - fee - mortgage;
      life.money += net;
      return ActionResult(
        'You sold the ${a.name.toLowerCase()} for ${_m(a.value)}.',
        [
          'Money ${net >= 0 ? '+' : '−'}${_m(net)}',
          'Why: agent fee ${_m(fee)}${mortgage > 0 ? ', ${debt.toLowerCase()} ${_m(mortgage)} repaid' : ''}',
        ],
      );
    default:
      if (!life.assets.any((x) => x.kind == 'car')) {
        life.flags.remove('owns_car');
      }
      final loan = a.kind != 'car' || life.assets.any((x) => x.kind == 'car')
          ? 0
          : (life.debts.remove('Auto loan') ?? 0);
      life.money += a.value - loan;
      return ActionResult('You sold your ${a.name.toLowerCase()}.', [
        'Money +${_m(a.value - loan)}',
        if (loan > 0)
          'Why: the auto loan (${_m(loan)}) was repaid from the sale',
      ]);
  }
}

// ---------------- Buying (used by the Assets activities) ----------------

void addCar(Life life) => life.assets.add(
  Asset(
    id: 'car${life.age}',
    kind: 'car',
    name: 'Used car',
    value: 4000,
    yearlyCost: 1200,
    since: life.age,
    condition: 70,
  ),
);

void addRental(Life life) => life.assets.add(
  Asset(
    id: 'flat${life.age}',
    kind: 'rental',
    name: 'Rented flat',
    value: 0,
    yearlyCost: 9600,
    since: life.age,
  ),
);

/// Buys a house with a deposit and a 25-year mortgage. Returns the price.
/// (Tests and old saves; players buy through the listings in homes.dart.)
int addHouse(Life life, int deposit, Random rng) {
  final price = 160000 + rng.nextInt(16) * 5000;
  life.assets.removeWhere((a) => a.kind == 'rental');
  life.flags.remove('own_flat');
  life.assets.add(
    Asset(
      id: 'house${life.age}',
      kind: 'house',
      name: 'House',
      value: price,
      yearlyCost: 2500,
      since: life.age,
      condition: 75 + rng.nextInt(20),
    ),
  );
  life.debts['Mortgage'] = (life.debts['Mortgage'] ?? 0) + price - deposit;
  return price;
}
