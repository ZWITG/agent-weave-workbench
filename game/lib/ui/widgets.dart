import 'package:flutter/material.dart';

import '../engine/currency.dart';

import '../theme.dart';

/// A labelled 0–100 bar. Screen readers hear "Happiness 78 percent".
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this._color,
  });

  final String label;
  final int value;
  final Color? _color;
  Color get color => _color ?? NF.blue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value percent',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: NF.sora(13, color: NF.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: NF.sora(13, weight: FontWeight.w700),
            ),
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
        decoration: BoxDecoration(
          color: NF.blue,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Text(
          initials,
          style: NF.sora(size * 0.36, weight: FontWeight.w700, color: NF.bg),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this._bg, this._fg});
  final String text;
  final Color? _bg;
  final Color? _fg;
  Color get bg => _bg ?? NF.orange;
  Color get fg => _fg ?? NF.bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: NF.sora(13, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this._color});
  final String text;
  final Color? _color;
  Color get color => _color ?? NF.orange;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: NF
        .sora(12, weight: FontWeight.w700, color: color)
        .copyWith(letterSpacing: 2),
  );
}

class NFCard extends StatelessWidget {
  const NFCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this._color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? _color;
  Color get color => _color ?? NF.surface;

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
  minimumSize: Size(64, 56),
  side: BorderSide(color: NF.borderStrong),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: NF.sora(14, weight: FontWeight.w600),
);

ButtonStyle orangeButton() => FilledButton.styleFrom(
  backgroundColor: NF.orange,
  foregroundColor: NF.bg,
  disabledBackgroundColor: NF.surface2,
  disabledForegroundColor: NF.muted,
  minimumSize: Size(104, 52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: NF.sora(16, weight: FontWeight.w700),
);

// ---------------- Richer visuals (Night Feed v2) ----------------

/// Per-stat accent colours (distinct in lightness as well as hue) and icons.
final statStyle = <String, (Color, IconData)>{
  // Prison values, shown instead of Smarts and Looks while inside.
  'behaviour': (const Color(0xFF9FE0C1), Icons.verified_user_rounded),
  'respect': (const Color(0xFFE3A06B), Icons.front_hand_rounded),
  'happiness': (Color(0xFFFFD166), Icons.sentiment_satisfied_alt_rounded),
  'health': (Color(0xFF5EE6A8), Icons.favorite_rounded),
  'smarts': (NF.blue, Icons.psychology_rounded),
  'looks': (Color(0xFFFF8FC7), Icons.auto_awesome_rounded),
};

/// Soft coloured glows behind the whole screen.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: NF.bg)),
        Positioned(
          top: -140,
          left: -120,
          child: _glow(
            NF.prison ? const Color(0xFF4D7A69) : const Color(0xFF7C9CFF),
            360,
            0.22,
          ),
        ),
        Positioned(
          top: 220,
          right: -160,
          child: _glow(
            NF.prison ? const Color(0xFFE3CF7A) : const Color(0xFFFFB86B),
            320,
            NF.prison ? 0.06 : 0.13,
          ),
        ),
        Positioned(
          bottom: -160,
          left: 40,
          child: _glow(
            NF.prison ? const Color(0xFF2C433B) : const Color(0xFFB57CFF),
            340,
            0.12,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _glow(Color c, double size, double alpha) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            c.withValues(alpha: alpha),
            c.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

/// Stat tile: icon, label, animated value and a gradient bar.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.statKey,
    required this.value,
    this.trend = 0,
    this.onTap,
  });
  final String statKey;
  final int value;

  /// Change since the start of the year (trend arrow).
  final int trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = statStyle[statKey]!;
    final label = statKey[0].toUpperCase() + statKey.substring(1);
    return Semantics(
      label:
          '$label $value percent${trend == 0 ? '' : ', ${trend > 0 ? 'up' : 'down'} ${trend.abs()} this year'}. Tap for why',
      button: onTap != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: NF.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.toDouble()),
            duration: motion(context, const Duration(milliseconds: 600)),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 17, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(label, style: NF.sora(12, color: NF.muted)),
                      ),
                    ),
                    if (trend != 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(
                          trend > 0
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: 22,
                          color: trend > 0
                              ? const Color(0xFF5EE6A8)
                              : NF.danger,
                        ),
                      ),
                    Text(
                      '${v.round()}',
                      style: NF.sora(17, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Container(height: 7, color: NF.surface2),
                      FractionallySizedBox(
                        widthFactor: (v / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.65), color],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with a ring that fills as the life progresses.
class AgeRingAvatar extends StatelessWidget {
  const AgeRingAvatar({
    super.key,
    required this.initials,
    required this.progress,
    this.size = 60,
  });
  final String initials;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress.clamp(0, 1)),
                duration: motion(context, const Duration(milliseconds: 700)),
                builder: (_, p, _) => CircularProgressIndicator(
                  value: p,
                  strokeWidth: 3.5,
                  backgroundColor: NF.surface2,
                  valueColor: AlwaysStoppedAnimation(NF.orange),
                ),
              ),
            ),
            Container(
              width: size - 12,
              height: size - 12,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // In prison the avatar takes the yard's green.
                  colors: NF.prison
                      ? const [Color(0xFF5C8A78), Color(0xFF3E6B5B)]
                      : const [Color(0xFF9DB4FF), Color(0xFF6A7FE8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: NF.blue.withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                initials,
                style: NF.sora(
                  size * 0.3,
                  weight: FontWeight.w700,
                  color: NF.bg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData categoryIcon(String category) => switch (category) {
  'family' => Icons.home_rounded,
  'school' => Icons.school_rounded,
  'friends' => Icons.groups_rounded,
  'love' => Icons.favorite_rounded,
  'work' => Icons.work_rounded,
  'health' => Icons.medical_services_rounded,
  'money' => Icons.savings_rounded,
  'crime' => Icons.gavel_rounded,
  'mind' => Icons.psychology_rounded,
  'identity' => Icons.face_rounded,
  'travel' => Icons.flight_rounded,
  'social' => Icons.celebration_rounded,
  'home' => Icons.cottage_rounded,
  'pets' => Icons.pets_rounded,
  'fame' => Icons.star_rounded,
  'community' => Icons.diversity_3_rounded,
  _ => Icons.auto_awesome_rounded,
};

/// "$12,400", "−$80".
/// An amount in the currency of the country you live in.
String money(int amount) => moneyIn(amount, activeCountry);

/// Animation length that honours Reduce motion (Settings or the OS).
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

/// The look shared by every drop-down list in the game.
InputDecoration dropdownDecoration({String? label}) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: NF.surface2,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
);

/// A labelled drop-down list for picking one option. It follows [value]
/// when the game changes it from elsewhere.
class PickList<T> extends StatelessWidget {
  const PickList({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onPick,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final void Function(T value) onPick;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    key: ValueKey(value),
    initialValue: value,
    isExpanded: true,
    dropdownColor: NF.surface,
    decoration: dropdownDecoration(label: label),
    items: [
      for (final (v, text) in options)
        DropdownMenuItem<T>(
          value: v,
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (v) {
      if (v is T) onPick(v);
    },
  );
}
