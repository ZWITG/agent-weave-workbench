import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/career_hub.dart';
import '../engine/models.dart';
import '../engine/policing.dart' show casesClosed, dirtyFile;
import '../theme.dart';
import 'career_stage.dart' show hubFace;
import 'widgets.dart';

// Each career's signature on its hub page (boot prints, a setlist, a
// balance scale...) and the drawings at the top of a season tab's sheet.
// The state lives in engine/career_seasons.dart; this only draws it.

const _risk = Color(0xFFFF6B6B);
const _good = Color(0xFF7BD88F);

/// The signature card for the career you are in.
class CareerSignature extends StatelessWidget {
  const CareerSignature({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final l = life;
    final id = l.careerId;
    final look = careerLooks[id];
    if (id == null || look == null || hubTabs(l) == null) {
      return const SizedBox.shrink();
    }
    final p = look.palette;
    final (title, right, body, note) = _signature(l, id, p);
    return Semantics(
      container: true,
      label: '$title. $right. $note',
      excludeSemantics: true,
      child: NFCard(
        key: const ValueKey('career-signature'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: hubFace(id, 18, NF.text))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    right.toUpperCase(),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NF
                        .sora(10.5, weight: FontWeight.w700, color: p.orange)
                        .copyWith(letterSpacing: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            body,
            const SizedBox(height: 10),
            Text(note, style: NF.sora(12, color: NF.muted)),
          ],
        ),
      ),
    );
  }
}

(String, String, Widget, String) _signature(Life l, String id, NFPalette p) {
  switch (id) {
    case 'military':
      final f = fieldFatigue(l);
      return (
        'FATIGUE',
        '$f / 5${f > 2 ? ' · risk up' : ''}',
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: CustomPaint(
                  size: const Size(26, 40),
                  painter: _BootPainter(i < f ? p.orange : null, NF.border),
                ),
              ),
          ],
        ),
        'Every course, exercise and posting leaves a boot print. Leave clears them.',
      );
    case 'athlete':
      final fat = athleteFatigue(l);
      final res = athleteResults(l);
      return (
        'FORM vs FATIGUE',
        fat >= 80 ? 'Injury zone' : 'Fit',
        Column(
          children: [
            _barRow('FORM', hubMeter(l), p.blue, id),
            const SizedBox(height: 8),
            _barRow('FATIGUE', fat, p.orange, id, hatchFrom: 80),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('SEASON', style: _lbl()),
                ),
                if (res.isEmpty)
                  Text('No matches yet', style: NF.sora(12, color: NF.muted)),
                for (final r in res)
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r == 'W'
                          ? p.blue
                          : r == 'L'
                          ? p.orange
                          : NF.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r,
                      style: hubFace(id, 14, r == 'D' ? NF.text : p.bg),
                    ),
                  ),
              ],
            ),
          ],
        ),
        'Past the hatched line, every hard block risks an injury.',
      );
    case 'musician':
      final songs = setlist(l);
      return (
        'Setlist',
        '${songs.length} song${songs.length == 1 ? '' : 's'}',
        _Setlist(songs: songs, p: p),
        'Write songs, record them better, then play your best one on tour.',
      );
    case 'actor':
      final g = actorGenres(l);
      final t = typecast(l);
      return (
        'Typecast',
        t ?? 'Not yet',
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              for (final e in g.entries) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: NF.surface2,
                      borderRadius: BorderRadius.circular(3),
                      border: e.key == t
                          ? Border.all(color: p.orange, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(e.key, style: hubFace(id, 13, NF.text)),
                        Text(
                          '${e.value}',
                          style: hubFace(
                            id,
                            20,
                            e.key == t ? p.orange : NF.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (e.key != 'Horror') const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        'Win three roles in one genre and you are typecast: your type lands more often, the rest gets harder.',
      );
    case 'politician':
      final w = whipBalance(l);
      return (
        'The balance',
        w > 55
            ? 'Whip $w'
            : w < 45
            ? 'Conscience ${100 - w}'
            : 'Balanced',
        SizedBox(
          height: 96,
          child: CustomPaint(size: Size.infinite, painter: _ScalePainter(w, p)),
        ),
        'Party votes please the whip. Conscience votes please voters. Debates go best near the middle.',
      );
    case 'police':
      final dirt = dirtyFile(l);
      return (
        'Your file',
        dirt == 0 ? 'Clean' : '$dirt marks',
        _Folder(closed: casesClosed(l), dirt: dirt, p: p),
        'Shortcuts close cases faster but mark your file. Marks hurt you in court and at the panel.',
      );
    case 'doctor':
      final b = burnout(l);
      return (
        'Burnout',
        '$b%',
        SizedBox(
          height: 64,
          child: CustomPaint(size: Size.infinite, painter: _EcgPainter(b, p)),
        ),
        'Long wards and big trials raise it. Over 80, mistakes happen. A holiday brings it down.',
      );
    case 'lawyer':
      final (won, lost, ethics) = lawRecord(l);
      return (
        'The record',
        'Ethics $ethics',
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB8893A),
                    Color(0xFFE9C97A),
                    Color(0xFFB8893A),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF6E4E1C), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'WON – LOST',
                    style: NF
                        .sora(
                          9.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF4A3410),
                        )
                        .copyWith(letterSpacing: 2),
                  ),
                  Text(
                    '$won – $lost',
                    style: hubFace(id, 26, const Color(0xFF2A1C06)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _gradientMarker(
              ethics / 100,
              const [_risk, Color(0xFFE9C97A), _good],
              'Ruthless',
              'Principled',
            ),
          ],
        ),
        'Trials and appeals build your record. Principled lawyers make partner more easily.',
      );
    case 'model':
      final img = modelImage(l);
      return (
        'Your image',
        img > 15
            ? 'Edgy'
            : img < -15
            ? 'Wholesome'
            : 'Balanced',
        SizedBox(
          height: 92,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DialPainter(img, p),
          ),
        ),
        'Luxury houses want balance. Controversial brands want edge.',
      );
    case 'vet':
      final t = farmTrust(l);
      return (
        'Farm trust',
        '${t.fold(0, (a, b) => a + b)} hearts',
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NF.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NF.border),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          vetFarms[i],
                          maxLines: 1,
                          style: hubFace(id, 15, NF.text),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: _iconRow(
                          Icons.favorite_rounded,
                          Icons.favorite_border_rounded,
                          t[i],
                          t[i] >= 2 ? p.orange : _risk,
                          13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 6),
            ],
          ],
        ),
        'Farms you visit trust you more. Farms you skip at harvest drift away.',
      );
    case 'pilot':
      final s = logbook(l);
      return (
        'Logbook',
        '${s.length} / 8 stamps',
        Center(
          child: SizedBox(
            width: 4 * 50 + 3 * 10,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 8; i++)
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i < s.length ? p.orange : NF.border,
                        width: i < s.length ? 2 : 1,
                      ),
                    ),
                    child: i < s.length
                        ? Transform.rotate(
                            angle: (i.isEven ? -1 : 1) * 0.18,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                s[i],
                                style: hubFace(id, 15, p.orange),
                              ),
                            ),
                          )
                        : Text('·', style: NF.sora(14, color: NF.border)),
                  ),
              ],
            ),
          ),
        ),
        'Each new airport is a stamp. Fill the page for a bonus and a holiday.',
      );
    case 'hustler':
      final corner = hustlerCorner(l);
      final corners = hubTabs(l)![0].opts;
      return (
        'Your pitch',
        corners.where((o) => o.id == corner).firstOrNull?.label ?? 'No pitch',
        _Chalkboard(
          lines: [
            for (final o in corners)
              (o.label, _policeWord(o.tag), o.id == corner),
          ],
          look: id,
        ),
        'Busy corners pay more but the police move you on. Pick a new pitch on Market days.',
      );
    case 'astronaut':
      final n = astroCountdown(l);
      return (
        'Countdown',
        n == 0 ? 'On the crew' : 'T−$n',
        SizedBox(
          height: 96,
          child: CustomPaint(
            size: Size.infinite,
            painter: _RingPainter(n, p, id),
          ),
        ),
        'Pass selection and training to count down. At zero you are on a crew and can launch.',
      );
    case 'fighter':
      final d = fightDamage(l);
      final foe = fighterFoe(l);
      return (
        'Damage',
        '$d%',
        Row(
          children: [
            SizedBox(
              width: 70,
              height: 100,
              child: CustomPaint(painter: _BodyPainter(d, p)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT OPPONENT', style: _lbl()),
                  Text(foe.$1, style: hubFace(id, 20, NF.text)),
                  Text(
                    'A ${foe.$2}. Strike beats grapple, grapple beats defend, defend beats strike.',
                    style: NF.sora(12, color: NF.soft),
                  ),
                ],
              ),
            ),
          ],
        ),
        'Every fight adds damage. Physio takes it off. Over 80, the doctors want you to stop.',
      );
  }
  return ('', '', const SizedBox.shrink(), '');
}

