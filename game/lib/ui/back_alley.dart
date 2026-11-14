import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/crime_wall.dart';
import '../engine/models.dart';
import '../engine/underworld.dart';
import '../theme.dart';
import 'widgets.dart' show money;

/// Back Alley, the look of Activities › Crime: a rain-soaked alley at
/// midnight under a sodium streetlamp. The picture tells your criminal life
/// at a glance:
/// - police lights wash in from the street as your heat rises
/// - a poster goes up on the wall when you are hot, WANTED when red hot
/// - police tape crosses the alley while investigations are open
/// - a duffel bag by the dumpster fills with your dirty money
/// - your crew's name is sprayed on the bricks
/// - with nothing to hide, a cat sleeps on the dumpster lid
/// - every kind of crime you have tried leaves its own spray tag on the
///   bricks, and the back door carries a chalk tally of them all
/// - a neon sign over the door: your crew's front, or the local dive bar
/// Tap the cat and it bolts; tap the lamp and it buzzes; tap the poster to
/// read it. Rain falls and the lights pulse unless reduce motion is on.

const _brick = Color(0xFF2A1F1C);
const _brickLine = Color(0xFF1A1312);
const _night = Color(0xFF07090D);
const _sodium = Color(0xFFFFB547);
const _red = Color(0xFFFF3B3B);
const _blue = Color(0xFF3B6BFF);
const _tape = Color(0xFFFFD23F);
const _metal = Color(0xFF2F3A3A);
const _paper = Color(0xFFE9DFC8);

/// Everything the picture needs from the life, so it can be built from
/// any life (and in tests).
typedef AlleyState = ({
  int heat,
  int cases,
  int dirty,
  String? crew,
  List<String> tags,
  int tally,
  String neon,
  int bounty,
});

AlleyState alleyOf(Life l) => (
  heat: heat(l),
  cases: l.cases.length,
  dirty: max(0, l.dirty),
  crew: crewOf(l)?.name,
  tags: crimeTags(l),
  tally: crimesCommitted(l),
  neon: neonSign(l),
  bounty: bountyOf(l),
);

/// The stencil each kind of crime leaves on the wall.
const crimeGlyphs = <String, IconData>{
  'shoplift': Icons.shopping_bag_rounded,
  'pickpocket': Icons.back_hand_rounded,
  'graffiti': Icons.brush_rounded,
  'porch_theft': Icons.inventory_2_rounded,
  'street_racing': Icons.speed_rounded,
  'burglary': Icons.key_rounded,
  'car_theft': Icons.directions_car_rounded,
  'black_market': Icons.storefront_rounded,
  'fraud': Icons.style_rounded,
  'identity_theft': Icons.badge_rounded,
  'hacking': Icons.terminal_rounded,
  'counterfeiting': Icons.payments_rounded,
  'insurance_fraud': Icons.health_and_safety_rounded,
  'insider_trading': Icons.trending_up_rounded,
  'embezzlement': Icons.account_balance_rounded,
  'tax_evasion': Icons.receipt_long_rounded,
  'crew_job': Icons.groups_rounded,
  'plan_heist': Icons.diamond_rounded,
  'smuggling': Icons.sailing_rounded,
  'extortion': Icons.front_hand_rounded,
  'assault': Icons.sports_mma_rounded,
  'armed_robbery': Icons.local_atm_rounded,
  'murder': Icons.dangerous_rounded,
};

const _sprays = [
  Color(0xFF59F2A6),
  Color(0xFFFF5FA2),
  Color(0xFF5EE3F0),
  Color(0xFFF2F0E6),
  Color(0xFFFFB547),
  Color(0xFFB98CFF),
];

/// Free spots on the bricks for tags, as fractions of the picture, clear
/// of the door, poster, dumpster and lamp.
const _tagSpots = [
  (0.06, 0.66),
  (0.16, 0.67),
  (0.26, 0.42),
  (0.44, 0.60),
  (0.63, 0.36),
  (0.92, 0.30),
  (0.74, 0.46),
  (0.95, 0.52),
  (0.26, 0.60),
  (0.62, 0.48),
  (0.44, 0.40),
  (0.92, 0.66),
  (0.03, 0.20),
  (0.27, 0.24),
  (0.79, 0.30),
  (0.11, 0.48),
];

