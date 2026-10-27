import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../sound.dart';
import '../theme.dart';
import 'outcome_card.dart';
import 'widgets.dart';

/// "Health +4", "Money −$400", "Salary +$2,100/year", "Bond with Ana +3".
final _deltaNote = RegExp(r'^(.+?) ([+−-])(\$?[\d,]+)(.*)$');

/// The result of an activity, interaction or job application, shown as a
/// pop-up card in the middle of the screen (same look as event outcomes).
Future<void> showResultPopup(
  BuildContext context,
  ActionResult r, {
  required String title,
  IconData icon = Icons.auto_awesome_rounded,
}) {
  final chips = <(String, bool, Color)>[];
  final info = <String>[];
  for (final n in r.notes) {
    final m = _deltaNote.firstMatch(n);
    if (m == null) {
      info.add(n);
      continue;
    }
    final label = m.group(1)!;
    final up = m.group(2) == '+';
    final key = label.toLowerCase();
    final color =
        statStyle[key]?.$1 ??
        (label.startsWith('Bond') ? NF.orange : const Color(0xFF5EE6A8));
    chips.add((n, up, color));
  }
  final ups = chips.where((c) => c.$2).length;
  final downs = chips.length - ups;
  final setback = info.any((n) => n.startsWith('Why:'));
  final tone = ups > 0 && downs > 0
      ? 'mixed'
      : ups > 0
      ? 'good'
      : downs > 0 || setback
      ? 'bad'
      : 'neutral';
  Sound.instance.outcome(tone);

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: motion(context, const Duration(milliseconds: 260)),
    transitionBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, _) => _ResultCard(
      title: title,
      icon: icon,
      text: r.text,
      tone: tone,
      chips: chips,
      info: info,
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.icon,
    required this.text,
    required this.tone,
    required this.chips,
    required this.info,
  });

  final String title;
  final IconData icon;
  final String text;
  final String tone;
  final List<(String, bool, Color)> chips;
  final List<String> info;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(tone);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          color.withValues(alpha: 0.20),
                          NF.surface,
                        ),
                        NF.surface,
                      ],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: NF.sora(
                                20,
                                weight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(text, style: NF.sora(16, height: 1.5)),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < chips.length; i++)
                              _NoteChip(
                                text: chips[i].$1,
                                up: chips[i].$2,
                                color: chips[i].$3,
                                index: i,
                              ),
                          ],
                        ),
                      ],
                      if (info.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (final n in info)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  n.startsWith('Why:')
                                      ? Icons.help_outline_rounded
                                      : n.startsWith('Tip:')
                                      ? Icons.lightbulb_outline_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 17,
                                  color: NF.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    n,
                                    style: NF.sora(14, color: NF.soft),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: primaryButton(),
                          autofocus: true,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({
    required this.text,
    required this.up,
    required this.color,
    required this.index,
  });
  final String text;
  final bool up;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = up ? color : NF.danger;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, Duration(milliseconds: 350 + index * 140)),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: c,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: NF.sora(13, weight: FontWeight.w700, color: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