String _policeWord(String? tag) {
  final n = tag != null && tag.startsWith('police:')
      ? int.tryParse(tag.substring(7)) ?? 0
      : 0;
  return n >= 30
      ? 'police often'
      : n >= 10
      ? 'police sometimes'
      : 'quiet';
}

TextStyle _lbl() => NF
    .sora(10, weight: FontWeight.w700, color: NF.muted)
    .copyWith(letterSpacing: 1.6);

Widget _barRow(String label, int v, Color c, String look, {int? hatchFrom}) =>
    Row(
      children: [
        SizedBox(width: 62, child: Text(label, style: _lbl())),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 12,
              child: CustomPaint(
                painter: _BarPainter(v / 100, c, hatchFrom: hatchFrom),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$v',
            textAlign: TextAlign.right,
            style: hubFace(look, 16, c),
          ),
        ),
      ],
    );

Widget _gradientMarker(double at, List<Color> colors, String lo, String hi) =>
    Column(
      children: [
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (_, box) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: (box.maxWidth - 6) * at.clamp(0, 1),
                  top: 0,
                  width: 6,
                  height: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: NF.text,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(lo, style: NF.sora(11, color: NF.muted)),
            ),
            Expanded(
              child: Text(
                hi,
                textAlign: TextAlign.right,
                style: NF.sora(11, color: NF.muted),
              ),
            ),
          ],
        ),
      ],
    );

class _Setlist extends StatelessWidget {
  const _Setlist({required this.songs, required this.p});
  final List<Map<String, dynamic>> songs;
  final NFPalette p;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A1230);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      child: Transform.rotate(
        angle: -0.02,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SETLIST', style: hubFace('vet', 24, ink)),
                  const SizedBox(height: 4),
                  if (songs.isEmpty)
                    Text(
                      'Nothing yet. Pick a mood in Write.',
                      style: NF.sora(13, color: const Color(0xFF7A6AA8)),
                    ),
                  for (var i = 0; i < songs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${i + 1}. ${songs[i]['t']} '),
                                  TextSpan(
                                    text: '${songs[i]['mood']}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF7A6AA8),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NF.sora(13, color: ink),
                            ),
                          ),
                          _iconRow(
                            Icons.star_rounded,
                            Icons.star_border_rounded,
                            (songs[i]['q'] as int?) ?? 1,
                            const Color(0xFFB0129A),
                            13,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(left: 18, top: -8, child: _tape(p.orange, -0.1)),
            Positioned(right: 18, top: -8, child: _tape(p.blue, 0.09)),
          ],
        ),
      ),
    );
  }

  Widget _tape(Color c, double a) => Transform.rotate(
    angle: a,
    child: Container(width: 52, height: 15, color: c.withValues(alpha: 0.85)),
  );
}

Widget _iconRow(IconData on, IconData off, int n, Color c, double size) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    for (var i = 0; i < 5; i++)
      Icon(
        i < n ? on : off,
        size: size,
        color: i < n ? c : c.withValues(alpha: 0.45),
      ),
  ],
);

class _Folder extends StatelessWidget {
  const _Folder({required this.closed, required this.dirt, required this.p});
  final int closed, dirt;
  final NFPalette p;