/// Where things are in the picture, shared by painting and tapping.
class _Geo {
  _Geo(Size size) : w = size.width, h = size.height, floor = size.height * 0.74;
  final double w, h, floor;
  Rect get door =>
      Rect.fromLTWH(w * 0.30, floor - h * 0.40, w * 0.11, h * 0.40);
  Rect get poster => Rect.fromLTWH(w * 0.47, h * 0.30, 40, 50);
  Rect get dumpster =>
      Rect.fromLTWH(w * 0.58, floor - h * 0.20, w * 0.18, h * 0.20);
  Offset get cat =>
      Offset(dumpster.left + dumpster.width * 0.35, dumpster.top - 8);
  Offset get lampHead => Offset(w * 0.84 - 16, h * 0.16);
  Offset get neon => Offset(door.center.dx, door.top - 24);
}

/// One plain sentence describing the scene, for screen readers.
String alleyCaption(AlleyState s) {
  final bits = <String>[
    s.heat == 0
        ? 'A quiet alley at night. The police are not looking at you'
        : 'A rainy alley at night. Heat: ${heatLabel(s.heat).toLowerCase()}',
    if (s.heat >= 70) 'a wanted poster with your face is on the wall',
    if (s.cases > 0)
      'police tape for ${s.cases} open investigation${s.cases == 1 ? '' : 's'}',
    if (s.dirty > 0) 'a bag of dirty money by the dumpster',
    if (s.crew != null) '${s.crew} is sprayed on the wall',
    if (s.tags.isNotEmpty)
      '${s.tags.length} kind${s.tags.length == 1 ? '' : 's'} of crime tagged on the bricks, ${s.tally} chalk marks on the door',
  ];
  return '${bits.join(', ')}.';
}

class AlleyScene extends StatefulWidget {
  const AlleyScene({super.key, required this.state, this.height = 190});

  final AlleyState state;
  final double height;

  @override
  State<AlleyScene> createState() => _AlleySceneState();
}

