import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/economy.dart';
import '../engine/finance.dart' show rateOf;
import '../engine/homes.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'hub_kit.dart';
import 'shop_screen.dart';
import '../engine/shopping.dart' show saleOn;
import 'result_popup.dart';
import 'wealth_more.dart';
import '../engine/possessions.dart';
import 'widgets.dart';

const _good = Color(0xFF5EE6A8);

/// The Wealth tab (plan S40–S44), shaped like the Activities panel: net
/// worth on top, a search box, "Suggested for you", then Browse tiles that
/// each open one section (cash flow, lifestyle, bank and loans, investing,
/// business, home and vehicles, money activities).
class WealthTab extends StatefulWidget {
  const WealthTab({super.key, required this.controller});
  final GameController controller;

  @override
  State<WealthTab> createState() => _WealthTabState();
}

class _WealthTabState extends State<WealthTab> {
  String? _section;
  String _q = '';
  final _search = TextEditingController();

  GameController get c => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _sections = <String, (String, IconData, String)>{
    'flow': (
      'Cash flow',
      Icons.swap_vert_rounded,
      'Last birthday and the next one',
    ),
    'lifestyle': (
      'Lifestyle',
      Icons.weekend_rounded,
      'Your budget, paid each birthday',
    ),
    'bank': (
      'Bank and loans',
      Icons.account_balance_rounded,
      'Move money, borrow and repay',
    ),
    'invest': (
      'Investing',
      Icons.candlestick_chart_rounded,
      'Stocks, bonds, gold and coins',
    ),
    'business': (
      'Business',
      Icons.storefront_rounded,
      'Start one, run it, sell it',
    ),
    'assets': (
      'Home and vehicles',
      Icons.home_work_rounded,
      'What you own and what it costs',
    ),
    'more': (
      'Money activities',
      Icons.savings_rounded,
      'Shopping, lottery, wills and more',
    ),
  };

  void _open(String? s) => setState(() {
    _section = s;
    _search.clear();
    _q = '';
  });

  List<GameAction> get _moneyActions => c.engine!.actions
      .where((a) => a.category == 'Money' || a.category == 'Assets')
      .toList();

