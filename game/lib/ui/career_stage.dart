import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

// The Career Hub's set dressing (docs/phase-2/03, 6.3): each look gets a
// signature instrument that shows its meter in the career's own language,
// and an illustrated scene across the top of its Hub.
//
//   Marquee      a marquee sign whose bulbs light up with your Buzz
//   Backstage    a VU meter, the needle riding your Following
//   Floodlights  a stadium scoreboard
//   Runway       a contact sheet, one frame for every ten points
//   Chamber      a hemicycle of a hundred seats, lit by Approval
//   Field Kit    a stencilled dog tag and a row of ammunition pips
//   Mahogany     the scales of justice, tipped by Reputation
//   Night Shift  a patient monitor with its trace
//   Flight Deck  an altimeter, a hundred hours to the point
//   Meadow       a hillside that fills with sheep
//   Market Day   chalk tally marks on a slate
//   Blue Line    a badge and the light bar
//
// Everything is drawn: no images. [t] (0..1, looping) animates; Reduce
// motion holds it still.

TextStyle _face(String look, double size, Color color) => switch (look) {
  'actor' || 'politician' || 'lawyer' || 'model' => TextStyle(
    fontFamily: 'Playfair',
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: look == 'model' ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: 1,
  ),
  'athlete' || 'military' || 'police' => TextStyle(
    fontFamily: 'StardosStencil',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1,
  ),
  'vet' || 'hustler' => TextStyle(
    fontFamily: 'Caveat',
    fontSize: size * 1.15,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1,
  ),
  _ => TextStyle(
    fontFamily: 'Sora',
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1,
  ),
};

/// Draws [text] centred on [at] (or left-aligned at it).
void _text(
  Canvas c,
  String text,
  TextStyle style,
  Offset at, {
  bool centre = true,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  tp.paint(
    c,
    centre
        ? at - Offset(tp.width / 2, tp.height / 2)
        : at - Offset(0, tp.height / 2),
  );
  tp.dispose();
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// What the instrument says to a screen reader, beyond "Meter 47 of 100".
String instrumentCaption(String look, int v) => switch (look) {
  'actor' => '${(v / 10).round()} of 10 bulbs lit on the marquee',
  'musician' => v >= 80 ? 'The needle is in the red' : 'The needle at $v',
  'model' => '${v ~/ 10} frames on the contact sheet',
  'politician' => '$v of 100 seats with you${v > 50 ? ', a majority' : ''}',
  'lawyer' =>
    v >= 50 ? 'The scales tip your way' : 'The scales tip against you',
  'pilot' => '${v * 100} hours in the logbook',
  'vet' => '${v ~/ 10} sheep on the hill',
  'hustler' => '$v chalk marks',
  _ => '$v of 100',
};

/// The career's meter drawn as its signature instrument.
class HubInstrument extends StatelessWidget {
  const HubInstrument({
    super.key,
    required this.look,
    required this.label,
    required this.value,
    this.t = 0,
    this.extra,
  });

  final String look;
  final String label;
  final int value;
  final double t;

  /// A second figure some instruments show (the pilot's logbook hours).
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final p = careerLooks[look]?.palette ?? nightFeed;
    return Semantics(
      label: '$label $value of 100. ${instrumentCaption(look, value)}',
      excludeSemantics: true,
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: CustomPaint(
          painter: _InstrumentPainter(
            look,
            label,
            value.clamp(0, 100),
            t,
            p,
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25),
          ),
        ),
      ),
    );
  }
}

class _InstrumentPainter extends CustomPainter {
  _InstrumentPainter(this.look, this.label, this.v, this.t, this.p, this.k);
  final String look, label;
  final int v;
  final double t;
  final NFPalette p;

  /// Text scale for the painted labels (capped so they still fit).
  final double k;

  double get f => v / 100;

  @override
  void paint(Canvas c, Size s) {
    switch (look) {
      case 'actor':
        _marquee(c, s);
      case 'musician':
        _vu(c, s);
      case 'athlete':
        _scoreboard(c, s);
      case 'model':
        _contactSheet(c, s);
      case 'politician':
        _hemicycle(c, s);
      case 'military':
        _dogTag(c, s);
      case 'lawyer':
        _scales(c, s);
      case 'doctor':
        _monitor(c, s);
      case 'pilot':
        _altimeter(c, s);
      case 'vet':
        _hillside(c, s);
      case 'hustler':
        _tally(c, s);
      default:
        _badge(c, s);
    }
  }

