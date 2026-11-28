import 'dart:math';

import 'package:flutter/material.dart';

/// The art of the era pages (the redesign after Phase 2D): each page is a
/// Renaissance object (a ledger, a broadsheet, a market stall, a street, a
/// hall of banners, a portrait wall), drawn in ink with a fixed palette so
/// it looks the same in a Legend life and an ordinary era life.
abstract final class EraInk {
  static const paper = Color(0xFFF3E7CC);
  static const paper2 = Color(0xFFE6D3AD);
  static const card = Color(0xFFF7ECD4);
  static const ink = Color(0xFF3B2A1A);
  static const ink2 = Color(0xFF6B5440);
  static const red = Color(0xFFA3452E);
  static const red2 = Color(0xFF7E2F1D);
  static const gold = Color(0xFFB8933F);
  static const gold2 = Color(0xFF8A6A2C);
  static const goldLight = Color(0xFFE8C66C);
  static const sea = Color(0xFF4D6B73);
  static const green = Color(0xFF5D6B3A);
  static const wood = Color(0xFF6B4A2A);
}

/// The book face of the era pages.
TextStyle fell(double size, {Color color = EraInk.ink, bool italic = false, double height = 1.25}) =>
    TextStyle(
      fontFamily: 'IMFellDWPica',
      fontFamilyFallback: const ['Sora'],
      fontSize: size,
      color: color,
      height: height,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );

/// The hand-lettered face.
TextStyle hand(double size, {Color color = EraInk.red, double height = 1.05}) => TextStyle(
  fontFamily: 'Caveat',
  fontFamilyFallback: const ['Sora'],
  fontWeight: FontWeight.w700,
  fontSize: size,
  color: color,
  height: height,
);

/// Small spaced capitals: "WEALTH · VINCI 1478".
Widget inkKicker(String text, {Color color = EraInk.red}) => Text(
  text.toUpperCase(),
  style: fell(12, color: color).copyWith(letterSpacing: 2.6),
);

/// A small solid button in ink red.
class InkButton extends StatelessWidget {
  const InkButton(this.text, {super.key, this.onTap, this.color = EraInk.red, this.light = false});
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final bool light;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: light ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: fell(13.5, color: light ? color : Colors.white).copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// A small tag: "RISKY · ×1.5".
class InkTag extends StatelessWidget {
  const InkTag(this.text, {super.key, this.color = EraInk.sea});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
    ),
  );
}

// ---------------- Wax seals ----------------

/// A wax seal with a letter or sign on it. Grey when [off].
class WaxSeal extends StatelessWidget {
  const WaxSeal(this.mark, {super.key, this.size = 64, this.color = EraInk.red, this.off = false, this.glyph});
  final String mark;
  final String? glyph;
  final double size;
  final Color color;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final c = off ? const Color(0xFF9C8C70) : color;
    return SizedBox(
      width: size,
      height: size + size * 0.06,
      child: CustomPaint(
        painter: _SealPainter(c),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.06),
            child: glyph != null
                ? InkGlyph(glyph!, size: size * 0.5, color: const Color(0xFFF6DCC0), accent: const Color(0xFFF6DCC0))
                : Text(
                    mark,
                    style: hand(size * (mark.length > 1 ? 0.36 : 0.44), color: const Color(0xFFF6DCC0)),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  _SealPainter(this.color);
  final Color color;

  Path _blob(Size s, double dy) {
    final c = Offset(s.width / 2, s.width / 2 + dy);
    final r = s.width / 2;
    final p = Path();
    const n = 26;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * pi;
      final rr = r * (i.isEven ? 1 : 0.9);
      final pt = c + Offset(cos(a) * rr, sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Color.lerp(color, Colors.black, 0.45)!;
    canvas.drawPath(_blob(size, size.width * 0.06), Paint()..color = dark);
    final face = _blob(size, 0);
    canvas.drawPath(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.18)!, color, dark],
          stops: const [0, 0.6, 1],
        ).createShader(Offset.zero & Size(size.width, size.width)),
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.width / 2),
      size.width * 0.33,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.color != color;
}

/// A seal with a caption under it, tappable.
class SealButton extends StatelessWidget {
  const SealButton({
    super.key,
    required this.mark,
    required this.title,
    required this.line,
    this.onTap,
    this.off = false,
    this.color = EraInk.red,
    this.lineColor,
    this.glyph,
  });
  final String mark;
  final String? glyph;
  final String title;
  final String line;
  final VoidCallback? onTap;
  final bool off;
  final Color color;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      children: [
        WaxSeal(mark, off: off, color: color, glyph: glyph),
        const SizedBox(height: 5),
        Text(title, textAlign: TextAlign.center, maxLines: 2, style: fell(13.5, height: 1.1)),
        Text(
          line,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: fell(12.5, color: lineColor ?? (off ? EraInk.ink2 : EraInk.red), height: 1.1),
        ),
      ],
    ),
  );
}

