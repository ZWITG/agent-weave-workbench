import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/era_health.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';
import 'health_screen.dart' show HelplinePanel;

/// Me → Health in an era life (Phase 2C): what ails you, the healers of
/// your city and their fees, and the plague when it comes. No insurance,
/// fitness or modern hospitals: those belong to modern lives.
class EraHealthScreen extends StatelessWidget {
  const EraHealthScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final group = era.regionOf(life).group;
      final humours = group != 'kongo';
      final ill = eraIllnesses(life);
      final healers = eraHealers(life, era);
      final plague = eraPlagueHere(life, era);
      final chosen = eraPlagueChoice(life);
      String money(int f) => f == 0 ? 'free' : moneyIn(f, life.country);
      return EraPage(
        life: life,
        kicker: 'Health · ${life.city} ${life.year}',
        title: humours ? 'The four humours' : 'Body and spirit',
        sub: [
          'Health ${life.stats['health']}%.',
          if (humours) 'Your humours lean ${eraHumour(life)}.',
          if (ill.isEmpty) 'Nothing ails you this year.',
        ].join(' '),
        children: [
          EraCard(
            life: life,
            title: 'What ails you',
            note: ill.isEmpty
                ? 'You are well. Fevers, the flux and the pox come to everyone sooner or later.'
                : 'Tap an ailment to send for someone, or to rest.',
            children: [
              for (final (i, id) in ill.indexed)
                if (eraAilment(era, id) case final a?)
                  EraRow(
                    first: i == 0,
                    title: a['name'] as String,
                    sub: a['about'] as String? ?? '',
                    pill: life.usedActions.contains('era_heal_$id')
                        ? 'Tried'
                        : 'Treat',
                    onTap: () => _treat(context, life, era, id, a, healers),
                  ),
            ],
          ),
          EraCard(
            life: life,
            title: 'Who to send for',
            note: 'The healers of ${life.city}.',
            children: [
              for (final (i, h) in healers.indexed)
                EraRow(
                  first: i == 0,
                  title: h.name,
                  sub: h.about,
                  pill: money(h.fee),
                  filled: h.fee > 0,
                ),
            ],
          ),
          if (plague)
            EraCard(
              life: life,
              title: 'Plague is in the city',
              note: chosen == null
                  ? '${life.year} is a plague year in ${life.city}. How will you meet it?'
                  : 'You have chosen for this year. It will be settled at your next birthday.',
              children: [
                for (final (i, p) in eraPlagueChoices(life, era).indexed)
                  EraRow(
                    first: i == 0,
                    title: p.label,
                    sub: p.about,
                    pill: chosen == p.id
                        ? 'Chosen'
                        : (p.cost > 0 ? money(p.cost) : null),
                    filled: chosen == p.id,
                    lock: chosen != null && chosen != p.id
                        ? 'You chose another way this year.'
                        : (chosen == null && life.money < p.cost
                              ? 'Needs ${money(p.cost)}.'
                              : null),
                    onTap: chosen != null
                        ? null
                        : () => eraRun(
                            context,
                            controller,
                            'The plague',
                            (l, e, _) => chooseEraPlague(l, e, p.id),
                            icon: Icons.coronavirus_outlined,
                          ),
                  ),
              ],
            ),
          if (life.eraWorld['hadPlague'] == true)
            Text(
              'You lived through the plague. Few can say it.',
              style: NF.sora(13, color: NF.muted),
            ),
          // A real-life safety card, not part of the story.
          const HelplinePanel(),
        ],
      );
    },
  );

  void _treat(
    BuildContext context,
    Life life,
    EraRules era,
    String id,
    Map<String, dynamic> a,
    List<EraHealer> healers,
  ) {
    final options = [
      (id: 'rest', name: 'Rest', about: 'Broth, warmth and time', fee: 0),
      ...healers,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: NF.surface,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text(a['name'] as String, style: eraHand(life, 30)),
            const SizedBox(height: 4),
            for (final (i, h) in options.indexed)
              EraRow(
                first: i == 0,
                title: h.name,
                sub: h.about,
                pill: h.fee == 0 ? 'free' : moneyIn(h.fee, life.country),
                lock: eraHealLock(life, h, id),
                onTap: () {
                  Navigator.of(sheet).pop();
                  eraRun(
                    context,
                    controller,
                    h.name,
                    (l, e, rng) => treatEraAilment(l, e, id, h.id, rng),
                    icon: Icons.healing_outlined,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
