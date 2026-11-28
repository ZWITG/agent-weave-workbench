import 'package:flutter/material.dart';

import '../engine/era_market.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// The market in an era life (Phase 2D): cloth and dress, beasts, craft
/// and learning, and what you own (sell it back for half). Nothing modern
/// is for sale.
class EraMarketScreen extends StatelessWidget {
  const EraMarketScreen({super.key, required this.controller});
  final GameController controller;

  static const _groups = {
    'Cloth and dress': ['cloak', 'silk', 'copper'],
    'Beasts': ['mule', 'horse'],
    'Craft and learning': ['book', 'paper', 'lute', 'sword', 'spice'],
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final items = eraMarketHere(life, era);
      final owned = eraOwned(life);
      return EraPage(
        life: life,
        kicker: '${eraMarketName(life, era)} · ${life.year}',
        title: 'The market',
        sub: 'Nothing modern is for sale. What you own shows in Wealth and in your life story.',
        children: [
          for (final g in _groups.entries)
            if (items.any((i) => g.value.contains(i['id'])))
              EraCard(
                life: life,
                title: g.key,
                children: [
                  for (final (i, it) in items.where((i) => g.value.contains(i['id'])).indexed)
                    EraRow(
                      first: i == 0,
                      title: it['label'] as String,
                      sub: it['about'] as String? ?? '',
                      pill: eraOwns(life, it['id'] as String) && it['id'] != 'spice'
                          ? 'Yours'
                          : eraM(life, eraCost(life, era, it['cost'] as int)),
                      filled: eraOwns(life, it['id'] as String) && it['id'] != 'spice',
                      lock: eraOwns(life, it['id'] as String) && it['id'] != 'spice'
                          ? null
                          : eraItemLock(life, era, it),
                      onTap: eraOwns(life, it['id'] as String) && it['id'] != 'spice'
                          ? null
                          : () => eraRun(
                              context,
                              controller,
                              it['label'] as String,
                              (l, e, rng) => eraBuy(l, e, it['id'] as String, rng),
                              icon: Icons.storefront_outlined,
                            ),
                    ),
                ],
              ),
          if (owned.isNotEmpty)
            EraCard(
              life: life,
              title: 'What you own',
              children: [
                for (final (i, id) in owned.indexed)
                  EraRow(
                    first: i == 0,
                    title: eraItem(life, era, id)?['label'] as String? ?? id,
                    sub: 'Sell it back for half',
                    pill: 'Sell',
                    onTap: () => eraRun(
                      context,
                      controller,
                      'Selling',
                      (l, e, _) => eraSell(l, e, id),
                      icon: Icons.storefront_outlined,
                    ),
                  ),
              ],
            ),
          Text(
            'Prices: game approximations from historians\' price series.',
            style: NF.sora(12, color: NF.muted, height: 1.4),
          ),
        ],
      );
    },
  );
}