  @override
  Widget build(BuildContext context) {
    const manila = Color(0xFFD9B871);
    const ink = Color(0xFF3B2A10);
    final stamp = dirt == 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 14,
          decoration: const BoxDecoration(
            color: manila,
            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: const BoxDecoration(
            color: manila,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONNEL FILE',
                      style: NF
                          .sora(10, weight: FontWeight.w700, color: ink)
                          .copyWith(letterSpacing: 1.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cases closed: $closed',
                      style: NF.sora(13, color: ink),
                    ),
                    Text('Marks: $dirt', style: NF.sora(13, color: ink)),
                  ],
                ),
              ),
              Transform.rotate(
                angle: -0.16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: stamp, width: 3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dirt == 0 ? 'CLEAN' : 'MARKED',
                    style: hubFace('police', 20, stamp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chalkboard extends StatelessWidget {
  const _Chalkboard({required this.lines, required this.look});
  final List<(String, String, bool)> lines;
  final String look;

  @override
  Widget build(BuildContext context) {
    const chalk = Color(0xFFF2F0E6);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3A2C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8A6A3A), width: 5),
      ),
      child: Column(
        children: [
          for (final (name, risk, on) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: on
                          ? BoxDecoration(
                              border: Border.all(color: chalk, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hubFace(look, 20, chalk),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      risk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hubFace(
                        look,
                        17,
                        risk == 'quiet'
                            ? const Color(0xFFB9E6A8)
                            : const Color(0xFFFFB4A8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- Painters ----------------

class _BootPainter extends CustomPainter {
  _BootPainter(this.fill, this.edge);
  final Color? fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size s) {
    final paint = fill == null
        ? (Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = edge)
        : (Paint()..color = fill!);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height * 0.3),
        width: s.width * 0.6,
        height: s.height * 0.54,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height * 0.8),
        width: s.width * 0.46,
        height: s.height * 0.28,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BootPainter o) => o.fill != fill;
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.v, this.c, {this.hatchFrom});
  final double v;
  final Color c;
  final int? hatchFrom;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = NF.surface2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width * v.clamp(0, 1), s.height),
      Paint()..color = c,
    );
    if (hatchFrom != null) {
      final x0 = s.width * hatchFrom! / 100;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(x0, 0, s.width - x0, s.height));
      final h = Paint()
        ..color = _risk.withValues(alpha: 0.6)
        ..strokeWidth = 3;
      for (var x = x0 - s.height; x < s.width; x += 7) {
        canvas.drawLine(Offset(x, s.height), Offset(x + s.height, 0), h);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.v != v;
}

class _ScalePainter extends CustomPainter {
  _ScalePainter(this.whip, this.p);
  final int whip;
  final NFPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final metal = Paint()
      ..color = const Color(0xFFD8B86A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Post and base.
    canvas.drawLine(Offset(cx, 14), Offset(cx, s.height - 10), metal);
    canvas.drawLine(
      Offset(cx - 26, s.height - 8),
      Offset(cx + 26, s.height - 8),
      metal,
    );
    canvas.drawCircle(
      Offset(cx, 12),
      5,
      Paint()..color = const Color(0xFFD8B86A),
    );
    // Beam: the whip side (right) drops as the whip grows.
    final a = (whip - 50) / 50 * 0.32;
    final arm = min(110.0, s.width / 2 - 34);
    final l = Offset(cx - arm * cos(a), 14 - arm * sin(a));
    final r = Offset(cx + arm * cos(a), 14 + arm * sin(a));
    canvas.drawLine(l, r, metal);
    void pan(Offset at, Color c, String label) {
      final thin = Paint()
        ..color = const Color(0xFFD8B86A)
        ..strokeWidth = 1.2;
      canvas.drawLine(at, at + const Offset(-20, 30), thin);
      canvas.drawLine(at, at + const Offset(20, 30), thin);
      final bowl = Path()
        ..moveTo(at.dx - 26, at.dy + 30)
        ..quadraticBezierTo(at.dx, at.dy + 50, at.dx + 26, at.dy + 30)
        ..close();
      canvas.drawPath(bowl, Paint()..color = c);
      _text(
        canvas,
        label,
        Offset(at.dx, at.dy + 54),
        NF.sora(11, weight: FontWeight.w700, color: c),
        center: true,
      );
    }

    pan(l, p.blue, 'Conscience');
    pan(r, p.orange, 'Whip');
  }

  @override
  bool shouldRepaint(_ScalePainter o) => o.whip != whip;
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.b, this.p);
  final int b;
  final NFPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = NF.border.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x < s.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (var y = 0.0; y < s.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final c = Color.lerp(_good, _risk, b / 100)!;
    final mid = s.height * 0.6;
    final beats = 3 + b ~/ 20;
    final gap = s.width / beats;
    final amp = s.height * (0.35 + b / 250);
    final path = Path()..moveTo(0, mid);
    for (var i = 0; i < beats; i++) {
      final x = i * gap;
      path
        ..lineTo(x + gap * 0.35, mid)
        ..lineTo(x + gap * 0.42, mid - amp * 0.2)
        ..lineTo(x + gap * 0.48, mid)
        ..lineTo(x + gap * 0.54, mid - amp)
        ..lineTo(x + gap * 0.60, mid + amp * 0.35)
        ..lineTo(x + gap * 0.66, mid)
        ..lineTo(x + gap, mid);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter o) => o.b != b;
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.img, this.p);
  final int img;
  final NFPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final r = min(s.width / 2 - 40, s.height - 34);
    final c = Offset(s.width / 2, s.height - 24);
    final rect = Rect.fromCircle(center: c, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: pi,
        endAngle: 2 * pi,
        colors: [p.blue, NF.muted, p.orange],
      ).createShader(rect);
    canvas.drawArc(rect, pi, pi, false, arc);
    final a = pi + (img + 50) / 100 * pi;
    canvas.drawLine(
      c,
      c + Offset(cos(a), sin(a)) * (r - 14),
      Paint()
        ..color = NF.text
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 6, Paint()..color = NF.text);
    _text(
      canvas,
      'Wholesome',
      Offset(c.dx - r, c.dy + 8),
      NF.sora(11, weight: FontWeight.w700, color: p.blue),
      center: true,
    );
    _text(
      canvas,
      'Edgy',
      Offset(c.dx + r, c.dy + 8),
      NF.sora(11, weight: FontWeight.w700, color: p.orange),
      center: true,
    );
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.img != img;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.n, this.p, this.look);
  final int n;
  final NFPalette p;
  final String look;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.height / 2 - 6;
    for (var i = 0; i < 3; i++) {
      final done = i < 3 - n;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2 + i * 2 * pi / 3 + 0.08,
        2 * pi / 3 - 0.16,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = done ? p.orange : NF.border,
      );
    }
    _text(
      canvas,
      n == 0 ? 'GO' : 'T−$n',
      c - const Offset(0, 14),
      hubFace(look, 24, n == 0 ? p.orange : NF.text),
      center: true,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.n != n;
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.d, this.p);
  final int d;
  final NFPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    Color part(int at) =>
        d >= at ? Color.lerp(p.orange, _risk, (d - at) / 60)! : NF.surface2;
    final w = s.width;
    canvas.drawCircle(Offset(w / 2, 12), 10, Paint()..color = part(60));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 15, 25, 30, 38),
        const Radius.circular(6),
      ),
      Paint()..color = part(30),
    );
    final limb = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w / 2 - 19, 30),
      Offset(w / 2 - 28, 58),
      limb..color = part(15),
    );
    canvas.drawLine(
      Offset(w / 2 + 19, 30),
      Offset(w / 2 + 28, 58),
      limb..color = part(15),
    );
    canvas.drawLine(
      Offset(w / 2 - 8, 68),
      Offset(w / 2 - 11, 96),
      limb..color = part(45),
    );
    canvas.drawLine(
      Offset(w / 2 + 8, 68),
      Offset(w / 2 + 11, 96),
      limb..color = part(45),
    );
  }

  @override
  bool shouldRepaint(_BodyPainter o) => o.d != d;
}

