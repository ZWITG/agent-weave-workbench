import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/era_homes.dart';
import '../engine/era_houses.dart';
import '../engine/era_market.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import 'era_art.dart';
import 'era_homes_screen.dart';
import 'era_houses_screen.dart';
import 'era_kit.dart' show eraCap, eraRun;
import 'era_market_screen.dart';
import 'result_popup.dart';

/// The Wealth tab in an era life, drawn as a merchant's counting house:
/// a coin stack for your purse, the year as a ledger (money in, money
/// out), banks, lenders and the Monte as wax seals, ventures as a voyage
/// on a map, the dowry chest, and gold seals to your home, your things
/// and the Great Houses.
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
    final home = eraHomeNow(life, era);
    String m(int v) => eraM(life, v);
    void run(String title, String Function(Life, EraRules, Random) act) =>
        eraRun(context, controller, title, act, icon: Icons.account_balance_outlined);
    void locked(String title, String why) =>
        showResultPopup(context, ActionResult(why), title: title, icon: Icons.lock_outline);

    // The ledger: money in, money out.
    final ins = <(String, int?)>[
      if (life.job != null && life.salary > 0) ('Pay as ${life.job}', life.salary),
      for (final s in stakes) (_short(s['label'] as String), null),
    ];
    final outs = <(String, int?)>[
      if (living > 0) ('Bread, wine and candles', living),
      if (home != null && eraRents(life) && home.rent > 0) ('Rent', home.rent),
      if (home != null && !eraRents(life) && home.upkeep > 0) ('Upkeep of the house', home.upkeep),
      if (eraLoan(life) > 0) ('The loan grows', null),
    ];
    final inSum = ins.fold(0, (a, e) => a + (e.$2 ?? 0));
    final outSum = outs.fold(0, (a, e) => a + (e.$2 ?? 0));

    final deposit = eraDeposit(life);
    final loan = eraLoan(life);
    final children = <Widget>[
      inkKicker('Wealth · ${life.city} ${life.year}'),
      const SizedBox(height: 8),
      Row(
        children: [
          CoinStack(money: life.money),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(m(life.money), style: hand(54, color: EraInk.ink, height: 0.95)),
                ),
                Text(
                  'in your purse · worth ${m(eraNetWorth(life, era))} in all',
                  style: fell(14.5, color: EraInk.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _Ledger(
        ins: [for (final e in ins) (e.$1, e.$2 == null ? '…' : m(e.$2!))],
        outs: [for (final e in outs) (e.$1, e.$2 == null ? '…' : m(e.$2!))],
        inTotal: '+${m(inSum)}',
        outTotal: '−${m(outSum)}',
      ),
      if (bank != null || deposit > 0 || lender != null || loan > 0 || monte != null) ...[
        _heading('Keep it safe'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bank != null || deposit > 0)
              Expanded(
                child: SealButton(
                  mark: _mark(deposit > 0 ? eraDepositWith(life, era) : bank?['name'] as String?),
                  title: eraCap(deposit > 0 ? (eraDepositWith(life, era) ?? 'The bank') : bank!['name'] as String),
                  line: deposit > 0 ? '${m(deposit)} kept' : (eraBankLock(life, era) ?? 'Deposit'),
                  off: deposit <= 0 && eraBankLock(life, era) != null,
                  onTap: deposit <= 0 && eraBankLock(life, era) != null
                      ? () => locked('The bank', eraBankLock(life, era)!)
                      : () => _bankSheet(context, life, era),
                ),
              ),
            if (lender != null || loan > 0)
              Expanded(
                child: SealButton(
                  mark: loan > 0 ? '!' : _mark(lender?['name'] as String?),
                  color: loan > 0 ? EraInk.red2 : EraInk.red,
                  title: eraCap(loan > 0 ? (life.eraWorld['loan'] as Map)['name'] as String : lender!['name'] as String),
                  line: loan > 0 ? 'You owe ${m(loan)}' : (eraLoanLock(life, era) ?? 'Borrow'),
                  off: loan <= 0 && eraLoanLock(life, era) != null,
                  onTap: loan > 0
                      ? () => _amounts(context, 'Repay', min(loan, life.money), (a) => run('Repay', (l, e, _) => eraRepay(l, e, a)), m)
                      : eraLoanLock(life, era) != null
                      ? () => locked('Borrowing', eraLoanLock(life, era)!)
                      : () => _amounts(
                          context,
                          'Borrow',
                          eraLoanLimit(life, era),
                          (a) => run('Borrow', (l, e, _) => eraBorrow(l, e, a)),
                          m,
                        ),
                ),
              ),
            if (monte != null)
              Expanded(
                child: SealButton(
                  mark: 'MP',
                  color: EraInk.green,
                  title: 'Monte di Pietà',
                  line: !eraMonteOpen(life, era)
                      ? 'Opens $monte'
                      : (eraOwned(life).isEmpty ? 'Nothing to pawn' : 'Pawn at ~6%'),
                  off: !eraMonteOpen(life, era) || eraOwned(life).isEmpty,
                  onTap: !eraMonteOpen(life, era)
                      ? () => locked('The Monte di Pietà', 'It opens in ${life.city} in $monte.')
                      : eraOwned(life).isEmpty
                      ? () => locked('The Monte di Pietà', 'You own nothing to pawn yet. Buy something at the market.')
                      : () => _pawnSheet(context, life, era),
                ),
              ),
          ],
        ),
        for (final p in pawned)
          _LineItem(
            glyph: 'chest',
            title: 'Pawned: ${p['label']}',
            sub: 'Redeem for ${m(((p['loan'] as int) * 1.06).ceil())} by ${(p['year'] as int) + 2}',
            action: 'Redeem',
            onTap: () => run('Redeem', (l, e, _) => eraRedeem(l, e, p['id'] as String)),
          ),
      ],
      if (ventures.isNotEmpty || stakes.isNotEmpty) ...[
        _heading('Ventures'),
        if (life.year < 1602)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No shares yet: you put money into a voyage, a caravan or a shop, and share what comes back.',
              style: fell(14, color: EraInk.ink2),
            ),
          ),
        for (final s in stakes)
          _Voyage(
            label: s['label'] as String,
            from: life.city,
            mode: _mode(s['id'] as String),
            progress: 0.5,
            tag: null,
            line: 'Your ${m(s['stake'] as int)} is out. You will know next year.',
          ),
        for (final v in ventures.where((v) => !stakes.any((s) => s['id'] == v['id'])))
          _Voyage(
            label: v['label'] as String,
            from: life.city,
            mode: _mode(v['id'] as String),
            progress: 0.06,
            tag: _risk(v),
            line: v['about'] as String,
            action: m(eraCost(life, era, v['cost'] as int)),
            lock: eraVentureLock(life, era, v),
            onTap: () => run(v['label'] as String, (l, e, _) => eraInvest(l, e, v['id'] as String)),
            onLocked: (why) => locked(v['label'] as String, why),
          ),
      ],
      if (fund != null || eraDowryFund(life) > 0) ...[
        _heading('The dowry chest'),
        _LineItem(
          glyph: 'chest',
          title: eraDowryFund(life) > 0
              ? '${m(eraDowryFund(life))} in ${fund?['name'] ?? 'the fund'}'
              : eraCap(fund!['name'] as String),
          sub: fund?['about'] as String? ?? 'Paid out as a dowry when a daughter marries',
          action: 'Pay in',
          onTap: life.age < 16
              ? () => locked('The dowry fund', 'When you are older.')
              : () => _amounts(
                  context,
                  'Pay in',
                  life.money,
                  (a) => run('The dowry fund', (l, e, _) => eraPayDowryFund(l, e, a)),
                  m,
                ),
        ),
      ],
      _heading('What you have'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SealButton(
              mark: '',
              glyph: 'home',
              color: EraInk.gold2,
              title: 'Home',
              line: eraHomeLine(life, era),
              lineColor: EraInk.ink2,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraHomesScreen(controller: controller)),
              ),
            ),
          ),
          Expanded(
            child: SealButton(
              mark: '${eraOwned(life).length}',
              color: EraInk.gold2,
              title: 'Things you own',
              line: eraOwned(life).isEmpty ? 'The market' : 'and the market',
              lineColor: EraInk.ink2,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraMarketScreen(controller: controller)),
              ),
            ),
          ),
          Expanded(
            child: SealButton(
              mark: eraHouseRank(life, era) != null ? '${eraHouseRank(life, era)}' : '',
              glyph: eraHouseRank(life, era) != null ? null : 'crown',
              color: EraInk.gold2,
              title: 'The Great Houses',
              line: eraHouseRank(life, era) != null ? '${eraYourHouse(life)} is listed' : 'Not yet listed',
              lineColor: EraInk.ink2,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EraHousesScreen(controller: controller)),
              ),
            ),
          ),
        ],
      ),
      if (era.wealthData['note'] != null) ...[
        const SizedBox(height: 16),
        Text(era.wealthData['note'] as String, style: fell(12.5, color: EraInk.ink2, italic: true)),
      ],
    ];
    return CustomPaint(
      painter: const LedgerPaperPainter(margin: 22),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(38, 10, 18, 28),
        children: children,
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text, style: hand(30)),
  );

  /// "the Medici bank" → "M".
  static String _mark(String? name) {
    final words = (name ?? 'Bank')
        .replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F ]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty && !const {'a', 'an', 'the', 'A', 'An', 'The'}.contains(w))
        .toList();
    if (words.isEmpty) return 'B';
    final caps = words.where((w) => w[0] == w[0].toUpperCase());
    return (caps.isNotEmpty ? caps.first : words.first).characters.first.toUpperCase();
  }

  static String _short(String label) => label.replaceFirst(RegExp(r'^A (share|qirad share) in (a |an |the )?'), '');

  static String _mode(String id) => switch (id) {
    'caravan' => 'camel',
    'silk' || 'wool' || 'florence_venture' || 'copper' || 'milan_arms' || 'rome_alum' => 'shop',
    _ => 'ship',
  };

  static (String, Color) _risk(Map v) {
    final risk = (v['risk'] as num?)?.toDouble() ?? 0.1;
    final ret = (v['ret'] as num?)?.toDouble() ?? 1.2;
    final word = risk >= 0.2 ? 'RISKY' : (risk >= 0.1 ? 'FAIR' : 'SAFE');
    final color = risk >= 0.2 ? EraInk.red : (risk >= 0.1 ? EraInk.sea : EraInk.green);
    return ('$word · ×${ret.toStringAsFixed(ret * 10 % 1 == 0 ? 1 : 2)}', color);
  }

  void _bankSheet(BuildContext context, Life life, EraRules era) {
    void run(String t, String Function(Life, EraRules, Random) a) =>
        eraRun(context, controller, t, a, icon: Icons.account_balance_outlined);
    String m(int v) => eraM(life, v);
    if (eraDeposit(life) <= 0) {
      _amounts(context, 'Deposit', life.money, (a) => run('Deposit', (l, e, _) => eraDepositMoney(l, e, a)), m);
      return;
    }
    final lock = eraBankLock(life, era) ?? (life.money <= 0 ? 'Your purse is empty.' : null);
    _sheet(
      context,
      eraCap(eraDepositWith(life, era) ?? 'The bank'),
      (sheet) => [
        _LineItem(
          glyph: 'coin',
          title: 'Put more in',
          sub: lock ?? 'From your purse',
          action: 'Deposit',
          dim: lock != null,
          onTap: lock != null
              ? null
              : () {
                  Navigator.of(sheet).pop();
                  _amounts(context, 'Deposit', life.money, (a) => run('Deposit', (l, e, _) => eraDepositMoney(l, e, a)), m);
                },
        ),
        _LineItem(
          glyph: 'chest',
          title: 'Take money out',
          sub: '${m(eraDeposit(life))} kept · into your purse',
          action: 'Withdraw',
          onTap: () {
            Navigator.of(sheet).pop();
            _amounts(
              context,
              'Withdraw',
              eraDeposit(life),
              (a) => run('Withdraw', (l, e, _) => eraWithdrawMoney(l, e, a)),
              m,
            );
          },
        ),
      ],
    );
  }

  void _pawnSheet(BuildContext context, Life life, EraRules era) => _sheet(
    context,
    'What will you pawn?',
    (sheet) => [
      for (final id in eraOwned(life))
        _LineItem(
          glyph: _itemGlyph(id),
          title: eraItem(life, era, id)?['label'] as String? ?? id,
          sub: 'The Monte lends two-thirds of its price',
          action: 'Pawn',
          onTap: () {
            Navigator.of(sheet).pop();
            eraRun(context, controller, 'The Monte di Pietà', (l, e, _) => eraPawn(l, e, id));
          },
        ),
    ],
  );
}

