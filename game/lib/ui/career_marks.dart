import 'package:flutter/material.dart';

import '../engine/career_hub.dart';
import '../engine/models.dart';
import '../theme.dart';

// Small marks of a special career's look outside its Hub
// (docs/phase-2/03, 6.3 and 6.4): the stamp on a career result, in the
// look's own type, and the signature meter as a chip in the header.

/// Each look's stamps: (went well, mixed, went badly).
const _stamps = <String, (String, String, String)>{
  'actor': ("THAT'S A WRAP", 'TAKE TWO', 'CUT'),
  'musician': ('ENCORE', 'ONE MORE TAKE', 'OFF KEY'),
  'athlete': ('MATCH WON', 'FULL TIME', 'BENCHED'),
  'model': ('BOOKED', 'CALLBACK', 'PASSED OVER'),
  'politician': ('PASSED', 'AMENDED', 'DEFEATED'),
  'military': ('MISSION COMPLETE', 'AT EASE', 'STAND DOWN'),
  'lawyer': ('SUSTAINED', 'ADJOURNED', 'OVERRULED'),
  'doctor': ('STABLE', 'UNDER OBSERVATION', 'CODE BLUE'),
  'pilot': ('LANDED', 'HOLDING', 'DIVERTED'),
  'vet': ('ALL WELL', 'CHECK BACK', 'CALLED OUT'),
  'hustler': ('SOLD', 'SLOW DAY', 'MOVED ON'),
  'police': ('CASE CLOSED', 'ON FILE', 'NO FURTHER ACTION'),
  'astronaut': ('MISSION SUCCESS', 'HOLD', 'SCRUBBED'),
  'fighter': ('WINNER', 'SPLIT DECISION', 'DEFEATED'),
};

/// The stamp on a career result in [look] (a careerLooks id), from the
/// result's tone ('good', 'mixed', 'bad' or 'neutral') and its text.
String? careerStamp(String? look, String tone, String text) {
  final s = _stamps[look];
  if (s == null) return null;
  final t = text.toLowerCase();
  // A few results have a stamp of their own.
  if (look == 'athlete' && t.contains('injur')) return 'INJURED';
  if (look == 'musician' && t.contains('sold out')) return 'SOLD OUT';
  if (look == 'actor' && (t.contains('award') && tone == 'good')) {
    return 'AND THE WINNER IS';
  }
  if (look == 'lawyer' && t.contains('not guilty')) return 'NOT GUILTY';
  if (look == 'model' && t.contains('cover')) return 'ON THE COVER';
  if (look == 'military' && t.contains('medal')) return 'MEDAL';
  if (look == 'fighter' && t.contains('champion')) return 'NEW CHAMPION';
  if (look == 'fighter' && tone == 'good' && t.contains('ended it')) {
    return 'KO!';
  }
  if (look == 'astronaut' && t.contains('dock')) {
    return tone == 'bad' ? 'ABORT' : 'DOCKED';
  }
  return switch (tone) {
    'good' => s.$1,
    'bad' => s.$3,
    _ => s.$2,
  };
}

/// The look's type for its stamps (existing fonts only).
TextStyle careerType(String look, double size, Color color) => switch (look) {
  'actor' || 'politician' || 'lawyer' => TextStyle(
    fontFamily: 'Playfair',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 1.2,
  ),
  'model' => TextStyle(
    fontFamily: 'Playfair',
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 1.2,
  ),
  'athlete' || 'military' || 'police' => NF.stencil(size, color: color),
  'vet' || 'hustler' => NF.chalk(size + 3, color: color),
  _ => NF.sora(size, weight: FontWeight.w800, color: color),
};

/// A career result's stamp, tilted like a rubber stamp, in the look's
/// colours and type.
class CareerStamp extends StatelessWidget {
  const CareerStamp(this.look, this.label, {super.key, required this.tone});
  final String look, label;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final p = careerLooks[look]?.palette;
    final color = tone == 'bad'
        ? NF.danger
        : tone == 'good'
        ? (p?.blue ?? NF.blue)
        : (p?.soft ?? NF.soft);
    return Semantics(
      label: 'Stamped: $label',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: -0.06,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 3, 8, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: careerType(look, 12, color),
          ),
        ),
      ),
    );
  }
}

/// The signature meter as a chip for the header, while you work in a
/// career with a Hub. Null when there is none.
Widget? hubMeterChip(Life l, {VoidCallback? onTap}) {
  final spec = hubFor(l);
  final look = careerLooks[l.careerId];
  if (spec == null || look == null) return null;
  final m = hubMeter(l);
  // The look's accent while the game wears it; Night Feed's otherwise.
  final accent = NF.career == l.careerId ? NF.blue : look.palette.blue;
  final style = NF.sora(13, weight: FontWeight.w700, color: accent);
  return LayoutBuilder(
    builder: (context, box) {
      final scaler = MediaQuery.textScalerOf(context);
      double w(String text) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final v = tp.width;
        tp.dispose();
        return v;
      }

      // Padding, border, icon and gap, then the number.
      final base = 10 * 2 + 2 + scaler.scale(14) + 5 + w(' $m') + 1;
      // The whole name fits: "Approval 50". Else just the icon and the
      // number (the screen reader still hears the name). With too little
      // room even for that (a huge fortune squeezing the name), the meter
      // stays on the Hub card rather than overflow.
      if (box.maxWidth >= base + w(spec.meter) + 6) {
        return _chip(spec.meter, m, look.icon, style, accent, onTap);
      }
      if (box.maxWidth >= base) {
        return _chip(
          spec.meter,
          m,
          look.icon,
          style,
          accent,
          onTap,
          label: false,
        );
      }
      return const SizedBox.shrink();
    },
  );
}

Widget _chip(
  String meter,
  int m,
  IconData icon,
  TextStyle style,
  Color accent,
  VoidCallback? onTap, {
  bool label = true,
}) => Semantics(
  label: '$meter $m of 100. Open your career',
  button: true,
  excludeSemantics: true,
  child: GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          if (label) Text(meter, maxLines: 1, style: style),
          Text(' $m', style: style),
        ],
      ),
    ),
  ),
);