void _text(
  Canvas canvas,
  String t,
  Offset at,
  TextStyle style, {
  bool center = false,
  bool right = false,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = center
      ? at.dx - tp.width / 2
      : right
      ? at.dx - tp.width
      : at.dx;
  tp.paint(canvas, Offset(dx, at.dy));
}

// ---------------- Sheet art ----------------

/// The drawing at the top of a season tab's sheet, or null.
Widget? seasonArt(Life l, SeasonTab tab) {
  final art = tab.art;
  final look = careerLooks[l.careerId];
  if (art == null || look == null) return null;
  return ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: CustomPaint(
          key: ValueKey('season-art-$art'),
          painter: _ArtPainter(art, look.palette, l, tab),
        ),
      ),
    ),
  );
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.art, this.p, this.l, this.tab);
  final String art;
  final NFPalette p;
  final Life l;
  final SeasonTab tab;

  String get look => l.careerId!;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()..color = Color.lerp(p.bg, Colors.black, 0.35)!,
    );
    switch (art) {
      case 'moor':
        _moor(canvas, s);
      case 'goal':
        _goal(canvas, s);
      case 'tour':
        _tour(canvas, s);
      case 'scripts':
        _cards(canvas, s, const [
          Color(0xFF8C2B3C),
          Color(0xFFC9A04A),
          Color(0xFF3B5B8C),
          Color(0xFF2F5F3A),
        ], const Color(0xFFFFF1E6));
      case 'budget':
        _budget(canvas, s);
      case 'board':
        _board(canvas, s);
      case 'covers':
        _covers(canvas, s);
      case 'triage':
        _triage(canvas, s);
      case 'files':
        _files(canvas, s);
      case 'chalk':
        _chalk(canvas, s);
      case 'console':
        _console(canvas, s);
      case 'scorecard':
        _scorecard(canvas, s);
      case 'farms':
        _farms(canvas, s);
      case 'radar':
        _radar(canvas, s);
    }
  }

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, min(d + 6, m.length)), paint);
      }
    }
  }

  void _moor(Canvas canvas, Size s) {
    final green = Paint()..color = const Color(0xFF2A3320);
    canvas.drawOval(
      Rect.fromLTWH(s.width * 0.1, 10, s.width * 0.55, 70),
      green,
    );
    canvas.drawOval(
      Rect.fromLTWH(s.width * 0.45, 40, s.width * 0.5, 80),
      green,
    );
    // Bog in the middle.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * 0.55),
        width: 90,
        height: 40,
      ),
      Paint()..color = const Color(0xFF2F4A55),
    );
    final start = Offset(24, s.height - 20);
    final end = Offset(s.width - 28, 24);
    final road = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(s.width - 40, s.height - 18)
      ..lineTo(end.dx, end.dy);
    final ridge = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(40, 26)
      ..lineTo(end.dx, end.dy);
    final bog = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(road, _stroke(NF.muted, 3));
    _dashed(canvas, ridge, _stroke(p.blue, 3));
    _dashed(canvas, bog, _stroke(p.orange, 3));
    canvas.drawCircle(start, 7, Paint()..color = NF.text);
    canvas.drawLine(end, end + const Offset(0, -18), _stroke(NF.text, 2));
    canvas.drawPath(
      Path()
        ..moveTo(end.dx, end.dy - 18)
        ..lineTo(end.dx + 14, end.dy - 13)
        ..lineTo(end.dx, end.dy - 8),
      Paint()..color = p.orange,
    );
    final f = NF.sora(11, weight: FontWeight.w700, color: NF.text);
    _text(
      canvas,
      'Road',
      Offset(s.width * 0.6, s.height - 36),
      f.copyWith(color: NF.muted),
    );
    _text(
      canvas,
      'Ridge',
      Offset(s.width * 0.35, 8),
      f.copyWith(color: p.blue),
    );
    _text(
      canvas,
      'Bog',
      Offset(s.width * 0.5, s.height * 0.5),
      f.copyWith(color: p.orange),
      center: true,
    );
  }

  void _goal(Canvas canvas, Size s) {
    final net = _stroke(NF.border, 1);
    final l = 30.0, r = s.width - 30, t = 20.0, b = s.height - 12;
    for (var x = l; x <= r; x += 24) {
      canvas.drawLine(Offset(x, t), Offset(x, b), net);
    }
    for (var y = t; y <= b; y += 22) {
      canvas.drawLine(Offset(l, y), Offset(r, y), net);
    }
    canvas.drawPath(
      Path()
        ..moveTo(l, b)
        ..lineTo(l, t)
        ..lineTo(r, t)
        ..lineTo(r, b),
      _stroke(NF.text, 5),
    );
    final kx = s.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(kx - 18, b - 56, 36, 56),
        const Radius.circular(10),
      ),
      Paint()..color = p.orange.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(kx, b - 66),
      10,
      Paint()..color = p.orange.withValues(alpha: 0.85),
    );
    final aim = Offset(r - 36, t + 26);
    canvas.drawCircle(aim, 15, _stroke(p.blue, 3));
    canvas.drawLine(
      aim - const Offset(22, 0),
      aim + const Offset(22, 0),
      _stroke(p.blue, 2),
    );
    canvas.drawLine(
      aim - const Offset(0, 22),
      aim + const Offset(0, 22),
      _stroke(p.blue, 2),
    );
  }

  void _tour(Canvas canvas, Size s) {
    final land = _stroke(NF.surface2, 16);
    canvas.drawPath(
      Path()
        ..moveTo(40, 18)
        ..cubicTo(80, 10, 90, 50, 80, 80)
        ..cubicTo(70, 110, 110, 120, 100, 130),
      land,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.5, 28)
        ..cubicTo(s.width * 0.7, 18, s.width * 0.85, 40, s.width - 24, 70)
        ..cubicTo(s.width - 20, 100, s.width * 0.8, 125, s.width * 0.65, 128),
      land,
    );
    final cities = [
      ('Glasgow', const Offset(70, 32), 0),
      ('Leeds', const Offset(96, 84), 0),
      ('London', const Offset(112, 114), 1),
      ('Berlin', Offset(s.width * 0.7, 62), 2),
      ('Paris', Offset(s.width * 0.5, 96), 1),
      ('Lisbon', Offset(s.width * 0.82, 112), 2),
    ];
    final route = Path()..moveTo(cities[0].$2.dx, cities[0].$2.dy);
    for (final c in cities.skip(1).where((c) => c.$3 < 2)) {
      route.lineTo(c.$2.dx, c.$2.dy);
    }
    _dashed(canvas, route, _stroke(p.orange, 3));
    for (final (name, at, ring) in cities) {
      if (ring < 2) {
        canvas.drawCircle(at, 6, Paint()..color = p.orange);
      } else {
        canvas.drawCircle(at, 6, _stroke(p.blue, 2));
      }
      _text(
        canvas,
        name,
        at + const Offset(10, -6),
        NF.sora(11, color: ring < 2 ? NF.text : NF.muted),
      );
    }
  }

  void _cards(Canvas canvas, Size s, List<Color> bars, Color paper) {
    final n = tab.opts.length;
    const gap = 8.0;
    final w = (s.width - 24 - gap * (n - 1)) / n;
    final t = typecast(l);
    for (var i = 0; i < n; i++) {
      final o = tab.opts[i];
      final x = 12 + i * (w + gap);
      final rect = Rect.fromLTWH(x, 12, w, s.height - 24);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = paper,
      );
      if (o.tag != null && o.tag == t) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          _stroke(p.orange, 3),
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(x + 6, 18, w - 12, 5),
        Paint()..color = bars[i % bars.length],
      );
      _text(
        canvas,
        o.label,
        Offset(x + 5, 30),
        hubFace(look, min(13, w / 7), const Color(0xFF24111A)),
        maxWidth: w - 10,
      );
      _text(
        canvas,
        o.tag ?? '',
        Offset(x + 6, s.height - 34),
        NF.sora(10, color: const Color(0xFF6B4A50)),
      );
    }
  }

  void _budget(Canvas canvas, Size s) {
    const cols = [
      Color(0xFF5B8DEF),
      Color(0xFF4CC38A),
      Color(0xFF8A7CF0),
      Color(0xFFE8B04B),
    ];
    final opts = tab.opts;
    final w = s.width - 32;
    var x = 16.0;
    final share = [0.3, 0.3, 0.2, 0.2];
    _text(
      canvas,
      'THE BUDGET',
      const Offset(16, 14),
      NF
          .sora(10, weight: FontWeight.w700, color: NF.muted)
          .copyWith(letterSpacing: 1.6),
    );
    for (var i = 0; i < opts.length; i++) {
      final seg = w * share[i % 4];
      canvas.drawRect(
        Rect.fromLTWH(x, 40, seg - 2, 34),
        Paint()..color = cols[i % 4],
      );
      _text(
        canvas,
        opts[i].label,
        Offset(x + seg / 2, 84),
        NF.sora(11, weight: FontWeight.w700, color: cols[i % 4]),
        center: true,
      );
      x += seg;
    }
    _text(
      canvas,
      'Where does most of it go?',
      Offset(s.width / 2, 106),
      NF.sora(11, color: NF.muted),
      center: true,
    );
  }

  void _board(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF9C7448));
    final dots = Paint()..color = const Color(0xFF8A6438);
    final rnd = Random(7);
    for (var i = 0; i < 160; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height),
        1.2,
        dots,
      );
    }
    final pins = [
      Offset(s.width * 0.15, 30),
      Offset(s.width * 0.45, 70),
      Offset(s.width * 0.78, 28),
      Offset(s.width * 0.7, 96),
      Offset(s.width * 0.22, 96),
    ];
    final string = Path()..moveTo(pins[0].dx, pins[0].dy);
    for (final pn in [pins[1], pins[2], pins[3], pins[1], pins[4]]) {
      string.lineTo(pn.dx, pn.dy);
    }
    for (var i = 0; i < pins.length; i++) {
      final r = Rect.fromCenter(
        center: pins[i] + const Offset(0, 14),
        width: 46,
        height: 34,
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = i.isEven
              ? const Color(0xFFF2EEE4)
              : const Color(0xFFE8E0C8),
      );
      canvas.drawCircle(
        r.center + const Offset(0, -2),
        7,
        Paint()..color = const Color(0xFF555555),
      );
    }
    canvas.drawPath(string, _stroke(const Color(0xFFD32F2F), 2));
    for (final pn in pins) {
      canvas.drawCircle(pn, 4, Paint()..color = const Color(0xFFD32F2F));
    }
  }

  void _covers(Canvas canvas, Size s) {
    final n = tab.opts.length;
    const gap = 10.0;
    final w = (s.width - 24 - gap * (n - 1)) / n;
    const bg = [Color(0xFF1E1A17), Color(0xFFF7D3E0), Color(0xFFB71C1C)];
    const fg = [Color(0xFFF5E6C8), Color(0xFF3A1A2A), Colors.white];
    for (var i = 0; i < n; i++) {
      final x = 12 + i * (w + gap);
      final rect = Rect.fromLTWH(x, 10, w, s.height - 20);
      canvas.drawRect(rect, Paint()..color = bg[i % 3]);
      final name = tab.opts[i].label.split(' ').first.toUpperCase();
      _text(
        canvas,
        name,
        Offset(x + w / 2, 16),
        hubFace(look, 20, fg[i % 3]),
        center: true,
        maxWidth: w - 6,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + w / 2, s.height - 50),
          width: w * 0.42,
          height: 30,
        ),
        Paint()..color = fg[i % 3].withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * 0.27, s.height - 40, w * 0.46, 30),
          const Radius.circular(10),
        ),
        Paint()..color = fg[i % 3].withValues(alpha: 0.35),
      );
    }
  }

  void _triage(Canvas canvas, Size s) {
    const cols = [
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFFFDD835),
      Color(0xFF43A047),
    ];
    const what = [
      'Cardiac arrest',
      'Broken femur',
      'Deep cut',
      'Sprained wrist',
    ];
    const gap = 8.0;
    final w = (s.width - 24 - gap * 3) / 4;
    for (var i = 0; i < 4; i++) {
      final x = 12 + i * (w + gap);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 14, w, s.height - 28),
        const Radius.circular(8),
      );
      canvas.drawRRect(r, Paint()..color = NF.surface);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 14, w, 22),
          const Radius.circular(8),
        ),
        Paint()..color = cols[i],
      );
      _text(
        canvas,
        '${i + 1}',
        Offset(x + w / 2, 17),
        NF.sora(12, weight: FontWeight.w800, color: Colors.black),
        center: true,
      );
      _text(
        canvas,
        what[i],
        Offset(x + 6, 46),
        NF.sora(11, color: NF.text),
        maxWidth: w - 12,
      );
    }
  }

  void _files(Canvas canvas, Size s) {
    const manila = Color(0xFFD9B871);
    const ink = Color(0xFF3B2A10);
    final n = tab.opts.length;
    const gap = 10.0;
    final w = (s.width - 24 - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final x = 12 + i * (w + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 6, 14, w * 0.45, 14),
          const Radius.circular(4),
        ),
        Paint()..color = manila,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 24, w, s.height - 36),
          const Radius.circular(5),
        ),
        Paint()..color = manila,
      );
      _text(
        canvas,
        tab.opts[i].label,
        Offset(x + 8, 36),
        hubFace(look, 14, ink),
        maxWidth: w - 16,
      );
      for (var k = 0; k < 3; k++) {
        canvas.drawLine(
          Offset(x + 8, 84 + k * 10.0),
          Offset(x + w - 8 - k * 10, 84 + k * 10.0),
          _stroke(ink.withValues(alpha: 0.35), 2),
        );
      }
    }
  }

  void _chalk(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF1F3A2C));
    canvas.drawRect(
      Rect.fromLTWH(2, 2, s.width - 4, s.height - 4),
      _stroke(const Color(0xFF8A6A3A), 5),
    );
    const chalk = Color(0xFFF2F0E6);
    _text(
      canvas,
      'Where to pitch up',
      const Offset(16, 8),
      hubFace(look, 22, chalk),
    );
    final opts = tab.opts;
    for (var i = 0; i < opts.length; i++) {
      final y = 40.0 + i * 21;
      _text(canvas, opts[i].label, Offset(20, y), hubFace(look, 18, chalk));
      final w = _policeWord(opts[i].tag);
      _text(
        canvas,
        w,
        Offset(s.width - 20, y),
        hubFace(
          look,
          17,
          w == 'quiet' ? const Color(0xFFB9E6A8) : const Color(0xFFFFB4A8),
        ),
        right: true,
      );
      if (opts[i].id == hustlerCorner(l)) {
        canvas.drawOval(Rect.fromLTWH(12, y - 2, 130, 26), _stroke(chalk, 1.5));
      }
    }
  }

  void _console(Canvas canvas, Size s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, s.width - 20, s.height - 20),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF151A22),
    );
    final n = astroCountdown(l);
    final rnd = Random(3);
    for (var i = 0; i < 12; i++) {
      final on = i < (3 - n) * 4;
      canvas.drawCircle(
        Offset(28 + (i % 6) * 20.0, 32 + (i ~/ 6) * 20.0),
        5,
        Paint()
          ..color = on
              ? const Color(0xFF4CAF50)
              : (rnd.nextBool()
                    ? const Color(0xFF5A2A2A)
                    : const Color(0xFF333B48)),
      );
    }
    _text(
      canvas,
      n == 0 ? 'ALL SYSTEMS GO' : 'T−$n · NOT ON CREW',
      const Offset(22, 78),
      hubFace(look, 13, n == 0 ? const Color(0xFF4CAF50) : NF.muted),
    );
    final bx = s.width - 150;
    for (final (i, label, col) in [
      (0, 'GO', const Color(0xFF2E7D32)),
      (1, 'SCRUB', const Color(0xFFC62828)),
    ]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx + i * 70, 34, 62, 62),
        const Radius.circular(31),
      );
      canvas.drawRRect(
        r,
        Paint()..color = col.withValues(alpha: i == 0 && n > 0 ? 0.35 : 1),
      );
      _text(
        canvas,
        label,
        Offset(bx + i * 70 + 31, 57),
        NF.sora(12, weight: FontWeight.w800, color: Colors.white),
        center: true,
      );
    }
  }

  void _scorecard(Canvas canvas, Size s) {
    final foe = fighterFoe(l);
    canvas.drawRect(
      Rect.fromLTWH(10, 10, s.width - 20, s.height - 20),
      Paint()..color = const Color(0xFFF4F1EA),
    );
    const ink = Color(0xFF1B1B1B);
    _text(
      canvas,
      'YOU  vs  ${foe.$1.toUpperCase()}',
      Offset(s.width / 2, 16),
      hubFace(look, 15, ink),
      center: true,
    );
    _text(
      canvas,
      'A ${foe.$2}',
      Offset(s.width / 2, 36),
      NF.sora(11, color: const Color(0xFF8B1A1A)),
      center: true,
    );
    final cy = 90.0;
    final pts = [
      Offset(s.width / 2, cy - 18),
      Offset(s.width / 2 + 60, cy + 22),
      Offset(s.width / 2 - 60, cy + 22),
    ];
    const names = ['Strike', 'Grapple', 'Defend'];
    for (var i = 0; i < 3; i++) {
      final a = pts[i], b = pts[(i + 1) % 3];
      canvas.drawLine(a, b, _stroke(const Color(0xFF8B1A1A), 1.6));
      final m = Offset.lerp(a, b, 0.55)!;
      final d = (b - a) / (b - a).distance;
      canvas.drawLine(
        m,
        m - d * 8 + Offset(-d.dy, d.dx) * 4,
        _stroke(const Color(0xFF8B1A1A), 1.6),
      );
      canvas.drawLine(
        m,
        m - d * 8 - Offset(-d.dy, d.dx) * 4,
        _stroke(const Color(0xFF8B1A1A), 1.6),
      );
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(pts[i], 6, Paint()..color = ink);
      final style = NF.sora(11, weight: FontWeight.w700, color: ink);
      switch (i) {
        case 0:
          _text(canvas, names[i], pts[i] + const Offset(12, -8), style);
        case 1:
          _text(canvas, names[i], pts[i] + const Offset(12, -8), style);
        default:
          _text(
            canvas,
            names[i],
            pts[i] + const Offset(-12, -8),
            style,
            right: true,
          );
      }
    }
  }

  void _farms(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF3E5A2E));
    final t = farmTrust(l);
    final spots = [
      Offset(s.width * 0.2, 36),
      Offset(s.width * 0.42, 92),
      Offset(s.width * 0.68, 34),
      Offset(s.width * 0.84, 96),
    ];
    final lane = _stroke(const Color(0xFFC9B27A), 4);
    final p0 = Path()..moveTo(spots[0].dx, spots[0].dy);
    for (final sp in spots.skip(1)) {
      p0.lineTo(sp.dx, sp.dy);
    }
    _dashed(canvas, p0, lane);
    for (var i = 0; i < 4; i++) {
      final at = spots[i];
      canvas.drawRect(
        Rect.fromCenter(center: at, width: 26, height: 18),
        Paint()..color = const Color(0xFFB0412E),
      );
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - 16, at.dy - 9)
          ..lineTo(at.dx, at.dy - 22)
          ..lineTo(at.dx + 16, at.dy - 9),
        Paint()..color = const Color(0xFF6E2A1E),
      );
      _text(
        canvas,
        vetFarms[i],
        at + const Offset(0, 12),
        hubFace(look, 15, Colors.white),
        center: true,
      );
      _text(
        canvas,
        String.fromCharCode(Icons.favorite_rounded.codePoint) * t[i],
        at + const Offset(0, 30),
        const TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: 11,
          color: Color(0xFFFF8A80),
        ),
        center: true,
      );
    }
  }

  void _radar(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.height / 2 - 8;
    const g = Color(0xFF4CE08A);
    for (var k = 1; k <= 3; k++) {
      canvas.drawCircle(c, r * k / 3, _stroke(g.withValues(alpha: 0.35), 1));
    }
    canvas.drawLine(
      c - Offset(r, 0),
      c + Offset(r, 0),
      _stroke(g.withValues(alpha: 0.25), 1),
    );
    canvas.drawLine(
      c - Offset(0, r),
      c + Offset(0, r),
      _stroke(g.withValues(alpha: 0.25), 1),
    );
    canvas.drawCircle(
      c + Offset(r * 0.3, -r * 0.2),
      r * 0.32,
      Paint()..color = const Color(0xFFFFC107).withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      c + Offset(r * 0.35, -r * 0.22),
      r * 0.16,
      Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.5, r * 0.4),
      r * 0.18,
      Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.5),
    );
    canvas.drawLine(c, c + Offset(cos(-0.6), sin(-0.6)) * r, _stroke(g, 2));
    canvas.drawCircle(c, 3, Paint()..color = g);
    _text(
      canvas,
      'Push on',
      Offset(s.width * 0.08, 16),
      NF.sora(11, color: NF.text),
    );
    _text(
      canvas,
      'Hold',
      Offset(s.width * 0.08, 36),
      NF.sora(11, color: NF.text),
    );
    _text(
      canvas,
      'Divert',
      Offset(s.width * 0.08, 56),
      NF.sora(11, color: NF.text),
    );
  }

  @override
  bool shouldRepaint(_ArtPainter o) => true;
}

