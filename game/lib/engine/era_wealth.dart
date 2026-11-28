/// Money in an era life (Legends plan §5.6, Phase 2D): where to keep it
/// (a bank where there is one, a goldsmith's box, a merchant's trust),
/// where to borrow it, the Monte di Pietà pawn bank where and when one
/// existed, ventures in place of shares (real shares only from the VOC in
/// 1602), and Florence's dowry fund. Every amount is kept in florins and
/// shown in the local money. Only timeline lives reach this file; modern
/// money (finance.dart, economy.dart) never runs in them.
library;

import 'dart:math';

import 'currency.dart';
import 'era_homes.dart';
import 'era_justice.dart' show eraInside;
import 'era_market.dart';
import 'eras.dart';
import 'models.dart';

/// A price from the 2D tables (florins in Florence, 1450) for this life's
/// place and year.
int eraCost(Life l, EraRules era, num base) {
  if (base <= 0) return 0;
  return max(
    1,
    (base * era.regionOf(l).priceScale * era.priceLevel(l.year)).round(),
  );
}

String eraM(Life l, int florins) => moneyIn(florins, l.country);

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

// ---------------- Banks ----------------

/// The bank (or strongbox, or trusted merchant) of this place and year.
Map<String, dynamic>? eraBankHere(Life l, EraRules era) =>
    eraFirst(era.wealthData['banks'] as List?, l, era);

Map<String, dynamic>? _bankById(EraRules era, String? id) {
  for (final b in (era.wealthData['banks'] as List?) ?? const []) {
    if ((b as Map)['id'] == id) return Map<String, dynamic>.from(b);
  }
  return null;
}

/// What you have deposited, and with whom.
int eraDeposit(Life l) => _int((l.eraWorld['bank'] as Map?)?['amount']);

String? eraDepositWith(Life l, EraRules era) {
  final id = (l.eraWorld['bank'] as Map?)?['id'] as String?;
  return _bankById(era, id)?['name'] as String?;
}

String? eraBankLock(Life l, EraRules era) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 14) return 'When you are older.';
  if (eraInside(l)) return 'Not while you are held.';
  if (eraBankHere(l, era) == null) return 'No bank here.';
  return null;
}

String eraDepositMoney(Life l, EraRules era, int amount) {
  final lock = eraBankLock(l, era);
  if (lock != null) return lock;
  final bank = eraBankHere(l, era)!;
  final held = l.eraWorld['bank'] as Map?;
  if (held != null && held['id'] != bank['id'] && eraDeposit(l) > 0) {
    return 'Your money is still with ${eraDepositWith(l, era)}. Take it out first.';
  }
  amount = min(amount, l.money);
  if (amount <= 0) return 'Your purse is empty.';
  l.money -= amount;
  l.eraWorld['bank'] = {'id': bank['id'], 'amount': eraDeposit(l) + amount};
  return 'You left ${eraM(l, amount)} with ${bank['name']}.';
}

String eraWithdrawMoney(Life l, EraRules era, int amount) {
  if (eraInside(l)) return 'Not while you are held.';
  amount = min(amount, eraDeposit(l));
  if (amount <= 0) return 'Nothing to take out.';
  final m = l.eraWorld['bank'] as Map;
  l.money += amount;
  final left = eraDeposit(l) - amount;
  if (left <= 0) {
    l.eraWorld.remove('bank');
  } else {
    l.eraWorld['bank'] = {'id': m['id'], 'amount': left};
  }
  return 'You took ${eraM(l, amount)} back into your purse.';
}

// ---------------- Lenders ----------------

Map<String, dynamic>? eraLenderHere(Life l, EraRules era) =>
    eraFirst(era.wealthData['lenders'] as List?, l, era);

/// What you owe, with the lender's name and yearly rate.
int eraLoan(Life l) => _int((l.eraWorld['loan'] as Map?)?['amount']);

