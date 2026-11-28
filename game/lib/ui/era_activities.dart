import 'package:flutter/material.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/era_activities.dart';
import '../engine/era_wealth.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';
import 'era_law_screen.dart';
import 'era_market_screen.dart';
import 'journey.dart';
import 'minigames.dart';
import 'result_popup.dart';

/// Activities in an era life (Phase 2D): the things this place and year
/// offer, as tiles. Each plays an existing mini-game in an era skin, then
/// tells what happened. The market, the night streets and journeys open
/// their own screens. Replaces the "soon" sheet.
class EraActivitiesPanel extends StatelessWidget {
  const EraActivitiesPanel({
    super.key,
    required this.controller,
    this.scroll,
  });
  final GameController controller;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final life = controller.life!;
      final era = eraRegistry[life.era]!;
      final acts = eraActivitiesHere(life, era);
      return ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          eraKicker('Activities · ${life.city} ${life.year}'),
          const SizedBox(height: 4),
          Text('What will you do?', style: eraHand(life, 34)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              for (final a in acts)
                _Tile(
                  label: a['label'] as String,
                  sub: eraActivityLock(life, era, a) ?? _sub(life, era, a),
                  locked: eraActivityLock(life, era, a) != null,
                  onTap: () => _open(context, a),
                ),
            ],
          ),
        ],
      );
    },
  );

  String _sub(Life life, EraRules era, Map a) {
    final cost = eraActivityCost(life, era, a);
    return [
      a['about'] as String? ?? '',
      if (cost > 0) eraM(life, cost),
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  Future<void> _open(BuildContext context, Map<String, dynamic> a) async {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final nav = Navigator.of(context);
    if (a['market'] == true) {
      nav.push(MaterialPageRoute(builder: (_) => EraMarketScreen(controller: controller)));
      return;
    }
    if (a['law'] == true) {
      nav.push(MaterialPageRoute(builder: (_) => EraLawScreen(controller: controller)));
      return;
    }
    if (a['journey'] == true) {
      await openJourneys(context, controller);
      return;
    }
    final lock = eraActivityLock(life, era, a);
    if (lock != null) {
      await showResultPopup(context, ActionResult(lock), title: a['label'] as String);
      return;
    }
    var score = 0.6;
    final game = eraActivityGame(a);
    if (game != null) {
      final s = await showMiniGame(
        context,
        game,
        age: life.age,
        title: a['label'] as String,
        activity: a['id'] as String,
        life: life,
        game: game,
      );
      if (s == null) return;
      score = s;
    }
    final r = controller.eraLifeAct(
      (l, e, rng) => doEraActivity(l, e, a['id'] as String, score, rng),
    );
    if (nav.mounted) {
      await showResultPopup(
        nav.context,
        r,
        title: a['label'] as String,
        icon: Icons.celebration_outlined,
      );
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.sub, required this.locked, required this.onTap});
  final String label;
  final String sub;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: locked ? 0.55 : 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: NF.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NF.text, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: NF.sora(14.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: NF.sora(11.5, color: NF.muted, height: 1.2)),
          ],
        ),
      ),
    ),
  );
}