// ---------------- The options sheet ----------------

IconData seasonIcon(String name) => switch (name) {
  'money' => Icons.payments_rounded,
  'heart' => Icons.favorite_rounded,
  'home' => Icons.home_rounded,
  'fist' => Icons.sports_mma_rounded,
  'bolt' => Icons.bolt_rounded,
  'shield' => Icons.shield_rounded,
  'run' => Icons.directions_run_rounded,
  'group' => Icons.groups_rounded,
  'walk' => Icons.directions_walk_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'sun' => Icons.wb_sunny_rounded,
  'star' => Icons.star_rounded,
  'mic' => Icons.mic_rounded,
  'farm' => Icons.agriculture_rounded,
  'water' => Icons.water_rounded,
  'target' => Icons.gps_fixed_rounded,
  'school' => Icons.school_rounded,
  'phone' => Icons.smartphone_rounded,
  'party' => Icons.celebration_rounded,
  'notes' => Icons.sticky_note_2_rounded,
  'hospital' => Icons.local_hospital_rounded,
  'grapple' => Icons.sports_kabaddi_rounded,
  'globe' => Icons.public_rounded,
  'flight' => Icons.flight_rounded,
  'circle' => Icons.circle_outlined,
  'chat' => Icons.chat_bubble_rounded,
  'book' => Icons.menu_book_rounded,
  'bed' => Icons.bed_rounded,
  'badge' => Icons.badge_rounded,
  'wind' => Icons.air_rounded,
  'van' => Icons.airport_shuttle_rounded,
  'train' => Icons.train_rounded,
  'terrain' => Icons.terrain_rounded,
  'tent' => Icons.festival_rounded,
  'swap' => Icons.swap_horiz_rounded,
  'store' => Icons.storefront_rounded,
  'stop' => Icons.do_not_disturb_on_rounded,
  'square' => Icons.crop_square_rounded,
  'spin' => Icons.autorenew_rounded,
  'sparkle' => Icons.auto_awesome_rounded,
  'snake' => Icons.pest_control_rounded,
  'smile' => Icons.sentiment_satisfied_rounded,
  'search' => Icons.search_rounded,
  'scale' => Icons.balance_rounded,
  'rocket' => Icons.rocket_launch_rounded,
  'road' => Icons.add_road_rounded,
  'pulse' => Icons.monitor_heart_rounded,
  'pen' => Icons.edit_rounded,
  'moon' => Icons.nightlight_round,
  'megaphone' => Icons.campaign_rounded,
  'mask' => Icons.theater_comedy_rounded,
  'map' => Icons.map_rounded,
  'loop' => Icons.loop_rounded,
  'leaf' => Icons.eco_rounded,
  'lamb' => Icons.pets_rounded,
  'idea' => Icons.lightbulb_rounded,
  'horse' => Icons.bedroom_baby_rounded,
  'helicopter' => Icons.flight_takeoff_rounded,
  'handshake' => Icons.handshake_rounded,
  'gavel' => Icons.gavel_rounded,
  'flask' => Icons.science_rounded,
  'flag' => Icons.flag_rounded,
  'fitness' => Icons.fitness_center_rounded,
  'fire' => Icons.local_fire_department_rounded,
  'film' => Icons.movie_rounded,
  'dock' => Icons.hub_rounded,
  'disc' => Icons.album_rounded,
  'diamond' => Icons.diamond_rounded,
  'cut' => Icons.content_cut_rounded,
  'cup' => Icons.coffee_rounded,
  'clock' => Icons.schedule_rounded,
  'child' => Icons.child_care_rounded,
  'check' => Icons.check_circle_rounded,
  'building' => Icons.account_balance_rounded,
  'broken' => Icons.heart_broken_rounded,
  'box' => Icons.inventory_2_rounded,
  'bench' => Icons.chair_rounded,
  'ball' => Icons.sports_soccer_rounded,
  'bag' => Icons.shopping_bag_rounded,
  'arch' => Icons.architecture_rounded,
  'alt' => Icons.alt_route_rounded,
  _ => Icons.circle_rounded,
};