class _AlleySceneState extends State<AlleyScene> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// The cat bolting off the lid, and the lamp buzzing.
  late final AnimationController _cat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _buzz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// What the tapped poster says, for a moment.
  String? _note;
  int _noteId = 0;

  void _tap(TapUpDetails d, Size size) {
    final g = _Geo(size);
    final p = d.localPosition;
    final s = widget.state;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (s.heat == 0 &&
        s.dirty == 0 &&
        _cat.value == 0 &&
        (p - g.cat).distance < 26) {
      reduce ? _cat.value = 1 : _cat.forward();
      _say('The cat bolted. Even it does not trust you now.');
    } else if (s.heat >= 45 && g.poster.inflate(8).contains(p)) {
      _say(
        s.heat >= 70
            ? 'WANTED. Reward ${money(s.bounty)} for information leading to an arrest.'
            : 'Have you seen this person? Reward ${money(s.bounty)}. Call it in.',
      );
    } else if ((p - g.lampHead).distance < 30 ||
        (p.dx - size.width * 0.84).abs() < 10) {
      if (!reduce) _buzz.forward(from: 0);
      _say('Bzzzt. The lamp flickers. Somebody should report that.');
    } else if ((p - g.neon).distance < 40) {
      if (!reduce) _buzz.forward(from: 0);
      _say(
        s.crew != null
            ? '${s.neon}: open late, no questions asked.'
            : '${s.neon}: the kind of bar where nobody remembers faces.',
      );
    }
  }

  void _say(String text) {
    final id = ++_noteId;
    setState(() => _note = text);
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (mounted && id == _noteId) setState(() => _note = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _a
        ..stop()
        ..value = 0.3;
    } else if (!_a.isAnimating) {
      _a.repeat();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _cat.dispose();
    _buzz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: alleyCaption(widget.state),
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          onTapUp: (d) => _tap(d, box.biggest),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_a, _cat, _buzz]),
                    builder: (context, _) => CustomPaint(
                      painter: AlleyPainter(
                        widget.state,
                        _a.value,
                        cat: _cat.value,
                        buzz: _buzz.isAnimating ? _buzz.value : -1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                top: 8,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _note == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: ValueKey(_noteId),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE6101215),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _sodium.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            _note!,
                            style: NF.sora(12, color: const Color(0xFFECE8E1)),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AlleyPainter extends CustomPainter {
  AlleyPainter(this.s, this.t, {this.cat = 0, this.buzz = -1});

  final AlleyState s;

  /// Animation phase, 0 to 1 (rain and the police lights).
  final double t;

  /// The cat's run: 0 asleep, then off the lid and away by 1.
  final double cat;

  /// The lamp's buzz, 0 to 1 while it flickers; below 0 when steady.
  final double buzz;

  /// The lamp's brightness right now (it stutters while buzzing).
  double get _lamp {
    if (buzz < 0) return 1;
    final k = (buzz * 14).floor();
    return k.isEven ? 0.15 + 0.2 * (k % 3) : 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floor = h * 0.74;
    canvas.clipRect(Offset.zero & size);

    // The wall: dark brick, a strip of night sky above.
    canvas.drawRect(Offset.zero & size, Paint()..color = _night);
    final wall = Rect.fromLTWH(0, h * 0.08, w, floor - h * 0.08);
    canvas.drawRect(wall, Paint()..color = _brick);
    final mortar = Paint()
      ..color = _brickLine
      ..strokeWidth = 1.2;
    const bh = 9.0, bw = 24.0;
    var row = 0;
    for (var y = wall.top; y < floor; y += bh, row++) {
      canvas.drawLine(Offset(0, y), Offset(w, y), mortar);
      for (var x = row.isEven ? 0.0 : bw / 2; x < w; x += bw) {
        canvas.drawLine(Offset(x, y), Offset(x, min(floor, y + bh)), mortar);
      }
    }
    // Roofline.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.06, w, 5),
      Paint()..color = const Color(0xFF121418),
    );

    // A back door with a caged bulb, left of centre.
    final door = Rect.fromLTWH(w * 0.30, floor - h * 0.40, w * 0.11, h * 0.40);
    canvas.drawRect(door, Paint()..color = const Color(0xFF14171B));
    canvas.drawRect(
      door,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF262B31),
    );
    canvas.drawCircle(
      Offset(door.center.dx, door.top - 9),
      22,
      Paint()
        ..shader =
            RadialGradient(
              colors: [_sodium.withValues(alpha: 0.35), Colors.transparent],
            ).createShader(
              Rect.fromCircle(
                center: Offset(door.center.dx, door.top - 9),
                radius: 22,
              ),
            ),
    );
    canvas.drawCircle(
      Offset(door.center.dx, door.top - 9),
      3,
      Paint()..color = _sodium,
    );

    // Chalk tally on the door, neon over it.
    if (s.tally > 0) _tally(canvas, door);
    _neon(canvas, Offset(door.center.dx, door.top - 24));

    // Fire escape on the left.
    _fireEscape(canvas, w, h, floor);

    // A tag for each kind of crime you have tried.
    _tags(canvas, w, h);

    // Crew graffiti.
    if (s.crew case final crew?) {
      _graffiti(canvas, crew, Offset(w * 0.45, h * 0.11), w);
    }

    // The poster: hot gets a "have you seen" notice, red hot WANTED.
    if (s.heat >= 45) _poster(canvas, Offset(w * 0.47, h * 0.30), s.heat >= 70);

    // The wet floor, with the lamp and the lights reflected in it.
    final ground = Rect.fromLTWH(0, floor, w, h - floor);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16191E), Color(0xFF0A0B0E)],
        ).createShader(ground),
    );
    canvas.drawLine(
      Offset(0, floor),
      Offset(w, floor),
      Paint()
        ..color = const Color(0xFF2B3038)
        ..strokeWidth = 1.5,
    );

    // Streetlamp on the right, with its cone of sodium light.
    final lampX = w * 0.84;
    final head = Offset(lampX - 16, h * 0.16);
    final pole = Paint()
      ..color = const Color(0xFF1E2329)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lampX, floor + 4), Offset(lampX, head.dy), pole);
    canvas.drawLine(Offset(lampX, head.dy), Offset(head.dx, head.dy), pole);
    final cone = Path()
      ..moveTo(head.dx - 5, head.dy + 4)
      ..lineTo(head.dx + 5, head.dy + 4)
      ..lineTo(head.dx + w * 0.17, floor)
      ..lineTo(head.dx - w * 0.17, floor)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _sodium.withValues(alpha: 0.42 * _lamp),
            _sodium.withValues(alpha: 0.06 * _lamp),
          ],
        ).createShader(cone.getBounds()),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, floor + 10),
        width: w * 0.38,
        height: 16,
      ),
      Paint()
        ..color = _sodium.withValues(alpha: 0.16 * _lamp)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: head, width: 16, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = Color.lerp(const Color(0xFF3A2E1A), _sodium, _lamp)!,
    );

    // Dumpster, bag of dirty money, the cat.
    _dumpster(canvas, w, h, floor);

    // Police lights from the street (left edge), stronger with heat.
    if (s.heat > 0) _siren(canvas, w, h, floor);

    // Police tape across the alley while cases are open.
    if (s.cases > 0) _policeTape(canvas, w, h, floor);

    // Rain over everything, brightest inside the lamp's cone.
    _rain(canvas, w, h, floor, cone);

    // Heat label, stencilled bottom left.
    _label(canvas, w, h);
  }

  void _fireEscape(Canvas canvas, double w, double h, double floor) {
    final p = Paint()
      ..color = _metal
      ..strokeWidth = 2;
    final left = w * 0.04, right = w * 0.22;
    for (final y in [h * 0.30, h * 0.54]) {
      canvas.drawRect(
        Rect.fromLTRB(left, y, right, y + 3),
        Paint()..color = _metal,
      );
      for (var x = left; x <= right; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(x, y - 12), p..strokeWidth = 1);
      }
      canvas.drawLine(
        Offset(left, y - 12),
        Offset(right, y - 12),
        p..strokeWidth = 2,
      );
    }
    // The ladder, pulled up.
    final lx = right - 12;
    canvas.drawLine(
      Offset(lx, h * 0.30),
      Offset(lx, h * 0.62),
      p..strokeWidth = 1.5,
    );
    canvas.drawLine(Offset(lx + 8, h * 0.30), Offset(lx + 8, h * 0.62), p);
    for (var y = h * 0.33; y < h * 0.62; y += 6) {
      canvas.drawLine(Offset(lx, y), Offset(lx + 8, y), p..strokeWidth = 1);
    }
    // A lit window behind the escape.
    final win = Rect.fromLTWH(left + 8, h * 0.36, 22, 14);
    canvas.drawRect(win, Paint()..color = _sodium.withValues(alpha: 0.55));
    canvas.drawLine(
      win.topCenter,
      win.bottomCenter,
      Paint()..color = _brickLine,
    );
  }

  void _graffiti(Canvas canvas, String name, Offset at, double w) {
    // The tag shrinks to fit the wall rather than being cut off.
    TextPainter tag(double size) => TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF59F2A6),
          shadows: const [Shadow(color: Color(0xAA59F2A6), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    final maxW = w * 0.42;
    var size = 24.0;
    var tp = tag(size)..layout();
    while (tp.width > maxW && size > 14) {
      size -= 1;
      tp = tag(size)..layout();
    }
    tp.layout(maxWidth: maxW);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-0.08);
    tp.paint(canvas, Offset.zero);
    // Paint drips.
    final drip = Paint()
      ..color = const Color(0xFF59F2A6).withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final r = Random(name.hashCode);
    for (var i = 0; i < 4; i++) {
      final x = tp.width * (0.15 + 0.22 * i) + r.nextDouble() * 4;
      final len = 4 + r.nextDouble() * 9;
      canvas.drawLine(
        Offset(x, tp.height - 6),
        Offset(x, tp.height - 6 + len),
        drip,
      );
    }
    canvas.restore();
  }

  void _poster(Canvas canvas, Offset at, bool wanted) {
    final r = Rect.fromLTWH(at.dx, at.dy, 40, 50);
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(0.05);
    canvas.translate(-r.center.dx, -r.center.dy);
    canvas.drawRect(
      r.shift(const Offset(2, 2)),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(r, Paint()..color = _paper);
    final tp = TextPainter(
      text: TextSpan(
        text: wanted ? 'WANTED' : 'SEEN?',
        style: const TextStyle(
          fontFamily: 'StardosStencil',
          fontSize: 9,
          color: Color(0xFF3A1A12),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.top + 3));
    // A silhouette.
    final ink = Paint()..color = const Color(0xFF3A2A22);
    canvas.drawCircle(Offset(r.center.dx, r.top + 22), 6, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(r.center.dx, r.top + 37),
          width: 22,
          height: 12,
        ),
        const Radius.circular(6),
      ),
      ink,
    );
    if (wanted) {
      canvas.drawRect(
        Rect.fromLTWH(r.left + 4, r.bottom - 7, r.width - 8, 3),
        Paint()..color = const Color(0xFFB0352A),
      );
    }
    // Tape at the top corners.
    final tape = Paint()..color = const Color(0x99D9D2BF);
    canvas.drawRect(Rect.fromLTWH(r.left - 3, r.top - 2, 10, 5), tape);
    canvas.drawRect(Rect.fromLTWH(r.right - 7, r.top - 2, 10, 5), tape);
    canvas.restore();
  }

  void _dumpster(Canvas canvas, double w, double h, double floor) {
    final body = Rect.fromLTWH(w * 0.58, floor - h * 0.20, w * 0.18, h * 0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1F3B30),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left - 2, body.top - 4, body.width + 4, 5),
      Paint()..color = const Color(0xFF173026),
    );
    final rib = Paint()
      ..color = const Color(0xFF173026)
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      final x = body.left + body.width * i / 4;
      canvas.drawLine(Offset(x, body.top + 4), Offset(x, body.bottom - 3), rib);
    }
    // Wheels.
    final wheel = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(body.left + 6, body.bottom + 1), 3, wheel);
    canvas.drawCircle(Offset(body.right - 6, body.bottom + 1), 3, wheel);

    if (s.heat == 0 && s.dirty == 0 && cat < 1) {
      // A cat asleep on the lid: nothing to hide. Tapped, it bolts left,
      // off the lid and out of the alley.
      final cat = Paint()..color = const Color(0xFF0A0A0C);
      final run = Curves.easeIn.transform(this.cat);
      final c = Offset(
        body.left + body.width * 0.35 - run * w * 0.75,
        body.top - 8 - sin(run * pi) * 18 + (run > 0.5 ? (run - 0.5) * 40 : 0),
      );
      canvas.drawOval(Rect.fromCenter(center: c, width: 20, height: 9), cat);
      canvas.drawCircle(c + const Offset(10, -2), 4.5, cat);
      final ear = Path()
        ..moveTo(c.dx + 7, c.dy - 5)
        ..lineTo(c.dx + 8.5, c.dy - 10)
        ..lineTo(c.dx + 10.5, c.dy - 6)
        ..moveTo(c.dx + 11, c.dy - 6)
        ..lineTo(c.dx + 13, c.dy - 10)
        ..lineTo(c.dx + 14, c.dy - 4)
        ..close();
      canvas.drawPath(ear, cat);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 9, c.dy + 2)
          ..quadraticBezierTo(c.dx - 18, c.dy + 6, c.dx - 14, c.dy + 14),
        Paint()
          ..color = const Color(0xFF0A0A0C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    if (s.dirty > 0) {
      // The bag grows with the money: about full at a million.
      final f = (log(1 + s.dirty / 10000) / log(101)).clamp(0.25, 1.0);
      final bw = 18 + 26 * f, bh = 10 + 12 * f;
      final bag = Rect.fromLTWH(body.left - bw - 8, floor - bh - 1, bw, bh);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bag, Radius.circular(bh / 2.4)),
        Paint()..color = const Color(0xFF2B2F36),
      );
      canvas.drawLine(
        Offset(bag.left + 4, bag.top + 3),
        Offset(bag.right - 4, bag.top + 3),
        Paint()
          ..color = const Color(0xFF555B66)
          ..strokeWidth = 1.2,
      );
      // Notes poking out of the zip.
      final note = Paint()..color = const Color(0xFF6FBF73);
      for (var i = 0; i < (2 + 3 * f).round(); i++) {
        canvas.save();
        canvas.translate(bag.left + 7 + i * 6, bag.top + 3);
        canvas.rotate(-0.4 + i * 0.25);
        canvas.drawRect(const Rect.fromLTWH(-3, -6, 7, 5), note);
        canvas.restore();
      }
    }
  }

  void _siren(Canvas canvas, double w, double h, double floor) {
    final k = (s.heat / 100).clamp(0.15, 1.0);
    // Red and blue take turns, sweeping in from the alley mouth.
    final phase = sin(t * pi * 2 * 2);
    final redA = (0.5 + 0.5 * phase) * 0.85 * k;
    final blueA = (0.5 - 0.5 * phase) * 0.85 * k;
    for (final (c, a, y) in [
      (_red, redA, h * 0.35),
      (_blue, blueA, h * 0.62),
    ]) {
      final rect = Rect.fromCircle(
        center: Offset(-w * 0.05, y),
        radius: w * 0.55,
      );
      canvas.drawRect(
        Offset.zero & Size(w, h),
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: a),
              c.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
    // The same lights on the wet ground.
    canvas.drawRect(
      Rect.fromLTWH(0, floor + 3, w * 0.5 * k + 20, 3),
      Paint()
        ..color = (phase > 0 ? _red : _blue).withValues(alpha: 0.35 * k)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _policeTape(Canvas canvas, double w, double h, double floor) {
    canvas.save();
    canvas.translate(0, floor + 7);
    canvas.rotate(-0.035);
    final band = Rect.fromLTWH(-10, 0, w + 40, 14);
    canvas.drawRect(band, Paint()..color = _tape);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'POLICE LINE  DO NOT CROSS  ',
        style: TextStyle(
          fontFamily: 'StardosStencil',
          fontSize: 9,
          color: Color(0xFF111111),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    for (var x = 0.0; x < w + 20; x += tp.width) {
      tp.paint(canvas, Offset(x, 2));
    }
    canvas.restore();
  }

  void _rain(Canvas canvas, double w, double h, double floor, Path cone) {
    final r = Random(7);
    final dim = Paint()
      ..color = const Color(0x55B9C4D0)
      ..strokeWidth = 1;
    final lit = Paint()
      ..color = _sodium.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 0; i < 90; i++) {
      final x0 = r.nextDouble() * (w + 30);
      final speed = 0.8 + r.nextDouble() * 0.5;
      final y = ((r.nextDouble() + t * speed * 3) % 1) * (floor + 10) - 10;
      final x = x0 - y * 0.12;
      final len = 7 + r.nextDouble() * 6;
      final p0 = Offset(x, y), p1 = Offset(x - len * 0.12, y + len);
      canvas.drawLine(p0, p1, cone.contains(p0) ? lit : dim);
    }
    // Splashes on the ground.
    final splash = Paint()
      ..color = const Color(0x44B9C4D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final p = ((r.nextDouble() + t * 2) % 1);
      final c = Offset(
        r.nextDouble() * w,
        floor + 6 + r.nextDouble() * (h - floor - 10),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 3 + 10 * p, height: 1 + 3 * p),
        splash..color = Color.fromRGBO(185, 196, 208, 0.35 * (1 - p)),
      );
    }
  }

  void _label(Canvas canvas, double w, double h) {
    final hot = s.heat >= 45;
    final tp = TextPainter(
      text: TextSpan(
        text: 'HEAT · ${heatLabel(s.heat).toUpperCase()}',
        style: TextStyle(
          fontFamily: 'StardosStencil',
          fontSize: 13,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
          color: hot ? const Color(0xFFFF6B5E) : _sodium,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromLTWH(
      12,
      h - tp.height - 14,
      tp.width + 14,
      tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    tp.paint(canvas, Offset(box.left + 7, box.top + 3));
  }

  void _tally(Canvas canvas, Rect door) {
    final chalk = Paint()
      ..color = const Color(0xCCE8E4DA)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final shown = min(s.tally, 30);
    const gw = 11.0, rowH = 11.0;
    final perRow = max(1, ((door.width - 6) / gw).floor());
    for (var g = 0; g * 5 < shown; g++) {
      final n = min(5, shown - g * 5);
      final x0 = door.left + 4 + (g % perRow) * gw;
      final y0 = door.top + 6 + (g ~/ perRow) * rowH;
      for (var i = 0; i < min(n, 4); i++) {
        final x = x0 + i * 2.2;
        canvas.drawLine(Offset(x, y0), Offset(x + 0.4, y0 + 8), chalk);
      }
      if (n == 5) {
        canvas.drawLine(Offset(x0 - 1, y0 + 7), Offset(x0 + 8, y0 + 1), chalk);
      }
    }
    if (s.tally > 30) {
      final tp = TextPainter(
        text: TextSpan(
          text: '+${s.tally - 30}',
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 11,
            color: Color(0xCCE8E4DA),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(door.left + 4, door.top + 6 + 6 * rowH / 2 + 12));
    }
  }

  void _neon(Canvas canvas, Offset at) {
    const pink = Color(0xFFFF4FA3);
    final letters = s.neon.split('');
    final spans = <TextSpan>[];
    for (var i = 0; i < letters.length; i++) {
      // A letter or two stutters now and then, like a tired tube.
      final dead =
          ((t * 3 + i * 0.37) % 1) < 0.05 ||
          (buzz >= 0 && (i + (buzz * 10).floor()).isEven);
      spans.add(
        TextSpan(
          text: letters[i],
          style: TextStyle(
            color: dead ? const Color(0xFF4A2036) : pink,
            shadows: dead
                ? null
                : const [
                    Shadow(color: pink, blurRadius: 6),
                    Shadow(color: Color(0x88FF4FA3), blurRadius: 14),
                  ],
          ),
        ),
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
        children: spans,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final box = Rect.fromCenter(
      center: at,
      width: tp.width + 12,
      height: tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x55FF4FA3),
    );
    tp.paint(canvas, Offset(box.left + 6, box.top + 3));
  }

  void _tags(Canvas canvas, double w, double h) {
    for (var i = 0; i < s.tags.length; i++) {
      final icon = crimeGlyphs[s.tags[i]] ?? Icons.star_rounded;
      final spot = _tagSpots[i % _tagSpots.length];
      final r = Random(s.tags[i].hashCode);
      final lap = i ~/ _tagSpots.length;
      final at = Offset(
        spot.$1 * w + lap * 9 + r.nextDouble() * 4,
        spot.$2 * h + lap * 6 + r.nextDouble() * 3,
      );
      final color = _sprays[i % _sprays.length];
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 15,
            color: color.withValues(alpha: 0.78),
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(-0.3 + r.nextDouble() * 0.6);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      // An overspray drip.
      canvas.drawLine(
        Offset(r.nextDouble() * 4 - 2, tp.height / 2 - 2),
        Offset(r.nextDouble() * 4 - 2, tp.height / 2 + 3 + r.nextDouble() * 5),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(AlleyPainter old) =>
      old.t != t || old.s != s || old.cat != cat || old.buzz != buzz;
}

/// A strip of police tape, used as a divider on the Crime page.
class TapeDivider extends StatelessWidget {
  const TapeDivider({super.key, this.text = 'CRIME SCENE  DO NOT CROSS  '});
  final String text;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 16,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: _tape,
      alignment: Alignment.centerLeft,
      child: ClipRect(
        child: Text(
          text * 8,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            fontFamily: 'StardosStencil',
            fontSize: 10,
            letterSpacing: 1,
            color: Color(0xFF111111),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

// ---------------- Police scanner ----------------

/// A strip of police radio under the alley. Each line types itself out,
/// holds, and gives way to the next. With reduce motion, lines show whole
/// and a tap moves on.
class ScannerTicker extends StatefulWidget {
  const ScannerTicker({super.key, required this.lines});
  final List<String> lines;

  @override
  State<ScannerTicker> createState() => _ScannerTickerState();
}

class _ScannerTickerState extends State<ScannerTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..addStatusListener(_next);
  int _i = 0;
  bool _still = false;

  void _next(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    setState(() => _i = (_i + 1) % max(1, widget.lines.length));
    _a.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.of(context).disableAnimations;
    if (_still) {
      _a.stop();
    } else if (!_a.isAnimating) {
      _a.forward();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final line = widget.lines[_i % widget.lines.length];
    return Semantics(
      label: 'Police scanner: $line',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() {
          _i = (_i + 1) % widget.lines.length;
          if (!_still) _a.forward(from: 0);
        }),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0B0D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2B3038)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _a,
                    builder: (context, _) => Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _still || (_a.value * 8).floor().isEven
                            ? _red
                            : const Color(0xFF4A1414),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SCANNER',
                    style: NF.stencil(11, color: const Color(0xFFFF6B5E)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TAP FOR NEXT',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NF.stencil(9, color: const Color(0xFF6A6A68)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _a,
                builder: (context, _) {
                  final shown = _still
                      ? line.length
                      : min(line.length, (line.length * _a.value * 2.2).ceil());
                  return Stack(
                    children: [
                      // The full line, invisible, keeps the height steady.
                      Opacity(opacity: 0, child: Text(line, style: _mono)),
                      Text(
                        '${line.substring(0, shown)}${shown < line.length ? '_' : ''}',
                        style: _mono,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextStyle get _mono => const TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    height: 1.35,
    color: _sodium,
  );
}

// ---------------- Case folders ----------------

/// A crime section as a manila case folder: a stencilled tab, the kind of
/// crime inside, and a stamp saying how many are open.
class CaseFolder extends StatelessWidget {
  const CaseFolder({
    super.key,
    required this.title,
    required this.sub,
    required this.icon,
    required this.open,
    required this.expanded,
    required this.onTap,
  });

  final String title, sub;
  final IconData icon;
  final int open;
  final bool expanded;
  final VoidCallback onTap;

  static const _kraft = Color(0xFF2A2419);
  static const _manila = Color(0xFFC9A86A);

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: expanded,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The folder's tab.
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.fromLTRB(10, 4, 12, 3),
            decoration: const BoxDecoration(
              color: _manila,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: const Color(0xFF2A1E0E)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NF.stencil(12, color: const Color(0xFF2A1E0E)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: _kraft,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border.all(color: _manila.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sub,
                    style: NF.sora(12.5, color: const Color(0xFFD9CDB4)),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: open == 0
                            ? const Color(0xFF7A7264)
                            : const Color(0xFFE0533F),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      open == 0 ? 'CLOSED' : '$open OPEN',
                      style: NF.stencil(
                        10,
                        color: open == 0
                            ? const Color(0xFF7A7264)
                            : const Color(0xFFE0533F),
                      ),
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFFB8A782),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------- Stamps on crime results ----------------

/// The rubber stamp on a crime's result, from how it went.
String crimeStamp(String text, String tone, {bool paid = false}) {
  final t = text.toLowerCase();
  const busted = [
    'arrested',
    'handcuff',
    'caught',
    'charged',
    'custody',
    'police station',
    'sentenced',
  ];
  if (busted.any(t.contains)) return 'BUSTED';
  if (t.contains('investigat') ||
      t.contains('witness') ||
      t.contains('camera') ||
      t.contains('suspect')) {
    return 'HEAT RISING';
  }
  if (paid) return 'PAYDAY';
  if (tone == 'bad') return 'BOTCHED';
  return 'CLEAN GETAWAY';
}

class CrimeStamp extends StatelessWidget {
  const CrimeStamp(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'BUSTED' || 'BOTCHED' => const Color(0xFFFF5A4A),
      'HEAT RISING' => const Color(0xFFFF9F43),
      'PAYDAY' => const Color(0xFF6FD08C),
      _ => _sodium,
    };
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(label, style: NF.stencil(12, color: color)),
      ),
    );
  }
}
