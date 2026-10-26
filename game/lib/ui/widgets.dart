import 'package:flutter/material.dart';

import '../theme.dart';

/// A labelled 0–100 bar. Screen readers hear "Happiness 78 percent".
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.label, required this.value, this.color = NF.blue});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value percent',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label, style: NF.sora(13, color: NF.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 10,
                backgroundColor: NF.surface2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('$value', textAlign: TextAlign.right, style: NF.sora(13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, this.size = 56});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: NF.blue, borderRadius: BorderRadius.circular(size * 0.32)),
        child: Text(initials, style: NF.sora(size * 0.36, weight: FontWeight.w700, color: NF.bg)),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.bg = NF.orange, this.fg = NF.bg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: NF.sora(13, weight: FontWeight.w700, color: fg)),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = NF.orange});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: NF.sora(12, weight: FontWeight.w700, color: color).copyWith(letterSpacing: 2),
      );
}

class NFCard extends StatelessWidget {
  const NFCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = NF.surface});
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: NF.border),
        ),
        child: child,
      );
}

ButtonStyle primaryButton() => FilledButton.styleFrom(
      backgroundColor: NF.blue,
      foregroundColor: NF.bg,
      minimumSize: const Size(64, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: NF.sora(14, weight: FontWeight.w700),
    );

ButtonStyle secondaryButton() => OutlinedButton.styleFrom(
      backgroundColor: NF.surface2,
      foregroundColor: NF.text,
      minimumSize: const Size(64, 56),
      side: const BorderSide(color: NF.borderStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: NF.sora(14, weight: FontWeight.w600),
    );

ButtonStyle orangeButton() => FilledButton.styleFrom(
      backgroundColor: NF.orange,
      foregroundColor: NF.bg,
      disabledBackgroundColor: NF.surface2,
      disabledForegroundColor: NF.muted,
      minimumSize: const Size(104, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: NF.sora(16, weight: FontWeight.w700),
    );