  // ---- Marquee: a sign ringed with bulbs, lit in proportion to Buzz ----
  void _marquee(Canvas c, Size s) {
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: min(s.width - 8, 300),
      height: s.height - 12,
    );
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(rr, _fill(p.surface2));
    c.drawRRect(rr, _stroke(p.borderStrong, 3));
    // Bulbs around the edge.
    final perim = 2 * (r.width + r.height);
    final n = (perim / 18).floor();
    final lit = (n * f).round();
    for (var i = 0; i < n; i++) {
      var d = i / n * perim;
      Offset at;
      if (d < r.width) {
        at = Offset(r.left + d, r.top);
      } else if ((d -= r.width) < r.height) {
        at = Offset(r.right, r.top + d);
      } else if ((d -= r.height) < r.width) {
        at = Offset(r.right - d, r.bottom);
      } else {
        d -= r.width;
        at = Offset(r.left, r.bottom - d);
      }
      final on = i < lit;
      // A brighter pulse chases round the lit bulbs.
      final chase = on && ((i / max(1, lit) - t) % 1).abs() < 0.08;
      if (on) {
        c.drawCircle(at, chase ? 8 : 6, _fill(p.blue.withValues(alpha: 0.25)));
      }
      c.drawCircle(
        at,
        3.4,
        _fill(on ? (chase ? Colors.white : p.blue) : p.border),
      );
    }
    _text(c, '$v', _face(look, 40 * k, p.text), r.center.translate(0, -6));
    _text(
      c,
      label.toUpperCase(),
      _face(look, 11 * k, p.blue).copyWith(letterSpacing: 3),
      r.center.translate(0, 26 * k),
    );
  }

  // ---- Backstage: a VU meter with a needle and a red zone ----
  void _vu(Canvas c, Size s) {
    final w = min(s.width - 8, 280.0);
    final face = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: w,
      height: s.height - 8,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(face, const Radius.circular(12)),
      _fill(const Color(0xFFF3E9C8)),
    );
    final pivot = Offset(face.center.dx, face.bottom - 10);
    final rad = face.height - 30;
    const a0 = pi * 1.17, a1 = pi * 1.83;
    // Scale: black, then red over 80.
    c.drawArc(
      Rect.fromCircle(center: pivot, radius: rad),
      a0,
      (a1 - a0) * 0.8,
      false,
      _stroke(const Color(0xFF1A1230), 2),
    );
    c.drawArc(
      Rect.fromCircle(center: pivot, radius: rad),
      a0 + (a1 - a0) * 0.8,
      (a1 - a0) * 0.2,
      false,
      _stroke(const Color(0xFFE0245E), 5),
    );
    for (var i = 0; i <= 10; i++) {
      final a = a0 + (a1 - a0) * i / 10;
      final o = pivot + Offset(cos(a), sin(a)) * rad;
      final i2 = pivot + Offset(cos(a), sin(a)) * (rad - (i.isEven ? 10 : 6));
      c.drawLine(
        i2,
        o,
        _stroke(
          i >= 8 ? const Color(0xFFE0245E) : const Color(0xFF1A1230),
          1.6,
        ),
      );
    }
    _text(
      c,
      'VU',
      _face(look, 12, const Color(0xFF1A1230)),
      pivot.translate(0, -rad * 0.42),
    );
    // The needle bounces a little on the beat.
    final jitter = sin(t * pi * 16) * 0.025 * (0.3 + f);
    final a = a0 + (a1 - a0) * (f + jitter).clamp(0.0, 1.02);
    c.drawLine(
      pivot,
      pivot + Offset(cos(a), sin(a)) * (rad + 4),
      _stroke(const Color(0xFF14101F), 2.4),
    );
    c.drawCircle(pivot, 6, _fill(const Color(0xFF14101F)));
    _text(
      c,
      '${label.toUpperCase()} $v',
      _face(look, 11 * k, const Color(0xFF5A3FB0)).copyWith(letterSpacing: 2),
      Offset(face.center.dx, face.top + 14),
    );
  }

  // ---- Floodlights: a stadium scoreboard ----
  void _scoreboard(Canvas c, Size s) {
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: min(s.width - 8, 300),
      height: s.height - 8,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      _fill(const Color(0xFF05070A)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      _stroke(p.border, 2),
    );
    _text(
      c,
      label.toUpperCase(),
      _face(look, 13 * k, p.soft).copyWith(letterSpacing: 3),
      Offset(r.center.dx, r.top + 18),
    );
    // Dot-matrix style number.
    _text(
      c,
      v.toString().padLeft(2, '0'),
      _face(look, 44 * k, p.blue),
      Offset(r.center.dx, r.center.dy + 2),
    );
    // A row of 20 lamps: lime when lit, the last few orange.
    const n = 20;
    final cw = (r.width - 40) / n;
    for (var i = 0; i < n; i++) {
      final on = i < (n * f).round();
      final x = r.left + 20 + i * cw + cw / 2;
      c.drawCircle(
        Offset(x, r.bottom - 16),
        cw * 0.32,
        _fill(on ? (i >= 16 ? p.orange : p.blue) : p.surface2),
      );
    }
  }

  // ---- Runway: a contact sheet, a frame for every ten points ----
  void _contactSheet(Canvas c, Size s) {
    final strip = Rect.fromLTWH(4, 14, s.width - 8, s.height - 40);
    c.drawRect(strip, _fill(const Color(0xFF141414)));
    // Sprocket holes.
    for (var x = strip.left + 6; x < strip.right - 6; x += 12) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, strip.top + 3, 6, 5),
          const Radius.circular(1),
        ),
        _fill(p.bg),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, strip.bottom - 8, 6, 5),
          const Radius.circular(1),
        ),
        _fill(p.bg),
      );
    }
    const frames = 10;
    final fw = (strip.width - 8) / frames;
    final shots = v ~/ 10;
    for (var i = 0; i < frames; i++) {
      final fr = Rect.fromLTWH(
        strip.left + 4 + i * fw + 2,
        strip.top + 12,
        fw - 4,
        strip.height - 24,
      );
      final shot = i < shots;
      c.drawRect(
        fr,
        _fill(shot ? const Color(0xFFEDEDED) : const Color(0xFF262626)),
      );
      if (shot) {
        // A model's silhouette, mid-turn.
        final cx = fr.center.dx + (i.isEven ? -1.5 : 1.5);
        final sil = _fill(const Color(0xFF2A2A2A));
        c.drawCircle(
          Offset(cx, fr.top + fr.height * 0.22),
          fr.width * 0.13,
          sil,
        );
        c.drawPath(
          Path()
            ..moveTo(cx - fr.width * 0.16, fr.top + fr.height * 0.34)
            ..lineTo(cx + fr.width * 0.16, fr.top + fr.height * 0.34)
            ..lineTo(cx + fr.width * 0.24, fr.bottom - 3)
            ..lineTo(cx - fr.width * 0.24, fr.bottom - 3)
            ..close(),
          sil,
        );
      }
      // The newest frame flashes.
      if (shot && i == shots - 1 && (t * 3 % 1) < 0.12) {
        c.drawRect(fr.inflate(2), _fill(Colors.white.withValues(alpha: 0.7)));
      }
    }
    // A grease-pencil circle round the best shot.
    if (shots > 0) {
      final best = Rect.fromLTWH(
        strip.left + 4 + (shots - 1) * fw,
        strip.top + 8,
        fw,
        strip.height - 16,
      );
      c.drawOval(best.inflate(4), _stroke(p.blue, 2));
    }
    _text(
      c,
      '${label.toUpperCase()} · $v',
      _face(look, 13 * k, p.text).copyWith(letterSpacing: 1.5),
      Offset(s.width / 2, s.height - 11),
    );
  }

  // ---- Chamber: a hemicycle of a hundred seats ----
  void _hemicycle(Canvas c, Size s) {
    final centre = Offset(s.width / 2, s.height - 14);
    final rMax = min(s.width / 2 - 8, s.height - 22);
    const rows = 5;
    // Seats per row grow with the radius; 100 in all.
    const perRow = [12, 16, 20, 24, 28];
    final seats = <(Offset, double)>[];
    for (var r = 0; r < rows; r++) {
      final rad = rMax * (0.45 + 0.55 * r / (rows - 1));
      for (var i = 0; i < perRow[r]; i++) {
        final a = pi + pi * (i + 0.5) / perRow[r];
        seats.add((centre + Offset(cos(a), sin(a)) * rad, a));
      }
    }
    // Fill from the left, by angle, like a real chamber.
    seats.sort((a, b) => a.$2.compareTo(b.$2));
    for (var i = 0; i < seats.length; i++) {
      final yours = i < v;
      c.drawCircle(
        seats[i].$1,
        rMax / 32,
        _fill(yours ? p.orange : p.surface2),
      );
    }
    // The majority line.
    c.drawLine(
      centre.translate(0, -rMax * 0.38),
      centre.translate(0, -rMax - 6),
      _stroke(p.blue.withValues(alpha: 0.7), 1.4),
    );
    _text(
      c,
      '$v',
      _face(look, 30 * k, p.text),
      centre.translate(0, -rMax * 0.22),
    );
    _text(
      c,
      v > 50 ? 'MAJORITY' : label.toUpperCase(),
      _face(look, 10 * k, p.blue).copyWith(letterSpacing: 2.5),
      centre.translate(0, 2),
    );
  }

  // ---- Field Kit: a dog tag and a row of pips ----
  void _dogTag(Canvas c, Size s) {
    final tag = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height / 2 - 8),
        width: min(s.width - 20, 220),
        height: 70,
      ),
      const Radius.circular(26),
    );
    // The chain.
    for (var x = 10.0; x < tag.left + 14; x += 8) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, tag.center.dy - 26 + (x / 40)),
          width: 7,
          height: 4,
        ),
        _stroke(p.muted, 1.2),
      );
    }
    c.drawRRect(tag, _fill(const Color(0xFFB9BCA8)));
    c.drawRRect(tag.deflate(4), _stroke(const Color(0xFF8E927C), 1));
    c.drawCircle(Offset(tag.left + 18, tag.center.dy), 5, _fill(p.bg));
    _text(
      c,
      label.toUpperCase(),
      _face(look, 12 * k, const Color(0xFF2B2F22)).copyWith(letterSpacing: 2),
      Offset(tag.center.dx + 8, tag.center.dy - 14),
    );
    _text(
      c,
      '$v / 100',
      _face(look, 26 * k, const Color(0xFF2B2F22)),
      Offset(tag.center.dx + 8, tag.center.dy + 12),
    );
    // Ammunition pips, one per ten.
    final n = 10;
    final gap = min(22.0, (s.width - 40) / n);
    final x0 = s.width / 2 - gap * (n - 1) / 2;
    for (var i = 0; i < n; i++) {
      final on = i < (v / 10).round();
      final at = Offset(x0 + i * gap, s.height - 12);
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: at, width: 7, height: 14),
        const Radius.circular(3),
      );
      c.drawRRect(body, _fill(on ? p.blue : p.surface2));
      if (on) c.drawCircle(at.translate(0, -6), 3, _fill(p.orange));
    }
  }

  // ---- Mahogany: the scales of justice ----
  void _scales(Canvas c, Size s) {
    final brass = p.blue;
    final top = Offset(s.width / 2, 22);
    c.drawLine(top, Offset(s.width / 2, s.height - 22), _stroke(brass, 3));
    c.drawLine(
      Offset(s.width / 2 - 26, s.height - 20),
      Offset(s.width / 2 + 26, s.height - 20),
      _stroke(brass, 5),
    );
    c.drawCircle(top.translate(0, -6), 5, _fill(brass));
    // Reputation tips the beam: high is your side (left) down.
    final tilt = ((50 - v) / 50) * 0.3 + sin(t * pi * 2) * 0.012;
    final arm = min(s.width / 2 - 40, 110.0);
    final l = top + Offset(-cos(tilt) * arm, -sin(tilt) * arm);
    final r = top + Offset(cos(tilt) * arm, sin(tilt) * arm);
    c.drawLine(l, r, _stroke(brass, 3));
    for (final (end, word) in [(l, 'YOU'), (r, 'THEM')]) {
      final pan = end.translate(0, 34);
      c.drawLine(
        end,
        pan.translate(-18, 0),
        _stroke(brass.withValues(alpha: 0.7), 1),
      );
      c.drawLine(
        end,
        pan.translate(18, 0),
        _stroke(brass.withValues(alpha: 0.7), 1),
      );
      c.drawArc(
        Rect.fromCenter(center: pan, width: 40, height: 16),
        0,
        pi,
        true,
        _fill(brass),
      );
      _text(
        c,
        word,
        _face('athlete', 9, p.muted).copyWith(letterSpacing: 1.5),
        pan.translate(0, 18),
      );
    }
    _text(
      c,
      '$v',
      _face(look, 26 * k, p.text),
      Offset(s.width / 2 - 58, s.height - 30),
    );
    _text(
      c,
      label.toUpperCase(),
      _face(look, 10 * k, brass).copyWith(letterSpacing: 2),
      Offset(s.width / 2, s.height - 6),
    );
  }

  // ---- Night Shift: a patient monitor ----
  void _monitor(Canvas c, Size s) {
    final r = Rect.fromLTWH(4, 4, s.width - 8, s.height - 8);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      _fill(const Color(0xFF020B0D)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      _stroke(p.border, 2),
    );
    final traceW = r.width * 0.62;
    final base = r.top + r.height * 0.55;
    // Grid.
    for (var x = r.left + 10; x < r.left + traceW; x += 14) {
      c.drawLine(
        Offset(x, r.top + 10),
        Offset(x, r.bottom - 10),
        _stroke(p.blue.withValues(alpha: 0.06), 1),
      );
    }
    // The trace: beats closer together when trust is high, a sweep that
    // erases ahead of it.
    final period = 70 - 30 * f;
    final path = Path();
    final head = (t * traceW * 2) % traceW;
    var first = true;
    for (var x = 0.0; x <= traceW - 12; x += 1.5) {
      if ((x - head).abs() < 8) {
        first = true;
        continue;
      }
      final u = (x % period) / period;
      final dy = u > 0.40 && u < 0.44
          ? -r.height * 0.32
          : u > 0.44 && u < 0.48
          ? r.height * 0.18
          : u > 0.6 && u < 0.7
          ? -r.height * 0.05 * sin((u - 0.6) / 0.1 * pi)
          : 0.0;
      final pt = Offset(r.left + 10 + x, base + dy);
      if (first) {
        path.moveTo(pt.dx, pt.dy);
        first = false;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    c.drawPath(path, _stroke(p.blue, 2));
    final rx = r.left + traceW + 8;
    _text(
      c,
      label.toUpperCase(),
      _face(look, 9.5 * k, p.muted).copyWith(letterSpacing: 1.5),
      Offset(rx, r.top + 18),
      centre: false,
      maxWidth: r.right - rx - 6,
    );
    _text(
      c,
      '$v',
      _face(look, 40 * k, p.blue),
      Offset(rx, r.center.dy + 4),
      centre: false,
    );
    final blink = (t * 4 % 1) < 0.5;
    c.drawCircle(
      Offset(r.right - 16, r.top + 18),
      4,
      _fill(blink ? p.orange : p.orange.withValues(alpha: 0.2)),
    );
  }

  // ---- Flight Deck: an altimeter ----
  void _altimeter(Canvas c, Size s) {
    final centre = Offset(
      s.width / 2 - (s.width > 300 ? 50 : 30),
      s.height / 2,
    );
    final rad = s.height / 2 - 6;
    c.drawCircle(centre, rad + 4, _fill(const Color(0xFF2A2F37)));
    c.drawCircle(centre, rad, _fill(const Color(0xFF0B0E12)));
    for (var i = 0; i < 50; i++) {
      final a = -pi / 2 + i / 50 * 2 * pi;
      final big = i % 5 == 0;
      c.drawLine(
        centre + Offset(cos(a), sin(a)) * (rad - (big ? 9 : 5)),
        centre + Offset(cos(a), sin(a)) * (rad - 1),
        _stroke(Colors.white.withValues(alpha: big ? 0.9 : 0.5), big ? 1.6 : 1),
      );
      if (big) {
        _text(
          c,
          '${i ~/ 5}',
          _face('doctor', 10, Colors.white),
          centre + Offset(cos(a), sin(a)) * (rad - 18),
        );
      }
    }
    // Long hand: hundreds of hours within the thousand; short hand: thousands.
    final hours = v * 100;
    final long =
        -pi / 2 + (hours % 1000) / 1000 * 2 * pi + sin(t * pi * 2) * 0.01;
    final short = -pi / 2 + (hours / 10000) * 2 * pi;
    c.drawLine(
      centre,
      centre + Offset(cos(short), sin(short)) * rad * 0.5,
      _stroke(Colors.white, 4),
    );
    c.drawLine(
      centre,
      centre + Offset(cos(long), sin(long)) * rad * 0.82,
      _stroke(p.orange, 2.4),
    );
    c.drawCircle(centre, 4, _fill(p.blue));
    final rx = centre.dx + rad + 18;
    _text(
      c,
      label.toUpperCase(),
      _face(look, 10 * k, p.muted).copyWith(letterSpacing: 1.5),
      Offset(rx, centre.dy - 22),
      centre: false,
      maxWidth: s.width - rx - 4,
    );
    _text(
      c,
      _hours(hours),
      _face(look, 24 * k, p.blue),
      Offset(rx, centre.dy + 4),
      centre: false,
      maxWidth: s.width - rx - 4,
    );
    _text(
      c,
      'HRS LOGGED',
      _face(look, 9 * k, p.muted).copyWith(letterSpacing: 2),
      Offset(rx, centre.dy + 26),
      centre: false,
    );
  }

  static String _hours(int h) => h >= 1000
      ? '${h ~/ 1000},${(h % 1000).toString().padLeft(3, '0')}'
      : '$h';

  // ---- Meadow: sheep gather on the hill ----
  void _hillside(Canvas c, Size s) {
    final sky = Rect.fromLTWH(0, 0, s.width, s.height);
    c.drawRRect(
      RRect.fromRectAndRadius(sky, const Radius.circular(14)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surface2, p.surface],
        ).createShader(sky),
    );
    c.drawCircle(
      Offset(s.width - 34, 28),
      14,
      _fill(p.orange.withValues(alpha: 0.85)),
    );
    final hill = Path()
      ..moveTo(0, s.height * 0.62)
      ..quadraticBezierTo(
        s.width * 0.35,
        s.height * 0.32,
        s.width * 0.7,
        s.height * 0.52,
      )
      ..quadraticBezierTo(
        s.width * 0.88,
        s.height * 0.6,
        s.width,
        s.height * 0.5,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(sky, const Radius.circular(14)));
    c.drawPath(hill, _fill(p.blue.withValues(alpha: 0.35)));
    // A hedgerow along the bottom.
    for (var x = 0.0; x < s.width + 20; x += 16) {
      c.drawCircle(
        Offset(x, s.height - 4),
        11,
        _fill(p.blue.withValues(alpha: 0.55)),
      );
    }
    final rnd = Random(3);
    final sheep = v ~/ 10;
    for (var i = 0; i < sheep; i++) {
      final x = 24 + rnd.nextDouble() * (s.width - 60);
      final y = s.height * (0.6 + rnd.nextDouble() * 0.22);
      final bob = sin(t * pi * 2 + i) * 1.2;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + bob), width: 18, height: 12),
        _fill(const Color(0xFFF7F3E8)),
      );
      c.drawCircle(
        Offset(x + 9, y - 1 + bob),
        3.6,
        _fill(const Color(0xFF3A3328)),
      );
    }
    c.restore();
    _text(
      c,
      '${label.toLowerCase()}: $v',
      _face(look, 20 * k, p.text),
      Offset(16, 26),
      centre: false,
    );
  }

  // ---- Market Day: chalk tally marks ----
  void _tally(Canvas c, Size s) {
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, s.width - 8, s.height - 8),
      const Radius.circular(6),
    );
    c.drawRRect(board, _fill(const Color(0xFF1E2620)));
    c.drawRRect(board, _stroke(const Color(0xFF8A6A3A), 5));
    final chalk = Colors.white.withValues(alpha: 0.82);
    _text(c, label, _face(look, 22 * k, chalk), Offset(18, 26), centre: false);
    _text(c, '$v', _face(look, 26 * k, p.blue), Offset(s.width - 34, 26));
    // Groups of five, wobbly like real chalk.
    final rnd = Random(5);
    final groups = (v / 5).ceil();
    const gw = 26.0;
    final perRow = max(1, ((s.width - 36) / gw).floor());
    for (var g = 0; g < groups; g++) {
      final row = g ~/ perRow;
      if (row > 1) break;
      final x = 18 + (g % perRow) * gw;
      final y = 52.0 + row * 34;
      final marks = min(5, v - g * 5);
      for (var m = 0; m < min(4, marks); m++) {
        final mx = x + m * 4.5;
        c.drawLine(
          Offset(mx + rnd.nextDouble(), y),
          Offset(mx + rnd.nextDouble() - 0.5, y + 24),
          _stroke(chalk, 2),
        );
      }
      if (marks == 5) {
        c.drawLine(
          Offset(x - 3, y + 18),
          Offset(x + 18, y + 5),
          _stroke(chalk, 2),
        );
      }
    }
  }

  // ---- Blue Line: a badge and the light bar ----
  void _badge(Canvas c, Size s) {
    final centre = Offset(s.width / 2, s.height / 2 - 6);
    final star = Path();
    for (var i = 0; i < 12; i++) {
      final a = -pi / 2 + i * pi / 6;
      final rad = i.isEven ? 48.0 : 30.0;
      final pt = centre + Offset(cos(a), sin(a)) * rad;
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    c.drawPath(star, _fill(const Color(0xFFC9B26A)));
    c.drawCircle(centre, 22, _fill(p.bg));
    _text(c, '$v', _face(look, 22 * k, p.text), centre);
    final on = (t * 6).floor().isEven;
    final bar = Rect.fromCenter(
      center: Offset(s.width / 2, s.height - 10),
      width: min(s.width - 40, 220),
      height: 10,
    );
    final lit = bar.width * f;
    c.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(5)),
      _fill(p.surface2),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, lit / 2, bar.height),
        const Radius.circular(5),
      ),
      _fill(p.orange.withValues(alpha: on ? 1 : 0.5)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left + lit / 2, bar.top, lit / 2, bar.height),
        const Radius.circular(5),
      ),
      _fill(p.blue.withValues(alpha: on ? 0.5 : 1)),
    );
  }

  @override
  bool shouldRepaint(_InstrumentPainter o) =>
      o.v != v || o.t != t || o.look != look || o.k != k;
}

