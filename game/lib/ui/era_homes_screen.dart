import 'package:flutter/material.dart';

import '../engine/era_homes.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// Wealth → Home in an era life (Phase 2D): where you live, what's to
/// rent and to buy here, the houses you own, and how homes look in other
/// parts of the world.
class EraHomesScreen extends StatelessWidget {
  const EraHomesScreen({super.key, required this.controller});
  final GameController controller;

  static const _elsewhere = {
    'italy':
        'London: a timber-framed house, a manor. Fez: a riad round a courtyard. Cairo: rooms in a rab\'. Mbanza Kongo: a walled compound. Ndongo and Matamba: the kilombo war camp.',
    'england':
        'Florence: a workshop with rooms above, a villa, a palazzo. Fez: a riad round a courtyard. Mbanza Kongo: a walled compound.',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final here = eraHomesHere(life, era);
      final owned = eraOwnedHomes(life);
      final now = eraHomeNow(life, era);
      String m(int v) => eraM(life, v);
      void run(String t, String Function(Life, EraRules) a) =>
          eraRun(context, controller, t, (l, e, _) => a(l, e), icon: Icons.house_outlined);
      final rent = here.where((h) => h.data.containsKey('rent')).toList();
      final buy = here.where((h) => h.data.containsKey('buy')).toList();
      return EraPage(
        life: life,
        kicker: 'Homes · ${life.city} ${life.year}',
        title: 'A roof in ${life.city}',
        sub: 'Where you live sets your standing, who visits and what it costs each year.',
        children: [
          EraCard(
            life: life,
            title: 'Where you live',
            children: [
              EraRow(
                first: true,
                title: eraHomeLine(life, era),
                sub: now == null
                    ? 'Free, and nobody leaves you alone'
                    : (eraRents(life)
                          ? (now.rent == 0 ? now.about : 'Rent ${m(now.rent)} a year · ${now.about}')
                          : (now.upkeep > 0 ? 'Upkeep ${m(now.upkeep)} a year · ${now.about}' : now.about)),
                pill: eraRents(life) && now?.data['start'] != true ? 'Leave' : null,
                onTap: eraRents(life) && now?.data['start'] != true
                    ? () => run('Moving out', eraLeaveHome)
                    : null,
              ),
            ],
          ),
          if (rent.isNotEmpty)
            EraCard(
              life: life,
              title: 'Rent',
              children: [
                for (final (i, h) in rent.indexed)
                  EraRow(
                    first: i == 0,
                    title: h.label,
                    sub: h.about,
                    pill: h.rent == 0 ? 'Free' : '${m(h.rent)}/yr',
                    lock: eraHomeLock(life, era, h, buy: false),
                    onTap: () => run(h.label, (l, e) => eraRentHome(l, e, h.id)),
                  ),
              ],
            ),
          if (buy.isNotEmpty)
            EraCard(
              life: life,
              title: 'Buy',
              children: [
                for (final (i, h) in buy.indexed)
                  EraRow(
                    first: i == 0,
                    title: h.label,
                    sub: h.about,
                    pill: owned.containsKey(h.id) ? 'Yours' : m(h.buy),
                    filled: owned.containsKey(h.id),
                    lock: owned.containsKey(h.id) ? null : eraHomeLock(life, era, h, buy: true),
                    onTap: owned.containsKey(h.id)
                        ? null
                        : () => run(h.label, (l, e) => eraBuyHome(l, e, h.id)),
                  ),
              ],
            ),
          if (owned.isNotEmpty)
            EraCard(
              life: life,
              title: 'Your houses',
              children: [
                for (final (i, e) in owned.entries.indexed)
                  if (eraHomeById(life, era, e.key) case final h?)
                    EraRow(
                      first: i == 0,
                      title: h.label,
                      sub: eraHomeId(life) == h.id
                          ? 'You live here · worth about ${m(e.value)}'
                          : 'Worth about ${m(e.value)} · sell for ${m(e.value * 4 ~/ 5)}',
                      pill: eraHomeId(life) == h.id ? 'Sell' : 'Move in',
                      onTap: eraHomeId(life) == h.id
                          ? () => run('Selling', (l, era) => eraSellHome(l, era, h.id))
                          : () => run('Moving', (l, era) => eraMoveHome(l, era, h.id)),
                    ),
              ],
            ),
          if (_elsewhere[era.regionOf(life).group] case final text?)
            EraCard(
              life: life,
              title: 'Elsewhere',
              children: [Text(text, style: NF.sora(14, color: NF.soft, height: 1.4))],
            ),
        ],
      );
    },
  );
}
