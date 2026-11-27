import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/era_justice.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// While an era life is held (Phase 2C), its tabs become Life, Prison,
/// Visitors and Me, in the life's own look: the Stinche, Newgate, Tor di
/// Nona, the debtors' ward or the galleys.
const eraInsideDestinations = <(IconData, IconData, String)>[
  (Icons.edit_note_outlined, Icons.edit_note, 'Life'),
  (Icons.lock_outline, Icons.lock, 'Prison'),
  (Icons.groups_outlined, Icons.groups, 'Visitors'),
  (Icons.menu_book_outlined, Icons.menu_book, 'Me'),
];

class EraPrisonTab extends StatelessWidget {
  const EraPrisonTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final m = eraInsideOf(life);
    if (m == null) return const SizedBox.shrink();
    final kind = m['kind'] as String;
    final name = m['name'] as String;
    final left = m['left'] as int? ?? 0;
    final debt = m['debt'] as int? ?? 0;
    final fee = eraJailerFee(life, era);
    final fed = m['fed'] == true;
    final feast = eraFeastRelease(life, era);
    String years(int n) => n == 1 ? 'a year' : '$n years';
    final sub = switch (kind) {
      'galleys' =>
        '${eraCap(m['why'] as String)}. Chained to the bench, ${years(left)} still to row.',
      'debt' =>
        'Held for a debt of ${moneyIn(debt, life.country)}. You walk out the day it is paid.',
      _ =>
        '${eraCap(m['why'] as String)}. ${eraCap(years(left))} still to serve, unless a petition is heard.',
    };
    return EraBody(
      life: life,
      kicker: '${eraCap(name)} · ${life.city} ${life.year}',
      title: kind == 'galleys'
          ? 'At the oar'
          : 'Inside ${name.startsWith('the ') ? name : name}',
      sub: sub,
      children: [
        if (kind != 'galleys')
          EraCard(
            life: life,
            title: 'The jailer',
            note: 'Food, a blanket and a dry place cost money inside.',
            children: [
              EraRow(
                first: true,
                title: 'Pay for bread and a blanket',
                sub: 'Your health holds',
                pill: '${moneyIn(fee, life.country)}/yr',
                filled: fed,
                lock: !fed && life.money < fee
                    ? 'Needs ${moneyIn(fee, life.country)}.'
                    : null,
                onTap: fed
                    ? null
                    : () => eraRun(
                        context,
                        controller,
                        'The jailer',
                        (l, e, _) => setEraFed(l, e, true),
                        icon: Icons.bakery_dining_outlined,
                      ),
              ),
              EraRow(
                title: 'Go without',
                sub: 'Eat what charity brings. Your health falls',
                pill: fed ? 'Choose' : 'Chosen',
                filled: !fed,
                onTap: !fed
                    ? null
                    : () => eraRun(
                        context,
                        controller,
                        'The jailer',
                        (l, e, _) => setEraFed(l, e, false),
                        icon: Icons.bakery_dining_outlined,
                      ),
              ),
            ],
          ),
        EraCard(
          life: life,
          title: 'Getting out',
          children: [
            if (kind == 'debt')
              EraRow(
                first: true,
                title: 'Pay what you owe',
                sub: 'And walk out today',
                pill: moneyIn(debt, life.country),
                lock: life.money < debt
                    ? 'Needs ${moneyIn(debt, life.country)}.'
                    : null,
                onTap: () => eraRun(
                  context,
                  controller,
                  'Paid',
                  (l, e, _) => payEraDebt(l, e),
                  icon: Icons.lock_open,
                ),
              ),
            EraRow(
              first: kind != 'debt',
              title: switch (era.regionOf(life).group) {
                'italy' || 'islands' => 'Petition for grace (grazia)',
                'england' => 'Petition for a pardon',
                _ => 'Ask for mercy',
              },
              sub: 'Your family, your guild and your good name can sign it',
              pill: 'Try',
              lock: life.usedActions.contains('era_petition')
                  ? 'Next year.'
                  : null,
              onTap: () => eraRun(
                context,
                controller,
                'The petition',
                petitionFromInside,
                icon: Icons.history_edu,
              ),
            ),
            if (feast != null && kind == 'prison')
              EraRow(
                title: 'Feast-day release',
                sub: feast,
                pill: 'June',
              ),
            if (kind != 'galleys')
              EraRow(
                title: 'Beg at the grate',
                sub: 'Coins from passers-by',
                pill: 'Try',
                lock: life.usedActions.contains('era_beg')
                    ? 'Next year.'
                    : null,
                onTap: () => eraRun(
                  context,
                  controller,
                  'At the grate',
                  begAtGrate,
                  icon: Icons.front_hand_outlined,
                ),
              ),
          ],
        ),
        Text(
          'Each year inside passes with Age +1. Work and school wait for you.',
          style: NF.sora(13, color: NF.muted),
        ),
      ],
    );
  }
}

/// Who might come to see you inside.
class EraVisitorsTab extends StatelessWidget {
  const EraVisitorsTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final m = eraInsideOf(life);
    final people = [
      for (final n in life.npcs)
        if (n.alive) n,
    ];
    return EraBody(
      life: life,
      kicker: 'Visitors · ${life.city} ${life.year}',
      title: 'Who will come?',
      sub: m?['kind'] == 'galleys'
          ? 'Few visitors reach a galley. A letter might.'
          : 'Visitors bring bread, news and courage.',
      children: [
        EraCard(
          life: life,
          title: 'Your people',
          note: people.isEmpty ? 'There is no one to send for.' : null,
          children: [
            for (final (i, n) in people.indexed)
              EraRow(
                first: i == 0,
                title: n.name,
                sub: '${n.role} · ${n.bondLabel}',
                pill: life.usedActions.contains('era_visit_${n.id}')
                    ? 'Asked'
                    : 'Ask',
                lock: m?['kind'] == 'galleys' ? 'Too far away.' : null,
                onTap: life.usedActions.contains('era_visit_${n.id}')
                    ? null
                    : () => eraRun(
                        context,
                        controller,
                        'A visit',
                        (l, e, rng) => askToVisit(l, n, rng),
                        icon: Icons.groups_outlined,
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