// ======================= Scenes =======================

/// The illustrated, animated scene across the top of a career's Hub.
/// [beat] is the season (0–3): the Meadow's sun follows it.
class HubScenePainter extends CustomPainter {
  HubScenePainter(this.look, this.t, {this.beat = 0});
  final String look;
  final double t;
  final int beat;

  NFPalette get p => careerLooks[look]?.palette ?? nightFeed;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.save();
    c.clipRect(r);
    switch (look) {
      case 'actor':
        _curtains(c, s);
      case 'musician':
        _stage(c, s);
      case 'athlete':
        _stadium(c, s);
      case 'model':
        _runway(c, s);
      case 'politician':
        _chamber(c, s);
      case 'military':
        _field(c, s);
      case 'lawyer':
        _chambers(c, s);
      case 'doctor':
        _corridor(c, s);
      case 'pilot':
        _cockpit(c, s);
      case 'vet':
        _valley(c, s);
      case 'hustler':
        _market(c, s);
      default:
        _street(c, s);
    }
    c.restore();
  }

  void _sky(Canvas c, Size s, Color top, Color bottom) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(r),
    );
  }

  /// A soft cone of light from [from] towards [to].
  void _beam(Canvas c, Offset from, Offset to, double spread, Color colour) {
    final d = to - from;
    final n = Offset(-d.dy, d.dx) / d.distance * spread;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx + n.dx, to.dy + n.dy)
      ..lineTo(to.dx - n.dx, to.dy - n.dy)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [colour.withValues(alpha: 0.45), colour.withValues(alpha: 0)],
        ).createShader(Rect.fromPoints(from, to)),
    );
  }

  // Marquee: velvet curtains, a scalloped valance and a roaming spotlight.
  void _curtains(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF0D0508), p.bg);
    final spot = Offset(
      s.width * (0.5 + 0.18 * sin(t * pi * 2)),
      s.height * 0.86,
    );
    c.drawOval(
      Rect.fromCenter(center: spot, width: 150, height: 30),
      _fill(p.blue.withValues(alpha: 0.18)),
    );
    _beam(c, Offset(s.width / 2, -10), spot, 70, p.blue);
    // Floorboards.
    for (var i = 0; i < 4; i++) {
      final y = s.height * (0.8 + i * 0.06);
      c.drawLine(
        Offset(0, y),
        Offset(s.width, y),
        _stroke(p.border.withValues(alpha: 0.5), 1),
      );
    }
    // Drapes, gathered towards the sides.
    for (final left in [true, false]) {
      final w = s.width * 0.24;
      for (var i = 0; i < 6; i++) {
        final x0 = left ? i * w / 6 : s.width - (i + 1) * w / 6;
        final fold = Rect.fromLTWH(x0, 0, w / 6 + 1, s.height);
        c.drawRect(
          fold,
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFF5E0F1E),
                const Color(0xFFB0233B),
                const Color(0xFF5E0F1E),
              ],
            ).createShader(fold),
        );
      }
      // The gold tie-back.
      final tie = Offset(left ? w * 0.75 : s.width - w * 0.75, s.height * 0.62);
      c.drawCircle(tie, 5, _fill(p.borderStrong));
      c.drawLine(tie, tie.translate(0, 18), _stroke(p.borderStrong, 2));
    }
    // The valance.
    final val = Path()..moveTo(0, 0);
    for (var x = 0.0; x <= s.width; x += 24) {
      val.lineTo(x, 22);
      val.quadraticBezierTo(x + 12, 34, x + 24, 22);
    }
    val
      ..lineTo(s.width, 0)
      ..close();
    c.drawPath(val, _fill(const Color(0xFF8E1A2E)));
    c.drawLine(
      const Offset(0, 22),
      Offset(s.width, 22),
      _stroke(p.borderStrong, 2),
    );
  }

  // Backstage: a lighting truss, sweeping beams, haze and a crowd.
  void _stage(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF07050F), p.surface);
    c.drawRect(
      Rect.fromLTWH(0, 10, s.width, 6),
      _fill(const Color(0xFF2A2440)),
    );
    final cans = (s.width / 70).floor();
    for (var i = 0; i < cans; i++) {
      final x = 35 + i * 70.0;
      final swing = sin(t * pi * 2 + i * 1.3) * 0.5;
      final colour = i.isEven ? p.orange : p.blue;
      _beam(
        c,
        Offset(x, 18),
        Offset(x + sin(swing) * s.height, s.height),
        26,
        colour,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 18), width: 14, height: 12),
          const Radius.circular(3),
        ),
        _fill(const Color(0xFF15111F)),
      );
      c.drawCircle(Offset(x, 22), 3, _fill(colour));
    }
    // Haze.
    c.drawRect(
      Rect.fromLTWH(0, s.height * 0.5, s.width, s.height * 0.5),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.06),
              ],
            ).createShader(
              Rect.fromLTWH(0, s.height * 0.5, s.width, s.height * 0.5),
            ),
    );
    // The crowd, heads bobbing; a few hands up.
    final rnd = Random(9);
    for (var x = -6.0; x < s.width + 10; x += 15) {
      final bob = sin(t * pi * 8 + x / 13) * 2.5;
      final y = s.height - 10 + rnd.nextDouble() * 6 + bob;
      c.drawCircle(Offset(x, y), 8, _fill(const Color(0xFF05040A)));
      if (rnd.nextInt(5) == 0) {
        c.drawLine(
          Offset(x + 4, y - 4),
          Offset(x + 9, y - 20 + bob),
          _stroke(const Color(0xFF05040A), 3),
        );
      }
    }
  }

  // Floodlights: towers, beams, the stands and a lime-lined pitch.
  void _stadium(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF03060B), p.bg);
    for (final x in [s.width * 0.12, s.width * 0.88]) {
      c.drawLine(
        Offset(x, 24),
        Offset(x, s.height * 0.6),
        _stroke(const Color(0xFF2A3340), 3),
      );
      final head = Rect.fromCenter(
        center: Offset(x, 22),
        width: 34,
        height: 18,
      );
      c.drawRect(head, _fill(const Color(0xFF1C2430)));
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 2; j++) {
          c.drawCircle(
            Offset(head.left + 5 + i * 8, head.top + 5 + j * 8),
            2.6,
            _fill(Colors.white.withValues(alpha: 0.95)),
          );
        }
      }
      _beam(
        c,
        Offset(x, 22),
        Offset(s.width / 2, s.height * 0.95),
        90,
        Colors.white,
      );
    }
    // The stands.
    final stand = Path()
      ..moveTo(0, s.height * 0.62)
      ..lineTo(s.width, s.height * 0.62)
      ..lineTo(s.width, s.height * 0.7)
      ..lineTo(0, s.height * 0.7)
      ..close();
    c.drawPath(stand, _fill(const Color(0xFF111821)));
    final rnd = Random(4);
    for (var x = 4.0; x < s.width; x += 6) {
      if (rnd.nextInt(3) == 0) {
        c.drawCircle(
          Offset(x, s.height * 0.64 + rnd.nextDouble() * 6),
          1.2,
          _fill((rnd.nextBool() ? p.orange : p.text).withValues(alpha: 0.5)),
        );
      }
    }
    // The pitch in perspective.
    final pitch = Path()
      ..moveTo(s.width * 0.2, s.height * 0.7)
      ..lineTo(s.width * 0.8, s.height * 0.7)
      ..lineTo(s.width * 1.1, s.height)
      ..lineTo(-s.width * 0.1, s.height)
      ..close();
    c.drawPath(pitch, _fill(const Color(0xFF0F2A16)));
    c.drawPath(pitch, _stroke(p.blue.withValues(alpha: 0.8), 1.5));
    c.drawLine(
      Offset(s.width / 2, s.height * 0.7),
      Offset(s.width / 2, s.height),
      _stroke(p.blue.withValues(alpha: 0.6), 1.2),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height * 0.86),
        width: 70,
        height: 16,
      ),
      _stroke(p.blue.withValues(alpha: 0.6), 1.2),
    );
    // The ball in flight.
    final u = (t * 2) % 1;
    final ball = Offset(
      s.width * (0.25 + 0.5 * u),
      s.height * (0.84 - sin(u * pi) * 0.4),
    );
    c.drawCircle(ball, 4, _fill(p.orange));
  }

  // Runway: a catwalk to the vanishing point, flashes popping along it.
  void _runway(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF050505), p.bg);
    final vp = Offset(s.width / 2, s.height * 0.28);
    final walk = Path()
      ..moveTo(vp.dx - 8, vp.dy)
      ..lineTo(vp.dx + 8, vp.dy)
      ..lineTo(s.width * 0.68, s.height)
      ..lineTo(s.width * 0.32, s.height)
      ..close();
    c.drawPath(
      walk,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF2A2A2E), const Color(0xFFEDEDF0)],
        ).createShader(Rect.fromLTWH(0, vp.dy, s.width, s.height - vp.dy)),
    );
    // Rows of audience either side, and flashes.
    final rnd = Random(12);
    for (var row = 0; row < 7; row++) {
      final y = vp.dy + (s.height - vp.dy) * (row + 1) / 8;
      final spread = (y - vp.dy) / (s.height - vp.dy);
      for (final side in [-1, 1]) {
        for (var k = 0; k < 4; k++) {
          final x =
              vp.dx +
              side * (16 + spread * s.width * 0.2 + k * (8 + spread * 18));
          c.drawCircle(
            Offset(x, y),
            1.5 + spread * 2.5,
            _fill(const Color(0xFF3A3A40)),
          );
          final phase = (t * 2 + rnd.nextDouble()) % 1;
          if (phase < 0.05) {
            final f = Offset(x, y - 4 - spread * 4);
            c.drawCircle(
              f,
              10 + spread * 8,
              _fill(Colors.white.withValues(alpha: 0.35)),
            );
            c.drawLine(
              f.translate(-9, 0),
              f.translate(9, 0),
              _stroke(Colors.white, 1.2),
            );
            c.drawLine(
              f.translate(0, -9),
              f.translate(0, 9),
              _stroke(Colors.white, 1.2),
            );
          }
        }
      }
    }
    // A pink wash at the end of the runway.
    c.drawCircle(vp, 40, _fill(p.blue.withValues(alpha: 0.18)));
  }

  // Chamber: tall windows, a crimson ribbon and a ballot slip dropping.
  void _chamber(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF070B18), p.bg);
    final n = max(3, (s.width / 90).floor());
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * s.width / n;
      final win = Path()
        ..moveTo(x - 18, s.height * 0.75)
        ..lineTo(x - 18, s.height * 0.3)
        ..arcToPoint(
          Offset(x + 18, s.height * 0.3),
          radius: const Radius.circular(18),
        )
        ..lineTo(x + 18, s.height * 0.75)
        ..close();
      c.drawPath(win, _fill(p.blue.withValues(alpha: 0.16)));
      c.drawPath(win, _stroke(p.borderStrong.withValues(alpha: 0.6), 1.5));
      c.drawLine(
        Offset(x, s.height * 0.2),
        Offset(x, s.height * 0.75),
        _stroke(p.borderStrong.withValues(alpha: 0.4), 1),
      );
    }
    // Benches.
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.8 + i * 0.07);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-10, y, s.width + 20, 8),
          const Radius.circular(4),
        ),
        _fill(const Color(0xFF1F5A3A).withValues(alpha: 0.7 - i * 0.15)),
      );
    }
    // The ribbon.
    final rib = Path()
      ..moveTo(0, s.height * 0.12)
      ..quadraticBezierTo(
        s.width * 0.5,
        s.height * (0.3 + 0.03 * sin(t * pi * 2)),
        s.width,
        s.height * 0.1,
      )
      ..lineTo(s.width, s.height * 0.16)
      ..quadraticBezierTo(
        s.width * 0.5,
        s.height * (0.36 + 0.03 * sin(t * pi * 2)),
        0,
        s.height * 0.18,
      )
      ..close();
    c.drawPath(rib, _fill(p.orange.withValues(alpha: 0.85)));
    // The ballot box with a slip going in.
    final box = Rect.fromCenter(
      center: Offset(s.width * 0.85, s.height * 0.72),
      width: 46,
      height: 34,
    );
    c.drawRect(box, _fill(const Color(0xFF15203A)));
    c.drawRect(box, _stroke(p.borderStrong, 1.5));
    c.drawLine(
      box.topCenter.translate(-10, 4),
      box.topCenter.translate(10, 4),
      _stroke(p.bg, 3),
    );
    final drop = (t * 1.5) % 1;
    if (drop < 0.7) {
      final y = box.top - 30 + drop / 0.7 * 30;
      c.drawRect(
        Rect.fromCenter(
          center: Offset(box.center.dx, y),
          width: 14,
          height: 18,
        ),
        _fill(const Color(0xFFF5EFE0)),
      );
    }
  }

  // Field Kit: contour lines of a training area and a radar sweep.
  void _field(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF0E110A), p.bg);
    final rnd = Random(21);
    for (var i = 0; i < 14; i++) {
      final centre = Offset(
        rnd.nextDouble() * s.width,
        rnd.nextDouble() * s.height,
      );
      c.drawOval(
        Rect.fromCenter(
          center: centre,
          width: 40 + rnd.nextDouble() * 80,
          height: 20 + rnd.nextDouble() * 40,
        ),
        _fill(
          (i.isEven ? const Color(0xFF2C3320) : const Color(0xFF3A3F28))
              .withValues(alpha: 0.6),
        ),
      );
    }
    for (var k = 1; k <= 4; k++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.3, s.height * 0.55),
          width: k * 60.0,
          height: k * 26.0,
        ),
        _stroke(p.blue.withValues(alpha: 0.18), 1),
      );
    }
    // Radar.
    final rc = Offset(s.width - 60, s.height / 2 + 6);
    const rr = 44.0;
    c.drawCircle(rc, rr, _fill(const Color(0xFF0B1208)));
    for (var k = 1; k <= 3; k++) {
      c.drawCircle(
        rc,
        rr * k / 3,
        _stroke(const Color(0xFF7FD46A).withValues(alpha: 0.3), 1),
      );
    }
    final a = t * pi * 2;
    c.drawArc(
      Rect.fromCircle(center: rc, radius: rr),
      a - 0.8,
      0.8,
      true,
      _fill(const Color(0xFF7FD46A).withValues(alpha: 0.25)),
    );
    c.drawLine(
      rc,
      rc + Offset(cos(a), sin(a)) * rr,
      _stroke(const Color(0xFF7FD46A), 1.5),
    );
    final blip = rc + Offset(cos(2.2), sin(2.2)) * rr * 0.6;
    final lit = ((a - 2.2) % (2 * pi)) < 1.2;
    c.drawCircle(blip, 3, _fill(p.orange.withValues(alpha: lit ? 1 : 0.2)));
    // A stencilled grid reference.
    _text(
      c,
      'GRID 0417 · 2260',
      _face('military', 11, p.muted.withValues(alpha: 0.7)),
      const Offset(16, 18),
      centre: false,
    );
  }

  // Mahogany: panelling, law books and a green banker's lamp.
  void _chambers(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF1E120C), p.bg);
    final pw = s.width / max(3, (s.width / 80).floor());
    for (var x = 0.0; x < s.width; x += pw) {
      final panel = Rect.fromLTWH(x + 6, 10, pw - 12, s.height * 0.5);
      c.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(3)),
        _fill(const Color(0xFF2E1C13)),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(panel.deflate(5), const Radius.circular(2)),
        _stroke(p.borderStrong.withValues(alpha: 0.35), 1),
      );
      for (var g = 0; g < 4; g++) {
        final gp = Path()..moveTo(panel.left + 8, panel.top + 12 + g * 14);
        for (var gx = panel.left + 8; gx < panel.right - 8; gx += 6) {
          gp.lineTo(gx, panel.top + 12 + g * 14 + sin(gx / 9 + g) * 1.5);
        }
        c.drawPath(gp, _stroke(const Color(0xFF4A2E1F), 1));
      }
    }
    // A shelf of law books.
    final shelfY = s.height * 0.78;
    c.drawRect(
      Rect.fromLTWH(0, shelfY, s.width, 5),
      _fill(const Color(0xFF3C2518)),
    );
    final rnd = Random(8);
    const spines = [
      Color(0xFF6E1B1B),
      Color(0xFF1B3D2A),
      Color(0xFF1F2A4A),
      Color(0xFF5A4520),
    ];
    for (var x = 4.0; x < s.width * 0.62;) {
      final w = 8 + rnd.nextDouble() * 6;
      final h = 26 + rnd.nextDouble() * 10;
      c.drawRect(
        Rect.fromLTWH(x, shelfY - h, w, h),
        _fill(spines[rnd.nextInt(4)]),
      );
      c.drawLine(
        Offset(x + 1, shelfY - h + 6),
        Offset(x + w - 1, shelfY - h + 6),
        _stroke(p.borderStrong.withValues(alpha: 0.7), 1),
      );
      x += w + 1.5;
    }
    // The banker's lamp, glowing.
    final lamp = Offset(s.width * 0.8, shelfY - 30);
    c.drawCircle(
      lamp.translate(0, 18),
      60 + 4 * sin(t * pi * 2),
      _fill(const Color(0xFFFFD27A).withValues(alpha: 0.08)),
    );
    c.drawLine(
      lamp.translate(0, 6),
      Offset(lamp.dx, shelfY),
      _stroke(p.blue, 2.5),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(lamp.dx, shelfY), width: 30, height: 6),
      _fill(p.blue),
    );
    final shade = Path()
      ..moveTo(lamp.dx - 26, lamp.dy + 8)
      ..quadraticBezierTo(lamp.dx, lamp.dy - 16, lamp.dx + 26, lamp.dy + 8)
      ..close();
    c.drawPath(shade, _fill(const Color(0xFF1E7A4E)));
    c.drawLine(
      Offset(lamp.dx - 22, lamp.dy + 9),
      Offset(lamp.dx + 22, lamp.dy + 9),
      _stroke(const Color(0xFFFFE6A8), 2),
    );
    // A gavel resting on its block.
    final g = Offset(s.width * 0.68, shelfY - 4);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: g, width: 22, height: 6),
        const Radius.circular(2),
      ),
      _fill(const Color(0xFF5A3420)),
    );
    c.drawLine(
      g.translate(-2, -6),
      g.translate(22, -14),
      _stroke(const Color(0xFF6B3E26), 3),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: g.translate(-4, -8), width: 16, height: 9),
        const Radius.circular(2),
      ),
      _fill(const Color(0xFF7A4A2E)),
    );
  }

  // Night Shift: a hospital corridor at night, lights passing overhead.
  void _corridor(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF041014), p.bg);
    final vp = Offset(s.width / 2, s.height * 0.5);
    for (final x in [0.0, s.width]) {
      c.drawLine(vp, Offset(x, 0), _stroke(p.border, 1));
      c.drawLine(vp, Offset(x, s.height), _stroke(p.border, 1));
    }
    // Ceiling lights rushing towards you.
    for (var i = 0; i < 6; i++) {
      final u = ((i / 6) + t) % 1;
      final d = pow(u, 2.2).toDouble();
      final y = vp.dy - (vp.dy - 4) * d;
      final w = 6 + d * s.width * 0.3;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(vp.dx, y),
            width: w,
            height: 2 + d * 6,
          ),
          const Radius.circular(3),
        ),
        _fill(Colors.white.withValues(alpha: 0.2 + 0.6 * d)),
      );
    }
    // Doors along the walls, with a red light over one.
    for (var i = 1; i <= 3; i++) {
      final d = i / 4;
      final xl = vp.dx - (vp.dx) * d;
      final h = 20 + 60 * d;
      c.drawRect(
        Rect.fromLTWH(xl, vp.dy - h * 0.2, 6 + 10 * d, h),
        _fill(p.surface2),
      );
      c.drawRect(
        Rect.fromLTWH(
          s.width - xl - (6 + 10 * d),
          vp.dy - h * 0.2,
          6 + 10 * d,
          h,
        ),
        _fill(p.surface2),
      );
    }
    final blink = (t * 4 % 1) < 0.5;
    c.drawCircle(
      Offset(s.width * 0.22, vp.dy - 20),
      4,
      _fill(p.orange.withValues(alpha: blink ? 1 : 0.25)),
    );
    // The trace across the bottom.
    final path = Path()..moveTo(0, s.height - 18);
    for (var x = 0.0; x <= s.width; x += 2) {
      final u = ((x + t * s.width) % 140) / 140;
      path.lineTo(
        x,
        s.height -
            18 +
            (u > 0.42 && u < 0.46
                ? -22
                : u > 0.46 && u < 0.5
                ? 12
                : 0),
      );
    }
    c.drawPath(path, _stroke(p.blue, 2));
  }

  // Flight Deck: the view through the windscreen.
  void _cockpit(Canvas c, Size s) {
    final tilt = sin(t * pi * 2) * 0.08;
    c.save();
    c.translate(s.width / 2, s.height * 0.55);
    c.rotate(tilt);
    c.drawRect(
      Rect.fromLTWH(-s.width, -s.height * 1.5, s.width * 2, s.height * 1.5),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1A33), Color(0xFF3B5E8C)],
            ).createShader(
              Rect.fromLTWH(
                -s.width,
                -s.height * 1.5,
                s.width * 2,
                s.height * 1.5,
              ),
            ),
    );
    c.drawRect(
      Rect.fromLTWH(-s.width, 0, s.width * 2, s.height),
      _fill(const Color(0xFF1A2230)),
    );
    c.drawLine(
      Offset(-s.width, 0),
      Offset(s.width, 0),
      _stroke(p.orange.withValues(alpha: 0.6), 1.5),
    );
    // Clouds drifting past.
    for (var i = 0; i < 5; i++) {
      final x = ((i * 0.27 + t) % 1) * s.width * 1.6 - s.width * 0.8;
      final y = -20.0 - (i % 3) * 18;
      for (var k = 0; k < 3; k++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x + k * 14, y - (k == 1 ? 5 : 0)),
            width: 30,
            height: 14,
          ),
          _fill(Colors.white.withValues(alpha: 0.18)),
        );
      }
    }
    c.restore();
    // The window frame and struts.
    final frame = _fill(const Color(0xFF0A0D12));
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 10), frame);
    c.drawPath(
      Path()
        ..moveTo(s.width / 2 - 6, 0)
        ..lineTo(s.width / 2 + 6, 0)
        ..lineTo(s.width / 2 + 10, s.height)
        ..lineTo(s.width / 2 - 10, s.height)
        ..close(),
      frame,
    );
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(30, 0)
        ..lineTo(10, s.height)
        ..lineTo(0, s.height)
        ..close(),
      frame,
    );
    c.drawPath(
      Path()
        ..moveTo(s.width, 0)
        ..lineTo(s.width - 30, 0)
        ..lineTo(s.width - 10, s.height)
        ..lineTo(s.width, s.height)
        ..close(),
      frame,
    );
    // The glareshield with a few glowing readouts.
    c.drawRect(
      Rect.fromLTWH(0, s.height - 22, s.width, 22),
      _fill(const Color(0xFF14181F)),
    );
    for (var i = 0; i < 5; i++) {
      final x = s.width * (0.15 + i * 0.17);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, s.height - 11),
            width: 30,
            height: 9,
          ),
          const Radius.circular(2),
        ),
        _fill((i == 2 ? p.orange : p.blue).withValues(alpha: 0.55)),
      );
    }
  }

  // Meadow: rolling hills, a hedgerow, a gate and the sun of the season.
  void _valley(Canvas c, Size s) {
    final dusk = beat == 3;
    _sky(
      c,
      s,
      dusk ? const Color(0xFF1B1A2E) : const Color(0xFF2A3A2A),
      p.surface2,
    );
    // The sun crosses the sky with the seasons.
    final sx = s.width * (0.15 + 0.23 * beat + 0.04 * sin(t * pi * 2));
    c.drawCircle(
      Offset(sx, s.height * 0.28),
      26,
      _fill(p.orange.withValues(alpha: 0.15)),
    );
    c.drawCircle(
      Offset(sx, s.height * 0.28),
      13,
      _fill(p.orange.withValues(alpha: dusk ? 0.55 : 0.9)),
    );
    for (var layer = 0; layer < 3; layer++) {
      final y = s.height * (0.5 + layer * 0.14);
      final hill = Path()..moveTo(0, s.height);
      for (var x = 0.0; x <= s.width; x += 8) {
        hill.lineTo(
          x,
          y + sin(x / (60 + layer * 30) + layer * 2) * (14 - layer * 3),
        );
      }
      hill
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(
        hill,
        _fill(
          Color.lerp(
            const Color(0xFF3E5A2E),
            const Color(0xFF6E8F3C),
            layer / 2,
          )!.withValues(alpha: 0.9),
        ),
      );
    }
    // A hedgerow and a five-bar gate.
    for (var x = 0.0; x < s.width + 20; x += 14) {
      c.drawCircle(Offset(x, s.height - 6), 10, _fill(const Color(0xFF2C4A22)));
    }
    final gx = s.width * 0.7;
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(gx, s.height - 30 + i * 5),
        Offset(gx + 42, s.height - 30 + i * 5),
        _stroke(const Color(0xFFCDB58A), 1.6),
      );
    }
    c.drawLine(
      Offset(gx, s.height - 30),
      Offset(gx + 42, s.height - 10),
      _stroke(const Color(0xFFCDB58A), 1.6),
    );
    // A few sheep, grazing.
    for (final (x, y) in [(0.22, 0.74), (0.35, 0.8), (0.52, 0.72)]) {
      final at = Offset(
        s.width * x + sin(t * pi * 2 + x * 9) * 2,
        s.height * y,
      );
      c.drawOval(
        Rect.fromCenter(center: at, width: 16, height: 10),
        _fill(const Color(0xFFF4F0E4)),
      );
      c.drawCircle(at.translate(8, 1), 3, _fill(const Color(0xFF3A3328)));
    }
  }

  // Market Day: striped awnings, bunting and a chalk board.
  void _market(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF221B12), p.bg);
    // Bunting, swaying.
    final sway = sin(t * pi * 2) * 4;
    final string = Path()..moveTo(0, 14);
    string.quadraticBezierTo(s.width / 2, 34 + sway, s.width, 14);
    c.drawPath(string, _stroke(p.soft.withValues(alpha: 0.5), 1));
    const flags = [
      Color(0xFFFF6B4A),
      Color(0xFFFFD45E),
      Color(0xFF5EC8FF),
      Color(0xFF8BE07A),
    ];
    for (var i = 0; i < (s.width / 22).floor(); i++) {
      final x = 11 + i * 22.0;
      final u = x / s.width;
      final y = 14 + 4 * u * (1 - u) * (20 + sway);
      c.drawPath(
        Path()
          ..moveTo(x - 7, y)
          ..lineTo(x + 7, y)
          ..lineTo(x, y + 14)
          ..close(),
        _fill(flags[i % 4]),
      );
    }
    // Three stalls with scalloped, striped awnings.
    final n = max(2, (s.width / 130).floor());
    for (var i = 0; i < n; i++) {
      final sw = s.width / n;
      final x0 = i * sw + 10;
      final w = sw - 20;
      final top = s.height * 0.42;
      for (var k = 0; k < 6; k++) {
        c.drawRect(
          Rect.fromLTWH(x0 + k * w / 6, top, w / 6 + 0.5, 22),
          _fill(
            k.isEven
                ? (i.isEven ? const Color(0xFFE2543A) : const Color(0xFF2E8A6E))
                : const Color(0xFFF2E6CC),
          ),
        );
      }
      for (var k = 0; k < 6; k++) {
        c.drawArc(
          Rect.fromLTWH(x0 + k * w / 6, top + 14, w / 6, 16),
          0,
          pi,
          true,
          _fill(
            k.isEven
                ? (i.isEven ? const Color(0xFFE2543A) : const Color(0xFF2E8A6E))
                : const Color(0xFFF2E6CC),
          ),
        );
      }
      c.drawRect(
        Rect.fromLTWH(x0, top + 30, w, s.height - top - 30),
        _fill(const Color(0xFF2C2218)),
      );
      // Produce on the counter.
      final rnd = Random(i + 2);
      for (var k = 0; k < 7; k++) {
        c.drawCircle(
          Offset(
            x0 + 10 + k * (w - 20) / 6,
            s.height - 18 - rnd.nextDouble() * 4,
          ),
          5,
          _fill(flags[rnd.nextInt(4)].withValues(alpha: 0.85)),
        );
      }
    }
    // A chalk price board.
    final board = Rect.fromLTWH(s.width - 70, s.height - 54, 56, 40);
    c.drawRect(board, _fill(const Color(0xFF1E2620)));
    c.drawRect(board, _stroke(const Color(0xFF8A6A3A), 3));
    _text(
      c,
      'FRESH',
      _face('hustler', 11, Colors.white.withValues(alpha: 0.85)),
      board.center,
    );
  }

  // Blue Line: a city at night, tape across it, the light bar washing it.
  void _street(Canvas c, Size s) {
    final on = (t * 6).floor().isEven;
    _sky(c, s, const Color(0xFF050814), p.bg);
    c.drawRect(
      Offset.zero & s,
      _fill(
        (on ? const Color(0xFFFF3B3B) : const Color(0xFF3B6BFF)).withValues(
          alpha: 0.10,
        ),
      ),
    );
    final rnd = Random(30);
    var x = 0.0;
    while (x < s.width) {
      final w = 24 + rnd.nextDouble() * 34;
      final h = s.height * (0.3 + rnd.nextDouble() * 0.45);
      final b = Rect.fromLTWH(x, s.height - h, w, h);
      c.drawRect(b, _fill(const Color(0xFF0C1122)));
      for (var wy = b.top + 6; wy < b.bottom - 6; wy += 9) {
        for (var wx = b.left + 4; wx < b.right - 4; wx += 7) {
          if (rnd.nextInt(4) == 0) {
            c.drawRect(
              Rect.fromLTWH(wx, wy, 3, 4),
              _fill(const Color(0xFFFFD27A).withValues(alpha: 0.6)),
            );
          }
        }
      }
      x += w + 2;
    }
    // Crime-scene tape, across the skyline above the title.
    c.save();
    c.translate(s.width / 2, s.height * 0.36);
    c.rotate(-0.08);
    final tape = Rect.fromCenter(
      center: Offset.zero,
      width: s.width * 1.3,
      height: 14,
    );
    c.drawRect(tape, _fill(const Color(0xFFF2C230)));
    for (var k = tape.left + 70; k < tape.right; k += 170) {
      _text(
        c,
        'POLICE LINE · DO NOT CROSS',
        _face('police', 9, const Color(0xFF151515)),
        Offset(k, 0),
      );
    }
    c.restore();
    // The light bar itself.
    final bar = Rect.fromCenter(
      center: Offset(s.width / 2, 16),
      width: 120,
      height: 12,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, 60, 12),
        const Radius.circular(6),
      ),
      _fill(const Color(0xFFFF3B3B).withValues(alpha: on ? 1 : 0.25)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left + 60, bar.top, 60, 12),
        const Radius.circular(6),
      ),
      _fill(const Color(0xFF3B6BFF).withValues(alpha: on ? 0.25 : 1)),
    );
  }

  @override
  bool shouldRepaint(HubScenePainter o) =>
      o.t != t || o.look != look || o.beat != beat;
}