/// The most a lender here will give you.
int eraLoanLimit(Life l, EraRules era) {
  final base = 20 + l.salary * 2 + eraHomesValue(l) ~/ 4;
  return max(0, eraCost(l, era, base) - eraLoan(l));
}

String? eraLoanLock(Life l, EraRules era) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 16) return 'Nobody lends to a child.';
  if (eraInside(l)) return 'Not while you are held.';
  final lender = eraLenderHere(l, era);
  if (lender == null) return 'No lender here.';
  if (lender['trust'] == true &&
      ((l.eraWorld['standing'] as int?) ?? 0) < 1 &&
      l.age < 25) {
    return 'He lends only to people of good name.';
  }
  if (eraLoanLimit(l, era) <= 0) return 'He will lend you no more.';
  return null;
}

String eraBorrow(Life l, EraRules era, int amount) {
  final lock = eraLoanLock(l, era);
  if (lock != null) return lock;
  final lender = eraLenderHere(l, era)!;
  amount = min(amount, eraLoanLimit(l, era));
  l.money += amount;
  l.eraWorld['loan'] = {
    'amount': eraLoan(l) + amount,
    'rate': (lender['rate'] as num).toDouble(),
    'name': lender['name'],
  };
  return 'You borrowed ${eraM(l, amount)} from ${lender['name']}.';
}

String eraRepay(Life l, EraRules era, int amount) {
  amount = min(amount, min(eraLoan(l), l.money));
  if (amount <= 0) return l.money <= 0 ? 'Your purse is empty.' : 'You owe nothing.';
  final m = Map<String, dynamic>.from(l.eraWorld['loan'] as Map);
  l.money -= amount;
  final left = eraLoan(l) - amount;
  if (left <= 0) {
    l.eraWorld.remove('loan');
    return 'You paid off ${m['name']}. You owe nothing now.';
  }
  m['amount'] = left;
  l.eraWorld['loan'] = m;
  return 'You paid ${eraM(l, amount)}. Still owed: ${eraM(l, left)}.';
}

// ---------------- The Monte di Pietà ----------------

/// The year the pawn bank opens in this city, or null if never (in this
/// era's data).
int? eraMonteFrom(Life l, EraRules era) {
  for (final m in (era.wealthData['montes'] as List?) ?? const []) {
    if (((m as Map)['cities'] as List).contains(l.city)) return m['from'] as int;
  }
  return null;
}

bool eraMonteOpen(Life l, EraRules era) {
  final from = eraMonteFrom(l, era);
  return from != null && l.year >= from;
}

List<Map<String, dynamic>> eraPawned(Life l) => [
  for (final p in (l.eraWorld['pawned'] as List?) ?? const [])
    Map<String, dynamic>.from(p as Map),
];

/// Pawns something you own at the Monte: two-thirds of its price, back
/// for the loan and 6% within two years.
String eraPawn(Life l, EraRules era, String itemId) {
  if (!eraMonteOpen(l, era)) return 'There is no Monte di Pietà here.';
  final item = eraItem(l, era, itemId);
  if (item == null || !eraOwns(l, itemId)) return 'You do not own that.';
  final loan = max(1, eraCost(l, era, _int(item['cost'])) * 2 ~/ 3);
  eraDisown(l, itemId);
  l.money += loan;
  l.eraWorld['pawned'] = [
    ...eraPawned(l),
    {'id': itemId, 'label': item['label'], 'loan': loan, 'year': l.year},
  ];
  return 'The Monte lent you ${eraM(l, loan)} on ${eraLower(item['label'] as String)}. Redeem it within two years.';
}

String eraRedeem(Life l, EraRules era, String itemId) {
  final list = eraPawned(l);
  final p = list.where((p) => p['id'] == itemId).firstOrNull;
  if (p == null) return 'Nothing pawned.';
  final due = (_int(p['loan']) * 1.06).ceil();
  if (l.money < due) return 'Needs ${eraM(l, due)}.';
  l.money -= due;
  list.remove(p);
  l.eraWorld['pawned'] = list;
  eraOwn(l, itemId);
  return 'You paid ${eraM(l, due)} and took back ${eraLower(p['label'] as String)}.';
}

