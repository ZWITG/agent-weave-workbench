import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/currency.dart';
import '../engine/era_faith.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';
import 'result_popup.dart';

/// Me → Faith in an era life (Phase 2C): the faith you were born into, how
/// you keep it this year, your standing with neighbours, and in England
/// whether you go to the parish church or keep the old faith. Every faith
/// is written with respect; none is shown as the right one.
class EraFaithScreen extends StatelessWidget {
  const EraFaithScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final practices = eraPractices(life, era);
      final notes = eraFaithNotes(life, era);
      final english = eraFaithOf(life) == 'english' && life.year >= 1559;
      return EraPage(
        life: life,
        kicker: 'Faith · ${life.city} ${life.year}',
        title: 'Your faith',
        sub:
            '${eraFaithBorn(life, era)}${eraFaithOf(life) == 'english' ? ' The church of the realm is now: ${eraFaithName(life, era)}.' : ''} How you keep it is up to you.',
        children: [
          EraCard(
            life: life,
            title: 'This year',
            children: [
              for (final (i, p) in practices.indexed)
                EraRow(
                  first: i == 0,
                  title: p.label,
                  sub: p.about,
                  pill: life.usedActions.contains('era_faith_${p.id}')
                      ? 'Done'
                      : (p.data['cost'] != null
                            ? moneyIn(p.data['cost'] as int, life.country)
                            : 'Go'),
                  filled: life.usedActions.contains('era_faith_${p.id}'),
                  lock: life.usedActions.contains('era_faith_${p.id}')
                      ? null
                      : eraPracticeLock(life, era, p),
                  onTap: life.usedActions.contains('era_faith_${p.id}')
                      ? null
                      : () => eraRun(
                          context,
                          controller,
                          p.label,
                          (l, e, rng) => keepEraPractice(l, e, p.id, rng),
                          icon: Icons.brightness_5_outlined,
                        ),
                ),
              EraRow(
                title: 'Keep your own counsel',
                sub: 'What you believe is your own business',
                pill: 'Choose',
                onTap: () => showResultPopup(
                  context,
                  ActionResult(
                    'You kept your thoughts to yourself this year. No one asked.',
                  ),
                  title: 'Your own counsel',
                  icon: Icons.brightness_5_outlined,
                ),
              ),
            ],
          ),
          if (english)
            EraCard(
              life: life,
              title: 'Church or the old faith',
              note:
                  'Recusants pay fines of about ${moneyIn(eraRecusantFine(life, era), life.country)} a year.',
              children: [
                EraRow(
                  first: true,
                  title: 'Go to the parish church',
                  sub: 'As the law asks',
                  pill: eraRecusant(life) ? 'Choose' : 'Chosen',
                  filled: !eraRecusant(life),
                  onTap: !eraRecusant(life)
                      ? null
                      : () => eraRun(
                          context,
                          controller,
                          'Sundays',
                          (l, e, _) => setEraRecusant(l, e, false),
                        ),
                ),
                EraRow(
                  title: 'Keep the old faith',
                  sub: 'A recusant: Mass in secret, fines in the open',
                  pill: eraRecusant(life) ? 'Chosen' : 'Choose',
                  filled: eraRecusant(life),
                  onTap: eraRecusant(life)
                      ? null
                      : () => eraRun(
                          context,
                          controller,
                          'Sundays',
                          (l, e, _) => setEraRecusant(l, e, true),
                        ),
                ),
              ],
            ),
          EraCard(
            life: life,
            title: 'Standing',
            children: [
              const SizedBox(height: 4),
              EraMeter(value: eraStanding(life)),
              const SizedBox(height: 8),
              Text(
                'Neighbours who see you at worship are slower to speak against you, and a good name helps a petition.',
                style: NF.sora(13.5, color: NF.muted, height: 1.4),
              ),
            ],
          ),
          if (notes.isNotEmpty)
            EraCard(
              life: life,
              title: 'In ${life.city}',
              children: [
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      n,
                      style: NF.sora(14, color: NF.soft, height: 1.4),
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  );
}