// ---------------- Coins ----------------

/// A stack (or two) of gold coins that grows with [money].
class CoinStack extends StatelessWidget {
  const CoinStack({super.key, required this.money, this.size = 86});
  final int money;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size * 0.92, child: CustomPaint(painter: _CoinPainter(money)));
}

class _CoinPainter extends CustomPainter {
  _CoinPainter(this.money);
  final int money;

  @override
  void paint(Canvas canvas, Size size) {
    // 1 coin for anything, up to 12 as the purse grows (log scale).
    final n = money <= 0 ? 0 : (1 + (log(money + 1) / ln10 * 3).floor()).clamp(1, 12);
    final w = size.width * 0.62, h = size.width * 0.19;
    final rng = Random(7);
    for (var i = 0; i < n; i++) {
      final stack = i < 7 ? 0 : 1;
      final k = stack == 0 ? i : i - 7;
      final x = (stack == 0 ? 0.0 : size.width * 0.34) + rng.nextDouble() * 4;
      final y = size.height - h - k * h * 0.6 - 2;
      final r = Rect.fromLTWH(x, y, w, h);
      canvas.drawOval(r.shift(Offset(0, h * 0.25)), Paint()..color = EraInk.gold2);
      canvas.drawOval(
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.5),
            colors: [Color(0xFFF2D27A), EraInk.gold, EraInk.gold2],
            stops: [0, 0.6, 1],
          ).createShader(r),
      );
      canvas.drawOval(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF6E5220),
      );
    }
    if (n == 0) {
      canvas.drawOval(
        Rect.fromLTWH(0, size.height - h, w, h),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = EraInk.ink2,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.money != money;
}

// ---------------- Ink glyphs ----------------

/// A small ink drawing by name: 'horse', 'lute', 'ship', 'masks'...
class InkGlyph extends StatelessWidget {
  const InkGlyph(this.name, {super.key, this.size = 44, this.color = EraInk.ink, this.accent = EraInk.red});
  final String name;
  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: GlyphPainter(name, color, accent)),
  );
}

class GlyphPainter extends CustomPainter {
  GlyphPainter(this.name, this.color, this.accent);
  final String name;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) => paintGlyph(canvas, Offset.zero & size, name, color, accent);

  @override
  bool shouldRepaint(GlyphPainter old) => old.name != name || old.color != color || old.accent != accent;
}

