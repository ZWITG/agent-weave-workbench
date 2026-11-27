import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'legend_look.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// Shared pieces of the era screens (Phase 2C: Health, The law, Prison,
/// Faith and the news): a page with a small kicker and a big title, cards
/// of tappable rows and the heat or standing meter. They wear the Legend's
/// look in a Legend life (Caveat titles and ink frames for Leonardo) and
/// the normal look in an ordinary era life.

/// The title face: the Legend's hand, or bold Sora.
TextStyle eraHand(Life life, double size) {
  final look = legendLookFor(life);
  return look == null
      ? NF.sora(size - 6, weight: FontWeight.w700, color: NF.orange)
      : legendHand(look, size);
}

/// "HEALTH · FLORENCE 1478".
Widget eraKicker(String text) => Text(
  text.toUpperCase(),
  style: NF.sora(
    11.5,
    color: NF.blue,
    weight: FontWeight.w700,
  ).copyWith(letterSpacing: 2.4),
);

/// A full page of an era life: back arrow, kicker, title, a line under it,
/// then cards.
class EraPage extends StatelessWidget {
  const EraPage({
    super.key,
    required this.life,
    required this.kicker,
    required this.title,
    this.sub,
    required this.children,
    this.top,
  });
  final Life life;
  final String kicker;
  final String title;
  final String? sub;
  final Widget? top;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NF.bg,
    appBar: AppBar(
      backgroundColor: NF.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: EraBody(
            life: life,
            kicker: kicker,
            title: title,
            sub: sub,
            top: top,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// The scrolling body of an era page or tab.
class EraBody extends StatelessWidget {
  const EraBody({
    super.key,
    required this.life,
    required this.kicker,
    required this.title,
    this.sub,
    this.top,
    required this.children,
  });
  final Life life;
  final String kicker;
  final String title;
  final String? sub;
  final Widget? top;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
    children: [
      eraKicker(kicker),
      const SizedBox(height: 4),
      Text(title, style: eraHand(life, 38)),
      if (sub != null) ...[
        const SizedBox(height: 6),
        Text(sub!, style: NF.sora(15, color: NF.soft, height: 1.4)),
      ],
      if (top != null) ...[const SizedBox(height: 12), top!],
      for (final c in children) ...[const SizedBox(height: 12), c],
    ],
  );
}

/// A card with a hand-lettered heading.
class EraCard extends StatelessWidget {
  const EraCard({
    super.key,
    required this.life,
    required this.title,
    this.note,
    required this.children,
  });
  final Life life;
  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => NFCard(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: eraHand(life, 25)),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note!, style: NF.sora(13.5, color: NF.muted, height: 1.4)),
        ],
        const SizedBox(height: 4),
        ...children,
      ],
    ),
  );
}

/// One row: a title, a line under it and a pill on the right. Tappable
/// when [onTap] is set; [lock] shows why not, in italics.
class EraRow extends StatelessWidget {
  const EraRow({
    super.key,
    required this.title,
    required this.sub,
    this.pill,
    this.filled = false,
    this.lock,
    this.onTap,
    this.first = false,
  });
  final String title;
  final String sub;
  final String? pill;
  final bool filled;
  final String? lock;
  final VoidCallback? onTap;
  final bool first;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: lock != null ? 0.62 : 1,
    child: InkWell(
      onTap: lock == null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: first
              ? null
              : Border(top: BorderSide(color: NF.text.withValues(alpha: 0.16))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: NF.sora(15.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    lock ?? sub,
                    style: lock != null
                        ? NF
                              .sora(12.5, color: NF.orange)
                              .copyWith(fontStyle: FontStyle.italic)
                        : NF.sora(12.5, color: NF.muted, height: 1.3),
                  ),
                ],
              ),
            ),
            if (pill != null) ...[
              const SizedBox(width: 10),
              EraPill(pill!, filled: filled),
            ],
          ],
        ),
      ),
    ),
  );
}

class EraPill extends StatelessWidget {
  const EraPill(this.text, {super.key, this.filled = false});
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: filled ? NF.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: NF.blue, width: 1.3),
    ),
    child: Text(
      text,
      style: NF.sora(12, color: filled ? NF.surface : NF.blue),
    ),
  );
}

/// Five segments: heat on your name, or standing with neighbours.
class EraMeter extends StatelessWidget {
  const EraMeter({super.key, required this.value, this.of = 5});
  final int value;
  final int of;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < of; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: i < value ? NF.orange : NF.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: NF.text, width: 1.2),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Runs an era action and shows what happened.
Future<void> eraRun(
  BuildContext context,
  GameController c,
  String title,
  String Function(Life, EraRules, Random) act, {
  IconData icon = Icons.auto_awesome_rounded,
}) async {
  final nav = Navigator.of(context);
  final r = c.eraLifeAct(act);
  await showResultPopup(nav.context, r, title: title, icon: icon);
  // A hearing waits on the Life tab: go there.
  if (c.pendingEvent != null && nav.mounted) {
    nav.popUntil((route) => route.isFirst);
  }
}

String eraCap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