// ======================= Words, icons and the ladder =======================

/// Each look's names for the Hub's sections and its log's bullet:
/// (ladder, work, log, bullet).
const hubWords = <String, (String, String, String, String)>{
  'actor': ('Top billing', 'Call sheet', 'Press cuttings', '★'),
  'musician': ('The charts', 'Setlist', 'Tour diary', '♪'),
  'athlete': ('Career path', 'Training plan', 'Match reports', '●'),
  'model': ('The book', 'Bookings', 'Tear sheets', '✦'),
  'politician': ('Offices of state', 'Order paper', 'The record', '§'),
  'military': ('Chain of command', 'Orders', 'Service record', '▸'),
  'lawyer': ('Called to the bar', 'The docket', 'Case law', '§'),
  'doctor': ('Rotation', 'Ward round', 'Patient notes', '+'),
  'pilot': ('Seniority', 'Flight plan', 'Logbook', '✈'),
  'vet': ('The practice', 'Day list', 'Field notes', '❦'),
  'hustler': ('Street cred', 'Today\'s pitch', 'Word on the street', '✎'),
  'police': ('Rank', 'Duty roster', 'Case log', '▪'),
};

(String, String, String, String) wordsFor(String look) =>
    hubWords[look] ?? ('The ladder', 'Your work', 'So far', '•');

