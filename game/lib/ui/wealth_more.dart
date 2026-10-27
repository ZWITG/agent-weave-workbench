import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/finance.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'result_popup.dart';
import 'wealth_tab.dart' show showAmountSheet;
import 'widgets.dart';

/// Wealth tab additions (plan Module 6): credit score, loan types, the
/// market and your business.

Color _bandColor(int? score) => switch (creditBand(score)) {
  'Unrated' => NF.muted,
  'Poor' => NF.danger,
  'Fair' => NF.orange,
  _ => const Color(0xFF5EE6A8),
};

/// Credit score row: tap for what moves it.
class CreditRow extends StatelessWidget {
  const CreditRow({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final score = life.credit;
    return OptionRow(
      icon: Icons.speed_rounded,
      title: score == null
          ? 'Credit score: not rated yet'
          : 'Credit score $score',
      detail: score == null
          ? 'Starts when you first borrow'
          : '${creditBand(score)} · card limit ${money(cardLimit(life))}${loansBlocked(life) ? ' · loans blocked after bankruptcy' : ''}',
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: NF.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score == null ? 'Credit score' : 'Credit score $score',
                  style: NF.sora(20, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  creditBand(score),
                  style: NF.sora(
                    14,
                    weight: FontWeight.w600,
                    color: _bandColor(score),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'From 300 to 850. Better scores get cheaper loans, bigger card limits and mortgages.',
                  style: NF.sora(13, color: NF.soft),
                ),
                const SizedBox(height: 12),
                for (final t in creditTips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $t', style: NF.sora(13, color: NF.soft)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// All loan types with their rate, limit and why one is locked.
void showLoansSheet(BuildContext context, GameController c) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NF.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final life = c.life!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Borrow money', style: NF.sora(20, weight: FontWeight.w700)),
              Text(
                'Rates follow your credit score (${life.credit ?? 'unrated'}). Mortgages and auto loans come with a home or a car.',
                style: NF.sora(13, color: NF.muted),
              ),
              const SizedBox(height: 12),
              for (final t in loanTypes) ...[
                Builder(
                  builder: (_) {
                    final lock = loanLock(life, t);
                    final rate = (t.rate(life) * 100).toStringAsFixed(1);
                    return OptionRow(
                      icon: t.name == 'Family loan'
                          ? Icons.family_restroom_rounded
                          : t.name == 'Payday loan'
                          ? Icons.warning_amber_rounded
                          : Icons.account_balance_rounded,
                      title: t.name,
                      detail:
                          lock ??
                          'Up to ${money(t.limit(life))} at $rate% · ${t.blurb}',
                      locked: lock != null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final a = await showAmountSheet(
                          context,
                          title: 'Borrow: ${t.name.toLowerCase()}',
                          max: t.limit(life),
                          verb: 'Borrow',
                        );
                        if (a == null || !context.mounted) return;
                        final r = c.wealth((l) => takeLoan(l, t, a));
                        showResultPopup(
                          context,
                          r,
                          title: t.name,
                          icon: Icons.account_balance_rounded,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );
}

// ---------------- Investments ----------------

class MarketList extends StatelessWidget {
  const MarketList({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final world = controller.engine!.world;
    final last = world.prices[life.year - 1] ?? const <String, double>{};
    final listed = tickers.where((t) => (life.quotes[t.id] ?? 0) > 0);
    final owned = listed.where((t) => (life.shares[t.id] ?? 0) > 0).toList();
    final value = life.portfolioValue;
    return NFCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.candlestick_chart_rounded, color: NF.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Market',
                  style: NF.sora(16, weight: FontWeight.w700),
                ),
              ),
              if (value > 0)
                Text(money(value), style: NF.sora(16, weight: FontWeight.w700)),
            ],
          ),
          Text(
            life.age < 18 ? 'Unlocks at 18.' : 'Fictional companies, bonds, gold and a coin. Prices move with the economy and the news; dividends are paid each birthday.',
            style: NF.sora(12, color: NF.muted),
          ),
          const SizedBox(height: 6),
          for (final t in [
            ...owned,
            ...listed.where((t) => !owned.contains(t)),
          ])
            _TickerRow(
              controller: controller,
              id: t.id,
              before: last[t.id],
              locked: life.age < 18,
            ),
        ],
      ),
    );
  }
}

class _TickerRow extends StatelessWidget {
  const _TickerRow({
    required this.controller,
    required this.id,
    required this.before,
    required this.locked,
  });
  final GameController controller;
  final String id;
  final double? before;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final t = tickerById(id)!;
    final price = life.quotes[id] ?? 0;
    final pct = before == null || before! <= 0
        ? null
        : ((price - before!) / before! * 100).round();
    final held = holdingValue(life, id);
    final paid = life.paid[id] ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: locked ? null : () => _trade(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                t.id,
                style: NF.sora(12, weight: FontWeight.w700, color: NF.blue),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: NF.sora(14, weight: FontWeight.w600)),
                  Text(
                    held > 0
                        ? 'You own ${money(held)} · ${held >= paid ? 'up' : 'down'} ${money((held - paid).abs())}'
                        : '${t.sector} · ${t.yield > 0 ? '${(t.yield * 100).toStringAsFixed(1)}% yield' : 'no dividend'}',
                    style: NF.sora(
                      11,
                      color: held > 0
                          ? (held >= paid ? const Color(0xFF5EE6A8) : NF.danger)
                          : NF.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceLabel(price),
                  style: NF.sora(13, weight: FontWeight.w600),
                ),
                if (pct != null)
                  Text(
                    '${pct >= 0 ? '▲' : '▼'} ${pct.abs()}%',
                    style: NF.sora(
                      11,
                      color: pct >= 0 ? const Color(0xFF5EE6A8) : NF.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _trade(BuildContext context) {
    final c = controller;
    final t = tickerById(id)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NF.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final life = c.life!;
        final held = holdingValue(life, id);
        final news = (c.engine!.world.market[life.year] ?? const [])
            .where((n) => n.startsWith(t.name))
            .firstOrNull;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: NF.sora(20, weight: FontWeight.w700)),
                Text(
                  '${t.sector} · ${priceLabel(life.quotes[id] ?? 0)}',
                  style: NF.sora(13, color: NF.muted),
                ),
                const SizedBox(height: 10),
                Text(t.blurb, style: NF.sora(14, color: NF.soft)),
                if (news != null) ...[
                  const SizedBox(height: 6),
                  Text('This year: $news', style: NF.sora(13, color: NF.soft)),
                ],
                if (held > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'You own ${money(held)} (paid ${money(life.paid[id] ?? 0)}).',
                    style: NF.sora(13, weight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: primaryButton(),
                        onPressed: life.money <= 0
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final a = await showAmountSheet(
                                  context,
                                  title: 'Buy ${t.name}',
                                  max: life.money,
                                  verb: 'Buy',
                                );
                                if (a == null || !context.mounted) return;
                                final r = c.wealth((l) => buyShares(l, id, a));
                                showResultPopup(
                                  context,
                                  r,
                                  title: t.name,
                                  icon: Icons.candlestick_chart_rounded,
                                );
                              },
                        child: const Text('Buy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: secondaryButton(),
                        onPressed: held <= 0
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final a = await showAmountSheet(
                                  context,
                                  title: 'Sell ${t.name}',
                                  max: held,
                                  verb: 'Sell',
                                );
                                if (a == null || !context.mounted) return;
                                final r = c.wealth((l) => sellShares(l, id, a));
                                showResultPopup(
                                  context,
                                  r,
                                  title: t.name,
                                  icon: Icons.candlestick_chart_rounded,
                                );
                              },
                        child: const Text('Sell'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- Business ----------------

class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final life = c.life!;
    final b = life.business;
    if (b == null) {
      final start = c.engine!.actions.firstWhere(
        (a) => a.id == 'start_business',
      );
      return actionRow(context, c, start, closeSheet: false);
    }
    final ind = industryById(b.industry);
    Widget meter(String label, int v) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: NF.sora(11, color: NF.muted)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 6,
              backgroundColor: NF.surface2,
              color: v >= 60
                  ? const Color(0xFF5EE6A8)
                  : v >= 35
                  ? NF.orange
                  : NF.danger,
            ),
          ),
          const SizedBox(height: 2),
          Text('$v%', style: NF.sora(11, weight: FontWeight.w600)),
        ],
      ),
    );
    return NFCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: NF.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.name, style: NF.sora(16, weight: FontWeight.w700)),
                    Text(
                      '${ind.name} · ${bizTiers[b.tier]!.label} · ${b.staff} staff · since age ${b.since}',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(life.businessValue),
                    style: NF.sora(15, weight: FontWeight.w700),
                  ),
                  Text('value', style: NF.sora(11, color: NF.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              meter('Quality', b.quality),
              const SizedBox(width: 10),
              meter('Brand', b.brand),
              const SizedBox(width: 10),
              meter('Customers', b.satisfaction),
              const SizedBox(width: 10),
              meter('Morale', b.morale),
            ],
          ),
          if (b.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Last year', style: NF.sora(12, color: NF.muted)),
            for (final (label, v) in b.lines)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: NF.sora(13, color: NF.soft)),
                    ),
                    Text(
                      '${v >= 0 ? '+' : ''}${money(v)}',
                      style: NF.sora(13, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      b.profit >= 0 ? 'Profit' : 'Loss',
                      style: NF.sora(14, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    money(b.profit),
                    style: NF.sora(
                      14,
                      weight: FontWeight.w700,
                      color: b.profit >= 0
                          ? const Color(0xFF5EE6A8)
                          : NF.danger,
                    ),
                  ),
                ],
              ),
            ),
            if (b.reasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Why: ${b.reasons.join(' · ')}',
                  style: NF.sora(12, color: NF.muted),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Your first results arrive at your next birthday.',
                style: NF.sora(12, color: NF.muted),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in bizMoves)
                Builder(
                  builder: (_) {
                    final lock = bizMoveLock(life, m);
                    return Tooltip(
                      message: lock ?? m.detail(life),
                      child: OutlinedButton(
                        style: secondaryButton(),
                        onPressed: lock != null
                            ? null
                            : () {
                                final r = c.wealth(
                                  (l) => runBizMove(l, m, c.engine!.rngFor(l)),
                                );
                                showResultPopup(
                                  context,
                                  r,
                                  title: m.label,
                                  icon: Icons.storefront_rounded,
                                );
                              },
                        child: Text(m.label),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Business model', style: NF.sora(12, color: NF.muted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final e in bizTiers.entries)
                ChoiceChip(
                  label: Text(e.value.label),
                  selected: b.tier == e.key,
                  onSelected: (_) => c.wealth((l) => setTier(l, e.key)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: secondaryButton(),
                  onPressed: () => _confirm(
                    context,
                    'Sell ${b.name}?',
                    'A buyer will pay about ${money(life.businessValue)} (three years of profit plus staff and brand).',
                    'Sell',
                    () => c.wealth(sellBusiness),
                  ),
                  child: const Text('Sell'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: secondaryButton(),
                  onPressed: () => _confirm(
                    context,
                    'Close ${b.name}?',
                    'You will get nothing for it, and any business loan still has to be repaid.',
                    'Close',
                    () => c.wealth(closeBusiness),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    String body,
    String verb,
    ActionResult Function() run,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NF.surface,
        title: Text(title, style: NF.sora(18, weight: FontWeight.w700)),
        content: Text(body, style: NF.sora(14, color: NF.soft)),
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
    final r = run();
    showResultPopup(context, r, title: verb, icon: Icons.storefront_rounded);
  }
}
