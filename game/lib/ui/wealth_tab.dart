import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/economy.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'result_popup.dart';
import 'widgets.dart';

const _good = Color(0xFF5EE6A8);

/// The Wealth tab (plan S40–S44): net worth and its trend, last birthday's
/// cash flow, lifestyle budget, bank and loans, and home and vehicles.
class WealthTab extends StatelessWidget {
  const WealthTab({super.key, required this.controller});
  final GameController controller;

  GameController get c => controller;

  @override
  Widget build(BuildContext context) {
    final life = c.life!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SectionLabel('Wealth'),
        const SizedBox(height: 10),
        _Overview(life: life),
        const SizedBox(height: 12),
        _CashFlow(life: life),
        if (life.age >= 18) ...[
          _title(
            'Lifestyle',
            livesWithFamily(life)
                ? 'Living with family · paid each birthday'
                : 'Living on your own · paid each birthday',
          ),
          _lifestyle(life),
        ],
        _title('Bank and loans', 'Move money, borrow and repay'),
        ..._bank(context, life),
        _title('Home and vehicles', 'What you own and what it costs'),
        ..._assets(context, life),
      ],
    );
  }

  Widget _title(String t, String sub) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: NF.sora(17, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: NF.sora(12, color: NF.muted)),
      ],
    ),
  );

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
          subtitle: '${((debtRates[d.key] ?? 0.1) * 100).round()}% a year',
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
        title: 'Take a personal loan',
        detail: limit > 0
            ? 'Up to ${money(limit)} at 12% a year'
            : !adult
            ? 'Unlocks at 18'
            : life.job == null
            ? 'Needs a job'
            : 'You have borrowed the most you can',
        locked: limit <= 0,
        onTap: () async {
          final a = await showAmountSheet(
            context,
            title: 'Borrow from the bank',
            max: limit,
            verb: 'Borrow',
          );
          if (a == null || !context.mounted) return;
          final r = c.wealth((l) => borrow(l, a));
          showResultPopup(
            context,
            r,
            title: 'Personal loan',
            icon: Icons.account_balance_rounded,
          );
        },
      ),
    ];
  }

  (String, bool, VoidCallback) _act(String l, bool on, VoidCallback f) =>
      (l, on, f);

  // ---------------- Home and vehicles ----------------

  List<Widget> _assets(BuildContext context, Life life) {
    final shop = allActions
        .where(
          (a) => const {'rent_flat', 'buy_house', 'buy_car'}.contains(a.id),
        )
        .toList();
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
        _AssetCard(asset: a, onSell: () => _sell(context, a)),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      for (final a in shop) ...[
        actionRow(context, c, a, closeSheet: false),
        const SizedBox(height: 8),
      ],
    ];
  }

  Future<void> _sell(BuildContext context, Asset a) async {
    final life = c.life!;
    final verb = a.kind == 'rental' ? 'Move out' : 'Sell';
    final detail = switch (a.kind) {
      'rental' => 'You will move back in with family and stop paying rent.',
      'house' =>
        'It is worth about ${money(a.value)}. A 3% agent fee and any mortgage '
            '(${money(life.debts['Mortgage'] ?? 0)}) come out of the sale.',
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
  const _AssetCard({required this.asset, required this.onSell});
  final Asset asset;
  final VoidCallback onSell;

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
          if (!rental) ...[
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: NF.text,
                side: const BorderSide(color: NF.borderStrong),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onSell,
              child: Text(rental ? 'Move out' : 'Sell'),
            ),
          ),
        ],
      ),
    );
  }
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