/// A section heading in the look's own type.
Widget hubHeading(String look, String text) {
  final p = careerLooks[look]?.palette ?? nightFeed;
  return Semantics(
    header: true,
    child: Text(text, style: _face(look, 19, p.text).copyWith(height: 1.2)),
  );
}

/// An icon for each Career activity.
const _actionIcons = <String, IconData>{
  'act_audition': Icons.record_voice_over_rounded,
  'act_class': Icons.school_rounded,
  'act_network': Icons.wine_bar_rounded,
  'act_agent': Icons.handshake_rounded,
  'act_press': Icons.mic_external_on_rounded,
  'mus_rehearse': Icons.queue_music_rounded,
  'mus_collab': Icons.people_alt_rounded,
  'mus_produce': Icons.tune_rounded,
  'mus_band': Icons.groups_rounded,
  'ath_train': Icons.fitness_center_rounded,
  'ath_rest': Icons.hotel_rounded,
  'ath_film': Icons.ondemand_video_rounded,
  'ath_sponsor': Icons.verified_rounded,
  'pol_speech': Icons.campaign_rounded,
  'pol_rally': Icons.flag_rounded,
  'pol_surgery': Icons.forum_rounded,
  'pol_fundraise': Icons.savings_rounded,
  'pol_bill': Icons.how_to_vote_rounded,
  'cop_patrol': Icons.local_police_rounded,
  'cop_cold': Icons.inventory_2_rounded,
  'mod_casting': Icons.directions_walk_rounded,
  'mod_shoot': Icons.photo_camera_rounded,
  'mod_fashion_week': Icons.checkroom_rounded,
  'mod_campaign': Icons.storefront_rounded,
  'mod_agency': Icons.apartment_rounded,
  'doc_triage': Icons.emergency_rounded,
  'doc_shift': Icons.nightlight_round,
  'doc_research': Icons.biotech_rounded,
  'doc_teach': Icons.co_present_rounded,
  'doc_abroad': Icons.volunteer_activism_rounded,
  'vet_clinic': Icons.pets_rounded,
  'vet_farm': Icons.agriculture_rounded,
  'vet_oncall': Icons.phone_in_talk_rounded,
  'vet_own_pets': Icons.favorite_rounded,
  'vet_practice': Icons.home_work_rounded,
  'pil_short': Icons.flight_takeoff_rounded,
  'pil_long': Icons.public_rounded,
  'pil_cargo': Icons.local_shipping_rounded,
  'pil_check': Icons.flight_land_rounded,
  'pil_staff_travel': Icons.beach_access_rounded,
  'pil_union': Icons.badge_rounded,
  'mil_drill': Icons.directions_run_rounded,
  'mil_course': Icons.menu_book_rounded,
  'mil_mission': Icons.explore_rounded,
  'mil_mentor': Icons.groups_2_rounded,
  'mil_leave': Icons.cottage_rounded,
  'law_case': Icons.folder_open_rounded,
  'law_cross': Icons.record_voice_over_rounded,
  'law_research': Icons.local_library_rounded,
  'law_client': Icons.restaurant_rounded,
  'law_probono': Icons.volunteer_activism_rounded,
  'law_hear': Icons.gavel_rounded,
  'hus_pitch': Icons.place_rounded,
  'hus_busk': Icons.music_note_rounded,
  'hus_sell': Icons.shopping_basket_rounded,
  'hus_show': Icons.auto_awesome_rounded,
  'hus_licence': Icons.card_membership_rounded,
};