// ---------------- Ventures ----------------

List<Map<String, dynamic>> eraVenturesHere(Life l, EraRules era) => [
  for (final v in (era.wealthData['ventures'] as List?) ?? const [])
    if (eraScoped(v as Map, l, era)) Map<String, dynamic>.from(v),
];

/// Your stakes at sea, on the road or in a shop, waiting for next year.
List<Map<String, dynamic>> eraStakes(Life l) => [
  for (final v in (l.eraWorld['ventures'] as List?) ?? const [])
    Map<String, dynamic>.from(v as Map),
];

String? eraVentureLock(Life l, EraRules era, Map v) {
  if (!l.alive) return 'This life is over.';
  if (l.age < 16) return 'When you are older.';
  if (eraInside(l)) return 'Not while you are held.';
  if (eraStakes(l).any((s) => s['id'] == v['id'])) return 'Your share is out. Back next year.';
  final cost = eraCost(l, era, _int(v['cost']));
  if (l.money < cost) return 'Needs ${eraM(l, cost)}.';
  return null;
}

String eraInvest(Life l, EraRules era, String id) {
  final v = eraVenturesHere(l, era).where((v) => v['id'] == id).firstOrNull;
  if (v == null) return 'Not here, not now.';
  final lock = eraVentureLock(l, era, v);
  if (lock != null) return lock;
  final cost = eraCost(l, era, _int(v['cost']));
  l.money -= cost;
  l.eraWorld['ventures'] = [
    ...eraStakes(l),
    {
      'id': v['id'],
      'label': v['label'],
      'stake': cost,
      'ret': v['ret'],
      'risk': v['risk'],
      'lost': v['lost'],
      'year': l.year,
    },
  ];
  return 'You put ${eraM(l, cost)} into ${eraLower(v['label'] as String)}. You will know next year.';
}

// ---------------- The dowry fund ----------------

Map<String, dynamic>? eraDowryFundHere(Life l, EraRules era) {
  final f = era.wealthData['dowryFund'] as Map?;
  if (f == null || !eraScoped(f, l, era)) return null;
  return Map<String, dynamic>.from(f);
}

int eraDowryFund(Life l) => _int(l.eraWorld['dowryFund']);

String eraPayDowryFund(Life l, EraRules era, int amount) {
  final f = eraDowryFundHere(l, era);
  if (f == null && eraDowryFund(l) == 0) return 'There is no dowry fund here.';
  if (l.age < 16) return 'When you are older.';
  amount = min(amount, l.money);
  if (amount <= 0) return 'Your purse is empty.';
  l.money -= amount;
  l.eraWorld['dowryFund'] = eraDowryFund(l) + amount;
  return 'You paid ${eraM(l, amount)} into ${f?['name'] ?? 'the dowry fund'}. It pays out when a daughter marries.';
}

// ---------------- Net worth ----------------

/// Purse, deposits, the dowry fund, homes, stakes and things, less debts.
int eraNetWorth(Life l, EraRules era) {
  final stakes = eraStakes(l).fold<int>(0, (a, s) => a + _int(s['stake']));
  return l.money +
      eraDeposit(l) +
      eraDowryFund(l) +
      eraHomesValue(l) +
      stakes +
      eraThingsValue(l, era) -
      eraLoan(l);
}

// ---------------- The year ----------------