/// The tab's options as a sheet. Returns the one the player picked.
Future<SeasonOpt?> showSeasonSheet(BuildContext context, Life l, int tab) {
  final spec = hubFor(l)!;
  final tabs = hubTabs(l)!;
  final t = tabs[tab];
  final id = l.careerId!;
  final p = careerLooks[id]!.palette;
  final chosen = hubSeasonChosen(l);
  final picked = hubSeasonPicked(l);
  return showModalBottomSheet<SeasonOpt>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NF.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(spec.seasons[tab], style: hubFace(id, 22, NF.text)),
            const SizedBox(height: 4),
            Text(hubSeasonHint(l, tab), style: NF.sora(13, color: NF.muted)),
            if (seasonArt(l, t) case final art?) ...[
              const SizedBox(height: 12),
              art,
            ],
            if (chosen != null) ...[
              const SizedBox(height: 12),
              Text(
                'This year\'s focus is done: ${spec.seasons[chosen]}. Pick again next year.',
                style: NF.sora(13, weight: FontWeight.w600, color: p.orange),
              ),
            ],
            const SizedBox(height: 12),
            for (final o in t.opts) ...[
              _OptCard(
                l: l,
                o: o,
                tab: tab,
                p: p,
                done: chosen != null,
                picked: chosen == tab && picked == o.id,
                onTap: () => Navigator.pop(ctx, o),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

class _OptCard extends StatelessWidget {
  const _OptCard({
    required this.l,
    required this.o,
    required this.tab,
    required this.p,
    required this.done,
    required this.picked,
    required this.onTap,
  });
  final Life l;
  final SeasonOpt o;
  final int tab;
  final NFPalette p;
  final bool done, picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lock = seasonOptLock(l, o);
    final off = done || lock != null;
    final chips = seasonChips(l, o, tab);
    return Semantics(
      button: !off,
      enabled: !off,
      label: '${o.label}. ${o.blurb}${lock != null ? '. $lock' : ''}',
      excludeSemantics: true,
      child: Opacity(
        opacity: off && !picked ? 0.5 : 1,
        child: Material(
          color: NF.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: picked ? p.orange : NF.border,
              width: picked ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            key: ValueKey('season-opt-${o.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: off ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: NF.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      seasonIcon(o.icon),
                      size: 22,
                      color: o.kind == SeasonKind.big ? p.orange : p.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.label,
                                style: NF.sora(14, weight: FontWeight.w700),
                              ),
                            ),
                            if (picked)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: p.orange,
                              ),
                          ],
                        ),
                        if (o.blurb.isNotEmpty)
                          Text(o.blurb, style: NF.sora(12, color: NF.soft)),
                        if (lock != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: NF.muted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    lock,
                                    style: NF.sora(11.5, color: NF.muted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final (text, tone) in chips)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: tone > 0
                                          ? p.blue
                                          : tone < 0
                                          ? p.orange
                                          : NF.border,
                                    ),
                                  ),
                                  child: Text(
                                    text,
                                    style: NF.sora(
                                      10.5,
                                      color: tone > 0
                                          ? p.blue
                                          : tone < 0
                                          ? p.orange
                                          : NF.muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