IconData? hubActionIcon(String id) => _actionIcons[id];

/// The ladder as a track: rungs behind you filled, your rung wearing the
/// career's emblem, the ones ahead hollow.
class HubLadder extends StatelessWidget {
  const HubLadder({
    super.key,
    required this.look,
    required this.ladder,
    required this.rank,
    this.next,
  });
  final String look;
  final List<String> ladder;
  final int rank;
  final String? next;

  @override
  Widget build(BuildContext context) {
    final cl = careerLooks[look];
    final p = cl?.palette ?? nightFeed;
    return Semantics(
      label:
          '${ladder[rank]}, step ${rank + 1} of ${ladder.length}.${next == null ? '' : ' Next: $next'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < ladder.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The rail between rungs.
                        Positioned(
                          top: i == 0 ? 17 : 0,
                          bottom: i == ladder.length - 1 ? null : 0,
                          height: i == ladder.length - 1 ? 17 : null,
                          child: Container(
                            width: 3,
                            color: i < rank ? p.orange : p.border,
                          ),
                        ),
                        Container(
                          width: i == rank ? 30 : 16,
                          height: i == rank ? 30 : 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < rank
                                ? p.orange
                                : i == rank
                                ? p.surface2
                                : p.bg,
                            border: Border.all(
                              color: i <= rank ? p.orange : p.border,
                              width: 2,
                            ),
                            boxShadow: i == rank
                                ? [
                                    BoxShadow(
                                      color: p.orange.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: i == rank
                              ? Icon(cl?.icon, size: 16, color: p.orange)
                              : i < rank
                              ? Icon(Icons.check_rounded, size: 11, color: p.bg)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        ladder[i],
                        style: i == rank
                            ? _face(look, 17, p.text).copyWith(height: 1.2)
                            : NF.sora(14, color: i < rank ? p.soft : p.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: p.blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.blue.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 16, color: p.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(next!, style: NF.sora(13, color: p.blue)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The look's display type (Playfair, stencil, chalk or Sora).
TextStyle hubFace(String look, double size, Color color) =>
    _face(look, size, color);

/// One of the career's people: role, name, bond and whether they are on
/// your side. [onTap] opens them in People.
class HubContactCard extends StatelessWidget {
  const HubContactCard({
    super.key,
    required this.look,
    required this.name,
    required this.role,
    required this.kind,
    required this.bond,
    this.onTap,
  });
  final String look, name, role, kind;
  final int bond;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = careerLooks[look]?.palette ?? nightFeed;
    final (tag, colour, icon) = switch (kind) {
      'rival' => ('Rival', NF.danger, Icons.bolt_rounded),
      'ally' => ('Ally', p.blue, Icons.handshake_rounded),
      _ => ('Your boss', p.soft, Icons.star_rounded),
    };
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join();
    return Semantics(
      button: true,
      label: '$name, $role. $tag. Bond $bond.',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colour.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: p.surface2,
                      child: Text(
                        initials,
                        style: NF.sora(
                          13,
                          weight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: colour),
                        ),
                        child: Icon(icon, size: 10, color: colour),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NF.sora(
                          14,
                          weight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      Text(
                        '$role · $tag',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: NF.sora(12, color: colour),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          value: bond / 100,
                          minHeight: 4,
                          backgroundColor: p.surface2,
                          color: colour,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
