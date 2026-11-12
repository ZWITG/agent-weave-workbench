import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/economy.dart' show sellAsset;
import '../engine/homes.dart';
import '../engine/models.dart';
import '../engine/property.dart';
import '../engine/realty.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'hub_kit.dart';
import 'result_popup.dart';
import 'widgets.dart';

const _good = Color(0xFF5EE6A8);

/// Wealth › Real estate: everything about property on one page. Your
/// portfolio in numbers, the home you live in (with things to do there),
/// each rental with its controls on the card, and the market: this year's
/// homes for sale, the auction and places to rent.
class PropertyHub extends StatefulWidget {
  const PropertyHub({super.key, required this.controller});
  final GameController controller;

  @override
  State<PropertyHub> createState() => _PropertyHubState();
}

class _PropertyHubState extends State<PropertyHub> {
  /// Whether a listing you open is a home to move into or one to let out
  /// (only asked when you already own a home).
  bool _toLet = true;

  GameController get c => widget.controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final life = c.life!;
      final home = homeOf(life);
      final renting = life.assets.where((a) => a.kind == 'rental').firstOrNull;
      final lets = lettingsOf(life);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summary(life),
          HubHeading(
            'Where you live',
            sub: home != null
                ? 'Your own home'
                : renting != null
                ? 'Renting'
                : 'With family',
          ),
          if (home != null)
            _homeCard(context, life, home)
          else
            _notOwning(context, life, renting),
          HubHeading(
            'Your rentals',
            sub: lets.isEmpty
                ? 'Buy a second home or win an auction to become a landlord'
                : '${lets.length} of $maxLets · ${_signed(rentalProfit(life))} a year after costs',
          ),
          if (lets.isEmpty)
            Text(
              home == null
                  ? 'Own a home first. Anything you buy after that can be let out.'
                  : 'No rentals yet. Pick "To let out" below and buy a second home.',
              style: NF.sora(13, color: NF.muted),
            ),
          for (final a in lets) ...[
            _LetCard(
              key: ValueKey(a.id),
              controller: c,
              asset: a,
              onSell: () => _sell(context, a),
            ),
            const SizedBox(height: 10),
          ],
          const HubHeading(
            'Find property',
            sub: 'Same listings all year · prices follow the economy',
          ),
          ..._finders(context, life),
          ..._market(context, life, home != null),
        ],
      );
    },
  );

  // ---------------- Summary ----------------

  Widget _summary(Life life) {
    final p = portfolioOf(life);
    final equity = p.value - p.owed;
    return NFCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Property portfolio'),
          const SizedBox(height: 6),
          Text(
            p.homes == 0 ? 'No property yet' : money(p.value),
            style: NF.sora(26, weight: FontWeight.w800),
          ),
          Text(
            p.homes == 0
                ? 'Buy a home, bid at auction or let out a second one.'
                : '${p.homes} home${p.homes == 1 ? '' : 's'} · ${life.economy} market',
            style: NF.sora(12, color: NF.muted),
          ),
          if (p.homes > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('Equity', money(equity), equity >= 0 ? _good : NF.danger),
                _stat('Mortgages', money(p.owed), NF.text),
                _stat(
                  'Rent a year',
                  money(p.rent),
                  p.rent > 0 ? _good : NF.muted,
                ),
              ],
            ),
            if (p.value > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (equity / p.value).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: NF.surface2,
                  color: _good,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You own ${(equity * 100 / p.value).clamp(0, 100).round()}% outright; the bank owns the rest.',
                style: NF.sora(11, color: NF.muted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NF.sora(11, color: NF.muted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: NF.sora(15, weight: FontWeight.w700, color: color),
          ),
        ),
      ],
    ),
  );

  // ---------------- Where you live ----------------

  Widget _homeCard(BuildContext context, Life life, Asset home) {
    final traits = List<String>.from(home.info['traits'] ?? const [])
        .map((t) => homeTraits[t]?.$1 ?? t)
        .toList();
    return NFCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(
            Icons.home_rounded,
            home.name,
            [
              home.info['area'] ?? life.city,
              if (home.info['beds'] != null) '${home.info['beds']} bed',
              if (home.info['garden'] == true) 'garden',
              if (home.info['pool'] == true) 'pool',
            ].join(' · '),
            money(home.value),
            '${money(home.yearlyCost)}/yr to run',
          ),
          const SizedBox(height: 10),
          ConditionBar(condition: home.condition),
          if (traits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Known for: ${traits.join(', ')}',
              style: NF.sora(12, color: NF.soft),
            ),
          ],
          const SizedBox(height: 12),
          Text('Look after it', style: NF.sora(12, color: NF.muted)),
          const SizedBox(height: 6),
          _buttons([
            if (home.condition < 80)
              (
                'Repair (${money(repairCost(home))})',
                life.money >= repairCost(home)
                    ? () => _work(context, 'Repairs', repairHome, home)
                    : null,
              ),
            (
              'Renovate (${money(renovationCost(home))})',
              renovateLock(life, home) == null
                  ? () => _work(context, 'Renovation', renovateHome, home)
                  : null,
            ),
            _act(context, life, 'Do some DIY', 'diy'),
            _act(context, life, 'Add a room', 'home_upgrade'),
            _act(context, life, 'Insurance', 'home_insurance'),
          ]),
          const SizedBox(height: 10),
          Text('Live in it', style: NF.sora(12, color: NF.muted)),
          const SizedBox(height: 6),
          _buttons([
            if (home.info['warmed'] != true)
              _act(context, life, 'Housewarming', 'housewarming'),
            if (home.info['garden'] == true)
              _act(context, life, 'Garden', 'tend_garden'),
            _act(context, life, 'Remortgage', 'remortgage'),
            ('Move house', () => _moveHouse(context)),
            ('Sell', () => _sell(context, home)),
          ]),
        ],
      ),
    );
  }

  Widget _notOwning(BuildContext context, Life life, Asset? flat) {
    if (flat == null) {
      return Text(
        life.age < 18
            ? 'You live with your family. Renting and buying open at 18.'
            : 'You live with your family. Rent a place or buy your first home below.',
        style: NF.sora(13, color: NF.muted),
      );
    }
    return NFCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(
            Icons.key_rounded,
            flat.name,
            '${flat.info['area'] ?? life.city} · ${flat.info['landlord'] == 'slow' ? 'a slow landlord' : 'a decent landlord'}'
                '${flat.info['shared'] == true ? ' · flatmates' : ''}',
            money(flat.yearlyCost),
            'rent a year',
          ),
          const SizedBox(height: 12),
          _buttons([
            _act(context, life, 'Find somewhere else', 'rent_flat'),
            ('Move out', () => _sell(context, flat)),
          ]),
        ],
      ),
    );
  }

  // ---------------- Market ----------------

  List<Widget> _finders(BuildContext context, Life life) {
    final auction = c.engine!.actions
        .where((a) => a.id == 'property_auction')
        .firstOrNull;
    final rent = c.engine!.actions
        .where((a) => a.id == 'rent_flat')
        .firstOrNull;
    final lots = auctionLots(life)
        .where((x) => !life.marks.contains('lot:${life.age}:${x.i}'))
        .length;
    return [
      if (auction != null)
        OptionRow(
          icon: Icons.gavel_rounded,
          title: 'Property auction',
          detail: life.age < 21
              ? 'Unlocks at 21'
              : lots == 0
              ? 'Every lot has sold this year'
              : '$lots lot${lots == 1 ? '' : 's'} well under value · cash only · sold as seen',
          locked: auction.lockReason(life) != null || lots == 0,
          onTap: () => runActionFlow(context, c, auction, closeSheet: false),
        ),
      if (rent != null && homeOf(life) == null) ...[
        const SizedBox(height: 8),
        OptionRow(
          icon: Icons.key_rounded,
          title: 'Rent a place',
          detail:
              rent.lockReason(life) ??
              'Six places, from a room in a shared house up',
          locked: rent.lockReason(life) != null,
          onTap: () => runActionFlow(context, c, rent, closeSheet: false),
        ),
      ],
    ];
  }

  List<Widget> _market(BuildContext context, Life life, bool owns) {
    final buyLocked = life.age < 21
        ? 'Unlocks at 21'
        : life.prison != null
        ? 'Not possible in prison'
        : null;
    return [
      HubHeading(
        'For sale in ${life.city}',
        sub: 'Six homes this year · tap one to view, survey or make an offer',
      ),
      if (owns) ...[
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('To let out'),
              icon: Icon(Icons.key_rounded),
            ),
            ButtonSegment(
              value: false,
              label: Text('To live in'),
              icon: Icon(Icons.home_rounded),
            ),
          ],
          selected: {_toLet},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _toLet = s.first),
        ),
        const SizedBox(height: 10),
      ],
      for (final h in listings(life).where((h) => !listingSold(life, h.i))) ...[
        _ListingCard(
          listing: h,
          toLet: owns && _toLet,
          lock: buyLocked,
          onTap: buyLocked != null ? null : () => _view(context, life, h.i),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  /// Opens a listing, remembering whether you are moving or buying to let.
  void _view(BuildContext context, Life life, int i) {
    if (c.busyReason case final busy?) {
      showBusyNotice(context, c, busy);
      return;
    }
    if (homeOf(life) != null) {
      c.wealth((l) {
        if (_toLet) {
          l.marks.remove('hunt:${l.age}:move');
        } else {
          l.marks.add('hunt:${l.age}:move');
        }
        return null;
      });
    }
    c.openScene('house_view:$i');
    showEvent(context, c);
  }

  /// Opens this year's listings as a hunt for a new home to move into.
  void _moveHouse(BuildContext context) {
    if (c.busyReason case final busy?) {
      showBusyNotice(context, c, busy);
      return;
    }
    setState(() => _toLet = false);
    c.wealth((l) => l.marks.add('hunt:${l.age}:move'));
    c.openScene('house_hunt');
    showEvent(context, c);
  }

  // ---------------- Helpers ----------------

  (String, VoidCallback?) _act(
    BuildContext context,
    Life life,
    String label,
    String id,
  ) {
    final g = c.engine!.actions.where((x) => x.id == id).firstOrNull;
    final ok = g != null && g.lockReason(life) == null;
    return (
      label,
      ok ? () => runActionFlow(context, c, g, closeSheet: false) : null,
    );
  }

  void _work(
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
    final owed = a.kind != 'house'
        ? 0
        : a.info['let'] == true
        ? letDebtShare(life, a)
        : life.debts['Mortgage'] ?? 0;
    final fee = (a.value * 0.03).round();
    final detail = a.kind == 'rental'
        ? 'You will move back in with family and stop paying rent.'
        : 'It is worth about ${money(a.value)}. After the 3% agent fee '
              '(${money(fee)})${owed > 0 ? ' and the mortgage on it (${money(owed)})' : ''}, '
              'about ${money(a.value - fee - owed)} comes to you.';
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
    showResultPopup(
      context,
      r,
      title: '$verb: ${a.name}',
      icon: Icons.real_estate_agent_rounded,
    );
  }
}

String _signed(int v) => '${v >= 0 ? '+' : '−'}${money(v.abs())}';

Widget _titleRow(
  IconData icon,
  String title,
  String sub,
  String value,
  String valueSub,
) => Row(
  children: [
    Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: NF.blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: NF.blue),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: NF.sora(16, weight: FontWeight.w700)),
          ),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: NF.sora(12, color: NF.muted),
          ),
        ],
      ),
    ),
    const SizedBox(width: 8),
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: NF.sora(16, weight: FontWeight.w700)),
        Text(valueSub, style: NF.sora(11, color: NF.muted)),
      ],
    ),
  ],
);

