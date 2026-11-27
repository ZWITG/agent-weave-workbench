import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'legend_look.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// The journey sheet of an era life (Phase 2A): every city of the world in
/// this year, nearest first, with how you'd go, how long it takes, what it
/// costs and how risky it is.
Future<void> openJourneys(BuildContext context, GameController c) {
  final nav = Navigator.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => _JourneyList(
        controller: c,
        scroll: scroll,
        onGo: (j) {
          Navigator.of(sheet).pop();
          final r = c.journey(j);
          showResultPopup(
            nav.context,
            r,
            title: 'A journey to ${j.to}',
            icon: _icon(j.by),
          );
        },
      ),
    ),
  );
}

IconData _icon(JourneyBy by) => switch (by) {
  JourneyBy.road => Icons.hiking_rounded,
  JourneyBy.sea => Icons.sailing_rounded,
  JourneyBy.caravan => Icons.landscape_rounded,
};

String _by(JourneyBy by) => switch (by) {
  JourneyBy.road => 'By road',
  JourneyBy.sea => 'By ship',
  JourneyBy.caravan => 'By caravan',
};

String _risk(double r) => r < 0.03
    ? 'safe enough'
    : r < 0.06
    ? 'some danger'
    : 'dangerous';

class _JourneyList extends StatelessWidget {
  const _JourneyList({
    required this.controller,
    required this.scroll,
    required this.onGo,
  });
  final GameController controller;
  final ScrollController scroll;
  final void Function(Journey) onGo;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final look = legendLookFor(life);
    final all = controller.journeys();
    final regions = <String, List<Journey>>{};
    for (final j in all) {
      (regions[j.region.nameIn(life.year)] ??= []).add(j);
    }
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          'Make a journey',
          style: look == null
              ? NF.sora(20, weight: FontWeight.w700)
              : legendHand(look, 28),
        ),
        const SizedBox(height: 4),
        Text(
          'From ${life.city}, in ${life.year}. Your purse: '
          '${moneyIn(life.money, life.country)}.',
          style: NF.sora(14, color: NF.soft),
        ),
        const SizedBox(height: 14),
        if (all.isEmpty)
          Text(
            'You have already travelled this year. Press Age +1 first.',
            style: NF.sora(14, color: NF.muted),
          ),
        for (final e in regions.entries) ...[
          SectionLabel(e.key),
          const SizedBox(height: 6),
          for (final j in e.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NFCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Icon(_icon(j.by), color: NF.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            j.to,
                            style: NF.sora(16, weight: FontWeight.w700),
                          ),
                          Text(
                            '${_by(j.by)} · ${j.days == 1 ? '1 day' : '${j.days} days'} · '
                            '${moneyIn(j.cost, life.country)} · ${_risk(j.risk)}',
                            style: NF.sora(13, color: NF.muted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: life.money >= j.cost ? () => onGo(j) : null,
                      child: Text(life.money >= j.cost ? 'Go' : 'Too poor'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