String _itemGlyph(String id) => switch (id) {
  'silk' => 'doublet',
  'copper' => 'pot',
  'spice' => 'sack',
  _ => id,
};

/// A paper sheet that slides up with a hand-lettered title.
void _sheet(BuildContext context, String title, List<Widget> Function(BuildContext) rows) =>
    showModalBottomSheet(
      context: context,
      backgroundColor: EraInk.paper,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title, style: hand(30)), const SizedBox(height: 6), ...rows(sheet)],
          ),
        ),
      ),
    );

/// Picks an amount: a few round sums, half and all of [most], as coins.
void _amounts(BuildContext context, String title, int most, void Function(int) pick, String Function(int) m) {
  if (most <= 0) return;
  final options = <int>{
    for (final v in [10, 50, 200, 1000])
      if (v < most) v,
    if (most >= 4) most ~/ 2,
    most,
  }.toList()..sort();
  _sheet(
    context,
    title,
    (sheet) => [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in options)
            InkButton(
              v == most ? 'All: ${m(v)}' : m(v),
              light: v != most,
              onTap: () {
                Navigator.of(sheet).pop();
                pick(v);
              },
            ),
        ],
      ),
    ],
  );
}

/// The year in the ledger: two ruled columns and a double-ruled total.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.ins, required this.outs, required this.inTotal, required this.outTotal});
  final List<(String, String)> ins;
  final List<(String, String)> outs;
  final String inTotal;
  final String outTotal;

  @override
  Widget build(BuildContext context) {
    final rows = max(max(ins.length, outs.length), 1);
    Widget cell(List<(String, String)> list, int i, {bool right = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: right ? null : const Border(right: BorderSide(color: EraInk.ink, width: 1.5)),
      ),
      child: i < list.length
          ? Row(
              children: [
                Expanded(
                  child: Text(list[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: fell(13.5)),
                ),
                Text(list[i].$2, style: fell(13.5)),
              ],
            )
          : Text(i == 0 ? 'Nothing yet' : '', style: fell(13.5, color: EraInk.ink2, italic: true)),
    );
    Widget head(String t, {bool right = false}) => Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: EraInk.ink, width: 1.5),
          right: right ? BorderSide.none : const BorderSide(color: EraInk.ink, width: 1.5),
        ),
      ),
      child: Text(t.toUpperCase(), style: fell(10.5, color: EraInk.red).copyWith(letterSpacing: 1.6)),
    );
    Widget total(String t, Color c, {bool right = false}) => Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: EraInk.ink, width: 3, style: BorderStyle.solid),
          right: right ? BorderSide.none : const BorderSide(color: EraInk.ink, width: 1.5),
        ),
      ),
      child: Text(t, style: hand(28, color: c)),
    );
    return Container(
      decoration: BoxDecoration(
        color: EraInk.card,
        border: Border.all(color: EraInk.ink, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: head('Money in · dare')),
              Expanded(child: head('Money out · avere', right: true)),
            ],
          ),
          for (var i = 0; i < rows; i++)
            Row(
              children: [
                Expanded(child: cell(ins, i)),
                Expanded(child: cell(outs, i, right: true)),
              ],
            ),
          Row(
            children: [
              Expanded(child: total(inTotal, EraInk.green)),
              Expanded(child: total(outTotal, EraInk.red, right: true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A venture: a sea (or desert, or street) map with the route and your
/// money on its way.
class _Voyage extends StatelessWidget {
  const _Voyage({
    required this.label,
    required this.from,
    required this.mode,
    required this.progress,
    required this.tag,
    required this.line,
    this.action,
    this.lock,
    this.onTap,
    this.onLocked,
  });
  final String label;
  final String from;
  final String mode;
  final double progress;
  final (String, Color)? tag;
  final String line;
  final String? action;
  final String? lock;
  final VoidCallback? onTap;
  final void Function(String)? onLocked;

  @override
  Widget build(BuildContext context) {
    final sea = mode == 'ship';
    final bg = switch (mode) {
      'camel' => const Color(0xFFF1E0B8),
      'shop' => const Color(0xFFF2E6D2),
      _ => const Color(0xFFE5EEE8),
    };
    return GestureDetector(
      onTap: action == null ? null : (lock != null ? () => onLocked?.call(lock!) : onTap),
      child: Opacity(
        opacity: lock != null ? 0.62 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: EraInk.ink, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: fell(15.5))),
                  if (tag != null) InkTag(tag!.$1, color: tag!.$2),
                ],
              ),
              SizedBox(
                height: 50,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RoutePainter(mode: mode, progress: progress, from: from, sea: sea),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(lock ?? line, style: fell(13, color: lock != null ? EraInk.red : EraInk.ink2, italic: lock != null)),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    InkButton(action!, onTap: lock != null ? () => onLocked?.call(lock!) : onTap),
                  ] else
                    const InkTag('AT SEA', color: EraInk.ink2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.mode, required this.progress, required this.from, required this.sea});
  final String mode;
  final double progress;
  final String from;
  final bool sea;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(8, h * 0.72)
      ..cubicTo(w * 0.3, h * 0.05, w * 0.55, h * 1.0, w - 8, h * 0.22);
    // Waves, dunes or rooftops behind the route.
    final faint = Paint()
      ..color = EraInk.ink.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rng = Random(mode.hashCode);
    for (var i = 0; i < 6; i++) {
      final x = rng.nextDouble() * (w - 30), y = 8 + rng.nextDouble() * (h - 16);
      switch (mode) {
        case 'camel':
          canvas.drawArc(Rect.fromLTWH(x, y, 26, 12), pi, pi, false, faint);
        case 'shop':
          canvas.drawRect(Rect.fromLTWH(x, y, 12, 14), faint);
        default:
          canvas.drawPath(
            Path()
              ..moveTo(x, y)
              ..quadraticBezierTo(x + 5, y - 4, x + 10, y)
              ..quadraticBezierTo(x + 15, y + 4, x + 20, y),
            faint,
          );
      }
    }
    final dash = Paint()
      ..color = EraInk.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), dash);
      }
      canvas.drawCircle(metric.getTangentForOffset(0)!.position, 4, Paint()..color = EraInk.red);
      canvas.drawCircle(metric.getTangentForOffset(metric.length)!.position, 4, Paint()..color = EraInk.red);
      final at = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0))!.position;
      paintGlyph(canvas, Rect.fromCenter(center: at - const Offset(0, 8), width: 30, height: 30), mode, EraInk.ink, EraInk.red);
    }
    final tp = TextPainter(
      text: TextSpan(text: from, style: fell(10.5, color: EraInk.ink2)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w / 2);
    tp.paint(canvas, Offset(2, h - tp.height));
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress || old.mode != mode;
}

/// One line with an ink glyph, a title, a line under it and a button.
class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.glyph,
    required this.title,
    required this.sub,
    required this.action,
    this.onTap,
    this.dim = false,
  });
  final String glyph;
  final String title;
  final String sub;
  final String action;
  final VoidCallback? onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dim ? 0.6 : 1,
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(color: EraInk.card, border: Border.all(color: EraInk.ink, width: 2)),
      child: Row(
        children: [
          InkGlyph(glyph, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: fell(15)),
                Text(sub, style: fell(12.5, color: EraInk.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkButton(action, onTap: onTap),
        ],
      ),
    ),
  );
}