/// One year of money at a birthday: interest, a bank that fails, debts
/// that grow, pledges the Monte sells, ventures that come home (or don't),
/// and the dowry fund. Returns feed lines.
List<String> eraWealthYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  // The bank.
  final held = l.eraWorld['bank'] as Map?;
  if (held != null && eraDeposit(l) > 0) {
    final bank = _bankById(era, held['id'] as String?);
    final failYears = List<int>.from((bank?['failYears'] as List?) ?? const []);
    final fails =
        bank != null &&
        (failYears.contains(l.year) ||
            rng.nextDouble() < ((bank['fail'] as num?) ?? 0).toDouble());
    if (fails) {
      final lose = (eraDeposit(l) * ((bank['lose'] as num?) ?? 0.5)).round();
      final left = eraDeposit(l) - lose;
      l.eraWorld['bank'] = {'id': held['id'], 'amount': left};
      if (left <= 0) l.eraWorld.remove('bank');
      out.add(
        '${bank['fall'] ?? '${eraUp(bank['name'] as String)} has failed.'} You lost ${eraM(l, lose)}.',
      );
      l.stats.add('happiness', -6);
    } else {
      final rate = ((bank?['rate'] as num?) ?? 0).toDouble();
      final gain = (eraDeposit(l) * rate).floor();
      if (gain > 0) {
        l.eraWorld['bank'] = {'id': held['id'], 'amount': eraDeposit(l) + gain};
        l.lastYear.add(('Interest', gain));
      }
    }
  }
  // The loan grows by its rate.
  final loan = l.eraWorld['loan'] as Map?;
  if (loan != null && eraLoan(l) > 0) {
    final rate = ((loan['rate'] as num?) ?? 0).toDouble();
    final add = (eraLoan(l) * rate).ceil();
    if (add > 0) {
      l.eraWorld['loan'] = {...loan, 'amount': eraLoan(l) + add};
      out.add('${eraUp(loan['name'] as String)} added ${eraM(l, add)} to what you owe.');
    }
    if (eraLoan(l) > eraCost(l, era, 200 + l.salary * 4)) {
      l.stats.add('happiness', -4);
      out.add('Your debts keep you awake. The lender has started to call at the door.');
    }
  }
  // Pledges at the Monte: sold after two years.
  final pawned = eraPawned(l);
  final kept = <Map<String, dynamic>>[];
  for (final p in pawned) {
    if (l.year - _int(p['year']) >= 2) {
      out.add('The Monte sold ${eraLower(p['label'] as String)} at auction. You never redeemed it.');
    } else {
      kept.add(p);
    }
  }
  if (pawned.isNotEmpty) l.eraWorld['pawned'] = kept;
  // Ventures from last year come home.
  final stakes = eraStakes(l);
  final still = <Map<String, dynamic>>[];
  for (final s in stakes) {
    if (_int(s['year']) >= l.year) {
      still.add(s);
      continue;
    }
    final risk = ((s['risk'] as num?) ?? 0.1).toDouble();
    final stake = _int(s['stake']);
    if (rng.nextDouble() < risk) {
      out.add('${s['lost'] ?? 'Your venture failed.'} Your ${eraM(l, stake)} is gone.');
      l.stats.add('happiness', -4);
    } else {
      final ret = ((s['ret'] as num?) ?? 1.2).toDouble();
      // Good years and lean years.
      final back = (stake * (ret - 0.15 + rng.nextDouble() * 0.3)).round();
      l.money += back;
      l.lastYear.add((eraUp(s['label'] as String), back - stake));
      out.add(
        back >= stake
            ? '${eraUp(s['label'] as String)} came home: ${eraM(l, back)} for your ${eraM(l, stake)}.'
            : '${eraUp(s['label'] as String)} came home poor: ${eraM(l, back)} for your ${eraM(l, stake)}.',
      );
      if (back > stake) l.stats.add('happiness', 3);
    }
  }
  if (stakes.isNotEmpty) l.eraWorld['ventures'] = still;
  // The dowry fund grows.
  if (eraDowryFund(l) > 0) {
    final rate =
        (((era.wealthData['dowryFund'] as Map?)?['rate'] as num?) ?? 0.08)
            .toDouble();
    l.eraWorld['dowryFund'] = (eraDowryFund(l) * (1 + rate)).round();
  }
  return out;
}

String eraLower(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
String eraUp(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