Widget _buttons(List<(String, VoidCallback?)> items) => Wrap(
  spacing: 8,
  runSpacing: 6,
  children: [
    for (final (label, tap) in items)
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: NF.text,
          side: BorderSide(color: NF.borderStrong),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: tap,
        child: Text(label),
      ),
  ],
);

/// A labelled condition bar, green to red.
class ConditionBar extends StatelessWidget {
  const ConditionBar({super.key, required this.condition});
  final int condition;

  @override
  Widget build(BuildContext context) {
    final color = condition >= 60
        ? _good
        : condition >= 30
        ? NF.orange
        : NF.danger;
    return Row(
      children: [
        Text('Condition', style: NF.sora(12, color: NF.muted)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: condition / 100,
              minHeight: 6,
              backgroundColor: NF.surface2,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$condition%', style: NF.sora(12, weight: FontWeight.w600)),
      ],
    );
  }
}

// ---------------- One rental ----------------

class _LetCard extends StatelessWidget {
  const _LetCard({
    super.key,
    required this.controller,
    required this.asset,
    required this.onSell,
  });

  final GameController controller;
  final Asset asset;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final life = c.life!;
    final a = asset;
    final holiday = isHoliday(a);
    final vacant = isVacant(a);
    final t = tenantOf(a);
    final agent = a.info['agent'] == true;
    final income = rentIncome(life, a);
    final status = holiday
        ? 'holiday let, booked ${occupancyOf(a)}% of the year'
        : vacant
        ? 'empty, no rent coming in'
        : t == null
        ? 'let to tenants'
        : '${t['name']} · ${tenantKinds[t['kind']]?.label.toLowerCase() ?? 'tenant'} since age ${t['since']}';

