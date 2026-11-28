import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/era_homes.dart';
import '../engine/era_houses.dart';
import '../engine/era_market.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_homes_screen.dart';
import 'era_houses_screen.dart';
import 'era_kit.dart';
import 'era_market_screen.dart';

/// The Wealth tab in an era life (Phase 2D): your purse and what the year
/// costs, where to keep money (a bank, a goldsmith, a trusted merchant),
/// where to borrow it, the Monte di Pietà, ventures, the dowry fund, and
/// your home, your things and the Great Houses. Replaces the "soon" card.
class EraWealthTab extends StatelessWidget {
  const EraWealthTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final bank = eraBankHere(life, era);
    final lender = eraLenderHere(life, era);
    final monte = eraMonteFrom(life, era);
    final ventures = eraVenturesHere(life, era);
    final stakes = eraStakes(life);
    final fund = eraDowryFundHere(life, era);
    final pawned = eraPawned(life);
    final living = life.age >= 16 ? era.price('living_year', era.regionOf(life), life.year) : 0;
    String m(int v) => eraM(life, v);
    void run(String title, String Function(Life, EraRules, Random) act) =>
        eraRun(context, controller, title, act, icon: Icons.account_balance_outlined);
    return EraBody(
      life: life,
      kicker: 'Wealth · ${life.city} ${life.year}',
      title: 'Your purse',
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m(life.money), style: eraHand(life, 40).copyWith(color: NF.text)),
          Text(
            [
              if (life.job != null && life.salary > 0) '${m(life.salary)} a year as ${life.job}',
              if (living > 0) 'living costs ${m(living)} a year',
              'worth ${m(eraNetWorth(life, era))} in all',
            ].join(' · '),
            style: NF.sora(14, color: NF.soft, height: 1.4),
          ),
        ],
      ),
      children: [
        EraCard(
          life: life,
          title: 'Keep it safe',
          children: [
            if (bank != null || eraDeposit(life) > 0)
              EraRow(
                first: true,
                title: eraDeposit(life) > 0
                    ? '${m(eraDeposit(life))} with ${eraDepositWith(life, era)}'
                    : 'Deposit with ${bank!['name']}',
                sub: bank?['about'] as String? ?? '',
                pill: eraDeposit(life) > 0 ? 'Manage' : 'Deposit',
                lock: eraDeposit(life) > 0 ? null : eraBankLock(life, era),
                onTap: () => _bankSheet(context, life, era),
              ),
            if (lender != null || eraLoan(life) > 0)
              EraRow(
                title: eraLoan(life) > 0
                    ? 'You owe ${m(eraLoan(life))} to ${(life.eraWorld['loan'] as Map)['name']}'
                    : 'Borrow from ${lender!['name']}',
                sub: eraLoan(life) > 0
                    ? 'It grows every year until it is paid'
                    : lender!['about'] as String,
                pill: eraLoan(life) > 0 ? 'Repay' : 'Borrow',
                lock: eraLoan(life) > 0 ? null : eraLoanLock(life, era),
                onTap: eraLoan(life) > 0
                    ? () => _amounts(context, life, 'Repay', min(eraLoan(life), life.money),
                          (a) => run('Repay', (l, e, _) => eraRepay(l, e, a)))
                    : () => _amounts(context, life, 'Borrow', eraLoanLimit(life, era),
                          (a) => run('Borrow', (l, e, _) => eraBorrow(l, e, a))),
              ),
            if (monte != null)
              EraRow(
                title: 'Pawn at the Monte di Pietà',
                sub: eraMonteOpen(life, era)
                    ? 'A loan on something you own, at about 6%'
                    : 'Opens in ${life.city} in $monte',
                pill: eraMonteOpen(life, era) ? 'Pawn' : '$monte',
                lock: !eraMonteOpen(life, era)
                    ? 'Opens in $monte'
                    : (eraOwned(life).isEmpty ? 'You own nothing to pawn' : null),
                onTap: () => _pawnSheet(context, life, era),
              ),
            for (final p in pawned)
              EraRow(
                title: 'Pawned: ${p['label']}',
                sub: 'Redeem for ${m(((p['loan'] as int) * 1.06).ceil())} by ${(p['year'] as int) + 2}',
                pill: 'Redeem',
                onTap: () => run('Redeem', (l, e, _) => eraRedeem(l, e, p['id'] as String)),
              ),
          ],
        ),
        if (ventures.isNotEmpty || stakes.isNotEmpty)
          EraCard(
            life: life,
            title: 'Ventures',
            note: life.year < 1602
                ? 'No shares yet: you put money into a voyage, a caravan or a shop, and share what comes back.'
                : null,
            children: [
              for (final (i, s) in stakes.indexed)
                EraRow(
                  first: i == 0,
                  title: s['label'] as String,
                  sub: 'Your ${m(s['stake'] as int)} is out. You will know next year.',
                  pill: 'Out',
                  filled: true,
                ),
              for (final (i, v) in ventures.where((v) => !stakes.any((s) => s['id'] == v['id'])).indexed)
                EraRow(
                  first: stakes.isEmpty && i == 0,
                  title: v['label'] as String,
                  sub: v['about'] as String,
                  pill: m(eraCost(life, era, v['cost'] as int)),
                  lock: eraVentureLock(life, era, v),
                  onTap: () => run(v['label'] as String, (l, e, _) => eraInvest(l, e, v['id'] as String)),
                ),
            ],
          ),
        if (fund != null || eraDowryFund(life) > 0)
          EraCard(
            life: life,
            title: 'The dowry fund',
            note: fund?['about'] as String?,
            children: [
              EraRow(
                first: true,
                title: eraDowryFund(life) > 0
                    ? '${m(eraDowryFund(life))} in ${fund?['name'] ?? 'the fund'}'
                    : 'Pay into ${fund!['name']}',
                sub: 'Paid out as a dowry when a daughter marries',
                pill: 'Pay in',
                lock: life.age < 16 ? 'When you are older.' : null,
                onTap: () => _amounts(context, life, 'Pay in', life.money,
                    (a) => run('The dowry fund', (l, e, _) => eraPayDowryFund(l, e, a))),
              ),
            ],
          ),
        EraCard(
          life: life,
          title: 'What you have',
          children: [
            EraRow(
              first: true,
              title: 'Home',
              sub: eraHomeLine(life, era),
              pill: '›',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraHomesScreen(controller: controller)),
              ),
            ),
            EraRow(
              title: 'Things you own',
              sub: eraOwned(life).isEmpty
                  ? 'Nothing much yet'
                  : [for (final id in eraOwned(life)) eraItem(life, era, id)?['label'] as String? ?? id].join(', '),
              pill: '›',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraMarketScreen(controller: controller)),
              ),
            ),
            EraRow(
              title: 'The Great Houses',
              sub: eraHouseRank(life, era) != null
                  ? '${eraYourHouse(life)}: number ${eraHouseRank(life, era)}'
                  : 'Your house: not yet on the list',
              pill: '›',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraHousesScreen(controller: controller)),
              ),
            ),
          ],
        ),
        if (era.wealthData['note'] != null)
          Text(
            era.wealthData['note'] as String,
            style: NF.sora(12, color: NF.muted, height: 1.4),
          ),
      ],
    );
  }

  void _bankSheet(BuildContext context, Life life, EraRules era) {
    void run(String t, String Function(Life, EraRules, Random) a) =>
        eraRun(context, controller, t, a, icon: Icons.account_balance_outlined);
    if (eraDeposit(life) <= 0) {
      _amounts(context, life, 'Deposit', life.money,
          (a) => run('Deposit', (l, e, _) => eraDepositMoney(l, e, a)));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eraDepositWith(life, era) ?? 'The bank', style: eraHand(life, 28)),
              EraRow(
                first: true,
                title: 'Put more in',
                sub: 'From your purse',
                pill: 'Deposit',
                lock: eraBankLock(life, era) ?? (life.money <= 0 ? 'Your purse is empty.' : null),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _amounts(context, life, 'Deposit', life.money,
                      (a) => run('Deposit', (l, e, _) => eraDepositMoney(l, e, a)));
                },
              ),
              EraRow(
                title: 'Take money out',
                sub: 'Into your purse',
                pill: 'Withdraw',
                onTap: () {
                  Navigator.of(sheet).pop();
                  _amounts(context, life, 'Withdraw', eraDeposit(life),
                      (a) => run('Withdraw', (l, e, _) => eraWithdrawMoney(l, e, a)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pawnSheet(BuildContext context, Life life, EraRules era) {
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What will you pawn?', style: eraHand(life, 28)),
              for (final (i, id) in eraOwned(life).indexed)
                EraRow(
                  first: i == 0,
                  title: eraItem(life, era, id)?['label'] as String? ?? id,
                  sub: 'The Monte lends two-thirds of its price',
                  pill: 'Pawn',
                  onTap: () {
                    Navigator.of(sheet).pop();
                    eraRun(context, controller, 'The Monte di Pietà', (l, e, _) => eraPawn(l, e, id));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks an amount: a few round sums, half and all of [most].
void _amounts(
  BuildContext context,
  Life life,
  String title,
  int most,
  void Function(int) pick,
) {
  if (most <= 0) return;
  final options = <int>{
    for (final v in [10, 50, 200, 1000])
      if (v < most) v,
    if (most >= 4) most ~/ 2,
    most,
  }.toList()
    ..sort();
  showModalBottomSheet(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: eraHand(life, 28)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in options)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      pick(v);
                    },
                    child: EraPill(v == most ? 'All: ${eraM(life, v)}' : eraM(life, v)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