  @override
  Widget build(BuildContext context) {
    final life = c.life!;
    final s = _section;
    if (s != null) {
      final (title, _, sub) = _sections[s]!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SectionBar(
            back: 'Wealth',
            title: title,
            sub: s == 'lifestyle'
                ? (livesWithFamily(life)
                      ? 'Living with family · paid each birthday'
                      : 'Living on your own · paid each birthday')
                : sub,
            onBack: () => _open(null),
          ),
          ..._sectionBody(context, life, s),
        ],
      );
    }
    final searching = _q.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _Overview(life: life),
        const SizedBox(height: 12),
        HubSearch(
          controller: _search,
          hint: 'Search money: savings, loan, house…',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching)
          ..._results(context, life)
        else ...[
          if (_suggested(context, life) case final rows
              when rows.isNotEmpty) ...[
            const HubHeading('Suggested for you'),
            for (final r in rows) ...[r, const SizedBox(height: 8)],
          ],
          const HubHeading('Browse'),
          BrowseGrid(items: _browse(life)),
        ],
      ],
    );
  }

  List<Widget> _sectionBody(BuildContext context, Life life, String s) =>
      switch (s) {
        'flow' => [_CashFlow(life: life)],
        'lifestyle' => [
          if (life.age < 18)
            Text(
              'Your family covers your living costs until you are 18.',
              style: NF.sora(14, color: NF.muted),
            )
          else
            _lifestyle(life),
        ],
        'bank' => _bank(context, life),
        'invest' => [MarketList(controller: c)],
        'business' => [BusinessCard(controller: c)],
        'assets' => _assets(context, life),
        _ => [
          for (final a in _moneyActions) ...[
            actionRow(context, c, a, closeSheet: false),
            const SizedBox(height: 8),
          ],
        ],
      };

  List<BrowseItem> _browse(Life life) {
    final f = forecastNextYear(life);
    final short = f < 0 && life.money + f < 0;
    final debt = life.totalDebt;
    final openMoney = _moneyActions.where((a) => a.lockReason(life) == null);
    String status(String k) => switch (k) {
      'flow' =>
        f == 0 ? 'Nothing due' : '${f > 0 ? '+' : ''}${money(f)} next year',
      'lifestyle' =>
        life.age < 18 ? 'Family pays' : lifestyles[life.lifestyle]!.label,
      'bank' =>
        debt > 0
            ? '${money(debt)} owed'
            : life.savings > 0
            ? '${money(life.savings)} saved'
            : 'Save or borrow',
      'invest' =>
        life.portfolioValue + life.invested > 0
            ? money(life.portfolioValue + life.invested)
            : (life.age < 18 ? 'From age 18' : 'Start investing'),
      'business' => life.business?.name ?? 'None yet',
      'assets' =>
        life.assets.isEmpty
            ? (life.age < 18 ? 'From age 18' : 'Nothing owned')
            : '${life.assets.length} owned',
      _ => '${openMoney.length} open',
    };
    final sale = saleOn(DateTime.now());
    return [
      BrowseItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Shop',
        status: sale != null ? '${sale.$2}% off' : 'Daily deals',
        alert: sale != null,
        onTap: () => openShop(context, c),
      ),
      for (final e in _sections.entries)
        BrowseItem(
          icon: e.value.$2,
          label: e.value.$1,
          status: status(e.key),
          alert: (e.key == 'flow' && short) || (e.key == 'bank' && debt > 0),
          dim: switch (e.key) {
            'invest' || 'assets' || 'business' => life.age < 18,
            'more' => openMoney.isEmpty,
            _ => false,
          },
          onTap: () => _open(e.key),
        ),
    ];
  }

  /// Up to three things worth doing with money right now.
  List<Widget> _suggested(BuildContext context, Life life) {
    final f = forecastNextYear(life);
    final rows = <Widget>[];
    if (f < 0 && life.money + f < 0) {
      rows.add(
        OptionRow(
          icon: Icons.warning_amber_rounded,
          title: 'You will run short next birthday',
          detail:
              'About ${money(-(life.money + f))} goes on a credit card. See why',
          onTap: () => _open('flow'),
        ),
      );
    }
    final debt = life.debts.entries.where((d) => d.value > 0).toList()
      ..sort((a, b) => rateOf(life, b.key).compareTo(rateOf(life, a.key)));
    if (debt.isNotEmpty && life.money > 0) {
      final d = debt.first;
      rows.add(
        OptionRow(
          icon: Icons.credit_card_rounded,
          title: 'Pay off your ${d.key.toLowerCase()}',
          detail:
              '${money(d.value)} at ${(rateOf(life, d.key) * 100).toStringAsFixed(1)}% a year',
          onTap: () => _open('bank'),
        ),
      );
    }
    if (life.age >= 18 && life.money >= 2000 && debt.isEmpty) {
      rows.add(
        OptionRow(
          icon: Icons.savings_rounded,
          title: life.portfolioValue + life.invested == 0
              ? 'Put your cash to work'
              : 'Grow your savings',
          detail: '${money(life.money)} in cash earns nothing',
          onTap: () => _open(life.money >= 5000 ? 'invest' : 'bank'),
        ),
      );
    }
    if (life.age >= 18 &&
        life.assets.every((a) => a.kind != 'house' && a.kind != 'rental')) {
      final home = allActions.where((a) => a.id == 'rent_flat').firstOrNull;
      if (home != null && home.lockReason(life) == null) {
        rows.add(actionRow(context, c, home, closeSheet: false));
      }
    }
    return rows.take(3).toList();
  }

  List<Widget> _results(BuildContext context, Life life) {
    final sections = _sections.entries
        .where((e) => matchesQuery(_q, [e.value.$1, e.value.$3]))
        .toList();
    final actions = _moneyActions.where((a) => a.matches(_q)).toList();
    if (sections.isEmpty && actions.isEmpty) {
      return [
        const SizedBox(height: 14),
        Text(
          'Nothing matches "$_q". Try "loan", "stocks" or "car".',
          style: NF.sora(14, color: NF.muted),
        ),
      ];
    }
    return [
      const SizedBox(height: 14),
      for (final e in sections) ...[
        OptionRow(
          icon: e.value.$2,
          title: e.value.$1,
          detail: e.value.$3,
          onTap: () => _open(e.key),
        ),
        const SizedBox(height: 8),
      ],
      for (final a in actions) ...[
        actionRow(context, c, a, closeSheet: false),
        const SizedBox(height: 8),
      ],
    ];
  }

  // ---------------- Lifestyle ----------------

  Widget _lifestyle(Life life) {
    return Row(
      children: [
        for (final e in lifestyles.entries) ...[
          if (e.key != lifestyles.keys.first) const SizedBox(width: 8),
          Expanded(
            child: _LifestyleTile(
              tier: e.value,
              cost: livingCost(life, e.key),
              selected: life.lifestyle == e.key,
              onTap: () => c.wealth((l) => l.lifestyle = e.key),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- Bank and loans ----------------

  List<Widget> _bank(BuildContext context, Life life) {
    final adult = life.age >= 18;
    final limit = borrowLimit(life);
    return [
      if (adult) ...[CreditRow(life: life), const SizedBox(height: 8)],
      _MoneyRow(
        icon: Icons.savings_rounded,
        title: 'Savings account',
        subtitle: 'Earns 2% a year · safe',
        amount: money(life.savings),
        actions: [
          _act('Deposit', life.money > 0, () async {
            final a = await showAmountSheet(
              context,
              title: 'Move money into savings',
              max: life.money,
              verb: 'Deposit',
            );
            if (a != null) c.wealth((l) => deposit(l, a));
          }),
          _act('Withdraw', life.savings > 0, () async {
            final a = await showAmountSheet(
              context,
              title: 'Take money out of savings',
              max: life.savings,
              verb: 'Withdraw',
            );
            if (a != null) c.wealth((l) => withdraw(l, a));
          }),
        ],
      ),
      const SizedBox(height: 8),
      _MoneyRow(
        icon: Icons.show_chart_rounded,
        title: 'Index fund',
        subtitle: adult
            ? 'Follows the economy · now ${life.economy.toLowerCase()}'
            : 'Unlocks at 18',
        locked: !adult,
        amount: money(life.invested),
        actions: [
          _act('Invest', adult && life.money > 0, () async {
            final a = await showAmountSheet(
              context,
              title: 'Invest in the index fund',
              max: life.money,
              verb: 'Invest',
            );
            if (a != null) c.wealth((l) => invest(l, a));
          }),
          _act('Sell', life.invested > 0, () async {
            final a = await showAmountSheet(
              context,
              title: 'Sell fund shares for cash',
              max: life.invested,
              verb: 'Sell',
            );
            if (a != null) c.wealth((l) => sellFund(l, a));
          }),
        ],
      ),
      for (final d in life.debts.entries) ...[
        const SizedBox(height: 8),
        _MoneyRow(
          icon: Icons.credit_card_rounded,
          title: d.key,
          subtitle:
              '${(rateOf(life, d.key) * 100).toStringAsFixed(1)}% a year${d.key == 'Payday loan' || d.key == 'Pay later' ? ' · due in full next birthday' : ''}',
          amount: money(-d.value),
          negative: true,
          actions: [
            _act('Pay off', life.money > 0, () async {
              final a = await showAmountSheet(
                context,
                title: 'Pay off your ${d.key.toLowerCase()}',
                max: min(life.money, d.value),
                verb: 'Pay',
              );
              if (a == null || !context.mounted) return;
              final r = c.wealth((l) => repay(l, d.key, a));
              showResultPopup(
                context,
                r,
                title: d.key,
                icon: Icons.credit_card_rounded,
              );
            }),
          ],
        ),
      ],
      const SizedBox(height: 8),
      OptionRow(
        icon: Icons.account_balance_rounded,
        title: 'Borrow money',
        detail: !adult
            ? 'Unlocks at 18'
            : limit > 0
            ? 'Personal loan up to ${money(limit)}, and other loan types'
            : 'Personal, business, payday and family loans',
        locked: !adult,
        onTap: () => showLoansSheet(context, c),
      ),
    ];
  }

  (String, bool, VoidCallback) _act(String l, bool on, VoidCallback f) =>
      (l, on, f);

  // ---------------- Home and vehicles ----------------

  List<Widget> _assets(BuildContext context, Life life) {
    final shop = allActions.where((a) => a.category == 'Assets').toList();
    return [
      if (life.assets.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            life.age < 18
                ? 'You live with your family. Homes and cars open at 18.'
                : 'You don\'t own anything yet.',
            style: NF.sora(14, color: NF.muted),
          ),
        ),
      for (final a in life.assets) ...[
        _AssetCard(
          asset: a,
          onSell: () => _sell(context, a),
          onRepair: a.kind == 'house' && a.condition < 80
              ? (life.money >= repairCost(a)
                    ? () => _homeWork(context, 'Repairs', repairHome, a)
                    : null)
              : null,
          repairLabel: 'Repair (${money(repairCost(a))})',
          onRenovate: a.kind == 'house' && renovateLock(life, a) == null
              ? () => _homeWork(context, 'Renovation', renovateHome, a)
              : null,
          renovateLabel: 'Renovate (${money(renovationCost(a))})',
          rent: a.info['let'] == true ? rentFor(a) : null,
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      for (final a in shop) ...[
        actionRow(context, c, a, closeSheet: false),
        const SizedBox(height: 8),
      ],
    ];
  }

  void _homeWork(
    BuildContext context,
    String title,
    ActionResult Function(Life, Asset) work,
    Asset a,
  ) {
    final r = c.wealth((l) => work(l, a));
    showResultPopup(context, r, title: title, icon: Icons.handyman_rounded);
  }

  Future<void> _sell(BuildContext context, Asset a) async {
    final life = c.life!;
    final verb = a.kind == 'rental' ? 'Move out' : 'Sell';
    final detail = switch (a.kind) {
      'rental' => 'You will move back in with family and stop paying rent.',
      'house' =>
        'It is worth about ${money(a.value)}. A 3% agent fee and any mortgage '
            '(${money(life.debts[a.info['let'] == true ? 'Buy-to-let mortgage' : 'Mortgage'] ?? 0)}) come out of the sale.',
      _ => 'A buyer will pay ${money(a.value)}.',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NF.surface,
        title: Text(
          '$verb: ${a.name}?',
          style: NF.sora(18, weight: FontWeight.w700),
        ),
        content: Text(detail, style: NF.sora(14, color: NF.soft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: primaryButton(),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final r = c.wealth((l) => sellAsset(l, a));
    showResultPopup(context, r, title: '$verb: ${a.name}', icon: _assetIcon(a));
  }
}

IconData _assetIcon(Asset a) => switch (a.kind) {
  'house' => Icons.home_rounded,
  'rental' => Icons.key_rounded,
  'valuable' => Icons.diamond_rounded,
  'boat' => Icons.sailing_rounded,
  'plane' => Icons.flight_rounded,
  'collectible' => Icons.style_rounded,
  'heirloom' => Icons.auto_awesome_rounded,
  _ => Icons.directions_car_rounded,
};

// ---------------- Overview: net worth, trend and the four totals ----------------

class _Overview extends StatelessWidget {
  const _Overview({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final points = life.netWorthByAge.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final prev = life.netWorthByAge[life.age - 1];
    final change = prev == null ? null : life.netWorth - prev;
    final eco = life.economy;
    final ecoIcon = switch (eco) {
      'Boom' => Icons.trending_up_rounded,
      'Normal' => Icons.trending_flat_rounded,
      _ => Icons.trending_down_rounded,
    };
    final ecoColor = switch (eco) {
      'Boom' || 'Normal' => _good,
      'Slowdown' => NF.orange,
      _ => NF.danger,
    };
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Net worth', style: NF.sora(13, color: NF.muted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NF.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ecoIcon, size: 16, color: ecoColor),
                    const SizedBox(width: 6),
                    Text(
                      'Economy: $eco',
                      style: NF.sora(
                        12,
                        weight: FontWeight.w600,
                        color: NF.soft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            money(life.netWorth),
            style: NF.sora(
              34,
              weight: FontWeight.w700,
              color: life.netWorth < 0 ? NF.danger : NF.text,
            ),
          ),
          if (change != null)
            Row(
              children: [
                Icon(
                  change >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 15,
                  color: change >= 0 ? _good : NF.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${money(change)} since last birthday',
                  style: NF.sora(13, color: NF.soft),
                ),
              ],
            ),
          if (points.length >= 2) ...[
            const SizedBox(height: 12),
            _Sparkline(points: [for (final p in points) (p.key, p.value)]),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Total(
                  'Cash',
                  money(life.money),
                  Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Total(
                  'Savings',
                  money(life.savings),
                  Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Total(
                  'Investments',
                  money(life.invested),
                  Icons.show_chart_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Total(
                  'Debts',
                  life.totalDebt == 0 ? '\$0' : money(-life.totalDebt),
                  Icons.credit_card_rounded,
                  warn: life.totalDebt > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value, this.icon, {this.warn = false});
  final String label;
  final String value;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: warn ? NF.danger : NF.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NF.sora(11, color: NF.muted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NF.sora(15, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Net worth by age: one 2px line with a soft fill. Touch or drag to read
/// any year.
class _Sparkline extends StatefulWidget {
  const _Sparkline({required this.points});
  final List<(int, int)> points;

  @override
  State<_Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<_Sparkline> {
  int? _sel;

  void _pick(double dx, double width) {
    final n = widget.points.length;
    setState(() => _sel = (dx / width * (n - 1)).round().clamp(0, n - 1));
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    final shown = pts[_sel ?? pts.length - 1];
    return Semantics(
      label:
          'Net worth trend from age ${pts.first.$1} to ${pts.last.$1}: '
          '${money(pts.first.$2)} to ${money(pts.last.$2)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age ${shown.$1} · ${money(shown.$2)}',
            style: NF.sora(12, color: NF.muted),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, box) => GestureDetector(
              onTapDown: (d) => _pick(d.localPosition.dx, box.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _pick(d.localPosition.dx, box.maxWidth),
              onTapUp: (_) => setState(() => _sel = null),
              onHorizontalDragEnd: (_) => setState(() => _sel = null),
              child: SizedBox(
                height: 64,
                width: box.maxWidth,
                child: CustomPaint(
                  painter: _SparkPainter(pts, _sel ?? pts.length - 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.selected);
  final List<(int, int)> points;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [for (final p in points) p.$2];
    var lo = values.reduce(min).toDouble();
    var hi = values.reduce(max).toDouble();
    if (hi - lo < 1) {
      hi += 1;
      lo -= 1;
    }
    Offset at(int i) => Offset(
      i / (points.length - 1) * (size.width - 8) + 4,
      4 + (1 - (values[i] - lo) / (hi - lo)) * (size.height - 8),
    );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(at(points.length - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NF.blue.withValues(alpha: 0.28),
            NF.blue.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    // Zero line when the trend crosses into debt.
    if (lo < 0 && hi > 0) {
      final y = 4 + (1 - (0 - lo) / (hi - lo)) * (size.height - 8);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = NF.border
          ..strokeWidth = 1,
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = NF.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final p = at(selected);
    canvas.drawCircle(p, 6, Paint()..color = NF.surface);
    canvas.drawCircle(p, 4, Paint()..color = NF.blue);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.selected != selected;
}

// ---------------- Last birthday's cash flow ----------------

class _CashFlow extends StatelessWidget {
  const _CashFlow({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final total = life.lastYear.fold(0, (a, l) => a + l.$2);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last birthday', style: NF.sora(15, weight: FontWeight.w700)),
          Text(
            'Where your cash went when you turned ${life.age}',
            style: NF.sora(12, color: NF.muted),
          ),
          const SizedBox(height: 10),
          if (life.lastYear.isEmpty)
            Text(
              life.age < 18
                  ? 'Your family covers your living costs until you are 18.'
                  : 'Age up to see your first year of money.',
              style: NF.sora(14, color: NF.soft),
            ),
          for (final l in life.lastYear) _line(l.$1, l.$2),
          if (life.lastYear.isNotEmpty) ...[
            const Divider(color: NF.border, height: 18),
            _line('Change in cash', total, bold: true),
          ],
          _forecast(),
          if (life.lastGrowth.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Grew outside your cash', style: NF.sora(12, color: NF.muted)),
            const SizedBox(height: 4),
            for (final l in life.lastGrowth) _line(l.$1, l.$2),
          ],
        ],
      ),
    );
  }

  /// Next birthday estimate, with a warning before cash runs out.
  Widget _forecast() {
    final f = forecastNextYear(life);
    if (f == 0) return const SizedBox.shrink();
    final short = f < 0 && life.money + f < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Next birthday (estimate)', style: NF.sora(12, color: NF.muted)),
        const SizedBox(height: 4),
        _line('Expected change in cash', f),
        if (short)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NF.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NF.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: NF.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have ${money(life.money)} but will need about '
                    '${money(-f)}. The rest (${money(-(life.money + f))}) '
                    'goes on a credit card at 20%. Spend less, move home or '
                    'find work.',
                    style: NF.sora(13, color: NF.soft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _line(String label, int v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          v >= 0
              ? Icons.add_circle_outline_rounded
              : Icons.remove_circle_outline_rounded,
          size: 16,
          color: v >= 0 ? _good : NF.danger,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: NF.sora(
              14,
              color: bold ? NF.text : NF.soft,
              weight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          '${v >= 0 ? '+' : ''}${money(v)}',
          style: NF.sora(14, weight: bold ? FontWeight.w700 : FontWeight.w600),
        ),
      ],
    ),
  );
}

// ---------------- Pieces ----------------

class _LifestyleTile extends StatelessWidget {
  const _LifestyleTile({
    required this.tier,
    required this.cost,
    required this.selected,
    required this.onTap,
  });
  final Lifestyle tier;
  final int cost;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = tier.happiness;
    return Semantics(
      button: true,
      selected: selected,
      label: '${tier.label}, ${money(cost)} a year, ${tier.blurb}',
      excludeSemantics: true,
      child: Material(
        color: selected ? NF.blue.withValues(alpha: 0.16) : NF.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? NF.blue : NF.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tier.label,
                    maxLines: 1,
                    style: NF.sora(14, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                Text('${money(cost)}/yr', style: NF.sora(12, color: NF.soft)),
                const SizedBox(height: 6),
                Text(
                  h == 0
                      ? 'Happiness ±0'
                      : 'Happiness ${h > 0 ? '+' : '−'}${h.abs()}',
                  style: NF.sora(
                    11,
                    weight: FontWeight.w600,
                    color: h > 0
                        ? _good
                        : h < 0
                        ? NF.danger
                        : NF.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.actions,
    this.negative = false,
    this.locked = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final List<(String, bool, VoidCallback)> actions;
  final bool negative;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final accent = negative ? NF.danger : (locked ? NF.muted : NF.orange);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: locked ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: NF.sora(15, weight: FontWeight.w600)),
                    Text(
                      subtitle,
                      style: NF.sora(12, color: locked ? NF.orange : NF.muted),
                    ),
                  ],
                ),
              ),
              Text(amount, style: NF.sora(16, weight: FontWeight.w700)),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final (label, on, f) in actions) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NF.text,
                      side: BorderSide(color: on ? NF.borderStrong : NF.border),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: on ? f : null,
                    child: Text(label),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.asset,
    required this.onSell,
    this.onRepair,
    this.onRenovate,
    this.repairLabel = 'Repair',
    this.renovateLabel = 'Renovate',
    this.rent,
  });
  final Asset asset;
  final VoidCallback onSell;
  final VoidCallback? onRepair;
  final VoidCallback? onRenovate;
  final String repairLabel;
  final String renovateLabel;

  /// Yearly rent from tenants for a buy-to-let.
  final int? rent;

  @override
  Widget build(BuildContext context) {
    final a = asset;
    final rental = a.kind == 'rental';
    final condColor = a.condition >= 60
        ? _good
        : a.condition >= 30
        ? NF.orange
        : NF.danger;
    return NFCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NF.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_assetIcon(a), color: NF.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: NF.sora(16, weight: FontWeight.w700)),
                    Text(
                      rental
                          ? 'Renting since age ${a.since}'
                          : rent != null
                          ? 'Let to tenants · ${money(rent!)} a year'
                          : 'Owned since age ${a.since}',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rental ? 'Rent' : money(a.value),
                    style: NF.sora(16, weight: FontWeight.w700),
                  ),
                  Text(
                    '${money(a.yearlyCost)}/yr',
                    style: NF.sora(12, color: NF.muted),
                  ),
                ],
              ),
            ],
          ),
          if (!rental && a.kind != 'collectible' && a.kind != 'heirloom') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Condition', style: NF.sora(12, color: NF.muted)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.condition / 100,
                      minHeight: 6,
                      backgroundColor: NF.surface2,
                      color: condColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${a.condition}%',
                  style: NF.sora(12, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (_details(a).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_details(a), style: NF.sora(12, color: NF.soft)),
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (a.kind == 'house' && a.condition < 80)
                _small(repairLabel, onRepair),
              if (a.kind == 'house') _small(renovateLabel, onRenovate),
              _small(rental ? 'Move out' : 'Sell', onSell),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _small(String label, VoidCallback? onTap) => OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: NF.text,
    side: const BorderSide(color: NF.borderStrong),
    visualDensity: VisualDensity.compact,
  ),
  onPressed: onTap,
  child: Text(label),
);

/// Listing details players asked for: bedrooms, garden, pool, area and
/// what the viewing or survey found.
String _details(Asset a) {
  final i = a.info;
  final traits = List<String>.from(i['traits'] ?? const []);
  return [
    if (i['beds'] != null) '${i['beds']} bed',
    if (i['garden'] == true) 'garden',
    if (i['pool'] == true) 'pool',
    if (i['area'] != null) '${i['area']}',
    for (final t in traits) homeTraits[t]?.$1 ?? t,
    if (i['deposit'] != null) 'deposit ${money(i['deposit'] as int)}',
    if (a.kind == 'car' && (i['dep'] as int? ?? 15) < 0) 'classic: gains value',
    if (a.kind == 'house') ...[
      for (final r in roomsOf(a))
        homeUpgrades.where((u) => u.id == r).firstOrNull?.name.toLowerCase() ??
            r,
      insured(a) ? 'insured' : 'not insured',
    ],
    if (a.kind == 'collectible') ...[
      '${collectibleTypes[i['type']] ?? 'Collectible'}: ${trendLabel(-(i['dep'] as int? ?? 0))} this year',
      i['checked'] == true
          ? (i['fake'] == true ? 'a fake' : 'genuine')
          : 'no papers, not checked',
    ],
    if (a.kind == 'heirloom')
      'Owned before you by ${heirloomHistory(a).join(', ')}',
  ].join(' · ');
}

/// Bottom sheet with a slider and quick picks; returns the chosen amount.
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  required int max,
  required String verb,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: NF.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AmountSheet(title: title, max: max, verb: verb),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.max,
    required this.verb,
  });
  final String title;
  final int max;
  final String verb;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late double _v = (widget.max / 2).roundToDouble();

  int get _amount => _v.round();

  @override
  Widget build(BuildContext context) {
    final m = widget.max <= 0 ? 1 : widget.max;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: NF.sora(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Up to ${money(widget.max)}',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                money(_amount),
                style: NF.sora(32, weight: FontWeight.w700),
              ),
            ),
            Slider(
              value: _v.clamp(0, m.toDouble()),
              max: m.toDouble(),
              divisions: m >= 100 ? 100 : m,
              label: money(_amount),
              onChanged: (v) => setState(() => _v = v),
            ),
            Row(
              children: [
                for (final (label, f) in [
                  ('25%', 0.25),
                  ('50%', 0.5),
                  ('All', 1.0),
                ]) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NF.text,
                        side: const BorderSide(color: NF.borderStrong),
                      ),
                      onPressed: () =>
                          setState(() => _v = (widget.max * f).roundToDouble()),
                      child: Text(label),
                    ),
                  ),
                  if (label != 'All') const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: primaryButton(),
                onPressed: _amount <= 0
                    ? null
                    : () => Navigator.of(context).pop(_amount),
                child: Text('${widget.verb} ${money(_amount)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