    void run(String title, String Function(Life) f) {
      final text = c.wealth(f);
      if (text.isEmpty) return;
      showResultPopup(
        context,
        ActionResult(text),
        title: title,
        icon: Icons.key_rounded,
      );
    }

    void scene(String id) {
      if (c.busyReason case final busy?) {
        showBusyNotice(context, c, busy);
        return;
      }
      c.openScene(id);
      showEvent(context, c);
    }

    void work(String title, ActionResult Function(Life, Asset) f) {
      final r = c.wealth((l) => f(l, a));
      showResultPopup(context, r, title: title, icon: Icons.handyman_rounded);
    }

    return NFCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(
            holiday ? Icons.luggage_rounded : Icons.key_rounded,
            a.name,
            '${a.info['area'] ?? ''} · $status',
            money(a.value),
            income > 0 ? '+${money(income)}/yr' : 'no rent',
          ),
          const SizedBox(height: 10),
          ConditionBar(condition: a.condition),
          const SizedBox(height: 4),
          Text(
            [
              'Runs ${money(a.yearlyCost)} a year',
              if (letDebtShare(life, a) > 0)
                '${money(letDebtShare(life, a))} still owed',
              if (!holiday) agent ? 'agent manages it' : 'you manage it',
              if (a.info['auction'] == true) 'bought at auction',
            ].join(' · '),
            style: NF.sora(12, color: NF.soft),
          ),
          if (!holiday) ...[
            const SizedBox(height: 10),
            Text('Rent level', style: NF.sora(12, color: NF.muted)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  for (final e in rentLevels.entries)
                    ButtonSegment(
                      value: e.key,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(switch (e.key) {
                          'low' => 'Low',
                          'high' => 'High',
                          _ => 'Market',
                        }),
                      ),
                    ),
                ],
                selected: {rentLevelOf(a)},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) =>
                    c.wealth((l) => setRentLevel(l, a, s.first)),
              ),
            ),
            const SizedBox(height: 4),
            Text(switch (rentLevelOf(a)) {
              'low' => '${money(rentFor(a))} a year · tenants stay longer',
              'high' => '${money(rentFor(a))} a year · tenants leave sooner',
              _ => '${money(rentFor(a))} a year · what similar homes charge',
            }, style: NF.sora(11, color: NF.muted)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (vacant && !holiday)
                FilledButton(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => scene('let_pick:${a.id}'),
                  child: const Text('Find a tenant'),
                ),
              ...[
                if (!holiday)
                  (
                    agent ? 'Drop the agent' : 'Hire an agent',
                    () => run('Letting agent', (l) => toggleAgent(l, a)),
                  ),
                if (t != null)
                  (
                    'Give notice',
                    () => run('Notice given', (l) => giveNotice(l, a)),
                  ),
                if (holiday)
                  ('Back to long lets', () => work('Long lets', endHolidayLet))
                else
                  (
                    'Holiday let (${money(furnishCost(a))})',
                    holidayLock(life, a) == null
                        ? () => work('Holiday let', makeHolidayLet)
                        : null,
                  ),
                if (a.condition < 80)
                  (
                    'Repair (${money(repairCost(a))})',
                    life.money >= repairCost(a)
                        ? () => work('Repairs', repairHome)
                        : null,
                  ),
                (
                  'Renovate (${money(renovationCost(a))})',
                  renovateLock(life, a) == null
                      ? () => work('Renovation', renovateHome)
                      : null,
                ),
                ('Sell', onSell),
              ].map(
                (e) => OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NF.text,
                    side: BorderSide(color: NF.borderStrong),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: e.$2,
                  child: Text(e.$1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- One listing ----------------

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.toLet,
    required this.lock,
    required this.onTap,
  });

  final Listing listing;
  final bool toLet;
  final String? lock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final h = listing;
    final rent = (h.price * 0.05 / 100).round() * 100;
    final yieldPct = (rent - h.upkeep) * 100 / h.price;
    return Material(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _typeIcon(h.type),
                color: lock != null ? NF.muted : NF.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.type} · ${h.area}',
                      style: NF.sora(14, weight: FontWeight.w700),
                    ),
                    Text(
                      [
                        '${h.beds} bed',
                        if (h.garden) 'garden',
                        if (h.pool) 'pool',
                        'looks ${conditionBand(h.shown).toLowerCase()}',
                      ].join(' · '),
                      style: NF.sora(12, color: NF.muted),
                    ),
                    Text(
                      lock ??
                          (toLet
                              ? 'Rent about ${money(rent)} a year · ${yieldPct.toStringAsFixed(1)}% after running costs'
                              : '${areas[h.area]?.$2 ?? ''} · runs ${money(h.upkeep)} a year'),
                      style: NF.sora(
                        11,
                        color: lock != null ? NF.muted : NF.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(money(h.price), style: NF.sora(15, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _typeIcon(String type) => switch (type) {
  'Flat' || 'Penthouse' => Icons.apartment_rounded,
  'Houseboat' => Icons.directions_boat_rounded,
  'Farmhouse' => Icons.agriculture_rounded,
  'Mansion' => Icons.castle_rounded,
  _ => Icons.house_rounded,
};
