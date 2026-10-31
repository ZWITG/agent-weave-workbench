import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/shopping.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart' show OptionRow;
import 'hub_kit.dart';
import 'result_popup.dart';
import 'widgets.dart';

const _deptIcons = <String, IconData>{
  'clothes': Icons.checkroom_rounded,
  'tech': Icons.devices_rounded,
  'home': Icons.chair_rounded,
  'books': Icons.menu_book_rounded,
  'sport': Icons.sports_tennis_rounded,
  'beauty': Icons.spa_rounded,
  'food': Icons.restaurant_rounded,
  'luxury': Icons.diamond_rounded,
  'gifts': Icons.card_giftcard_rounded,
  'subs': Icons.autorenew_rounded,
  'stuff': Icons.inventory_2_rounded,
};

/// One thing bought in the shop that lasts, with Return and Sell. Shown in
/// the shop's "Your stuff" and on the Wealth tab's "What you own".
class OwnedItemCard extends StatefulWidget {
  const OwnedItemCard({
    super.key,
    required this.controller,
    required this.item,
  });
  final GameController controller;
  final Map<String, dynamic> item;

  @override
  State<OwnedItemCard> createState() => _OwnedItemCardState();
}

/// Tap the card to see when you bought it, what it does and your options.
class _OwnedItemCardState extends State<OwnedItemCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final item = widget.item;
    final life = c.life!;
    final i = itemById(item['id'] as String);
    if (i == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NFCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  Icon(_deptIcons[i.dept], color: NF.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i.name,
                      style: NF.sora(15, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${item['left']} yr${item['left'] == 1 ? '' : 's'} left',
                    style: NF.sora(12, color: NF.muted),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: NF.muted,
                  ),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: 4),
              Text(
                'Bought at ${item['age']} for ${money(item['paid'] as int)} · ${i.blurb}${i.yearly.isEmpty ? '' : ' · ${i.yearly.entries.map((e) => '${_stat(e.key)} ${_signed(e.value)} a year').join(', ')}'}',
                style: NF.sora(12, color: NF.soft),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: returnLock(life, item) == null
                        ? () {
                            final r = c.wealth((l) => returnItem(l, item));
                            showResultPopup(
                              context,
                              r,
                              title: 'Returned',
                              icon: Icons.undo_rounded,
                            );
                          }
                        : null,
                    child: Text(
                      returnLock(life, item) == null
                          ? 'Return'
                          : 'Return (this year only)',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final r = c.wealth((l) => sellItem(l, item));
                      showResultPopup(
                        context,
                        r,
                        title: 'Sold',
                        icon: Icons.sell_rounded,
                      );
                    },
                    child: Text('Sell for ${money(resaleOf(item))}'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _stat(String k) => '${k[0].toUpperCase()}${k.substring(1)}';

String _signed(int v) => v >= 0 ? '+$v' : '−${-v}';

/// The shop, laid out like the Activities panel: sale banner, today's
/// deals, search, departments as tiles, and "Your stuff" for returns,
/// resale and subscriptions.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String? _dept;
  String _q = '';

  /// Department view: 'range' (grouped by price), 'low' or 'high'.
  String _sort = 'range';
  bool _affordable = false;
  final _search = TextEditingController();

  GameController get c => widget.controller;
  Life get life => c.life!;
  DateTime get _now => DateTime.now();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(String? d) => setState(() {
    _dept = d;
    _sort = 'range';
    _affordable = false;
    _search.clear();
    _q = '';
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        backgroundColor: NF.bg,
        appBar: AppBar(
          backgroundColor: NF.bg,
          title: Text('Shop', style: NF.sora(18, weight: FontWeight.w700)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Pill(
                  money(life.money),
                  bg: const Color(0xFF173B2E),
                  fg: const Color(0xFF5EE6A8),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _dept == null
                ? _home(context)
                : _department(context, _dept!),
          ),
        ),
      ),
    );
  }

  // ---------------- Home ----------------

  Widget _home(BuildContext context) {
    final sale = saleOn(_now);
    final deals = dealsOn(_now);
    final searching = _q.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        if (sale != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NF.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NF.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: NF.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${sale.$1}: ${sale.$2}% off ${sale.$3.map((d) => departments[d]!.toLowerCase()).join(', ')}',
                    style: NF.sora(14, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        HubSearch(
          controller: _search,
          hint: 'Search the shop',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching) ...[
          const SizedBox(height: 14),
          for (final i in catalogue.where(
            (i) => matchesQuery(_q, [i.name, i.blurb, departments[i.dept]!]),
          ))
            _ItemCard(item: i, shop: this),
          for (final s in subscriptions.where(
            (s) => matchesQuery(_q, [s.name, s.blurb, 'subscription']),
          ))
            _subRow(context, s),
        ] else ...[
          const HubHeading('Today\'s deals', sub: 'New deals every day'),
          for (final e in deals.entries)
            if (itemById(e.key) case final i?) _ItemCard(item: i, shop: this),
          const HubHeading('Departments'),
          BrowseGrid(
            items: [
              for (final d in departments.entries)
                BrowseItem(
                  icon: _deptIcons[d.key]!,
                  label: d.value,
                  status: d.key == 'subs'
                      ? (life.subs.isEmpty
                            ? 'None yet'
                            : '${life.subs.length} active')
                      : sale != null && sale.$3.contains(d.key)
                      ? '${sale.$2}% off'
                      : '${catalogue.where((i) => i.dept == d.key).length} items',
                  alert: sale != null && sale.$3.contains(d.key),
                  onTap: () => _open(d.key),
                ),
              BrowseItem(
                icon: _deptIcons['stuff']!,
                label: 'Your stuff',
                status: life.items.isEmpty
                    ? 'Nothing yet'
                    : '${life.items.length} things',
                dim: life.items.isEmpty && life.subs.isEmpty,
                onTap: () => _open('stuff'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------------- Department pages ----------------

  Widget _department(BuildContext context, String d) {
    final title = d == 'stuff' ? 'Your stuff' : departments[d]!;
    final sub = switch (d) {
      'subs' => 'Paid each birthday · cancel any time',
      'gifts' => 'Pick someone, then a gift they will love',
      'luxury' => 'Kept on Wealth › What you own and can be sold',
      'stuff' => 'Return things bought this year, or sell them second-hand',
      _ => 'Effects show on each item',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        SectionBar(
          back: 'Shop',
          title: title,
          sub: sub,
          onBack: () => _open(null),
        ),
        if (d == 'subs')
          for (final s in subscriptions) _subRow(context, s)
        else if (d == 'stuff')
          ..._stuff(context)
        else
          ..._items(d),
      ],
    );
  }

  /// A department's items: sort and filter chips, then the items, grouped
  /// into price ranges unless sorted.
  List<Widget> _items(String d) {
    final items = [
      for (final i in catalogue.where((i) => i.dept == d))
        if (!_affordable || priceOf(life, i, _now) <= life.money) i,
    ];
    int price(ShopItem i) => priceOf(life, i, _now);
    items.sort(
      (a, b) => _sort == 'high'
          ? price(b).compareTo(price(a))
          : price(a).compareTo(price(b)),
    );
    Widget chip(String label, bool on, VoidCallback tap) => ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(tap),
    );
    String range(ShopItem i) => price(i) < 100
        ? 'Budget · under \$100'
        : price(i) < 1000
        ? 'Mid-range · \$100 to \$999'
        : 'Premium · \$1,000 and up';
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('By price range', _sort == 'range', () => _sort = 'range'),
          chip('Cheapest first', _sort == 'low', () => _sort = 'low'),
          chip('Priciest first', _sort == 'high', () => _sort = 'high'),
          FilterChip(
            label: const Text('What I can afford'),
            selected: _affordable,
            onSelected: (v) => setState(() => _affordable = v),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Text(
          'Nothing here you can afford right now.',
          style: NF.sora(14, color: NF.muted),
        ),
      for (var k = 0; k < items.length; k++) ...[
        if (_sort == 'range' &&
            (k == 0 || range(items[k - 1]) != range(items[k])))
          HubHeading(range(items[k])),
        _ItemCard(item: items[k], shop: this),
      ],
    ];
  }

  Widget _subRow(BuildContext context, Subscription s) {
    final on = life.subs.contains(s.id);
    final lock = on ? null : subLock(life, s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OptionRow(
        icon: Icons.autorenew_rounded,
        title: s.name,
        detail:
            lock ??
            '${money(s.yearly)} a year · ${s.blurb}${on ? ' · tap to cancel' : ''}',
        locked: lock != null,
        trailing: on ? Icons.check_circle_rounded : Icons.add_circle_outline,
        onTap: () {
          final r = c.wealth((l) => on ? unsubscribe(l, s) : subscribe(l, s));
          showResultPopup(
            context,
            r,
            title: s.name,
            icon: Icons.autorenew_rounded,
          );
        },
      ),
    );
  }

  List<Widget> _stuff(BuildContext context) {
    final items = life.items;
    return [
      if (items.isEmpty)
        Text(
          'Things that last (tech, furniture, gear) show up here. Everything you own, homes and valuables included, is listed on Wealth › What you own.',
          style: NF.sora(14, color: NF.muted),
        ),
      for (final item in List<Map<String, dynamic>>.from(items))
        OwnedItemCard(key: ObjectKey(item), controller: c, item: item),
      if (life.subs.isNotEmpty) ...[
        const HubHeading('Subscriptions'),
        for (final id in List<String>.from(life.subs))
          if (subById(id) case final s?) _subRow(context, s),
      ],
    ];
  }

  // ---------------- Buying ----------------

  Future<void> buy(BuildContext context, ShopItem i) async {
    final lock = itemLock(life, i);
    if (lock != null) return;
    final price = priceOf(life, i, _now);
    final gift = i.dept == 'gifts';
    Npc? to;
    if (gift || i.likes.isNotEmpty) {
      final pick = await _pickRecipient(context, i, required: gift);
      if (pick == null) return; // closed
      to = pick.$1;
    }
    if (!context.mounted) return;
    final how = await _pickPayment(context, i, price, to);
    if (how == null || !context.mounted) return;
    final r = c.wealth(
      (l) => buyItem(
        l,
        i,
        pay: how,
        giftFor: to,
        now: _now,
        rng: Random(l.seed + l.age * 31 + l.marks.length),
      ),
    );
    if (!context.mounted) return;
    await showResultPopup(
      context,
      r,
      title: to == null ? i.name : 'A gift for ${to.name.split(' ').first}',
      icon: _deptIcons[i.dept]!,
      cue: 'purchase',
    );
  }

  /// Returns (person or null for yourself), or null when closed.
  Future<(Npc?,)?> _pickRecipient(
    BuildContext context,
    ShopItem i, {
    required bool required,
  }) {
    final people =
        life.npcs
            .where((n) => n.alive && n.circle != 'Pets' && n.circle != 'Prison')
            .toList()
          ..sort((a, b) {
            final la = loves(life, a, i) ? 0 : 1;
            final lb = loves(life, b, i) ? 0 : 1;
            return la != lb ? la.compareTo(lb) : b.bond.compareTo(a.bond);
          });
    return showModalBottomSheet<(Npc?,)>(
      context: context,
      backgroundColor: NF.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text(
              required ? 'Who is it for?' : 'For you, or a gift?',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (!required) ...[
              OptionRow(
                icon: Icons.person_rounded,
                title: 'For me',
                detail: i.now.isEmpty
                    ? i.blurb
                    : i.now.entries
                          .map((e) => '${_stat(e.key)} +${e.value}')
                          .join(', '),
                onTap: () => Navigator.pop(ctx, (null,)),
              ),
              const SizedBox(height: 8),
            ],
            if (people.isEmpty)
              Text(
                'Nobody to give it to yet.',
                style: NF.sora(14, color: NF.muted),
              ),
            for (final n in people.take(12)) ...[
              OptionRow(
                icon: loves(life, n, i)
                    ? Icons.favorite_rounded
                    : Icons.card_giftcard_rounded,
                title: '${n.name.split(' ').first} · ${n.role}',
                detail: loves(life, n, i)
                    ? 'They would love this · Bond ${n.bond}%'
                    : 'A kind thought · Bond ${n.bond}%',
                onTap: () => Navigator.pop(ctx, (n,)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _pickPayment(
    BuildContext context,
    ShopItem i,
    int price,
    Npc? to,
  ) {
    String? lock(String how) => payLock(life, how, price);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: NF.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${i.name} · ${money(price)}',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
            Text(
              to == null
                  ? 'How do you want to pay?'
                  : 'For ${to.name.split(' ').first}. How do you want to pay?',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 12),
            for (final (how, icon, title, detail) in [
              (
                'cash',
                Icons.payments_rounded,
                'Pay now',
                'From your ${money(life.money)} cash',
              ),
              (
                'card',
                Icons.credit_card_rounded,
                'Put it on your card',
                '20% a year on what you owe',
              ),
              (
                'later',
                Icons.event_repeat_rounded,
                'Pay in 3',
                '${money((price / 3).ceil())} today, the rest at your next birthday · 0%',
              ),
            ]) ...[
              OptionRow(
                icon: icon,
                title: title,
                detail: lock(how) ?? detail,
                locked: lock(how) != null,
                onTap: () => Navigator.pop(ctx, how),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.shop});
  final ShopItem item;
  final _ShopScreenState shop;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final life = shop.life;
    final now = DateTime.now();
    final price = priceOf(life, i, now);
    final off = discountOn(i, now);
    final lock = itemLock(life, i);
    final effects = [
      for (final e in i.now.entries) '${_stat(e.key)} ${_signed(e.value)}',
      for (final e in i.yearly.entries)
        '${_stat(e.key)} ${_signed(e.value)}/yr${i.years > 0 ? ' for ${i.years}' : ''}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: lock != null ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: lock == null ? () => shop.buy(context, i) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NF.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_deptIcons[i.dept], color: NF.orange, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.name, style: NF.sora(15, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        lock ?? i.blurb,
                        style: NF.sora(
                          12,
                          color: lock != null ? NF.orange : NF.muted,
                        ),
                      ),
                      if (effects.isNotEmpty || i.likes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final e in effects) _chip(e, NF.blue),
                            if (i.likes.isNotEmpty)
                              _chip(
                                'Gift for ${i.likes.map((l) => l == 'kid'
                                    ? 'kids'
                                    : l == 'teen'
                                    ? 'teens'
                                    : l == 'elder'
                                    ? 'older people'
                                    : l == 'partner'
                                    ? 'partners'
                                    : 'adults').join(', ')}',
                                const Color(0xFFFF8FC7),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(price),
                      style: NF.sora(15, weight: FontWeight.w700),
                    ),
                    if (off > 0) ...[
                      Text(
                        money(i.price),
                        style: NF
                            .sora(11, color: NF.muted)
                            .copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      Text(
                        '−$off%',
                        style: NF.sora(
                          11,
                          weight: FontWeight.w700,
                          color: NF.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      t,
      style: NF.sora(11, weight: FontWeight.w600, color: c),
    ),
  );
}

/// Opens the shop from the Activities panel or the Wealth tab.
void openShop(BuildContext context, GameController c) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ShopScreen(controller: c)));