/// Draws glyph [name] into [r], in a 100×100 design box.
void paintGlyph(Canvas canvas, Rect r, String name, Color ink, Color accent) {
  canvas.save();
  canvas.translate(r.left, r.top);
  canvas.scale(r.width / 100, r.height / 100);
  final s = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final f = Paint()..color = accent;
  final g = Paint()..color = EraInk.gold;
  final paper = Paint()..color = EraInk.card;
  final wood = Paint()..color = EraInk.wood;
  Path p(List<double> pts, {bool close = false}) {
    final path = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i], pts[i + 1]);
    }
    if (close) path.close();
    return path;
  }

  void both(Path path, Paint fill) {
    canvas.drawPath(path, fill);
    canvas.drawPath(path, s);
  }

  switch (name) {
    case 'lance':
      canvas.drawLine(const Offset(10, 90), const Offset(88, 14), s..strokeWidth = 6);
      both(p([70, 30, 92, 26, 80, 44], close: true), f);
      canvas.drawLine(const Offset(18, 72), const Offset(30, 84), s..strokeWidth = 4.5);
    case 'horse' || 'mule':
      final body = Path()
        ..moveTo(14, 50)
        ..quadraticBezierTo(18, 32, 42, 32)
        ..lineTo(66, 32)
        ..lineTo(76, 14)
        ..lineTo(86, 20)
        ..lineTo(84, 36)
        ..quadraticBezierTo(92, 44, 84, 50)
        ..lineTo(72, 50);
      canvas.drawPath(body, s);
      for (final x in [22.0, 34.0, 60.0, 70.0]) {
        canvas.drawLine(Offset(x, 48), Offset(x, 88), s);
      }
      canvas.drawLine(const Offset(14, 50), const Offset(72, 50), s);
      if (name == 'mule') {
        canvas.drawLine(const Offset(78, 16), const Offset(74, 2), s);
        canvas.drawLine(const Offset(84, 18), const Offset(86, 4), s);
        both(p([36, 32, 56, 32, 56, 22, 36, 22], close: true), wood);
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(14, 50)
            ..quadraticBezierTo(4, 60, 8, 74),
          s,
        );
        both(p([38, 32, 58, 32, 58, 40, 38, 40], close: true), f);
      }
    case 'court':
      canvas.drawRect(const Rect.fromLTWH(8, 18, 84, 64), s);
      canvas.drawLine(const Offset(50, 18), const Offset(50, 82), s..strokeWidth = 2.5);
      canvas.drawCircle(const Offset(32, 52), 7, f);
      canvas.drawLine(const Offset(64, 30), const Offset(84, 70), s..strokeWidth = 4.5);
    case 'cards':
      canvas.save();
      canvas.translate(32, 50);
      canvas.rotate(-0.22);
      both(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -26, 32, 52), const Radius.circular(4))), paper);
      canvas.restore();
      canvas.save();
      canvas.translate(64, 50);
      canvas.rotate(0.2);
      both(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -26, 32, 52), const Radius.circular(4))), paper);
      canvas.drawCircle(Offset.zero, 6, f);
      canvas.restore();
    case 'tavern':
      both(p([24, 30, 66, 30, 62, 88, 28, 88], close: true), paper);
      canvas.drawPath(
        Path()
          ..moveTo(66, 40)
          ..quadraticBezierTo(86, 42, 82, 60)
          ..quadraticBezierTo(80, 72, 64, 72),
        s,
      );
      canvas.drawPath(
        Path()
          ..moveTo(20, 30)
          ..quadraticBezierTo(30, 14, 44, 24)
          ..quadraticBezierTo(56, 12, 70, 28),
        s..color = accent,
      );
    case 'bath':
      both(
        Path()
          ..moveTo(10, 60)
          ..lineTo(90, 60)
          ..quadraticBezierTo(88, 88, 50, 88)
          ..quadraticBezierTo(12, 88, 10, 60),
        paper,
      );
      for (final x in [32.0, 50.0, 68.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 50)
            ..quadraticBezierTo(x + 7, 38, x, 28)
            ..quadraticBezierTo(x - 7, 18, x, 8),
          s..color = accent,
        );
      }
    case 'lute' || 'music':
      canvas.drawLine(const Offset(52, 44), const Offset(90, 8), s..strokeWidth = 7);
      both(Path()..addOval(const Rect.fromLTWH(10, 36, 50, 56)), g);
      canvas.drawCircle(const Offset(35, 64), 7, Paint()..color = ink);
    case 'flag':
      canvas.drawLine(const Offset(40, 92), const Offset(40, 8), s);
      both(p([40, 10, 84, 22, 40, 36], close: true), f);
      canvas.drawLine(const Offset(18, 92), const Offset(64, 92), s);
    case 'night':
      both(p([8, 92, 8, 56, 28, 56, 28, 92], close: true), paper);
      both(p([40, 92, 40, 38, 64, 38, 64, 92], close: true), paper);
      canvas.drawRect(const Rect.fromLTWH(48, 50, 8, 10), Paint()..color = EraInk.goldLight);
      canvas.drawCircle(const Offset(82, 22), 12, s);
      canvas.drawLine(const Offset(4, 92), const Offset(96, 92), s);
    case 'masks':
      both(
        Path()
          ..moveTo(6, 44)
          ..quadraticBezierTo(30, 20, 54, 44)
          ..quadraticBezierTo(46, 72, 30, 72)
          ..quadraticBezierTo(14, 72, 6, 44),
        f,
      );
      both(
        Path()
          ..moveTo(46, 52)
          ..quadraticBezierTo(70, 30, 94, 52)
          ..quadraticBezierTo(86, 82, 70, 82)
          ..quadraticBezierTo(54, 82, 46, 52),
        g,
      );
      for (final c in const [Offset(21, 48), Offset(39, 48), Offset(62, 56), Offset(78, 56)]) {
        canvas.drawCircle(c, 5, paper);
      }
    case 'candle':
      both(p([40, 40, 60, 40, 60, 92, 40, 92], close: true), paper);
      both(
        Path()
          ..moveTo(50, 10)
          ..quadraticBezierTo(64, 26, 50, 34)
          ..quadraticBezierTo(36, 26, 50, 10),
        f,
      );
      canvas.drawLine(const Offset(30, 92), const Offset(70, 92), s);
    case 'ball':
      both(Path()..addOval(const Rect.fromLTWH(18, 18, 64, 64)), paper);
      canvas.drawPath(
        Path()
          ..moveTo(18, 50)
          ..quadraticBezierTo(50, 30, 82, 50),
        s,
      );
      canvas.drawPath(
        Path()
          ..moveTo(50, 18)
          ..quadraticBezierTo(36, 50, 50, 82),
        s,
      );
    case 'chess':
      both(
        Path()
          ..moveTo(30, 90)
          ..lineTo(70, 90)
          ..lineTo(64, 74)
          ..lineTo(58, 74)
          ..quadraticBezierTo(54, 50, 60, 40)
          ..lineTo(40, 40)
          ..quadraticBezierTo(46, 50, 42, 74)
          ..lineTo(36, 74)
          ..close(),
        paper,
      );
      canvas.drawCircle(const Offset(50, 26), 12, f);
      canvas.drawCircle(const Offset(50, 26), 12, s);
    case 'book':
      both(p([22, 14, 78, 14, 78, 88, 22, 88], close: true), Paint()..color = EraInk.red2);
      canvas.drawLine(const Offset(32, 14), const Offset(32, 88), s..color = EraInk.goldLight);
    case 'paper':
      both(p([14, 84, 74, 24, 82, 32, 22, 92], close: true), paper);
      both(Path()..addOval(const Rect.fromLTWH(14, 12, 30, 30)), paper);
      canvas.drawCircle(const Offset(29, 27), 6, f);
    case 'sword':
      canvas.drawLine(const Offset(20, 80), const Offset(84, 16), s..strokeWidth = 6);
      canvas.drawLine(const Offset(18, 56), const Offset(44, 82), s..strokeWidth = 6);
      canvas.drawCircle(const Offset(14, 86), 6, g);
    case 'sack':
      both(
        Path()
          ..moveTo(36, 26)
          ..quadraticBezierTo(10, 50, 20, 88)
          ..lineTo(80, 88)
          ..quadraticBezierTo(90, 50, 64, 26)
          ..close(),
        Paint()..color = EraInk.paper2,
      );
      canvas.drawLine(const Offset(34, 26), const Offset(66, 26), s);
      for (final c in const [Offset(42, 62), Offset(56, 70), Offset(50, 54)]) {
        canvas.drawCircle(c, 4, f);
      }
    case 'pot':
      both(
        Path()
          ..moveTo(20, 40)
          ..lineTo(80, 40)
          ..quadraticBezierTo(82, 86, 50, 86)
          ..quadraticBezierTo(18, 86, 20, 40),
        Paint()..color = const Color(0xFFB87333),
      );
      canvas.drawLine(const Offset(14, 40), const Offset(86, 40), s);
      canvas.drawLine(const Offset(50, 40), const Offset(50, 20), s);
    case 'cloak':
      both(p([50, 8, 22, 22, 10, 92, 90, 92, 78, 22], close: true), wood);
      canvas.drawLine(const Offset(50, 8), const Offset(50, 92), s..strokeWidth = 2.5);
    case 'doublet':
      both(p([28, 10, 72, 10, 90, 30, 78, 36, 76, 92, 24, 92, 22, 36, 10, 30], close: true), f);
      for (final y in [34.0, 50.0, 66.0]) {
        canvas.drawLine(Offset(38, y), Offset(62, y), Paint()
          ..color = EraInk.goldLight
          ..strokeWidth = 4);
      }
    case 'ship':
      both(p([10, 66, 90, 66, 78, 86, 22, 86], close: true), wood);
      canvas.drawLine(const Offset(50, 66), const Offset(50, 10), s);
      both(p([50, 14, 80, 56, 50, 56], close: true), paper);
      both(p([50, 20, 26, 56, 50, 56], close: true), paper);
      both(p([50, 8, 64, 12, 50, 16], close: true), f);
    case 'camel':
      canvas.drawPath(
        Path()
          ..moveTo(14, 56)
          ..quadraticBezierTo(24, 24, 40, 44)
          ..quadraticBezierTo(54, 20, 66, 46)
          ..lineTo(74, 30)
          ..lineTo(88, 30)
          ..lineTo(84, 38),
        s,
      );
      canvas.drawLine(const Offset(14, 56), const Offset(70, 56), s);
      for (final x in [22.0, 32.0, 56.0, 66.0]) {
        canvas.drawLine(Offset(x, 56), Offset(x, 90), s);
      }
    case 'shop':
      both(p([12, 90, 12, 40, 88, 40, 88, 90], close: true), paper);
      for (var i = 0; i < 4; i++) {
        canvas.drawPath(
          p([8 + i * 21.0, 40, 8 + i * 21.0 + 21, 40, 8 + i * 21.0 + 21, 24, 8 + i * 21.0, 24], close: true),
          i.isEven ? f : paper,
        );
      }
      canvas.drawRect(const Rect.fromLTWH(8, 24, 84, 16), s);
      both(p([38, 90, 38, 60, 62, 60, 62, 90], close: true), wood);
    case 'awning':
      for (var i = 0; i < 5; i++) {
        canvas.drawPath(
          p([4 + i * 18.4, 14, 4 + i * 18.4 + 18.4, 14, 4 + i * 18.4 + 18.4, 34, 4 + i * 18.4, 34], close: true),
          i.isEven ? f : paper,
        );
      }
      canvas.drawRect(const Rect.fromLTWH(4, 14, 92, 20), s);
      canvas.drawLine(const Offset(12, 34), const Offset(12, 90), s);
      canvas.drawLine(const Offset(88, 34), const Offset(88, 90), s);
      both(p([20, 66, 80, 66, 80, 78, 20, 78], close: true), wood);
      canvas.drawCircle(const Offset(34, 58), 7, g);
      canvas.drawCircle(const Offset(52, 58), 7, f);
      canvas.drawCircle(const Offset(68, 58), 7, g);
    case 'fire':
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * 2 * pi;
        canvas.drawLine(
          Offset(50 + cos(a) * 14, 40 + sin(a) * 14),
          Offset(50 + cos(a) * 34, 40 + sin(a) * 34),
          s..color = i.isEven ? accent : EraInk.gold,
        );
      }
      canvas.drawLine(const Offset(50, 92), const Offset(50, 60), s..color = ink);
    case 'stage':
      canvas.drawCircle(const Offset(50, 54), 38, s);
      canvas.drawCircle(const Offset(50, 54), 26, s..strokeWidth = 2.5);
      both(p([38, 54, 62, 54, 62, 92, 38, 92], close: true), f);
      both(p([50, 6, 64, 12, 50, 18], close: true), f);
      canvas.drawLine(const Offset(50, 6), const Offset(50, 16), s..strokeWidth = 4.5);
    case 'shrine':
      both(
        Path()
          ..moveTo(22, 90)
          ..lineTo(22, 50)
          ..quadraticBezierTo(50, 10, 78, 50)
          ..lineTo(78, 90)
          ..close(),
        paper,
      );
      both(
        Path()
          ..moveTo(40, 90)
          ..lineTo(40, 66)
          ..quadraticBezierTo(50, 54, 60, 66)
          ..lineTo(60, 90),
        wood,
      );
    case 'crescent':
      canvas.drawCircle(const Offset(50, 34), 20, f);
      canvas.drawCircle(const Offset(60, 28), 18, Paint()..color = EraInk.card);
      for (var i = 0; i < 2; i++) {
        canvas.drawPath(
          Path()
            ..moveTo(4, 74 + i * 14.0)
            ..quadraticBezierTo(30, 58 + i * 14.0, 54, 74 + i * 14.0)
            ..quadraticBezierTo(76, 86 + i * 14.0, 96, 70 + i * 14.0),
          s,
        );
      }
    case 'chest':
      both(p([8, 44, 92, 44, 92, 90, 8, 90], close: true), wood);
      both(
        Path()
          ..moveTo(8, 44)
          ..quadraticBezierTo(50, 8, 92, 44),
        Paint()..color = const Color(0xFF7E5A34),
      );
      canvas.drawRect(const Rect.fromLTWH(42, 50, 16, 18), g);
    case 'home':
      both(p([14, 92, 14, 48, 50, 18, 86, 48, 86, 92], close: true), paper);
      both(p([40, 92, 40, 64, 60, 64, 60, 92], close: true), wood);
    case 'crown':
      both(p([10, 80, 10, 30, 30, 52, 50, 20, 70, 52, 90, 30, 90, 80], close: true), g);
    case 'dance':
      for (final x in [32.0, 68.0]) {
        canvas.drawCircle(Offset(x, 22), 9, s);
        canvas.drawPath(p([x - 16, 88, x, 36, x + 16, 88], close: true), x < 50 ? f : paper);
        canvas.drawPath(p([x - 16, 88, x, 36, x + 16, 88], close: true), s);
      }
      canvas.drawLine(const Offset(40, 52), const Offset(60, 52), s);
    case 'drum':
      both(Path()..addRect(const Rect.fromLTWH(22, 36, 56, 48)), f);
      canvas.drawOval(const Rect.fromLTWH(22, 28, 56, 16), paper);
      canvas.drawOval(const Rect.fromLTWH(22, 28, 56, 16), s);
      canvas.drawLine(const Offset(30, 18), const Offset(46, 34), s);
      canvas.drawLine(const Offset(70, 18), const Offset(54, 34), s);
    case 'hunt':
      canvas.drawPath(
        Path()
          ..moveTo(14, 70)
          ..quadraticBezierTo(30, 30, 70, 30)
          ..lineTo(88, 20)
          ..lineTo(84, 44)
          ..quadraticBezierTo(50, 50, 28, 78),
        s,
      );
      canvas.drawOval(const Rect.fromLTWH(76, 16, 18, 32), g);
      canvas.drawPath(
        Path()
          ..moveTo(4, 92)
          ..quadraticBezierTo(50, 66, 96, 92),
        s,
      );
    case 'coin':
      both(Path()..addOval(const Rect.fromLTWH(18, 18, 64, 64)), g);
      canvas.drawCircle(const Offset(50, 50), 20, s..strokeWidth = 2.5);
    default:
      canvas.drawCircle(const Offset(50, 50), 30, s);
      canvas.drawCircle(const Offset(50, 50), 8, f);
  }
  canvas.restore();
}

// ---------------- People ----------------

/// A small painted portrait in an oval, seeded by [seed] so each person
/// always looks the same.
class InkPortrait extends StatelessWidget {
  const InkPortrait({
    super.key,
    required this.seed,
    required this.female,
    required this.age,
    this.width = 92,
  });
  final String seed;
  final bool female;
  final int age;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 1.22,
    child: CustomPaint(painter: _PortraitPainter(seed, female, age)),
  );
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.seed, this.female, this.age);
  final String seed;
  final bool female;
  final int age;

  static const _grounds = [
    Color(0xFF4E6A70),
    Color(0xFF6E5A34),
    Color(0xFF55663A),
    Color(0xFF6B3A2E),
    Color(0xFF3E4A66),
    Color(0xFF7A6A4A),
  ];
  static const _skins = [Color(0xFFE7C9A6), Color(0xFFD9AE86), Color(0xFFB98660), Color(0xFF8A5A3A), Color(0xFF5E3A24)];
  static const _hair = [Color(0xFF3B2A1A), Color(0xFF5A3A22), Color(0xFF7E5A34), Color(0xFF1E1610), Color(0xFF9A6A3A)];
  static const _cloth = [EraInk.red2, Color(0xFF2F3A5A), EraInk.green, Color(0xFF4A2F4A), EraInk.ink, Color(0xFF6B4A2A)];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed.hashCode);
    final w = size.width, h = size.height;
    final frame = Rect.fromLTWH(0, 0, w, h);
    // Gold frame.
    canvas.drawOval(frame.shift(const Offset(0, 4)), Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawOval(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3D27B), Color(0xFFA87C2E), Color(0xFFF0CF7A), Color(0xFF8A6A2C)],
        ).createShader(frame),
    );
    final inner = frame.deflate(w * 0.075);
    canvas.save();
    canvas.clipPath(Path()..addOval(inner));
    final ground = _grounds[rng.nextInt(_grounds.length)];
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(ground, Colors.white, 0.12)!, Color.lerp(ground, Colors.black, 0.3)!],
        ).createShader(inner),
    );
    final cx = w / 2;
    final head = Offset(cx, h * 0.42);
    final hr = w * 0.17;
    final skin = _skins[rng.nextInt(_skins.length)];
    final hair = age >= 55 ? const Color(0xFFB8B0A0) : _hair[rng.nextInt(_hair.length)];
    final cloth = _cloth[rng.nextInt(_cloth.length)];
    // Shoulders.
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.38, h)
        ..quadraticBezierTo(cx - w * 0.36, h * 0.64, cx, h * 0.63)
        ..quadraticBezierTo(cx + w * 0.36, h * 0.64, cx + w * 0.38, h)
        ..close(),
      Paint()..color = cloth,
    );
    if (female) {
      // Veil or long hair behind the head.
      canvas.drawPath(
        Path()
          ..moveTo(head.dx - hr * 1.25, head.dy + hr * 1.6)
          ..quadraticBezierTo(head.dx - hr * 1.5, head.dy - hr * 1.5, head.dx, head.dy - hr * 1.3)
          ..quadraticBezierTo(head.dx + hr * 1.5, head.dy - hr * 1.5, head.dx + hr * 1.25, head.dy + hr * 1.6)
          ..close(),
        Paint()..color = rng.nextBool() ? hair : const Color(0xFFEFE6D2),
      );
    }
    canvas.drawCircle(head, hr, Paint()..color = skin);
    if (!female) {
      // Hair cap, then a hat on some.
      canvas.drawArc(Rect.fromCircle(center: head, radius: hr * 1.04), pi, pi, true, Paint()..color = hair);
      if (rng.nextInt(3) == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: head - Offset(0, hr * 0.95), width: hr * 2.5, height: hr * 0.7),
            Radius.circular(hr * 0.3),
          ),
          Paint()..color = EraInk.red,
        );
      }
      if (age >= 35 && rng.nextBool()) {
        canvas.drawArc(
          Rect.fromCircle(center: head + Offset(0, hr * 0.25), radius: hr * 0.95),
          0.15,
          pi - 0.3,
          false,
          Paint()
            ..color = hair
            ..style = PaintingStyle.stroke
            ..strokeWidth = hr * 0.45,
        );
      }
    } else {
      canvas.drawArc(Rect.fromCircle(center: head, radius: hr * 1.02), pi * 1.05, pi * 0.9, true, Paint()..color = hair);
    }
    // Eyes.
    final eye = Paint()..color = const Color(0xFF2A1E14);
    canvas.drawCircle(head + Offset(-hr * 0.35, hr * 0.1), hr * 0.09, eye);
    canvas.drawCircle(head + Offset(hr * 0.35, hr * 0.1), hr * 0.09, eye);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.seed != seed || old.age != age;
}

/// Ruled ledger paper with a red margin, behind the Wealth tab.
class LedgerPaperPainter extends CustomPainter {
  const LedgerPaperPainter({this.margin = 30});
  final double margin;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = EraInk.paper);
    final rule = Paint()
      ..color = const Color(0xFFD8C3A0)
      ..strokeWidth = 1;
    for (var y = 32.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    final red = Paint()
      ..color = const Color(0xFFC0573C)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(margin, 0), Offset(margin, size.height), red);
    canvas.drawLine(Offset(margin + 4, 0), Offset(margin + 4, size.height), red..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(LedgerPaperPainter old) => old.margin != margin;
}
